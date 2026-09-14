/// Hôpital partenaire — GET /api/HopitalPartenaire/actifs.
class HopitalPartenaireModel {
  final int idHopital;
  final String nom;
  final String adresse;
  final String telephone;
  final String email;
  final String contactPersonne;
  final String niveau;
  final String codeAcces;
  final bool estActif;
  final bool statut;

  const HopitalPartenaireModel({
    required this.idHopital,
    required this.nom,
    this.adresse = '',
    this.telephone = '',
    this.email = '',
    this.contactPersonne = '',
    this.niveau = '',
    this.codeAcces = '',
    this.estActif = true,
    this.statut = true,
  });

  String get label {
    if (nom.trim().isNotEmpty) return nom.trim();
    return 'Hôpital #$idHopital';
  }

  factory HopitalPartenaireModel.fromJson(Map<String, dynamic> json) {
    return HopitalPartenaireModel(
      idHopital: _asInt(
        json['idHopital'] ?? json['IdHopital'] ?? json['id'] ?? json['Id'],
      ),
      nom: (json['nom'] ?? json['Nom'] ?? '').toString().trim(),
      adresse: (json['adresse'] ?? json['Adresse'] ?? '').toString().trim(),
      telephone:
          (json['telephone'] ?? json['Telephone'] ?? '').toString().trim(),
      email: (json['email'] ?? json['Email'] ?? '').toString().trim(),
      contactPersonne: (json['contactPersonne'] ?? json['ContactPersonne'] ?? '')
          .toString()
          .trim(),
      niveau: (json['niveau'] ?? json['Niveau'] ?? '').toString().trim(),
      codeAcces: (json['codeAcces'] ?? json['CodeAcces'] ?? '')
          .toString()
          .trim(),
      estActif: _asBool(json['estActif'] ?? json['EstActif'], defaultValue: true),
      statut: _asBool(json['statut'] ?? json['Statut'], defaultValue: true),
    );
  }

  static int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  static bool _asBool(dynamic value, {required bool defaultValue}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final n = value.trim().toLowerCase();
      if (n == 'true' || n == '1') return true;
      if (n == 'false' || n == '0') return false;
    }
    return defaultValue;
  }
}
