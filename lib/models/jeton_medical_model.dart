/// Jeton médical lié 1-1 à un bon d'envoi.
class JetonMedicalModel {
  final int idJetonMedical;
  final int affilieId;
  final String codeJeton;
  final int bonEnvoiId;
  final String bonEnvoiNumero;
  final String statutJeton;
  final DateTime? dateCreation;
  final DateTime? dateExpiration;
  final DateTime? dateUtilisation;
  final bool estUtilise;
  final bool statut;

  JetonMedicalModel({
    required this.idJetonMedical,
    required this.affilieId,
    required this.codeJeton,
    required this.bonEnvoiId,
    required this.bonEnvoiNumero,
    required this.statutJeton,
    this.dateCreation,
    this.dateExpiration,
    this.dateUtilisation,
    required this.estUtilise,
    required this.statut,
  });

  factory JetonMedicalModel.fromJson(Map<String, dynamic> json) {
    return JetonMedicalModel(
      idJetonMedical: _asInt(json['idJetonMedical'] ?? json['jetonMedicalId']),
      affilieId: _asInt(json['affilieId']),
      codeJeton: _asString(
        json['codeJeton'] ??
            json['jetonMedicalCode'] ??
            json['numeroJeton'] ??
            json['code'],
      ),
      bonEnvoiId: _asInt(json['bonEnvoiId']),
      bonEnvoiNumero: _asString(json['bonEnvoiNumero'] ?? json['numeroBon']),
      statutJeton: _asString(json['statutJeton'] ?? json['statutPaiement']),
      dateCreation: _parseDate(json['dateCreation']),
      dateExpiration: _parseDate(json['dateExpiration']),
      dateUtilisation: _parseDate(json['dateUtilisation']),
      estUtilise: _asBool(json['estUtilise'], defaultValue: false),
      statut: _asBool(json['statut'], defaultValue: true),
    );
  }

  bool get isActif => statut && !estUtilise;

  bool get isExpire {
    final exp = dateExpiration;
    if (exp == null) return false;
    return DateTime.now().isAfter(exp);
  }

  String? get dureeValiditeLabel {
    final creation = dateCreation;
    final expiration = dateExpiration;
    if (expiration == null) return null;
    if (creation != null) {
      final hours = expiration.difference(creation).inHours;
      if (hours > 0 && hours < 48) {
        return 'Valable $hours h (expire le ${_fmt(expiration)})';
      }
      final days = expiration.difference(creation).inDays;
      if (days > 0) {
        return 'Valable $days j (expire le ${_fmt(expiration)})';
      }
    }
    return 'Expire le ${_fmt(expiration)}';
  }

  static String _fmt(DateTime d) {
    final local = d.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${local.year} $hh:$min';
  }
}

int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString();
}

bool _asBool(dynamic value, {required bool defaultValue}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final n = value.trim().toLowerCase();
    if (n == 'true') return true;
    if (n == 'false') return false;
  }
  return defaultValue;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
