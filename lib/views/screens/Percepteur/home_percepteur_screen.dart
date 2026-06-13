import 'dart:math';

import 'package:flutter/material.dart';
import 'package:prosoc/config/colors.dart';
import 'package:prosoc/services/auth_service.dart';
import 'package:prosoc/views/screens/percepteur/dashboard_percepteur_screen.dart';
import 'package:prosoc/views/screens/percepteur/collecte_percepteur_screen.dart';
import 'package:prosoc/views/screens/percepteur/historique_percepteur_screen.dart';

// ============================================
// ÉCRAN D'ACCUEIL PERCEPTEUR
// ============================================
class HomePercepteurScreen extends StatefulWidget {
  final int currentIndex;
  final Function(int) onIndexChanged;

  const HomePercepteurScreen({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  State<HomePercepteurScreen> createState() => _HomePercepteurScreenState();
}

class _HomePercepteurScreenState extends State<HomePercepteurScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildHomeAppBar(context),
      body: _buildContent(),
    );
  }

  PreferredSizeWidget _buildHomeAppBar(BuildContext context) {
    final userName = AuthService.currentUser?.utilisateur.nomComplet ?? 'Percepteur';
    final greeting = _getGreeting();

    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 2,
      automaticallyImplyLeading: false,
      toolbarHeight: 84,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$greeting,',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications,
                color: AppColors.prosocGreen,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    final random = Random();

    const morningGreetings = [
      'Bonjour',
      'Bon début de journée',
      'Passez une excellente matinée',
    ];

    const afternoonGreetings = [
      'Bon après-midi',
      'Bonne suite de journée',
      'Ravi de vous revoir',
    ];

    const eveningGreetings = [
      'Bonsoir',
      'Bonne soirée',
      'Finissez bien votre journée',
    ];

    List<String> selectedList;

    if (hour >= 5 && hour < 12) {
      selectedList = morningGreetings;
    } else if (hour >= 12 && hour < 18) {
      selectedList = afternoonGreetings;
    } else {
      selectedList = eveningGreetings;
    }

    return selectedList[random.nextInt(selectedList.length)];
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main balance card
          _buildBalanceCard(),
          const SizedBox(height: 24),

          // Quick services
          Text(
            'Services Rapides',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildQuickServices(context),
          const SizedBox(height: 24),

          // Recent activity
          Text(
            'Activité Récente',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildRecentActivity(context),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.prosocGreen,
            AppColors.prosocGreen.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.prosocGreen.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Solde Total',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.account_balance, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Percepteur',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '1,250,000 XOF',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildMiniStat('Ce mois', '+150,000', Icons.trending_up),
              const SizedBox(width: 24),
              _buildMiniStat('Affiliés', '45', Icons.people),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickServices(BuildContext context) {
    final services = [
      _QuickService(
        title: 'Encaisser',
        icon: Icons.add_circle,
        color: AppColors.prosocGreen,
        onTap: () {
          widget.onIndexChanged(1); // Go to collecte tab
        },
      ),
      _QuickService(
        title: 'Dashboard',
        icon: Icons.dashboard,
        color: Colors.blue,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DashboardPercepteurScreen(),
            ),
          );
        },
      ),
      _QuickService(
        title: 'Historique',
        icon: Icons.history,
        color: Colors.orange,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HistoriquePercepteurScreen(),
            ),
          );
        },
      ),
      _QuickService(
        title: 'Réseau',
        icon: Icons.people,
        color: Colors.purple,
        onTap: () {
          // Navigate to network
        },
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: services.map((service) {
        return InkWell(
          onTap: service.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: service.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  service.icon,
                  color: service.color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                service.title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    // Mock data for recent activity
    final activities = [
      _ActivityItem(
        title: 'Collecte - M. Jean',
        date: '20/03/2026',
        amount: '+50,000 XOF',
        icon: Icons.arrow_downward,
        color: AppColors.prosocGreen,
      ),
      _ActivityItem(
        title: 'Commission reversée',
        date: '19/03/2026',
        amount: '+5,000 XOF',
        icon: Icons.arrow_upward,
        color: Colors.blue,
      ),
      _ActivityItem(
        title: 'Nouvelle adhésion',
        date: '18/03/2026',
        amount: '',
        icon: Icons.person_add,
        color: Colors.orange,
      ),
    ];

    return Column(
      children: activities.map((activity) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: activity.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  activity.icon,
                  color: activity.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      activity.date,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (activity.amount.isNotEmpty)
                Text(
                  activity.amount,
                  style: TextStyle(
                    color: activity.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _QuickService {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _QuickService({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _ActivityItem {
  final String title;
  final String date;
  final String amount;
  final IconData icon;
  final Color color;

  _ActivityItem({
    required this.title,
    required this.date,
    required this.amount,
    required this.icon,
    required this.color,
  });
}
