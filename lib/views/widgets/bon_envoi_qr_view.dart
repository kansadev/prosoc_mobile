import 'package:flutter/material.dart';

import '../../config/colors.dart';
import '../../utils/bon_envoi_qr_helper.dart';

/// Affichage du QR d'un bon (image base64 API ou repli payload / indisponible).
class BonEnvoiQrView extends StatelessWidget {
  final String qrCodeImageBase64;
  final String qrCodePayload;
  final double size;
  final bool showLabel;

  const BonEnvoiQrView({
    super.key,
    required this.qrCodeImageBase64,
    this.qrCodePayload = '',
    this.size = 120,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = BonEnvoiQrHelper.decodeImageBase64(qrCodeImageBase64);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel) ...[
          Text(
            'QR code',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (bytes != null)
          _qrFrame(
            child: Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, __, ___) => _placeholder(
                icon: Icons.broken_image_outlined,
                label: 'QR illisible',
              ),
            ),
          )
        else if (qrCodePayload.trim().isNotEmpty)
          _qrFrame(
            child: _placeholder(
              icon: Icons.qr_code_2,
              label: _shortPayload(qrCodePayload),
            ),
          )
        else
          _qrFrame(
            child: _placeholder(
              icon: Icons.qr_code_scanner,
              label: 'QR non disponible',
              muted: true,
            ),
          ),
      ],
    );
  }

  String _shortPayload(String payload) {
    final t = payload.trim();
    if (t.length <= 48) return t;
    return '${t.substring(0, 45)}...';
  }

  Widget _qrFrame({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _placeholder({
    required IconData icon,
    required String label,
    bool muted = false,
  }) {
    final color = muted ? Colors.grey.shade400 : AppColors.prosocGreen;
    return SizedBox(
      width: size,
      height: size,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: size * 0.4, color: color.withValues(alpha: 0.7)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
