import 'package:flutter/material.dart';

// ============================================
// MODÈLE SERVICE
// ============================================
class ServiceModel {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  ServiceModel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  static List<ServiceModel> getAllServices() {
    return [
      ServiceModel(
        title: 'Assurance Santé',
        subtitle: 'Coverage complète',
        icon: Icons.health_and_safety,
        color: const Color(0xFF4A148C),
      ),
      ServiceModel(
        title: 'Assurance Vie',
        subtitle: 'Protection familiale',
        icon: Icons.favorite,
        color: const Color(0xFFFF1744),
      ),
      ServiceModel(
        title: 'Assurance Auto',
        subtitle: 'Protection véhicule',
        icon: Icons.directions_car,
        color: const Color(0xFF7C4DFF),
      ),
      ServiceModel(
        title: 'Assurance Habitation',
        subtitle: 'Protection domicile',
        icon: Icons.home,
        color: const Color(0xFF00BFA5),
      ),
      ServiceModel(
        title: 'Assurance Voyage',
        subtitle: 'Tranquillité abroad',
        icon: Icons.flight,
        color: const Color(0xFFFFAB00),
      ),
      ServiceModel(
        title: 'Assurance Prévoyance',
        subtitle: 'Protection invalidité',
        icon: Icons.verified_user,
        color: const Color(0xFF4A148C),
      ),
    ];
  }
}

// ============================================
// MODÈLE ACTIVITÉ
// ============================================
class ActivityModel {
  final String title;
  final String date;
  final double amount;
  final IconData icon;
  final Color color;

  ActivityModel({
    required this.title,
    required this.date,
    required this.amount,
    required this.icon,
    required this.color,
  });

  String get formattedAmount => '${amount.toStringAsFixed(0)} €';

  static List<ActivityModel> getRecentActivities() {
    return [
      ActivityModel(
        title: 'Remboursement opticien',
        date: 'Aujourd\'hui',
        amount: 120,
        icon: Icons.visibility,
        color: const Color(0xFF00C853),
      ),
      ActivityModel(
        title: 'Consultation médecin',
        date: 'Hier',
        amount: 35,
        icon: Icons.medical_services,
        color: const Color(0xFF00BFA5),
      ),
      ActivityModel(
        title: 'Analyse sanguine',
        date: 'Il y a 3 jours',
        amount: 85,
        icon: Icons.science,
        color: const Color(0xFF7C4DFF),
      ),
    ];
  }
}

// ============================================
// MODÈLE SERVICE RAPIDE
// ============================================
class QuickServiceModel {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  QuickServiceModel({
    required this.title,
    required this.icon,
    required this.color,
    this.onTap,
  });

  static List<QuickServiceModel> getQuickServices() {
    return [
      QuickServiceModel(
        title: 'Adhésion',
        icon: Icons.person_add,
        color: const Color(0xFF2DB467),
      ),
      QuickServiceModel(
        title: 'Mon Réseau',
        icon: Icons.people,
        color: const Color(0xFFA7001E),
      ),
      QuickServiceModel(
        title: 'KPIs',
        icon: Icons.bar_chart,
        color: const Color(0xFFFFAB00),
      ),
      QuickServiceModel(
        title: 'Dashboard',
        icon: Icons.dashboard,
        color: const Color(0xFF4A148C),
      ),
    ];
  }
}

// ============================================
// MODÈLE MENU PROFIL
// ============================================
class ProfileMenuModel {
  final String title;
  final IconData icon;
  final bool isLogout;

  ProfileMenuModel({
    required this.title,
    required this.icon,
    this.isLogout = false,
  });

  static List<ProfileMenuModel> getMenuItems() {
    return [
      ProfileMenuModel(
        title: 'Mes informations',
        icon: Icons.person,
      ),
      ProfileMenuModel(
        title: 'Mes documents',
        icon: Icons.description,
      ),
      ProfileMenuModel(
        title: 'Mes garages',
        icon: Icons.location_on,
      ),
      ProfileMenuModel(
        title: 'Paramètres',
        icon: Icons.settings,
      ),
      ProfileMenuModel(
        title: 'Déconnexion',
        icon: Icons.logout,
        isLogout: true,
      ),
    ];
  }
}
