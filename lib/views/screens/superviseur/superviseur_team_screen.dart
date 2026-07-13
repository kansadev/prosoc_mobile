import 'package:flutter/material.dart';

import '../../../config/colors.dart';
import '../../../models/dashboard_superviseur_model.dart';
import 'superviseur_controller.dart';
import 'superviseur_agent_details_screen.dart';
import 'widgets/superviseur_recharge_wallet_sheet.dart';
import '../../widgets/prosoc_resource_error_view.dart';
import '../../widgets/prosoc_shimmer_loading.dart';

class SuperviseurTeamScreen extends StatefulWidget {
  final SuperviseurController controller;

  const SuperviseurTeamScreen({super.key, required this.controller});

  @override
  State<SuperviseurTeamScreen> createState() => _SuperviseurTeamScreenState();
}

class _SuperviseurTeamScreenState extends State<SuperviseurTeamScreen> {
  List<SuperviseurAgentPerformance> _filtered = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
    _searchController.addListener(_applyFilter);
    _syncAgents();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    _searchController.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) _syncAgents();
  }

  List<SuperviseurAgentPerformance> get _agents {
    final hierarchie = widget.controller.hierarchie;
    if (hierarchie != null) {
      final fromHierarchie = hierarchie.allAgents;
      if (fromHierarchie.isNotEmpty) return fromHierarchie;
    }

    final kpis = widget.controller.kpis;
    if (kpis?.agentsSupervises.isNotEmpty == true) {
      return kpis!.agentsSupervises;
    }
    return widget.controller.dashboard?.agentsEquipe ?? const [];
  }

  SuperviseurHierarchieModel? get _hierarchie => widget.controller.hierarchie;

  void _syncAgents() {
    _applyFilter();
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    final agents = _agents;
    setState(() {
      if (query.isEmpty) {
        _filtered = List.from(agents);
      } else {
        _filtered = agents.where((agent) {
          return agent.nomAgent.toLowerCase().contains(query) ||
              agent.agentId.toString().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        widget.controller.isLoading && !widget.controller.hasLoaded;
    final errorMessage = widget.controller.errorMessage;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Mon équipe'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un agent…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _buildBody(isLoading, errorMessage),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isLoading, String? errorMessage) {
    if (isLoading) {
      return const ProsocLoadingShimmer.list(itemCount: 5);
    }

    final hasAgents = _agents.isNotEmpty;
    final hasError = errorMessage != null && !hasAgents;

    if (hasError) {
      return RefreshIndicator(
        color: AppColors.prosocGreen,
        onRefresh: () => widget.controller.load(force: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.12),
            ProsocResourceErrorView(
              message: errorMessage,
              statusCode: widget.controller.errorStatusCode,
              onRetry: () => widget.controller.load(force: true),
            ),
          ],
        ),
      );
    }

    if (_filtered.isEmpty && !hasAgents) {
      final hierarchie = _hierarchie;
      return RefreshIndicator(
        color: AppColors.prosocGreen,
        onRefresh: () => widget.controller.load(force: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            if (hierarchie != null) ...[
              _buildHierarchieSummary(hierarchie),
              const SizedBox(height: 16),
              ...hierarchie.sousSuperviseurs.map(_buildSousSuperviseurCard),
            ],
            if (hierarchie == null || hierarchie.sousSuperviseurs.isEmpty) ...[
              const SizedBox(height: 80),
              const Icon(Icons.groups_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Aucun agent dans votre équipe',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (_filtered.isEmpty) {
      return const Center(child: Text('Aucun résultat pour cette recherche'));
    }

    return RefreshIndicator(
      color: AppColors.prosocGreen,
      onRefresh: () => widget.controller.load(force: true),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: _listItemCount(),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _buildListItem(index),
      ),
    );
  }

  int _listItemCount() {
    var count = _filtered.length;
    if (_hierarchie != null) count += 1;
    return count;
  }

  Widget _buildListItem(int index) {
    if (_hierarchie != null) {
      if (index == 0) return _buildHierarchieSummary(_hierarchie!);
      return _buildAgentCard(_filtered[index - 1]);
    }
    return _buildAgentCard(_filtered[index]);
  }

  Widget _buildHierarchieSummary(SuperviseurHierarchieModel hierarchie) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.prosocGreen.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hierarchie.nomSuperviseur,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Niveau hiérarchique ${hierarchie.niveauHierarchique}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _summaryMetric(
                  '${hierarchie.totalAgentsDansHierarchie}',
                  'Agents',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryMetric(
                  hierarchie.formattedMontantHierarchie,
                  'Montant total',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryMetric(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSousSuperviseurCard(SuperviseurHierarchieModel sous) {
    final initial =
        sous.nomSuperviseur.isNotEmpty ? sous.nomSuperviseur[0].toUpperCase() : 'S';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.prosocGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
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
                  sous.nomSuperviseur,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Sous-superviseur · Niveau ${sous.niveauHierarchique}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${sous.totalAgentsDansHierarchie} agent(s)',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              Text(
                sous.formattedMontantHierarchie,
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgentCard(SuperviseurAgentPerformance agent) {
    final initial =
        agent.nomAgent.isNotEmpty ? agent.nomAgent[0].toUpperCase() : 'A';

    return InkWell(
      onTap: agent.agentId > 0 ? () => _openAgentDetails(agent) : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.prosocGreen.withValues(alpha: 0.12),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppColors.prosocGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agent.nomAgent,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Agent #${agent.agentId}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.prosocGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Rang ${agent.rangEquipe}',
                  style: const TextStyle(
                    color: AppColors.prosocGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _metricChip('Montant', '${agent.montantTotal.toStringAsFixed(0)}'),
              const SizedBox(width: 8),
              _metricChip('Tx', '${agent.nombreTransactions}'),
              const SizedBox(width: 8),
              _metricChip(
                  'Objectif', '${agent.atteinteObjectif.toStringAsFixed(0)}%'),
            ],
          ),
          if (agent.nombreJoursActifs > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${agent.nombreJoursActifs} jours actifs',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: agent.agentId > 0
                      ? () => _openAgentDetails(agent)
                      : null,
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('Voir détails'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: agent.agentId > 0
                      ? () => _openRechargeWallet(agent)
                      : null,
                  icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                  label: const Text('Recharger'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.prosocGreen,
                    side: BorderSide(
                      color: AppColors.prosocGreen.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  void _openAgentDetails(SuperviseurAgentPerformance agent) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SuperviseurAgentDetailsScreen(
          agentId: agent.agentId,
          agentNom: agent.nomAgent,
        ),
      ),
    );
  }

  Future<void> _openRechargeWallet(SuperviseurAgentPerformance agent) async {
    final recharged = await SuperviseurRechargeWalletSheet.show(
      context,
      agentId: agent.agentId,
      agentNom: agent.nomAgent,
    );
    if (!mounted || !recharged) return;
    await widget.controller.load(force: true);
  }

  Widget _metricChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
