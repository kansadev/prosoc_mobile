import 'package:flutter/material.dart';
import 'package:prosoc/config/api.dart';
import 'package:prosoc/config/colors.dart';
import 'package:prosoc/models/retrait_agent_model.dart';
import 'package:prosoc/services/auth_service.dart';
import 'package:prosoc/utils/api_error_helper.dart';
import 'package:prosoc/utils/currency_formatter.dart';
import 'package:prosoc/utils/formatters.dart';
import 'package:prosoc/views/widgets/empty_state_widget.dart';
import 'package:prosoc/views/widgets/prosoc_resource_error_view.dart';

/// Historique des demandes de retrait agent
/// (`GET /api/RetraitAgent/by-agent/{agentId}`).
class RetraitHistoriqueScreen extends StatefulWidget {
  const RetraitHistoriqueScreen({super.key});

  @override
  State<RetraitHistoriqueScreen> createState() =>
      _RetraitHistoriqueScreenState();
}

class _RetraitHistoriqueScreenState extends State<RetraitHistoriqueScreen> {
  List<DemandeRetraitAgentModel> _demandes = [];
  bool _isLoading = true;
  String? _error;
  int? _errorStatusCode;

  @override
  void initState() {
    super.initState();
    _loadDemandes(reset: true);
  }

  int? get _agentId => AuthService.currentUser?.utilisateur.agentId;

  Future<void> _loadDemandes({bool reset = false}) async {
    final agentId = _agentId;
    if (agentId == null) {
      setState(() {
        _error = 'Agent non identifié';
        _isLoading = false;
      });
      return;
    }

    if (reset) {
      setState(() {
        _isLoading = true;
        _error = null;
        _errorStatusCode = null;
      });
    }

    try {
      final response = await ApiService.getRetraitAgentByAgent(agentId);
      if (!mounted) return;

      if (response.success && response.data != null) {
        final rows = ApiService.parseRetraitAgentList(response.data)
          ..sort((a, b) {
            final da = a.dateReference;
            final db = b.dateReference;
            if (da == null && db == null) return 0;
            if (da == null) return 1;
            if (db == null) return -1;
            return db.compareTo(da);
          });
        setState(() {
          _demandes = rows;
          _error = null;
          _errorStatusCode = null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.message ??
              ApiErrorHelper.userFacingMessage(
                statusCode: response.statusCode,
              );
          _errorStatusCode = response.statusCode;
          if (reset) _demandes = [];
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('RetraitHistorique', e, stackTrace, false);
      if (!mounted) return;
      setState(() {
        if (reset || _demandes.isEmpty) {
          _error = ApiErrorHelper.userFacingNetwork();
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: const Text(
          'Historique des retraits',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _demandes.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.prosocGreen),
      );
    }

    if (_error != null && _demandes.isEmpty) {
      return ProsocResourceErrorView(
        message: _error!,
        statusCode: _errorStatusCode,
        onRetry: () => _loadDemandes(reset: true),
      );
    }

    if (_demandes.isEmpty) {
      return RefreshIndicator(
        color: AppColors.prosocGreen,
        onRefresh: () => _loadDemandes(reset: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.22),
            const EmptyStateWidget(
              icon: Icons.history_rounded,
              title: 'Aucune demande de retrait',
              subtitle:
                  'Vos demandes de retrait apparaîtront ici une fois soumises.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.prosocGreen,
      onRefresh: () => _loadDemandes(reset: true),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: _demandes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _RetraitDemandeCard(
          demande: _demandes[index],
        ),
      ),
    );
  }
}

class _RetraitDemandeCard extends StatelessWidget {
  final DemandeRetraitAgentModel demande;

  const _RetraitDemandeCard({required this.demande});

  Color _statutColor(String statut) {
    final normalized = statut.trim().toUpperCase();
    if (normalized.contains('REJET') || normalized.contains('REFUS')) {
      return Colors.red.shade700;
    }
    if (normalized.contains('APPROUV') ||
        normalized.contains('VALID') ||
        normalized.contains('TRAITE') ||
        normalized.contains('UTILIS')) {
      return AppColors.prosocGreen;
    }
    if (normalized.contains('ATTENTE') || normalized.contains('PENDING')) {
      return Colors.orange.shade800;
    }
    return AppColors.textSecondary;
  }

  String _statutLabel(String statut) {
    final normalized = statut.trim();
    if (normalized.isEmpty) return 'En attente';
    return normalized.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final statutColor = _statutColor(demande.statutDemande);
    final montantLabel = CurrencyFormatter.format(
      amount: demande.montantDemande,
      deviseId: demande.deviseId,
      deviseCode: demande.deviseCode,
      deviseSymbole: demande.deviseSymbole,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      montantLabel,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      demande.typeRetrait.isNotEmpty
                          ? demande.typeRetrait
                          : 'Retrait',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statutColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statutLabel(demande.statutDemande),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statutColor,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              AppFormatters.formatDateTime(demande.dateReference),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          children: [
            if (demande.motifRetrait.isNotEmpty)
              _detailRow('Motif', demande.motifRetrait),
            if (demande.motifRejet.isNotEmpty)
              _detailRow('Motif de rejet', demande.motifRejet),
            if (demande.deviseCode.isNotEmpty)
              _detailRow('Devise', demande.deviseCode),
            if (demande.dateValidation != null)
              _detailRow(
                'Date validation',
                AppFormatters.formatDateTime(demande.dateValidation),
              ),
            if (demande.dateTraitement != null)
              _detailRow(
                'Date traitement',
                AppFormatters.formatDateTime(demande.dateTraitement),
              ),
            if (demande.agentValidationNom.isNotEmpty)
              _detailRow('Validé par', demande.agentValidationNom),
            if (demande.jetonRetraitCode.isNotEmpty)
              _detailRow('Jeton', demande.jetonRetraitCode),
            if (demande.idDemande > 0)
              _detailRow('Référence', '#${demande.idDemande}'),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
