import 'package:flutter/material.dart';

import '../../../config/colors.dart';
import '../../../controllers/main_controller.dart';
import '../../../controllers/chef_equipe_controller.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/tab_load_gate.dart';
import '../at/profile_screen.dart';
import 'chef_equipe_kpis_screen.dart';
import 'chef_equipe_team_screen.dart';

// ============================================
// SHELL NAVIGATION — CHEF D'EQUIPE
// ============================================
class MainChefEquipeScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const MainChefEquipeScreen({super.key, this.onLogout});

  @override
  State<MainChefEquipeScreen> createState() => _MainChefEquipeScreenState();
}

class _MainChefEquipeScreenState extends State<MainChefEquipeScreen> {
  int _currentIndex = 0;

  late final ChefEquipeController _chefController;
  late final MainController _mainController;
  late final ProfileController _profileController;

  @override
  void initState() {
    super.initState();
    _mainController = MainController();
    _profileController = ProfileController(_mainController);
    _chefController = ChefEquipeController(onLogout: _handleLogout);
    _chefController.load();
  }

  @override
  void dispose() {
    _chefController.dispose();
    super.dispose();
  }

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
          ChefEquipeKpisScreen(controller: _chefController),
          TabLoadGate(
            tabIndex: 1,
            currentIndex: _currentIndex,
            child: ChefEquipeTeamScreen(
              controller: _chefController,
              onOpenDetails: _handleOpenAgentDetails,
            ),
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
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'KPIs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Equipe',
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

  void _handleOpenAgentDetails(int agentId, String agentNom) {
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
}

