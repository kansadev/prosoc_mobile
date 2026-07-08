import 'package:flutter/foundation.dart';

import '../config/api.dart';
import '../models/chef_equipe_model.dart';
import '../utils/api_error_helper.dart';

/// Controller partagé pour l'espace Chef d'équipe (zone sociale).
class ChefEquipeController extends ChangeNotifier {
  ChefEquipeKpisDto? kpis;
  List<ChefEquipeAgentResumeDto> agents = [];

  bool isLoading = false;
  bool hasLoaded = false;
  String? errorMessage;
  int? errorStatusCode;

  final Future<void> Function() _onLogout;

  ChefEquipeController({
    required Future<void> Function() onLogout,
  }) : _onLogout = onLogout;

  Future<void> load({bool force = false}) async {
    if (isLoading) return;
    if (hasLoaded && !force) return;

    isLoading = true;
    errorMessage = null;
    errorStatusCode = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        ApiService.getChefEquipeKpis(),
        ApiService.getChefEquipeAgents(),
      ]);

      final kpisResponse = results[0] as ApiResponse<ChefEquipeKpisDto>;
      final agentsResponse =
          results[1] as ApiResponse<List<ChefEquipeAgentResumeDto>>;

      if (kpisResponse.success) kpis = kpisResponse.data;
      if (agentsResponse.success && agentsResponse.data != null) {
        agents = agentsResponse.data!;
      } else {
        agents = [];
      }

      // Gestion UX auth
      if (!kpisResponse.success && kpisResponse.statusCode == 401) {
        await _onLogout();
        return;
      }
      if (!agentsResponse.success && agentsResponse.statusCode == 401) {
        await _onLogout();
        return;
      }
      if (!kpisResponse.success && kpisResponse.statusCode == 403) {
        errorMessage = 'Accès refusé (hors périmètre)';
        errorStatusCode = 403;
      }
      if (!agentsResponse.success && agentsResponse.statusCode == 403) {
        errorMessage = 'Accès refusé (hors périmètre)';
        errorStatusCode = 403;
      }

      if (!kpisResponse.success &&
          !agentsResponse.success &&
          (kpisResponse.statusCode != 401 &&
              agentsResponse.statusCode != 401)) {
        errorMessage = kpisResponse.message ??
            agentsResponse.message ??
            'Impossible de charger les données Chef d\'équipe.';
        errorStatusCode = kpisResponse.statusCode ?? agentsResponse.statusCode;
      }

      hasLoaded = true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('ChefEquipeController/load error: $e');
      }
      ApiErrorHelper.logException('ChefEquipeController/load', e, stackTrace);
      errorMessage = ApiErrorHelper.userFacingNetwork();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

