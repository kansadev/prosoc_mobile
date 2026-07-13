import 'package:flutter/foundation.dart';

import '../../../config/api.dart';
import '../../../models/dashboard_superviseur_model.dart';
import '../../../services/auth_service.dart';
import '../../../utils/api_error_helper.dart';

/// Données superviseur partagées entre les onglets (un seul chargement API).
class SuperviseurController extends ChangeNotifier {
  StatsSuperviseur? kpis;
  SuperviseurIndicateursPerformance? indicateurs;
  DashboardSuperviseurModel? dashboard;
  SuperviseurHierarchieModel? hierarchie;
  bool isLoading = false;
  bool hasLoaded = false;
  String? errorMessage;
  int? errorStatusCode;

  Future<void> load({bool force = false}) async {
    if (isLoading) return;
    if (hasLoaded && !force) return;

    final superviseurId = AuthService.superviseurId;
    if (superviseurId == null) {
      errorMessage = 'Identifiant superviseur introuvable.';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    errorStatusCode = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        ApiService.getDashboardSuperviseurKpis(superviseurId),
        ApiService.getDashboardSuperviseurIndicateursPerformance(superviseurId),
        ApiService.getDashboardSuperviseur(superviseurId),
        ApiService.getSuperviseurHierarchie(superviseurId),
      ]);

      final kpisResponse = results[0] as ApiResponse<StatsSuperviseur>;
      final indicateursResponse =
          results[1] as ApiResponse<SuperviseurIndicateursPerformance>;
      final dashboardResponse =
          results[2] as ApiResponse<DashboardSuperviseurModel>;
      final hierarchieResponse =
          results[3] as ApiResponse<SuperviseurHierarchieModel>;

      if (kpisResponse.success) kpis = kpisResponse.data;
      if (indicateursResponse.success) {
        indicateurs = indicateursResponse.data;
      }
      if (dashboardResponse.success) dashboard = dashboardResponse.data;
      if (hierarchieResponse.success) hierarchie = hierarchieResponse.data;

      final hasAnyData = kpis != null || dashboard != null || hierarchie != null;
      if (!hasAnyData) {
        final failed = [
          kpisResponse,
          dashboardResponse,
          hierarchieResponse,
        ].where((r) => !r.success).toList();

        if (failed.isNotEmpty) {
          final primary = failed.firstWhere(
            (r) => r == hierarchieResponse,
            orElse: () => failed.first,
          );
          final rawMessage = [
            hierarchieResponse.message,
            kpisResponse.message,
            dashboardResponse.message,
          ].whereType<String>().firstWhere(
                (m) => m.trim().isNotEmpty,
                orElse: () => 'Impossible de charger les données superviseur.',
              );

          errorStatusCode = primary.statusCode;
          errorMessage = ApiErrorHelper.messageForSuperviseurTeamError(
            statusCode: primary.statusCode,
            serverMessage: rawMessage,
          );
        }
      }

      hasLoaded = true;
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('SuperviseurController', e, stackTrace, false);
      errorMessage = ApiErrorHelper.userFacingNetwork();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
