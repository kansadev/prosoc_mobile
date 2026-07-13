import 'package:flutter/material.dart';

import '../../../config/colors.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/tab_load_gate.dart';
import '../at/virtual_account_screen.dart';
import '../at/wallet_screen.dart';
import 'home_percepteur_screen.dart';
import 'percepteur_transactions_screen.dart';
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

  void _goToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomePercepteurScreen(
            currentIndex: _currentIndex,
            onIndexChanged: _goToTab,
            onOpenWallet: () => _goToTab(1),
            onOpenVirtualAccount: () => _goToTab(3),
          ),
          TabLoadGate(
            tabIndex: 1,
            currentIndex: _currentIndex,
            child: const WalletScreen(),
          ),
          TabLoadGate(
            tabIndex: 2,
            currentIndex: _currentIndex,
            child: const PercepteurTransactionsScreen(
              embeddedInNavigation: true,
            ),
          ),
          TabLoadGate(
            tabIndex: 3,
            currentIndex: _currentIndex,
            child: const VirtualAccountScreen(),
          ),
          ProfilePercepteurScreen(onLogout: _handleLogout),
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
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Transactions',
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
