import 'dart:math';

import 'package:flutter/material.dart';
import 'package:prosoc/views/screens/adh%C3%A9rent/AffiliateDetailsScreen.dart';
import '../../../config/colors.dart';
import '../../../config/api.dart';
import '../../../controllers/main_controller.dart';
import '../../../services/auth_service.dart';
import '../../../models/wallet_agent_model.dart';
import '../../../models/recent_affilie_model.dart';
import '../../../utils/api_error_helper.dart';
import '../../../utils/wallet_agent_loader.dart';
import '../../widgets/common_widgets.dart';
import 'new_adhesion_screen.dart';
import 'my_network_screen.dart';
import 'dashboard_screen.dart';
import 'kpi_screen.dart';

// ============================================
// ÉCRAN D'ACCUEIL (VIEW)
// ============================================
class HomeScreen extends StatefulWidget {
  final HomeController controller;

  const HomeScreen({super.key, required this.controller});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  WalletAgentModel? _walletAgent;
  bool _isLoadingWallet = true;
  bool _isUsdSelected = false;
  Set<int> _availableDeviseIds = {};
  Map<int, WalletAgentModel> _walletsByDevise = {};
  List<RecentAffilieModel> _recentAffiliates = [];
  bool _isLoadingRecentAffiliates = true;

  int get _selectedDeviseId => _isUsdSelected
      ? WalletAgentDeviseIds.usd
      : WalletAgentDeviseIds.cdf;

  bool get _hasDiscoveredDevises => _availableDeviseIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
    _loadRecentAffiliates();
  }

  void _onDeviseChanged(bool isUsd) {
    if (_isUsdSelected == isUsd) return;
    setState(() => _isUsdSelected = isUsd);
    _loadWalletData(silent: _walletAgent != null, singleDeviseOnly: true);
  }

  void _syncDeviseSelection(int deviseId) {
    _isUsdSelected = WalletAgentLoader.isUsdDeviseId(deviseId);
  }

  Future<void> _loadRecentAffiliates({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoadingRecentAffiliates = true);
    }

    try {
      final response = await ApiService.getRecentAffiliates(limit: 5);

      if (response.success && response.data != null) {
        setState(() {
          _recentAffiliates = response.data!;
          _isLoadingRecentAffiliates = false;
        });
      } else {
        setState(() => _isLoadingRecentAffiliates = false);
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('Home/recentAffiliates', e, stackTrace, false);
      setState(() => _isLoadingRecentAffiliates = false);
    }
  }

  Future<void> _loadWalletData({
    bool silent = false,
    bool singleDeviseOnly = false,
  }) async {
    if (!silent) {
      setState(() => _isLoadingWallet = true);
    }

    try {
      final agentId = AuthService.currentUser?.utilisateur.agentId;

      if (agentId != null) {
        final result = singleDeviseOnly && _hasDiscoveredDevises
            ? await WalletAgentLoader.loadSingleDevise(
                agentId: agentId,
                deviseId: _selectedDeviseId,
                availableDeviseIds: _availableDeviseIds,
                cachedWallets: _walletsByDevise,
              )
            : await WalletAgentLoader.load(
                agentId: agentId,
                preferredDeviseId: _selectedDeviseId,
              );

        setState(() {
          _availableDeviseIds = result.availableDeviseIds;
          _walletsByDevise = result.walletsByDevise;
          if (result.hasWallet) {
            _walletAgent = result.wallet;
            if (result.resolvedDeviseId != null) {
              _syncDeviseSelection(result.resolvedDeviseId!);
            }
          } else if (!silent) {
            _walletAgent = null;
          }
          _isLoadingWallet = false;
        });
      } else {
        setState(() => _isLoadingWallet = false);
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('Home/wallet', e, stackTrace, false);
      setState(() => _isLoadingWallet = false);
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      _loadWalletData(silent: true),
      _loadRecentAffiliates(silent: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildHomeAppBar(context),
      body: RefreshIndicator(
        color: AppColors.prosocGreen,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildMainCard(),
            ),
            SliverToBoxAdapter(
              child: _buildQuickServices(context),
            ),
            SliverToBoxAdapter(
              child: _buildRecentActivity(context),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildHomeAppBar(BuildContext context) {
    final userName = AuthService.currentUser?.utilisateur.nomComplet ?? 'Agent';
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

  // Fonction pour obtenir la salutation basée sur l'heure
String _getGreeting() {
  final hour = DateTime.now().hour;
  final random = Random();
  
  // Listes de salutations variées
  const morningGreetings = [
    'Bonjour',
    'Bon début de journée',
    'Passez une excellente matinée',
    'Salut ! Prêt pour les nouveaux Target ?',
  ];

  const afternoonGreetings = [
    'Bon après-midi',
    'Bonne suite de journée',
    'Ravi de vous revoir',
    'Bonne session de travail',
  ];

  const eveningGreetings = [
    'Bonsoir',
    'Bonne soirée',
    'Finissez bien votre journée',
    'Détendez-vous, c\'est le soir',
  ];

  List<String> selectedList;

  // Définition des plages horaires
  if (hour >= 5 && hour < 12) {
    selectedList = morningGreetings;
  } else if (hour >= 12 && hour < 18) {
    selectedList = afternoonGreetings;
  } else {
    selectedList = eveningGreetings;
  }

  // Sélection aléatoire d'un message dans la liste choisie
  final greeting = selectedList[random.nextInt(selectedList.length)];
  
  debugPrint('Heure: $hour | Salutation: $greeting'); 
  return greeting;
}

  Widget _buildMainCard() {
    if (_isLoadingWallet) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.prosocGreen,
          ),
        ),
      );
    }

    final wallet = _walletAgent;
    return AccountCard(
      balance: wallet?.formattedSolde ?? '0.00',
      matricule: wallet?.agentMatricule ?? 'N/A',
      isActive: wallet?.statut ?? false,
      isUsdSelected: _isUsdSelected,
      availableDeviseIds:
          _hasDiscoveredDevises ? _availableDeviseIds : null,
      onDeviseChanged: _onDeviseChanged,
    );
  }

  Widget _buildQuickServices(BuildContext context) {
    final services = widget.controller.quickServices;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Services rapides',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: services.map((service) {
              return QuickServiceItem(
                title: service.title,
                icon: service.icon,
                color: service.color,
                onTap: () => _navigateToService(context, service.title),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToService(BuildContext context, String serviceName) async {
    switch (serviceName) {
      case 'Adhésion':
        final created = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (context) => const NewAdhesionScreen()),
        );
        if (created == true && mounted) {
          setState(() {
            _isLoadingRecentAffiliates = true;
          });
          await _loadRecentAffiliates();
        }
        break;
      case 'Mon Réseau':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyNetworkScreen()),
        );
        break;
      case 'Dashboard':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
        break;
      case 'KPIs':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const KpiScreen()),
        );
        break;
      default:
        debugPrint('Service tapped: $serviceName');
    }
  }

  Widget _buildRecentActivity(BuildContext context) {
    if (_isLoadingRecentAffiliates) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.prosocGreen,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Récentes adhésions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (_recentAffiliates.isEmpty)
            const Text('Aucun affilié récent')
          else
            ..._recentAffiliates.map((affilie) => ActivityItem(
              title: affilie.typeAdhesion.trim().isEmpty
                  ? '${affilie.nom} ${affilie.prenom}'
                  : '${affilie.nom} ${affilie.prenom} - ${affilie.typeAdhesion}',
              date: affilie.dateAdhesion != null
                  ? '${affilie.dateAdhesion!.day.toString().padLeft(2, '0')}/${affilie.dateAdhesion!.month.toString().padLeft(2, '0')}/${affilie.dateAdhesion!.year}'
                  : '',
              amount: '',
              icon: Icons.person,
              color: AppColors.prosocGreen,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AffiliateDetailsScreen(
                      affilieId: affilie.idAffilie,
                      preview: affilie,
                    ),
                  ),
                );
              },
            )).toList(),
        ],
      ),
    );
  }
}
