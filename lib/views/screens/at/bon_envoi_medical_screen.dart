import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prosoc/config/api.dart';
import 'package:prosoc/config/colors.dart';
import 'package:prosoc/models/demande_bon_envoi_model.dart';
import 'package:prosoc/services/auth_service.dart';
import 'package:prosoc/utils/api_error_helper.dart';
import 'package:prosoc/utils/formatters.dart';
import 'package:prosoc/views/widgets/bon_envoi_qr_view.dart';
import 'package:prosoc/views/widgets/empty_state_widget.dart';
import 'package:prosoc/views/widgets/prosoc_resource_error_view.dart';

enum _BonMedicalTab { enAttente, validees, traitees }

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

  Future<List<DemandeBonEnvoiModel>> _fetchStatut(String statut) async {
    final response = await ApiService.getDemandesBonEnvoiByStatut(statut);
    if (response.success && response.data != null) {
      return response.data!;
    }
    return [];
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

      setState(() {
        _enAttente = results[0];
        _validees = results[1];
        _traitees = results[2];
        _isLoading = false;
        _errorMessage = null;
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

    final observation = await _askText(
      title: 'Confirmer la demande',
      label: 'Observation agent (optionnel)',
      hint: 'Ex. Dossier conforme, bon émis',
      confirmLabel: 'Confirmer et générer',
    );
    if (!mounted) return;
    if (observation == null) return;

    setState(() => _actionDemandeId = demande.idDemande);

    try {
      final response = await ApiService.confirmerDemandeBonEnvoi(
        demande.idDemande,
        agentId: agentId,
        observationAgent: observation,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        final result = response.data!;
        _showSnack(
          'Bon ${result.bonEnvoiNumero.isNotEmpty ? result.bonEnvoiNumero : ''} '
          'et jeton ${result.jetonMedicalCode.isNotEmpty ? result.jetonMedicalCode : ''} '
          'générés',
        );
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
    final payload = await _askText(
      title: 'Scanner un bon d\'envoi',
      label: 'Contenu QR ou numéro de bon',
      hint: 'Collez le payload QR ou le numéro BE-...',
      confirmLabel: 'Vérifier',
      required: true,
    );
    if (!mounted || payload == null) return;

    try {
      final isNumero = payload.toUpperCase().startsWith('BE-') ||
          payload.toUpperCase().contains('BON');
      final response = await ApiService.scannerBonEnvoi(
        qrCodePayload: isNumero ? '' : payload,
        numeroBon: isNumero ? payload : null,
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

  Future<String?> _askText({
    required String title,
    required String label,
    required String hint,
    required String confirmLabel,
    bool required = false,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (required && value.isEmpty) return;
                Navigator.pop(ctx, value);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.prosocGreen,
              ),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return result;
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
            if (tab == _BonMedicalTab.enAttente)
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
            else if (tab == _BonMedicalTab.validees && d.hasCoupleBonJeton)
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
