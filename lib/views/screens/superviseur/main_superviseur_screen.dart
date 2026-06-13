import 'package:flutter/material.dart';

import '../../../config/colors.dart';
import '../../../controllers/main_controller.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/tab_load_gate.dart';
import '../at/my_network_screen.dart';
import '../at/profile_screen.dart';
import '../at/virtual_account_screen.dart';
import '../at/wallet_screen.dart';
import 'superviseur_controller.dart';
import 'superviseur_dashboard_screen.dart';
import 'superviseur_home_screen.dart';
import 'superviseur_team_screen.dart';

// ============================================
// SHELL NAVIGATION — SUPERVISEUR + AGENT TERRAIN
// ============================================
class MainSuperviseurScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const MainSuperviseurScreen({super.key, this.onLogout});

  @override
  State<MainSuperviseurScreen> createState() => _MainSuperviseurScreenState();
}

class _MainSuperviseurScreenState extends State<MainSuperviseurScreen> {
  int _currentIndex = 0;
  late final SuperviseurController _superviseurController;
  late final MainController _mainController;
  late final ProfileController _profileController;

  @override
  void initState() {
    super.initState();
    _superviseurController = SuperviseurController();
    _superviseurController.load();
    _mainController = MainController();
    _profileController = ProfileController(_mainController);
  }

  @override
  void dispose() {
    _superviseurController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    widget.onLogout?.call();
  }

  void _goToTab(int index) {
    setState(() => _currentIndex = index);
  }

  void _openTeamScreen() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            SuperviseurTeamScreen(controller: _superviseurController),
      ),
    );
  }

  void _openPerformanceScreen() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SuperviseurDashboardScreen(
          controller: _superviseurController,
          embedded: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          SuperviseurHomeScreen(
            controller: _superviseurController,
            onOpenTeam: _openTeamScreen,
            onOpenPerformance: _openPerformanceScreen,
            onOpenNetwork: () => _goToTab(1),
            onOpenWallet: () => _goToTab(2),
            onOpenVirtualAccount: () => _goToTab(3),
          ),
          TabLoadGate(
            tabIndex: 1,
            currentIndex: _currentIndex,
            child: MyNetworkScreen(onBack: () => _goToTab(0)),
          ),
          TabLoadGate(
            tabIndex: 2,
            currentIndex: _currentIndex,
            child: const WalletScreen(),
          ),
          TabLoadGate(
            tabIndex: 3,
            currentIndex: _currentIndex,
            child: const VirtualAccountScreen(),
          ),
          ProfileScreen(
            controller: _profileController,
            onLogout: _handleLogout,
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
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Réseau',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card_outlined),
            activeIcon: Icon(Icons.credit_card),
            label: 'Compte',
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
