import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/api.dart';
import '../../../config/colors.dart';
import '../../../models/perception_virtuelle_model.dart';
import '../../../utils/api_error_helper.dart';
import '../../../utils/paginated_response_helper.dart';
import '../../widgets/prosoc_resource_error_view.dart';
import '../../widgets/prosoc_shimmer_loading.dart';

/// Historique + synthèse des remises VA (PerceptionVirtuelle).
class PercepteurVaHistoriqueScreen extends StatefulWidget {
  const PercepteurVaHistoriqueScreen({super.key});

  @override
  State<PercepteurVaHistoriqueScreen> createState() =>
      _PercepteurVaHistoriqueScreenState();
}

class _PercepteurVaHistoriqueScreenState
    extends State<PercepteurVaHistoriqueScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<PerceptionVirtuelleHistoModel> _historique = [];
  List<PerceptionVirtuelleSyntheseAgent> _synthese = [];
  bool _loadingHisto = true;
  bool _loadingSynthese = true;
  bool _loadingMoreHisto = false;
  String? _histoError;
  String? _syntheseError;
  int _histoPage = 1;
  bool _histoHasNext = false;
  final _scrollController = ScrollController();

  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);
    _loadHistorique(reset: true);
    _loadSynthese();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_tabController.index != 0) return;
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 200) return;
    if (!_loadingHisto && !_loadingMoreHisto && _histoHasNext) {
      _loadHistorique();
    }
  }

  Future<void> _loadHistorique({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loadingHisto = true;
        _histoError = null;
        _historique = [];
        _histoPage = 1;
        _histoHasNext = false;
      });
    } else {
      if (_loadingMoreHisto || !_histoHasNext) return;
      setState(() => _loadingMoreHisto = true);
    }

    final pageToLoad = reset ? 1 : _histoPage + 1;
    try {
      final response = await ApiService.getPerceptionVirtuelleHistorique(
        page: pageToLoad,
        pageSize: _pageSize,
      );
      if (!mounted) return;

      if (response.success && response.data != null) {
        final rows = ApiService.parsePerceptionVirtuelleHisto(response.data);
        setState(() {
          _historique = reset ? rows : [..._historique, ...rows];
          _histoPage = PaginatedResponseHelper.extractCurrentPage(
            response.data!,
            fallback: pageToLoad,
          );
          _histoHasNext =
              PaginatedResponseHelper.extractHasNext(response.data!);
          _loadingHisto = false;
          _loadingMoreHisto = false;
          _histoError = null;
        });
      } else {
        setState(() {
          _histoError = response.message ??
              ApiErrorHelper.userFacingMessage(statusCode: response.statusCode);
          _loadingHisto = false;
          _loadingMoreHisto = false;
        });
      }
    } catch (e, st) {
      ApiErrorHelper.logException(
        'PercepteurVaHistorique/histo',
        e,
        st,
        false,
      );
      if (!mounted) return;
      setState(() {
        _histoError = ApiErrorHelper.userFacingNetwork();
        _loadingHisto = false;
        _loadingMoreHisto = false;
      });
    }
  }

  Future<void> _loadSynthese() async {
    setState(() {
      _loadingSynthese = true;
      _syntheseError = null;
    });
    try {
      final response = await ApiService.getPerceptionVirtuelleSyntheseAgents();
      if (!mounted) return;
      if (response.success && response.data != null) {
        setState(() {
          _synthese = response.data!;
          _loadingSynthese = false;
        });
      } else {
        setState(() {
          _syntheseError = response.message ??
              ApiErrorHelper.userFacingMessage(statusCode: response.statusCode);
          _loadingSynthese = false;
        });
      }
    } catch (e, st) {
      ApiErrorHelper.logException(
        'PercepteurVaHistorique/synthese',
        e,
        st,
        false,
      );
      if (!mounted) return;
      setState(() {
        _syntheseError = ApiErrorHelper.userFacingNetwork();
        _loadingSynthese = false;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat("dd/MM/yyyy 'à' HH:mm", 'fr_FR').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Remises VA',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.prosocGreen,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.prosocGreen,
          tabs: const [
            Tab(text: 'Historique'),
            Tab(text: 'Synthèse agents'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHistoriqueTab(),
          _buildSyntheseTab(),
        ],
      ),
    );
  }

  Widget _buildHistoriqueTab() {
    if (_loadingHisto) {
      return const ProsocLoadingShimmer.list(itemCount: 6);
    }
    if (_histoError != null && _historique.isEmpty) {
      return ProsocResourceErrorView(
        message: _histoError!,
        onRetry: () => _loadHistorique(reset: true),
      );
    }
    if (_historique.isEmpty) {
      return Center(
        child: Text(
          'Aucune remise virtuelle enregistrée.',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.prosocGreen,
      onRefresh: () => _loadHistorique(reset: true),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _historique.length + (_loadingMoreHisto ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= _historique.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.prosocGreen,
                    strokeWidth: 2,
                  ),
                ),
              ),
            );
          }
          final item = _historique[index];
          return _HistoCard(item: item, dateLabel: _formatDate(item.datePerception));
        },
      ),
    );
  }

  Widget _buildSyntheseTab() {
    if (_loadingSynthese) {
      return const ProsocLoadingShimmer.list(itemCount: 6);
    }
    if (_syntheseError != null && _synthese.isEmpty) {
      return ProsocResourceErrorView(
        message: _syntheseError!,
        onRetry: _loadSynthese,
      );
    }
    if (_synthese.isEmpty) {
      return Center(
        child: Text(
          'Aucune collecte VA en attente.',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.prosocGreen,
      onRefresh: _loadSynthese,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _synthese.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _synthese[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      AppColors.prosocGreen.withValues(alpha: 0.12),
                  child: Text(
                    item.agentNom.trim().isNotEmpty
                        ? item.agentNom.trim()[0].toUpperCase()
                        : 'A',
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
                        item.agentNom,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      if (item.agentMatricule.isNotEmpty)
                        Text(
                          item.agentMatricule,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.nombreCollectesEnAttente} collecte(s) en attente',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  item.formattedMontantEnAttente,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.prosocGreen,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HistoCard extends StatelessWidget {
  final PerceptionVirtuelleHistoModel item;
  final String dateLabel;

  const _HistoCard({required this.item, required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    final annulee = item.isAnnulee;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: annulee
              ? Colors.red.shade200
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.agentNom,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                item.formattedMontant,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: annulee ? Colors.red.shade700 : AppColors.prosocGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            [
              if (item.agentMatricule.isNotEmpty) item.agentMatricule,
              dateLabel,
              if (item.nombreCollectes > 0)
                '${item.nombreCollectes} collecte(s)',
            ].join(' · '),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          if (item.statutMetier.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (annulee ? Colors.red : AppColors.prosocGreen)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.statutMetier,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: annulee ? Colors.red.shade800 : AppColors.prosocGreen,
                ),
              ),
            ),
          ],
          if (item.observation.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.observation,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ],
      ),
    );
  }
}
