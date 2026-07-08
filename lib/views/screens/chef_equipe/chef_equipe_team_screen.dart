import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final content = Column(
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
        Expanded(child: _buildBody()),
      ],
    );

    if (widget.embedded) {
      return ColoredBox(
        color: const Color(0xFFF5F7FA),
        child: content,
      );
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

    final isLoading = widget.controller.isLoading && !widget.controller.hasLoaded;
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

