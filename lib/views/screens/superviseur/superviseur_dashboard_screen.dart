import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/colors.dart';
import '../../../models/dashboard_superviseur_model.dart';
import '../../../services/auth_service.dart';
import 'superviseur_controller.dart';
import 'widgets/superviseur_indicateurs_section.dart';
import 'widgets/superviseur_tendances_timeline.dart';

class SuperviseurDashboardScreen extends StatelessWidget {
  final SuperviseurController controller;
  final bool embedded;

  const SuperviseurDashboardScreen({
    super.key,
    required this.controller,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
            ),
            title: const Text('Performance équipe'),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            automaticallyImplyLeading: !embedded,
          ),
          body: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    final isLoading = controller.isLoading && !controller.hasLoaded;
    final errorMessage = controller.errorMessage;
    final dashboard = controller.dashboard;

    if (isLoading && dashboard == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.prosocGreen),
      );
    }

    if (errorMessage != null && dashboard == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(errorMessage, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => controller.load(force: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.prosocGreen,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (dashboard == null) {
      return const Center(child: Text('Aucune donnée disponible'));
    }

    final kpis = controller.kpis ?? dashboard.stats;
    final indicateurs = controller.indicateurs;
    final lastUpdate =
        dashboard.derniereMiseAJour ??
        kpis?.derniereMiseAJour ??
        dashboard.stats?.derniereMiseAJour;

    return RefreshIndicator(
      color: AppColors.prosocGreen,
      onRefresh: () => controller.load(force: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          if (lastUpdate != null)
            Text(
              'Mis à jour ${DateFormat('dd/MM/yyyy HH:mm').format(lastUpdate)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          const SizedBox(height: 12),
          _heroCard(kpis, dashboard),
          if (indicateurs != null) ...[
            const SizedBox(height: 16),
            SuperviseurIndicateursSection(indicateurs: indicateurs),
          ],
          const SizedBox(height: 16),
          _sectionTitle('Indicateurs clés'),
          const SizedBox(height: 12),
          _metricsGrid(kpis, dashboard),
          const SizedBox(height: 20),
          _sectionTitle('Tendances mensuelles'),
          const SizedBox(height: 12),
          SuperviseurTendancesTimeline(tendances: dashboard.tendancesEquipe),
          if (dashboard.rapportPerformance != null) ...[
            const SizedBox(height: 20),
            _sectionTitle('Rapport de performance'),
            const SizedBox(height: 12),
            _rapportCard(dashboard.rapportPerformance!),
          ],
          const SizedBox(height: 20),
          _sectionTitle('Objectifs équipe'),
          const SizedBox(height: 12),
          _objectiveCard(kpis, dashboard),
          if ((kpis?.agentsSupervises ?? dashboard.agentsEquipe)
              .isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionTitle('Classement agents'),
            const SizedBox(height: 12),
            ...(kpis?.agentsSupervises.isNotEmpty == true
                    ? kpis!.agentsSupervises
                    : dashboard.agentsEquipe)
                .map(_agentPerformanceCard),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );
  }

  Widget _heroCard(
    StatsSuperviseur? kpis,
    DashboardSuperviseurModel dashboard,
  ) {
    final nom = kpis?.nomSuperviseur.isNotEmpty == true
        ? kpis!.nomSuperviseur
        : (dashboard.nomSuperviseur.isNotEmpty
              ? dashboard.nomSuperviseur
              : (AuthService.currentUser?.utilisateur.nomComplet ??
                    'Superviseur'));
    final montant =
        kpis?.formattedMontantEquipe ?? dashboard.formattedMontantEquipe;
    final perf = kpis?.formattedPerformance ?? dashboard.formattedPerformance;
    final taux = kpis?.formattedTauxSucces ?? dashboard.formattedTauxSucces;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.prosocGreen,
            AppColors.prosocGreen.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nom,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            montant,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Performance $perf • Succès $taux',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _metricsGrid(
    StatsSuperviseur? kpis,
    DashboardSuperviseurModel dashboard,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: [
        _metricTile(
          'Agents directs',
          '${kpis?.nombreAgentsDirects ?? dashboard.nombreAgentsDirects}',
          Icons.groups,
        ),
        _metricTile(
          'Total équipe',
          '${kpis?.nombreAgentsTotal ?? dashboard.nombreAgentsTotal}',
          Icons.account_tree,
        ),
        _metricTile(
          'Transactions',
          '${kpis?.nombreTransactionsSuperviseur ?? dashboard.nombreTransactions}',
          Icons.receipt_long,
        ),
        _metricTile(
          'Perf. hiérarchie',
          '${dashboard.performanceMoyenneHierarchie.toStringAsFixed(1)}%',
          Icons.trending_up,
        ),
        _metricTile(
          'Montant superviseur',
          '${kpis?.montantTotalSuperviseur.toStringAsFixed(0) ?? dashboard.stats?.montantTotalSuperviseur.toStringAsFixed(0) ?? '0'}',
          Icons.person_outline,
        ),
        _metricTile(
          'Montant hiérarchie',
          '${dashboard.montantTotalHierarchie.toStringAsFixed(0)}',
          Icons.payments,
        ),
      ],
    );
  }

  Widget _metricTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppColors.prosocGreen, size: 22),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _rapportCard(SuperviseurRapportPerformance rapport) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${rapport.nombreAgents} agent(s) • ${rapport.totalTransactionsEquipe} transactions',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Montant moyen/agent: ${rapport.montantMoyenParAgent.toStringAsFixed(0)} CDF',
            style: TextStyle(color: Colors.grey[700]),
          ),
          if (rapport.rangParmiSuperviseurs > 0)
            Text(
              'Rang parmi superviseurs: ${rapport.rangParmiSuperviseurs}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
        ],
      ),
    );
  }

  Widget _objectiveCard(
    StatsSuperviseur? kpis,
    DashboardSuperviseurModel dashboard,
  ) {
    final objectif = kpis?.objectifEquipe ?? dashboard.objectifEquipe;
    final atteinte =
        kpis?.atteinteObjectifEquipe ?? dashboard.atteinteObjectifEquipe;
    final formattedAtteinte =
        kpis?.formattedAtteinteObjectif ?? dashboard.formattedAtteinteObjectif;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Objectif équipe',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '${objectif.toStringAsFixed(0)} CDF',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (atteinte.clamp(0, 100)) / 100,
              minHeight: 8,
              backgroundColor: AppColors.prosocGreen.withValues(alpha: 0.15),
              color: AppColors.prosocGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Atteinte: $formattedAtteinte',
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _agentPerformanceCard(SuperviseurAgentPerformance agent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.prosocGreen.withValues(alpha: 0.12),
            child: Text(
              agent.rangEquipe.toString(),
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
                  agent.nomAgent,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${agent.nombreTransactions} tx • ${agent.montantTotal.toStringAsFixed(0)} CDF',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${agent.atteinteObjectif.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.prosocGreen,
                ),
              ),
              Text(
                'Obj. ${agent.objectifPersonnel.toStringAsFixed(0)}',
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
