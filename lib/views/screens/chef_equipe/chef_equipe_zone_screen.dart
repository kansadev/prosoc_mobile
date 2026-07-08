import 'package:flutter/material.dart';

import '../../../config/colors.dart';
import '../../../controllers/chef_equipe_controller.dart';
import 'chef_equipe_kpis_screen.dart';
import 'chef_equipe_team_screen.dart';

/// Onglet « Zone » — vue analytique + liste d'équipe (sans tabs).
class ChefEquipeZoneScreen extends StatelessWidget {
  final ChefEquipeController controller;
  final void Function(int agentId, String agentNom) onOpenAgentDetails;

  const ChefEquipeZoneScreen({
    super.key,
    required this.controller,
    required this.onOpenAgentDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Ma zone'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 1, thickness: 1),
          Expanded(
            flex: 5,
            child: ChefEquipeKpisScreen(controller: controller),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Text(
                  'Équipe',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(width: 8),
                AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) {
                    final count = controller.agents.length;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.prosocGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: AppColors.prosocGreen,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: ChefEquipeTeamScreen(
              controller: controller,
              onOpenDetails: onOpenAgentDetails,
              embedded: true,
            ),
          ),
        ],
      ),
    );
  }
}
