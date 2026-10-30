import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/collecte_receipt_data.dart';
import '../utils/api_error_helper.dart';
import '../utils/currency_formatter.dart';

/// Génère, imprime et partage le reçu de collecte au format PDF.
///
/// Le reçu est produit localement (frontend only) : aucune dépendance à un
/// service de facturation distant.
abstract final class CollecteReceiptPdfService {
  static const String _filePrefix = 'recu-prosoc';

  /// Reprend la couleur de l'application (`AppColors.prosocGreen`).
  static final PdfColor _green = const PdfColor.fromInt(0xFF2DB467);

  static const PdfColor _borderColor = PdfColor.fromInt(0xFFE2E8F0);
  static const PdfColor _labelColor = PdfColor.fromInt(0xFF64748B);

  static String _formatDate(DateTime date) =>
      DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(date.toLocal());

  static String _formatMontant(CollecteReceiptData receipt) =>
      CurrencyFormatter.format(
        amount: receipt.montant,
        deviseCode: receipt.deviseCode,
        deviseId: receipt.deviseId,
      );

  /// Lignes « libellé / valeur » affichées sur le reçu, dans l'ordre.
  static List<(String, String)> _rows(CollecteReceiptData receipt) {
    final rows = <(String, String)>[
      ('N° reçu', receipt.numeroRecu),
      ('Date', _formatDate(receipt.date)),
      ('Opération', receipt.operation.label),
      ('Montant', _formatMontant(receipt)),
    ];

    void add(String label, String? value) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isEmpty) return;
      rows.add((label, trimmed));
    }

    add('Affilié', receipt.affilieNom);
    add('Code adhésion', receipt.codeAdhesion);
    final collecteur = receipt.collecteurNom?.trim().isNotEmpty == true
        ? receipt.collecteurNom!.trim()
        : (receipt.agentNom?.trim().isNotEmpty == true
              ? receipt.agentNom!.trim()
              : (receipt.extras['Agent collecteur']?.trim().isNotEmpty == true
                    ? receipt.extras['Agent collecteur']!.trim()
                    : (receipt.extras['Collecteur']?.trim().isNotEmpty == true
                          ? receipt.extras['Collecteur']!.trim()
                          : '')));
    if (collecteur.isNotEmpty) {
      add('Collecteur / Agent collecteur', collecteur);
    }
    add('Mode de paiement', receipt.modePaiement);
    add('Référence', receipt.reference);
    add('Statut', receipt.statutPaiement);
    add('Observation', receipt.observation);
    for (final entry in receipt.extras.entries) {
      add(entry.key, entry.value);
    }
    if (receipt.idCollecte != null) {
      rows.add(('Collecte', '#${receipt.idCollecte}'));
    }
    if (receipt.idAdhesion != null) {
      rows.add(('Adhésion', '#${receipt.idAdhesion}'));
    }
    return rows;
  }

  /// Format ticket (70 mm) commun à toutes les opérations, aligné sur le
  /// reçu d'adhésion.
  static final PdfPageFormat _ticketFormat = PdfPageFormat(
    70 * PdfPageFormat.mm,
    350 * PdfPageFormat.mm,
    marginAll: 8 * PdfPageFormat.mm,
  );

  static Future<Uint8List> buildPdfBytes(CollecteReceiptData receipt) async {
    final document = pw.Document(
      title: 'Reçu ${receipt.numeroRecu} — ${receipt.operation.label}',
      author: 'PROSOC',
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: _ticketFormat,
        margin: pw.EdgeInsets.all(8 * PdfPageFormat.mm),
        build: (context) => [_buildTicketReceipt(receipt)],
      ),
    );

    return document.save();
  }

  static pw.Widget _buildTicketReceipt(CollecteReceiptData receipt) {
    final rows = _rows(receipt).where((row) => row.$1 != 'Montant');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Center(
          child: pw.Text(
            'PROSOC',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: _green,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Center(
          child: pw.Text(
            receipt.title.toUpperCase(),
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Divider(color: _borderColor),
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Text(
            _formatMontant(receipt),
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: _green,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Divider(color: _borderColor),
        pw.SizedBox(height: 3),
        ...rows.map(
          (row) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 4),
            padding: const pw.EdgeInsets.only(bottom: 3),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: _borderColor, width: 0.5),
              ),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 48,
                  child: pw.Text(
                    row.$1,
                    style: const pw.TextStyle(fontSize: 7, color: _labelColor),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    row.$2,
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Center(
          child: pw.Text(
            "Reçu généré par l'application mobile PROSOC.",
            style: const pw.TextStyle(fontSize: 7, color: _labelColor),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );
  }

  static Future<File> writeToFile(CollecteReceiptData receipt) async {
    final bytes = await buildPdfBytes(receipt);
    final file = File(
      '${Directory.systemTemp.path}/$_filePrefix-${receipt.numeroRecu}.pdf',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Ouvre la boîte de dialogue d'impression / « enregistrer en PDF ».
  static Future<void> printReceipt(CollecteReceiptData receipt) async {
    await Printing.layoutPdf(
      onLayout: (_) => buildPdfBytes(receipt),
      name: '${receipt.title} ${receipt.numeroRecu}',
      dynamicLayout: false,
    );
  }

  /// Partage le PDF via la feuille système (mail, WhatsApp, etc.).
  static Future<void> shareReceipt(CollecteReceiptData receipt) async {
    final file = await writeToFile(receipt);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        subject: '${receipt.title} ${receipt.numeroRecu}',
        text: _plainTextSummary(receipt),
      ),
    );
  }

  /// Résumé texte joint au partage, pour les messagerie qui n'affichent pas
  /// la pièce jointe.
  static String _plainTextSummary(CollecteReceiptData receipt) {
    final buffer = StringBuffer()
      ..writeln('PROSOC — ${receipt.title}')
      ..writeln('N° ${receipt.numeroRecu}')
      ..writeln('Date : ${_formatDate(receipt.date)}')
      ..writeln('Montant : ${_formatMontant(receipt)}');
    final affilie = receipt.affilieNom?.trim() ?? '';
    if (affilie.isNotEmpty) {
      buffer.writeln('Affilié : $affilie');
    }
    return buffer.toString();
  }

  /// Journalise une erreur de génération sans interrompre le parcours.
  static void logFailure(String context, Object error, StackTrace stackTrace) {
    ApiErrorHelper.logException(context, error, stackTrace, false);
  }
}
