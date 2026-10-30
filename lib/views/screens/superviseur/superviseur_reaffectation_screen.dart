import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/api.dart';
import '../../../config/colors.dart';
import '../../../models/agent_affilie_row_model.dart';
import '../../../models/agent_model.dart';
import '../../../services/auth_service.dart';
import '../../../utils/api_error_helper.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/prosoc_resource_error_view.dart';

/// Réaffectation d'un affilié déjà rattaché à un Agent AT vers un autre agent.
///
/// L'agent source est envoyé via `sourceAgentId` afin que le backend trace le
/// déplacement plutôt que de créer un doublon d'affectation.
class SuperviseurReaffectationScreen extends StatefulWidget {
  const SuperviseurReaffectationScreen({super.key});

  @override
  State<SuperviseurReaffectationScreen> createState() =>
      _SuperviseurReaffectationScreenState();
}

/// Trace locale d'une réaffectation, l'API n'exposant pas d'historique
/// affilié → agent en lecture.
class _ReaffectationJournal {
  final DateTime date;
  final String affilie;
  final String source;
  final String cible;
  final bool succes;
  final String message;

  const _ReaffectationJournal({
    required this.date,
    required this.affilie,
    required this.source,
    required this.cible,
    required this.succes,
    required this.message,
  });
}

class _SuperviseurReaffectationScreenState
    extends State<SuperviseurReaffectationScreen> {
  final _searchController = TextEditingController();
  final List<AgentAffilieRow> _affilies = [];
  final List<_ReaffectationJournal> _journal = [];

  List<AgentModel> _agents = [];
  AgentModel? _sourceAgent;

  bool _isLoadingAgents = true;
  bool _isLoadingAffilies = false;
  bool _isLoadingMore = false;
  bool _isSubmitting = false;
  String? _agentsError;
  String? _affiliesError;
  int _page = 1;
  bool _hasNext = false;
  int? _affilieIdEnCours;

  @override
  void initState() {
    super.initState();
    _loadAgents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _agentLabel(AgentModel agent) =>
      agent.nomComplet.isNotEmpty ? agent.nomComplet : 'Agent #${agent.id}';

  Future<void> _loadAgents() async {
    final superviseurId = AuthService.superviseurId;
    if (superviseurId == null) {
      setState(() {
        _isLoadingAgents = false;
        _agentsError = 'Superviseur non identifié. Reconnectez-vous.';
      });
      return;
    }

    setState(() {
      _isLoadingAgents = true;
      _agentsError = null;
    });

    try {
      final response = await ApiService.getAgentsBySuperviseur(superviseurId);
      if (!mounted) return;

      if (response.success && response.data != null) {
        final agents = response.data!;
        setState(() {
          _agents = agents;
          _isLoadingAgents = false;
          if (agents.length == 1) _selectSourceAgent(agents.first);
        });
        return;
      }

      setState(() {
        _isLoadingAgents = false;
        _agentsError =
            response.message ??
            ApiErrorHelper.userFacingMessage(statusCode: response.statusCode);
      });
    } catch (e, stackTrace) {
      if (!mounted) return;
      ApiErrorHelper.logException(
        'SuperviseurReaffectation/agents',
        e,
        stackTrace,
        false,
      );
      setState(() {
        _isLoadingAgents = false;
        _agentsError = ApiErrorHelper.userFacingNetwork();
      });
    }
  }

  void _selectSourceAgent(AgentModel agent) {
    setState(() {
      _sourceAgent = agent;
      _affilies.clear();
      _page = 1;
      _hasNext = false;
      _affiliesError = null;
    });
    _loadAffilies();
  }

  Future<void> _loadAffilies({bool loadMore = false}) async {
    final source = _sourceAgent;
    if (source == null) return;
    if (loadMore && (_isLoadingMore || !_hasNext)) return;

    if (loadMore) {
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoadingAffilies = true;
        _affiliesError = null;
      });
    }

    final search = _searchController.text.trim();

    try {
      final response = await ApiService.getAgentAffiliesRows(
        source.id,
        page: _page,
        pageSize: 20,
        search: search.isEmpty ? null : search,
      );
      if (!mounted) return;

      if (!response.success) {
        setState(() {
          _isLoadingAffilies = false;
          _isLoadingMore = false;
          _affiliesError =
              response.message ??
              ApiErrorHelper.userFacingMessage(statusCode: response.statusCode);
        });
        return;
      }

      final data = response.data!;
      setState(() {
        if (!loadMore) _affilies.clear();
        _affilies.addAll(data.rows);
        _hasNext = data.hasNext;
        _isLoadingAffilies = false;
        _isLoadingMore = false;
        _affiliesError = null;
      });
    } catch (e, stackTrace) {
      if (!mounted) return;
      ApiErrorHelper.logException(
        'SuperviseurReaffectation/affilies',
        e,
        stackTrace,
        false,
      );
      setState(() {
        _isLoadingAffilies = false;
        _isLoadingMore = false;
        _affiliesError = ApiErrorHelper.userFacingNetwork();
      });
    }
  }

  void _loadMoreAffilies() {
    _page++;
    _loadAffilies(loadMore: true);
  }

  Future<void> _reaffecter(AgentAffilieRow affilie) async {
    final source = _sourceAgent;
    if (source == null) return;

    if (affilie.idAffilie <= 0) {
      _showSnack(
        "Identifiant de l'affilié non communiqué par la plateforme.",
        isError: true,
      );
      return;
    }

    final cibles = _agents.where((a) => a.id != source.id).toList();
    if (cibles.isEmpty) {
      _showSnack(
        'Aucun autre agent disponible dans votre équipe.',
        isError: true,
      );
      return;
    }

    final cible = await showModalBottomSheet<AgentModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nouvel agent responsable',
                style: Theme.of(
                  ctx,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                '${affilie.nomComplet} · actuellement ${_agentLabel(source)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: cibles.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final agent = cibles[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.prosocGreen.withValues(
                          alpha: 0.12,
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: AppColors.prosocGreen,
                        ),
                      ),
                      title: Text(_agentLabel(agent)),
                      subtitle: agent.matricule.isNotEmpty
                          ? Text(agent.matricule)
                          : null,
                      onTap: () => Navigator.pop(ctx, agent),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (cible == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la réaffectation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(affilie.nomComplet),
            if (affilie.matricule.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Matricule ${affilie.matricule}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
            const SizedBox(height: 14),
            _transitionRow(
              label: 'Agent actuel',
              value: _agentLabel(source),
              color: AppColors.errorColor,
              icon: Icons.person_off_outlined,
            ),
            const SizedBox(height: 8),
            _transitionRow(
              label: 'Nouvel agent',
              value: _agentLabel(cible),
              color: AppColors.prosocGreen,
              icon: Icons.person_add_alt_1_outlined,
            ),
            const SizedBox(height: 14),
            Text(
              'Le portfolio de cet affilié (collectes, commissions et '
              'historique) sera transféré au nouvel agent.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
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
            child: const Text('Réaffecter'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _submit(affilie, source, cible);
  }

  Widget _transitionRow({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label : ',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submit(
    AgentAffilieRow affilie,
    AgentModel source,
    AgentModel cible,
  ) async {
    setState(() => _affilieIdEnCours = affilie.idAffilie);

    try {
      final response = await ApiService.affecterAffiliesToAgent(
        cible.id,
        affilieIds: [affilie.idAffilie],
        sourceAgentId: source.id,
      );

      if (!mounted) return;

      if (!response.success || response.data == null) {
        _showSnack(
          response.message ?? 'Échec de la réaffectation',
          isError: true,
        );
        return;
      }

      final result = response.data!;
      final item = result.resultats.isEmpty ? null : result.resultats.first;
      final succes = item?.succes ?? result.totalReussites > 0;

      setState(() {
        _journal.insert(
          0,
          _ReaffectationJournal(
            date: DateTime.now(),
            affilie: affilie.nomComplet,
            source: _agentLabel(source),
            cible: _agentLabel(cible),
            succes: succes,
            message: item?.message.isNotEmpty == true
                ? item!.message
                : succes
                ? 'Réaffectation effectuée'
                : 'Échec',
          ),
        );
        if (succes) {
          _affilies.removeWhere((a) => a.idAffilie == affilie.idAffilie);
        }
      });

      await _showResultDialog(
        succes: succes,
        affilie: affilie,
        source: source,
        cible: cible,
        ancienAgentRapporte: item?.ancienAgentId,
        message: item?.message ?? '',
      );
    } catch (e, stackTrace) {
      if (!mounted) return;
      ApiErrorHelper.logException(
        'SuperviseurReaffectation/submit',
        e,
        stackTrace,
        false,
      );
      _showSnack(ApiErrorHelper.userFacingNetwork(), isError: true);
    } finally {
      if (mounted) setState(() => _affilieIdEnCours = null);
    }
  }

  Future<void> _showResultDialog({
    required bool succes,
    required AgentAffilieRow affilie,
    required AgentModel source,
    required AgentModel cible,
    required int? ancienAgentRapporte,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          succes ? Icons.check_circle_outline_rounded : Icons.error_outline,
          color: succes ? AppColors.prosocGreen : AppColors.errorColor,
        ),
        title: Text(succes ? 'Réaffectation réussie' : 'Réaffectation échouée'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(affilie.nomComplet),
            const SizedBox(height: 12),
            if (ancienAgentRapporte != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Ancien agent enregistré par la plateforme : '
                  '#$ancienAgentRapporte'
                  '${ancienAgentRapporte == source.id ? ' (confirmé)' : ''}',
                  style: const TextStyle(fontSize: 11.5),
                ),
              ),
            if (message.isNotEmpty)
              Text(message, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            _transitionRow(
              label: 'De',
              value: _agentLabel(source),
              color: Colors.grey.shade700,
              icon: Icons.arrow_back_rounded,
            ),
            const SizedBox(height: 6),
            _transitionRow(
              label: 'Vers',
              value: _agentLabel(cible),
              color: AppColors.prosocGreen,
              icon: Icons.arrow_forward_rounded,
            ),
          ],
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Réaffecter un affilié',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoadingAgents) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.prosocGreen),
      );
    }

    if (_agentsError != null) {
      return ProsocResourceErrorView(
        message: _agentsError!,
        onRetry: _loadAgents,
      );
    }

    if (_agents.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.groups_outlined,
        title: 'Aucun agent à superviser',
        subtitle: 'Vous n\'avez pas encore d\'agents dans votre équipe.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildStep(
          number: 1,
          title: 'Agent actuellement responsable',
          child: _buildAgentPicker(),
        ),
        const SizedBox(height: 20),
        _buildStep(
          number: 2,
          title: 'Affilié à transférer',
          child: _buildAffilieList(),
        ),
        if (_journal.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildJournal(),
        ],
      ],
    );
  }

  Widget _buildStep({
    required int number,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.prosocGreen,
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildAgentPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: RadioGroup<int?>(
        groupValue: _sourceAgent?.id,
        onChanged: (value) {
          final agent = _agents.where((a) => a.id == value).firstOrNull;
          if (agent != null) _selectSourceAgent(agent);
        },
        child: Column(
          children: _agents
              .map(
                (agent) => RadioListTile<int?>(
                  value: agent.id,
                  activeColor: AppColors.prosocGreen,
                  dense: true,
                  title: Text(
                    _agentLabel(agent),
                    style: const TextStyle(fontSize: 13.5),
                  ),
                  subtitle: agent.matricule.isNotEmpty
                      ? Text(
                          agent.matricule,
                          style: const TextStyle(fontSize: 11.5),
                        )
                      : null,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildAffilieList() {
    if (_sourceAgent == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          'Sélectionnez d\'abord un agent responsable.',
          style: TextStyle(fontSize: 13),
        ),
      );
    }

    return Column(
      children: [
        TextField(
          controller: _searchController,
          onSubmitted: (_) {
            _page = 1;
            _loadAffilies();
          },
          decoration: InputDecoration(
            hintText: 'Rechercher un affilié',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: const Icon(Icons.arrow_forward_rounded),
              onPressed: () {
                _page = 1;
                _loadAffilies();
              },
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingAffilies)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: CircularProgressIndicator(color: AppColors.prosocGreen),
          )
        else if (_affiliesError != null)
          ProsocResourceErrorView(
            message: _affiliesError!,
            onRetry: () {
              _page = 1;
              _loadAffilies();
            },
          )
        else if (_affilies.isEmpty)
          const EmptyStateWidget(
            icon: Icons.person_search_outlined,
            title: 'Aucun affilié',
            subtitle: 'Cet agent n\'a aucun affilié rattaché.',
          )
        else
          ..._affilies.map(_buildAffilieTile),
        if (_hasNext && !_isLoadingAffilies)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton(
              onPressed: _isLoadingMore ? null : _loadMoreAffilies,
              child: _isLoadingMore
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.prosocGreen,
                      ),
                    )
                  : const Text('Charger plus'),
            ),
          ),
      ],
    );
  }

  Widget _buildAffilieTile(AgentAffilieRow affilie) {
    final busy = _affilieIdEnCours == affilie.idAffilie;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.prosocGreen.withValues(alpha: 0.12),
            child: const Icon(
              Icons.person_outline,
              color: AppColors.prosocGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  affilie.nomComplet.isEmpty
                      ? 'Affilié #${affilie.idAffilie}'
                      : affilie.nomComplet,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                if (affilie.matricule.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Matricule ${affilie.matricule}',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (busy)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.prosocGreen,
              ),
            )
          else
            IconButton(
              tooltip: 'Réaffecter',
              onPressed: _isSubmitting ? null : () => _reaffecter(affilie),
              icon: const Icon(
                Icons.swap_horiz_rounded,
                color: AppColors.prosocGreen,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildJournal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Journal de réaffectations',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          'La plateforme n\'expose pas d\'historique affilié → agent en '
          'lecture. Ce journal retrace les opérations de cette session.',
          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 10),
        ..._journal.map(
          (entry) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: entry.succes
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFDECEA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      entry.succes
                          ? Icons.check_circle_outline_rounded
                          : Icons.error_outline_rounded,
                      size: 16,
                      color: entry.succes
                          ? AppColors.prosocGreen
                          : AppColors.errorColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.affilie,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM HH:mm', 'fr_FR').format(entry.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${entry.source} → ${entry.cible}',
                  style: const TextStyle(fontSize: 12),
                ),
                if (entry.message.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.message,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
