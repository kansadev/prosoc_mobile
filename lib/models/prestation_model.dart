int _prestationInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

int? _prestationNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

String? _prestationNullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

class Prestation {
  final int id;
  final String nomPrestation;
  final String description;
  final double? montant;
  final int deviseId;
  final String? deviseCode;
  final int? produitMutuelId;
  final String? produitMutuelNom;
  final int? produitAssiseurId;
  final String? produitAssiseurNom;

  Prestation({
    required this.id,
    required this.nomPrestation,
    required this.description,
    this.montant,
    required this.deviseId,
    this.deviseCode,
    this.produitMutuelId,
    this.produitMutuelNom,
    this.produitAssiseurId,
    this.produitAssiseurNom,
  });

  factory Prestation.fromJson(Map<String, dynamic> json) {
    return Prestation(
      id: _prestationInt(json['id']),
      nomPrestation: json['nomPrestation']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      montant: _parseMontant(
        json['montant'] ?? json['prix'] ?? json['montantPrestation'],
      ),
      deviseId: _prestationInt(json['deviseId']),
      deviseCode: _prestationNullableString(json['deviseCode']),
      produitMutuelId: _prestationNullableInt(json['produitMutuelId']),
      produitMutuelNom: json['produitMutuelNom']?.toString(),
      produitAssiseurId: _prestationNullableInt(
        json['produitAssureurId'] ?? json['produitAssiseurId'],
      ),
      produitAssiseurNom: json['produitAssureurNom']?.toString() ??
          json['produitAssiseurNom']?.toString(),
    );
  }

  static double? _parseMontant(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  /// Montant facturable renvoyé par l'API.
  double? resolveMontant() {
    if (montant != null && montant! > 0) return montant;
    return null;
  }

  String resolveDeviseCode() {
    final code = deviseCode?.trim();
    if (code != null && code.isNotEmpty) return code;
    if (deviseId == 2) return 'USD';
    if (deviseId == 1) return 'CDF';
    return '';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nomPrestation': nomPrestation,
      'description': description,
      if (montant != null) 'montant': montant,
      'deviseId': deviseId,
      if (deviseCode != null) 'deviseCode': deviseCode,
      'produitMutuelId': produitMutuelId,
      'produitMutuelNom': produitMutuelNom,
      'produitAssiseurId': produitAssiseurId,
      'produitAssiseurNom': produitAssiseurNom,
    };
  }

  @override
  String toString() {
    return 'Prestation(id: $id, nomPrestation: $nomPrestation)';
  }
}
