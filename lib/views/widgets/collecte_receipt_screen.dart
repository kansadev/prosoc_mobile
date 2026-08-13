import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../config/colors.dart';
import '../../models/collecte_receipt_data.dart';
import '../../utils/currency_formatter.dart';

/// Reçu / facture locale après une opération de collecte (frontend only).
class CollecteReceiptScreen extends StatelessWidget {
  const CollecteReceiptScreen({
    super.key,
    required this.receipt,
    this.popResult,
  });

  final CollecteReceiptData receipt;
  final Object? popResult;

  static Future<T?> show<T>(
    BuildContext context, {
    required CollecteReceiptData receipt,
    T? popResult,
  }) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        builder: (_) => CollecteReceiptScreen(
          receipt: receipt,
          popResult: popResult,
        ),
      ),
    );
  }

  String get _montantLabel => CurrencyFormatter.format(
        amount: receipt.montant,
        deviseCode: receipt.deviseCode,
        deviseId: receipt.deviseId,
      );

  String get _dateLabel =>
      DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(receipt.date.toLocal());

  String get _plainText {
    final buffer = StringBuffer()
      ..writeln('PROSOC — ${receipt.title}')
      ..writeln('N° ${receipt.numeroRecu}')
      ..writeln('Date : $_dateLabel')
      ..writeln('Montant : $_montantLabel');
    if (receipt.affilieNom != null && receipt.affilieNom!.trim().isNotEmpty) {
      buffer.writeln('Affilié : ${receipt.affilieNom!.trim()}');
    }
    if (receipt.codeAdhesion != null &&
        receipt.codeAdhesion!.trim().isNotEmpty) {
      buffer.writeln('Code adhésion : ${receipt.codeAdhesion!.trim()}');
    }
    if (receipt.modePaiement != null &&
        receipt.modePaiement!.trim().isNotEmpty) {
      buffer.writeln('Mode : ${receipt.modePaiement!.trim()}');
    }
    if (receipt.reference != null && receipt.reference!.trim().isNotEmpty) {
      buffer.writeln('Référence : ${receipt.reference!.trim()}');
    }
    if (receipt.idCollecte != null) {
      buffer.writeln('Collecte #${receipt.idCollecte}');
    }
    if (receipt.idAdhesion != null) {
      buffer.writeln('Adhésion #${receipt.idAdhesion}');
    }
    if (receipt.statutPaiement != null &&
        receipt.statutPaiement!.trim().isNotEmpty) {
      buffer.writeln('Statut : ${receipt.statutPaiement!.trim()}');
    }
    for (final entry in receipt.extras.entries) {
      if (entry.value.trim().isEmpty) continue;
      buffer.writeln('${entry.key} : ${entry.value.trim()}');
    }
    buffer.writeln('— Document généré par Prosoc Mobile —');
    return buffer.toString();
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _plainText));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reçu copié dans le presse-papiers')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Reçu'),
        backgroundColor: AppColors.prosocGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Copier',
            onPressed: () => _copy(context),
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.prosocGreen.withValues(alpha: 0.25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.prosocGreen.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: AppColors.prosocGreen,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              receipt.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'N° ${receipt.numeroRecu}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.prosocGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Montant',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _montantLabel,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.prosocGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _row('Date', _dateLabel, isDark),
                  if (receipt.affilieNom?.trim().isNotEmpty == true)
                    _row('Affilié', receipt.affilieNom!.trim(), isDark),
                  if (receipt.codeAdhesion?.trim().isNotEmpty == true)
                    _row('Code adhésion', receipt.codeAdhesion!.trim(), isDark),
                  if (receipt.modePaiement?.trim().isNotEmpty == true)
                    _row('Mode de paiement', receipt.modePaiement!.trim(), isDark),
                  if (receipt.reference?.trim().isNotEmpty == true)
                    _row('Référence', receipt.reference!.trim(), isDark),
                  if (receipt.idCollecte != null)
                    _row('N° collecte', '#${receipt.idCollecte}', isDark),
                  if (receipt.idAdhesion != null)
                    _row('N° adhésion', '#${receipt.idAdhesion}', isDark),
                  if (receipt.statutPaiement?.trim().isNotEmpty == true)
                    _row('Statut', receipt.statutPaiement!.trim(), isDark),
                  if (receipt.observation?.trim().isNotEmpty == true)
                    _row('Observation', receipt.observation!.trim(), isDark),
                  for (final entry in receipt.extras.entries)
                    if (entry.value.trim().isNotEmpty)
                      _row(entry.key, entry.value.trim(), isDark),
                  const SizedBox(height: 16),
                  Text(
                    'Document généré localement par Prosoc Mobile. '
                    'Conservez ce reçu comme preuve de l\'opération.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => _copy(context),
              icon: const Icon(Icons.copy_all_rounded),
              label: const Text('Copier le reçu'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.prosocGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.prosocGreen),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(popResult),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.prosocGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Terminer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
