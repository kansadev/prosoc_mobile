import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../../config/colors.dart';

/// Page WebView pour finaliser un paiement par carte (FlexPay).
class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({
    super.key,
    required this.paymentUrl,
  });

  final String paymentUrl;

  static Future<void> open(BuildContext context, String paymentUrl) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PaymentWebViewScreen(paymentUrl: paymentUrl),
      ),
    );
  }

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  var _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    final uri = Uri.tryParse(widget.paymentUrl.trim());
    if (uri == null) {
      _loadError = 'Lien de paiement invalide';
      _isLoading = false;
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final platform = _controller.platform;
      if (platform is AndroidWebViewController) {
        platform.setMixedContentMode(MixedContentMode.alwaysAllow);
      }
    }

    _controller
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() {
              _isLoading = true;
              _loadError = null;
            });
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            // Ne pas bloquer l'écran pour jQuery / scripts tiers (Mixed Content, etc.)
            if (error.isForMainFrame != true) return;
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _loadError = error.description;
            });
          },
        ),
      )
      ..loadRequest(uri);
  }

  Future<void> _openInExternalBrowser() async {
    final uri = Uri.tryParse(widget.paymentUrl.trim());
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir le navigateur')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Paiement par carte'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Ouvrir dans le navigateur',
            onPressed: _openInExternalBrowser,
          ),
        ],
      ),
      body: _loadError != null
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
            )
          : Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.prosocGreen,
                    ),
                  ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.amber.shade50,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        'Si le formulaire carte ne s\'affiche pas correctement, '
                        'utilisez l\'icône navigateur en haut à droite.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
