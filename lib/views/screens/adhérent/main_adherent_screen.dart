import 'package:flutter/material.dart';

import '../../../config/colors.dart';
import 'adherent_contributions_tab_screen.dart';
import 'adherent_demande_bon_screen.dart';
import 'adherent_dependants_screen.dart';
import 'adherent_home_screen.dart';
import 'adherent_profile_screen.dart';
import 'adherent_prestation_screen.dart';

/// Indices de la barre de navigation affilié.
///
/// Ordre UI :
/// 0 Accueil · 1 Cotisations · 2 Souscriptions · 3 Dépendants · 4 Profil
abstract final class _AdherentTabs {
  static const accueil = 0;
  static const cotisations = 1;
  static const souscriptions = 2;
  static const dependants = 3;
  static const profil = 4;
}

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
  int _currentIndex = _AdherentTabs.accueil;

  void _afterLogout() {
    widget.onLogout?.call();
  }

  void _goToTab(int index) {
    if (index < 0 || index > _AdherentTabs.profil) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // 0 — Accueil
          AdherentHomeScreen(
            onPayCotisation: () => _goToTab(_AdherentTabs.cotisations),
            onOpenSouscriptions: () => _goToTab(_AdherentTabs.souscriptions),
            onOpenDependants: () => _goToTab(_AdherentTabs.dependants),
            onOpenDemandeBon: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AdherentDemandeBonScreen(),
                ),
              );
            },
          ),
          // 1 — Cotisations (paiements périodiques)
          const KeyedSubtree(
            key: ValueKey('tab_cotisations'),
            child: AdherentContributionsTabScreen(),
          ),
          // 2 — Souscriptions (prestations)
          const KeyedSubtree(
            key: ValueKey('tab_souscriptions'),
            child: AdherentPrestationScreen(),
          ),
          // 3 — Dépendants
          const KeyedSubtree(
            key: ValueKey('tab_dependants'),
            child: AdherentDependantsScreen(),
          ),
          // 4 — Profil
          AdherentProfileScreen(
            onLogout: _afterLogout,
            onOpenDependants: () => _goToTab(_AdherentTabs.dependants),
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
            icon: Icon(Icons.payments_outlined),
            activeIcon: Icon(Icons.payments),
            label: 'Cotisations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined),
            activeIcon: Icon(Icons.medical_services),
            label: 'Souscriptions',
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
