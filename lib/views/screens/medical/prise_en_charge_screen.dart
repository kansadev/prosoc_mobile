import 'package:flutter/material.dart';

import '../../../config/api.dart';
import '../../../config/colors.dart';
import '../../../models/medical/prise_en_charge_medicale_model.dart';
import '../../../services/auth_service.dart';
import '../../../utils/bon_envoi_qr_helper.dart';
import '../../../utils/medical_permissions.dart';
import '../../widgets/bon_envoi_scanner_sheet.dart';
import '../../widgets/prosoc_message_dialog.dart';
import '../../widgets/prosoc_resource_error_view.dart';
import 'widgets/medical_ui.dart';

/// Actions serveur partagées par le détail et le scan.
abstract final class _PriseEnChargeActions {
  /// Consommation (bon et jeton ensemble). Non rejouable : après une issue
  /// inconnue, la prise en charge est relue avant toute nouvelle tentative.
  static Future<PriseEnChargeMedicale?> consommer(
    BuildContext context,
    PriseEnChargeMedicale prise,
  ) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Consommer le bon'),
        content: Text(
          'Confirmer l\'utilisation du bon ${prise.numeroBon ?? ''} pour '
          '« ${prise.soinNom ?? 'ce soin'} » ? Le bon et le jeton ne pourront '
          'plus être réutilisés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.prosocGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Consommer'),
          ),
        ],
      ),
    );
    if (confirme != true || !context.mounted) return null;

    final response = await ApiService.utiliserPriseEnChargeMedicale(prise.id);
    if (!context.mounted) return null;
    if (response.success && response.data != null) return response.data;

    final status = response.statusCode;
    if (status == null || status >= 500) {
      final relue = await ApiService.getPriseEnChargeMedicale(prise.id);
      if (!context.mounted) return null;
      if (relue.success && relue.data != null) {
        if (relue.data!.estUtilise) return relue.data;
        await _message(
          context,
          'Bon non consommé',
          'La consommation n\'a pas été enregistrée. Vous pouvez réessayer.',
        );
        return relue.data;
      }
      await _message(
        context,
        'Issue inconnue',
        'Impossible de savoir si le bon a été consommé. Relisez la prise en '
            'charge avant toute nouvelle tentative.',
      );
      return null;
    }
    await _message(
      context,
      'Consommation refusée',
      response.message ?? 'Le bon ne peut pas être consommé.',
      statusCode: status,
    );
    return null;
  }

  /// Confirmation ou rejet (personnel `CONFIRM_DEMANDE_BON_ENVOI`).
  static Future<PriseEnChargeMedicale?> confirmer(
    BuildContext context,
    PriseEnChargeMedicale prise,
  ) async {
    final agentId = AuthService.agentId;
    if (agentId == null || agentId <= 0) {
      await _message(
        context,
        'Profil agent introuvable',
        'Reconnectez-vous avec un compte agent pour traiter cette demande.',
      );
      return null;
    }
    final decision = await showDialog<({bool accepter, String observation})>(
      context: context,
      builder: (_) => const _DecisionDialog(),
    );
    if (decision == null || !context.mounted) return null;

    final response = await ApiService.confirmerPriseEnChargeMedicale(
      prise.id,
      agentId: agentId,
      accepter: decision.accepter,
      observation: decision.observation.isEmpty ? null : decision.observation,
    );
    if (!context.mounted) return null;
    if (response.success && response.data != null) return response.data;
    await _message(
      context,
      'Traitement impossible',
      response.message ?? 'La demande n\'a pas pu être traitée.',
      statusCode: response.statusCode,
    );
    return null;
  }

  static Future<void> _message(
    BuildContext context,
    String title,
    String message, {
    int? statusCode,
  }) {
    return ProsocMessageDialog.show(
      context,
      variant: ProsocMessageVariant.error,
      title: title,
      message: message,
      statusCode: statusCode,
    );
  }
}

class _DecisionDialog extends StatefulWidget {
  const _DecisionDialog();

  @override
  State<_DecisionDialog> createState() => _DecisionDialogState();
}

class _DecisionDialogState extends State<_DecisionDialog> {
  final _observation = TextEditingController();

  @override
  void dispose() {
    _observation.dispose();
    super.dispose();
  }

  void _decider(bool accepter) {
    Navigator.of(context).pop((accepter: accepter, observation: _observation.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Traiter la demande'),
      content: TextField(
        controller: _observation,
        maxLength: 500,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Observation (facultative)',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => _decider(false),
          style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
          child: const Text('Rejeter'),
        ),
        ElevatedButton(
          onPressed: () => _decider(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.prosocGreen,
            foregroundColor: Colors.white,
          ),
          child: const Text('Valider'),
        ),
      ],
    );
  }
}

/// Informations d'une prise en charge (QR affiché pour un bon valide).
class PriseEnChargeDetails extends StatelessWidget {
  const PriseEnChargeDetails({super.key, required this.prise, this.showQr = true});

  final PriseEnChargeMedicale prise;
  final bool showQr;

  @override
  Widget build(BuildContext context) {
    final badge = prise.badge();
    final qr = showQr && badge == BadgePriseEnCharge.validee
        ? BonEnvoiQrHelper.decodeImageBase64(prise.qrCodeImageBase64)
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MedicalSection(
          title: prise.soinNom ?? 'Soin #${prise.soinId}',
          icon: Icons.assignment_outlined,
          trailing: MedicalBadge.priseEnCharge(badge),
          child: Column(
            children: [
              MedicalInfoRow('Demandée le', MedicalFormat.dateHeure(prise.dateDemandeUtc)),
              if (prise.motif != null) MedicalInfoRow('Motif', prise.motif!),
              if (prise.numeroBon != null) MedicalInfoRow('N° de bon', prise.numeroBon!),
              if (prise.codeJeton != null) MedicalInfoRow('Code jeton', prise.codeJeton!),
              if (prise.dateConfirmationUtc != null)
                MedicalInfoRow(
                  'Traitée le',
                  MedicalFormat.dateHeure(prise.dateConfirmationUtc),
                ),
              if (prise.dateExpirationUtc != null)
                MedicalInfoRow(
                  'Expire le',
                  MedicalFormat.dateHeure(prise.dateExpirationUtc),
                ),
              if (prise.observation != null)
                MedicalInfoRow('Observation', prise.observation!),
            ],
          ),
        ),
        if (qr != null)
          MedicalSection(
            title: 'QR code à présenter à l\'hôpital',
            icon: Icons.qr_code_2,
            child: Column(
              children: [
                Center(
                  child: Image.memory(
                    qr,
                    width: 220,
                    height: 220,
                    gaplessPlayback: true,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Usage unique, valable jusqu\'au '
                  '${MedicalFormat.dateHeure(prise.dateExpirationUtc)}.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Détail d'une prise en charge (membre ou personnel).
class PriseEnChargeScreen extends StatefulWidget {
  const PriseEnChargeScreen({super.key, required this.priseEnChargeId});

  final int priseEnChargeId;

  @override
  State<PriseEnChargeScreen> createState() => _PriseEnChargeScreenState();
}

class _PriseEnChargeScreenState extends State<PriseEnChargeScreen>
    with WidgetsBindingObserver, MedicalResumeRefresh {
  PriseEnChargeMedicale? _prise;
  bool _isLoading = true;
  bool _isActing = false;
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
    if (showLoader) setState(() => _isLoading = true);
    final response = await ApiService.getPriseEnChargeMedicale(
      widget.priseEnChargeId,
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _prise = response.data ?? _prise;
      _error = response.success ? null : response.message;
      _errorStatus = response.statusCode;
    });
  }

  Future<void> _agir(
    Future<PriseEnChargeMedicale?> Function(
      BuildContext,
      PriseEnChargeMedicale,
    ) action,
  ) async {
    final prise = _prise;
    if (prise == null || _isActing) return;
    setState(() => _isActing = true);
    await action(context, prise);
    if (!mounted) return;
    setState(() => _isActing = false);
    await _load(showLoader: false);
  }

  @override
  Widget build(BuildContext context) {
    final prise = _prise;
    final peutTraiter =
        prise != null && prise.estEnAttente && MedicalPermissions.peutConfirmerPriseEnCharge;
    final peutConsommer =
        prise != null &&
        prise.badge() == BadgePriseEnCharge.validee &&
        MedicalPermissions.peutConsommer;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Prise en charge'),
        backgroundColor: AppColors.prosocGreen,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: peutTraiter || peutConsommer
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _isActing
                      ? null
                      : () => _agir(
                          peutTraiter
                              ? _PriseEnChargeActions.confirmer
                              : _PriseEnChargeActions.consommer,
                        ),
                  icon: Icon(peutTraiter ? Icons.fact_check_outlined : Icons.done_all),
                  label: Text(peutTraiter ? 'Traiter la demande' : 'Consommer le bon'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.prosocGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => _load(showLoader: false),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : prise == null
            ? ListView(
                children: [
                  ProsocResourceErrorView(
                    message: _error ?? 'Prise en charge introuvable.',
                    statusCode: _errorStatus,
                    onRetry: _load,
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Le personnel ne voit pas le QR : il le scanne.
                  PriseEnChargeDetails(
                    prise: prise,
                    showQr: MedicalPermissions.estMembre,
                  ),
                ],
              ),
      ),
    );
  }
}

/// Scan d'un bon médical au moment du soin : vérification puis consommation
/// explicite. N'utilise jamais l'endpoint historique JetonMedical.
class MedicalScanScreen extends StatefulWidget {
  const MedicalScanScreen({super.key});

  @override
  State<MedicalScanScreen> createState() => _MedicalScanScreenState();
}

class _MedicalScanScreenState extends State<MedicalScanScreen> {
  PriseEnChargeMedicale? _verifiee;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scanner());
  }

  Future<void> _scanner() async {
    if (_isBusy) return;
    // Contenu exact lu par la caméra, transmis sans reconstruction.
    final payload = await BonEnvoiScannerSheet.show(context);
    if (payload == null || payload.isEmpty || !mounted) return;
    setState(() {
      _isBusy = true;
      _verifiee = null;
    });
    final response = await ApiService.scannerPriseEnChargeMedicale(payload);
    if (!mounted) return;
    setState(() {
      _isBusy = false;
      _verifiee = response.data;
    });
    if (!response.success) {
      await ProsocMessageDialog.show(
        context,
        variant: ProsocMessageVariant.error,
        title: 'Bon non valide',
        message: response.message ?? 'Ce QR code n\'a pas pu être vérifié.',
        statusCode: response.statusCode,
      );
    }
  }

  Future<void> _consommer() async {
    final prise = _verifiee;
    if (prise == null || _isBusy) return;
    setState(() => _isBusy = true);
    final result = await _PriseEnChargeActions.consommer(context, prise);
    if (!mounted) return;
    setState(() {
      _isBusy = false;
      if (result != null) _verifiee = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final prise = _verifiee;
    final peutConsommer =
        prise != null &&
        prise.badge() == BadgePriseEnCharge.validee &&
        MedicalPermissions.peutConsommer;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Scanner un bon médical'),
        backgroundColor: AppColors.prosocGreen,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_isBusy) const LinearProgressIndicator(color: AppColors.prosocGreen),
          if (prise == null && !_isBusy)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'Scannez le QR code présenté par l\'affilié pour vérifier son '
                'bon de prise en charge.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
          if (prise != null) ...[
            PriseEnChargeDetails(prise: prise, showQr: false),
            if (prise.estUtilise)
              Text(
                'Ce bon a déjà été utilisé.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
          const SizedBox(height: 16),
          if (peutConsommer)
            ElevatedButton.icon(
              onPressed: _isBusy ? null : _consommer,
              icon: const Icon(Icons.done_all),
              label: const Text('Consommer le bon'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.prosocGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _isBusy ? null : _scanner,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scanner un autre bon'),
          ),
        ],
      ),
    );
  }
}
