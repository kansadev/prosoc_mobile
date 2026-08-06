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

bool _prestationBool(dynamic value) {
  if (value == true) return true;
  if (value == false || value == null) return false;
  if (value is num) return value != 0;
  final text = value.toString().trim().toLowerCase();
  return text == 'true' || text == '1';
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
  /// Dérivé du produit lié (non stocké sur Prestation en écriture).
  final bool estGratuit;

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
    this.estGratuit = false,
  });

  /// Gratuit via flag API ou montant à 0.
  bool get isGratuit =>
      estGratuit || (montant != null && montant! == 0);

  factory Prestation.fromJson(Map<String, dynamic> json) {
    final montant = _parseMontant(
      json['montant'] ?? json['prix'] ?? json['montantPrestation'],
    );
    final estGratuitFlag = _prestationBool(
      json['estGratuit'] ?? json['EstGratuit'],
    );

    return Prestation(
      id: _prestationInt(
        json['id'] ?? json['idPrestation'] ?? json['IdPrestation'],
      ),
      nomPrestation: (json['nomPrestation'] ??
              json['nom'] ??
              json['NomPrestation'] ??
              json['Nom'] ??
              '')
          .toString(),
      description: (json['description'] ?? json['Description'] ?? '').toString(),
      montant: montant,
      deviseId: _prestationInt(json['deviseId'] ?? json['DeviseId']),
      deviseCode: _prestationNullableString(
        json['deviseCode'] ?? json['DeviseCode'],
      ),
      produitMutuelId: _prestationNullableInt(
        json['produitMutuelId'] ?? json['ProduitMutuelId'],
      ),
      produitMutuelNom: json['produitMutuelNom']?.toString() ??
          json['ProduitMutuelNom']?.toString(),
      produitAssiseurId: _prestationNullableInt(
        json['produitAssureurId'] ??
            json['produitAssiseurId'] ??
            json['ProduitAssureurId'],
      ),
      produitAssiseurNom: json['produitAssureurNom']?.toString() ??
          json['produitAssiseurNom']?.toString() ??
          json['ProduitAssureurNom']?.toString(),
      estGratuit: estGratuitFlag || (montant != null && montant == 0),
    );
  }

  static double? _parseMontant(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  /// Montant facturable. `0` si gratuite ; `null` si inconnu.
  double? resolveMontant() {
    if (isGratuit) return montant ?? 0;
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

  /// Libellé UI catalogue (badge Gratuit).
  String displayLabel({String? formattedMontant}) {
    if (isGratuit) {
      return '$nomPrestation — Gratuit';
    }
    if (formattedMontant != null && formattedMontant.isNotEmpty) {
      return '$nomPrestation — $formattedMontant';
    }
    return nomPrestation;
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
      // estGratuit : lecture seule — ne pas envoyer en écriture
    };
  }

  @override
  String toString() {
    return 'Prestation(id: $id, nomPrestation: $nomPrestation, '
        'estGratuit: $estGratuit)';
  }
}
