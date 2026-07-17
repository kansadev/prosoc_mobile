import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../config/api.dart';
import '../../../config/colors.dart';
import '../../../models/adhesion_with_affilie_model.dart';
import '../../../services/flex_pay_signalr_service.dart';
import '../../../utils/api_error_helper.dart';
import '../../../utils/formatters.dart';

/// Écran d'attente pendant la validation FlexPay (Mobile Money, carte, etc.).
///
/// Confirme le succès **uniquement** après `GET /api/FlexPay/verifier/{orderNumber}`
/// (polling) ou événement SignalR de succès (si branché).
class FlexPayPaymentWaitingScreen extends StatefulWidget {
  const FlexPayPaymentWaitingScreen({
    super.key,
    required this.payment,
    required this.isMobileMoney,
  });

  final AdhesionElectronicPaymentResponse payment;
  final bool isMobileMoney;

  @override
  State<FlexPayPaymentWaitingScreen> createState() =>
      _FlexPayPaymentWaitingScreenState();
}

class _FlexPayPaymentWaitingScreenState
    extends State<FlexPayPaymentWaitingScreen> {
  static const _pollInterval = Duration(seconds: 4);

  Timer? _expiryTimer;
  Timer? _pollTimer;
  bool _isExpired = false;
  bool _isChecking = false;
  bool _isFinalizing = false;
  bool _paymentFailed = false;
  String? _statusHint;
  FlexPayVerifierResult? _lastResult;

  String? get _orderNumber {
    final order = widget.payment.orderNumberFlexPay?.trim();
    if (order != null && order.isNotEmpty) return order;
    return null;
  }

  @override
  void initState() {
    super.initState();
    _scheduleExpiryCheck();
    _connectSignalR();
    _startPolling();
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _pollTimer?.cancel();
    FlexPaySignalRService.instance.disconnect();
    super.dispose();
  }

  void _startPolling() {
    if (_orderNumber == null) {
      if (kDebugMode) {
        debugPrint('[FlexPay] polling impossible — orderNumber manquant');
      }
      setState(() {
        _statusHint =
            'Numéro de commande FlexPay manquant — impossible de vérifier le paiement.';
      });
      return;
    }

    if (kDebugMode) {
      debugPrint(
        '[FlexPay] démarrage polling orderNumber=$_orderNumber '
        '(toutes les ${_pollInterval.inSeconds}s)',
      );
    }

    // Premier contrôle immédiat, puis intervalle.
    unawaited(_checkPaymentStatus(showBusy: false));
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      unawaited(_checkPaymentStatus(showBusy: false));
    });
  }

  Future<void> _connectSignalR() async {
    final collecteId = widget.payment.idCollecteEnAttente;
    if (collecteId == null || collecteId.isEmpty) return;

    await FlexPaySignalRService.instance.connect(
      idCollecteEnAttente: collecteId,
      onUpdated: (update) {
        if (!mounted || _isFinalizing) return;
        if (update.success) {
          // SignalR accélère : on revalide quand même via l'API.
          unawaited(_checkPaymentStatus(showBusy: true));
        } else if (update.message != null && update.message!.isNotEmpty) {
          setState(() => _statusHint = update.message);
        }
      },
    );
  }

  void _scheduleExpiryCheck() {
    final expiresAt = widget.payment.holdExpireAt;
    if (expiresAt == null) return;

    void check() {
      if (!mounted || _isFinalizing) return;
      if (DateTime.now().isAfter(expiresAt)) {
        setState(() => _isExpired = true);
        _expiryTimer?.cancel();
        _pollTimer?.cancel();
      }
    }

    check();
    _expiryTimer = Timer.periodic(const Duration(seconds: 30), (_) => check());
  }

  Future<void> _checkPaymentStatus({required bool showBusy}) async {
    if (!mounted || _isFinalizing || _paymentFailed || _isExpired) return;
    if (_isChecking) return;

    final orderNumber = _orderNumber;
    if (orderNumber == null) return;

    setState(() {
      _isChecking = true;
      if (showBusy) {
        _statusHint = 'Vérification du paiement…';
      }
    });

    try {
      final response = await ApiService.verifyFlexPayPayment(orderNumber);
      if (!mounted || _isFinalizing) return;

      if (!response.success || response.data == null) {
        final msg = response.message?.trim();
        setState(() {
          _statusHint = (msg != null && msg.isNotEmpty)
              ? msg
              : 'En attente de confirmation FlexPay…';
        });
        return;
      }

      final result = response.data!;
      if (kDebugMode) {
        debugPrint(
          '[FlexPay] poll résultat success=${result.success} '
          'alreadyProcessed=${result.alreadyProcessed} '
          'idAdhesion=${result.idAdhesion} idCollecte=${result.idCollecte} '
          'finalized=${result.isPaymentFinalized} '
          'failed=${result.isPaymentFailed} '
          'message=${result.message}',
        );
      }

      setState(() {
        _lastResult = result;
        final msg = result.message?.trim();
        if (msg != null && msg.isNotEmpty) {
          _statusHint = msg;
        } else if (!result.isPaymentFinalized) {
          _statusHint = 'Paiement en attente de confirmation…';
        }
      });

      if (result.isPaymentFinalized) {
        await _onPaymentConfirmedByApi(result);
        return;
      }

      if (result.isPaymentFailed) {
        _pollTimer?.cancel();
        final msg = result.message?.trim();
        setState(() {
          _paymentFailed = true;
          _statusHint = (msg != null && msg.isNotEmpty)
              ? msg
              : 'Le paiement a échoué ou n\'a pas pu être finalisé.';
        });
      }
    } catch (e, st) {
      ApiErrorHelper.logException('FlexPay/verifier (poll)', e, st);
      if (!mounted) return;
      setState(() {
        _statusHint = 'Impossible de vérifier pour le moment. Nouvel essai…';
      });
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _onPaymentConfirmedByApi(FlexPayVerifierResult result) async {
    if (_isFinalizing || !mounted) return;
    _isFinalizing = true;
    _pollTimer?.cancel();
    _expiryTimer?.cancel();

    final detail = <String>[];
    if (result.idAdhesion != null) {
      detail.add('Adhésion n° ${result.idAdhesion}');
    }
    if (result.idCollecte != null) {
      detail.add('Collecte n° ${result.idCollecte}');
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Icon(
          Icons.check_circle,
          color: AppColors.prosocGreen,
          size: 64,
        ),
        content: Text(
          detail.isEmpty
              ? 'Paiement confirmé.\nL\'opération a bien été finalisée.'
              : 'Paiement confirmé.\n${detail.join('\n')}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: TextButton.styleFrom(foregroundColor: AppColors.prosocGreen),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _onClosePressed() {
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final payment = widget.payment;
    final message = payment.message?.trim();
    final statusFallback = widget.isMobileMoney
        ? 'En attente de validation sur le téléphone…'
        : 'En attente de confirmation du paiement…';

    final headline = _paymentFailed
        ? (_statusHint ?? 'Paiement échoué')
        : _isExpired
            ? 'Délai de paiement expiré. Relancez l\'opération si nécessaire.'
            : (_statusHint?.isNotEmpty == true
                ? _statusHint!
                : (message?.isNotEmpty == true ? message! : statusFallback));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.isMobileMoney
              ? 'Paiement Mobile Money'
              : 'Paiement en cours',
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: _isChecking && !_paymentFailed && !_isExpired
                            ? const SizedBox(
                                width: 64,
                                height: 64,
                                child: CircularProgressIndicator(
                                  color: AppColors.prosocGreen,
                                  strokeWidth: 3,
                                ),
                              )
                            : Icon(
                                _paymentFailed
                                    ? Icons.cancel_outlined
                                    : _isExpired
                                        ? Icons.timer_off_outlined
                                        : Icons.sync,
                                size: 72,
                                color: _paymentFailed
                                    ? Colors.red.shade400
                                    : _isExpired
                                        ? Colors.orange
                                        : AppColors.prosocGreen,
                              ),
                      ),
                      Text(
                        headline,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (!_isExpired && !_paymentFailed) ...[
                        const SizedBox(height: 12),
                        Text(
                          widget.isMobileMoney
                              ? 'Validez la demande Mobile Money sur le téléphone, '
                                  'puis attendez la confirmation automatique.'
                              : 'Finalisez le paiement, puis attendez la confirmation automatique.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _orderNumber == null
                              ? 'Vérification impossible sans numéro de commande.'
                              : 'Vérification automatique toutes les ${_pollInterval.inSeconds} s.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      _infoTile(
                        Icons.payments_outlined,
                        'Montant',
                        '${payment.montantFlexPay.toStringAsFixed(2)} '
                            '${payment.codeDevisePaiement ?? payment.codeDeviseTarif ?? ''}',
                      ),
                      if (payment.referenceFlexPay?.isNotEmpty == true)
                        _infoTile(
                          Icons.tag_outlined,
                          'Référence',
                          payment.referenceFlexPay!,
                        ),
                      if (payment.orderNumberFlexPay?.isNotEmpty == true)
                        _infoTile(
                          Icons.confirmation_number_outlined,
                          'Commande FlexPay',
                          payment.orderNumberFlexPay!,
                        ),
                      if (payment.idCollecteEnAttente?.isNotEmpty == true)
                        _infoTile(
                          Icons.fingerprint_outlined,
                          'Collecte en attente',
                          payment.idCollecteEnAttente!,
                        ),
                      if (payment.holdExpireAt != null)
                        _infoTile(
                          Icons.timer_outlined,
                          'Expire le',
                          AppFormatters.formatDateTime(payment.holdExpireAt),
                        ),
                      if (_lastResult?.idAdhesion != null)
                        _infoTile(
                          Icons.badge_outlined,
                          'Adhésion',
                          '${_lastResult!.idAdhesion}',
                        ),
                    ],
                  ),
                ),
              ),
              if (!_isExpired && !_paymentFailed && _orderNumber != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isChecking
                        ? null
                        : () => _checkPaymentStatus(showBusy: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.prosocGreen,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.prosocGreen.withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      _isChecking ? 'Vérification…' : 'Vérifier le statut',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _onClosePressed,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.prosocGreen,
                    side: const BorderSide(color: AppColors.prosocGreen),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    _isExpired || _paymentFailed
                        ? 'Fermer'
                        : 'Quitter sans confirmer',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: AppColors.prosocGreen),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
