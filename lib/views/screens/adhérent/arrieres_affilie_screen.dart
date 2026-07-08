import 'package:flutter/material.dart';
import 'package:prosoc/config/api.dart';
import 'package:prosoc/config/colors.dart';
import 'package:prosoc/models/arriere_affilie_model.dart';
import 'package:prosoc/services/auth_service.dart';
import 'package:prosoc/utils/api_error_helper.dart';
import 'package:prosoc/utils/arriere_payment_navigator.dart';
import 'package:prosoc/utils/formatters.dart';
import 'package:prosoc/views/widgets/prosoc_resource_error_view.dart';

/// Liste des arriérés d'un affilié (agent) ou de l'affilié connecté.
class ArrieresAffilieScreen extends StatefulWidget {
  final int affilieId;
  final String affilieNom;
  final String affiliePrenom;
  final bool useMesArrieres;
  final String? affilieTelephone;
  final int? agentId;
  final int nombreDependants;

  const ArrieresAffilieScreen({
    super.key,
    required this.affilieId,
    this.affilieNom = '',
    this.affiliePrenom = '',
    this.useMesArrieres = false,
    this.affilieTelephone,
    this.agentId,
    this.nombreDependants = 0,
  });

  /// Arriérés de l'affilié connecté (`/api/arrieres-affilie/mes-arrieres`).
  factory ArrieresAffilieScreen.mesArrieres({
    String affilieNom = '',
    String affiliePrenom = '',
    String? affilieTelephone,
    int nombreDependants = 0,
  }) {
    return ArrieresAffilieScreen(
      affilieId: AuthService.affilieId ?? 0,
      affilieNom: affilieNom,
      affiliePrenom: affiliePrenom,
      affilieTelephone: affilieTelephone,
      useMesArrieres: true,
      nombreDependants: nombreDependants,
    );
  }

  @override
  State<ArrieresAffilieScreen> createState() => _ArrieresAffilieScreenState();
}

class _ArrieresAffilieScreenState extends State<ArrieresAffilieScreen> {
  List<ArriereAffilieModel> _arrieres = [];
  bool _isLoading = true;
  String? _errorMessage;
  int? _errorStatusCode;

  @override
  void initState() {
    super.initState();
    _loadArrieres();
  }

  int get _effectiveAffilieId {
    if (widget.useMesArrieres) {
      return AuthService.affilieId ?? widget.affilieId;
    }
    return widget.affilieId;
  }

  String get _affilieLabel {
    final parts = <String>[
      if (widget.affiliePrenom.trim().isNotEmpty) widget.affiliePrenom.trim(),
      if (widget.affilieNom.trim().isNotEmpty) widget.affilieNom.trim(),
    ];
    return parts.join(' ');
  }

  Future<void> _loadArrieres() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _errorStatusCode = null;
    });

    try {
      final response = widget.useMesArrieres
          ? await ApiService.getMesArrieresAffilie()
          : await ApiService.getArrieresAffilie(widget.affilieId);
      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _arrieres = response.data!;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _errorMessage = response.message ??
            ApiErrorHelper.userFacingMessage(statusCode: response.statusCode);
        _errorStatusCode = response.statusCode;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('ArrieresAffilie/load', e, stackTrace, false);
      if (!mounted) return;
      setState(() {
        _errorMessage = ApiErrorHelper.userFacingNetwork();
        _isLoading = false;
      });
    }
  }

  int get _impayesCount => _arrieres.where((a) => a.estImpaye).length;

  double get _totalResteAPayer => _arrieres
      .where((a) => a.estImpaye)
      .fold<double>(0, (sum, a) => sum + a.restAPayer);

  Future<void> _payerArriere(ArriereAffilieModel arriere) async {
    final affilieId = _effectiveAffilieId > 0
        ? _effectiveAffilieId
        : arriere.affilieId;
    if (affilieId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Affilié introuvable pour ce paiement.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final paid = await ArrierePaymentNavigator.openPayment(
      context: context,
      arriere: arriere,
      affilieId: affilieId,
      affilieNom: widget.affilieNom,
      affiliePrenom: widget.affiliePrenom,
      affilieTelephone: widget.affilieTelephone,
      agentId: widget.agentId,
      nombreDependants: widget.nombreDependants,
    );

    if (paid == true && mounted) {
      await _loadArrieres();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.useMesArrieres ? 'Mes arriérés' : 'Arriérés'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.prosocGreen),
      );
    }

    if (_errorMessage != null) {
      return ProsocResourceErrorView(
        message: _errorMessage!,
        statusCode: _errorStatusCode,
        onRetry: _loadArrieres,
      );
    }

    if (_arrieres.isEmpty) {
      return RefreshIndicator(
        color: AppColors.prosocGreen,
        onRefresh: _loadArrieres,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 80),
            Icon(
              Icons.check_circle_outline,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              widget.useMesArrieres
                  ? 'Vous n\'avez aucun arriéré.'
                  : (_affilieLabel.isNotEmpty
                      ? 'Aucun arriéré pour $_affilieLabel.'
                      : 'Aucun arriéré pour cet affilié.'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.prosocGreen,
      onRefresh: _loadArrieres,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (_affilieLabel.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _affilieLabel,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          _buildSummaryCard(),
          const SizedBox(height: 12),
          ..._arrieres.map(_buildArriereTile),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_impayesCount impayé${_impayesCount > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_arrieres.length} obligation${_arrieres.length > 1 ? 's' : ''} au total',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Reste à payer',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              Text(
                AppFormatters.formatCurrencyDollar(_totalResteAPayer),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArriereTile(ArriereAffilieModel arriere) {
    final isImpaye = arriere.estImpaye;
    final statusColor =
        isImpaye ? AppColors.warningColor : AppColors.prosocGreen;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusColor.withValues(alpha: isImpaye ? 0.25 : 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _iconForType(arriere.typeObligation),
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      arriere.titre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      arriere.typeObligationLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              _statusChip(
                arriere.statutPaiement.isNotEmpty
                    ? arriere.statutPaiement
                    : (isImpaye ? 'Impayé' : 'Payé'),
                statusColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _amountColumn(
                'Attendu',
                AppFormatters.formatCurrencyDollar(arriere.montantAttendu),
              ),
              _amountColumn(
                'Payé',
                AppFormatters.formatCurrencyDollar(arriere.montantPaye),
              ),
              _amountColumn(
                'Reste',
                AppFormatters.formatCurrencyDollar(arriere.restAPayer),
                highlight: isImpaye,
              ),
            ],
          ),
          if (arriere.dateEcheance != null) ...[
            const SizedBox(height: 8),
            Text(
              'Échéance : ${AppFormatters.formatDate(arriere.dateEcheance)}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
          if (isImpaye) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _payerArriere(arriere),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.prosocGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.payments_outlined, size: 18),
                label: Text(
                  'Payer ${AppFormatters.formatCurrencyDollar(arriere.restAPayer)}',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _amountColumn(String label, String value, {bool highlight = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: highlight ? AppColors.warningColor : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type.toUpperCase()) {
      case 'FRAIS':
        return Icons.receipt_long_outlined;
      case 'COTISATION':
        return Icons.payments_outlined;
      case 'SOUSCRIPTION':
        return Icons.medical_services_outlined;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }
}
