import '../../../config/api.dart';
import '../../../models/agent_model.dart';
import '../../../utils/api_error_helper.dart';

/// Agents de l'équipe d'un superviseur, pour l'affectation / réaffectation.
class SuperviseurAgentsResult {
  const SuperviseurAgentsResult({required this.agents, this.erreur});

  final List<AgentModel> agents;

  /// Message à afficher quand aucun agent n'a pu être chargé.
  final String? erreur;
}

abstract final class SuperviseurAgentsLoader {
  /// La hiérarchie (`Superviseur/hierarchie`, contrat retenu par le backend)
  /// d'abord ; `Agents/by-superviseur` en repli, car il refuse les superviseurs
  /// rattachés par commune. Le serveur reste juge de chaque affectation.
  static Future<SuperviseurAgentsResult> load(int superviseurId) async {
    final hierarchie = await ApiService.getSuperviseurHierarchie(superviseurId);
    if (hierarchie.success && hierarchie.data != null) {
      final vus = <int>{};
      final agents = <AgentModel>[];
      for (final a in hierarchie.data!.allAgents) {
        if (a.agentId <= 0 || !vus.add(a.agentId)) continue;
        agents.add(
          AgentModel.fromJson({'agentId': a.agentId, 'nomComplet': a.nomAgent}),
        );
      }
      if (agents.isNotEmpty) return SuperviseurAgentsResult(agents: agents);
    }

    final direct = await ApiService.getAgentsBySuperviseur(superviseurId);
    if (direct.success && (direct.data?.isNotEmpty ?? false)) {
      return SuperviseurAgentsResult(agents: direct.data!);
    }

    final message = ApiErrorHelper.messageForSuperviseurTeamError(
      statusCode: direct.statusCode ?? hierarchie.statusCode,
      serverMessage: direct.message ?? hierarchie.message,
    );
    return SuperviseurAgentsResult(
      agents: const [],
      erreur: direct.success && hierarchie.success
          ? 'Aucun agent dans votre équipe : l\'affectation est impossible.'
          : message,
    );
  }
}
