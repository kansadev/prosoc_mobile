import 'package:flutter/material.dart';

import '../../../config/api.dart';
import '../../../config/colors.dart';
import '../../../models/collecte_receipt_data.dart';
import '../../../models/medical/catalogue_medical_model.dart';
import '../../../models/medical/prise_en_charge_medicale_model.dart';
import '../../../models/medical/souscription_medicale_model.dart';
import '../../../utils/medical_permissions.dart';
import '../../widgets/flex_pay_card_payment_bottom_sheet.dart';
import '../../widgets/prosoc_message_dialog.dart';
import '../../widgets/prosoc_resource_error_view.dart';
import '../at/flex_pay_payment_waiting_screen.dart';
import '../at/payment_webview_screen.dart';
import 'medical_catalogue_screen.dart';
import 'medical_guichet_sheet.dart';
import 'medical_paiement_sheet.dart';
import 'prise_en_charge_screen.dart';
import 'widgets/medical_ui.dart';

/// Détail d'une période de couverture : solde, droits, soins de la version
/// figée, paiements et prises en charge.
class MedicalPeriodeScreen extends StatefulWidget {
  const MedicalPeriodeScreen({
    super.key,
    required this.periodeId,
    required this.offreId,
    required this.affilieId,
    this.affilieNom,
  });

  final int periodeId;
  final int offreId;
  final int affilieId;
  final String? affilieNom;

  @override
  State<MedicalPeriodeScreen> createState() => _MedicalPeriodeScreenState();
}

class _MedicalPeriodeScreenState extends State<MedicalPeriodeScreen>
    with WidgetsBindingObserver, MedicalResumeRefresh {
  PeriodeCouvertureMedicale? _periode;
  VersionOffreMedicale? _version;
  List<PriseEnChargeMedicale> _prisesEnCharge = const [];
  bool _isLoading = true;
  String? _error;
  int? _errorStatus;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Future<void> onResumeRefresh() => _load(showLoader: false);

  Future<void> _load({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    await MedicalDevises.ensureLoaded();
    final periode = await ApiService.getPeriodeMedicale(widget.periodeId);
    if (!mounted) return;
    if (!periode.success || periode.data == null) {
      setState(() {
        _isLoading = false;
        _error = periode.message;
        _errorStatus = periode.statusCode;
      });
      return;
    }

    // Soins de la période = version figée, jamais la version courante.
    VersionOffreMedicale? version = _version;
    if (version?.id != periode.data!.versionOffreMedicaleId) {
      final versions = await ApiService.getVersionsOffreMedicale(widget.offreId);
      version = versions.data
          ?.where((v) => v.id == periode.data!.versionOffreMedicaleId)
          .firstOrNull;
    }

    var prises = _prisesEnCharge;
    if (MedicalPermissions.peutConsulterPrisesEnCharge) {
      final response = await ApiService.getPrisesEnChargeByPeriode(
        widget.periodeId,
      );
      if (response.success && response.data != null) {
        prises = [...response.data!]
          ..sort(
            (a, b) => (b.dateDemandeUtc ?? DateTime(0)).compareTo(
              a.dateDemandeUtc ?? DateTime(0),
            ),
          );
      }
    }
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _error = null;
      _periode = periode.data;
      _version = version;
      _prisesEnCharge = prises;
    });
  }

  // --- Paiement -----------------------------------------------------------

  Future<void> _payer() async {
    final periode = _periode;
    if (periode == null) return;
    final guichet = MedicalPermissions.peutEncaisserGuichet;
    final electronique = MedicalPermissions.peutPayerElectronique;

    var choix = electronique ? 'electronique' : 'guichet';
    if (guichet && electronique) {
      final selected = await showModalBottomSheet<String>(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.point_of_sale_outlined),
                title: const Text('Encaissement au guichet'),
                subtitle: const Text('Compte virtuel, espèces, chèque, virement'),
                onTap: () => Navigator.of(sheetContext).pop('guichet'),
              ),
              ListTile(
                leading: const Icon(Icons.phone_android_outlined),
                title: const Text('Paiement électronique'),
                subtitle: const Text('Mobile money ou carte'),
                onTap: () => Navigator.of(sheetContext).pop('electronique'),
              ),
            ],
          ),
        ),
      );
      if (selected == null || !mounted) return;
      choix = selected;
    }

    if (choix == 'guichet') {
      await MedicalGuichetSheet.show(
        context,
        periode,
        affilieNom: widget.affilieNom,
      );
    } else {
      final initiation = await MedicalPaiementSheet.show(context, periode);
      if (initiation != null && mounted) await _suivreInitiation(initiation);
    }
    if (mounted) await _load(showLoader: false);
  }

  /// Suivi d'une initiation acceptée. Aucun succès n'est affiché sur la seule
  /// initiation ni sur un retour navigateur : confirmation serveur requise.
  Future<void> _suivreInitiation(MedicalInitiationResult initiation) async {
    final payment = initiation.payment;
    final url = payment.paymentUrl?.trim() ?? '';
    final hasUrl = url.isNotEmpty && url.toLowerCase() != 'null';

    Future<bool?> attendre({required bool mobileMoney}) {
      return Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => FlexPayPaymentWaitingScreen(
            payment: payment,
            isMobileMoney: mobileMoney,
            receiptOperation: CollecteReceiptOperation.prestationMedicale,
            affilieNom: widget.affilieNom,
            modePaiement: initiation.modePaiement,
          ),
        ),
      );
    }

    bool? confirme;
    if (initiation.isMobileMoney || !hasUrl) {
      confirme = await attendre(mobileMoney: initiation.isMobileMoney);
    } else {
      await FlexPayCardPaymentBottomSheet.show(
        context,
        payment: payment,
        onPay: () async {
          await PaymentWebViewScreen.open(context, url);
          if (!mounted) return;
          confirme = await attendre(mobileMoney: false);
        },
      );
    }

    // Après confirmation, l'attente devient l'idPaiement : relire le paiement
    // (un 404 signifie seulement « pas encore finalisé ») puis la période.
    final idAttente = payment.idCollecteEnAttente;
    if (confirme == true && idAttente != null && idAttente.isNotEmpty) {
      await ApiService.getPaiementMedical(idAttente);
    }
  }

  // --- Prise en charge ------------------------------------------------------

  Future<void> _demanderPriseEnCharge() async {
    final periode = _periode;
    final version = _version;
    if (periode == null || version == null) return;
    final created = await showModalBottomSheet<PriseEnChargeMedicale>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DemandePriseEnChargeSheet(
        periodeId: periode.id,
        soins: version.soins,
      ),
    );
    if (!mounted) return;
    if (created != null) {
      await _ouvrirPriseEnCharge(created.id);
    } else {
      await _load(showLoader: false);
    }
  }

  Future<void> _ouvrirPriseEnCharge(int id) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PriseEnChargeScreen(priseEnChargeId: id)),
    );
    if (mounted) await _load(showLoader: false);
  }

  @override
  Widget build(BuildContext context) {
    final periode = _periode;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          periode == null
              ? 'Période'
              : MedicalFormat.mois(periode.annee, periode.mois),
        ),
        backgroundColor: AppColors.prosocGreen,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(showLoader: false),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : periode == null
            ? ListView(
                children: [
                  ProsocResourceErrorView(
                    message: _error ?? 'Période introuvable.',
                    statusCode: _errorStatus,
                    onRetry: _load,
                  ),
                ],
              )
            : _buildContent(periode),
      ),
    );
  }

  Widget _buildContent(PeriodeCouvertureMedicale periode) {
    final etat = periode.etat();
    final peutPayer =
        periode.soldeRestant > 0 &&
        etat != EtatPeriodeMedicale.expire &&
        (MedicalPermissions.peutPayerElectronique ||
            MedicalPermissions.peutEncaisserGuichet);
    final peutDemander =
        periode.droitsOuverts &&
        MedicalPermissions.peutDemanderPriseEnCharge &&
        (_version?.soins.isNotEmpty ?? false);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        MedicalSection(
          title: 'Couverture',
          icon: Icons.shield_outlined,
          trailing: MedicalBadge.periode(etat),
          child: Column(
            children: [
              MedicalInfoRow(
                'Montant dû',
                MedicalDevises.montant(periode.montantDu, deviseId: periode.deviseId),
              ),
              MedicalInfoRow(
                'Montant payé',
                MedicalDevises.montant(
                  periode.montantValide,
                  deviseId: periode.deviseId,
                ),
              ),
              MedicalInfoRow(
                'Solde restant',
                MedicalDevises.montant(
                  periode.soldeRestant,
                  deviseId: periode.deviseId,
                ),
                emphasize: true,
              ),
              MedicalInfoRow(
                'Début des droits',
                MedicalFormat.dateHeure(periode.dateDebutDroitsUtc),
              ),
              MedicalInfoRow(
                'Fin (exclue)',
                MedicalFormat.dateHeure(periode.dateFinExclusiveUtc),
              ),
              if (etat == EtatPeriodeMedicale.paiementPartiel)
                _note(
                  'Paiement partiel : les droits s\'ouvriront une fois le mois '
                  'entièrement soldé.',
                ),
              if (etat == EtatPeriodeMedicale.payeAVenir)
                _note('Mois soldé : les droits commencent au début du mois.'),
              if (etat == EtatPeriodeMedicale.droitsIndisponibles)
                _note(
                  'Les droits ne sont pas ouverts pour cette période. Si un '
                  'paiement vient d\'être confirmé, actualisez ; sinon '
                  'contactez le support.',
                ),
            ],
          ),
        ),
        if (peutPayer || peutDemander)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                if (peutPayer)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _payer,
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Payer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.prosocGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                if (peutPayer && peutDemander) const SizedBox(width: 12),
                if (peutDemander)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _demanderPriseEnCharge,
                      icon: const Icon(Icons.assignment_outlined),
                      label: const Text('Prise en charge'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.prosocGreen,
                        side: const BorderSide(color: AppColors.prosocGreen),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (_version != null)
          MedicalSoinsSection(
            soins: _version!.soins,
            title: 'Soins couverts ce mois',
          )
        else
          _note('Liste des soins de cette période indisponible.'),
        if (MedicalPermissions.peutConsulterPrisesEnCharge)
          MedicalSection(
            title: 'Prises en charge',
            icon: Icons.assignment_outlined,
            child: _prisesEnCharge.isEmpty
                ? Text(
                    'Aucune demande pour cette période.',
                    style: TextStyle(color: Colors.grey.shade600),
                  )
                : Column(
                    children: _prisesEnCharge
                        .map(
                          (p) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              p.soinNom ?? 'Soin #${p.soinId}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              'Demandée le ${MedicalFormat.dateHeure(p.dateDemandeUtc)}',
                            ),
                            trailing: MedicalBadge.priseEnCharge(p.badge()),
                            onTap: () => _ouvrirPriseEnCharge(p.id),
                          ),
                        )
                        .toList(),
                  ),
          ),
      ],
    );
  }

  Widget _note(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade800)),
    );
  }
}

/// Demande de prise en charge d'un soin inclus dans la version payée.
class _DemandePriseEnChargeSheet extends StatefulWidget {
  const _DemandePriseEnChargeSheet({required this.periodeId, required this.soins});

  final int periodeId;
  final List<SoinCouvert> soins;

  @override
  State<_DemandePriseEnChargeSheet> createState() =>
      _DemandePriseEnChargeSheetState();
}

class _DemandePriseEnChargeSheetState extends State<_DemandePriseEnChargeSheet> {
  final _motifController = TextEditingController();
  int? _soinId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _motifController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final soinId = _soinId;
    if (soinId == null || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    final motif = _motifController.text.trim();
    final response = await ApiService.createPriseEnChargeMedicale(
      periodeCouvertureMedicaleId: widget.periodeId,
      soinId: soinId,
      motif: motif.isEmpty ? null : motif,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (response.success && response.data != null) {
      Navigator.of(context).pop(response.data);
      return;
    }
    await ProsocMessageDialog.show(
      context,
      variant: ProsocMessageVariant.error,
      title: 'Demande impossible',
      message: response.message ?? 'La demande n\'a pas pu être créée.',
      statusCode: response.statusCode,
      hint: response.statusCode == null
          ? 'Consultez la liste des prises en charge avant de refaire la '
                'demande : elle a pu être enregistrée.'
          : null,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Demander une prise en charge',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _soinId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Soin',
                border: OutlineInputBorder(),
              ),
              items: widget.soins
                  .map(
                    (s) => DropdownMenuItem(value: s.soinId, child: Text(s.nom)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _soinId = v),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _motifController,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Motif (facultatif)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _soinId == null || _isSubmitting ? null : _submit,
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
                  : const Text('Envoyer la demande'),
            ),
          ],
        ),
      ),
    );
  }
}
