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
  bool isLoading = false;
  bool hasLoaded = false;
  String? errorMessage;

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
    notifyListeners();

    try {
      final results = await Future.wait([
        ApiService.getDashboardSuperviseurKpis(superviseurId),
        ApiService.getDashboardSuperviseurIndicateursPerformance(superviseurId),
        ApiService.getDashboardSuperviseur(superviseurId),
      ]);

      final kpisResponse = results[0] as ApiResponse<StatsSuperviseur>;
      final indicateursResponse =
          results[1] as ApiResponse<SuperviseurIndicateursPerformance>;
      final dashboardResponse =
          results[2] as ApiResponse<DashboardSuperviseurModel>;

      if (kpisResponse.success) kpis = kpisResponse.data;
      if (indicateursResponse.success) {
        indicateurs = indicateursResponse.data;
      }
      if (dashboardResponse.success) dashboard = dashboardResponse.data;

      if (!kpisResponse.success && !dashboardResponse.success) {
        errorMessage = kpisResponse.message ??
            dashboardResponse.message ??
            'Impossible de charger les données superviseur.';
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
