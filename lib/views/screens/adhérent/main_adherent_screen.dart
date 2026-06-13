import 'package:flutter/material.dart';

import '../../../config/colors.dart';
import '../../../services/auth_service.dart';
import 'adherent_contributions_tab_screen.dart';
import 'adherent_demande_bon_screen.dart';
import 'adherent_dependants_screen.dart';
import 'adherent_home_screen.dart';
import 'adherent_profile_screen.dart';
import 'adherent_prestation_screen.dart';

// ============================================
// SHELL NAVIGATION — RÔLE ADHÉRENT / AFFILIÉ
// ============================================
class MainAdherentScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const MainAdherentScreen({super.key, this.onLogout});

  @override
  State<MainAdherentScreen> createState() => _MainAdherentScreenState();
}

class _MainAdherentScreenState extends State<MainAdherentScreen> {
  int _currentIndex = 0;

  Future<void> _handleLogout() async {
    await AuthService.logout();
    widget.onLogout?.call();
  }

  void _goToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          AdherentHomeScreen(
            onPayCotisation: () => _goToTab(2),
            onOpenDependants: () => _goToTab(3),
            onOpenDemandeBon: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AdherentDemandeBonScreen(),
                ),
              );
            },
          ),
          const AdherentPrestationScreen(),
          const AdherentContributionsTabScreen(),
          const AdherentDependantsScreen(),
          AdherentProfileScreen(
            onLogout: _handleLogout,
            onOpenDependants: () => _goToTab(3),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _goToTab,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.prosocGreen,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined),
            activeIcon: Icon(Icons.medical_services),
            label: 'Souscriptions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments_outlined),
            activeIcon: Icon(Icons.payments),
            label: 'Cotisations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Dépendants',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
