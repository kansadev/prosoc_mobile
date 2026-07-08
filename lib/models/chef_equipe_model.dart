// ============================================
// Modèles Chef d'équipe (DashboardChefEquipe)
// ============================================

/// Helpers simples de parsing tolérant.
int _asInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

double _asDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? fallback;
  return fallback;
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final n = value.trim().toLowerCase();
    if (n == 'true') return true;
    if (n == 'false') return false;
    if (n == '1') return true;
    if (n == '0') return false;
  }
  return fallback;
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString();
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  final s = value.toString();
  if (s.trim().isEmpty) return null;
  return DateTime.tryParse(s);
}

class ChefEquipeKpisDto {
  final int zoneSocialeId;
  final String? zoneSocialeNom;
  final int nombreAgentsAt;
  final int collectesMoisZone;
  final double totalCollectesMoisZone;
  final String? devisePrincipaleCode;
  final int collectesEnAttenteZone;
  final int transactionsValidesMoisZone;

  ChefEquipeKpisDto({
    required this.zoneSocialeId,
    required this.zoneSocialeNom,
    required this.nombreAgentsAt,
    required this.collectesMoisZone,
    required this.totalCollectesMoisZone,
    required this.devisePrincipaleCode,
    required this.collectesEnAttenteZone,
    required this.transactionsValidesMoisZone,
  });

  factory ChefEquipeKpisDto.fromJson(Map<String, dynamic> json) {
    return ChefEquipeKpisDto(
      zoneSocialeId: _asInt(json['zoneSocialeId'] ?? json['ZoneSocialeId']),
      zoneSocialeNom: json['zoneSocialeNom'] ?? json['ZoneSocialeNom'],
      nombreAgentsAt:
          _asInt(json['nombreAgentsAt'] ?? json['NombreAgentsAt']),
      collectesMoisZone:
          _asInt(json['collectesMoisZone'] ?? json['CollectesMoisZone']),
      totalCollectesMoisZone: _asDouble(
        json['totalCollectesMoisZone'] ?? json['TotalCollectesMoisZone'],
      ),
      devisePrincipaleCode: json['devisePrincipaleCode'] ??
          json['DevisePrincipaleCode'],
      collectesEnAttenteZone: _asInt(
        json['collectesEnAttenteZone'] ?? json['CollectesEnAttenteZone'],
      ),
      transactionsValidesMoisZone: _asInt(
        json['transactionsValidesMoisZone'] ??
            json['TransactionsValidesMoisZone'],
      ),
    );
  }
}

class ChefEquipeAgentResumeDto {
  final int agentId;
  final String nomComplet;
  final String matricule;
  final String? telephone;
  final bool statut;
  final int collectesMois;
  final double totalCollectesMois;
  final int collectesEnAttente;

  ChefEquipeAgentResumeDto({
    required this.agentId,
    required this.nomComplet,
    required this.matricule,
    required this.telephone,
    required this.statut,
    required this.collectesMois,
    required this.totalCollectesMois,
    required this.collectesEnAttente,
  });

  factory ChefEquipeAgentResumeDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return ChefEquipeAgentResumeDto(
      agentId: _asInt(json['agentId'] ?? json['AgentId']),
      nomComplet:
          _asString(json['nomComplet'] ?? json['NomComplet'], fallback: ''),
      matricule:
          _asString(json['matricule'] ?? json['Matricule'], fallback: ''),
      telephone: json['telephone'] ?? json['Telephone'],
      statut: _asBool(json['statut'] ?? json['Statut'], fallback: false),
      collectesMois:
          _asInt(json['collectesMois'] ?? json['CollectesMois']),
      totalCollectesMois: _asDouble(
        json['totalCollectesMois'] ?? json['TotalCollectesMois'],
      ),
      collectesEnAttente: _asInt(
        json['collectesEnAttente'] ?? json['CollectesEnAttente'],
      ),
    );
  }
}

class ChefEquipeCollecteResumeDto {
  final int idCollecte;
  final int agentId;
  final String? agentNom;
  final String? affilieNom;
  final double montant;
  final String? statutPaiement;
  final String? modePaiement;
  final DateTime? dateCollecte;

  ChefEquipeCollecteResumeDto({
    required this.idCollecte,
    required this.agentId,
    required this.agentNom,
    required this.affilieNom,
    required this.montant,
    required this.statutPaiement,
    required this.modePaiement,
    required this.dateCollecte,
  });

  factory ChefEquipeCollecteResumeDto.fromJson(Map<String, dynamic> json) {
    return ChefEquipeCollecteResumeDto(
      idCollecte: _asInt(json['idCollecte'] ?? json['IdCollecte']),
      agentId: _asInt(json['agentId'] ?? json['AgentId']),
      agentNom: json['agentNom'] ?? json['AgentNom'],
      affilieNom: json['affilieNom'] ?? json['AffilieNom'],
      montant: _asDouble(json['montant'] ?? json['Montant']),
      statutPaiement:
          json['statutPaiement'] ?? json['StatutPaiement'],
      modePaiement: json['modePaiement'] ?? json['ModePaiement'],
      dateCollecte:
          _asDateTime(json['dateCollecte'] ?? json['DateCollecte']),
    );
  }
}

class AgentCommissionMouvementDto {
  final int idWalletMouvement;
  final double montant;
  final String source;
  final String? description;
  final DateTime? dateOperation;
  final String? nomAffilie;
  final double? montantCollecteLiee;

  AgentCommissionMouvementDto({
    required this.idWalletMouvement,
    required this.montant,
    required this.source,
    required this.description,
    required this.dateOperation,
    required this.nomAffilie,
    required this.montantCollecteLiee,
  });

  factory AgentCommissionMouvementDto.fromJson(Map<String, dynamic> json) {
    final montantCollecteLieeRaw =
        json['montantCollecteLiee'] ?? json['MontantCollecteLiee'];
    return AgentCommissionMouvementDto(
      idWalletMouvement: _asInt(
        json['idWalletMouvement'] ?? json['IdWalletMouvement'],
      ),
      montant: _asDouble(json['montant'] ?? json['Montant']),
      source: _asString(json['source'] ?? json['Source'], fallback: ''),
      description: json['description'] ?? json['Description'],
      dateOperation:
          _asDateTime(json['dateOperation'] ?? json['DateOperation']),
      nomAffilie: json['nomAffilie'] ?? json['NomAffilie'],
      montantCollecteLiee: montantCollecteLieeRaw == null
          ? null
          : _asDouble(montantCollecteLieeRaw),
    );
  }
}

class AgentCommissionsResumeDto {
  final double soldeWallet;
  final double totalCommissionsMois;
  final double totalCommissionsAnnee;
  final int nombreMouvementsMois;
  final List<AgentCommissionMouvementDto> mouvementsRecents;

  AgentCommissionsResumeDto({
    required this.soldeWallet,
    required this.totalCommissionsMois,
    required this.totalCommissionsAnnee,
    required this.nombreMouvementsMois,
    required this.mouvementsRecents,
  });

  factory AgentCommissionsResumeDto.fromJson(Map<String, dynamic> json) {
    final mouvementsRaw = json['mouvementsRecents'] ??
        json['MouvementsRecents'] ??
        json['mouvements'] ??
        json['Mouvements'];

    final mouvements = <AgentCommissionMouvementDto>[];
    if (mouvementsRaw is List) {
      for (final item in mouvementsRaw) {
        if (item is Map<String, dynamic>) {
          mouvements.add(AgentCommissionMouvementDto.fromJson(item));
        } else if (item is Map) {
          mouvements.add(
            AgentCommissionMouvementDto.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    return AgentCommissionsResumeDto(
      soldeWallet: _asDouble(json['soldeWallet'] ?? json['SoldeWallet']),
      totalCommissionsMois: _asDouble(
        json['totalCommissionsMois'] ?? json['TotalCommissionsMois'],
      ),
      totalCommissionsAnnee: _asDouble(
        json['totalCommissionsAnnee'] ?? json['TotalCommissionsAnnee'],
      ),
      nombreMouvementsMois: _asInt(
        json['nombreMouvementsMois'] ?? json['NombreMouvementsMois'],
      ),
      mouvementsRecents: mouvements,
    );
  }
}

