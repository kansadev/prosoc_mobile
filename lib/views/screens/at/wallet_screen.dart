import 'package:flutter/material.dart';
import '../../../config/colors.dart';
import '../../../services/auth_service.dart';
import '../../../models/wallet_agent_model.dart';
import '../../../utils/api_error_helper.dart';
import '../../../utils/wallet_agent_loader.dart';
import 'withdrawal_screen.dart';
import 'token_screen.dart';
import 'wallet_mouvements_screen.dart';
import '../../widgets/prosoc_resource_error_view.dart';
import '../../widgets/wallet_devise_switch.dart';


class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  WalletAgentModel? _walletData;
  bool _isLoading = true;
  String? _errorMessage;
  int? _errorStatusCode;
  bool _isUsdSelected = false;
  Set<int> _availableDeviseIds = {};
  Map<int, WalletAgentModel> _walletsByDevise = {};

  int get _selectedDeviseId => _isUsdSelected
      ? WalletAgentDeviseIds.usd
      : WalletAgentDeviseIds.cdf;

  bool get _hasDiscoveredDevises => _availableDeviseIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  void _onDeviseChanged(bool isUsd) {
    if (_isUsdSelected == isUsd) return;
    setState(() => _isUsdSelected = isUsd);
    _loadWalletData(silent: _walletData != null, singleDeviseOnly: true);
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
        _errorMessage = null;
        _errorStatusCode = null;
      });
    }

    try {
      final agentId = AuthService.currentUser?.utilisateur.agentId;

      if (agentId == null) {
        setState(() {
          _errorMessage = 'Agent non identifié';
          _errorStatusCode = null;
          _isLoading = false;
        });
        return;
      }

      final result = singleDeviseOnly && _hasDiscoveredDevises
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

      if (result.hasWallet) {
        setState(() {
          _walletData = result.wallet;
          _availableDeviseIds = result.availableDeviseIds;
          _walletsByDevise = result.walletsByDevise;
          if (result.resolvedDeviseId != null) {
            _syncDeviseSelection(result.resolvedDeviseId!);
          }
          _errorMessage = null;
          _errorStatusCode = null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _availableDeviseIds = result.availableDeviseIds;
          _walletsByDevise = result.walletsByDevise;
          if (!silent || _walletData == null) {
            _errorMessage = result.errorMessage ??
                ApiErrorHelper.messageForWalletAgentError(
                  statusCode: result.errorStatusCode,
                );
            _errorStatusCode = result.errorStatusCode;
          }
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('WalletScreen', e, stackTrace, false);
      setState(() {
        if (!silent || _walletData == null) {
          _errorMessage = ApiErrorHelper.userFacingNetwork();
          _errorStatusCode = null;
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
        SliverToBoxAdapter(
          child: _buildHeader(context),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading && _walletData == null
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.prosocGreen,
                ),
              )
            : _errorMessage != null && _walletData == null
                ? _buildRefreshableBody([
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildErrorView(),
                    ),
                  ])
                : _buildRefreshableBody(_walletSlivers(context)),
      ),
    );
  }

  Widget _buildErrorView() {
    return ProsocResourceErrorView(
      message: _errorMessage ?? 'Une erreur est survenue',
      statusCode: _errorStatusCode,
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
              _walletData?.formattedSolde ?? '0.00',
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
                _buildWalletInfo('Numéro', _walletData?.agentMatricule ?? 'N/A'),
                WalletDeviseSwitch(
                  isUsdSelected: _isUsdSelected,
                  availableDeviseIds:
                      _hasDiscoveredDevises ? _availableDeviseIds : null,
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
                icon: Icons.generating_tokens_rounded,
                label: 'Jeton',
                color: AppColors.prosocGreen,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TokenScreen()),
                  );
                },
              ),
              _buildActionButton(
                icon: Icons.sync_alt_rounded,
                label: 'Mouvement',
                color: AppColors.prosocGreen,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WalletMovementsScreen()),
                  );
                },
              ),
              _buildActionButton(
                icon: Icons.qr_code,
                label: 'Scanner',
                color: AppColors.prosocGreen,
                onTap: () {},
              ),
            ],
          ),
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
          soldeDisponible: _walletData?.soldeCourant,
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
