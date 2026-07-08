import 'package:flutter/material.dart';
import '../../config/colors.dart';
import '../../controllers/main_controller.dart';
import '../../controllers/chef_equipe_controller.dart';
import '../../services/auth_service.dart';
import 'at/home_screen.dart';
import 'at/wallet_screen.dart';
import 'at/virtual_account_screen.dart';
import 'at/profile_screen.dart';
import 'chef_equipe/chef_equipe_zone_screen.dart';
import 'chef_equipe/chef_equipe_team_screen.dart';
import '../../widgets/tab_load_gate.dart';

// ============================================
// ÉCRAN PRINCIPAL AVEC NAVIGATION (AGENT AT)
// + onglet Zone pour Chef d'équipe
// ============================================
class MainScreen extends StatefulWidget {
  final MainController controller;
  final VoidCallback? onLogout;
  final bool enableChefEquipeFeatures;

  const MainScreen({
    super.key,
    required this.controller,
    this.onLogout,
    this.enableChefEquipeFeatures = false,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final HomeController _homeController;
  late final ProfileController _profileController;
  ChefEquipeController? _chefEquipeController;

  bool get _isChefEquipe {
    if (widget.enableChefEquipeFeatures) return true;
    return AuthService.currentUser?.isChefEquipe ?? false;
  }

  int get _tabCount => _isChefEquipe ? 5 : 4;

  int get _profileTabIndex => _isChefEquipe ? 4 : 3;

  int get _zoneTabIndex => 3;

  int _clampTabIndex(int index) {
    final maxIndex = _tabCount - 1;
    if (index < 0) return 0;
    if (index > maxIndex) return maxIndex;
    return index;
  }

  void _normalizeTabIndex() {
    final safeIndex = _clampTabIndex(widget.controller.currentIndex);
    if (safeIndex != widget.controller.currentIndex) {
      widget.controller.setIndex(safeIndex);
    }
  }

  @override
  void initState() {
    super.initState();
    _homeController = HomeController(widget.controller);
    _profileController = ProfileController(widget.controller);

    if (_isChefEquipe) {
      _chefEquipeController = ChefEquipeController(onLogout: _handleLogout);
      _chefEquipeController!.load();
    }

    _normalizeTabIndex();
  }

  @override
  void didUpdateWidget(covariant MainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enableChefEquipeFeatures != widget.enableChefEquipeFeatures) {
      _normalizeTabIndex();
    }
  }

  @override
  void dispose() {
    _chefEquipeController?.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    widget.onLogout?.call();
  }

  void _onTabSelected(int index) {
    setState(() => widget.controller.setIndex(_clampTabIndex(index)));
  }

  void _openAgentDetails(int agentId, String agentNom) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ChefEquipeTeamScreen.agentDetailsRoute(
          agentId: agentId,
          agentNom: agentNom,
          onLogout: _handleLogout,
        ),
      ),
    );
  }

  List<Widget> _buildStackChildren(int stackIndex) {
    final chefController = _chefEquipeController;

    return [
      HomeScreen(controller: _homeController),
      TabLoadGate(
        tabIndex: 1,
        currentIndex: stackIndex,
        child: const WalletScreen(),
      ),
      TabLoadGate(
        tabIndex: 2,
        currentIndex: stackIndex,
        child: const VirtualAccountScreen(),
      ),
      if (_isChefEquipe)
        TabLoadGate(
          tabIndex: _zoneTabIndex,
          currentIndex: stackIndex,
          child: chefController != null
              ? ChefEquipeZoneScreen(
                  controller: chefController,
                  onOpenAgentDetails: _openAgentDetails,
                )
              : const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.prosocGreen,
                  ),
                ),
        ),
      TabLoadGate(
        tabIndex: _profileTabIndex,
        currentIndex: stackIndex,
        child: ProfileScreen(
          controller: _profileController,
          onLogout: _handleLogout,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final stackIndex = _clampTabIndex(widget.controller.currentIndex);
    final stackChildren = _buildStackChildren(stackIndex);

    return Scaffold(
      body: IndexedStack(
        index: stackIndex,
        children: stackChildren,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: stackIndex,
        onTap: _onTabSelected,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.prosocGreen,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 8,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.credit_card_outlined),
            activeIcon: Icon(Icons.credit_card),
            label: 'Compte',
          ),
          if (_isChefEquipe)
            const BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Zone',
            ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
