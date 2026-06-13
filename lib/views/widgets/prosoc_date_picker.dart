import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../config/colors.dart';

/// Calendrier Material en français, thème Prosoc.
class ProsocDatePicker {
  ProsocDatePicker._();

  static const Locale frenchLocale = Locale('fr', 'FR');

  static const List<LocalizationsDelegate<dynamic>> localizationDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [frenchLocale];

  /// Affiche le sélecteur de date (mois et libellés en français).
  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    Locale locale = frenchLocale,
    String helpText = 'Sélectionner une date',
    String cancelText = 'Annuler',
    String confirmText = 'OK',
  }) {
    return showDatePicker(
      context: context,
      locale: locale,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: helpText,
      cancelText: cancelText,
      confirmText: confirmText,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.prosocGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  static String formatDdMmYyyy(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  static DateTime? parseDdMmYyyy(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parts = value.trim().split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  static DateTime clampDate(
    DateTime date, {
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    if (date.isBefore(firstDate)) return firstDate;
    if (date.isAfter(lastDate)) return lastDate;
    return date;
  }

  static DateTime resolveInitialDate({
    String? currentText,
    DateTime? fallback,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    final parsed = parseDdMmYyyy(currentText);
    final base = parsed ?? fallback ?? DateTime.now();
    return clampDate(base, firstDate: firstDate, lastDate: lastDate);
  }
}

/// Champ formulaire ouvrant le calendrier français Prosoc.
class ProsocDateField extends StatelessWidget {
  const ProsocDateField({
    super.key,
    required this.controller,
    required this.label,
    this.icon = Icons.calendar_today_outlined,
    this.isRequired = false,
    this.onChanged,
    this.firstDate,
    this.lastDate,
    this.initialDateFallback,
    this.emptyHint = 'Sélectionner une date',
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isRequired;
  final VoidCallback? onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateTime? initialDateFallback;
  final String emptyHint;
  final bool enabled;

  Future<void> _openPicker(BuildContext context) async {
    if (!enabled) return;

    final first = firstDate ?? DateTime(1950);
    final last = lastDate ?? DateTime.now();
    final initial = ProsocDatePicker.resolveInitialDate(
      currentText: controller.text,
      fallback: initialDateFallback ?? DateTime(1990),
      firstDate: first,
      lastDate: last,
    );

    final date = await ProsocDatePicker.show(
      context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );

    if (date != null) {
      controller.text = ProsocDatePicker.formatDdMmYyyy(date);
      onChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: enabled ? () => _openPicker(context) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: enabled ? Colors.white : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: enabled ? AppColors.prosocGreen : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, child) {
                      final text = value.text;
                      return Text(
                        text.isEmpty ? emptyHint : text,
                        style: TextStyle(
                          color: text.isEmpty
                              ? Colors.grey.shade400
                              : AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: Colors.grey.shade400,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Variante compacte (bordure simple) pour les formulaires adhérent.
class ProsocDateFieldCompact extends StatelessWidget {
  const ProsocDateFieldCompact({
    super.key,
    this.value,
    required this.label,
    required this.onDateSelected,
    this.icon = Icons.calendar_today_outlined,
    this.firstDate,
    this.lastDate,
    this.initialDateFallback,
    this.emptyHint = 'Sélectionner',
    this.enabled = true,
  });

  final DateTime? value;
  final String label;
  final ValueChanged<DateTime> onDateSelected;
  final IconData icon;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateTime? initialDateFallback;
  final String emptyHint;
  final bool enabled;

  Future<void> _openPicker(BuildContext context) async {
    if (!enabled) return;

    final first = firstDate ?? DateTime(1900);
    final last = lastDate ?? DateTime.now();
    final initial = ProsocDatePicker.clampDate(
      value ?? initialDateFallback ?? DateTime.now(),
      firstDate: first,
      lastDate: last,
    );

    final date = await ProsocDatePicker.show(
      context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );

    if (date != null) {
      onDateSelected(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final display = value != null
        ? ProsocDatePicker.formatDdMmYyyy(value!)
        : emptyHint;

    return InkWell(
      onTap: enabled ? () => _openPicker(context) : null,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.prosocGreen, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade100,
        ),
        child: Text(
          display,
          style: TextStyle(
            color: value != null
                ? AppColors.textPrimary
                : Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
