import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../config/api.dart';
import '../../../config/colors.dart';
import '../../../models/dashboard_agent_model.dart';
import '../../../navigation/app_route_observer.dart';
import '../../../services/auth_service.dart';
import '../../../utils/api_error_helper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with RouteAware, WidgetsBindingObserver {
  DashboardAgentModel? _dashboardData;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  DateTime? _lastUpdatedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDashboardData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadDashboardData(silent: _dashboardData != null);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _loadDashboardData(silent: _dashboardData != null);
    }
  }

  Future<void> _loadDashboardData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else if (_dashboardData != null) {
      setState(() => _isRefreshing = true);
    }

    try {
      if (AuthService.userId == null) {
        setState(() {
          _errorMessage = 'Utilisateur non connecté';
          _isLoading = false;
          _isRefreshing = false;
        });
        return;
      }

      final response = await ApiService.getDashboardAgentPerformance();

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _dashboardData = response.data;
          _errorMessage = null;
          _isLoading = false;
          _isRefreshing = false;
          _lastUpdatedAt = DateTime.now();
        });
      } else {
        final message =
            response.message ??
            ApiErrorHelper.userFacingMessage(statusCode: response.statusCode);
        setState(() {
          if (!silent || _dashboardData == null) {
            _errorMessage = message;
          }
          _isLoading = false;
          _isRefreshing = false;
        });
        if (silent && _dashboardData != null) {
          _showRefreshSnackBar(message, isError: true);
        }
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('DashboardScreen', e, stackTrace, false);
      if (!mounted) return;
      final message = ApiErrorHelper.userFacingNetwork();
      setState(() {
        if (!silent || _dashboardData == null) {
          _errorMessage = message;
        }
        _isLoading = false;
        _isRefreshing = false;
      });
      if (silent && _dashboardData != null) {
        _showRefreshSnackBar(message, isError: true);
      }
    }
  }

  void _showRefreshSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : AppColors.prosocGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _shimmerBlock({
    double? width,
    required double height,
    double radius = 12,
  }) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _shimmerBlock(height: 120, radius: 16)),
              const SizedBox(width: 14),
              Expanded(child: _shimmerBlock(height: 120, radius: 16)),
            ],
          ),
          const SizedBox(height: 24),
          _shimmerBlock(width: 160, height: 18, radius: 6),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _shimmerBlock(height: 120, radius: 16)),
              const SizedBox(width: 14),
              Expanded(child: _shimmerBlock(height: 120, radius: 16)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _shimmerBlock(height: 120, radius: 16)),
              const SizedBox(width: 14),
              Expanded(child: _shimmerBlock(height: 120, radius: 16)),
            ],
          ),
          const SizedBox(height: 24),
          _shimmerBlock(width: 140, height: 18, radius: 6),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _shimmerBlock(height: 120, radius: 16)),
              const SizedBox(width: 14),
              Expanded(child: _shimmerBlock(height: 120, radius: 16)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
        ),
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),

        elevation: 0,
        centerTitle: true,
        actions: [
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.prosocGreen,
                  ),
                ),
              ),
            )
          else
            IconButton(
              tooltip: 'Actualiser',
              onPressed: () => _loadDashboardData(silent: _dashboardData != null),
              icon: const Icon(Icons.refresh_rounded, size: 22),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.prosocGreen,
        onRefresh: () async {
          await _loadDashboardData(silent: _dashboardData != null);
          if (mounted && _dashboardData != null && _errorMessage == null) {
            _showRefreshSnackBar('Dashboard actualisé', isError: false);
          }
        },
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _dashboardData == null) {
      return _buildShimmerLoading();
    }

    if (_errorMessage != null && _dashboardData == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          _buildErrorView(),
        ],
      );
    }

    if (_dashboardData == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          _buildEmptyView(),
        ],
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: _buildDashboardContent(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  String? get _lastUpdatedLabel {
    final updatedAt = _lastUpdatedAt;
    if (updatedAt == null) return null;
    return 'Mis à jour à ${DateFormat('HH:mm').format(updatedAt)}';
  }

  Widget _buildDashboardContent() {
    final dashboard = _dashboardData!;
    final lastUpdatedLabel = _lastUpdatedLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lastUpdatedLabel != null) ...[
          Text(
            lastUpdatedLabel,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: _buildHighlightCard(
                title: 'Classement',
                value: dashboard.classement > 0
                    ? '#${dashboard.classement}'
                    : '—',
                icon: Icons.emoji_events_outlined,
                color: const Color(0xFFFF9800),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildHighlightCard(
                title: 'Taux de réussite',
                value: dashboard.formattedTauxReussite,
                icon: Icons.trending_up_rounded,
                color: AppColors.prosocGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('Aperçu de la performance'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total collectes',
                value: dashboard.formattedTotalCollectes,
                icon: Icons.payments_outlined,
                color: AppColors.prosocGreen,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildStatCard(
                title: 'Commissions',
                value: dashboard.formattedTotalCommissions,
                icon: Icons.percent_rounded,
                color: const Color(0xFF2196F3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Affiliés',
                value: dashboard.totalAffilies.toString(),
                icon: Icons.people_outline_rounded,
                color: const Color(0xFFFF9800),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildStatCard(
                title: 'Transactions',
                value: dashboard.nombreTransactions.toString(),
                icon: Icons.swap_horiz_rounded,
                color: const Color(0xFF9C27B0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('Progression'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Mois',
                value: dashboard.formattedProgressionMois,
                icon: Icons.calendar_month_rounded,
                color: AppColors.prosocGreen,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildStatCard(
                title: 'Année',
                value: dashboard.formattedProgressionAnnee,
                icon: Icons.date_range_rounded,
                color: AppColors.prosocGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHighlightCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 56,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'Impossible de charger le dashboard',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Une erreur est survenue',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _loadDashboardData(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.prosocGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return const Column(
      children: [
        Icon(Icons.dashboard_outlined, size: 56, color: Colors.grey),
        SizedBox(height: 16),
        Text(
          'Aucune donnée disponible',
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
      ],
    );
  }
}
