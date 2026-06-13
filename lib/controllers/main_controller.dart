import '../models/user_model.dart';
import '../models/service_model.dart';
import 'package:flutter/material.dart';

class MainController {
  // État de la navigation
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  // Utilisateur actuel
  final UserModel _currentUser = UserModel.defaultUser();
  UserModel get currentUser => _currentUser;

  // Changement d'onglet
  void setIndex(int index) {
    _currentIndex = index;
  }

  // Récupérer les services rapides
  List<QuickServiceModel> get quickServices => QuickServiceModel.getQuickServices();

  // Récupérer les activités récentes
  List<ActivityModel> get recentActivities => ActivityModel.getRecentActivities();

  // Récupérer tous les services
  List<ServiceModel> get allServices => ServiceModel.getAllServices();

  // Récupérer le menu du profil
  List<ProfileMenuModel> get profileMenuItems => ProfileMenuModel.getMenuItems();
}


class HomeController {
  final MainController _mainController;

  HomeController(this._mainController);

  UserModel get user => _mainController.currentUser;
  List<QuickServiceModel> get quickServices => _mainController.quickServices;
  List<ActivityModel> get recentActivities => _mainController.recentActivities;

  // Actions
  void onServiceTap(String serviceName) {
    // Logique de navigation vers le service
    debugPrint('Service tapped: $serviceName');
  }

  void onActivityTap(ActivityModel activity) {
    // Logique pour voir les détails de l'activité
    debugPrint('Activity tapped: ${activity.title}');
  }
}

// ============================================
// CONTRÔLEUR SERVICES
// ============================================
class ServicesController {
  final MainController _mainController;

  ServicesController(this._mainController);

  List<ServiceModel> get services => _mainController.allServices;

  void onServiceTap(ServiceModel service) {
    // Logique pour voir les détails du service
    debugPrint('Service tapped: ${service.title}');
  }
}

// ============================================
// CONTRÔLEUR PROFIL
// ============================================
class ProfileController {
  final MainController _mainController;

  ProfileController(this._mainController);

  UserModel get user => _mainController.currentUser;
  List<ProfileMenuModel> get menuItems => _mainController.profileMenuItems;

  void onMenuItemTap(ProfileMenuModel menuItem) {
    // Logique pour chaque élément du menu
    debugPrint('Menu item tapped: ${menuItem.title}');
  }

  void logout() {
    // Logique de déconnexion
    debugPrint('User logged out');
  }
}
