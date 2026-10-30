import 'package:flutter/material.dart';

import '../../../config/api.dart';
import '../../../config/colors.dart';
import '../../../models/agent_model.dart';
import '../../../models/zone_sociale_model.dart';
import '../../../services/auth_service.dart';
import '../../../utils/api_error_helper.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/prosoc_resource_error_view.dart';

/// Gestion des chefs d'équipe par zone sociale.
///
/// La plateforme n'expose pas d'endpoint de listage des chefs d'équipe :
/// `GET /api/ZoneSociale` est donc la source de lecture, via
/// `chefEquipeAgentId` / `chefEquipeNom`. Les modifications passent par
/// `PUT`/`DELETE /api/ZoneSociale/{id}/chef-equipe`.
class SuperviseurZonesScreen extends StatefulWidget {
  const SuperviseurZonesScreen({super.key});

  @override
  State<SuperviseurZonesScreen> createState() => _SuperviseurZonesScreenState();
}

class _SuperviseurZonesScreenState extends State<SuperviseurZonesScreen> {
  final _searchController = TextEditingController();
  final List<ZoneSocialeModel> _zones = [];
  List<AgentModel> _agents = [];

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  int? _zoneIdEnCours;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _agentLabel(AgentModel agent) =>
      agent.nomComplet.isNotEmpty ? agent.nomComplet : 'Agent #${agent.id}';

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final superviseurId = AuthService.superviseurId;
    final search = _searchController.text.trim();

    try {
      // Les zones sont chargées en priorité : c'est la donnée affichée.
      final zonesFuture = ApiService.getZoneSocialesAvecChefs(
        page: 1,
        pageSize: 100,
        search: search.isEmpty ? null : search,
      );

      final agentsFuture = superviseurId == null
          ? Future<ApiResponse<List<AgentModel>>>.value(
              ApiResponse<List<AgentModel>>.error('Superviseur non identifié'),
            )
          : ApiService.getAgentsBySuperviseur(superviseurId);

      final results = await Future.wait([zonesFuture, agentsFuture]);
      final zonesResponse =
          results[0]
              as ApiResponse<({List<ZoneSocialeModel> rows, bool hasNext})>;
      final agentsResponse = results[1] as ApiResponse<List<AgentModel>>;

      if (!mounted) return;

      if (!zonesResponse.success) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              zonesResponse.message ??
              ApiErrorHelper.userFacingMessage(
                statusCode: zonesResponse.statusCode,
              );
        });
        return;
      }

      setState(() {
        _zones
          ..clear()
          ..addAll(zonesResponse.data!.rows);
        if (agentsResponse.success && agentsResponse.data != null) {
          _agents = agentsResponse.data!;
        }
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      if (!mounted) return;
      ApiErrorHelper.logException('SuperviseurZones', e, stackTrace, false);
      setState(() {
        _isLoading = false;
        _errorMessage = ApiErrorHelper.userFacingNetwork();
      });
    }
  }

  Future<void> _affecterChefEquipe(ZoneSocialeModel zone) async {
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
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Chef d\'équipe — ${zone.nom}',
                style: Theme.of(
                  ctx,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Actuel : ${zone.chefEquipeLabel}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _agents.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final a = _agents[index];
                    final already = a.id == zone.chefEquipeAgentId;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.prosocGreen.withValues(
                          alpha: 0.12,
                        ),
                        child: const Icon(
                          Icons.groups_2_outlined,
                          color: AppColors.prosocGreen,
                        ),
                      ),
                      title: Text(_agentLabel(a)),
                      subtitle: a.matricule.isNotEmpty
                          ? Text(a.matricule)
                          : null,
                      trailing: already
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.prosocGreen,
                              size: 20,
                            )
                          : null,
                      onTap: already ? null : () => Navigator.pop(ctx, a),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (agent == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la désignation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Zone : ${zone.nom}'),
            if ((zone.communeNom ?? '').isNotEmpty)
              Text(
                zone.communeNom!,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            const SizedBox(height: 14),
            Text(
              'Désigner ${_agentLabel(agent)} comme chef d\'équipe de cette '
              'zone ?',
            ),
            if (zone.hasChefEquipe) ...[
              const SizedBox(height: 10),
              Text(
                'Le chef d\'équipe actuel (${zone.chefEquipeLabel}) sera '
                'remplacé.',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.errorColor,
                ),
              ),
            ],
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
            child: const Text('Désigner'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _submitAffectation(zone, agent);
  }

  Future<void> _submitAffectation(
    ZoneSocialeModel zone,
    AgentModel agent,
  ) async {
    setState(() {
      _isSubmitting = true;
      _zoneIdEnCours = zone.id;
    });

    try {
      final response = await ApiService.affecterChefEquipeZone(
        zone.id,
        agent.id,
      );
      if (!mounted) return;

      if (!response.success || response.data == null) {
        _showSnack(
          response.message ?? 'Échec de la désignation',
          isError: true,
        );
        return;
      }

      final updated = response.data!;
      setState(() {
        final index = _zones.indexWhere((z) => z.id == updated.id);
        if (index >= 0) {
          _zones[index] = ZoneSocialeModel(
            id: updated.id,
            nom: updated.nom.isEmpty ? zone.nom : updated.nom,
            communeId: updated.communeId > 0
                ? updated.communeId
                : zone.communeId,
            communeNom: updated.communeNom ?? zone.communeNom,
            statut: updated.statut,
            chefEquipeAgentId: agent.id,
            chefEquipeNom: _agentLabel(agent),
          );
        }
      });

      _showSnack('${_agentLabel(agent)} désigné sur ${zone.nom}');
    } catch (e, stackTrace) {
      if (!mounted) return;
      ApiErrorHelper.logException(
        'SuperviseurZones/affecter',
        e,
        stackTrace,
        false,
      );
      _showSnack(ApiErrorHelper.userFacingNetwork(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _zoneIdEnCours = null;
        });
      }
    }
  }

  Future<void> _retirerChefEquipe(ZoneSocialeModel zone) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer le chef d\'équipe'),
        content: Text(
          'La zone « ${zone.nom} » n\'aura plus de chef d\'équipe désigné. '
          'Confirmez-vous ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.errorColor,
            ),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isSubmitting = true;
      _zoneIdEnCours = zone.id;
    });

    try {
      final response = await ApiService.retirerChefEquipeZone(zone.id);
      if (!mounted) return;

      if (!response.success) {
        _showSnack(response.message ?? 'Échec du retrait', isError: true);
        return;
      }

      setState(() {
        final index = _zones.indexWhere((z) => z.id == zone.id);
        if (index >= 0) {
          final z = _zones[index];
          _zones[index] = ZoneSocialeModel(
            id: z.id,
            nom: z.nom,
            communeId: z.communeId,
            communeNom: z.communeNom,
            statut: z.statut,
          );
        }
      });

      _showSnack('Chef d\'équipe retiré de ${zone.nom}');
    } catch (e, stackTrace) {
      if (!mounted) return;
      ApiErrorHelper.logException(
        'SuperviseurZones/retirer',
        e,
        stackTrace,
        false,
      );
      _showSnack(ApiErrorHelper.userFacingNetwork(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _zoneIdEnCours = null;
        });
      }
    }
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
          'Zones & chefs d\'équipe',
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.prosocGreen),
      );
    }

    if (_errorMessage != null) {
      return ProsocResourceErrorView(message: _errorMessage!, onRetry: _load);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: TextField(
            controller: _searchController,
            onSubmitted: (_) => _load(),
            decoration: InputDecoration(
              hintText: 'Rechercher une zone',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward_rounded),
                onPressed: _load,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.prosocGreen,
            onRefresh: _load,
            child: _zones.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 100),
                      EmptyStateWidget(
                        icon: Icons.map_outlined,
                        title: 'Aucune zone',
                        subtitle: 'Aucune zone sociale ne correspond.',
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    itemCount: _zones.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _buildZoneTile(_zones[index]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildZoneTile(ZoneSocialeModel zone) {
    final busy = _isSubmitting && _zoneIdEnCours == zone.id;
    final agentsDansZone = _agentsInZone(zone);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.prosocGreen.withValues(alpha: 0.12),
                child: const Icon(
                  Icons.map_outlined,
                  color: AppColors.prosocGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zone.nom.isEmpty ? 'Zone #${zone.id}' : zone.nom,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Zone #${zone.id}'
                      '${(zone.communeNom ?? '').isNotEmpty ? ' · ${zone.communeNom}' : ''}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: zone.statut
                      ? AppColors.prosocGreen.withValues(alpha: 0.1)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  zone.statut ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: zone.statut
                        ? AppColors.prosocGreen
                        : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _zoneMetric(
                icon: zone.hasChefEquipe
                    ? Icons.groups_2_outlined
                    : Icons.person_off_outlined,
                label: 'Chef d\'équipe',
                value: zone.chefEquipeLabel,
              ),
              const SizedBox(width: 8),
              _zoneMetric(
                icon: Icons.groups_rounded,
                label: 'Agents AT',
                value: '$agentsDansZone',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy || _agents.isEmpty
                      ? null
                      : () => _affecterChefEquipe(zone),
                  icon: const Icon(Icons.how_to_reg_rounded, size: 16),
                  label: Text(zone.hasChefEquipe ? 'Changer' : 'Désigner'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.prosocGreen,
                    side: const BorderSide(color: AppColors.prosocGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              if (zone.hasChefEquipe) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Retirer',
                  onPressed: busy ? null : () => _retirerChefEquipe(zone),
                  icon: const Icon(
                    Icons.remove_circle_outline_rounded,
                    color: AppColors.errorColor,
                  ),
                ),
              ],
            ],
          ),
          if (busy) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(minHeight: 2),
          ],
        ],
      ),
    );
  }

  /// Agents AT rattachés à la zone (même source que le module « Ma zone » du
  /// chef d'équipe : les agents de l'équipe du superviseur).
  int _agentsInZone(ZoneSocialeModel zone) {
    return _agents
        .where((a) => a.zoneSocialeId != null && a.zoneSocialeId == zone.id)
        .length;
  }

  Widget _zoneMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
