import 'package:flutter/material.dart';

import '../../config/colors.dart';

/// État d'erreur réutilisable pour wallet agent, compte virtuel, etc.
class ProsocResourceErrorView extends StatelessWidget {
  final String message;
  final int? statusCode;
  final VoidCallback? onRetry;
  final String retryLabel;
  final bool compact;
  final IconData? icon;

  const ProsocResourceErrorView({
    super.key,
    required this.message,
    this.statusCode,
    this.onRetry,
    this.retryLabel = 'Réessayer',
    this.compact = false,
    this.icon,
  });

  bool get _isNotFound => statusCode == 404;

  IconData get _resolvedIcon {
    if (icon != null) return icon!;
    if (_isNotFound) return Icons.inbox_outlined;
    if (statusCode == 403) return Icons.lock_outline_rounded;
    if (statusCode != null && statusCode! >= 500) {
      return Icons.cloud_off_rounded;
    }
    return Icons.error_outline_rounded;
  }

  Color get _resolvedIconColor {
    if (_isNotFound) return Colors.orange.shade700;
    if (statusCode == 403) return Colors.amber.shade800;
    if (statusCode != null && statusCode! >= 500) {
      return Colors.blueGrey.shade600;
    }
    return Colors.red.shade400;
  }

  String? get _statusHint {
    if (statusCode == null) return null;
    if (_isNotFound) return 'Ressource non disponible (404)';
    if (statusCode! >= 500) return 'Erreur serveur ($statusCode)';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 40.0 : 64.0;
    final titleStyle = TextStyle(
      fontSize: compact ? 14 : 16,
      height: 1.4,
      color: Colors.grey.shade800,
      fontWeight: FontWeight.w500,
    );
    final hintStyle = TextStyle(
      fontSize: compact ? 11 : 12,
      color: Colors.grey.shade500,
    );

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 20 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _resolvedIcon,
              size: iconSize,
              color: _resolvedIconColor,
            ),
            SizedBox(height: compact ? 12 : 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: titleStyle,
            ),
            if (_statusHint != null) ...[
              const SizedBox(height: 8),
              Text(
                _statusHint!,
                textAlign: TextAlign.center,
                style: hintStyle,
              ),
            ],
            if (onRetry != null) ...[
              SizedBox(height: compact ? 12 : 20),
              compact
                  ? TextButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(retryLabel),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.prosocGreen,
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(retryLabel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.prosocGreen,
                        foregroundColor: Colors.white,
                      ),
                    ),
            ],
          ],
        ),
      ),
    );
  }
}
