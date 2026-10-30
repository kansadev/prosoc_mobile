import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/api.dart';
import '../../../config/colors.dart';
import '../../../models/dashboard_percepteur_model.dart';
import '../../../utils/api_error_helper.dart';
import 'widgets/perception_periode_detail_sheet.dart';

/// Périodes de consultation de la collecte.
///
/// Le contrat API n'expose aucun paramètre « semaine » : les agrégats
/// jour / semaine / mois sont fournis tels quels par
/// `GET /api/DashboardPercepteur/summary` (`PercepteurKpis`). Le détail des
/// opérations, lui, se filtre par fenêtre de dates.
enum _PerceptionPeriode {
  jour('Aujourd\'hui'),
  semaine('7 derniers jours'),
  mois('Ce mois');

  const _PerceptionPeriode(this.label);

  final String label;
}

class DashboardPercepteurScreen extends StatefulWidget {
  const DashboardPercepteurScreen({super.key});

  @override
  State<DashboardPercepteurScreen> createState() =>
      _DashboardPercepteurScreenState();
}

class _DashboardPercepteurScreenState extends State<DashboardPercepteurScreen> {
  DashboardPercepteurModel? _dashboard;
  bool _isLoading = true;
  String? _errorMessage;
  _PerceptionPeriode _periode = _PerceptionPeriode.semaine;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getDashboardPercepteurSummary();

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _dashboard = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = ApiErrorHelper.messageForApiFailure(
            statusCode: response.statusCode,
            serverDetail: response.message,
            fallback: 'Impossible de charger le tableau de bord.',
          );
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException(
        'DashboardPercepteur/load',
        e,
        stackTrace,
        false,
      );
      if (!mounted) return;
      setState(() {
        _errorMessage = ApiErrorHelper.userFacingNetwork();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Tableau de bord'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _dashboard == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.prosocGreen),
      );
    }

    if (_errorMessage != null && _dashboard == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDashboardData,
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

    final dashboard = _dashboard;
    if (dashboard == null) {
      return const Center(child: Text('Aucune donnée disponible'));
    }

    final kpis = dashboard.kpis;

    return RefreshIndicator(
      color: AppColors.prosocGreen,
      onRefresh: _loadDashboardData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          if (dashboard.derniereMiseAJour != null)
            Text(
              'Mis à jour ${DateFormat('dd/MM/yyyy HH:mm').format(dashboard.derniereMiseAJour!)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          const SizedBox(height: 12),
          _heroCard(dashboard, kpis),
          const SizedBox(height: 20),
          _sectionTitle('Indicateurs clés'),
          const SizedBox(height: 12),
          _metricsGrid(dashboard, kpis),
          if (dashboard.graphs?.resumeMensuels.isNotEmpty == true) ...[
            const SizedBox(height: 20),
            _sectionTitle('Résumé mensuel'),
            const SizedBox(height: 12),
            ...dashboard.graphs!.resumeMensuels.map(_resumeMensuelCard),
          ],
          if (dashboard.objectifs.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionTitle('Objectifs'),
            const SizedBox(height: 12),
            ...dashboard.objectifs.map(_objectifCard),
          ],
          if (dashboard.topAgents.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionTitle('Meilleurs agents'),
            const SizedBox(height: 12),
            ...dashboard.topAgents.map(_topAgentCard),
          ],
          if (dashboard.agentsStats.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionTitle('Agents actifs de la zone'),
            const SizedBox(height: 12),
            ...dashboard.agentsStats.map(_agentStatsCard),
          ],
          const SizedBox(height: 24),
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

  Widget _heroCard(DashboardPercepteurModel dashboard, PercepteurKpis? kpis) {
    final operations = _operationsPeriode(kpis);

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
          _periodeSelector(),
          const SizedBox(height: 14),
          Text(
            'Montant perçu — ${_periode.label}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            _montantPeriode(kpis),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$operations opération${operations > 1 ? 's' : ''} sur la période',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Total général : ${kpis?.formattedMontantTotal ?? dashboard.formatMontant(0)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          if (dashboard.soldeAPercevoir > 0) ...[
            const SizedBox(height: 12),
            Text(
              'Solde à percevoir : ${dashboard.formatMontant(dashboard.soldeAPercevoir)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          _buildDetailButton(),
        ],
      ),
    );
  }

  /// Montant de la période sélectionnée, à partir des agrégats déjà chargés
  /// par `GET /api/DashboardPercepteur/summary`.
  String _montantPeriode(PercepteurKpis? kpis) {
    if (kpis == null) return '—';
    switch (_periode) {
      case _PerceptionPeriode.jour:
        return kpis.formattedMontantJour;
      case _PerceptionPeriode.semaine:
        return kpis.formattedMontantSemaine;
      case _PerceptionPeriode.mois:
        return kpis.formattedMontantMois;
    }
  }

  int _operationsPeriode(PercepteurKpis? kpis) {
    if (kpis == null) return 0;
    switch (_periode) {
      case _PerceptionPeriode.jour:
        return kpis.transactionsDuJour;
      case _PerceptionPeriode.semaine:
        return kpis.transactionsSemaine;
      case _PerceptionPeriode.mois:
        return kpis.transactionsMois;
    }
  }

  /// Fenêtre de dates correspondant à la période sélectionnée.
  ///
  /// Aucune notion de « semaine » n'existe côté API : la semaine est traduite
  /// en fenêtre glissante de 7 jours.
  ({DateTime debut, DateTime fin}) _fenetrePeriode() {
    final now = DateTime.now();
    final debutDuJour = DateTime(now.year, now.month, now.day);
    switch (_periode) {
      case _PerceptionPeriode.jour:
        return (
          debut: debutDuJour,
          fin: debutDuJour.add(const Duration(days: 1)),
        );
      case _PerceptionPeriode.semaine:
        return (
          debut: debutDuJour.subtract(const Duration(days: 6)),
          fin: debutDuJour.add(const Duration(days: 1)),
        );
      case _PerceptionPeriode.mois:
        return (
          debut: DateTime(now.year, now.month, 1),
          fin: debutDuJour.add(const Duration(days: 1)),
        );
    }
  }

  Widget _buildDetailButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          final fenetre = _fenetrePeriode();
          PerceptionPeriodeDetailSheet.show(
            context,
            dateDebut: fenetre.debut,
            dateFin: fenetre.fin,
            periodeLabel: _periode.label,
          );
        },
        icon: const Icon(Icons.receipt_long_outlined, size: 18),
        label: const Text('Voir les opérations de la période'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _periodeSelector() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: _PerceptionPeriode.values.map((periode) {
          final selected = periode == _periode;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _periode = periode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  periode.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppColors.prosocGreen
                        : Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _metricsGrid(DashboardPercepteurModel dashboard, PercepteurKpis? kpis) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: [
        _metricTile(
          'Transactions',
          '${kpis?.nombreTotalTransactions ?? 0}',
          Icons.receipt_long_outlined,
        ),
        _metricTile(
          'Agents actifs',
          '${kpis?.nombreAgentsActifs ?? dashboard.agentsStats.length}',
          Icons.groups_outlined,
        ),
        _metricTile(
          'Opérations période',
          '${_operationsPeriode(kpis)}',
          Icons.date_range_outlined,
        ),
        _metricTile(
          'Taux de succès',
          kpis?.formattedTauxSucces ?? '—',
          Icons.check_circle_outline,
        ),
        _metricTile(
          'En attente',
          '${dashboard.transactionsEnAttente}',
          Icons.hourglass_empty_rounded,
        ),
      ],
    );
  }

  Widget _metricTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.prosocGreen, size: 22),
          const Spacer(),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _resumeMensuelCard(PercepteurResumeMensuel resume) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resume.mois.isNotEmpty ? resume.mois : 'Période',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${resume.nombreTransactions} transactions • '
                  '${resume.atteinteObjectif.toStringAsFixed(0)} % objectif',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            resume.montantTotal.toStringAsFixed(0),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.prosocGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _objectifCard(ObjectifPercepteur objectif) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            objectif.typeObjectif.isNotEmpty
                ? objectif.typeObjectif
                : 'Objectif',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (objectif.atteinte / 100).clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade200,
            color: AppColors.prosocGreen,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            '${objectif.realise.toStringAsFixed(0)} / ${objectif.objectif.toStringAsFixed(0)} '
            '(${objectif.atteinte.toStringAsFixed(0)} %)',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _topAgentCard(TopAgentPercepteur agent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.prosocGreen.withValues(alpha: 0.12),
            child: Text(
              '#${agent.rang > 0 ? agent.rang : agent.agentId}',
              style: const TextStyle(
                color: AppColors.prosocGreen,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agent.nomAgent.isNotEmpty
                      ? agent.nomAgent
                      : 'Agent #${agent.agentId}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${agent.nombreTransactions} tx • '
                  '${agent.tauxSucces.toStringAsFixed(0)} % succès',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            agent.montantTotal.toStringAsFixed(0),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _agentStatsCard(PercepteurAgentStats agent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline, color: AppColors.prosocGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agent.nomAgent.isNotEmpty
                      ? agent.nomAgent
                      : 'Agent #${agent.agentId}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${agent.nombreJoursActifs} j. actifs • '
                  '${agent.nombreTransactions} transactions',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            agent.montantTotal.toStringAsFixed(0),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
