import 'dart:async';

import 'package:flutter/material.dart';

import '../../../config/colors.dart';
import '../../../models/adhesion_with_affilie_model.dart';
import '../../../utils/formatters.dart';

/// Page dédiée pendant la validation FlexPay (Mobile Money, etc.).
///
/// TODO(SignalR) : s'abonner au hub temps réel avec [idCollecteEnAttente]
/// pour fermer automatiquement cet écran en cas de succès ou d'échec.
/// Le polling HTTP a été retiré — en attendant, l'agent confirme manuellement.
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
  Timer? _expiryTimer;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _scheduleExpiryCheck();
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }

  void _scheduleExpiryCheck() {
    final expiresAt = widget.payment.holdExpireAt;
    if (expiresAt == null) return;

    void check() {
      if (!mounted) return;
      if (DateTime.now().isAfter(expiresAt)) {
        setState(() => _isExpired = true);
        _expiryTimer?.cancel();
      }
    }

    check();
    _expiryTimer = Timer.periodic(const Duration(seconds: 30), (_) => check());
  }

  Future<void> _onManualPaymentConfirmed() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Icon(
          Icons.check_circle,
          color: AppColors.prosocGreen,
          size: 64,
        ),
        content: const Text(
          'Paiement enregistré.\nL\'adhésion a été initiée.',
          textAlign: TextAlign.center,
          style: TextStyle(
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
        ? 'En attente de validation sur le téléphone de l\'affilié…'
        : 'En attente de confirmation du paiement…';

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
                        child: Icon(
                          _isExpired
                              ? Icons.timer_off_outlined
                              : Icons.sync,
                          size: 72,
                          color: _isExpired
                              ? Colors.orange
                              : AppColors.prosocGreen,
                        ),
                      ),
                      Text(
                        _isExpired
                            ? 'Délai de paiement expiré. Relancez l\'adhésion si nécessaire.'
                            : (message?.isNotEmpty == true
                                ? message!
                                : statusFallback),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (!_isExpired) ...[
                        const SizedBox(height: 12),
                        Text(
                          widget.isMobileMoney
                              ? 'Demandez à l\'affilié de valider la demande '
                                  'Mobile Money sur son téléphone.'
                              : 'Finalisez le paiement sur l\'appareil de l\'affilié.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'La fermeture automatique sera disponible via SignalR.',
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
                    ],
                  ),
                ),
              ),
              if (!_isExpired) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _onManualPaymentConfirmed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.prosocGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Paiement validé par l\'affilié'),
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
                  child: Text(_isExpired ? 'Fermer' : 'Quitter sans confirmer'),
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
