import 'package:flutter/material.dart';

import '../../../config/api.dart';
import '../../../config/colors.dart';
import '../../../models/adhesion_with_affilie_model.dart';
import '../../../models/medical/paiement_medical_model.dart';
import '../../../models/medical/souscription_medicale_model.dart';
import '../../../services/auth_service.dart';
import '../../../utils/electronic_payment_error_handler.dart';
import '../../../utils/phone_utils.dart';
import '../../widgets/devise_paiement_selector.dart';
import '../../widgets/prosoc_message_dialog.dart';
import 'widgets/medical_ui.dart';

/// Résultat d'une initiation électronique acceptée.
class MedicalInitiationResult {
  const MedicalInitiationResult({
    required this.payment,
    required this.modePaiement,
  });

  final AdhesionElectronicPaymentResponse payment;
  final String modePaiement;

  bool get isMobileMoney => modePaiement == PaiementMedicalModes.mobileMoney;
}

/// Paiement électronique d'une période (membre ou opérateur). Un paiement
/// concerne une seule période ; les versements partiels n'ouvrent pas les
/// droits. Renvoie l'initiation acceptée (une attente, pas un encaissement).
class MedicalPaiementSheet extends StatefulWidget {
  const MedicalPaiementSheet({super.key, required this.periode});

  final PeriodeCouvertureMedicale periode;

  static Future<MedicalInitiationResult?> show(
    BuildContext context,
    PeriodeCouvertureMedicale periode,
  ) {
    return showModalBottomSheet<MedicalInitiationResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MedicalPaiementSheet(periode: periode),
    );
  }

  @override
  State<MedicalPaiementSheet> createState() => _MedicalPaiementSheetState();
}

class _MedicalPaiementSheetState extends State<MedicalPaiementSheet> {
  final _montantController = TextEditingController();
  final _telephoneController = TextEditingController();
  late final DevisePaiementController _devisePaiement;
  String _mode = PaiementMedicalModes.mobileMoney;
  bool _isSubmitting = false;

  PeriodeCouvertureMedicale get _periode => widget.periode;
  bool get _isMobileMoney => _mode == PaiementMedicalModes.mobileMoney;

  @override
  void initState() {
    super.initState();
    _montantController.text = _formatInput(_periode.soldeRestant);
    if (AuthService.currentUser?.isAdherentOrAffilie ?? false) {
      final tel = AuthService.currentUser?.utilisateur.telephone?.trim();
      if (tel != null && tel.isNotEmpty) _telephoneController.text = tel;
    }
    _devisePaiement = DevisePaiementController(
      operation: () => (deviseId: _periode.deviseId, montant: _montantSaisi),
      triggers: _montantController,
    )..loadDevises();
  }

  @override
  void dispose() {
    _devisePaiement.dispose();
    _montantController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  static String _formatInput(double value) =>
      value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);

  /// Montant dans la devise du tarif (point décimal, pas de séparateur).
  double? get _montantSaisi =>
      double.tryParse(_montantController.text.trim().replaceAll(',', '.'));

  String? _validerMontant() {
    final montant = _montantSaisi;
    if (montant == null || montant < 0.01) return 'Montant invalide.';
    if ((montant * 100).roundToDouble() != montant * 100) {
      return 'Deux décimales maximum.';
    }
    if (montant > _periode.soldeRestant + 0.001) {
      return 'Le montant dépasse le solde restant.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final erreur = _validerMontant();
    if (erreur != null) {
      await _alerte(erreur);
      return;
    }
    String? telephone;
    if (_isMobileMoney) {
      telephone = PhoneUtils.normalizeDrcPhone(_telephoneController.text);
      if (telephone == null) {
        await _alerte(PhoneUtils.invalidFormatMessage);
        return;
      }
    }

    setState(() => _isSubmitting = true);
    // Paiement dans une autre devise : montant converti par le serveur.
    final paiement = await _devisePaiement.resolve(enabled: _isMobileMoney);
    if (!mounted) return;
    if (!paiement.isReady) {
      setState(() => _isSubmitting = false);
      await _alerte(paiement.blockingMessage!);
      return;
    }

    final response = await ApiService.initierPaiementMedicalElectronique(
      periodeCouvertureMedicaleId: _periode.id,
      montant: paiement.montant!,
      deviseId: paiement.deviseId!,
      modePaiement: _mode,
      telephonePaiement: telephone,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (response.success && response.data != null) {
      final payment = response.data!;
      if (payment.flexPayAccepted) {
        Navigator.of(context).pop(
          MedicalInitiationResult(payment: payment, modePaiement: _mode),
        );
        return;
      }
      await _alerte(payment.message ?? 'Paiement non accepté par le prestataire.');
      return;
    }
    if (response.statusCode == null) {
      // Réponse perdue : ne jamais relancer automatiquement une initiation.
      await ProsocMessageDialog.show(
        context,
        variant: ProsocMessageVariant.warning,
        title: 'Issue inconnue',
        message: response.message ?? 'La réponse du serveur n\'a pas été reçue.',
        hint:
            'Un paiement a peut-être été initié. Vérifiez le solde de la '
            'période avant de relancer un paiement.',
      );
      return;
    }
    await ElectronicPaymentErrorHandler.show(context, response);
  }

  Future<void> _alerte(String message) {
    return ProsocMessageDialog.show(
      context,
      variant: ProsocMessageVariant.error,
      title: 'Paiement impossible',
      message: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Payer ${MedicalFormat.mois(_periode.annee, _periode.mois)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Solde restant : ${MedicalDevises.montant(_periode.soldeRestant, deviseId: _periode.deviseId)}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _montantController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Montant',
                  helperText:
                      'Versement partiel possible : les droits s\'ouvrent une '
                      'fois le mois soldé.',
                  helperMaxLines: 2,
                  suffixText: MedicalDevises.codeFor(_periode.deviseId),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _mode,
                decoration: const InputDecoration(
                  labelText: 'Mode de paiement',
                  border: OutlineInputBorder(),
                ),
                items: PaiementMedicalModes.electronique.entries
                    .map(
                      (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _mode = v);
                },
              ),
              if (_isMobileMoney) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _telephoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 20,
                  decoration: const InputDecoration(
                    labelText: 'Numéro Mobile Money',
                    hintText: '243XXXXXXXXX',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 4),
                DevisePaiementSelector(
                  controller: _devisePaiement,
                  decoration: const InputDecoration(
                    labelText: 'Devise de paiement',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.prosocGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Lancer le paiement'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
