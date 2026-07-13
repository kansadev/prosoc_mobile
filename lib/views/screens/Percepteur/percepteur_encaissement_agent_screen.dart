import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:prosoc/config/api.dart';
import 'package:prosoc/config/colors.dart';
import 'package:prosoc/models/agent_model.dart';
import 'package:prosoc/models/perception_virtuelle_model.dart';
import 'package:prosoc/utils/api_error_helper.dart';
import 'package:prosoc/utils/currency_formatter.dart';
import 'package:prosoc/utils/paginated_response_helper.dart';
import 'package:prosoc/views/widgets/prosoc_resource_error_view.dart';
import 'package:prosoc/views/widgets/prosoc_shimmer_loading.dart';

/// Encaissement percepteur — sélection agent puis collectes cash en attente.
class PercepteurEncaissementAgentScreen extends StatefulWidget {
  const PercepteurEncaissementAgentScreen({super.key});

  @override
  State<PercepteurEncaissementAgentScreen> createState() =>
      _PercepteurEncaissementAgentScreenState();
}

class _PercepteurEncaissementAgentScreenState
    extends State<PercepteurEncaissementAgentScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;

  // --- Liste agents ---
  List<AgentModel> _agents = [];
  bool _isLoadingAgents = true;
  bool _isLoadingMoreAgents = false;
  String? _agentsError;
  int _agentsPage = 1;
  bool _agentsHasNext = false;
  String? _agentsSearch;

  // --- Collectes sélectionnées ---
  AgentModel? _selectedAgent;
  List<CollecteEnAttenteModel> _collectes = [];
  final Set<int> _selectedCollecteIds = {};
  bool _isLoadingCollectes = false;
  bool _isLoadingMoreCollectes = false;
  String? _collectesError;
  int _collectesPage = 1;
  bool _collectesHasNext = false;
  bool _isConfirming = false;

  static const _pageSize = 15;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadAgents(reset: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 200) return;

    if (_selectedAgent == null) {
      if (!_isLoadingAgents && !_isLoadingMoreAgents && _agentsHasNext) {
        _loadAgents();
      }
    } else {
      if (!_isLoadingCollectes &&
          !_isLoadingMoreCollectes &&
          _collectesHasNext) {
        _loadCollectes();
      }
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      final query = value.trim();
      if (_selectedAgent == null) {
        _loadAgents(reset: true, search: query.isEmpty ? null : query);
      }
    });
  }

  Future<void> _loadAgents({bool reset = false, String? search}) async {
    if (reset) {
      setState(() {
        _isLoadingAgents = true;
        _isLoadingMoreAgents = false;
        _agentsError = null;
        _agents = [];
        _agentsPage = 1;
        _agentsHasNext = false;
        _agentsSearch = search;
      });
    } else {
      if (_isLoadingMoreAgents || !_agentsHasNext) return;
      setState(() {
        _isLoadingMoreAgents = true;
        _agentsError = null;
      });
    }

    final pageToLoad = reset ? 1 : _agentsPage + 1;

    try {
      final response = await ApiService.searchAgents(
        page: pageToLoad,
        pageSize: _pageSize,
        search: search ?? _agentsSearch,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        final payload = response.data!;
        final rows = PaginatedResponseHelper.extractRows(payload);
        final pageItems = rows
            .whereType<Map>()
            .map((row) => AgentModel.fromJson(Map<String, dynamic>.from(row)))
            .where((a) => a.id > 0)
            .toList();

        setState(() {
          _agents = reset ? pageItems : [..._agents, ...pageItems];
          _agentsPage = PaginatedResponseHelper.extractCurrentPage(
            payload,
            fallback: pageToLoad,
          );
          _agentsHasNext = PaginatedResponseHelper.extractHasNext(payload);
          _isLoadingAgents = false;
          _isLoadingMoreAgents = false;
        });
      } else {
        setState(() {
          _agentsError = ApiErrorHelper.messageForApiFailure(
            statusCode: response.statusCode,
            serverDetail: response.message,
            fallback: 'Impossible de charger les agents.',
          );
          _isLoadingAgents = false;
          _isLoadingMoreAgents = false;
        });
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException(
        'PercepteurEncaissementAgent/agents',
        e,
        stackTrace,
        false,
      );
      if (!mounted) return;
      setState(() {
        _agentsError = ApiErrorHelper.userFacingNetwork();
        _isLoadingAgents = false;
        _isLoadingMoreAgents = false;
      });
    }
  }

  void _selectAgent(AgentModel agent) {
    setState(() {
      _selectedAgent = agent;
      _selectedCollecteIds.clear();
      _collectes = [];
      _collectesError = null;
      _searchController.clear();
    });
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    _loadCollectes(reset: true);
  }

  void _clearSelectedAgent() {
    setState(() {
      _selectedAgent = null;
      _collectes = [];
      _selectedCollecteIds.clear();
      _collectesError = null;
      _searchController.clear();
    });
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    _loadAgents(reset: true);
  }

  Future<void> _loadCollectes({bool reset = false}) async {
    final agent = _selectedAgent;
    if (agent == null) return;

    if (reset) {
      setState(() {
        _isLoadingCollectes = true;
        _isLoadingMoreCollectes = false;
        _collectesError = null;
        _collectes = [];
        _collectesPage = 1;
        _collectesHasNext = false;
        if (reset) _selectedCollecteIds.clear();
      });
    } else {
      if (_isLoadingMoreCollectes || !_collectesHasNext) return;
      setState(() {
        _isLoadingMoreCollectes = true;
        _collectesError = null;
      });
    }

    final pageToLoad = reset ? 1 : _collectesPage + 1;

    try {
      final response = await ApiService.getPerceptionVirtuelleCollectesEnAttente(
        agentId: agent.id,
        page: pageToLoad,
        pageSize: _pageSize,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        final payload = response.data!;
        final pageItems = ApiService.parseCollectesEnAttente(payload);

        setState(() {
          _collectes = reset ? pageItems : [..._collectes, ...pageItems];
          _collectesPage = PaginatedResponseHelper.extractCurrentPage(
            payload,
            fallback: pageToLoad,
          );
          _collectesHasNext = PaginatedResponseHelper.extractHasNext(payload);
          _isLoadingCollectes = false;
          _isLoadingMoreCollectes = false;
        });
      } else {
        setState(() {
          _collectesError = ApiErrorHelper.messageForApiFailure(
            statusCode: response.statusCode,
            serverDetail: response.message,
            fallback: 'Impossible de charger les collectes en attente.',
          );
          _isLoadingCollectes = false;
          _isLoadingMoreCollectes = false;
        });
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException(
        'PercepteurEncaissementAgent/collectes',
        e,
        stackTrace,
        false,
      );
      if (!mounted) return;
      setState(() {
        _collectesError = ApiErrorHelper.userFacingNetwork();
        _isLoadingCollectes = false;
        _isLoadingMoreCollectes = false;
      });
    }
  }

  List<CollecteEnAttenteModel> get _selectedCollectes => _collectes
      .where((c) => _selectedCollecteIds.contains(c.idCollecte))
      .toList();

  Map<String, double> get _totalsByDevise {
    final totals = <String, double>{};
    for (final collecte in _selectedCollectes) {
      totals.update(
        collecte.deviseCode,
        (value) => value + collecte.montant,
        ifAbsent: () => collecte.montant,
      );
    }
    return totals;
  }

  String get _formattedSelectionTotal {
    if (_totalsByDevise.isEmpty) return '0';
    return _totalsByDevise.entries
        .map(
          (e) => CurrencyFormatter.format(
            amount: e.value,
            deviseCode: e.key,
          ),
        )
        .join(' + ');
  }

  void _toggleCollecte(int idCollecte, bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedCollecteIds.add(idCollecte);
      } else {
        _selectedCollecteIds.remove(idCollecte);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedCollecteIds.length == _collectes.length) {
        _selectedCollecteIds.clear();
      } else {
        _selectedCollecteIds
          ..clear()
          ..addAll(_collectes.map((c) => c.idCollecte));
      }
    });
  }

  Future<void> _confirmSelection() async {
    final agent = _selectedAgent;
    if (agent == null || _selectedCollecteIds.isEmpty || _isConfirming) return;

    final observation = await _askObservation();
    if (observation == null || !mounted) return;

    setState(() => _isConfirming = true);

    try {
      final response = await ApiService.confirmerPerceptionVirtuelle(
        agentId: agent.id,
        collecteIds: _selectedCollecteIds.toList(),
        observation: observation,
      );

      if (!mounted) return;

      final statusCode = response.statusCode;
      final isHttpOk = statusCode == 200 || statusCode == 201;

      if (!isHttpOk || !response.success || response.data == null) {
        _showSnack(
          response.message ?? 'Erreur lors de la confirmation.',
          isError: true,
        );
        return;
      }

      final result = response.data!;
      if (!result.succes) {
        _showSnack(
          result.message.isNotEmpty
              ? result.message
              : 'La perception n\'a pas pu être confirmée.',
          isError: true,
        );
        return;
      }

      final confirmedIds = _selectedCollecteIds.toList();

      await _showSuccessDialog(result);
      if (!mounted) return;

      setState(() {
        _selectedCollecteIds.clear();
        _collectes.removeWhere(
          (collecte) => confirmedIds.contains(collecte.idCollecte),
        );
      });

      await _loadCollectes(reset: true);
    } catch (e, stackTrace) {
      ApiErrorHelper.logException(
        'PercepteurEncaissementAgent/confirmer',
        e,
        stackTrace,
        false,
      );
      if (mounted) {
        _showSnack(ApiErrorHelper.userFacingNetwork(), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  Future<String?> _askObservation() async {
    final controller = TextEditingController(
      text: 'Perception cash effectuée au guichet percepteur',
    );

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la perception'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_selectedCollecteIds.length} collecte(s) · $_formattedSelectionTotal',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observation',
                border: OutlineInputBorder(),
              ),
            ),
          ],
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
      ),
    );
  }

  Future<void> _showSuccessDialog(
    PerceptionVirtuelleConfirmResultModel result,
  ) async {
    if (!mounted) return;

    final montant = CurrencyFormatter.format(amount: result.montantTotal);
    final solde = CurrencyFormatter.format(amount: result.soldeRestantAgent);

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.check_circle_rounded,
          color: AppColors.prosocGreen,
          size: 40,
        ),
        title: const Text('Perception confirmée'),
        content: Text(
          result.message.isNotEmpty
              ? result.message
              : '${result.nombreCollectes} collecte(s) perçue(s) pour un total '
                  'de $montant.\nSolde virtuel restant agent : $solde.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.prosocGreen,
            ),
            child: const Text('OK'),
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

  String _formatCollecteDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat("dd/MM/yyyy 'à' HH:mm", 'fr_FR').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedAgent;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          selected == null ? 'Encaisser — Agent' : 'Collectes en attente',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: selected == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                onPressed: _clearSelectedAgent,
              ),
      ),
      body: selected == null ? _buildAgentsBody() : _buildCollectesBody(selected),
      bottomNavigationBar:
          selected != null && _selectedCollecteIds.isNotEmpty
              ? _buildConfirmBar()
              : null,
    );
  }

  Widget _buildAgentsBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher un agent (nom, matricule…)',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() {});
              _onSearchChanged(value);
            },
          ),
        ),
        Expanded(child: _buildAgentsList()),
      ],
    );
  }

  Widget _buildAgentsList() {
    if (_isLoadingAgents) {
      return const ProsocLoadingShimmer.list(itemCount: 6);
    }

    if (_agentsError != null && _agents.isEmpty) {
      return ProsocResourceErrorView(
        message: _agentsError!,
        onRetry: () => _loadAgents(reset: true, search: _agentsSearch),
      );
    }

    if (_agents.isEmpty) {
      return Center(
        child: Text(
          _agentsSearch != null
              ? 'Aucun agent trouvé.'
              : 'Aucun agent disponible.',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.prosocGreen,
      onRefresh: () => _loadAgents(reset: true, search: _agentsSearch),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: _agents.length + (_isLoadingMoreAgents ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index >= _agents.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.prosocGreen,
                    strokeWidth: 2,
                  ),
                ),
              ),
            );
          }

          final agent = _agents[index];
          final initial = agent.nomComplet.trim().isNotEmpty
              ? agent.nomComplet.trim()[0].toUpperCase()
              : 'A';

          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => _selectAgent(agent),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          AppColors.prosocGreen.withValues(alpha: 0.12),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: AppColors.prosocGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            agent.nomComplet,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          if (agent.matricule.isNotEmpty)
                            Text(
                              agent.matricule,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCollectesBody(AgentModel agent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.prosocGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.prosocGreen.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.badge_outlined, color: AppColors.prosocGreen),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agent.nomComplet,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (agent.matricule.isNotEmpty)
                      Text(
                        agent.matricule,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_collectes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Checkbox(
                  value: _selectedCollecteIds.length == _collectes.length &&
                      _collectes.isNotEmpty,
                  tristate: true,
                  onChanged: (_) => _toggleSelectAll(),
                  activeColor: AppColors.prosocGreen,
                ),
                Text(
                  'Tout sélectionner (${_collectes.length})',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        Expanded(child: _buildCollectesList()),
      ],
    );
  }

  Widget _buildCollectesList() {
    if (_isLoadingCollectes) {
      return const ProsocLoadingShimmer.list(itemCount: 5);
    }

    if (_collectesError != null && _collectes.isEmpty) {
      return ProsocResourceErrorView(
        message: _collectesError!,
        onRetry: () => _loadCollectes(reset: true),
      );
    }

    if (_collectes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Aucune collecte cash en attente pour cet agent.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.prosocGreen,
      onRefresh: () => _loadCollectes(reset: true),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
        itemCount: _collectes.length + (_isLoadingMoreCollectes ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          if (index >= _collectes.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.prosocGreen,
                    strokeWidth: 2,
                  ),
                ),
              ),
            );
          }

          final collecte = _collectes[index];
          final isSelected =
              _selectedCollecteIds.contains(collecte.idCollecte);

          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: CheckboxListTile(
              value: isSelected,
              onChanged: (value) =>
                  _toggleCollecte(collecte.idCollecte, value),
              activeColor: AppColors.prosocGreen,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              title: Text(
                collecte.affilieNom.isNotEmpty
                    ? collecte.affilieNom
                    : 'Affilié #${collecte.affilieId}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    collecte.typeCollecte,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _formatCollecteDate(collecte.dateCollecte),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                  if (collecte.referencePaiement != null &&
                      collecte.referencePaiement!.isNotEmpty)
                    Text(
                      collecte.referencePaiement!,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
              secondary: Text(
                collecte.formattedMontant,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.prosocGreen,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConfirmBar() {
    return Material(
      elevation: 8,
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedCollecteIds.length} sélectionnée(s)',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _formattedSelectionTotal,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: _isConfirming ? null : _confirmSelection,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.prosocGreen,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                child: _isConfirming
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Percevoir'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
