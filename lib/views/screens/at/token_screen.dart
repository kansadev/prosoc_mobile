import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prosoc/config/api.dart';
import 'package:prosoc/config/colors.dart';
import 'package:prosoc/models/retrait_agent_model.dart';
import 'package:prosoc/services/auth_service.dart';
import 'package:prosoc/utils/api_error_helper.dart';
import 'package:prosoc/utils/formatters.dart';
import 'package:prosoc/views/widgets/empty_state_widget.dart';
import 'package:prosoc/views/widgets/prosoc_resource_error_view.dart';

enum _JetonTab { enAttente, validees, traitees }

/// Gestion des jetons de retrait agent
/// (`en-attente`, `validees`, `traitees`, `valider-et-generer-jeton`, `utiliser-jeton`).
class TokenScreen extends StatefulWidget {
  const TokenScreen({super.key});

  @override
  State<TokenScreen> createState() => _TokenScreenState();
}

class _TokenScreenState extends State<TokenScreen>
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

  int? get _agentId => AuthService.agentId;

  List<DemandeRetraitAgentModel> _filterForAgent(
    List<DemandeRetraitAgentModel> rows,
  ) {
    final agentId = _agentId;
    if (agentId == null) return rows;
    return rows.where((d) => d.agentId == agentId).toList();
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
        ApiService.getRetraitsEnAttente(),
        ApiService.getRetraitsValidees(),
        ApiService.getRetraitsTraitees(),
      ]);

      if (!mounted) return;

      final failed = results.where((r) => !r.success).toList();
      if (failed.isNotEmpty) {
        final first = failed.first;
        setState(() {
          _errorMessage =
              first.message ??
              ApiErrorHelper.userFacingMessage(statusCode: first.statusCode);
          _errorStatusCode = first.statusCode;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _enAttente = _filterForAgent(results[0].data ?? []);
        _validees = _filterForAgent(results[1].data ?? []);
        _traitees = _filterForAgent(results[2].data ?? []);
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('TokenScreen', e, stackTrace, false);
      if (!mounted) return;
      setState(() {
        _errorMessage = ApiErrorHelper.userFacingNetwork();
        _isLoading = false;
      });
    }
  }

  Future<void> _genererJeton(DemandeRetraitAgentModel demande) async {
    final agentId = _agentId;
    if (agentId == null) {
      _showSnack('Agent non identifié', isError: true);
      return;
    }

    setState(() => _actionDemandeId = demande.idDemande);

    try {
      final response = await ApiService.validerEtGenererJetonRetrait(
        idDemande: demande.idDemande,
        statutDemande: 'VALIDE',
        motifValidation: 'Validation automatique depuis l\'application',
        agentValidationId: agentId,
      );

      if (!mounted) return;

      if (response.success) {
        _showSnack('Jeton généré avec succès');
        await _loadAll(showLoader: false);
      } else {
        _showSnack(
          response.message ?? 'Erreur lors de la génération du jeton',
          isError: true,
        );
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('TokenScreen.genererJeton', e, stackTrace);
      if (!mounted) return;
      _showSnack(ApiErrorHelper.userFacingNetwork(), isError: true);
    } finally {
      if (mounted) setState(() => _actionDemandeId = null);
    }
  }

  Future<void> _utiliserJeton(DemandeRetraitAgentModel demande) async {
    final agentId = _agentId;
    if (agentId == null) {
      _showSnack('Agent non identifié', isError: true);
      return;
    }

    if (!demande.hasJeton || demande.jetonRetraitId <= 0) {
      _showSnack('Jeton invalide ou manquant', isError: true);
      return;
    }

    final observation = await _askObservation();
    if (observation == null || !mounted) return;

    setState(() => _actionDemandeId = demande.idDemande);

    try {
      final response = await ApiService.utiliserJetonRetraitAgent(
        idJeton: demande.jetonRetraitId,
        codeJeton: demande.jetonRetraitCode,
        agentId: agentId,
        observationUtilisation: observation,
      );

      if (!mounted) return;

      if (response.success) {
        _showSnack('Jeton utilisé avec succès');
        await _loadAll(showLoader: false);
      } else {
        _showSnack(
          response.message ?? 'Erreur lors de l\'utilisation du jeton',
          isError: true,
        );
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('TokenScreen.utiliserJeton', e, stackTrace);
      if (!mounted) return;
      _showSnack(ApiErrorHelper.userFacingNetwork(), isError: true);
    } finally {
      if (mounted) setState(() => _actionDemandeId = null);
    }
  }

  Future<String?> _askObservation() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Utiliser le jeton'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Observation (optionnel)',
              hintText: 'Ex. Retrait effectué en agence',
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
              child: const Text('Confirmer'),
            ),
          ],
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

  void _copyJeton(String code) {
    Clipboard.setData(ClipboardData(text: code));
    _showSnack('Code jeton copié');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Jetons de retrait',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.prosocGreen,
        foregroundColor: Colors.white,
        elevation: 0,
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
                    tab: _JetonTab.enAttente,
                    emptyMessage: 'Aucune demande en attente',
                    isDark: isDark,
                  ),
                  _buildList(
                    demandes: _validees,
                    tab: _JetonTab.validees,
                    emptyMessage: 'Aucune demande validée',
                    isDark: isDark,
                  ),
                  _buildList(
                    demandes: _traitees,
                    tab: _JetonTab.traitees,
                    emptyMessage: 'Aucune demande traitée',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildList({
    required List<DemandeRetraitAgentModel> demandes,
    required _JetonTab tab,
    required String emptyMessage,
    required bool isDark,
  }) {
    if (demandes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
          EmptyStateWidget(
            icon: Icons.token_outlined,
            title: emptyMessage,
            subtitle: 'Les demandes apparaîtront ici après soumission.',
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: demandes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _buildDemandeCard(demandes[index], tab, isDark),
    );
  }

  Widget _buildDemandeCard(
    DemandeRetraitAgentModel demande,
    _JetonTab tab,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final isBusy = _actionDemandeId == demande.idDemande;
    final cardColor = theme.cardColor;

    return Card(
      color: cardColor,
      elevation: isDark ? 0 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Demande #${demande.idDemande}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                _buildStatutChip(demande.statutDemande, tab),
              ],
            ),
            const SizedBox(height: 10),
            _infoRow(Icons.payments_outlined, demande.formattedMontant),
            if (demande.typeRetrait.isNotEmpty)
              _infoRow(Icons.category_outlined, demande.typeRetrait),
            if (demande.dateReference != null)
              _infoRow(
                Icons.calendar_today_outlined,
                AppFormatters.formatDate(demande.dateReference),
              ),
            if (demande.motifRetrait.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                demande.motifRetrait,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
            ],
            if (tab == _JetonTab.enAttente) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isBusy || demande.hasJeton
                      ? null
                      : () => _genererJeton(demande),
                  icon: isBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.qr_code_2_rounded),
                  label: Text(
                    demande.hasJeton ? 'Jeton déjà généré' : 'Générer le jeton',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.prosocGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
            if (tab == _JetonTab.validees && demande.hasJeton) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.prosocGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.prosocGreen.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Code jeton',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            demande.jetonRetraitCode,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copier',
                      onPressed: () => _copyJeton(demande.jetonRetraitCode),
                      icon: const Icon(Icons.copy_rounded),
                      color: AppColors.prosocGreen,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isBusy ? null : () => _utiliserJeton(demande),
                  icon: isBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Utiliser le jeton'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.prosocGreen,
                    side: const BorderSide(color: AppColors.prosocGreen),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
            if (tab == _JetonTab.traitees && demande.dateTraitement != null)
              _infoRow(
                Icons.done_all_rounded,
                'Traité le ${AppFormatters.formatDate(demande.dateTraitement)}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.prosocGreen),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildStatutChip(String statut, _JetonTab tab) {
    Color bg;
    Color fg;
    String label;

    switch (tab) {
      case _JetonTab.enAttente:
        bg = Colors.orange.withValues(alpha: 0.15);
        fg = Colors.orange.shade800;
        label = statut.isNotEmpty ? statut : 'En attente';
      case _JetonTab.validees:
        bg = AppColors.prosocGreen.withValues(alpha: 0.15);
        fg = AppColors.prosocGreen;
        label = statut.isNotEmpty ? statut : 'Validée';
      case _JetonTab.traitees:
        bg = Colors.blue.withValues(alpha: 0.12);
        fg = Colors.blue.shade700;
        label = statut.isNotEmpty ? statut : 'Traitée';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
