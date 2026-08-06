import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../config/colors.dart';

/// Bottom sheet — scan QR d'un bon d'envoi (caméra + saisie manuelle).
class BonEnvoiScannerSheet extends StatefulWidget {
  const BonEnvoiScannerSheet({super.key});

  /// Retourne le contenu scanné / saisi, ou `null` si annulé.
  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const BonEnvoiScannerSheet(),
    );
  }

  @override
  State<BonEnvoiScannerSheet> createState() => _BonEnvoiScannerSheetState();
}

class _BonEnvoiScannerSheetState extends State<BonEnvoiScannerSheet> {
  final _manualController = TextEditingController();
  final _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    formats: const [BarcodeFormat.qrCode],
  );

  bool _handled = false;
  bool _torchOn = false;
  bool _showManual = false;
  String? _manualError;

  @override
  void dispose() {
    _manualController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final raw = barcodes.first.rawValue?.trim();
    if (raw == null || raw.isEmpty) return;

    _handled = true;
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(raw);
  }

  void _submitManual() {
    if (_handled) return;
    final value = _manualController.text.trim();
    if (value.isEmpty) {
      setState(() => _manualError = 'Saisissez le contenu QR ou le numéro BE-…');
      return;
    }
    _handled = true;
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(value);
  }

  Future<void> _toggleTorch() async {
    await _scannerController.toggleTorch();
    if (!mounted) return;
    setState(() => _torchOn = !_torchOn);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final height = MediaQuery.sizeOf(context).height * 0.78;

    return SafeArea(
      child: SizedBox(
        height: height + bottomInset,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Scanner un bon d\'envoi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: _torchOn ? 'Éteindre le flash' : 'Allumer le flash',
                    onPressed: _toggleTorch,
                    icon: Icon(
                      _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                      color: AppColors.prosocGreen,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fermer',
                    onPressed: () {
                      if (_handled) return;
                      _handled = true;
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Cadrez le QR code du bon dans la zone de scan.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: _onDetect,
                        errorBuilder: (context, error) {
                          return ColoredBox(
                            color: Colors.grey.shade900,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.videocam_off_outlined,
                                      color: Colors.white70,
                                      size: 40,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      error.errorDetails?.message ??
                                          error.errorCode.message,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Vous pouvez aussi saisir le code manuellement.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      IgnorePointer(
                        child: CustomPaint(
                          painter: _ScannerOverlayPainter(
                            color: AppColors.prosocGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextButton.icon(
                onPressed: () => setState(() {
                  _showManual = !_showManual;
                  _manualError = null;
                }),
                icon: Icon(
                  _showManual
                      ? Icons.keyboard_hide_outlined
                      : Icons.keyboard_alt_outlined,
                ),
                label: Text(
                  _showManual
                      ? 'Masquer la saisie manuelle'
                      : 'Saisir manuellement',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.prosocGreen,
                ),
              ),
              if (_showManual) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _manualController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submitManual(),
                  decoration: InputDecoration(
                    labelText: 'Contenu QR ou numéro de bon',
                    hintText: 'BE-… ou payload QR',
                    errorText: _manualError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.prosocGreen,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (_) {
                    if (_manualError != null) {
                      setState(() => _manualError = null);
                    }
                  },
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: _submitManual,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.prosocGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Vérifier'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  _ScannerOverlayPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Paint()..color = Colors.black.withValues(alpha: 0.45);
    final cut = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.72,
        height: size.width * 0.72,
      ),
      const Radius.circular(16),
    );

    final path = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(cut)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, overlay);

    final border = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(cut, border);
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) =>
      oldDelegate.color != color;
}
