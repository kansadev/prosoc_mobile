import 'package:flutter/material.dart';

import '../../../config/api.dart';
import '../../../config/colors.dart';
import '../../../models/collecte_receipt_data.dart';
import '../../../models/medical/paiement_medical_model.dart';
import '../../../models/medical/souscription_medicale_model.dart';
import '../../../services/auth_service.dart';
import '../../../utils/collecte_receipt_helper.dart';
import '../../../utils/guid.dart';
import '../../widgets/devise_paiement_selector.dart';
import '../../widgets/prosoc_message_dialog.dart';
import 'widgets/medical_ui.dart';

/// Encaissement au guichet d'une période (opérateur `CREATE_COLLECTE`).
///
/// Idempotence : un GUID par versement, conservé jusqu'au résultat définitif.
/// Après timeout / 5xx, le versement est relu puis repris avec **le même GUID
/// et le même corps** ; un nouveau GUID n'est créé que pour un nouveau
/// versement. Renvoie `true` après un encaissement réussi.
class MedicalGuichetSheet extends StatefulWidget {
  const MedicalGuichetSheet({
    super.key,
    required this.periode,
    this.affilieNom,
  });

  final PeriodeCouvertureMedicale periode;
  final String? affilieNom;

  static Future<bool?> show(
    BuildContext context,
    PeriodeCouvertureMedicale periode, {
    String? affilieNom,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          MedicalGuichetSheet(periode: periode, affilieNom: affilieNom),
    );
  }

  @override
  State<MedicalGuichetSheet> createState() => _MedicalGuichetSheetState();
}

class _MedicalGuichetSheetState extends State<MedicalGuichetSheet> {
  final _montantController = TextEditingController();
  late final DevisePaiementController _devisePaiement;
  String _mode = PaiementMedicalModes.virtualAccount;
  bool _fondsRecus = false;
  bool _isSubmitting = false;

  /// Versement en cours dont l'issue n'est pas définitive : le formulaire est
  /// figé tant qu'il existe.
  PaiementMedicalGuichetRequest? _pending;
  String? _pendingMessage;

  PeriodeCouvertureMedicale get _periode => widget.periode;

  @override
  void initState() {
    super.initState();
    final solde = _periode.soldeRestant;
    _montantController.text = solde == solde.truncateToDouble()
        ? solde.toInt().toString()
        : solde.toStringAsFixed(2);
    _devisePaiement = DevisePaiementController(
      operation: () => (deviseId: _periode.deviseId, montant: _montantSaisi),
      triggers: _montantController,
    )..loadDevises();
  }

  @override
  void dispose() {
    _devisePaiement.dispose();
    _montantController.dispose();
    super.dispose();
  }

  double? get _montantSaisi =>
      double.tryParse(_montantController.text.trim().replaceAll(',', '.'));

  bool get _formulaireFige => _pending != null || _isSubmitting;

  String? _valider() {
    final montant = _montantSaisi;
    if (montant == null || montant < 0.01) return 'Montant invalide.';
    if ((montant * 100).roundToDouble() != montant * 100) {
      return 'Deux décimales maximum.';
    }
    if (montant > _periode.soldeRestant + 0.001) {
      return 'Le montant dépasse le solde restant.';
    }
    if (PaiementMedicalModes.exigeConfirmationFonds(_mode) && !_fondsRecus) {
      return 'Confirmez la réception effective des fonds avant la saisie.';
    }
    return null;
  }

  Future<void> _nouveauVersement() async {
    if (_formulaireFige) return;
    final erreur = _valider();
    if (erreur != null) {
      await _alerte('Encaissement impossible', erreur);
      return;
    }
    setState(() => _isSubmitting = true);

    if (_mode == PaiementMedicalModes.espece) {
      final caisse = await ApiService.getSessionCaisseCourante();
      if (!mounted) return;
      if (!caisse.success || caisse.data == null || !caisse.data!.isOuverte) {
        setState(() => _isSubmitting = false);
        await _alerte(
          'Caisse fermée',
          'Ouvrez votre session de caisse avant d\'encaisser des espèces.',
        );
        return;
      }
    }

    final paiement = await _devisePaiement.resolve(enabled: true);
    if (!mounted) return;
    if (!paiement.isReady) {
      setState(() => _isSubmitting = false);
      await _alerte('Encaissement impossible', paiement.blockingMessage!);
      return;
    }

    _pending = PaiementMedicalGuichetRequest(
      idPaiement: Guid.v4(),
      periodeCouvertureMedicaleId: _periode.id,
      montant: paiement.montant!,
      deviseId: paiement.deviseId!,
      modePaiement: _mode,
    );
    await _envoyer();
  }

  /// Envoie (ou renvoie à l'identique) le versement en attente.
  Future<void> _envoyer() async {
    final request = _pending;
    if (request == null) return;
    setState(() {
      _isSubmitting = true;
      _pendingMessage = null;
    });
    final response = await ApiService.encaisserPaiementMedical(request);
    if (!mounted) return;

    if (response.success && response.data != null) {
      await _succes(response.data!);
      return;
    }
    final status = response.statusCode;
    if (status == null || status >= 500) {
      // Issue inconnue : relire avant de proposer la reprise.
      await _verifier(silencieux: true);
      return;
    }
    // Refus définitif (4xx, dont 409 conflit / collision) : versement clos.
    setState(() {
      _isSubmitting = false;
      _pending = null;
    });
    await _alerte(
      status == 409 ? 'Conflit' : 'Encaissement refusé',
      response.message ?? 'Le versement a été refusé.',
      hint: status == 409
          ? 'La période a pu évoluer : elle sera rechargée.'
          : null,
    );
    if (status == 409 && mounted) Navigator.of(context).pop(false);
  }

  /// Consulte le versement en attente par son GUID.
  Future<void> _verifier({bool silencieux = false}) async {
    final request = _pending;
    if (request == null) return;
    setState(() => _isSubmitting = true);
    final response = await ApiService.getPaiementMedical(request.idPaiement);
    if (!mounted) return;
    if (response.success && response.data != null) {
      await _succes(response.data!);
      return;
    }
    setState(() {
      _isSubmitting = false;
      _pendingMessage = response.statusCode == 404
          ? 'Aucun encaissement enregistré pour ce versement. Vous pouvez le '
                'reprendre : le même identifiant sera renvoyé, sans double '
                'débit.'
          : 'Impossible de vérifier le versement pour le moment. Reprenez ou '
                'vérifiez à nouveau.';
    });
    if (!silencieux) {
      await _alerte('Versement non confirmé', _pendingMessage!);
    }
  }

  Future<void> _succes(PaiementMedicalRead result) async {
    setState(() {
      _isSubmitting = false;
      _pending = null;
    });
    await CollecteReceiptHelper.open(
      context,
      receipt: CollecteReceiptData(
        operation: CollecteReceiptOperation.prestationMedicale,
        montant: result.montant,
        deviseId: result.deviseId,
        deviseCode: MedicalDevises.codeFor(result.deviseId),
        reference: result.idPaiement,
        modePaiement:
            PaiementMedicalModes.guichet[_mode] ?? _mode,
        affilieNom: widget.affilieNom,
        agentNom: AuthService.currentUser?.utilisateur.nomComplet,
        idCollecte: result.collecteId,
        statutPaiement: 'OK',
        extras: {
          'Période': MedicalFormat.mois(_periode.annee, _periode.mois),
          'Montant crédité': MedicalDevises.montant(
            result.montantCredite,
            deviseId: result.deviseTarifId,
          ),
        },
      ),
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _alerte(String title, String message, {String? hint}) {
    return ProsocMessageDialog.show(
      context,
      variant: ProsocMessageVariant.error,
      title: title,
      message: message,
      hint: hint,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _pending;
    return PopScope(
      // Un versement à l'issue inconnue doit être résolu avant de fermer.
      canPop: pending == null && !_isSubmitting,
      child: SafeArea(
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Encaisser ${MedicalFormat.mois(_periode.annee, _periode.mois)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (pending == null && !_isSubmitting)
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
                Text(
                  'Solde restant : ${MedicalDevises.montant(_periode.soldeRestant, deviseId: _periode.deviseId)}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _montantController,
                  enabled: !_formulaireFige,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Montant (devise du tarif)',
                    suffixText: MedicalDevises.codeFor(_periode.deviseId),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _mode,
                  decoration: const InputDecoration(
                    labelText: 'Mode d\'encaissement',
                    border: OutlineInputBorder(),
                  ),
                  items: PaiementMedicalModes.guichet.entries
                      .map(
                        (e) =>
                            DropdownMenuItem(value: e.key, child: Text(e.value)),
                      )
                      .toList(),
                  onChanged: _formulaireFige
                      ? null
                      : (v) {
                          if (v != null) {
                            setState(() {
                              _mode = v;
                              _fondsRecus = false;
                            });
                          }
                        },
                ),
                if (PaiementMedicalModes.exigeConfirmationFonds(_mode))
                  CheckboxListTile(
                    value: _fondsRecus,
                    onChanged: _formulaireFige
                        ? null
                        : (v) => setState(() => _fondsRecus = v ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.prosocGreen,
                    title: const Text(
                      'Je confirme la réception effective des fonds.',
                      style: TextStyle(fontSize: 13.5),
                    ),
                  ),
                const SizedBox(height: 12),
                IgnorePointer(
                  ignoring: _formulaireFige,
                  child: DevisePaiementSelector(
                    controller: _devisePaiement,
                    decoration: const InputDecoration(
                      labelText: 'Devise encaissée',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (pending == null)
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _nouveauVersement,
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
                        : const Text('Encaisser'),
                  )
                else
                  _buildReprise(pending),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReprise(PaiementMedicalGuichetRequest pending) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Text(
            _pendingMessage ??
                'Issue du versement en cours de vérification…',
            style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _envoyer,
          icon: const Icon(Icons.replay),
          label: const Text('Reprendre ce versement'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.prosocGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _isSubmitting ? null : () => _verifier(),
          icon: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.search),
          label: const Text('Vérifier à nouveau'),
        ),
        TextButton(
          onPressed: _isSubmitting ? null : _fermerSansConclure,
          child: const Text('Fermer et vérifier plus tard'),
        ),
      ],
    );
  }

  Future<void> _fermerSansConclure() async {
    final reference = _pending?.idPaiement;
    final quitter = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Versement non confirmé'),
        content: Text(
          'L\'encaissement a peut-être abouti. Avant tout nouveau versement, '
          'vérifiez le solde de la période.\n\nRéférence : $reference',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Rester'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
    if (quitter != true || !mounted) return;
    setState(() => _pending = null);
    Navigator.of(context).pop(false);
  }
}
