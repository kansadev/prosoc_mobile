import 'package:flutter/material.dart';

import '../../../config/colors.dart';
import '../../../config/api.dart';
import '../../../models/chef_equipe_model.dart';
import '../../../utils/api_error_helper.dart';
import '../../../utils/formatters.dart';
import '../../widgets/prosoc_resource_error_view.dart';

class ChefEquipeAgentDetailsScreen extends StatefulWidget {
  final int agentId;
  final String agentNom;
  final Future<void> Function() onLogout;

  const ChefEquipeAgentDetailsScreen({
    super.key,
    required this.agentId,
    required this.agentNom,
    required this.onLogout,
  });

  @override
  State<ChefEquipeAgentDetailsScreen> createState() =>
      _ChefEquipeAgentDetailsScreenState();
}

class _ChefEquipeAgentDetailsScreenState
    extends State<ChefEquipeAgentDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _isLoadingMovements = false;
  bool _isLoadingCollectes = false;

  bool _movementsLoaded = false;
  bool _collectesLoaded = false;

  String? _movementsError;
  int? _movementsErrorStatusCode;
  AgentCommissionsResumeDto? _movementsData;

  String? _collectesError;
  int? _collectesErrorStatusCode;
  List<ChefEquipeCollecteResumeDto> _collectesData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadMovementsIfNeeded(initial: true);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) return;
    if (_tabController.index == 0) {
      _loadMovementsIfNeeded();
    } else {
      _loadCollectesIfNeeded();
    }
  }

  Future<void> _loadMovementsIfNeeded({bool force = false, bool initial = false}) async {
    if (_movementsLoaded && !force && !initial) return;
    if (_isLoadingMovements) return;
    setState(() => _isLoadingMovements = true);

    try {
      final response =
          await ApiService.getChefEquipeMouvementsWallet(
        widget.agentId,
        limit: 20,
      );

      if (response.statusCode == 401) {
        await widget.onLogout();
        return;
      }

      if (response.statusCode == 403) {
        setState(() {
          _movementsError = 'Accès refusé (hors périmètre)';
          _movementsErrorStatusCode = 403;
        });
        return;
      }

      if (response.success && response.data != null) {
        setState(() {
          _movementsData = response.data;
          _movementsLoaded = true;
          _movementsError = null;
          _movementsErrorStatusCode = null;
        });
        return;
      }

      setState(() {
        _movementsError = response.message ?? 'Erreur lors du chargement.';
        _movementsErrorStatusCode = response.statusCode;
      });
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('ChefEquipeAgentDetails/mouvements', e, stackTrace);
      setState(() {
        _movementsError = ApiErrorHelper.userFacingNetwork();
        _movementsErrorStatusCode = 0;
      });
    } finally {
      if (mounted) setState(() => _isLoadingMovements = false);
    }
  }

  Future<void> _loadCollectesIfNeeded() async {
    if (_collectesLoaded) return;
    if (_isLoadingCollectes) return;
    setState(() => _isLoadingCollectes = true);

    try {
      final response = await ApiService.getChefEquipeCollectes(
        widget.agentId,
        limit: 50,
      );

      if (response.statusCode == 401) {
        await widget.onLogout();
        return;
      }

      if (response.statusCode == 403) {
        setState(() {
          _collectesError = 'Accès refusé (hors périmètre)';
          _collectesErrorStatusCode = 403;
        });
        return;
      }

      if (response.success && response.data != null) {
        setState(() {
          _collectesData = response.data!;
          _collectesLoaded = true;
          _collectesError = null;
          _collectesErrorStatusCode = null;
        });
        return;
      }

      setState(() {
        _collectesError = response.message ?? 'Erreur lors du chargement.';
        _collectesErrorStatusCode = response.statusCode;
      });
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('ChefEquipeAgentDetails/collectes', e, stackTrace);
      setState(() {
        _collectesError = ApiErrorHelper.userFacingNetwork();
        _collectesErrorStatusCode = 0;
      });
    } finally {
      if (mounted) setState(() => _isLoadingCollectes = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeNom =
        widget.agentNom.trim().isNotEmpty ? widget.agentNom : 'Agent';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(safeNom),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mouvements wallet'),
            Tab(text: 'Collectes'),
          ],
          indicatorColor: AppColors.prosocGreen,
          labelColor: AppColors.prosocGreen,
          unselectedLabelColor: Colors.grey.shade600,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMovementsTab(),
          _buildCollectesTab(),
        ],
      ),
    );
  }

  Widget _buildMovementsTab() {
    if (_isLoadingMovements && !_movementsLoaded) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.prosocGreen),
      );
    }

    if (_movementsError != null) {
      return ProsocResourceErrorView(
        message: _movementsError!,
        statusCode: _movementsErrorStatusCode,
        onRetry: () => _loadMovementsIfNeeded(force: true),
      );
    }

    final data = _movementsData;
    if (data == null) {
      return const Center(child: Text('Aucune donnée disponible.'));
    }

    return RefreshIndicator(
      color: AppColors.prosocGreen,
      onRefresh: () async => _loadMovementsIfNeeded(force: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _MovementsSummaryCard(data: data),
          const SizedBox(height: 16),
          if (data.mouvementsRecents.isEmpty)
            _emptyState('Aucun mouvement récent pour ce wallet.')
          else
            ...data.mouvementsRecents.map((m) => _MovementRow(mouvement: m)),
        ],
      ),
    );
  }

  Widget _buildCollectesTab() {
    if (_isLoadingCollectes && !_collectesLoaded) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.prosocGreen),
      );
    }

    if (_collectesError != null) {
      return ProsocResourceErrorView(
        message: _collectesError!,
        statusCode: _collectesErrorStatusCode,
        onRetry: () => _loadCollectesIfNeeded(),
      );
    }

    if (_collectesData.isEmpty) {
      return RefreshIndicator(
        color: AppColors.prosocGreen,
        onRefresh: _loadCollectesIfNeeded,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          children: [
            _emptyState('Aucune collecte trouvée pour ce agent.'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.prosocGreen,
      onRefresh: _loadCollectesIfNeeded,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _collectesData.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final collecte = _collectesData[index];
          return _CollecteCard(collecte: collecte);
        },
      ),
    );
  }

  Widget _emptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _MovementsSummaryCard extends StatelessWidget {
  final AgentCommissionsResumeDto data;

  const _MovementsSummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.prosocGreen.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aperçu wallet',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          _SummaryTile(
            label: 'Solde wallet',
            value: data.soldeWallet.toStringAsFixed(2),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  label: 'Mois',
                  value: data.totalCommissionsMois.toStringAsFixed(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryTile(
                  label: 'Année',
                  value: data.totalCommissionsAnnee.toStringAsFixed(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _SummaryTile(
            label: 'Mouvements (mois)',
            value: data.nombreMouvementsMois.toString(),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MovementRow extends StatelessWidget {
  final AgentCommissionMouvementDto mouvement;

  const _MovementRow({required this.mouvement});

  @override
  Widget build(BuildContext context) {
    final dateLabel = mouvement.dateOperation != null
        ? AppFormatters.formatDate(mouvement.dateOperation)
        : 'N/A';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.prosocGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.swap_horiz_rounded,
                color: AppColors.prosocGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mouvement.description?.trim().isNotEmpty == true
                      ? mouvement.description!
                      : mouvement.source,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mouvement.nomAffilie?.trim().isNotEmpty == true
                      ? 'Affilié : ${mouvement.nomAffilie}'
                      : 'Source : ${mouvement.source}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  dateLabel,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            mouvement.montant.toStringAsFixed(2),
            style: const TextStyle(
              color: AppColors.prosocGreen,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _CollecteCard extends StatelessWidget {
  final ChefEquipeCollecteResumeDto collecte;

  const _CollecteCard({required this.collecte});

  @override
  Widget build(BuildContext context) {
    final dateLabel = AppFormatters.formatDateTime(collecte.dateCollecte);
    final montantLabel = collecte.montant.toStringAsFixed(2);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.prosocGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    color: AppColors.prosocGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collecte.affilieNom?.trim().isNotEmpty == true
                          ? collecte.affilieNom!
                          : 'Collecte',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateLabel,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                montantLabel,
                style: const TextStyle(
                  color: AppColors.prosocGreen,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _statusPill(collecte.statutPaiement?.toString() ?? '—'),
              if (collecte.modePaiement?.trim().isNotEmpty == true)
                const SizedBox(width: 8),
              if (collecte.modePaiement?.trim().isNotEmpty == true)
                _statusPill('Mode: ${collecte.modePaiement}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String label) {
    final trimmed = label.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.prosocGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.prosocGreen.withValues(alpha: 0.25)),
      ),
      child: Text(
        trimmed.isEmpty ? '—' : trimmed,
        style: const TextStyle(
          color: AppColors.prosocGreen,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

