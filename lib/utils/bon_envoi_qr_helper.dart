import 'dart:convert';
import 'dart:typed_data';

/// Décodage QR base64 renvoyé par l'API (BonEnvoi / DemandeBonEnvoi).
class BonEnvoiQrHelper {
  BonEnvoiQrHelper._();

  static Uint8List? decodeImageBase64(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      var payload = raw.trim();
      final comma = payload.indexOf(',');
      if (comma > 0 && payload.substring(0, comma).contains('base64')) {
        payload = payload.substring(comma + 1);
      }
      return base64Decode(payload);
    } catch (_) {
      return null;
    }
  }

  static bool hasQrImage(String? qrCodeImageBase64) =>
      decodeImageBase64(qrCodeImageBase64) != null;
}
