/// Session caisse — GET /api/Caisse/session/courante, POST …/ouvrir
class SessionCaisseModel {
  final int idSessionCaisse;
  final int utilisateurId;
  final double soldeOuverture;
  final double soldeCourant;
  final int deviseId;
  final String? deviseCode;
  final String? statut;
  final DateTime? dateOuverture;
  final DateTime? dateCloture;

  const SessionCaisseModel({
    required this.idSessionCaisse,
    required this.utilisateurId,
    required this.soldeOuverture,
    required this.soldeCourant,
    required this.deviseId,
    this.deviseCode,
    this.statut,
    this.dateOuverture,
    this.dateCloture,
  });

  bool get isOuverte {
    final s = (statut ?? '').trim().toUpperCase();
    if (s.isEmpty) return dateCloture == null && idSessionCaisse > 0;
    return s == 'OUVERTE' || s == 'OPEN' || s == 'OUVERT';
  }

  factory SessionCaisseModel.fromJson(Map<String, dynamic> json) {
    return SessionCaisseModel(
      idSessionCaisse: _asInt(
            json['idSessionCaisse'] ?? json['IdSessionCaisse'],
          ) ??
          0,
      utilisateurId:
          _asInt(json['utilisateurId'] ?? json['UtilisateurId']) ?? 0,
      soldeOuverture:
          _asDouble(json['soldeOuverture'] ?? json['SoldeOuverture']),
      soldeCourant: _asDouble(json['soldeCourant'] ?? json['SoldeCourant']),
      deviseId: _asInt(json['deviseId'] ?? json['DeviseId']) ?? 0,
      deviseCode: (json['deviseCode'] ?? json['DeviseCode'])?.toString(),
      statut: (json['statut'] ?? json['Statut'])?.toString(),
      dateOuverture: _parseDate(json['dateOuverture'] ?? json['DateOuverture']),
      dateCloture: _parseDate(json['dateCloture'] ?? json['DateCloture']),
    );
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

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
