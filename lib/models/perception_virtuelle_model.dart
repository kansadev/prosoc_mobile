import '../utils/currency_formatter.dart';

/// Collecte cash en attente de perception virtuelle.
/// GET /api/PerceptionVirtuelle/collectes-en-attente
class CollecteEnAttenteModel {
  final int idCollecte;
  final int agentId;
  final int agentIdEffectif;
  final String agentNom;
  final String agentMatricule;
  final int affilieId;
  final String affilieNom;
  final double montant;
  final double montantDevisePrincipale;
  final String deviseCode;
  final DateTime? dateCollecte;
  final String typeCollecte;
  final String? referencePaiement;
  final String statutPerception;

  const CollecteEnAttenteModel({
    required this.idCollecte,
    required this.agentId,
    required this.agentIdEffectif,
    required this.agentNom,
    required this.agentMatricule,
    required this.affilieId,
    required this.affilieNom,
    required this.montant,
    required this.montantDevisePrincipale,
    required this.deviseCode,
    this.dateCollecte,
    required this.typeCollecte,
    this.referencePaiement,
    required this.statutPerception,
  });

  factory CollecteEnAttenteModel.fromJson(Map<String, dynamic> json) {
    return CollecteEnAttenteModel(
      idCollecte: _asInt(json['idCollecte'] ?? json['IdCollecte']) ?? 0,
      agentId: _asInt(json['agentId'] ?? json['AgentId']) ?? 0,
      agentIdEffectif:
          _asInt(json['agentIdEffectif'] ?? json['AgentIdEffectif']) ?? 0,
      agentNom: (json['agentNom'] ?? json['AgentNom'] ?? '').toString(),
      agentMatricule:
          (json['agentMatricule'] ?? json['AgentMatricule'] ?? '').toString(),
      affilieId: _asInt(json['affilieId'] ?? json['AffilieId']) ?? 0,
      affilieNom: (json['affilieNom'] ?? json['AffilieNom'] ?? '').toString(),
      montant: _asDouble(json['montant'] ?? json['Montant']),
      montantDevisePrincipale: _asDouble(
        json['montantDevisePrincipale'] ?? json['MontantDevisePrincipale'],
      ),
      deviseCode:
          (json['deviseCode'] ?? json['DeviseCode'] ?? 'CDF').toString(),
      dateCollecte: _parseDate(json['dateCollecte'] ?? json['DateCollecte']),
      typeCollecte:
          (json['typeCollecte'] ?? json['TypeCollecte'] ?? '').toString(),
      referencePaiement:
          (json['referencePaiement'] ?? json['ReferencePaiement'])?.toString(),
      statutPerception: (json['statutPerception'] ?? json['StatutPerception'] ??
              'NON_PERCU')
          .toString(),
    );
  }

  String get formattedMontant => CurrencyFormatter.format(
        amount: montant,
        deviseCode: deviseCode,
      );

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? 0;
    return 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

/// Résultat POST /api/PerceptionVirtuelle/confirmer
class PerceptionVirtuelleConfirmResultModel {
  final bool succes;
  final String message;
  final String? codeErreur;
  final int perceptionVirtuelleId;
  final double montantTotal;
  final int nombreCollectes;
  final double soldeRestantAgent;

  const PerceptionVirtuelleConfirmResultModel({
    required this.succes,
    required this.message,
    this.codeErreur,
    required this.perceptionVirtuelleId,
    required this.montantTotal,
    required this.nombreCollectes,
    required this.soldeRestantAgent,
  });

  factory PerceptionVirtuelleConfirmResultModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final nombreCollectes =
        _asInt(json['nombreCollectes'] ?? json['NombreCollectes']) ?? 0;
    final perceptionVirtuelleId = _asInt(
          json['perceptionVirtuelleId'] ?? json['PerceptionVirtuelleId'],
        ) ??
        0;
    final succes = _parseBool(
      json['succes'] ?? json['Succes'] ?? json['success'] ?? json['Success'],
    );

    return PerceptionVirtuelleConfirmResultModel(
      succes: succes ||
          nombreCollectes > 0 ||
          perceptionVirtuelleId > 0,
      message: (json['message'] ?? json['Message'] ?? '').toString(),
      codeErreur: (json['codeErreur'] ?? json['CodeErreur'])?.toString(),
      perceptionVirtuelleId: perceptionVirtuelleId,
      montantTotal: _asDouble(json['montantTotal'] ?? json['MontantTotal']),
      nombreCollectes: nombreCollectes,
      soldeRestantAgent:
          _asDouble(json['soldeRestantAgent'] ?? json['SoldeRestantAgent']),
    );
  }

  static bool _parseBool(dynamic value) {
    if (value == true) return true;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    if (value is num) return value != 0;
    return false;
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? 0;
    return 0;
  }
}
