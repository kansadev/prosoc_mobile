import 'package:flutter/material.dart';
import 'package:prosoc/config/api.dart';
import 'package:prosoc/config/colors.dart';
import 'package:prosoc/models/wallet_mouvement_model.dart';
import 'package:prosoc/services/auth_service.dart';
import 'package:prosoc/utils/api_error_helper.dart';
import 'package:prosoc/utils/currency_formatter.dart';
import 'package:prosoc/views/widgets/wallet_movement_card.dart';

import 'wallet_mouvement_detail_screen.dart';

class WalletMovementsScreen extends StatefulWidget {
  const WalletMovementsScreen({super.key});

  @override
  State<WalletMovementsScreen> createState() => _WalletMovementsScreenState();
}

class _WalletMovementsScreenState extends State<WalletMovementsScreen> {
  static const int _pageSize = 20;

  final ScrollController _scrollController = ScrollController();

  List<WalletMouvementModel> _movements = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasNextPage = false;
  int _currentPage = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMovements(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int? get _agentId => AuthService.currentUser?.utilisateur.agentId;

  void _onScroll() {
    if (!_hasNextPage || _isLoadingMore || _isLoading) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMovements();
    }
  }

  Future<void> _loadMovements({bool reset = false}) async {
    final agentId = _agentId;
    if (agentId == null) {
      setState(() {
        _error = 'Agent non identifié';
        _isLoading = false;
        _isLoadingMore = false;
      });
      return;
    }

    if (reset) {
      setState(() {
        _isLoading = true;
        _isLoadingMore = false;
        _error = null;
        _currentPage = 1;
        _hasNextPage = false;
      });
    } else {
      if (!_hasNextPage || _isLoadingMore) return;
      setState(() => _isLoadingMore = true);
    }

    final pageToLoad = reset ? 1 : _currentPage + 1;

    try {
      final response = await ApiService.getWalletMouvementsPaginated(
        agentId,
        page: pageToLoad,
        pageSize: _pageSize,
        sortBy: 'dateOperation',
        sortDirection: 'desc',
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        final rows = ApiService.parseWalletMouvements(response.data);
        setState(() {
          if (reset) {
            _movements = rows;
          } else {
            _movements = [..._movements, ...rows];
          }
          _currentPage = pageToLoad;
          _hasNextPage = ApiService.parseHasNextPage(response.data);
          _error = null;
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          if (reset || _movements.isEmpty) {
            _error =
                response.message ??
                ApiErrorHelper.userFacingMessage(
                  statusCode: response.statusCode,
                );
          }
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('WalletMovements', e, stackTrace, false);
      if (!mounted) return;
      setState(() {
        if (reset || _movements.isEmpty) {
          _error = ApiErrorHelper.userFacingNetwork();
        }
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
        ),
        title: const Text(
          'Mouvements du wallet',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _movements.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.prosocGreen),
      );
    }

    if (_error != null && _movements.isEmpty) {
      return _buildErrorView();
    }

    if (_movements.isEmpty) {
      return RefreshIndicator(
        color: AppColors.prosocGreen,
        onRefresh: () => _loadMovements(reset: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            _buildEmptyView(),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.prosocGreen,
      onRefresh: () => _loadMovements(reset: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: _movements.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _movements.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
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
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildMovementCard(_movements[index]),
          );
        },
      ),
    );
  }

  void _openDetail(WalletMouvementModel movement) {
    if (movement.idWalletMouvement <= 0) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WalletMouvementDetailScreen(
          mouvementId: movement.idWalletMouvement,
          preview: movement,
        ),
      ),
    );
  }

  String _formatAmount(WalletMouvementModel movement, bool isPositive) {
    final signedAmount = isPositive && !movement.isDebit
        ? movement.montant.abs()
        : movement.isDebit
            ? -movement.montant.abs()
            : movement.montant;

    return CurrencyFormatter.formatMovementAmount(
      amount: signedAmount,
      deviseId: movement.deviseId > 0 ? movement.deviseId : null,
      deviseCode:
          movement.deviseCode.isNotEmpty ? movement.deviseCode : null,
      deviseSymbole: movement.deviseSymbole.isNotEmpty
          ? movement.deviseSymbole
          : null,
      withSign: true,
    );
  }

  Widget _buildMovementCard(WalletMouvementModel movement) {
    final isPositive =
        movement.isCredit || (!movement.isDebit && movement.montant >= 0);

    return WalletMovementCard.fromWalletMovement(
      movement: movement,
      amountLabel: _formatAmount(movement, isPositive),
      isPositive: isPositive,
      showDetailChevron: movement.idWalletMouvement > 0,
      onTap: movement.idWalletMouvement > 0
          ? () => _openDetail(movement)
          : null,
    );
  }

  Widget _buildEmptyView() {
    return Column(
      children: [
        Icon(
          Icons.account_balance_wallet_outlined,
          size: 64,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 16),
        Text(
          'Aucun mouvement',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Votre wallet n\'a pas encore de mouvements',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Impossible de charger les mouvements',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadMovements(reset: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.prosocGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
