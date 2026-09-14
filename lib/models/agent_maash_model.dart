/// Couverture / retenues MAASH agent — GET /api/agent-maash/{agentId}/couverture
class AgentMaashBeneficiaire {
  final int id;
  final String nomComplet;
  final String lienParente;

  const AgentMaashBeneficiaire({
    required this.id,
    required this.nomComplet,
    required this.lienParente,
  });

  factory AgentMaashBeneficiaire.fromJson(Map<String, dynamic> json) {
    return AgentMaashBeneficiaire(
      id: _asInt(json['idAgentBeneficiaireMaash'] ?? json['id']),
      nomComplet: (json['nomComplet'] ?? '').toString().trim(),
      lienParente: (json['lienParente'] ?? '').toString().trim(),
    );
  }
}

class AgentMaashCouverture {
  final int agentId;
  final String nomCompletAgent;
  final bool estEligible;
  final bool cotisationMaashPayeePourPeriodeCourante;
  final double montantRetenueMensuelle;
  final int deviseId;
  final String periodeCourante;
  final DateTime? dateDerniereRetenue;
  final int? produitMaashId;
  final String produitMaashNom;
  final List<AgentMaashBeneficiaire> beneficiairesFamille;

  const AgentMaashCouverture({
    required this.agentId,
    required this.nomCompletAgent,
    required this.estEligible,
    required this.cotisationMaashPayeePourPeriodeCourante,
    required this.montantRetenueMensuelle,
    required this.deviseId,
    required this.periodeCourante,
    this.dateDerniereRetenue,
    this.produitMaashId,
    required this.produitMaashNom,
    this.beneficiairesFamille = const [],
  });

  bool get hasRetenueMensuelle => montantRetenueMensuelle > 0;

  factory AgentMaashCouverture.fromJson(Map<String, dynamic> json) {
    final rawBenef = json['beneficiairesFamille'];
    final beneficiaires = <AgentMaashBeneficiaire>[];
    if (rawBenef is List) {
      for (final item in rawBenef) {
        if (item is Map) {
          beneficiaires.add(
            AgentMaashBeneficiaire.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return AgentMaashCouverture(
      agentId: _asInt(json['agentId']),
      nomCompletAgent: (json['nomCompletAgent'] ?? '').toString().trim(),
      estEligible: json['estEligible'] == true,
      cotisationMaashPayeePourPeriodeCourante:
          json['cotisationMaashPayeePourPeriodeCourante'] == true,
      montantRetenueMensuelle: _asDouble(json['montantRetenueMensuelle']),
      deviseId: _asInt(json['deviseId']),
      periodeCourante: (json['periodeCourante'] ?? '').toString().trim(),
      dateDerniereRetenue: _parseDate(json['dateDerniereRetenue']),
      produitMaashId: _asNullableInt(json['produitMaashId']),
      produitMaashNom: (json['produitMaashNom'] ?? '').toString().trim(),
      beneficiairesFamille: beneficiaires,
    );
  }
}

/// Paramètres métier retrait — GET /api/parametres-metier/retrait-agent
class RetraitAgentParametresMetier {
  final int fenetre1Debut;
  final int fenetre1Fin;
  final int fenetre2DerniersJours;
  final double montantMinimumPartiel;
  final double pourcentageMaxPartiel;
  final double montantMaximumPartiel;
  final bool expirationAutomatiqueActivee;
  final int intervalleExpirationMinutes;

  const RetraitAgentParametresMetier({
    required this.fenetre1Debut,
    required this.fenetre1Fin,
    required this.fenetre2DerniersJours,
    required this.montantMinimumPartiel,
    this.pourcentageMaxPartiel = 0,
    this.montantMaximumPartiel = 0,
    this.expirationAutomatiqueActivee = false,
    this.intervalleExpirationMinutes = 0,
  });

  factory RetraitAgentParametresMetier.fromJson(Map<String, dynamic> json) {
    return RetraitAgentParametresMetier(
      fenetre1Debut: _asInt(json['fenetre1Debut']),
      fenetre1Fin: _asInt(json['fenetre1Fin']),
      fenetre2DerniersJours: _asInt(json['fenetre2DerniersJours']),
      montantMinimumPartiel: _asDouble(json['montantMinimumPartiel']),
      pourcentageMaxPartiel: _asDouble(
        json['pourcentageMaxPartiel'] ?? json['PourcentageMaxPartiel'],
      ),
      montantMaximumPartiel: _asDouble(
        json['montantMaximumPartiel'] ?? json['MontantMaximumPartiel'],
      ),
      expirationAutomatiqueActivee:
          json['expirationAutomatiqueActivee'] == true,
      intervalleExpirationMinutes: _asInt(json['intervalleExpirationMinutes']),
    );
  }
}

int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  final parsed = _asInt(value, -1);
  return parsed >= 0 ? parsed : null;
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? 0;
  return 0;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
