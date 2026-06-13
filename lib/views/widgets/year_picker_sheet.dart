import 'package:flutter/material.dart';

import '../../config/colors.dart';

/// Bottom sheet de sélection d'année — réutilisable (dashboard, cotisations, etc.).
class YearPickerSheet {
  YearPickerSheet._();

  /// Affiche le sélecteur et retourne l'année choisie, ou `null` si annulé.
  static Future<int?> show(
    BuildContext context, {
    required int selectedYear,
    String title = 'Choisir une année',
    String? subtitle,
    int yearsBack = 6,
    int yearsForward = 0,
  }) {
    final now = DateTime.now().year;
    final years = <int>[
      for (var i = yearsForward; i >= -yearsBack; i--) now + i,
    ];

    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _YearPickerSheetContent(
        title: title,
        subtitle: subtitle,
        years: years,
        selectedYear: selectedYear,
      ),
    );
  }
}

class _YearPickerSheetContent extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<int> years;
  final int selectedYear;

  const _YearPickerSheetContent({
    required this.title,
    this.subtitle,
    required this.years,
    required this.selectedYear,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.prosocGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: AppColors.prosocGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
                itemCount: years.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final year = years[index];
                  final isSelected = year == selectedYear;
                  return _YearTile(
                    year: year,
                    isSelected: isSelected,
                    onTap: () => Navigator.pop(context, year),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YearTile extends StatelessWidget {
  final int year;
  final bool isSelected;
  final VoidCallback onTap;

  const _YearTile({
    required this.year,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppColors.prosocGreen.withValues(alpha: 0.08)
          : const Color(0xFFF8F9FA),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.prosocGreen.withValues(alpha: 0.5)
                  : Colors.grey.shade200,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(
                '$year',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? AppColors.prosocGreen
                      : AppColors.textPrimary,
                ),
              ),
              if (year == DateTime.now().year) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.prosocGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'En cours',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.prosocGreen,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.prosocGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bouton AppBar / toolbar pour ouvrir [YearPickerSheet].
class YearPickerButton extends StatelessWidget {
  final int selectedYear;
  final ValueChanged<int> onYearSelected;
  final String sheetTitle;
  final String? sheetSubtitle;
  final int yearsBack;
  final int yearsForward;

  const YearPickerButton({
    super.key,
    required this.selectedYear,
    required this.onYearSelected,
    this.sheetTitle = 'Choisir une année',
    this.sheetSubtitle,
    this.yearsBack = 6,
    this.yearsForward = 0,
  });

  Future<void> _open(BuildContext context) async {
    final picked = await YearPickerSheet.show(
      context,
      selectedYear: selectedYear,
      title: sheetTitle,
      subtitle: sheetSubtitle,
      yearsBack: yearsBack,
      yearsForward: yearsForward,
    );
    if (picked != null && picked != selectedYear) {
      onYearSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _open(context),
      icon: const Icon(Icons.calendar_today_outlined, size: 18),
      label: Text('$selectedYear'),
      style: TextButton.styleFrom(foregroundColor: AppColors.prosocGreen),
    );
  }
}
