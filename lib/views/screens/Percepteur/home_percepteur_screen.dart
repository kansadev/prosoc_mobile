import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:prosoc/config/api.dart';
import 'package:prosoc/config/colors.dart';
import 'package:prosoc/models/dashboard_percepteur_model.dart';
import 'package:prosoc/models/wallet_agent_model.dart';
import 'package:prosoc/services/auth_service.dart';
import 'package:prosoc/utils/api_error_helper.dart';
import 'package:prosoc/utils/wallet_agent_loader.dart';
import 'package:prosoc/views/screens/at/new_adhesion_screen.dart';
import 'dashboard_percepteur_screen.dart';
import 'percepteur_encaissement_choice_sheet.dart';
import 'percepteur_encaissement_screen.dart';
import 'percepteur_retraits_screen.dart';
import 'widgets/percepteur_wallet_overview_flip_card.dart';
import '../../widgets/prosoc_shimmer_loading.dart';

// ============================================
// ÉCRAN D'ACCUEIL PERCEPTEUR
// ============================================
class HomePercepteurScreen extends StatefulWidget {
  final int currentIndex;
  final Function(int) onIndexChanged;
  final VoidCallback? onOpenWallet;
  final VoidCallback? onOpenVirtualAccount;

  const HomePercepteurScreen({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
    this.onOpenWallet,
    this.onOpenVirtualAccount,
  });

  @override
  State<HomePercepteurScreen> createState() => _HomePercepteurScreenState();
}

class _HomePercepteurScreenState extends State<HomePercepteurScreen> {
  static const int _transactionsLimit = 5;

  DashboardPercepteurModel? _dashboard;
  List<PercepteurTransaction> _transactions = [];
  WalletAgentModel? _walletAgent;
  bool _isLoading = true;
  bool _isLoadingWallet = false;
  bool _isLoadingTransactions = false;
  bool _isUsdSelected = false;
  Set<int> _availableDeviseIds = {};
  Map<int, WalletAgentModel> _walletsByDevise = {};
  String? _errorMessage;

  bool get _hasAgentProfile => AuthService.isAgentTerrain;

  int get _selectedDeviseId =>
      _isUsdSelected ? WalletAgentDeviseIds.usd : WalletAgentDeviseIds.cdf;

  bool get _hasDiscoveredDevises => _availableDeviseIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  void _onDeviseChanged(bool isUsd) {
    if (_isUsdSelected == isUsd) return;
    setState(() => _isUsdSelected = isUsd);
    _loadWalletData(silent: true, singleDeviseOnly: true);
  }

  void _syncDeviseSelection(int deviseId) {
    _isUsdSelected = WalletAgentLoader.isUsdDeviseId(deviseId);
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _isLoading = true;
      _isLoadingTransactions = true;
      _errorMessage = null;
    });

    final futures = <Future<void>>[
      _loadDashboardSummary(),
      _loadRecentTransactions(silent: true),
    ];

    if (_hasAgentProfile) {
      futures.add(_loadWalletData(silent: true));
    }

    await Future.wait(futures);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDashboardSummary() async {
    try {
      final response = await ApiService.getDashboardPercepteurSummary();

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _dashboard = response.data;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = ApiErrorHelper.messageForApiFailure(
            statusCode: response.statusCode,
            serverDetail: response.message,
            fallback: 'Impossible de charger les données d\'accueil.',
          );
        });
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException(
        'HomePercepteur/summary',
        e,
        stackTrace,
        false,
      );
      if (!mounted) return;
      setState(() {
        _errorMessage = ApiErrorHelper.userFacingNetwork();
      });
    }
  }

  Future<void> _loadRecentTransactions({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoadingTransactions = true);
    }

    try {
      final response = await ApiService.getDashboardPercepteurTransactions(
        limit: _transactionsLimit,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _transactions = response.data!;
          _isLoadingTransactions = false;
        });
      } else {
        setState(() => _isLoadingTransactions = false);
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException(
        'HomePercepteur/transactions',
        e,
        stackTrace,
        false,
      );
      if (mounted) setState(() => _isLoadingTransactions = false);
    }
  }

  Future<void> _loadWalletData({
    bool silent = false,
    bool singleDeviseOnly = false,
  }) async {
    if (!_hasAgentProfile) return;

    final agentId = AuthService.agentId;
    if (agentId == null) {
      if (mounted) setState(() => _isLoadingWallet = false);
      return;
    }

    if (!silent) setState(() => _isLoadingWallet = true);

    try {
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
            );

      if (!mounted) return;

      setState(() {
        _availableDeviseIds = result.availableDeviseIds;
        _walletsByDevise = result.walletsByDevise;
        if (result.resolvedDeviseId != null) {
          _syncDeviseSelection(result.resolvedDeviseId!);
        }
        _walletAgent = _walletsByDevise[_selectedDeviseId] ?? result.wallet;
        _isLoadingWallet = false;
      });
    } catch (e, stackTrace) {
      ApiErrorHelper.logException(
        'HomePercepteur/wallet',
        e,
        stackTrace,
        false,
      );
      if (mounted) setState(() => _isLoadingWallet = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _buildHomeAppBar(context), body: _buildBody());
  }

  Widget _buildBody() {
    if (_isLoading && _dashboard == null) {
      return ProsocHomeShimmer.percepteur();
    }

    if (_errorMessage != null && _dashboard == null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      color: AppColors.prosocGreen,
      onRefresh: _loadHomeData,
      child: _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadHomeData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.prosocGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildHomeAppBar(BuildContext context) {
    final userName =
        AuthService.currentUser?.utilisateur.nomComplet ?? 'Percepteur';
    final greeting = _getGreeting();

    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 2,
      automaticallyImplyLeading: false,
      toolbarHeight: 84,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$greeting,',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications,
                color: AppColors.prosocGreen,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    final random = Random();

    const morningGreetings = [
      'Bonjour',
      'Bon début de journée',
      'Passez une excellente matinée',
    ];

    const afternoonGreetings = [
      'Bon après-midi',
      'Bonne suite de journée',
      'Ravi de vous revoir',
    ];

    const eveningGreetings = [
      'Bonsoir',
      'Bonne soirée',
      'Finissez bien votre journée',
    ];

    List<String> selectedList;

    if (hour >= 5 && hour < 12) {
      selectedList = morningGreetings;
    } else if (hour >= 12 && hour < 18) {
      selectedList = afternoonGreetings;
    } else {
      selectedList = eveningGreetings;
    }

    return selectedList[random.nextInt(selectedList.length)];
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMainOverviewCard(),
            const SizedBox(height: 24),
            Text(
              'Services Rapides',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildQuickServices(context),
            const SizedBox(height: 24),
            Text(
              'Activité Récente',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildRecentActivity(context),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildMainOverviewCard() {
    if (_hasAgentProfile) {
      final wallet = _walletsByDevise[_selectedDeviseId] ?? _walletAgent;
      final unavailableMessage = wallet == null && !_isLoadingWallet
          ? ApiErrorHelper.walletAgentUnavailableMessage(
              deviseId: _selectedDeviseId,
            )
          : null;

      return PercepteurWalletOverviewFlipCard(
        wallet: wallet,
        isLoadingWallet: _isLoadingWallet,
        isUsdSelected: _isUsdSelected,
        enableAllDevises: true,
        availableDeviseIds: _availableDeviseIds,
        walletUnavailableMessage: unavailableMessage,
        dashboard: _dashboard,
        onDeviseChanged: _onDeviseChanged,
      );
    }

    return _buildBalanceCard();
  }

  void _openDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DashboardPercepteurScreen(),
      ),
    );
  }

  Widget _buildBalanceCard() {
    final dashboard = _dashboard;
    final kpis = dashboard?.kpis;
    final formatMontant =
        kpis?.formatMontant ??
        (double value) => dashboard?.formatMontant(value) ?? '0 CDF';

    final montantTotal = kpis?.formattedMontantTotal ?? formatMontant(0);
    final montantMois = kpis?.formattedMontantMois ?? formatMontant(0);
    final agentsActifs = kpis?.nombreAgentsActifs ?? 0;
    final transactionsEnAttente = dashboard?.transactionsEnAttente ?? 0;
    final montantEnAttente = dashboard?.montantEnAttente ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.prosocGreen,
            AppColors.prosocGreen.withValues(alpha: 0.8),
          ],
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total perçu',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.account_balance, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    TextButton(
                      onPressed: _openDashboard,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Détails',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            montantTotal,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (dashboard != null && dashboard.soldeAPercevoir > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Solde à percevoir : ${formatMontant(dashboard.soldeAPercevoir)}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (transactionsEnAttente > 0) ...[
            const SizedBox(height: 8),
            Text(
              '$transactionsEnAttente en attente (${formatMontant(montantEnAttente)})',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              _buildMiniStat('Ce mois', montantMois, Icons.trending_up),
              const SizedBox(width: 24),
              _buildMiniStat('Agents actifs', '$agentsActifs', Icons.people),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickServices(BuildContext context) {
    final services = <_QuickService>[
      _QuickService(
        title: 'Encaisser',
        icon: Icons.add_circle,
        color: AppColors.prosocGreen,
        onTap: () => PercepteurEncaissementChoiceSheet.show(context),
      ),
      _QuickService(
        title: 'Souscription',
        icon: Icons.medical_services_outlined,
        color: Colors.purple,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PercepteurEncaissementScreen(
                souscriptionOnly: true,
              ),
            ),
          );
        },
      ),
      _QuickService(
        title: 'Retraits',
        icon: Icons.pending_actions_outlined,
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
      if (_hasAgentProfile)
        _QuickService(
          title: 'Adhésion',
          icon: Icons.person_add_alt_1,
          color: Colors.teal,
          onTap: () async {
            final created = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => const NewAdhesionScreen(),
              ),
            );
            if (created == true && mounted) {
              await _loadHomeData();
            }
          },
        ),
      _QuickService(
        title: 'Dashboard',
        icon: Icons.dashboard,
        color: Colors.blue,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DashboardPercepteurScreen(),
            ),
          );
        },
      ),
      if (!_hasAgentProfile)
        _QuickService(
          title: 'Réseau',
          icon: Icons.people,
          color: Colors.purple,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DashboardPercepteurScreen(),
              ),
            );
          },
        ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.72,
      children: services.map((service) {
        return InkWell(
          onTap: service.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: service.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(service.icon, color: service.color, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                service.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    if (_isLoadingTransactions && _transactions.isEmpty) {
      return ProsocHomeShimmer.activityList(
        context,
        itemCount: 3,
      );
    }

    final dashboard = _dashboard;
    final kpis = dashboard?.kpis;
    final formatMontant =
        kpis?.formatMontant ??
        (double value) => dashboard?.formatMontant(value) ?? '0 CDF';

    if (_transactions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 40,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Aucune activité récente',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Column(
      children: _transactions.map((transaction) {
        final dateLabel = transaction.dateTransaction != null
            ? dateFormat.format(transaction.dateTransaction!.toLocal())
            : '—';
        final subtitle = transaction.buildSubtitle();
        final displayAmount = transaction.netAPercevoir > 0
            ? transaction.netAPercevoir
            : transaction.montant;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.prosocGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  color: AppColors.prosocGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    Text(
                      dateLabel,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (displayAmount > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatMontant(displayAmount),
                      style: const TextStyle(
                        color: AppColors.prosocGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (transaction.commission > 0)
                      Text(
                        'Com. ${formatMontant(transaction.commission)}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _QuickService {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _QuickService({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
