import 'package:flutter/material.dart';

import '../../../config/api.dart';
import '../../../config/colors.dart';
import '../../../models/dashboard_superviseur_model.dart';
import '../../../services/auth_service.dart';
import '../../../utils/api_error_helper.dart';
import '../../widgets/prosoc_resource_error_view.dart';

class SuperviseurTopAgentsScreen extends StatefulWidget {
  const SuperviseurTopAgentsScreen({super.key});

  @override
  State<SuperviseurTopAgentsScreen> createState() =>
      _SuperviseurTopAgentsScreenState();
}

class _SuperviseurTopAgentsScreenState
    extends State<SuperviseurTopAgentsScreen> {
  List<SuperviseurAgentPerformance> _agents = [];
  bool _isLoading = true;
  String? _errorMessage;
  int? _errorStatusCode;

  @override
  void initState() {
    super.initState();
    _loadTopAgents();
  }

  Future<void> _loadTopAgents({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _errorStatusCode = null;
      });
    }

    final superviseurId = AuthService.superviseurId;
    if (superviseurId == null) {
      setState(() {
        _errorMessage = 'Identifiant superviseur introuvable.';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await ApiService.getDashboardSuperviseurTopAgents(
        superviseurId,
        limit: 20,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _agents = response.data!;
          _errorMessage = null;
          _errorStatusCode = null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              response.message ??
              ApiErrorHelper.userFacingMessage(statusCode: response.statusCode);
          _errorStatusCode = response.statusCode;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('SuperviseurTopAgents', e, stackTrace, false);
      if (!mounted) return;
      setState(() {
        _errorMessage = ApiErrorHelper.userFacingNetwork();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
        ),
        title: const Text(
          'Top agents',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _agents.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.prosocGreen),
      );
    }

    if (_errorMessage != null && _agents.isEmpty) {
      return ProsocResourceErrorView(
        message: _errorMessage!,
        statusCode: _errorStatusCode,
        onRetry: () => _loadTopAgents(),
      );
    }

    if (_agents.isEmpty) {
      return RefreshIndicator(
        color: AppColors.prosocGreen,
        onRefresh: () => _loadTopAgents(silent: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Center(child: Text('Aucun agent classé pour le moment')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.prosocGreen,
      onRefresh: () => _loadTopAgents(silent: true),
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _agents.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _buildAgentCard(_agents[index], index),
      ),
    );
  }

  Widget _buildAgentCard(SuperviseurAgentPerformance agent, int index) {
    final rank = agent.rangEquipe > 0 ? agent.rangEquipe : index + 1;
    final initial = agent.nomAgent.isNotEmpty
        ? agent.nomAgent[0].toUpperCase()
        : 'A';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: rank <= 3
            ? Border.all(
                color: _rankColor(rank).withValues(alpha: 0.35),
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _RankBadge(rank: rank),
          const SizedBox(width: 14),
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.prosocGreen.withValues(alpha: 0.12),
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.prosocGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agent.nomAgent.isNotEmpty ? agent.nomAgent : 'Agent #$rank',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${agent.montantTotal.toStringAsFixed(0)} CDF • ${agent.nombreTransactions} tx',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  'Perf. ${agent.performanceMoyenne.toStringAsFixed(1)}% • Obj. ${agent.atteinteObjectif.toStringAsFixed(0)}%',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${agent.tauxSucces.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.prosocGreen,
                ),
              ),
              Text(
                'Succès',
                style: TextStyle(color: Colors.grey[500], fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return AppColors.prosocGreen;
    }
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final color = switch (rank) {
      1 => const Color(0xFFFFD700),
      2 => const Color(0xFFC0C0C0),
      3 => const Color(0xFFCD7F32),
      _ => AppColors.prosocGreen,
    };

    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: rank <= 3
          ? Icon(Icons.emoji_events, color: color, size: 18)
          : Text(
              '$rank',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
    );
  }
}
