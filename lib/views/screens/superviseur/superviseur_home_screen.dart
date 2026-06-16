import 'package:flutter/material.dart';

import '../../../config/api.dart';
import '../../../config/colors.dart';
import '../../../models/dashboard_superviseur_model.dart';
import '../../../models/wallet_agent_model.dart';
import '../../../services/auth_service.dart';
import '../../../utils/api_error_helper.dart';
import '../../../utils/wallet_agent_loader.dart';
import '../at/new_adhesion_screen.dart';
import 'superviseur_controller.dart';
import 'superviseur_top_agents_screen.dart';
import 'widgets/superviseur_indicateurs_section.dart';
import 'widgets/superviseur_wallet_overview_flip_card.dart';

class SuperviseurHomeScreen extends StatefulWidget {
  final SuperviseurController controller;
  final VoidCallback? onOpenTeam;
  final VoidCallback? onOpenPerformance;
  final VoidCallback? onOpenNetwork;
  final VoidCallback? onOpenWallet;
  final VoidCallback? onOpenVirtualAccount;

  const SuperviseurHomeScreen({
    super.key,
    required this.controller,
    this.onOpenTeam,
    this.onOpenPerformance,
    this.onOpenNetwork,
    this.onOpenWallet,
    this.onOpenVirtualAccount,
  });

  @override
  State<SuperviseurHomeScreen> createState() => _SuperviseurHomeScreenState();
}

class _SuperviseurHomeScreenState extends State<SuperviseurHomeScreen> {
  WalletAgentModel? _walletAgent;
  bool _isLoadingWallet = true;
  bool _isUsdSelected = false;
  Set<int> _availableDeviseIds = {};
  Map<int, WalletAgentModel> _walletsByDevise = {};

  int get _selectedDeviseId =>
      _isUsdSelected ? WalletAgentDeviseIds.usd : WalletAgentDeviseIds.cdf;

  bool get _hasDiscoveredDevises => _availableDeviseIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (AuthService.isAgentTerrain) {
      _loadWalletData();
    } else {
      _isLoadingWallet = false;
    }
  }

  void _onDeviseChanged(bool isUsd) {
    if (_isUsdSelected == isUsd) return;
    setState(() => _isUsdSelected = isUsd);
    _loadWalletData(silent: true, singleDeviseOnly: true);
  }

  void _syncDeviseSelection(int deviseId) {
    _isUsdSelected = WalletAgentLoader.isUsdDeviseId(deviseId);
  }

  Future<void> _loadWalletData({
    bool silent = false,
    bool singleDeviseOnly = false,
  }) async {
    if (!AuthService.isAgentTerrain) return;

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
        'SuperviseurHome/wallet',
        e,
        stackTrace,
        false,
      );
      if (mounted) setState(() => _isLoadingWallet = false);
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      widget.controller.load(force: true),
      if (AuthService.isAgentTerrain) _loadWalletData(silent: true),
    ]);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Bonjour';
    if (hour >= 12 && hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final kpis = widget.controller.kpis;
        final indicateurs = widget.controller.indicateurs;
        final isLoading =
            widget.controller.isLoading && !widget.controller.hasLoaded;

        final userName = kpis?.nomSuperviseur.isNotEmpty == true
            ? kpis!.nomSuperviseur
            : (AuthService.currentUser?.utilisateur.nomComplet ??
                  'Superviseur');

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            toolbarHeight: 84,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()},',
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
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.prosocGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.supervisor_account,
                        color: AppColors.prosocGreen,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Superviseur',
                        style: TextStyle(
                          color: AppColors.prosocGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            color: AppColors.prosocGreen,
            onRefresh: _onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AuthService.isAgentTerrain
                      ? SuperviseurWalletOverviewFlipCard(
                          wallet: _walletsByDevise[_selectedDeviseId] ??
                              _walletAgent,
                          isLoadingWallet: _isLoadingWallet,
                          isUsdSelected: _isUsdSelected,
                          enableAllDevises: true,
                          walletUnavailableMessage:
                              !_isLoadingWallet &&
                                      (_walletsByDevise[_selectedDeviseId] ??
                                              _walletAgent) ==
                                          null
                                  ? ApiErrorHelper.walletAgentUnavailableMessage(
                                      deviseId: _selectedDeviseId,
                                    )
                                  : null,
                          onDeviseChanged: _onDeviseChanged,
                          onOpenWallet: widget.onOpenWallet,
                          kpis: kpis,
                        )
                      : _buildOverviewCard(kpis),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Activité terrain',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildTerrainActions(context),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Supervision',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSupervisionActions(context),
                ),
                const SizedBox(height: 24),
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                        color: AppColors.prosocGreen,
                      ),
                    ),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildStatsGrid(kpis),
                  ),
                  if (kpis?.agentsSupervises.isNotEmpty == true) ...[
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Agents supervisés',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...kpis!.agentsSupervises
                        .take(3)
                        .map(
                          (a) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildAgentPreview(a),
                          ),
                        ),
                  ],
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewCard(StatsSuperviseur? kpis) {
    final montant = kpis?.formattedMontantEquipe ?? '—';
    final performance = kpis?.formattedPerformance ?? '—';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.prosocGreen,
            AppColors.prosocGreen.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.prosocGreen.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vue d\'ensemble équipe',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            montant,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Montant total • Perf. moyenne $performance',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _miniStat(
                'Agents directs',
                '${kpis?.nombreAgentsDirects ?? '—'}',
              ),
              const SizedBox(width: 12),
              _miniStat('Total équipe', '${kpis?.nombreAgentsTotal ?? '—'}'),
              const SizedBox(width: 12),
              _miniStat('Taux succès', kpis?.formattedTauxSucces ?? '—'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTerrainActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _actionTile(
            icon: Icons.person_add_alt_1,
            label: 'Adhésion',
            color: AppColors.prosocGreen,
            onTap: () async {
              await Navigator.push<bool>(
                context,
                MaterialPageRoute<bool>(
                  builder: (_) => const NewAdhesionScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionTile(
            icon: Icons.people_outline,
            label: 'Mon réseau',
            color: const Color(0xFF2196F3),
            onTap: widget.onOpenNetwork,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionTile(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Wallet',
            color: const Color(0xFFFF9800),
            onTap: widget.onOpenWallet,
          ),
        ),
      ],
    );
  }

  Widget _buildSupervisionActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _actionTile(
            icon: Icons.groups,
            label: 'Mon équipe',
            color: const Color(0xFF2196F3),
            onTap: widget.onOpenTeam,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionTile(
            icon: Icons.insights_outlined,
            label: 'Performance',
            color: const Color(0xFF9C27B0),
            onTap: widget.onOpenPerformance,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionTile(
            icon: Icons.emoji_events_outlined,
            label: 'Top agents',
            color: const Color(0xFF607D8B),
            onTap: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const SuperviseurTopAgentsScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(StatsSuperviseur? kpis) {
    if (kpis == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Impossible de charger les KPIs superviseur.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: [
        _statCard(
          'Transactions',
          '${kpis.nombreTransactionsSuperviseur}',
          Icons.receipt_long,
        ),
        _statCard(
          'Objectif',
          kpis.formattedAtteinteObjectif,
          Icons.flag_outlined,
        ),
        _statCard(
          'Agents total',
          '${kpis.nombreAgentsTotal}',
          Icons.account_tree_outlined,
        ),
        _statCard(
          'Montant superviseur',
          '${kpis.montantTotalSuperviseur.toStringAsFixed(0)}',
          Icons.payments_outlined,
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppColors.prosocGreen, size: 22),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[600], fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentPreview(SuperviseurAgentPerformance agent) {
    final initial = agent.nomAgent.isNotEmpty
        ? agent.nomAgent[0].toUpperCase()
        : 'A';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.prosocGreen.withValues(alpha: 0.12),
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.prosocGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agent.nomAgent,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Rang ${agent.rangEquipe} • ${agent.montantTotal.toStringAsFixed(0)} CDF',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${agent.atteinteObjectif.toStringAsFixed(0)}%',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.prosocGreen,
            ),
          ),
        ],
      ),
    );
  }
}
