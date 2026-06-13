import 'package:flutter/material.dart';
import 'package:prosoc/config/api.dart';
import 'package:prosoc/config/colors.dart';
import 'package:prosoc/models/wallet_mouvement_model.dart';
import 'package:prosoc/utils/api_error_helper.dart';
import 'package:prosoc/utils/formatters.dart';

class WalletMouvementDetailScreen extends StatefulWidget {
  final int mouvementId;
  final WalletMouvementModel? preview;

  const WalletMouvementDetailScreen({
    super.key,
    required this.mouvementId,
    this.preview,
  });

  @override
  State<WalletMouvementDetailScreen> createState() =>
      _WalletMouvementDetailScreenState();
}

class _WalletMouvementDetailScreenState
    extends State<WalletMouvementDetailScreen> {
  WalletMouvementModel? _mouvement;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _mouvement = widget.preview;
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = _mouvement == null;
      _error = null;
    });

    try {
      final response = await ApiService.getWalletMouvementById(
        widget.mouvementId,
      );
      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _mouvement = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error =
              response.message ??
              ApiErrorHelper.userFacingMessage(statusCode: response.statusCode);
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException(
        'WalletMouvementDetail',
        e,
        stackTrace,
        false,
      );
      if (!mounted) return;
      setState(() {
        _error = ApiErrorHelper.userFacingNetwork();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
        ),
        title: const Text(
          'Détail du mouvement',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _mouvement == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.prosocGreen),
      );
    }

    if (_error != null && _mouvement == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadDetail,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.prosocGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final m = _mouvement!;
    final isPositive = m.isCredit || (!m.isDebit && m.montant >= 0);
    final color = isPositive ? AppColors.prosocGreen : AppColors.errorColor;

    return RefreshIndicator(
      color: AppColors.prosocGreen,
      onRefresh: _loadDetail,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPositive ? 'Crédit' : 'Débit',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppFormatters.formatCurrencyDollar(m.montant.abs()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    m.formattedDate,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: 'Opération',
              rows: [
                _DetailRow('Description', _valueOrDash(m.description)),
                _DetailRow('Type', _valueOrDash(m.typeOperation)),
                _DetailRow('Source', m.sourceDisplay),
                _DetailRow(
                  'Date',
                  AppFormatters.formatDateTime(m.dateOperation),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildSection(
              title: 'Références',
              rows: [
                _DetailRow('N° mouvement', '#${m.idWalletMouvement}'),
                _DetailRow('Wallet ID', m.walletId.toString()),
                _DetailRow('Agent ID', m.walletAgentId.toString()),
              ],
            ),
            const SizedBox(height: 14),
            _buildSection(
              title: 'Agent',
              rows: [
                _DetailRow('Nom', _valueOrDash(m.agentNom)),
                _DetailRow('Matricule', _valueOrDash(m.agentMatricule)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _valueOrDash(String value) =>
      value.trim().isEmpty ? '—' : value.trim();

  Widget _buildSection({
    required String title,
    required List<_DetailRow> rows,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...rows.map(_buildDetailRow),
        ],
      ),
    );
  }

  Widget _buildDetailRow(_DetailRow row) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              row.label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              row.value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);
}
