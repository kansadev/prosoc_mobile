## Intégration Frontend — Rôle **Chef d’équipe** (dashboard de zone)

Ce document explique comment intégrer côté frontend l’espace **Chef d’équipe** (périmètre *zone sociale*), en consommant les endpoints `DashboardChefEquipe`.

### Pré-requis

- **Authentification**: JWT Bearer (header `Authorization: Bearer <token>`).
- **Rôle requis (string exact)**: `Chef d'équipe` (avec apostrophe et accent).
- **Source de vérité du périmètre**: la zone est déterminée côté serveur (pas côté UI).

### Modèle de périmètre (règles d’accès)

Le backend calcule la zone du chef ainsi:

- **Si titulaire**: la zone où `ZonesSociales.ChefEquipeAgentId == chefAgentId`.
- **Sinon**: fallback sur la fiche agent (`Agents.ZoneSocialeId`).

Les listes/agrégats sont ensuite limités aux **agents AT actifs** de cette zone (hors le chef lui‑même).

### Endpoints disponibles

Base: `GET /api/DashboardChefEquipe/*`  
Autorisation: `[Authorize(Roles = "Chef d'équipe")]`

#### 1) KPIs de la zone

`GET /api/DashboardChefEquipe/kpis`

- **But**: KPIs consolidés mensuels sur les AT de la zone (montants en devise principale).
- **Retour**: `ChefEquipeKpisDto`

Exemple de réponse (200):

```json
{
  "zoneSocialeId": 12,
  "zoneSocialeNom": "Zone A",
  "nombreAgentsAt": 7,
  "collectesMoisZone": 53,
  "totalCollectesMoisZone": 1240.5,
  "devisePrincipaleCode": "USD",
  "collectesEnAttenteZone": 4,
  "transactionsValidesMoisZone": 45
}
```

#### 2) Liste des agents AT de la zone (résumé)

`GET /api/DashboardChefEquipe/agents`

- **But**: alimenter l’écran “Équipe” (carte agent + métriques du mois).
- **Retour**: `ChefEquipeAgentResumeDto[]`

Exemple de réponse (200):

```json
[
  {
    "agentId": 101,
    "nomComplet": "KAMBA John",
    "matricule": "AT-001",
    "telephone": "0990000001",
    "statut": true,
    "collectesMois": 12,
    "totalCollectesMois": 55,
    "collectesEnAttente": 1
  }
]
```

#### 3) Détail commissions / mouvements wallet d’un agent

`GET /api/DashboardChefEquipe/agents/{agentId}/mouvements-wallet?limit=20`

- **But**: afficher les mouvements crédit (commissions) de l’agent.
- **Query**:
  - `limit` (optionnel): défaut serveur **20** si `0`/absent.
- **Retour**: `AgentCommissionsResumeDto`

Notes:
- Le backend vérifie que `agentId` est dans la zone du chef, sinon **403**.

#### 4) Détail collectes d’un agent

`GET /api/DashboardChefEquipe/agents/{agentId}/collectes?limit=50`

- **But**: lister les collectes récentes de l’agent.
- **Query**:
  - `limit` (optionnel): défaut serveur **50** si `0`/absent.
- **Retour**: `ChefEquipeCollecteResumeDto[]`

### Gestion des erreurs (recommandations UI)

- **401 Unauthorized**
  - Token absent/expiré, ou utilisateur sans `agentId` rattaché côté serveur.
  - Action UI: rediriger login / forcer refresh token.
- **403 Forbidden**
  - Le chef tente d’accéder à un `agentId` **hors de sa zone**, ou la zone n’est pas correctement affectée.
  - Action UI: afficher un message “Accès refusé (hors périmètre)”.
- **500**
  - Erreur technique: afficher fallback et proposer “réessayer”.

### Contrats TypeScript (suggestion)

```ts
export interface ChefEquipeKpisDto {
  zoneSocialeId: number;
  zoneSocialeNom?: string | null;
  nombreAgentsAt: number;
  collectesMoisZone: number;
  totalCollectesMoisZone: number;
  devisePrincipaleCode?: string | null;
  collectesEnAttenteZone: number;
  transactionsValidesMoisZone: number;
}

export interface ChefEquipeAgentResumeDto {
  agentId: number;
  nomComplet: string;
  matricule: string;
  telephone?: string | null;
  statut: boolean;
  collectesMois: number;
  totalCollectesMois: number;
  collectesEnAttente: number;
}

export interface ChefEquipeCollecteResumeDto {
  idCollecte: number;
  agentId: number;
  agentNom?: string | null;
  affilieNom?: string | null;
  montant: number;
  statutPaiement?: string | null;
  modePaiement?: string | null;
  dateCollecte: string; // ISO
}

export interface AgentCommissionMouvementDto {
  idWalletMouvement: number;
  montant: number;
  source: string;
  description?: string | null;
  dateOperation: string; // ISO
  nomAffilie?: string | null;
  montantCollecteLiee?: number | null;
}

export interface AgentCommissionsResumeDto {
  soldeWallet: number;
  totalCommissionsMois: number;
  totalCommissionsAnnee: number;
  nombreMouvementsMois: number;
  mouvementsRecents: AgentCommissionMouvementDto[];
}
```

### Exemples Flutter (Dio)

Pré-requis côté app Flutter:

- dépendance: `dio`
- `apiBase` = ex. `https://dev-prosoc.asdc-rdc.org` (sans `/api` à la fin)
- `jwt` disponible en mémoire (state management)

#### Modèles Dart (extrait)

```dart
class ChefEquipeKpisDto {
  final int zoneSocialeId;
  final String? zoneSocialeNom;
  final int nombreAgentsAt;
  final int collectesMoisZone;
  final num totalCollectesMoisZone;
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
      zoneSocialeId: (json['zoneSocialeId'] as num).toInt(),
      zoneSocialeNom: json['zoneSocialeNom'] as String?,
      nombreAgentsAt: (json['nombreAgentsAt'] as num).toInt(),
      collectesMoisZone: (json['collectesMoisZone'] as num).toInt(),
      totalCollectesMoisZone: json['totalCollectesMoisZone'] as num,
      devisePrincipaleCode: json['devisePrincipaleCode'] as String?,
      collectesEnAttenteZone: (json['collectesEnAttenteZone'] as num).toInt(),
      transactionsValidesMoisZone: (json['transactionsValidesMoisZone'] as num).toInt(),
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
  final num totalCollectesMois;
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

  factory ChefEquipeAgentResumeDto.fromJson(Map<String, dynamic> json) {
    return ChefEquipeAgentResumeDto(
      agentId: (json['agentId'] as num).toInt(),
      nomComplet: (json['nomComplet'] as String?) ?? '',
      matricule: (json['matricule'] as String?) ?? '',
      telephone: json['telephone'] as String?,
      statut: json['statut'] as bool? ?? false,
      collectesMois: (json['collectesMois'] as num).toInt(),
      totalCollectesMois: json['totalCollectesMois'] as num,
      collectesEnAttente: (json['collectesEnAttente'] as num).toInt(),
    );
  }
}
```

#### Client API minimal (Dio)

```dart
import 'package:dio/dio.dart';

class ApiAuthException implements Exception {
  final int statusCode;
  final String message;
  ApiAuthException(this.statusCode, this.message);
}

class ChefEquipeApiClient {
  final Dio _dio;

  ChefEquipeApiClient({
    required String apiBase,
    required String jwt,
  }) : _dio = Dio(BaseOptions(
          baseUrl: apiBase,
          headers: {
            'Authorization': 'Bearer $jwt',
            'Accept': 'application/json',
          },
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        ));

  Future<ChefEquipeKpisDto> getKpis() async {
    try {
      final res = await _dio.get('/api/DashboardChefEquipe/kpis');
      return ChefEquipeKpisDto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _rethrowAuthOrTechnical(e);
      rethrow;
    }
  }

  Future<List<ChefEquipeAgentResumeDto>> getAgents() async {
    try {
      final res = await _dio.get('/api/DashboardChefEquipe/agents');
      final list = (res.data as List).cast<dynamic>();
      return list
          .map((x) => ChefEquipeAgentResumeDto.fromJson(x as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _rethrowAuthOrTechnical(e);
      rethrow;
    }
  }

  /// limit: si null -> laisse le serveur appliquer son défaut.
  Future<Map<String, dynamic>> getMouvementsWalletAgent({
    required int agentId,
    int? limit,
  }) async {
    try {
      final res = await _dio.get(
        '/api/DashboardChefEquipe/agents/$agentId/mouvements-wallet',
        queryParameters: limit == null ? null : {'limit': limit},
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _rethrowAuthOrTechnical(e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getCollectesAgent({
    required int agentId,
    int? limit,
  }) async {
    try {
      final res = await _dio.get(
        '/api/DashboardChefEquipe/agents/$agentId/collectes',
        queryParameters: limit == null ? null : {'limit': limit},
      );
      final list = (res.data as List).cast<dynamic>();
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      _rethrowAuthOrTechnical(e);
      rethrow;
    }
  }

  Never _rethrowAuthOrTechnical(DioException e) {
    final code = e.response?.statusCode;
    if (code == 401) {
      throw ApiAuthException(401, "Non authentifié (token expiré ou invalide).");
    }
    if (code == 403) {
      throw ApiAuthException(403, "Accès refusé (hors périmètre zone).");
    }
    throw Exception("Erreur API (${code ?? 'no_status'}): ${e.message}");
  }
}
```

#### Exemple d’appel (écran KPIs)

```dart
final client = ChefEquipeApiClient(apiBase: apiBase, jwt: jwt);
final kpis = await client.getKpis();
// afficher kpis.devisePrincipaleCode, kpis.totalCollectesMoisZone, etc.
```

### Checklist frontend

- **Accès**: n’afficher le menu/onglet Chef d’équipe que si le JWT contient le rôle `Chef d'équipe`.
- **Source des IDs**: pour naviguer vers le détail d’un agent, utiliser uniquement les `agentId` issus de `GET /agents` (évite les appels hors périmètre).
- **Limits**: envoyer `limit` seulement si besoin; sinon laisser les defaults (20 / 50).
- **Resilience**: gérer 401/403 avec une UX claire (relogin vs message d’accès refusé).

