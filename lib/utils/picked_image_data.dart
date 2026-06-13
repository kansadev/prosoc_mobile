import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

/// Fichier image prêt pour l'API (base64 + type MIME).
class PickedImageData {
  /// Taille max par fichier image acceptée par l'API (1 Mo).
  static const int maxApiImageBytes = 1024 * 1024;

  final String base64;
  final String contentType;
  final Uint8List bytes;
  final String fileName;

  const PickedImageData({
    required this.base64,
    required this.contentType,
    required this.bytes,
    required this.fileName,
  });

  int get byteLength => bytes.length;

  int get base64Length => base64.length;

  bool get isWithinApiLimit => byteLength <= maxApiImageBytes;

  static String formatByteSize(int bytes) {
    if (bytes >= maxApiImageBytes) {
      return '${(bytes / maxApiImageBytes).toStringAsFixed(2)} Mo';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} Ko';
    }
    return '$bytes o';
  }

  static String contentTypeFromPath(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  static Future<PickedImageData?> pick({
    required ImageSource source,
    int maxWidth = 1920,
    int maxHeight = 1920,
    int imageQuality = 85,
  }) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      maxWidth: maxWidth.toDouble(),
      maxHeight: maxHeight.toDouble(),
      imageQuality: imageQuality,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    final contentType = contentTypeFromPath(file.path);
    final name = file.name.isNotEmpty
        ? file.name
        : file.path.split(RegExp(r'[/\\]')).last;

    return PickedImageData(
      base64: base64Encode(bytes),
      contentType: contentType,
      bytes: bytes,
      fileName: name,
    );
  }

  /// Photo / pièce d'identité pour adhésion — redimensionnement + JPEG compressé.
  static Future<PickedImageData?> pickForAdhesion({
    required ImageSource source,
    required bool isIdentityDocument,
  }) async {
    final maxSide = isIdentityDocument ? 1400 : 960;
    final quality = isIdentityDocument ? 78 : 72;

    final picked = await pick(
      source: source,
      maxWidth: maxSide,
      maxHeight: maxSide,
      imageQuality: quality,
    );
    if (picked == null) return null;

    final compressed = compressForApiUpload(
      picked,
      maxSide: maxSide,
      jpegQuality: quality,
    );

    if (kDebugMode) {
      debugPrint(
        '[Image] ${isIdentityDocument ? 'carte' : 'photo'} '
        '${picked.byteLength} → ${compressed.byteLength} octets '
        '(base64 ${compressed.base64Length})',
      );
    }

    return compressed;
  }

  /// Réencode en JPEG pour limiter la taille du POST (évite les 500 serveur).
  static PickedImageData compressForApiUpload(
    PickedImageData input, {
    int maxSide = 1024,
    int jpegQuality = 75,
  }) {
    final decoded = img.decodeImage(input.bytes);
    if (decoded == null) return input;

    var image = decoded;
    final longest = image.width > image.height ? image.width : image.height;
    if (longest > maxSide) {
      if (image.width >= image.height) {
        image = img.copyResize(image, width: maxSide);
      } else {
        image = img.copyResize(image, height: maxSide);
      }
    }

    final jpegBytes = Uint8List.fromList(
      img.encodeJpg(image, quality: jpegQuality),
    );

    final baseName = input.fileName.contains('.')
        ? input.fileName.substring(0, input.fileName.lastIndexOf('.'))
        : input.fileName;

    return PickedImageData(
      base64: base64Encode(jpegBytes),
      contentType: 'image/jpeg',
      bytes: jpegBytes,
      fileName: '$baseName.jpg',
    );
  }
}
