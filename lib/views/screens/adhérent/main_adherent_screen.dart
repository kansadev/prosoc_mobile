import 'package:flutter/material.dart';

import '../../../config/colors.dart';
import 'adherent_contributions_tab_screen.dart';
import 'adherent_demande_bon_screen.dart';
import 'adherent_dependants_screen.dart';
import 'adherent_home_screen.dart';
import 'adherent_profile_screen.dart';
import 'adherent_prestation_screen.dart';

/// Shell navigation — rôle Adhérent / Affilié.
class MainAdherentScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const MainAdherentScreen({super.key, this.onLogout});

  @override
  State<MainAdherentScreen> createState() => _MainAdherentScreenState();
}

class _MainAdherentScreenState extends State<MainAdherentScreen> {
  int _currentIndex = 0;

  void _afterLogout() {
    widget.onLogout?.call();
  }

  void _goToTab(int index) {
    if (index < 0 || index >= _navItems.length) return;
    setState(() => _currentIndex = index);
  }

  int get _cotisationsIndex => 1;

  int get _souscriptionsIndex => 2;

  int get _dependantsIndex => 3;

  List<Widget> get _pages {
    return [
      AdherentHomeScreen(
        onPayCotisation: () => _goToTab(_cotisationsIndex),
        onOpenSouscriptions: () => _goToTab(_souscriptionsIndex),
        onOpenDependants: () => _goToTab(_dependantsIndex),
        onOpenDemandeBon: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AdherentDemandeBonScreen(),
            ),
          );
        },
      ),
      const KeyedSubtree(
        key: ValueKey('tab_cotisations'),
        child: AdherentContributionsTabScreen(),
      ),
      const KeyedSubtree(
        key: ValueKey('tab_souscriptions'),
        child: AdherentPrestationScreen(),
      ),
      const KeyedSubtree(
        key: ValueKey('tab_dependants'),
        child: AdherentDependantsScreen(),
      ),
      AdherentProfileScreen(
        onLogout: _afterLogout,
        onOpenDependants: () => _goToTab(_dependantsIndex),
      ),
    ];
  }

  List<BottomNavigationBarItem> get _navItems {
    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Accueil',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.payments_outlined),
        activeIcon: Icon(Icons.payments),
        label: 'Cotisations',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.medical_services_outlined),
        activeIcon: Icon(Icons.medical_services),
        label: 'Souscriptions',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.people_outline),
        activeIcon: Icon(Icons.people),
        label: 'Dépendants',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profil',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    final safeIndex = _currentIndex.clamp(0, pages.length - 1);

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        onTap: _goToTab,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.prosocGreen,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 8,
        items: _navItems,
      ),
    );
  }
}
