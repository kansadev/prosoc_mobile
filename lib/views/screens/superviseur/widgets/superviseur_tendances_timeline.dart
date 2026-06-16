import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timelines_plus/timelines_plus.dart';

import '../../../../config/colors.dart';
import '../../../../models/dashboard_superviseur_model.dart';

/// Bande timeline + cartes montants séparées, scroll synchronisé.
class SuperviseurTendancesTimeline extends StatefulWidget {
  final List<SuperviseurTendanceEquipe> tendances;

  const SuperviseurTendancesTimeline({super.key, required this.tendances});

  @override
  State<SuperviseurTendancesTimeline> createState() =>
      _SuperviseurTendancesTimelineState();
}

class _SuperviseurTendancesTimelineState
    extends State<SuperviseurTendancesTimeline> {
  static const double _itemExtent = 156;

  late final ScrollController _timelineController;
  late final ScrollController _cardsController;
  bool _didInitialScroll = false;
  bool _isSyncingScroll = false;

  List<SuperviseurTendanceEquipe> get _sortedTendances {
    final items = [...widget.tendances];
    items.sort((a, b) {
      final da = _TendancesTimelineHelpers.parsePeriode(a.periode);
      final db = _TendancesTimelineHelpers.parsePeriode(b.periode);
      if (da == null && db == null) return a.periode.compareTo(b.periode);
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });
    return items;
  }

  int? get _currentMonthIndex {
    final now = DateTime.now();
    final index = _sortedTendances.indexWhere((t) {
      final parsed = _TendancesTimelineHelpers.parsePeriode(t.periode);
      return parsed != null &&
          parsed.year == now.year &&
          parsed.month == now.month;
    });
    return index >= 0 ? index : null;
  }

  int get _focusIndex => _currentMonthIndex ?? _sortedTendances.length - 1;

  @override
  void initState() {
    super.initState();
    _timelineController = ScrollController();
    _cardsController = ScrollController();
    _timelineController.addListener(_syncCardsFromTimeline);
    _cardsController.addListener(_syncTimelineFromCards);
  }

  void _syncCardsFromTimeline() {
    if (_isSyncingScroll || !_cardsController.hasClients) return;
    _isSyncingScroll = true;
    _cardsController.jumpTo(_timelineController.offset);
    _isSyncingScroll = false;
  }

  void _syncTimelineFromCards() {
    if (_isSyncingScroll || !_timelineController.hasClients) return;
    _isSyncingScroll = true;
    _timelineController.jumpTo(_cardsController.offset);
    _isSyncingScroll = false;
  }

  @override
  void dispose() {
    _timelineController.removeListener(_syncCardsFromTimeline);
    _cardsController.removeListener(_syncTimelineFromCards);
    _timelineController.dispose();
    _cardsController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SuperviseurTendancesTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tendances != widget.tendances) {
      _didInitialScroll = false;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scheduleScrollToCurrentMonth(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tendances.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Aucune tendance disponible',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    final sorted = _sortedTendances;
    final focusIndex = _focusIndex;

    if (!_didInitialScroll) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scheduleScrollToCurrentMonth(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TimelineStrip(
          sorted: sorted,
          focusIndex: focusIndex,
          hasCurrentMonth: _currentMonthIndex != null,
          controller: _timelineController,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 178,
          child: ListView.separated(
            controller: _cardsController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            physics: const BouncingScrollPhysics(),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final isCurrent =
                  index == focusIndex && _currentMonthIndex != null;
              return SizedBox(
                width: _itemExtent - 12,
                child: _TendanceMetricsCard(
                  tendance: sorted[index],
                  isCurrentMonth: isCurrent,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _scheduleScrollToCurrentMonth() {
    if (!mounted) return;
    if (!_timelineController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scheduleScrollToCurrentMonth(),
      );
      return;
    }
    _scrollToCurrentMonth();
  }

  void _scrollToCurrentMonth() {
    if (!mounted || !_timelineController.hasClients) return;
    if (_sortedTendances.isEmpty) return;

    const horizontalPadding = 4.0;
    const cardGap = 12.0;
    final cardWidth = _itemExtent - 12;
    final viewport = _timelineController.position.viewportDimension;
    final cardsStride = cardWidth + cardGap;
    final cardsTarget = horizontalPadding +
        (_focusIndex * cardsStride) -
        (viewport - cardWidth) / 2;
    final timelineTarget = horizontalPadding +
        (_focusIndex * _itemExtent) -
        (viewport - _itemExtent) / 2;

    _isSyncingScroll = true;

    _cardsController.animateTo(
      cardsTarget.clamp(0.0, _cardsController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );

    _timelineController
        .animateTo(
      timelineTarget.clamp(0.0, _timelineController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    )
        .whenComplete(() {
      if (mounted) _isSyncingScroll = false;
    });

    _didInitialScroll = true;
  }
}

class _TimelineStrip extends StatelessWidget {
  final List<SuperviseurTendanceEquipe> sorted;
  final int focusIndex;
  final bool hasCurrentMonth;
  final ScrollController controller;

  const _TimelineStrip({
    required this.sorted,
    required this.focusIndex,
    required this.hasCurrentMonth,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parcours mensuel',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 72,
            child: TimelineTheme(
              data: TimelineThemeData(
                direction: Axis.horizontal,
                nodePosition: 0.78,
                indicatorPosition: 0.5,
                connectorTheme: ConnectorThemeData(
                  thickness: 3,
                  space: 0,
                  color: Colors.grey.shade300,
                ),
                indicatorTheme: const IndicatorThemeData(
                  size: 12,
                  position: 0.5,
                ),
              ),
              child: Timeline.tileBuilder(
                controller: controller,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                builder: TimelineTileBuilder.connected(
                  connectionDirection: ConnectionDirection.before,
                  itemExtent: _SuperviseurTendancesTimelineState._itemExtent,
                  contentsAlign: ContentsAlign.basic,
                  oppositeContentsBuilder: (context, index) {
                    final parsed = _TendancesTimelineHelpers.parsePeriode(
                      sorted[index].periode,
                    );
                    final isCurrent = index == focusIndex && hasCurrentMonth;
                    return _TimelineMonthLabel(
                      parsed: parsed,
                      fallbackLabel: sorted[index].periode,
                      isCurrentMonth: isCurrent,
                    );
                  },
                  contentsBuilder: (_, __) => const SizedBox(height: 2),
                  indicatorBuilder: (context, index) {
                    final isCurrent = index == focusIndex && hasCurrentMonth;
                    final isPast = index < focusIndex;

                    if (isCurrent) {
                      return DotIndicator(
                        size: 20,
                        color: AppColors.prosocGreen,
                        border: Border.all(color: Colors.white, width: 3),
                      );
                    }
                    if (isPast) {
                      return DotIndicator(
                        size: 11,
                        color: AppColors.prosocGreen,
                      );
                    }
                    return OutlinedDotIndicator(
                      size: 11,
                      color: Colors.grey.shade400,
                      borderWidth: 2,
                    );
                  },
                  connectorBuilder: (context, index, type) {
                    if (index == 0) return null;
                    return SolidLineConnector(
                      color: index <= focusIndex
                          ? AppColors.prosocGreen
                          : Colors.grey.shade300,
                    );
                  },
                  itemCount: sorted.length,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineMonthLabel extends StatelessWidget {
  final DateTime? parsed;
  final String fallbackLabel;
  final bool isCurrentMonth;

  const _TimelineMonthLabel({
    required this.parsed,
    required this.fallbackLabel,
    required this.isCurrentMonth,
  });

  @override
  Widget build(BuildContext context) {
    final monthShort = parsed != null
        ? _TendancesTimelineHelpers.capitalize(
            DateFormat('MMM', 'fr_FR').format(parsed!),
          )
        : fallbackLabel;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCurrentMonth)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.prosocGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'En cours',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Text(
            monthShort,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: isCurrentMonth ? 13 : 11,
              color: isCurrentMonth
                  ? AppColors.prosocGreen
                  : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TendanceMetricsCard extends StatelessWidget {
  final SuperviseurTendanceEquipe tendance;
  final bool isCurrentMonth;

  const _TendanceMetricsCard({
    required this.tendance,
    required this.isCurrentMonth,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentMonth
              ? AppColors.prosocGreen
              : Colors.grey.shade200,
          width: isCurrentMonth ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrentMonth
                ? AppColors.prosocGreen.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: isCurrentMonth ? 16 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payments_outlined,
                size: 16,
                color: isCurrentMonth
                    ? AppColors.prosocGreen
                    : Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Montant',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            tendance.montantPeriode.toStringAsFixed(0),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isCurrentMonth ? 22 : 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'CDF',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _MetricRow(
            icon: Icons.receipt_long_outlined,
            label: 'Transactions',
            value: '${tendance.nombreTransactionsPeriode}',
          ),
          const SizedBox(height: 8),
          _MetricRow(
            icon: Icons.flag_outlined,
            label: 'Objectif',
            value: '${tendance.atteinteObjectifPeriode.toStringAsFixed(0)}%',
            valueColor: isCurrentMonth ? AppColors.prosocGreen : null,
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

abstract final class _TendancesTimelineHelpers {
  static DateTime? parsePeriode(String periode) {
    final raw = periode.trim();
    if (raw.isEmpty) return null;

    final iso = RegExp(r'^(\d{4})[-/](\d{1,2})').firstMatch(raw);
    if (iso != null) {
      return DateTime(int.parse(iso.group(1)!), int.parse(iso.group(2)!));
    }

    final european = RegExp(r'^(\d{1,2})[-/](\d{4})').firstMatch(raw);
    if (european != null) {
      return DateTime(
        int.parse(european.group(2)!),
        int.parse(european.group(1)!),
      );
    }

    final lower = raw.toLowerCase();
    for (final entry in _frenchMonths.entries) {
      if (lower.contains(entry.key)) {
        final yearMatch = RegExp(r'(\d{4})').firstMatch(raw);
        if (yearMatch != null) {
          return DateTime(int.parse(yearMatch.group(1)!), entry.value);
        }
      }
    }

    return DateTime.tryParse(raw);
  }

  static String capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  static const _frenchMonths = {
    'janvier': 1,
    'janv': 1,
    'février': 2,
    'fevrier': 2,
    'fév': 2,
    'fev': 2,
    'mars': 3,
    'avril': 4,
    'avr': 4,
    'mai': 5,
    'juin': 6,
    'juillet': 7,
    'juil': 7,
    'août': 8,
    'aout': 8,
    'septembre': 9,
    'sept': 9,
    'octobre': 10,
    'oct': 10,
    'novembre': 11,
    'nov': 11,
    'décembre': 12,
    'decembre': 12,
    'déc': 12,
    'dec': 12,
  };
}
