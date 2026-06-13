import 'package:flutter/material.dart';
import '../../config/colors.dart';
import '../../controllers/main_controller.dart';
import '../../services/auth_service.dart';
import 'at/home_screen.dart';
import 'at/wallet_screen.dart';
import 'at/virtual_account_screen.dart';
import 'at/profile_screen.dart';
import '../../widgets/tab_load_gate.dart';

// ============================================
// ÉCRAN PRINCIPAL AVEC NAVIGATION (AGENT AT)
// ============================================
class MainScreen extends StatefulWidget {
  final MainController controller;
  final VoidCallback? onLogout;

  const MainScreen({super.key, required this.controller, this.onLogout});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final HomeController _homeController;
  late final ProfileController _profileController;

  @override
  void initState() {
    super.initState();
    _homeController = HomeController(widget.controller);
    _profileController = ProfileController(widget.controller);
  }

  void _handleLogout() async {
    await AuthService.logout();
    widget.onLogout?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: widget.controller.currentIndex,
        children: [
          HomeScreen(controller: _homeController),
          TabLoadGate(
            tabIndex: 1,
            currentIndex: widget.controller.currentIndex,
            child: const WalletScreen(),
          ),
          TabLoadGate(
            tabIndex: 2,
            currentIndex: widget.controller.currentIndex,
            child: const VirtualAccountScreen(),
          ),
          ProfileScreen(controller: _profileController, onLogout: _handleLogout),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: widget.controller.currentIndex,
        onTap: (index) => setState(() => widget.controller.setIndex(index)),
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
