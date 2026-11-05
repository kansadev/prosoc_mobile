import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prosoc/config/api.dart';
import 'package:prosoc/config/colors.dart';
import 'package:prosoc/models/demande_bon_envoi_model.dart';
import 'package:prosoc/models/hopital_partenaire_model.dart';
import 'package:prosoc/services/auth_service.dart';
import 'package:prosoc/utils/api_error_helper.dart';
import 'package:prosoc/utils/formatters.dart';
import 'package:prosoc/utils/medical_permissions.dart';
import 'package:prosoc/views/widgets/bon_envoi_qr_view.dart';
import 'package:prosoc/views/widgets/bon_envoi_scanner_sheet.dart';
import 'package:prosoc/views/widgets/empty_state_widget.dart';
import 'package:prosoc/views/widgets/prosoc_resource_error_view.dart';

enum _BonMedicalTab { enAttente, validees, traitees }

class _BonEnvoiConfirmerResult {
  const _BonEnvoiConfirmerResult({
    required this.hopitalPartenaireId,
    required this.observationAgent,
  });

  final int hopitalPartenaireId;
  final String observationAgent;
}

/// Gestion agent : confirmation demandes → couple BonEnvoi + JetonMedical.
class BonEnvoiMedicalScreen extends StatefulWidget {
  const BonEnvoiMedicalScreen({super.key});

  @override
  State<BonEnvoiMedicalScreen> createState() => _BonEnvoiMedicalScreenState();
}

class _BonEnvoiMedicalScreenState extends State<BonEnvoiMedicalScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<DemandeBonEnvoiModel> _enAttente = [];
  List<DemandeBonEnvoiModel> _validees = [];
  List<DemandeBonEnvoiModel> _traitees = [];

  bool _isLoading = true;
  String? _errorMessage;
  int? _errorStatusCode;
  int? _actionDemandeId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int? get _agentId => AuthService.agentId;

  Future<ApiResponse<List<DemandeBonEnvoiModel>>> _fetchStatut(
    String statut,
  ) {
    return ApiService.getDemandesBonEnvoiByStatut(statut);
  }

  Future<void> _loadAll({bool showLoader = true}) async {
    if (!mounted) return;

    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _errorStatusCode = null;
      });
    }

    try {
      final results = await Future.wait([
        _fetchStatut('EN_ATTENTE'),
        _fetchStatut('VALIDEE'),
        _fetchStatut('TRAITEE'),
      ]);

      if (!mounted) return;

      final failures = results.where((r) => !r.success).toList();
      final allFailed = failures.length == results.length;

      if (allFailed) {
        final firstFailure = failures.first;
        setState(() {
          _errorMessage = firstFailure.message ??
              ApiErrorHelper.userFacingMessage(
                statusCode: firstFailure.statusCode,
              );
          _errorStatusCode = firstFailure.statusCode;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _enAttente = results[0].success ? (results[0].data ?? []) : [];
        _validees = results[1].success ? (results[1].data ?? []) : [];
        _traitees = results[2].success ? (results[2].data ?? []) : [];
        _isLoading = false;
        _errorMessage = null;
        _errorStatusCode = null;
      });
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('BonEnvoiMedical', e, stackTrace, false);
      if (!mounted) return;
      setState(() {
        _errorMessage = ApiErrorHelper.userFacingNetwork();
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmerDemande(DemandeBonEnvoiModel demande) async {
    final agentId = _agentId;
    if (agentId == null) {
      _showSnack('Agent non identifié', isError: true);
      return;
    }

    final form = await _askConfirmerDemande();
    if (!mounted) return;
    if (form == null) return;

    setState(() => _actionDemandeId = demande.idDemande);

    try {
      final response = await ApiService.confirmerDemandeBonEnvoi(
        demande.idDemande,
        agentId: agentId,
        accepter: true,
        hopitalPartenaireId: form.hopitalPartenaireId,
        observationAgent: form.observationAgent,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        final result = response.data!;
        await _showJetonDemandeurDialog(result);
        if (!mounted) return;
        await _loadAll(showLoader: false);
      } else {
        _showSnack(
          response.message ??
              'Impossible de confirmer la demande (bon + jeton).',
          isError: true,
        );
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('BonEnvoi/confirmer', e, stackTrace, false);
      if (!mounted) return;
      _showSnack(ApiErrorHelper.userFacingNetwork(), isError: true);
    } finally {
      if (mounted) setState(() => _actionDemandeId = null);
    }
  }

  Future<void> _utiliserJeton(DemandeBonEnvoiModel demande) async {
    if (demande.jetonMedicalId <= 0 || demande.jetonMedicalCode.isEmpty) {
      _showSnack('Jeton médical introuvable pour cette demande', isError: true);
      return;
    }

    final observation = await _askText(
      title: 'Utiliser le jeton médical',
      label: 'Observation (optionnel)',
      hint: 'Ex. Soins effectués à l\'hôpital',
      confirmLabel: 'Utiliser',
    );
    if (!mounted) return;
    if (observation == null) return;

    setState(() => _actionDemandeId = demande.idDemande);

    try {
      final response = await ApiService.utiliserJetonMedical(
        idJetonMedical: demande.jetonMedicalId,
        codeJeton: demande.jetonMedicalCode,
        observation: observation,
      );

      if (!mounted) return;

      if (response.success) {
        _showSnack('Jeton utilisé avec succès');
        await _loadAll(showLoader: false);
      } else {
        _showSnack(
          response.message ?? 'Utilisation du jeton refusée',
          isError: true,
        );
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('JetonMedical/utiliser', e, stackTrace, false);
      if (!mounted) return;
      _showSnack(ApiErrorHelper.userFacingNetwork(), isError: true);
    } finally {
      if (mounted) setState(() => _actionDemandeId = null);
    }
  }

  Future<void> _scannerBon() async {
    final payload = await BonEnvoiScannerSheet.show(context);
    if (!mounted || payload == null) return;

    final trimmed = payload.trim();
    if (trimmed.isEmpty) return;

    try {
      final isNumero = trimmed.toUpperCase().startsWith('BE-') ||
          trimmed.toUpperCase().contains('BON');
      final response = await ApiService.scannerBonEnvoi(
        qrCodePayload: isNumero ? '' : trimmed,
        numeroBon: isNumero ? trimmed : null,
      );

      if (!mounted) return;

      if (response.success) {
        _showSnack('Bon valide — jeton lié conforme');
        await _loadAll(showLoader: false);
      } else {
        _showSnack(
          response.message ??
              'Scan refusé (jeton introuvable, invalide, expiré ou déjà utilisé)',
          isError: true,
        );
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('BonEnvoi/scanner', e, stackTrace, false);
      if (!mounted) return;
      _showSnack(ApiErrorHelper.userFacingNetwork(), isError: true);
    }
  }

  Future<_BonEnvoiConfirmerResult?> _askConfirmerDemande() {
    return showModalBottomSheet<_BonEnvoiConfirmerResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _BonEnvoiConfirmerSheet(),
    );
  }

  Future<String?> _askText({
    required String title,
    required String label,
    required String hint,
    required String confirmLabel,
    bool required = false,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _BonEnvoiAskTextSheet(
          title: title,
          label: label,
          hint: hint,
          confirmLabel: confirmLabel,
          requiredField: required,
        );
      },
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.errorColor : AppColors.prosocGreen,
      ),
    );
  }

  void _copy(String label, String value) {
    if (value.trim().isEmpty) return;
    Clipboard.setData(ClipboardData(text: value));
    _showSnack('$label copié');
  }

  Future<void> _showJetonDemandeurDialog(DemandeBonEnvoiModel result) async {
    final jeton = result.jetonMedicalCode.trim();
    final bon = result.bonEnvoiNumero.trim();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Bon et jeton générés'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Le jeton est maintenant disponible chez le demandeur. '
                'Contrôlez-le au guichet avant utilisation.',
              ),
              if (bon.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Bon', style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                SelectableText(
                  bon,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
              if (jeton.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Jeton', style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                SelectableText(
                  jeton,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    letterSpacing: 1.2,
                    color: AppColors.prosocGreen,
                  ),
                ),
                if (result.jetonDateExpiration != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Expire le : ${AppFormatters.formatDateTime(result.jetonDateExpiration)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ] else
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Jeton généré — le demandeur le verra dans son espace bons.',
                  ),
                ),
            ],
          ),
          actions: [
            if (jeton.isNotEmpty)
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: jeton));
                  Navigator.pop(ctx);
                  _showSnack('Jeton copié');
                },
                child: const Text('Copier le jeton'),
              ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.prosocGreen,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bons médicaux',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.prosocGreen,
        foregroundColor: Colors.white,
        actions: [
          if (MedicalPermissions.peutScanner)
            IconButton(
              tooltip: 'Scanner un bon',
              onPressed: _scannerBon,
              icon: const Icon(Icons.qr_code_scanner_rounded),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'En attente (${_enAttente.length})'),
            Tab(text: 'Validées (${_validees.length})'),
            Tab(text: 'Traitées (${_traitees.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.prosocGreen),
            )
          : _errorMessage != null
              ? ProsocResourceErrorView(
                  message: _errorMessage!,
                  statusCode: _errorStatusCode,
                  onRetry: () => _loadAll(),
                )
              : RefreshIndicator(
                  color: AppColors.prosocGreen,
                  onRefresh: () => _loadAll(showLoader: false),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(
                        demandes: _enAttente,
                        tab: _BonMedicalTab.enAttente,
                        emptyMessage: 'Aucune demande en attente',
                      ),
                      _buildList(
                        demandes: _validees,
                        tab: _BonMedicalTab.validees,
                        emptyMessage: 'Aucune demande validée',
                      ),
                      _buildList(
                        demandes: _traitees,
                        tab: _BonMedicalTab.traitees,
                        emptyMessage: 'Aucune demande traitée',
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildList({
    required List<DemandeBonEnvoiModel> demandes,
    required _BonMedicalTab tab,
    required String emptyMessage,
  }) {
    if (demandes.isEmpty) {
      return EmptyStateScrollable(
        icon: Icons.medical_information_outlined,
        title: emptyMessage,
        subtitle: tab == _BonMedicalTab.enAttente
            ? 'Les demandes confirmées génèrent automatiquement un bon et un jeton liés.'
            : null,
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: demandes.length,
      itemBuilder: (context, index) {
        return _buildDemandeCard(demandes[index], tab);
      },
    );
  }

  Widget _buildDemandeCard(DemandeBonEnvoiModel d, _BonMedicalTab tab) {
    final isBusy = _actionDemandeId == d.idDemande;
    final statut = d.statutDemande.isNotEmpty ? d.statutDemande : '—';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.affilieNom.isNotEmpty
                            ? d.affilieNom
                            : 'Affilié #${d.affilieId}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      if (d.prestationNom.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          d.prestationNom,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        [
                          if (d.dateDemande != null)
                            AppFormatters.formatDate(d.dateDemande),
                          d.typeDemande,
                        ].where((s) => s.isNotEmpty).join(' · '),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.prosocGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statut,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.prosocGreen,
                    ),
                  ),
                ),
              ],
            ),
            if (d.motifDemande.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                d.motifDemande,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
            if (d.hasCoupleBonJeton) ...[
              const SizedBox(height: 10),
              _linkRow(
                'Bon',
                d.bonEnvoiNumero.isNotEmpty
                    ? d.bonEnvoiNumero
                    : '#${d.bonEnvoiId}',
                onCopy: () => _copy('Bon', d.bonEnvoiNumero),
              ),
              const SizedBox(height: 4),
              _linkRow(
                'Jeton',
                d.jetonMedicalCode.isNotEmpty
                    ? d.jetonMedicalCode
                    : '#${d.jetonMedicalId}',
                onCopy: () => _copy('Jeton', d.jetonMedicalCode),
              ),
            ],
            if (d.hasQr) ...[
              const SizedBox(height: 12),
              Center(
                child: BonEnvoiQrView(
                  qrCodeImageBase64: d.qrCodeImageBase64,
                  qrCodePayload: d.qrCodePayload,
                  size: 120,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (tab == _BonMedicalTab.enAttente &&
                MedicalPermissions.peutConfirmerPriseEnCharge)
              FilledButton.icon(
                onPressed: isBusy ? null : () => _confirmerDemande(d),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.prosocGreen,
                ),
                icon: isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.verified_outlined, size: 18),
                label: const Text('Confirmer (bon + jeton)'),
              )
            else if (tab == _BonMedicalTab.validees &&
                d.hasCoupleBonJeton &&
                MedicalPermissions.peutConsommer)
              OutlinedButton.icon(
                onPressed: isBusy ? null : () => _utiliserJeton(d),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Utiliser le jeton'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _linkRow(String label, String value, {VoidCallback? onCopy}) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        if (onCopy != null)
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded, size: 18),
          ),
      ],
    );
  }
}

class _BonEnvoiConfirmerSheet extends StatefulWidget {
  const _BonEnvoiConfirmerSheet();

  @override
  State<_BonEnvoiConfirmerSheet> createState() =>
      _BonEnvoiConfirmerSheetState();
}

class _BonEnvoiConfirmerSheetState extends State<_BonEnvoiConfirmerSheet> {
  late final TextEditingController _observationController;
  List<HopitalPartenaireModel> _hopitaux = [];
  int? _selectedId;
  bool _loading = true;
  String? _loadError;
  String? _hopitalError;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _observationController = TextEditingController();
    _loadHopitaux();
  }

  @override
  void dispose() {
    _observationController.dispose();
    super.dispose();
  }

  Future<void> _loadHopitaux() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final response = await ApiService.getHopitauxPartenairesActifs();
      if (!mounted) return;

      if (!response.success) {
        setState(() {
          _loading = false;
          _loadError = response.message ??
              'Impossible de charger les hôpitaux partenaires.';
          _hopitaux = [];
          _selectedId = null;
        });
        return;
      }

      final list = List<HopitalPartenaireModel>.from(response.data ?? [])
        ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));

      setState(() {
        _hopitaux = list;
        _selectedId = list.length == 1 ? list.first.idHopital : null;
        _loading = false;
        _loadError = list.isEmpty
            ? 'Aucun hôpital partenaire actif disponible.'
            : null;
      });
    } catch (e, stackTrace) {
      ApiErrorHelper.logException(
        'BonEnvoi/hopitaux',
        e,
        stackTrace,
        false,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = ApiErrorHelper.userFacingNetwork();
        _hopitaux = [];
        _selectedId = null;
      });
    }
  }

  void _submit() {
    if (_submitted || _loading) return;
    final hopitalId = _selectedId;
    if (hopitalId == null || hopitalId <= 0) {
      setState(() => _hopitalError = 'Sélectionnez un hôpital partenaire');
      return;
    }
    _submitted = true;
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(
      _BonEnvoiConfirmerResult(
        hopitalPartenaireId: hopitalId,
        observationAgent: _observationController.text.trim(),
      ),
    );
  }

  void _cancel() {
    if (_submitted) return;
    _submitted = true;
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final canSubmit =
        !_loading && _selectedId != null && _loadError == null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 16),
            const Text(
              'Confirmer la demande',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'L’hôpital partenaire est obligatoire pour générer le bon et le jeton.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_loadError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.errorColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  _loadError!,
                  style: const TextStyle(
                    color: AppColors.errorColor,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _loadHopitaux,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
              ),
            ] else
              DropdownButtonFormField<int>(
                key: ValueKey(
                  'hopitaux-${_hopitaux.map((h) => h.idHopital).join('-')}',
                ),
                initialValue: _selectedId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Hôpital partenaire *',
                  errorText: _hopitalError,
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
                items: _hopitaux
                    .map(
                      (h) => DropdownMenuItem<int>(
                        value: h.idHopital,
                        child: Text(
                          h.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedId = value;
                    _hopitalError = null;
                  });
                },
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _observationController,
              maxLines: 3,
              enabled: !_loading && _loadError == null,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Observation agent (optionnel)',
                hintText: 'Ex. Dossier conforme, bon émis',
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
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: canSubmit ? _submit : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.prosocGreen,
                      disabledBackgroundColor:
                          AppColors.prosocGreen.withValues(alpha: 0.4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Confirmer et générer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BonEnvoiAskTextSheet extends StatefulWidget {
  const _BonEnvoiAskTextSheet({
    required this.title,
    required this.label,
    required this.hint,
    required this.confirmLabel,
    required this.requiredField,
  });

  final String title;
  final String label;
  final String hint;
  final String confirmLabel;
  final bool requiredField;

  @override
  State<_BonEnvoiAskTextSheet> createState() => _BonEnvoiAskTextSheetState();
}

class _BonEnvoiAskTextSheetState extends State<_BonEnvoiAskTextSheet> {
  late final TextEditingController _controller;
  String? _errorText;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_submitted) return;
    final value = _controller.text.trim();
    if (widget.requiredField && value.isEmpty) {
      setState(() => _errorText = 'Ce champ est requis');
      return;
    }
    _submitted = true;
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(value);
  }

  void _cancel() {
    if (_submitted) return;
    _submitted = true;
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: widget.label,
                hintText: widget.hint,
                errorText: _errorText,
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
                if (_errorText != null) setState(() => _errorText = null);
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.prosocGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(widget.confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
