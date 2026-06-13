import 'package:flutter/material.dart';

import '../../../config/colors.dart';
import '../../../models/dashboard_superviseur_model.dart';
import 'superviseur_controller.dart';

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
    final kpis = widget.controller.kpis;
    if (kpis?.agentsSupervises.isNotEmpty == true) {
      return kpis!.agentsSupervises;
    }
    return widget.controller.dashboard?.agentsEquipe ?? const [];
  }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => widget.controller.load(force: true),
          ),
        ],
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
      return const Center(
        child: CircularProgressIndicator(color: AppColors.prosocGreen),
      );
    }

    if (_filtered.isEmpty && _agents.isEmpty) {
      return RefreshIndicator(
        color: AppColors.prosocGreen,
        onRefresh: () => widget.controller.load(force: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 120),
            Icon(Icons.groups_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Center(
              child: Text(
                errorMessage ?? 'Aucun agent dans votre équipe',
                textAlign: TextAlign.center,
              ),
            ),
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
        itemCount: _filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _buildAgentCard(_filtered[index]),
      ),
    );
  }

  Widget _buildAgentCard(SuperviseurAgentPerformance agent) {
    final initial =
        agent.nomAgent.isNotEmpty ? agent.nomAgent[0].toUpperCase() : 'A';

    return Container(
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
        ],
      ),
    );
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
