import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:prosoc/utils/api_error_helper.dart';
import 'package:prosoc/utils/currency_formatter.dart';
import '../../../config/colors.dart';
import '../../../config/api.dart';
import '../../../models/wallet_virtuel_mouvement_model.dart';
import '../../../services/auth_service.dart';
import '../../../models/wallet_virtuel_agent_model.dart';
import '../../widgets/prosoc_resource_error_view.dart';
import '../../widgets/wallet_movement_card.dart';
import 'virtual_wallet_mouvements_screen.dart';

class VirtualAccountScreen extends StatefulWidget {
  const VirtualAccountScreen({super.key});

  @override
  State<VirtualAccountScreen> createState() => _VirtualAccountScreenState();
}

class _VirtualAccountScreenState extends State<VirtualAccountScreen> {
  WalletVirtuelAgentModel? _walletData;
  List<WalletVirtuelMouvementModel> _mouvements = [];
  bool _isLoadingWallet = true;
  bool _isLoadingMouvements = true;
  String? _walletError;
  int? _walletErrorStatusCode;
  String? _mouvementsError;
  int? _mouvementsErrorStatusCode;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  int? get _agentId => AuthService.currentUser?.utilisateur.agentId;

  Future<void> _loadAll({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoadingWallet = true;
        _isLoadingMouvements = true;
        _walletError = null;
        _walletErrorStatusCode = null;
        _mouvementsError = null;
        _mouvementsErrorStatusCode = null;
      });
    } else {
      setState(() {
        _mouvementsError = null;
        _mouvementsErrorStatusCode = null;
      });
    }

    await Future.wait([
      _loadWallet(silent: silent),
      _loadMouvements(silent: silent),
    ]);
  }

  Future<void> _loadWallet({bool silent = false}) async {
    final agentId = _agentId;
    if (agentId == null) {
      setState(() {
        _walletError = 'Agent non identifié';
        _walletErrorStatusCode = null;
        _isLoadingWallet = false;
      });
      return;
    }

    try {
      final response = await ApiService.getWalletVirtuelAgent(agentId);
      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _walletData = response.data;
          _walletError = null;
          _walletErrorStatusCode = null;
          _isLoadingWallet = false;
        });
      } else {
        setState(() {
          if (!silent || _walletData == null) {
            if (kDebugMode) {
              debugPrint(
                '[VirtualAccount/wallet] API error statusCode=${response.statusCode} message="${response.message}"',
              );
            }

            if (response.statusCode == 404) {
              _walletError =
                  'Vous n’avez pas de wallet virtuel. Veuillez contacter votre superviseur.';
            } else {
            _walletError = ApiErrorHelper.messageForWalletVirtuelError(
              statusCode: response.statusCode,
              serverMessage: response.message,
            );
            }
            _walletErrorStatusCode = response.statusCode;
          }
          _isLoadingWallet = false;
        });
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException(
        'VirtualAccount/wallet',
        e,
        stackTrace,
        false,
      );
      if (!mounted) return;
      setState(() {
        if (!silent || _walletData == null) {
          _walletError = ApiErrorHelper.userFacingNetwork();
          _walletErrorStatusCode = null;
        }
        _isLoadingWallet = false;
      });
    }
  }

  Future<void> _loadMouvements({bool silent = false}) async {
    final agentId = _agentId;
    if (agentId == null) {
      setState(() {
        _mouvementsError = 'Agent non identifié';
        _mouvementsErrorStatusCode = null;
        _isLoadingMouvements = false;
      });
      return;
    }

    if (!silent) {
      setState(() => _isLoadingMouvements = true);
    }

    try {
      final response = await ApiService.getWalletVirtuelMouvementsPaginated(
        agentId,
        page: 1,
        pageSize: 10,
        sortBy: 'dateOperation',
        sortDirection: 'desc',
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _mouvements = ApiService.parseWalletVirtuelMouvements(response.data);
          _mouvementsError = null;
          _mouvementsErrorStatusCode = null;
          _isLoadingMouvements = false;
        });
      } else {
        setState(() {
          if (!silent || _mouvements.isEmpty) {
            _mouvementsError = ApiErrorHelper.messageForWalletMouvementsError(
              statusCode: response.statusCode,
              serverMessage: response.message,
            );
            _mouvementsErrorStatusCode = response.statusCode;
          }
          _isLoadingMouvements = false;
        });
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException(
        'VirtualAccount/mouvements',
        e,
        stackTrace,
        false,
      );
      if (!mounted) return;
      setState(() {
        if (!silent || _mouvements.isEmpty) {
          _mouvementsError = ApiErrorHelper.userFacingNetwork();
          _mouvementsErrorStatusCode = null;
        }
        _isLoadingMouvements = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletFailed = _walletError != null && _walletData == null;

    return Scaffold(
      backgroundColor: AppColors.cardColor,
      appBar: AppBar(
        title: const Text(
          'Compte virtuel',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),

        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Historique',
            onPressed: () {
              final wallet = _walletData;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VirtualWalletMovementsScreen(
                    deviseId: wallet?.deviseId,
                    deviseCode: wallet?.deviseCode,
                    deviseSymbole: wallet?.deviseSymbole,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.history_rounded, size: 24),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: walletFailed && !_isLoadingWallet
          ? ProsocResourceErrorView(
              message: _walletError!,
              statusCode: _walletErrorStatusCode,
              onRetry: () => _loadAll(),
            )
          : RefreshIndicator(
              color: AppColors.prosocGreen,
              onRefresh: () => _loadAll(silent: _walletData != null),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildWalletSection(),
                  ),
                  SliverToBoxAdapter(
                    child: _buildSectionTitle('Opérations récentes'),
                  ),
                  _buildOperationsSliver(),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
    );
  }

  Widget _buildWalletSection() {
    if (_isLoadingWallet && _walletData == null) {
      return _buildWalletShimmer();
    }
    if (_walletData == null) {
      return const SizedBox.shrink();
    }
    return _buildBalanceCard();
  }

  String _formatWalletBalance(WalletVirtuelAgentModel wallet) {
    return CurrencyFormatter.format(
      amount: wallet.soldeVirtuel,
      deviseId: wallet.deviseId,
      deviseCode: wallet.deviseCode,
      deviseSymbole: wallet.deviseSymbole,
    );
  }

  Widget _buildWalletShimmer() {
    return Container(
      margin: const EdgeInsets.all(20),
      height: 160,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(28),
      ),
    );
  }

  Widget _buildBalanceCard() {
    final wallet = _walletData!;
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.prosocGreen.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Solde disponible',
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
              Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white54,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatWalletBalance(wallet),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MATRICULE',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Text(
                    wallet.agentMatricule.isNotEmpty ? wallet.agentMatricule : '—',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  wallet.statut ? 'ACTIF' : 'INACTIF',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildOperationsSliver() {
    if (_isLoadingMouvements && _mouvements.isEmpty) {
      return SliverToBoxAdapter(child: _buildMouvementsLoading());
    }

    if (_mouvementsError != null && _mouvements.isEmpty) {
      return SliverToBoxAdapter(child: _buildMouvementsError());
    }

    if (_mouvements.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyMouvements());
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index == _mouvements.length) {
            return const SizedBox(height: 8);
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildMovementCard(_mouvements[index], _walletData),
          );
        }, childCount: _mouvements.length + 1),
      ),
    );
  }

  Widget _buildMouvementsLoading() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.prosocGreen,
          ),
        ),
      ),
    );
  }

  Widget _buildMouvementsError() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ProsocResourceErrorView(
        message: _mouvementsError ?? 'Erreur de chargement',
        statusCode: _mouvementsErrorStatusCode,
        onRetry: () => _loadMouvements(),
        compact: true,
      ),
    );
  }

  Widget _buildEmptyMouvements() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.history_rounded, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Aucun mouvement récent',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementCard(
    WalletVirtuelMouvementModel movement,
    WalletVirtuelAgentModel? wallet,
  ) {
    final isPositive =
        movement.isCredit || (!movement.isDebit && movement.montant >= 0);
    final signedAmount = isPositive && !movement.isDebit
        ? movement.montant.abs()
        : movement.isDebit
            ? -movement.montant.abs()
            : movement.montant;

    return WalletMovementCard.fromVirtuelMovement(
      movement: movement,
      isPositive: isPositive,
      amountLabel: CurrencyFormatter.format(
        amount: signedAmount,
        deviseId: wallet?.deviseId,
        deviseCode: wallet?.deviseCode,
        deviseSymbole: wallet?.deviseSymbole,
        withSign: true,
      ),
    );
  }
}
