import 'package:flutter/material.dart';

import '../../config/colors.dart';

/// Onglet pour [DashboardSegmentTabBar].
class DashboardSegmentTabItem {
  final String label;

  /// Nombre affiché entre parenthèses, ex. « Récentes (5) ».
  final int? badgeCount;

  /// Si true, le badge n'apparaît que lorsque [badgeCount] > 0
  /// (ex. onglet « Retards » sans « (0) »).
  final bool showBadgeOnlyIfPositive;

  const DashboardSegmentTabItem({
    required this.label,
    this.badgeCount,
    this.showBadgeOnlyIfPositive = false,
  });

  String get displayLabel {
    if (badgeCount == null) return label;
    if (showBadgeOnlyIfPositive && badgeCount! <= 0) return label;
    return '$label ($badgeCount)';
  }
}

/// Barre d'onglets segmentée (dashboard cotisations / prestations).
class DashboardSegmentTabBar extends StatelessWidget {
  final TabController controller;
  final List<DashboardSegmentTabItem> tabs;
  final Color indicatorColor;

  const DashboardSegmentTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.indicatorColor = AppColors.prosocGreen,
  }) : assert(tabs.length >= 2);

  @override
  Widget build(BuildContext context) {
    assert(
      controller.length == tabs.length,
      'TabController.length (${controller.length}) doit égaler tabs.length (${tabs.length})',
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: indicatorColor,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textPrimary,
        dividerHeight: 0,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        tabs: [
          for (final tab in tabs) Tab(text: tab.displayLabel),
        ],
      ),
    );
  }
}

/// Colonne standard : barre d'onglets + [TabBarView].
class DashboardSegmentTabScaffold extends StatelessWidget {
  final TabController controller;
  final List<DashboardSegmentTabItem> tabs;
  final List<Widget> children;
  final Color indicatorColor;

  const DashboardSegmentTabScaffold({
    super.key,
    required this.controller,
    required this.tabs,
    required this.children,
    this.indicatorColor = AppColors.prosocGreen,
  }) : assert(tabs.length == children.length);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DashboardSegmentTabBar(
          controller: controller,
          tabs: tabs,
          indicatorColor: indicatorColor,
        ),
        Expanded(
          child: TabBarView(
            controller: controller,
            children: children,
          ),
        ),
      ],
    );
  }
}
