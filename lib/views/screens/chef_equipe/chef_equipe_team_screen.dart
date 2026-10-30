import 'package:flutter/material.dart';

import '../../../config/api.dart';
import '../../../config/colors.dart';
import '../../../controllers/chef_equipe_controller.dart';
import '../../../models/chef_equipe_model.dart';
import '../../widgets/prosoc_resource_error_view.dart';
import 'chef_equipe_agent_details_screen.dart';

class ChefEquipeTeamScreen extends StatefulWidget {
  final ChefEquipeController controller;
  final void Function(int agentId, String agentNom) onOpenDetails;
  final bool embedded;

  const ChefEquipeTeamScreen({
    super.key,
    required this.controller,
    required this.onOpenDetails,
    this.embedded = false,
  });

  static Widget agentDetailsRoute({
    required int agentId,
    required String agentNom,
    required Future<void> Function() onLogout,
  }) {
    return ChefEquipeAgentDetailsScreen(
      agentId: agentId,
      agentNom: agentNom,
      onLogout: onLogout,
    );
  }

  @override
  State<ChefEquipeTeamScreen> createState() => _ChefEquipeTeamScreenState();
}

class _ChefEquipeTeamScreenState extends State<ChefEquipeTeamScreen> {
  final _searchController = TextEditingController();
  List<ChefEquipeAgentResumeDto> _filtered = [];

  /// Période affichée par agent : collecte du jour ou mois en cours.
  bool _voirJournee = true;

  /// Agrégats journaliers par agent (agentId → nombre + montant du jour).
  final Map<int, ({int nombre, double montant})> _collecteJour = {};
  bool _isLoadingJour = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
    _searchController.addListener(_applyFilter);
    _sync();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    _searchController.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    _sync();
  }

  void _sync() {
    _applyFilter();
    setState(() {});
    _loadCollecteJour();
  }

  List<ChefEquipeAgentResumeDto> get _agents {
    return widget.controller.agents;
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    final agents = _agents;
    if (query.isEmpty) {
      _filtered = List.from(agents);
      return;
    }

    _filtered = agents.where((a) {
      return a.nomComplet.toLowerCase().contains(query) ||
          a.matricule.toLowerCase().contains(query) ||
          a.agentId.toString().contains(query);
    }).toList();
  }

  /// Collecte du jour de chaque agent AT de la zone.
  ///
  /// La plateforme n'expose pas d'agrégat journalier par agent : on le calcule
  /// à partir des collectes récentes remontées par
  /// `GET /api/DashboardChefEquipe/agents/{agentId}/collectes`.
  Future<void> _loadCollecteJour() async {
    final agents = _agents;
    if (agents.isEmpty || _isLoadingJour) return;

    setState(() => _isLoadingJour = true);
    final today = DateTime.now();
    final jour = DateTime(today.year, today.month, today.day);

    final results = <int, ({int nombre, double montant})>{};
    for (final agent in agents) {
      if (!mounted) return;
      try {
        final response = await ApiService.getChefEquipeCollectes(
          agent.agentId,
          limit: 100,
        );
        if (!response.success || response.data == null) continue;
        var nombre = 0;
        var montant = 0.0;
        for (final collecte in response.data!) {
          final date = collecte.dateCollecte;
          if (date == null) continue;
          final d = date.toLocal();
          if (d.year == jour.year &&
              d.month == jour.month &&
              d.day == jour.day) {
            nombre++;
            montant += collecte.montant;
          }
        }
        results[agent.agentId] = (nombre: nombre, montant: montant);
      } catch (_) {
        // Un agent en échec ne bloque pas l'agrégat des autres.
      }
    }

    if (!mounted) return;
    setState(() {
      _collecteJour
        ..clear()
        ..addAll(results);
      _isLoadingJour = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
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
              const SizedBox(width: 10),
              _PeriodToggle(
                journee: _voirJournee,
                onChanged: (value) => setState(() => _voirJournee = value),
              ),
            ],
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    );

    if (widget.embedded) {
      return ColoredBox(color: const Color(0xFFF5F7FA), child: content);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Équipe'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: content,
    );
  }

  Widget _buildBody() {
    if (widget.controller.errorMessage != null) {
      return ProsocResourceErrorView(
        message: widget.controller.errorMessage!,
        statusCode: widget.controller.errorStatusCode,
        onRetry: () => widget.controller.load(force: true),
      );
    }

    final isLoading =
        widget.controller.isLoading && !widget.controller.hasLoaded;
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.prosocGreen),
      );
    }

    final agents = _agents;
    if (agents.isEmpty) {
      return RefreshIndicator(
        color: AppColors.prosocGreen,
        onRefresh: () => widget.controller.load(force: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          children: const [
            SizedBox(height: 40),
            Center(
              child: Text(
                'Aucun agent AT dans votre zone.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.prosocGreen,
      onRefresh: () => widget.controller.load(force: true),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: _filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final agent = _filtered[index];
          return _buildAgentCard(agent);
        },
      ),
    );
  }

  Widget _buildAgentCard(ChefEquipeAgentResumeDto agent) {
    final initials = agent.nomComplet.trim().isNotEmpty
        ? agent.nomComplet.trim()[0].toUpperCase()
        : 'A';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => widget.onOpenDetails(agent.agentId, agent.nomComplet),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.prosocGreen.withValues(alpha: 0.12),
                child: Text(
                  initials,
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
                      agent.nomComplet,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      agent.matricule,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _voirJournee
                        ? '${_collecteJour[agent.agentId]?.nombre ?? agent.collectesJour ?? 0}'
                        : '${agent.collectesMois}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _voirJournee ? 'coll. du jour' : 'coll. du mois',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Text(
                _voirJournee
                    ? '${(_collecteJour[agent.agentId]?.montant ?? agent.montantJour ?? 0).toStringAsFixed(0)}'
                    : agent.totalCollectesMois.toStringAsFixed(0),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.prosocGreen,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Ancien layout détaillé des métriques supprimé pour une liste plus simple.
}

/// Bascule Journée / Mois pour le suivi des collectes par agent.
class _PeriodToggle extends StatelessWidget {
  final bool journee;
  final ValueChanged<bool> onChanged;

  const _PeriodToggle({required this.journee, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _segment('Jour', journee, () => onChanged(true)),
          _segment('Mois', !journee, () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _segment(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.prosocGreen : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
