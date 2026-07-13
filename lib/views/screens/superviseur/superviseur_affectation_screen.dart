import 'package:flutter/material.dart';

import '../../../config/api.dart';
import '../../../config/colors.dart';
import '../../../models/adhesion_en_ligne_model.dart';
import '../../../models/agent_affecter_affilies_model.dart';
import '../../../models/agent_model.dart';
import '../../../services/auth_service.dart';
import '../../../utils/api_error_helper.dart';
import '../../../utils/formatters.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/prosoc_resource_error_view.dart';

/// File d'attente adhésions en ligne sans gestionnaire + affectation vers un AT.
class SuperviseurAffectationScreen extends StatefulWidget {
  const SuperviseurAffectationScreen({super.key});

  @override
  State<SuperviseurAffectationScreen> createState() =>
      _SuperviseurAffectationScreenState();
}

class _SuperviseurAffectationScreenState
    extends State<SuperviseurAffectationScreen> {
  final _searchController = TextEditingController();
  final List<AdhesionEnLigneSansGestionnaireModel> _items = [];
  List<AgentModel> _agents = [];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int? _errorStatusCode;
  int _page = 1;
  bool _hasNext = false;
  int? _affectingAffilieId;

  @override
  void initState() {
    super.initState();
    _loadAgents();
    _loadPage(refresh: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AdhesionEnLigneSansGestionnaireModel> get _filteredItems {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((item) {
      return item.nomComplet.toLowerCase().contains(q) ||
          item.codeAdhesion.toLowerCase().contains(q) ||
          (item.provinceResidence?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Future<void> _loadAgents() async {
    final superviseurId = AuthService.superviseurId;
    if (superviseurId == null) return;

    try {
      final response = await ApiService.getAgentsBySuperviseur(superviseurId);
      if (!mounted) return;
      if (response.success && response.data != null) {
        setState(() => _agents = response.data!);
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException(
        'SuperviseurAffectation/agents',
        e,
        stackTrace,
        false,
      );
    }
  }

  Future<void> _loadPage({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _errorStatusCode = null;
        _page = 1;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final response = await ApiService.getAdhesionsEnLigneSansGestionnaire(
        page: _page,
        pageSize: 20,
      );

      if (!mounted) return;

      if (!response.success || response.data == null) {
        setState(() {
          _errorMessage = response.message ??
              ApiErrorHelper.userFacingMessage(statusCode: response.statusCode);
          _errorStatusCode = response.statusCode;
          _isLoading = false;
          _isLoadingMore = false;
        });
        return;
      }

      final page = response.data!;
      setState(() {
        if (refresh) {
          _items
            ..clear()
            ..addAll(page.items);
        } else {
          _items.addAll(page.items);
        }
        _hasNext = page.hasNext;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e, stackTrace) {
      ApiErrorHelper.logException(
        'SuperviseurAffectation/list',
        e,
        stackTrace,
        false,
      );
      if (!mounted) return;
      setState(() {
        _errorMessage = ApiErrorHelper.userFacingNetwork();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasNext || _isLoadingMore) return;
    _page++;
    await _loadPage();
  }

  Future<void> _openAffectationSheet(
    AdhesionEnLigneSansGestionnaireModel dossier,
  ) async {
    if (_agents.isEmpty) {
      _showSnack('Aucun agent disponible dans votre équipe.', isError: true);
      return;
    }

    final agent = await showModalBottomSheet<AgentModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Affecter à un agent',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  dossier.nomComplet,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _agents.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final a = _agents[index];
                      final name = a.nomComplet.isNotEmpty
                          ? a.nomComplet
                          : 'Agent #${a.id}';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.prosocGreen.withValues(alpha: 0.12),
                          child: const Icon(
                            Icons.person_outline,
                            color: AppColors.prosocGreen,
                          ),
                        ),
                        title: Text(name),
                        subtitle: a.matricule.isNotEmpty
                            ? Text(a.matricule)
                            : null,
                        onTap: () => Navigator.pop(ctx, a),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (agent == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer l\'affectation'),
        content: Text(
          'Affecter ${dossier.nomComplet} à '
          '${agent.nomComplet.isNotEmpty ? agent.nomComplet : 'l\'agent sélectionné'} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.prosocGreen,
            ),
            child: const Text('Affecter'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _affecter(dossier, agent);
  }

  Future<void> _affecter(
    AdhesionEnLigneSansGestionnaireModel dossier,
    AgentModel agent,
  ) async {
    setState(() => _affectingAffilieId = dossier.idAffilie);

    try {
      final response = await ApiService.affecterAffiliesToAgent(
        agent.id,
        affilieIds: [dossier.idAffilie],
      );

      if (!mounted) return;

      if (!response.success || response.data == null) {
        _showSnack(
          response.message ?? 'Échec de l\'affectation',
          isError: true,
        );
        return;
      }

      final result = response.data!;
      await _showAffectationResult(result);

      if (result.totalReussites > 0) {
        setState(() {
          _items.removeWhere((i) => i.idAffilie == dossier.idAffilie);
        });
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException(
        'SuperviseurAffectation/affecter',
        e,
        stackTrace,
      );
      if (mounted) {
        _showSnack(ApiErrorHelper.userFacingNetwork(), isError: true);
      }
    } finally {
      if (mounted) setState(() => _affectingAffilieId = null);
    }
  }

  Future<void> _showAffectationResult(
    AgentAffecterAffiliesResultModel result,
  ) async {
    final messages = result.resultats
        .map((r) => '${r.succes ? '✓' : '✗'} ${r.message}')
        .join('\n');

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          result.totalReussites > 0
              ? 'Affectation réussie'
              : 'Affectation partielle ou échouée',
        ),
        content: Text(
          '${result.totalReussites}/${result.totalDemandes} réussite(s).\n\n$messages',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.errorColor : AppColors.prosocGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final rows = _filteredItems;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Adhésions sans gestionnaire',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.prosocGreen,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Rechercher (nom, code, province)…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark ? theme.cardColor : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.prosocGreen,
                    ),
                  )
                : _errorMessage != null
                    ? ProsocResourceErrorView(
                        message: _errorMessage!,
                        statusCode: _errorStatusCode,
                        onRetry: () => _loadPage(refresh: true),
                      )
                    : RefreshIndicator(
                        color: AppColors.prosocGreen,
                        onRefresh: () => _loadPage(refresh: true),
                        child: rows.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 120),
                                  EmptyStateWidget(
                                    icon: Icons.inbox_outlined,
                                    title: 'Aucun dossier en attente',
                                    subtitle:
                                        'Les nouvelles adhésions en ligne apparaîtront ici.',
                                  ),
                                ],
                              )
                            : ListView.separated(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(16),
                                itemCount: rows.length + (_hasNext ? 1 : 0),
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  if (index >= rows.length) {
                                    if (_isLoadingMore) {
                                      return const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: CircularProgressIndicator(
                                            color: AppColors.prosocGreen,
                                          ),
                                        ),
                                      );
                                    }
                                    return Center(
                                      child: TextButton(
                                        onPressed: _loadMore,
                                        child: const Text('Charger plus'),
                                      ),
                                    );
                                  }
                                  return _buildCard(rows[index], isDark);
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(AdhesionEnLigneSansGestionnaireModel item, bool isDark) {
    final isBusy = _affectingAffilieId == item.idAffilie;

    return Card(
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
                    item.nomComplet,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                _chip(item.statutDossier, AppColors.prosocGreen),
              ],
            ),
            const SizedBox(height: 8),
            _info(Icons.badge_outlined, item.codeAdhesion),
            if (item.telephone.isNotEmpty)
              _info(Icons.phone_outlined, item.telephone),
            if (item.provinceResidence?.isNotEmpty == true)
              _info(Icons.location_on_outlined, item.provinceResidence!),
            if (item.dateAdhesion != null)
              _info(
                Icons.calendar_today_outlined,
                AppFormatters.formatDate(item.dateAdhesion),
              ),
            if (item.modePaiementAdhesion?.isNotEmpty == true)
              _info(Icons.payment_outlined, item.modePaiementAdhesion!),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isBusy ? null : () => _openAffectationSheet(item),
                icon: isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.person_add_alt_1),
                label: const Text('Affecter à un agent'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.prosocGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(IconData icon, String text) {
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

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
