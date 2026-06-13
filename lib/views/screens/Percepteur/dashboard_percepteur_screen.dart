import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../config/colors.dart';
import '../../../config/api.dart';
import '../../../services/auth_service.dart';
import '../../../models/dashboard_agent_model.dart';

class DashboardPercepteurScreen extends StatefulWidget {
  const DashboardPercepteurScreen({super.key});

  @override
  State<DashboardPercepteurScreen> createState() => _DashboardPercepteurScreenState();
}

class _DashboardPercepteurScreenState extends State<DashboardPercepteurScreen> {
  DashboardAgentModel? _dashboardData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = AuthService.userId;

      if (userId == null) {
        setState(() {
          _errorMessage = 'Utilisateur non connecté';
          _isLoading = false;
        });
        return;
      }

      // Using the same dashboard API for now - can be replaced with specific percepteur endpoint
      final response = await ApiService.getDashboardAgentPerformance();

      if (response.success && response.data != null) {
        setState(() {
          _dashboardData = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          if (kDebugMode) {
            print('Erreur: ${response.message}');
          } else {
            _errorMessage = "Un problème est survenu, veuillez réessayer plus tard";
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de connexion: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Dashboard Percepteur', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.prosocGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.prosocGreen),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDashboardData,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _buildDashboardContent(),
    );
  }

  Widget _buildDashboardContent() {
    final dashboard = _dashboardData;
    if (dashboard == null) {
      return const Center(child: Text('Aucune donnée disponible'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Percepteur specific header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.prosocGreen,
                  AppColors.prosocGreen.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tableau de Bord',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Vue d\'ensemble de vos activités',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Total collections
          const Text(
            'Collectes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Collecté',
                  dashboard.formattedTotalCollectes,
                  Icons.money,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Commissions',
                  dashboard.formattedTotalCommissions,
                  Icons.percent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Affiliés',
                  dashboard.totalAffilies.toString(),
                  Icons.people,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Transactions',
                  dashboard.nombreTransactions.toString(),
                  Icons.swap_horiz,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Progression
          const Text(
            'Progression',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Ce Mois',
                  dashboard.formattedProgressionMois,
                  Icons.trending_up,
                  color: AppColors.prosocGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Cette Année',
                  dashboard.formattedProgressionAnnee,
                  Icons.trending_up,
                  color: AppColors.prosocGreen,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Financial summary
          const Text(
            'Résumé Financier',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _buildStatCard(
            'Net à Percevoir',
            dashboard.formattedNetAPercevoir,
            Icons.account_balance_wallet,
            color: AppColors.prosocGreen,
          ),

          const SizedBox(height: 12),

          _buildStatCard(
            'Taux de Réussite',
            dashboard.formattedTauxReussite,
            Icons.check_circle,
            color: AppColors.prosocGreen,
          ),

          const SizedBox(height: 24),

          // Quick actions for percepteur
          const Text(
            'Actions Rapides',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'Encaisser',
                  Icons.add_circle,
                  () {
                    // Navigate to collection
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  'Historique',
                  Icons.history,
                  () {
                    // Navigate to history
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color ?? AppColors.prosocGreen, size: 24),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.prosocGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.prosocGreen.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.prosocGreen, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.prosocGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
