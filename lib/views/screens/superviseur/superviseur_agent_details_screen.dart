import 'package:flutter/material.dart';

import '../../../config/api.dart';
import '../../../config/colors.dart';
import '../../../models/agent_model.dart';
import '../../../utils/api_error_helper.dart';
import '../../../utils/formatters.dart';
import '../../widgets/prosoc_resource_error_view.dart';
import 'widgets/superviseur_recharge_wallet_sheet.dart';

/// Détails d'un agent supervisé via GET /api/Agent/{id}.
class SuperviseurAgentDetailsScreen extends StatefulWidget {
  final int agentId;
  final String? agentNom;

  const SuperviseurAgentDetailsScreen({
    super.key,
    required this.agentId,
    this.agentNom,
  });

  @override
  State<SuperviseurAgentDetailsScreen> createState() =>
      _SuperviseurAgentDetailsScreenState();
}

class _SuperviseurAgentDetailsScreenState
    extends State<SuperviseurAgentDetailsScreen> {
  AgentModel? _agent;
  bool _isLoading = true;
  String? _errorMessage;
  int? _errorStatusCode;

  @override
  void initState() {
    super.initState();
    _loadAgent();
  }

  Future<void> _loadAgent({bool force = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _errorStatusCode = null;
    });

    try {
      final response = await ApiService.getAgentDetail(widget.agentId);
      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _agent = response.data;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = response.message ??
            'Impossible de charger les détails de l\'agent.';
        _errorStatusCode = response.statusCode;
      });
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('SuperviseurAgentDetails', e, stackTrace);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = ApiErrorHelper.userFacingNetwork();
        _errorStatusCode = 0;
      });
    }
  }

  Future<void> _openRechargeWallet(AgentModel agent) async {
    final recharged = await SuperviseurRechargeWalletSheet.show(
      context,
      agentId: agent.id,
      agentNom: agent.nomComplet,
    );
    if (!mounted || !recharged) return;
    await _loadAgent(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final agent = _agent;
    final title = agent?.nomComplet.isNotEmpty == true
        ? agent!.nomComplet
        : (widget.agentNom?.isNotEmpty == true
            ? widget.agentNom!
            : 'Détails agent');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.prosocGreen),
            )
          : _errorMessage != null
              ? ProsocResourceErrorView(
                  message: _errorMessage!,
                  statusCode: _errorStatusCode,
                  onRetry: () => _loadAgent(force: true),
                )
              : RefreshIndicator(
                  color: AppColors.prosocGreen,
                  onRefresh: () => _loadAgent(force: true),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      _buildHeader(agent!),
                      const SizedBox(height: 16),
                      _buildInfoSection(agent),
                      const SizedBox(height: 16),
                      _buildWalletSection(agent),
                      const SizedBox(height: 16),
                      _buildAccountSection(agent),
                      const SizedBox(height: 24),
                      if (agent.walletVirtuelCree || agent.walletVirtuelId != null)
                        FilledButton.icon(
                          onPressed: () => _openRechargeWallet(agent),
                          icon: const Icon(Icons.account_balance_wallet_outlined),
                          label: const Text('Recharger le compte virtuel'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.prosocGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader(AgentModel agent) {
    final initial = agent.nomComplet.isNotEmpty
        ? agent.nomComplet[0].toUpperCase()
        : 'A';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.prosocGreen.withValues(alpha: 0.12),
            backgroundImage:
                agent.photoUrl != null && agent.photoUrl!.isNotEmpty
                    ? NetworkImage(agent.photoUrl!)
                    : null,
            child: agent.photoUrl == null || agent.photoUrl!.isEmpty
                ? Text(
                    initial,
                    style: const TextStyle(
                      color: AppColors.prosocGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agent.nomComplet,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  agent.matricule.isNotEmpty
                      ? 'Matricule : ${agent.matricule}'
                      : 'Agent #${agent.id}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                _buildStatusChip(agent.statut),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(bool actif) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (actif ? AppColors.prosocGreen : Colors.red)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        actif ? 'Actif' : 'Inactif',
        style: TextStyle(
          color: actif ? AppColors.prosocGreen : Colors.red.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoSection(AgentModel agent) {
    return _sectionCard(
      title: 'Informations',
      icon: Icons.person_outline,
      children: [
        _infoRow('Téléphone', agent.phone, Icons.phone_outlined),
        if (agent.emailAgent != null && agent.emailAgent!.isNotEmpty)
          _infoRow('E-mail', agent.emailAgent!, Icons.email_outlined),
        if (agent.fonction != null && agent.fonction!.isNotEmpty)
          _infoRow('Fonction', agent.fonction!, Icons.work_outline),
        if (agent.roleAgent != null && agent.roleAgent!.isNotEmpty)
          _infoRow('Rôle', agent.roleAgent!, Icons.badge_outlined),
        if (agent.zoneSocialeNom != null && agent.zoneSocialeNom!.isNotEmpty)
          _infoRow('Zone sociale', agent.zoneSocialeNom!, Icons.map_outlined),
        _infoRow(
          'Date de création',
          AppFormatters.formatDate(agent.dateCreation),
          Icons.calendar_today_outlined,
        ),
        if (agent.dateModification != null)
          _infoRow(
            'Dernière modification',
            AppFormatters.formatDateTime(agent.dateModification),
            Icons.update_outlined,
          ),
      ],
    );
  }

  Widget _buildWalletSection(AgentModel agent) {
    return _sectionCard(
      title: 'Comptes',
      icon: Icons.account_balance_wallet_outlined,
      children: [
        _walletTile(
          label: 'Wallet agent',
          solde: agent.formattedWalletSolde,
          cree: agent.walletCree,
          icon: Icons.savings_outlined,
          color: AppColors.prosocGreen,
        ),
        const SizedBox(height: 12),
        _walletTile(
          label: 'Compte virtuel',
          solde: agent.formattedWalletVirtuelSolde,
          cree: agent.walletVirtuelCree,
          icon: Icons.credit_card_outlined,
          color: Colors.blue.shade700,
        ),
      ],
    );
  }

  Widget _buildAccountSection(AgentModel agent) {
    return _sectionCard(
      title: 'Compte utilisateur',
      icon: Icons.manage_accounts_outlined,
      children: [
        _infoRow(
          'Utilisateur lié',
          agent.utilisateurCree
              ? (agent.nomUtilisateur?.isNotEmpty == true
                  ? agent.nomUtilisateur!
                  : 'Utilisateur #${agent.utilisateurId ?? '—'}')
              : 'Non créé',
          Icons.person_outline,
        ),
        if (agent.utilisateurId != null && agent.utilisateurId! > 0)
          _infoRow(
            'ID utilisateur',
            agent.utilisateurId.toString(),
            Icons.tag_outlined,
          ),
      ],
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.prosocGreen),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _walletTile({
    required String label,
    required String solde,
    required bool cree,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  solde,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (cree ? AppColors.prosocGreen : Colors.orange)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              cree ? 'Actif' : 'Non créé',
              style: TextStyle(
                color: cree ? AppColors.prosocGreen : Colors.orange.shade800,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
