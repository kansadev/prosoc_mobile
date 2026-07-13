import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/api.dart';
import '../../../config/colors.dart';
import '../../../models/retrait_agent_model.dart';
import '../../../services/auth_service.dart';
import '../../../utils/api_error_helper.dart';
import '../../../utils/formatters.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/prosoc_resource_error_view.dart';

/// Validation et paiement des retraits agents par le percepteur (guichet).
class PercepteurRetraitsScreen extends StatefulWidget {
  const PercepteurRetraitsScreen({super.key});

  @override
  State<PercepteurRetraitsScreen> createState() =>
      _PercepteurRetraitsScreenState();
}

class _PercepteurRetraitsScreenState extends State<PercepteurRetraitsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<DemandeRetraitAgentModel> _enAttente = [];
  List<DemandeRetraitAgentModel> _validees = [];
  List<DemandeRetraitAgentModel> _traitees = [];

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

  int? get _validatorId => AuthService.agentId ?? AuthService.userId;

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
        ApiService.getRetraitsEnAttente(),
        ApiService.getRetraitsValidees(),
        ApiService.getRetraitsTraitees(),
      ]);

      if (!mounted) return;

      final failed = results.where((r) => !r.success).toList();
      if (failed.isNotEmpty) {
        final first = failed.first;
        setState(() {
          _errorMessage = first.message ??
              ApiErrorHelper.userFacingMessage(statusCode: first.statusCode);
          _errorStatusCode = first.statusCode;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _enAttente = results[0].data ?? [];
        _validees = results[1].data ?? [];
        _traitees = results[2].data ?? [];
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('PercepteurRetraits', e, stackTrace, false);
      if (!mounted) return;
      setState(() {
        _errorMessage = ApiErrorHelper.userFacingNetwork();
        _isLoading = false;
      });
    }
  }

  Future<void> _valider(DemandeRetraitAgentModel demande) async {
    final validatorId = _validatorId;
    if (validatorId == null) {
      _showSnack('Percepteur non identifié', isError: true);
      return;
    }

    setState(() => _actionDemandeId = demande.idDemande);

    try {
      final response = await ApiService.validerEtGenererJetonRetrait(
        idDemande: demande.idDemande,
        statutDemande: 'VALIDEE',
        motifValidation: 'Validation percepteur',
        agentValidationId: validatorId,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        await _showJetonDialog(response.data!);
        await _loadAll(showLoader: false);
      } else {
        _showSnack(
          response.message ?? 'Erreur lors de la validation',
          isError: true,
        );
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('PercepteurRetraits.valider', e, stackTrace);
      if (mounted) _showSnack(ApiErrorHelper.userFacingNetwork(), isError: true);
    } finally {
      if (mounted) setState(() => _actionDemandeId = null);
    }
  }

  Future<void> _rejeter(DemandeRetraitAgentModel demande) async {
    final validatorId = _validatorId;
    if (validatorId == null) {
      _showSnack('Percepteur non identifié', isError: true);
      return;
    }

    final motif = await _askMotifRejet();
    if (motif == null || motif.isEmpty || !mounted) return;

    setState(() => _actionDemandeId = demande.idDemande);

    try {
      final response = await ApiService.putRejeterDemandeRetraitAgent(
        id: demande.idDemande,
        idDemande: demande.idDemande,
        agentValidationId: validatorId,
        motifValidation: motif,
      );

      if (!mounted) return;

      if (response.success) {
        _showSnack('Demande rejetée');
        await _loadAll(showLoader: false);
      } else {
        _showSnack(
          response.message ?? 'Erreur lors du rejet',
          isError: true,
        );
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('PercepteurRetraits.rejeter', e, stackTrace);
      if (mounted) _showSnack(ApiErrorHelper.userFacingNetwork(), isError: true);
    } finally {
      if (mounted) setState(() => _actionDemandeId = null);
    }
  }

  Future<void> _payerJeton(DemandeRetraitAgentModel demande) async {
    if (!demande.hasJeton || demande.jetonRetraitId <= 0) {
      _showSnack('Jeton invalide ou manquant', isError: true);
      return;
    }

    final observation = await _askObservationPaiement();
    if (observation == null || !mounted) return;

    setState(() => _actionDemandeId = demande.idDemande);

    try {
      final response = await ApiService.utiliserJetonRetraitAgent(
        idJeton: demande.jetonRetraitId,
        codeJeton: demande.jetonRetraitCode,
        agentId: demande.agentId,
        observationUtilisation: observation,
      );

      if (!mounted) return;

      if (response.success) {
        _showSnack('Retrait payé avec succès');
        await _loadAll(showLoader: false);
      } else {
        final message = ApiErrorHelper.messageForUtiliserJetonRetraitError(
          statusCode: response.statusCode,
          serverMessage: response.message,
        );
        if (response.statusCode == 403) {
          await _showPaiementRefuseDialog(message);
        } else {
          _showSnack(message, isError: true);
        }
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('PercepteurRetraits.payer', e, stackTrace);
      if (mounted) _showSnack(ApiErrorHelper.userFacingNetwork(), isError: true);
    } finally {
      if (mounted) setState(() => _actionDemandeId = null);
    }
  }

  Future<String?> _askMotifRejet() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Motif du rejet'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Motif obligatoire',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(ctx, text);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.errorColor,
            ),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }

  Future<String?> _askObservationPaiement() async {
    final controller = TextEditingController(
      text: 'Paiement effectué au guichet percepteur',
    );
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer le paiement'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Observation',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.prosocGreen,
            ),
            child: const Text('Payer le retrait'),
          ),
        ],
      ),
    );
  }

  Future<void> _showJetonDialog(RetraitWorkflowResultModel result) async {
    final code = result.jetonCode ?? '';
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Jeton généré'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Remettez ce jeton à l\'agent lors du paiement au guichet.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            if (code.isNotEmpty) ...[
              Text(
                code,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppColors.prosocGreen,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  _showSnack('Code copié');
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copier le code'),
              ),
            ],
            if (result.montantRetrait != null)
              Text('Montant : ${result.montantRetrait}'),
            if (result.dateExpiration != null)
              Text(
                'Expire le : ${AppFormatters.formatDateTime(result.dateExpiration)}',
              ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.prosocGreen,
            ),
            child: const Text('Fermer'),
          ),
        ],
      ),
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

  Future<void> _showPaiementRefuseDialog(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.lock_outline_rounded,
          color: Colors.amber.shade800,
          size: 32,
        ),
        title: const Text('Paiement refusé'),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.prosocGreen,
            ),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Retraits agents',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.prosocGreen,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'En attente (${_enAttente.length})'),
            Tab(text: 'À payer (${_validees.length})'),
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
                        _enAttente,
                        showActions: true,
                        emptyMessage: 'Aucune demande en attente',
                        isDark: isDark,
                      ),
                      _buildList(
                        _validees,
                        showJeton: true,
                        showPayout: true,
                        emptyMessage: 'Aucun retrait à payer',
                        isDark: isDark,
                      ),
                      _buildList(
                        _traitees,
                        emptyMessage: 'Aucun retrait traité',
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildList(
    List<DemandeRetraitAgentModel> demandes, {
    required String emptyMessage,
    required bool isDark,
    bool showActions = false,
    bool showJeton = false,
    bool showPayout = false,
  }) {
    if (demandes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.15),
          EmptyStateWidget(
            icon: Icons.pending_actions_outlined,
            title: emptyMessage,
            subtitle:
                'Les agents terrain soumettent leurs demandes depuis leur wallet.',
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: demandes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildCard(
        demandes[index],
        isDark: isDark,
        showActions: showActions,
        showJeton: showJeton,
        showPayout: showPayout,
      ),
    );
  }

  Widget _buildCard(
    DemandeRetraitAgentModel demande, {
    required bool isDark,
    bool showActions = false,
    bool showJeton = false,
    bool showPayout = false,
  }) {
    final theme = Theme.of(context);
    final isBusy = _actionDemandeId == demande.idDemande;

    return Card(
      color: theme.cardColor,
      elevation: isDark ? 0 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Demande #${demande.idDemande}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (demande.agentNom.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                demande.agentNom,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 8),
            _info(Icons.payments_outlined, demande.formattedMontant),
            if (demande.typeRetrait.isNotEmpty)
              _info(Icons.category_outlined, demande.typeRetrait),
            if (demande.motifRetrait.isNotEmpty)
              _info(Icons.notes_outlined, demande.motifRetrait),
            if (demande.isRejetee && demande.motifRejet.isNotEmpty)
              _info(Icons.cancel_outlined, demande.motifRejet),
            if (showJeton && demande.hasJeton) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.prosocGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  demande.jetonRetraitCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
            if (showActions) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isBusy ? null : () => _rejeter(demande),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.errorColor,
                        side: const BorderSide(color: AppColors.errorColor),
                      ),
                      child: const Text('Rejeter'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: isBusy ? null : () => _valider(demande),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.prosocGreen,
                      ),
                      child: isBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Valider'),
                    ),
                  ),
                ],
              ),
            ],
            if (showPayout && demande.hasJeton) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isBusy ? null : () => _payerJeton(demande),
                  icon: isBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.payments_outlined),
                  label: const Text('Payer le retrait'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.prosocGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _info(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.prosocGreen),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
