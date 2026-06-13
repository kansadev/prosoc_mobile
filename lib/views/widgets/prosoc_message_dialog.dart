import 'package:flutter/material.dart';

import '../../config/colors.dart';

/// Variante visuelle du dialogue message Prosoc.
enum ProsocMessageVariant {
  success,
  error,
  warning,
  info,
}

/// Dialogue message réutilisable (succès, erreur, avertissement, info).
class ProsocMessageDialog extends StatelessWidget {
  const ProsocMessageDialog({
    super.key,
    required this.variant,
    required this.title,
    required this.message,
    this.hint,
    this.statusCode,
    this.confirmLabel,
    this.onConfirm,
    this.secondaryLabel,
    this.onSecondary,
    this.barrierDismissible = false,
    this.icon,
    this.accentColor,
  });

  final ProsocMessageVariant variant;
  final String title;
  final String message;
  final String? hint;
  final int? statusCode;
  final String? confirmLabel;
  final VoidCallback? onConfirm;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool barrierDismissible;
  final IconData? icon;
  final Color? accentColor;

  static Future<void> show(
    BuildContext context, {
    required ProsocMessageVariant variant,
    required String title,
    required String message,
    String? hint,
    int? statusCode,
    String? confirmLabel,
    VoidCallback? onConfirm,
    String? secondaryLabel,
    VoidCallback? onSecondary,
    bool barrierDismissible = false,
    IconData? icon,
    Color? accentColor,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => ProsocMessageDialog(
        variant: variant,
        title: title,
        message: message,
        hint: hint,
        statusCode: statusCode,
        confirmLabel: confirmLabel,
        onConfirm: onConfirm == null
            ? null
            : () {
                Navigator.of(dialogContext).pop();
                onConfirm();
              },
        secondaryLabel: secondaryLabel,
        onSecondary: onSecondary,
        barrierDismissible: barrierDismissible,
        icon: icon,
        accentColor: accentColor,
      ),
    );
  }

  /// Dialogue à deux choix. Retourne `true` si l'action secondaire est choisie.
  static Future<bool> showChoice(
    BuildContext context, {
    required ProsocMessageVariant variant,
    required String title,
    required String message,
    String? hint,
    required String primaryLabel,
    required String secondaryLabel,
    bool barrierDismissible = false,
    IconData? icon,
    Color? accentColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => ProsocMessageDialog(
        variant: variant,
        title: title,
        message: message,
        hint: hint,
        confirmLabel: primaryLabel,
        secondaryLabel: secondaryLabel,
        barrierDismissible: barrierDismissible,
        icon: icon,
        accentColor: accentColor,
        onConfirm: () => Navigator.of(dialogContext).pop(false),
        onSecondary: () => Navigator.of(dialogContext).pop(true),
      ),
    );
    return result ?? false;
  }

  Color get _resolvedAccent {
    if (accentColor != null) return accentColor!;
    return switch (variant) {
      ProsocMessageVariant.success => AppColors.prosocGreen,
      ProsocMessageVariant.error => Colors.red.shade600,
      ProsocMessageVariant.warning => Colors.orange.shade700,
      ProsocMessageVariant.info => Colors.blue.shade700,
    };
  }

  IconData get _resolvedIcon {
    if (icon != null) return icon!;
    return switch (variant) {
      ProsocMessageVariant.success => Icons.check_circle_outline_rounded,
      ProsocMessageVariant.error => Icons.error_outline_rounded,
      ProsocMessageVariant.warning => Icons.warning_amber_rounded,
      ProsocMessageVariant.info => Icons.info_outline_rounded,
    };
  }

  String get _resolvedConfirmLabel {
    if (confirmLabel != null) return confirmLabel!;
    return switch (variant) {
      ProsocMessageVariant.success => 'Parfait',
      ProsocMessageVariant.warning => 'Compris',
      _ => 'OK',
    };
  }

  @override
  Widget build(BuildContext context) {
    final accent = _resolvedAccent;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_resolvedIcon, color: accent, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: Colors.grey.shade800,
            ),
          ),
          if (hint != null && hint!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                hint!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
          if (statusCode != null && statusCode! >= 400) ...[
            const SizedBox(height: 10),
            Text(
              'Code $statusCode',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ],
      ),
      actions: [
        if (secondaryLabel != null) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                if (onSecondary != null) {
                  onSecondary!();
                } else {
                  Navigator.of(context).pop();
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(secondaryLabel!),
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (onConfirm != null) {
                onConfirm!();
              } else {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.prosocGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(_resolvedConfirmLabel),
          ),
        ),
      ],
    );
  }
}
