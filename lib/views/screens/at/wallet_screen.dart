import 'package:flutter/material.dart';
import '../../../config/colors.dart';
import '../../../services/auth_service.dart';
import '../../../models/wallet_agent_model.dart';
import '../../../utils/api_error_helper.dart';
import '../../../utils/wallet_agent_loader.dart';
import 'withdrawal_screen.dart';
import '../Percepteur/percepteur_retraits_screen.dart';
import 'wallet_mouvements_screen.dart';
import 'collecte_historique_screen.dart';
import 'my_network_screen.dart';
import '../Percepteur/percepteur_transactions_screen.dart';
import '../../widgets/prosoc_resource_error_view.dart';
import '../../widgets/wallet_devise_switch.dart';


class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _isLoading = true;
  String? _criticalErrorMessage;
  bool _isUsdSelected = false;
  Set<int> _availableDeviseIds = {};
  Map<int, WalletAgentModel> _walletsByDevise = {};

  int get _selectedDeviseId => _isUsdSelected
      ? WalletAgentDeviseIds.usd
      : WalletAgentDeviseIds.cdf;

  WalletAgentModel? get _walletForSelectedDevise =>
      _walletsByDevise[_selectedDeviseId];

  String? get _unavailableMessageForSelectedDevise {
    if (_isLoading) return null;
    if (_walletForSelectedDevise != null) return null;
    return ApiErrorHelper.walletAgentUnavailableMessage(
      deviseId: _selectedDeviseId,
    );
  }

  bool get _hasAnyWallet => _availableDeviseIds.isNotEmpty;

  bool get _isPercepteur => AuthService.isPercepteur;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  void _onDeviseChanged(bool isUsd) {
    if (_isUsdSelected == isUsd) return;
    setState(() => _isUsdSelected = isUsd);
    _loadWalletData(silent: _hasAnyWallet, singleDeviseOnly: true);
  }

  void _syncDeviseSelection(int deviseId) {
    _isUsdSelected = WalletAgentLoader.isUsdDeviseId(deviseId);
  }

  Future<void> _loadWalletData({
    bool silent = false,
    bool singleDeviseOnly = false,
  }) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _criticalErrorMessage = null;
      });
    }

    try {
      final agentId = AuthService.currentUser?.utilisateur.agentId;

      if (agentId == null) {
        setState(() {
          _criticalErrorMessage = 'Agent non identifié';
          _isLoading = false;
        });
        return;
      }

      final result = singleDeviseOnly
          ? await WalletAgentLoader.loadSingleDevise(
              agentId: agentId,
              deviseId: _selectedDeviseId,
              availableDeviseIds: _availableDeviseIds,
              cachedWallets: _walletsByDevise,
            )
          : await WalletAgentLoader.load(
              agentId: agentId,
              preferredDeviseId: _selectedDeviseId,
              cachedWallets: singleDeviseOnly ? _walletsByDevise : null,
            );

      setState(() {
        _availableDeviseIds = result.availableDeviseIds;
        _walletsByDevise = result.walletsByDevise;
        if (result.resolvedDeviseId != null && !singleDeviseOnly) {
          _syncDeviseSelection(result.resolvedDeviseId!);
        }
        _criticalErrorMessage = null;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('WalletScreen', e, stackTrace, false);
      setState(() {
        if (!silent || !_hasAnyWallet) {
          _criticalErrorMessage = ApiErrorHelper.userFacingNetwork();
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() => _loadWalletData(silent: true);

  Widget _buildRefreshableBody(List<Widget> slivers) {
    return RefreshIndicator(
      color: AppColors.prosocGreen,
      onRefresh: _onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: slivers,
      ),
    );
  }

  List<Widget> _walletSlivers(BuildContext context) => [
        if (!_isPercepteur)
          SliverToBoxAdapter(
            child: _buildHeader(context),
          ),
        if (_isPercepteur)
          const SliverToBoxAdapter(
            child: SizedBox(height: 8),
          ),
        SliverToBoxAdapter(
          child: _buildWalletCard(),
        ),
        SliverToBoxAdapter(
          child: _buildQuickActions(),
        ),
        SliverToBoxAdapter(
          child: _buildRecentTransactions(),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ];

  PreferredSizeWidget? _buildAppBar() {
    if (!_isPercepteur) return null;

    return AppBar(
      title: const Text(
        'Mon Wallet',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      foregroundColor: AppColors.textPrimary,
      actions: [
        IconButton(
          tooltip: 'Historique',
          onPressed: _openHistorique,
          icon: const Icon(Icons.history_rounded),
        ),
      ],
    );
  }

  void _openHistorique() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _isPercepteur
            ? const PercepteurTransactionsScreen()
            : const CollecteHistoriqueScreen(),
      ),
    );
  }

  void _openMonReseau() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyNetworkScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      child: _criticalErrorMessage != null
          ? _buildRefreshableBody([
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildErrorView(),
              ),
            ])
          : _isLoading && !_hasAnyWallet
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.prosocGreen,
                  ),
                )
              : _buildRefreshableBody(_walletSlivers(context)),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: body,
    );
  }

  Widget _buildErrorView() {
    return ProsocResourceErrorView(
      message: _criticalErrorMessage ?? 'Une erreur est survenue',
      onRetry: () => _loadWalletData(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mon Wallet',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Gérez vos fonds et transactions',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.prosocGreen, Color(0xFF1E8A4A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.prosocGreen.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Solde disponible',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _unavailableMessageForSelectedDevise ??
                  (_walletForSelectedDevise?.formattedSoldeDisponible ??
                      '0.00'),
              style: TextStyle(
                color: Colors.white,
                fontSize: _unavailableMessageForSelectedDevise != null ? 15 : 32,
                fontWeight: FontWeight.bold,
                height: _unavailableMessageForSelectedDevise != null ? 1.35 : 1.1,
              ),
            ),
            if (_walletForSelectedDevise != null &&
                _unavailableMessageForSelectedDevise == null) ...[
              const SizedBox(height: 8),
              Text(
                'Solde courant : ${_walletForSelectedDevise!.formattedSolde}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                ),
              ),
              if (_walletForSelectedDevise!.hasRetenue) ...[
                const SizedBox(height: 4),
                Text(
                  'Retenues à la source appliquées',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildWalletInfo(
                  'Numéro',
                  _walletForSelectedDevise?.agentMatricule ?? 'N/A',
                ),
                WalletDeviseSwitch(
                  isUsdSelected: _isUsdSelected,
                  enableAllDevises: false,
                  availableDeviseIds: _availableDeviseIds,
                  onChanged: _onDeviseChanged,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actions rapides',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (_isPercepteur)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: Icons.pending_actions_outlined,
                  label: 'Retraits agents',
                  color: const Color(0xFFE65100),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PercepteurRetraitsScreen(),
                      ),
                    );
                  },
                ),
                if (AuthService.isAgentTerrain)
                  _buildActionButton(
                    icon: Icons.account_balance_wallet,
                    label: 'Ma demande',
                    color: AppColors.prosocGreen,
                    onTap: () => _openWithdrawalScreen(context),
                  ),
                _buildActionButton(
                  icon: Icons.sync_alt_rounded,
                  label: 'Mouvement',
                  color: AppColors.prosocGreen,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WalletMovementsScreen(),
                      ),
                    );
                  },
                ),
                _buildActionButton(
                  icon: Icons.people_outline,
                  label: 'Mon réseau',
                  color: AppColors.prosocGreen,
                  onTap: _openMonReseau,
                ),
              ],
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: Icons.account_balance_wallet,
                  label: 'Retrait',
                  color: AppColors.prosocGreen,
                  onTap: () => _openWithdrawalScreen(context),
                ),
                _buildActionButton(
                  icon: Icons.sync_alt_rounded,
                  label: 'Mouvement',
                  color: AppColors.prosocGreen,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WalletMovementsScreen(),
                      ),
                    );
                  },
                ),
                _buildActionButton(
                  icon: Icons.history_rounded,
                  label: 'Historique',
                  color: AppColors.prosocGreen,
                  onTap: _openHistorique,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openWithdrawalScreen(BuildContext context) async {
    final refreshed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => WithdrawalScreen(
          initialDeviseId: _selectedDeviseId,
          initialWalletsByDevise: _walletsByDevise,
        ),
      ),
    );
    if (refreshed == true && mounted) {
      await _loadWalletData(silent: true);
    }
  }

  Widget _buildRecentTransactions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transactions récentes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Aucune transaction récente',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
