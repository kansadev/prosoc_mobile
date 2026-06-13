# 📚 Documentation API Prosoc v2.1
> *Système de Gestion Mutualiste Moderne* ![Version](https://img.shields.io/badge/version-2.1-blue) ![Status](https://img.shields.io/badge/status-Production-green)

---

## 🎯 Vue d'ensemble

### 🚀 Caractéristiques principales
- **Architecture RESTful** avec pagination universelle
- **Authentification JWT** avec refresh tokens  
- **Commissionnement automatique** (25% pour les agents)
- **Wallets multiples** (Agent + Virtuel)
- **Workflows métier** complets (Adhésion → Collecte → Commission)
- **Support multi-modes** de paiement (Mobile Money, VIRTUAL_ACCOUNT, etc.)

### 📊 Statistiques actuelles
- **45+ endpoints** opérationnels
- **12 contrôleurs** principaux  
- **Mise à jour** : Mars 2026
- **Base URL** : `https://dev-prosoc.asdc-rdc.org`

### 🎯 Public cible
- **Développeurs Frontend** : React, Vue.js, Angular
- **Développeurs Mobile** : Flutter, React Native
- **Intégrateurs** : Partenaires techniques
- **Administrateurs système** : Monitoring et gestion

---

## 🚀 Getting Started

### 📋 Prérequis techniques
- **Runtime** : .NET 6.0+
- **Base de données** : MySQL 8.0+
- **Authentification** : JWT Bearer Token
- **Formats supportés** : JSON (application/json)

### 🔧 Configuration rapide

#### 🌍 URLs d'environnement
| Environnement | Base URL | Swagger UI |
|---------------|-----------|------------|
| Production | `https://dev-prosoc.asdc-rdc.org` | [Swagger](https://dev-prosoc.asdc-rdc.org/swagger) |
| Local | `https://localhost:7116` | [Swagger](http://localhost:7116/swagger) |
| Staging | `https://staging-prosoc.asdc-rdc.org` | [Swagger](https://staging-prosoc.asdc-rdc.org/swagger) |

#### 📋 En-têtes requis
```http
Content-Type: application/json
Authorization: Bearer {votre_token_jwt}
Accept: application/json
```

### 🎯 Votre premier appel

#### 🔐 Obtenir un token d'accès
```bash
curl -X POST "https://dev-prosoc.asdc-rdc.org/api/utilisateur/login" \
  -H "Content-Type: application/json" \
  -d '{
    "nomUtilisateur": "admin@prosoc.cd",
    "motDePasse": "votre_mot_de_passe"
  }'
```

#### 📤 Tester l'authentification
```bash
curl -X GET "https://dev-prosoc.asdc-rdc.org/api/utilisateur/me" \
  -H "Authorization: Bearer {votre_token}"
```

---

## 🔐 Authentification

### 🎯 Vue d'ensemble du système d'authentification
L'API utilise un système JWT (JSON Web Tokens) avec :
- **Access Token** : 1 heure de validité
- **Refresh Token** : 7 jours de validité  
- **Support multi-identifiants** : Email, Téléphone, Nom d'utilisateur

### POST /api/utilisateur/login
Permet d'obtenir un token JWT pour l'accès à l'API.

#### 📋 Corps de la requête
```json
{
  "nomUtilisateur": "admin@prosoc.cd",
  "motDePasse": "votre_mot_de_passe"
}
```

**Note** : Le champ `nomUtilisateur` accepte :
- Adresse email : `user@domain.com`
- Numéro téléphone : `+243XXXXXXXXX`
- Nom d'utilisateur : `username`

#### 📤 Réponse réussie (200 OK)
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkFkbWluIiwicm9sZSI6IkFkbWluIiwiZXhwIjoxNzQ0NTY3ODkwLCJpc3MiOiJodHRwczovL2xvY2FsaG9zdDo4MDgwL2FwaS9hdXRoL2xvZ2luIiwiaWF0IjoiaHR0cHM6Ly9sb2NhbGhvc3Q6ODA4MC9hcGkvYXV0aC9sb2dpbiJ9.NQrYz7H9oLmX_q8jWkqJhKxMwYpZl4xQaM8kRw",
  "expiresAtUtc": "2026-03-16T20:00:00Z",
  "refreshToken": "def50200-1a4b-4c7c-8d9b-5f9b8c7e2f3a",
  "utilisateur": {
    "idUtilisateur": 1,
    "referenceUtilisateur": "ADMIN001",
    "nomComplet": "Admin User",
    "nomUtilisateur": "admin",
    "emailUtilisateur": "admin@prosoc.cd",
    "phoneUtilisateur": "+243999999999",
    "photoUrl": null,
    "genre": "M",
    "statut": true,
    "dateCreation": "2026-03-03T20:56:51.622409",
    "isConnecte": false,
    "doitChangerMotDePasse": false,
    "agentId": 1,
    "affilieId": null
  }
}
```

#### 🔴 Codes d'erreur
| Code HTTP | Message d'erreur | Cause | Solution |
|-----------|------------------|-------|---------|
| 401 | "Identifiants invalides" | Nom utilisateur ou mot de passe incorrect | Vérifier les identifiants |
| 429 | "Trop de tentatives de connexion" | Rate limiting activé | Attendre 15 minutes |
| 500 | "Erreur interne du serveur" | Problème technique | Contacter le support |

### POST /api/utilisateur/refresh
Rafraîchit le access token en utilisant le refresh token.

#### 📋 Corps de la requête
```json
{
  "refreshToken": "def50200-1a4b-4c7c-8d9b-5f9b8c7e2f3a"
}
```

#### 📤 Réponse réussie
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresAtUtc": "2026-03-16T21:00:00Z"
}
```

### GET /api/utilisateur/me
Récupère les informations de l'utilisateur connecté.

#### 📤 Réponse réussie
```json
{
  "idUtilisateur": 1,
  "referenceUtilisateur": "ADMIN001",
  "nomComplet": "Admin User",
  "nomUtilisateur": "admin",
  "emailUtilisateur": "admin@prosoc.cd",
  "phoneUtilisateur": "+243999999999",
  "photoUrl": "https://storage.prosoc.cd/photos/admin.jpg",
  "genre": "M",
  "statut": true,
  "agentId": 1,
  "affilieId": null
}
```

---

## 📋 Gestion des Adhésions

### 🎯 Vue d'ensemble du workflow d'adhésion

```mermaid
graph TD
    A[Demande d'adhésion] --> B[Validation des données]
    B --> C[Création affilié]
    C --> D[Création utilisateur]
    D --> E[Génération code adhésion]
    E --> F[Traitement collectes]
    F --> G[Commissionnement]
    F --> H[Débit wallet virtuel]
    G --> I[Crédit wallet agent]
    H --> J[Création souscriptions]
    J --> K[Adhésion complète]
```

### 🎯 POST /api/adhesion/with-affilie
**Endpoint principal** pour créer une adhésion complète avec affilié, collectes, souscriptions et dépendants.

#### 🔄 Workflow complet
1. **Validation** des données d'entrée avec règles métier
2. **Création** de l'affilié et de son compte utilisateur automatique
3. **Génération** du code d'adhésion unique (format: TYPE-ANNEE-PROVINCE-NUMERO)
4. **Traitement** des collectes avec commissionnement automatique (25%)
5. **Débit** automatique du wallet virtuel si mode `VIRTUAL_ACCOUNT`
6. **Création** des souscriptions et dépendants avec validation croisée
7. **Transaction** atomique : tout est validé ou rien n'est sauvegardé

#### 📋 Corps de la requête
```json
{
  "nom": "kasongo",
  "prenom": "billy", 
  "postnom": "Ntumba",
  "dateNaissance": "1980-02-27T09:08:53.467Z",
  "telephone": "+24384 8109394",
  "emailAffilie": "billykasongo80@gmail.com",
  "provinceResidence": "Kinshasa",
  "communeResidence": "Selembao",
  "quartierResidence": "Sans-fil",
  "avenueResidence": "Lukunga", 
  "numeroResidence": "50",
  "affilieStatut": true,
  "statutDossier": "En Attente",
  "typeAdhesionId": 1,
  "agentId": 3,
  "adhesionStatut": true,
  "collectes": [
    {
      "typeCollecte": "Frais",
      "fraisId": 1,
      "montant": 1.5,
      "mois": 3,
      "annee": 2026,
      "modePaiement": "VIRTUAL_ACCOUNT",
      "statutPaiement": "OK",
      "montantRecu": 1.5,
      "montantAttendu": 1.5,
      "deviseId": 2,
      "statut": true
    },
    {
      "typeCollecte": "Souscription",
      "souscription": {
        "prestationId": 1,
        "statut": true
      },
      "fraisId": null,
      "montant": 5,
      "mois": 3,
      "annee": 2026,
      "modePaiement": "MOBILE_MONEY",
      "referencePaiement": "REF-MOBILE-001",
      "statutPaiement": "OK",
      "montantRecu": 5,
      "montantAttendu": 5,
      "deviseId": 2,
      "statut": true
    },
    {
      "typeCollecte": "Souscription", 
      "souscription": {
        "prestationId": 2,
        "statut": true
      },
      "fraisId": null,
      "montant": 10,
      "mois": 3,
      "annee": 2026,
      "modePaiement": "VIRTUAL_ACCOUNT",
      "statutPaiement": "OK",
      "montantRecu": 10,
      "montantAttendu": 10,
      "deviseId": 2,
      "statut": true
    }
  ],
  "dependants": [],
  "antecedants": []
}
```

#### 🎯 Validation des données
| Champ | Règle de validation | Exemple |
|-------|-------------------|---------|
| `typeCollecte` | Doit être "Frais" ou "Souscription" | `"Frais"` |
| `modePaiement` | Doit être dans la liste des modes valides | `"VIRTUAL_ACCOUNT"` |
| `referencePaiement` | Obligatoire sauf pour VIRTUAL_ACCOUNT | `"REF-001"` |
| `souscription.prestationId` | Requis si typeCollecte = "Souscription" | `1` |

#### 📤 Réponse réussie (201 Created)
```json
{
  "idAdhesion": 123,
  "codeAdhesion": "KD-26-KIN-001",
  "statutDossier": "Actif",
  "affilie": {
    "idAffilie": 456,
    "codeAdhesion": "KD-26-KIN-001",
    "nomComplet": "kasongo Ntumba billy",
    "dateNaissance": "1980-02-27T09:08:53.467Z",
    "telephone": "+24384 8109394",
    "emailAffilie": "billykasongo80@gmail.com",
    "statut": true
  },
  "utilisateur": {
    "idUtilisateur": 789,
    "nomUtilisateur": "KD-26-KIN-001",
    "emailUtilisateur": "billykasongo80@gmail.com",
    "statut": true
  },
  "collectes": [
    {
      "idCollecte": 1001,
      "typeCollecte": "Frais",
      "montant": 1.5,
      "modePaiement": "VIRTUAL_ACCOUNT",
      "statutPaiement": "OK",
      "agentId": 3
    }
  ],
  "souscriptions": [
    {
      "idSouscriptionPrestation": 501,
      "prestationId": 1,
      "affilieId": 456,
      "statut": true
    }
  ],
  "dependants": [],
  "antecedants": []
}
```

#### 🔴 Codes d'erreur spécifiques
| Code HTTP | Message d'erreur | Cause | Solution |
|-----------|------------------|-------|---------|
| 400 | "TypeCollecte invalide" | Valeur non supportée | Utiliser "Frais" ou "Souscription" |
| 400 | "Mode de paiement invalide" | Mode non reconnu | Utiliser modes valides : ESPECE, MOBILE_MONEY, ORANGE_MONEY, AIRTEL_MONEY, VIREMENT_BANCAIRE, CHEQUE, VIRTUAL_ACCOUNT |
| 400 | "Référence paiement obligatoire" | Mode paiement nécessite référence | Ajouter referencePaiement pour tous les modes sauf VIRTUAL_ACCOUNT |
| 400 | "Solde wallet virtuel insuffisant" | Débit impossible | Vérifier solde ou utiliser autre mode de paiement |
| 400 | "Collecte de type SOUSCRIPTION doit avoir une SouscriptionPrestationId" | Souscription sans prestation | Ajouter objet souscription avec prestationId |
| 409 | "Adhésion déjà existe" | Affilié déjà adhéré | Vérifier statut existant ou créer nouvel affilié |
| 500 | "Erreur technique lors de la création d'adhésion" | Problème base de données ou service | Contacter le support technique |

---

## 💰 Gestion des Wallets

### 🎯 Architecture des wallets

```mermaid
graph LR
    A[Agent] --> B[Wallet Agent]
    A --> C[Wallet Virtuel]
    D[Collecte VIRTUAL_ACCOUNT] --> C
    E[Commission] --> B
    F[Retrait Agent] --> B
```

### 💳 Wallet Virtuel Agent

#### GET /api/wallets-virtuels/{agentId}
Récupère le solde et les mouvements du wallet virtuel d'un agent.

#### 📤 Réponse réussie
```json
{
  "idWalletVirtuelAgent": 1,
  "agentId": 3,
  "soldeVirtuel": 150000,
  "dateModification": "2026-03-16T10:00:00Z",
  "mouvements": [
    {
      "idWalletMouvement": 45,
      "montant": -50.00,
      "typeOperation": "DEBIT",
      "source": "COLLECTE_VIRTUEL",
      "description": "Collecte #789 - Affilie 456",
      "dateOperation": "2026-03-16T14:30:00Z",
      "statut": true
    },
    {
      "idWalletMouvement": 44,
      "montant": 25.00,
      "typeOperation": "CREDIT",
      "source": "COMMISSION_COLLECTE",
      "description": "Commission collecte #788",
      "dateOperation": "2026-03-16T14:25:00Z",
      "statut": true
    }
  ]
}
```

### 💰 Wallet Agent

#### GET /api/wallets-agents/{agentId}
Récupère le solde du wallet commission d'un agent.

#### 📤 Réponse réussie
```json
{
  "idWalletAgent": 1,
  "agentId": 3,
  "soldeCourant": 25000,
  "dateModification": "2026-03-16T10:00:00Z",
  "totalCommissions": 50000,
  "TotalRetraits": 25000
}
```

---

## 🏥 Gestion des Affiliés

### 🎯 GET /api/affilie/souscriptions
Récupère la liste des souscriptions d'un affilié connecté.

#### 🔍 Requête
```http
GET /api/affilie/souscriptions
Authorization: Bearer {token}
```

#### 📤 Réponse réussie
```json
[
  {
    "id": 1,
    "affilieId": 456,
    "prestationId": 1,
    "prestationNom": "Consultation médicale",
    "prestationDescription": "Consultation générale avec médecin généraliste",
    "dateSouscription": "2026-03-01T00:00:00Z",
    "dateCreation": "2026-03-01T00:00:00Z",
    "statut": true,
    "montantPrestation": 100.00,
    "frequencePaiement": "Mensuel",
    "estDejaPayeeCeMois": false,
    "affilieNom": "kasongo Ntumba billy",
    "affiliePrenom": "billy"
  }
]
```

### 💳 POST /api/affilie/paiement
Permet à un affilié de payer sa souscription.

#### 📋 Corps de la requête
```json
{
  "souscriptionPrestationId": 1,
  "montant": 100.00,
  "modePaiement": "Mobile Money",
  "referencePaiement": "REF-PAY-001",
  "deviseId": 2,
  "observation": "Paiement mensuel Mars 2026"
}
```

#### 📤 Réponse réussie (201 Created)
```json
{
  "idCollecte": 1002,
  "typeCollecte": "Souscription",
  "souscriptionPrestationId": 1,
  "affilieId": 456,
  "agentId": 3,
  "montant": 100.00,
  "referencePaiement": "REF-PAY-001",
  "modePaiement": "Mobile Money",
  "statutPaiement": "Validé",
  "montantRecu": 100.00,
  "montantAttendu": 100.00,
  "dateCollecte": "2026-03-16T15:30:00Z",
  "statut": true
}
```

---

## 📱 Guides d'Intégration

### 🎯 React + TypeScript

#### 📦 Installation des dépendances
```bash
npm install axios @types/axios
npm install @types/jsonwebtoken --save-dev
```

#### 🔧 Service API TypeScript
```typescript
// src/services/prosoc-api.ts
export interface Utilisateur {
  idUtilisateur: number;
  nomComplet: string;
  nomUtilisateur: string;
  emailUtilisateur: string;
  photoUrl?: string;
  agentId?: number;
  affilieId?: number;
}

export interface Collecte {
  idCollecte: number;
  typeCollecte: 'Frais' | 'Souscription';
  montant: number;
  modePaiement: string;
  referencePaiement?: string;
}

export interface AdhesionWithAffilieDto {
  nom: string;
  prenom: string;
  postnom: string;
  dateNaissance: string;
  telephone: string;
  emailAffilie: string;
  provinceResidence: string;
  communeResidence: string;
  agentId: number;
  typeAdhesionId: number;
  collectes: Collecte[];
  dependants: any[];
  antecedants: any[];
}

export interface ProsocAPIResponse<T> {
  data: T;
  message?: string;
  errors?: string[];
}

class ProsocAPI {
  private baseURL = 'https://dev-prosoc.asdc-rdc.org/api';
  private token: string;

  constructor(token: string) {
    this.token = token;
  }

  private get headers() {
    return {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${this.token}`
    };
  }

  async login(credentials: { nomUtilisateur: string; motDePasse: string }): Promise<{ accessToken: string; utilisateur: Utilisateur }> {
    const response = await axios.post(
      `${this.baseURL}/utilisateur/login`,
      credentials,
      { headers: { 'Content-Type': 'application/json' } }
    );
    return response.data;
  }

  async createAdhesion(data: AdhesionWithAffilieDto): Promise<ProsocAPIResponse<any>> {
    const response = await axios.post(
      `${this.baseURL}/adhesion/with-affilie`,
      data,
      { headers: this.headers }
    );
    return response.data;
  }

  async getSouscriptions(affilieId: number): Promise<Collecte[]> {
    const response = await axios.get(
      `${this.baseURL}/affilie/souscriptions`,
      { headers: this.headers }
    );
    return response.data;
  }

  async getWalletVirtuel(agentId: number): Promise<any> {
    const response = await axios.get(
      `${this.baseURL}/wallets-virtuels/${agentId}`,
      { headers: this.headers }
    );
    return response.data;
  }
}
```

#### 🎯 Hook React personnalisé
```typescript
// src/hooks/useProsocAPI.ts
import { useMutation, useQuery } from '@tanstack/react-query';
import { ProsocAPI } from '../services/prosoc-api';

export const useProsocAPI = (token: string) => {
  const api = new ProsocAPI(token);

  const createAdhesion = useMutation({
    mutationFn: api.createAdhesion,
    onSuccess: (data) => {
      console.log('Adhésion créée avec succès:', data);
      // Invalider les requêtes en cache
      queryClient.invalidateQueries(['souscriptions']);
      queryClient.invalidateQueries(['wallet']);
    },
    onError: (error: any) => {
      const message = error.response?.data?.message || 'Erreur lors de la création';
      console.error('Erreur création adhésion:', message);
    }
  });

  const getSouscriptions = useQuery({
    queryKey: ['souscriptions'],
    queryFn: () => api.getSouscriptions(affilieId),
    enabled: !!affilieId
  });

  const getWalletVirtuel = useQuery({
    queryKey: ['wallet-virtuel', agentId],
    queryFn: () => api.getWalletVirtuel(agentId),
    enabled: !!agentId
  });

  return { 
    createAdhesion, 
    getSouscriptions, 
    getWalletVirtuel 
  };
};
```

#### 🎯 Composant React d'exemple
```typescript
// src/components/AdhesionForm.tsx
import React from 'react';
import { useProsocAPI } from '../hooks/useProsocAPI';

export const AdhesionForm: React.FC = () => {
  const { createAdhesion } = useProsocAPI('votre_token');
  const [isSubmitting, setIsSubmitting] = React.useState(false);

  const handleSubmit = async (formData: AdhesionWithAffilieDto) => {
    setIsSubmitting(true);
    try {
      await createAdhesion.mutateAsync(formData);
      alert('Adhésion créée avec succès !');
    } catch (error) {
      alert('Erreur lors de la création');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      {/* Champs du formulaire */}
      <button 
        type="submit" 
        disabled={isSubmitting}
        className="btn btn-primary"
      >
        {isSubmitting ? 'Création...' : 'Créer l\'adhésion'}
      </button>
    </form>
  );
};
```

### 🎯 Flutter + Dart

#### 📦 Dépendances dans pubspec.yaml
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^0.13.5
  json_annotation: ^4.8.1
  intl: ^0.18.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  json_serializable: ^6.7.1
  build_runner: ^2.4.6
  retrofit_generator: ^8.0.4
```

#### 🔧 Modèles Dart avec JSON Serialization
```dart
// lib/models/adhesion_models.dart
import 'package:json_annotation/json_annotation.dart';

part 'adhesion_models.g.dart';

@JsonSerializable()
class Collecte {
  @JsonKey(name: 'idCollecte')
  final int idCollecte;
  
  @JsonKey(name: 'typeCollecte')
  final String typeCollecte;
  
  @JsonKey(name: 'montant')
  final double montant;
  
  @JsonKey(name: 'modePaiement')
  final String modePaiement;
  
  @JsonKey(name: 'referencePaiement')
  final String? referencePaiement;

  Collecte({
    required this.idCollecte,
    required this.typeCollecte,
    required this.montant,
    required this.modePaiement,
    this.referencePaiement,
  });

  factory Collecte.fromJson(Map<String, dynamic> json) => _$CollecteFromJson(json);
}

@JsonSerializable()
class AdhesionWithAffilieDto {
  final String nom;
  final String prenom;
  final String postnom;
  final String dateNaissance;
  final String telephone;
  final String emailAffilie;
  final String provinceResidence;
  final String communeResidence;
  final int agentId;
  final int typeAdhesionId;
  final List<Collecte> collectes;
  final List<dynamic> dependants;
  final List<dynamic> antecedants;

  AdhesionWithAffilieDto({
    required this.nom,
    required this.prenom,
    required this.postnom,
    required this.dateNaissance,
    required this.telephone,
    required this.emailAffilie,
    required this.provinceResidence,
    required this.communeResidence,
    required this.agentId,
    required this.typeAdhesionId,
    required this.collectes,
    this.dependants = const [],
    this.antecedants = const [],
  });

  factory AdhesionWithAffilieDto.fromJson(Map<String, dynamic> json) => _$AdhesionWithAffilieDtoFromJson(json);
}
```

#### 🔧 Service API Flutter
```dart
// lib/services/prosoc_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:prosoc_api/models/adhesion_models.dart';

class ProsocAPIService {
  final String _baseURL = 'https://dev-prosoc.asdc-rdc.org/api';
  final String _token;

  ProsocAPIService(this._token);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_token',
  };

  Future<Map<String, dynamic>> login({
    required String nomUtilisateur,
    required String motDePasse,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseURL/utilisateur/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nomUtilisateur': nomUtilisateur,
        'motDePasse': motDePasse,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur de connexion: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> createAdhesion(AdhesionWithAffilieDto data) async {
    final response = await http.post(
      Uri.parse('$_baseURL/adhesion/with-affilie'),
      headers: _headers,
      body: jsonEncode(data.toJson()),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception('Erreur création adhésion: ${errorData['message']}');
    }
  }

  Future<List<dynamic>> getSouscriptions(int affilieId) async {
    final response = await http.get(
      Uri.parse('$_baseURL/affilie/souscriptions'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Erreur récupération souscriptions: ${response.statusCode}');
    }
  }
}
```

#### 🎯 Widget Flutter d'exemple
```dart
// lib/widgets/adhesion_form.dart
import 'package:flutter/material.dart';
import 'package:prosoc_api/models/adhesion_models.dart';
import 'package:prosoc_api/services/prosoc_api_service.dart';

class AdhesionForm extends StatefulWidget {
  @override
  _AdhesionFormState createState() => _AdhesionFormState();
}

class _AdhesionFormState extends State<AdhesionForm> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ProsocAPIService('votre_token');
  bool _isSubmitting = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final formData = AdhesionWithAffilieDto(
        nom: 'kasongo',
        prenom: 'billy',
        postnom: 'Ntumba',
        dateNaissance: '1980-02-27T09:08:53.467Z',
        telephone: '+24384 8109394',
        emailAffilie: 'billykasongo80@gmail.com',
        provinceResidence: 'Kinshasa',
        communeResidence: 'Selembao',
        agentId: 3,
        typeAdhesionId: 1,
        collectes: [
          Collecte(
            idCollecte: 0,
            typeCollecte: 'Frais',
            montant: 1.5,
            modePaiement: 'VIRTUAL_ACCOUNT',
          ),
        ],
      );

      final result = await _apiService.createAdhesion(formData);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Adhésion créée avec succès!')),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nouvelle Adhésion')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Nom'),
                validator: (value) => value?.isEmpty ?? true ? 'Champ requis' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: 'Prénom'),
                validator: (value) => value?.isEmpty ?? true ? 'Champ requis' : null,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                child: _isSubmitting 
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Créer l\'adhésion'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 🚀 Déploiement

### 🐳 Docker Configuration

#### Dockerfile
```dockerfile
# Étape 1 : Build stage
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src
COPY ["Prosoc.csproj", "."]
RUN dotnet restore "./Prosoc.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet publish "Prosoc.csproj" -c Release -o /app/publish

# Étape 2 : Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:6.0
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "ProsocAPI.dll"]
```

#### docker-compose.yml
```yaml
version: '3.8'
services:
  prosoc-api:
    build: .
    ports:
      - "7116:80"
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
      - ConnectionStrings__DefaultServer=Server=mysql;Database=prosocdb;Uid=root;Pwd=password;
      - JWT__Secret=votre_secret_jwt_super_securise
      - JWT__Issuer=https://dev-prosoc.asdc-rdc.org
      - JWT__Audience=https://dev-prosoc.asdc-rdc.org
    depends_on:
      - mysql
      - redis

  mysql:
    image: mysql:8.0
    environment:
      - MYSQL_ROOT_PASSWORD=password
      - MYSQL_DATABASE=prosocdb
    volumes:
      - mysql_data:/var/lib/mysql

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  mysql_data:
```

### 📊 Monitoring et Health Checks

#### Health Check Endpoint
```http
GET /api/health
```

**Réponse healthy :**
```json
{
  "status": "Healthy",
  "timestamp": "2026-03-16T15:30:00Z",
  "version": "2.1.0",
  "uptime": "2.15:30:45",
  "database": "Connected",
  "memory": {
    "allocated": "256MB",
    "used": "180MB"
  }
}
```

#### Metrics Endpoint
```http
GET /api/metrics
Authorization: Bearer {admin_token}
```

---

## 🧪 Testing

### 🔬 Tests unitaires avec Jest
```bash
# Installation
npm install --save-dev jest @types/jest ts-jest

# Exécution
npm test

# Avec couverture
npm test --coverage
```

### 🔬 Tests d'intégration avec Postman
```json
{
  "info": {
    "name": "Prosoc API Collection",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Authentification",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"nomUtilisateur\": \"admin@prosoc.cd\",\n  \"motDePasse\": \"votre_mot_de_passe\"\n}"
        },
        "url": {
          "raw": "{{base_url}}/api/utilisateur/login"
        }
      }
    }
  ]
}
```

---

## 📞 Support et Dépannage

### 🆘 En cas de problème

#### 📋 Checklist de dépannage
1. **Vérifier le statut du service** : https://status.prosoc.cd
2. **Consulter les logs d'erreur** : Application Insights ou logs locaux
3. **Valider le format du token JWT** : Utiliser jwt.io pour décoder
4. **Vérifier les en-têtes HTTP** : Content-Type et Authorization
5. **Tester avec Swagger UI** : https://dev-prosoc.asdc-rdc.org/swagger

#### 🔍 Codes d'erreur communs
| Code HTTP | Catégorie | Action recommandée |
|-----------|------------|-------------------|
| 400 | Validation | Corriger les données envoyées |
| 401 | Authentification | Vérifier le token JWT |
| 403 | Autorisation | Vérifier les permissions |
| 404 | Ressource | Vérifier l'URL et les IDs |
| 429 | Rate Limiting | Attendre avant de réessayer |
| 500 | Serveur | Contacter le support technique |

### 📧 Contact support
- **Email technique** : support@prosoc.cd
- **Documentation** : https://docs.prosoc.cd
- **Status Page** : https://status.prosoc.cd
- **Swagger UI** : https://dev-prosoc.asdc-rdc.org/swagger
- **Health Check** : https://dev-prosoc.asdc-rdc.org/api/health

### 🎯 Temps de réponse cibles
| Type d'endpoint | Temps cible | Temps acceptable |
|-----------------|---------------|----------------|
| Authentification | < 200ms | < 500ms |
| Lecture (GET) | < 300ms | < 800ms |
| Création (POST) | < 500ms | < 1200ms |
| Dashboard | < 800ms | < 1500ms |

---

## 📝 Notes de Version

### 🆕 Version 2.1.0 (Mars 2026)
- ✅ **Endpoint Adhésion** : `/api/adhesion/with-affilie` complètement fonctionnel
- ✅ **Wallet Virtuel** : Débit automatique pour VIRTUAL_ACCOUNT
- ✅ **Commissionnement** : 25% automatique pour les agents
- ✅ **TypeCollecte** : Support chaînes et nombres avec convertisseur
- ✅ **Validation robuste** : Messages d'erreur détaillés
- ✅ **Documentation complète** : Guides d'intégration React/Flutter

### 📜 Historique des versions
- **v2.0.0** : Pagination universelle, authentification unifiée
- **v1.8.0** : Optimisations de performance et dashboards
- **v1.5.0** : Modules retrait agent et jetons médicaux
- **v1.0.0** : Version initiale avec endpoints de base

---

## 🏆 Conclusion

L'API Prosoc v2.1 offre une solution **complète, robuste et évolutive** pour la gestion mutualiste moderne. Avec ses **workflows métier intégrés**, son **système de wallets multiples** et ses **guides d'intégration complets**, elle constitue une base solide pour le développement d'applications professionnelles.

### 🌟 Points forts de la v2.1.0
- **45+ endpoints** opérationnels et documentés
- **Workflows métier** complets (Adhésion → Collecte → Commission)
- **Support multi-mode** de paiement (Mobile Money, VIRTUAL_ACCOUNT, etc.)
- **Architecture RESTful** avec pagination universelle
- **Documentation interactive** avec exemples fonctionnels
- **Guides d'intégration** pour React et Flutter
- **Monitoring intégré** avec health checks et métriques

**Pour commencer l'intégration, consultez le Swagger UI :** `https://dev-prosoc.asdc-rdc.org/swagger`

---

*📅 Dernière mise à jour : 16 Mars 2026*  
*👨‍💻 Auteur : Équipe de développement Prosoc*  
*📄 Version : 2.1.0*  
*🚀 Statut : Production*
