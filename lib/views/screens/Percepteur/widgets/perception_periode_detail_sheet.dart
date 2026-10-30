import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../config/api.dart';
import '../../../../config/colors.dart';
import '../../../../models/perception_virtuelle_model.dart';
import '../../../../utils/api_error_helper.dart';
import '../../../../utils/currency_formatter.dart';
import '../../../../utils/paginated_response_helper.dart';
import '../../../widgets/empty_state_widget.dart';

/// Détail des opérations de perception sur une période.
///
/// L'API n'expose aucun paramètre « semaine » : la période est traduite en
/// fenêtre `dateDebut` / `dateFin` sur `GET /api/PerceptionVirtuelle/historique`.
class PerceptionPeriodeDetailSheet extends StatefulWidget {
  final DateTime dateDebut;
  final DateTime dateFin;
  final String periodeLabel;

  const PerceptionPeriodeDetailSheet({
    super.key,
    required this.dateDebut,
    required this.dateFin,
    required this.periodeLabel,
  });

  static Future<void> show(
    BuildContext context, {
    required DateTime dateDebut,
    required DateTime dateFin,
    required String periodeLabel,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.85,
        child: PerceptionPeriodeDetailSheet(
          dateDebut: dateDebut,
          dateFin: dateFin,
          periodeLabel: periodeLabel,
        ),
      ),
    );
  }

  @override
  State<PerceptionPeriodeDetailSheet> createState() =>
      _PerceptionPeriodeDetailSheetState();
}

class _PerceptionPeriodeDetailSheetState
    extends State<PerceptionPeriodeDetailSheet> {
  static const _pageSize = 20;

  final _scrollController = ScrollController();

  List<PerceptionVirtuelleHistoModel> _operations = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasNext = false;
  int _page = 1;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _page = 1;
        _hasNext = false;
      });
    } else {
      if (_isLoadingMore || _isLoading || !_hasNext) return;
      setState(() => _isLoadingMore = true);
    }

    final page = reset ? 1 : _page;

    try {
      final response = await ApiService.getPerceptionVirtuelleHistorique(
        page: page,
        pageSize: _pageSize,
        dateDebut: widget.dateDebut,
        dateFin: widget.dateFin,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        final rows = ApiService.parsePerceptionVirtuelleHisto(response.data);

        setState(() {
          _operations = reset ? rows : [..._operations, ...rows];
          _hasNext = PaginatedResponseHelper.extractHasNext(response.data);
          _page = PaginatedResponseHelper.extractCurrentPage(
            response.data,
            fallback: page,
          ) + 1;
          _errorMessage = null;
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          if (reset) {
            _operations = [];
            _errorMessage = ApiErrorHelper.messageForApiFailure(
              statusCode: response.statusCode,
              serverDetail: response.message,
              fallback: 'Impossible de charger les opérations.',
            );
          }
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException(
        'PerceptionPeriodeDetailSheet/load',
        e,
        stackTrace,
        false,
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _operations = [];
          _errorMessage = ApiErrorHelper.userFacingNetwork();
        }
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  String get _periodeRangeLabel {
    final debut = DateFormat('dd/MM/yyyy').format(widget.dateDebut);
    final fin = DateFormat('dd/MM/yyyy').format(widget.dateFin);
    return '$debut → $fin';
  }

  double get _totalMontant =>
      _operations.fold(0, (sum, o) => sum + o.montantTotal);

  int get _totalCollectes =>
      _operations.fold(0, (sum, o) => sum + o.nombreCollectes);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Opérations — ${widget.periodeLabel}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _periodeRangeLabel,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _operations.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.prosocGreen),
      );
    }

    if (_errorMessage != null && _operations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _load(reset: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.prosocGreen,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_operations.isEmpty) {
      return EmptyStateScrollable(
        icon: Icons.event_busy,
        title: 'Aucune opération',
        subtitle: 'Aucune encaissement sur $_periodeRangeLabel.',
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: _operations.length + 2,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) return _buildSummaryCard();
        if (index == _operations.length + 1) {
          if (_isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.prosocGreen,
                ),
              ),
            );
          }
          if (!_hasNext) {
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  'Fin de la période',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }
        return _buildOperationTile(_operations[index - 1]);
      },
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.prosocGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.prosocGreen.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total encaissé',
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(amount: _totalMontant),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.prosocGreen,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Remises',
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                '${_operations.length}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$_totalCollectes collecte(s)',
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOperationTile(PerceptionVirtuelleHistoModel operation) {
    final date = operation.datePerception == null
        ? '—'
        : DateFormat('dd/MM/yyyy HH:mm').format(operation.datePerception!);
    final annulee = operation.statutMetier.toUpperCase().contains('ANNUL');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: annulee ? Colors.grey[50] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  operation.agentNom.isNotEmpty
                      ? operation.agentNom
                      : 'Agent #${operation.agentId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    date,
                    '${operation.nombreCollectes} collecte(s)',
                    if (operation.agentMatricule.isNotEmpty)
                      operation.agentMatricule,
                  ].join(' • '),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (operation.statutMetier.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    operation.motifAnnulation.isNotEmpty
                        ? '${operation.statutMetier} — ${operation.motifAnnulation}'
                        : operation.statutMetier,
                    style: TextStyle(
                      fontSize: 11,
                      color: annulee ? Colors.red.shade700 : Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            CurrencyFormatter.format(
              amount: operation.montantTotal,
              deviseId: operation.deviseId > 0 ? operation.deviseId : null,
              deviseCode: operation.deviseCode,
            ),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              decoration: annulee ? TextDecoration.lineThrough : null,
              color: annulee ? Colors.grey : AppColors.prosocGreen,
            ),
          ),
        ],
      ),
    );
  }
}
