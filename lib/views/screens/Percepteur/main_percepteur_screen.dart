import 'package:flutter/material.dart';
import '../../../config/colors.dart';
import '../../../services/auth_service.dart';
import 'home_percepteur_screen.dart';
import 'collecte_percepteur_screen.dart';
import 'historique_percepteur_screen.dart';
import 'profile_percepteur_screen.dart';

// ============================================
// ÉCRAN PRINCIPAL PERCEPTEUR AVEC NAVIGATION
// ============================================
class MainPercepteurScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const MainPercepteurScreen({super.key, this.onLogout});

  @override
  State<MainPercepteurScreen> createState() => _MainPercepteurScreenState();
}

class _MainPercepteurScreenState extends State<MainPercepteurScreen> {
  int _currentIndex = 0;

  void _handleLogout() async {
    await AuthService.logout();
    widget.onLogout?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomePercepteurScreen(
            currentIndex: _currentIndex,
            onIndexChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          const CollectePercepteurScreen(),
          const HistoriquePercepteurScreen(),
          ProfilePercepteurScreen(onLogout: _handleLogout),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
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
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Encaisser',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Historique',
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
