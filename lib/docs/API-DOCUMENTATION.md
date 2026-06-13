# 📚 Documentation API Prosoc

## 🎯 **Vue d'ensemble**

L'API Prosoc est une solution complète de gestion mutualiste avec **pagination universelle**, conçue pour offrir des performances optimales et une expérience développeur exceptionnelle.

### **🚀 Caractéristiques principales**
- **Pagination universelle** sur tous les endpoints de liste
- **Performance optimisée** avec pagination côté serveur
- **Swagger UI** complet et interactif
- **Architecture unifiée** avec BaseApiController
- **Gestion d'erreurs** robuste
- **Logging** intégré

---

## ⚙️ **Guide de Pagination Universelle**

### **🔧 Paramètres de pagination**

Tous les endpoints de pagination acceptent les paramètres suivants :

| Paramètre | Type | Description | Valeur par défaut |
|-----------|-------|-------------|-------------------|
| `pageNumber` | integer | Numéro de la page (commence à 1) | 1 |
| `pageSize` | integer | Nombre d'éléments par page (1-100) | 20 |
| `sortBy` | string | Champ de tri | null |
| `sortDirection` | string | Direction du tri (`asc` ou `desc`) | `asc` |
| `search` | string | Terme de recherche global | null |
| `filters` | string | Filtres avancés (format JSON) | null |

### **📋 Format de réponse paginée**

```json
{
  "data": [
    {
      "id": 1,
      "nom": "Exemple",
      "dateCreation": "2024-01-01T00:00:00Z"
    }
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalItems": 150,
    "totalPages": 8,
    "hasNext": true,
    "hasPrevious": false,
    "firstItem": 1,
    "lastItem": 20
  },
  "filters": [],
  "sorting": {
    "sortBy": "nom",
    "sortDirection": "asc"
  }
}
```

### **🔍 Exemples d'utilisation**

#### **Pagination simple**
```http
GET /api/Utilisateurs?pageNumber=2&pageSize=10
```

#### **Avec tri**
```http
GET /api/Utilisateurs?pageNumber=1&pageSize=20&sortBy=nom&sortDirection=desc
```

#### **Avec recherche**
```http
GET /api/Utilisateurs?search=john&pageNumber=1&pageSize=20
```

#### **Avec filtres avancés**
```http
GET /api/Utilisateurs?filters=[{"field":"statut","operator":"eq","value":"ACTIF"}]
```

---

## 📋 Notes de Version - Mise à jour Mars 2026

### ✨ Changements Récents

#### 🔄 **Pagination Universelle - Mars 2026** 
- **Nouveau système** de pagination universelle sur tous les contrôleurs
- **Architecture unifiée** avec BaseApiController
- **Performance optimisée** avec pagination côté serveur (IQueryable)
- **Endpoints paginés** : 43 endpoints créés/modifiés
- **Contrôleurs transformés** : 31 contrôleurs avec pagination
- **Swagger amélioré** : Routes uniques et documentation complète
- **Filtres avancés** : Support JSON pour filtres complexes
- **Tri personnalisé** : sortBy et sortDirection sur tous les endpoints
- **Métadonnées complètes** : totalPages, hasNext, hasPrevious, etc.

#### 🔄 Module Retrait Agent - Mars 2026
- **Nouveau système** de retrait pour les agents avec validation périodique
- **Périodes autorisées** : 15-20 et 30+ du mois uniquement
- **Génération de jetons** uniques (format "JRT" + 8 caractères)
- **Validation automatique** des soldes WalletAgent
- **Workflow complet** : Demande → Validation → Jeton → Utilisation
- **Nouveaux endpoints** : `/api/retraitagent/*` (15+ endpoints)
- **Nouvelles tables** : `DemandesRetraitAgents` et `JetonsRetraits`

---

## 🛣️ **Routes de l'API - Pagination Universelle**

### **📊 Catégories d'endpoints avec pagination**

#### **🔐 Authentification**
- `POST /api/Auth/login` - Connexion utilisateur
- `POST /api/Auth/register` - Inscription utilisateur
- `POST /api/Auth/refresh` - Rafraîchissement token

#### **👥 Gestion des utilisateurs**
- `GET /api/Utilisateurs` - **Liste paginée** des utilisateurs
- `GET /api/Utilisateurs/{id}` - Détails utilisateur
- `POST /api/Utilisateurs` - Création utilisateur
- `PUT /api/Utilisateurs/{id}` - Mise à jour utilisateur
- `DELETE /api/Utilisateurs/{id}` - Suppression utilisateur

#### **🏥 Gestion des affiliés**
- `GET /api/Affilies` - **Liste paginée** des affiliés
- `GET /api/Affilies/{id}` - Détails affilié
- `GET /api/Affilies/by-agent/{agentId}` - Affiliés par agent
- `GET /api/Affilies/by-agent/{agentId}/paginated` - **Affiliés par agent (paginé)**

#### **💰 Gestion des collectes**
- `GET /api/Collectes` - **Liste paginée** des collectes
- `GET /api/Collectes/{id}` - Détails collecte
- `GET /api/Collectes/by-affilie/{affilieId}/simple` - Collectes par affilié
- `GET /api/Collectes/by-affilie/{affilieId}/paginated` - **Collectes par affilié (paginé)**
- `GET /api/Collectes/by-agent/{agentId}` - Collectes par agent
- `GET /api/Collectes/by-devise/{deviseId}` - Collectes par devise

#### **🎫 Gestion des prestations**
- `GET /api/Prestations` - **Liste paginée** des prestations
- `GET /api/Prestations/{id}` - Détails prestation
- `GET /api/Prestations/by-produit-mutuel/{produitMutuelId}` - Prestations par produit mutuel
- `GET /api/Prestations/by-produit-mutuel/{produitMutuelId}/paginated` - **Prestations par produit mutuel (paginé)**
- `GET /api/Prestations/by-produit-assureur/{produitAssuteurId}` - Prestations par produit assureur

#### **👨‍⚕️ Gestion des agents**
- `GET /api/Agents` - **Liste paginée** des agents
- `GET /api/Agents/{id}` - Détails agent
- `GET /api/Agents/by-superviseur/{superviseurId}` - Agents par superviseur

#### **💳 Gestion des wallets**
- `GET /api/WalletAgents` - **Liste paginée** des wallets agents
- `GET /api/WalletAgents/{id}` - Détails wallet agent
- `GET /api/WalletAgents/by-agent/{agentId}` - Wallet par agent
- `GET /api/WalletAgents/by-agent/{agentId}/paginated` - **Wallet par agent (paginé)**

#### **🏥 Hôpitaux partenaires**
- `GET /api/HopitalPartenaires` - **Liste paginée** des hôpitaux partenaires
- `GET /api/HopitalPartenaires/{id}` - Détails hôpital partenaire

#### **🎫 Jetons médicaux**
- `GET /api/JetonMedicals` - **Liste paginée** des jetons médicaux
- `GET /api/JetonMedicals/{id}` - Détails jeton médical
- `GET /api/JetonMedicals/by-affilie/{affilieId}` - Jetons par affilié

#### **📄 Demandes de bon d'envoi**
- `GET /api/DemandeBonEnvois` - **Liste paginée** des demandes
- `GET /api/DemandeBonEnvois/{id}` - Détails demande
- `GET /api/DemandeBonEnvois/by-affilie/{affilieId}` - Demandes par affilié
- `GET /api/DemandeBonEnvois/by-statut/{statut}/simple` - Demandes par statut
- `GET /api/DemandeBonEnvois/by-statut/{statut}/paginated` - **Demandes par statut (paginé)**

#### **🔄 Demandes de retrait**
- `GET /api/RetraitAgents` - **Liste paginée** des demandes de retrait
- `GET /api/RetraitAgents/{id}` - Détails demande de retrait
- `GET /api/RetraitAgents/by-agent/{agentId}` - Demandes par agent
- `GET /api/RetraitAgents/by-statut/{statut}` - Demandes par statut

#### **🎯 Autres contrôleurs avec pagination**
- `GET /api/Adhesions` - **Liste paginée** des adhésions
- `GET /api/Dependants` - **Liste paginée** des dépendants
- `GET /api/Superviseurs` - **Liste paginée** des superviseurs
- `GET /api/ProduitsMutuels` - **Liste paginée** des produits mutuels
- `GET /api/ProduitsAssureurs` - **Liste paginée** des produits assureurs
- `GET /api/Devises` - **Liste paginée** des devises
- `GET /api/Communes` - **Liste paginée** des communes
- `GET /api/Provinces` - **Liste paginée** des provinces
- `GET /api/CategoriesAdhesions` - **Liste paginée** des catégories d'adhésions
- `GET /api/TypesAdhesions` - **Liste paginée** des types d'adhésions
- `GET /api/Assureurs` - **Liste paginée** des assureurs
- `GET /api/CategoriesAgents` - **Liste paginée** des catégories d'agents
- `GET /api/Roles` - **Liste paginée** des rôles
- `GET /api/Permissions` - **Liste paginée** des permissions
- `GET /api/Antecedents` - **Liste paginée** des antécédents
- `GET /api/BonsEnvoi` - **Liste paginée** des bons d'envoi
- `GET /api/SouscriptionsPrestations` - **Liste paginée** des souscriptions prestations
- `GET /api/TargetAgents` - **Liste paginée** des cibles agents
- `GET /api/WalletMouvements` - **Liste paginée** des mouvements wallets
- `GET /api/WalletsVirtuelsAgents` - **Liste paginée** des wallets virtuels
- `GET /api/ZonesSociales` - **Liste paginée** des zones sociales

---

## 📊 **Dashboard Affilié - Mars 2026**

---

## 🔐 **Authentification**

### **🔑 JWT Token**
L'API utilise l'authentification JWT Bearer.

#### **En-tête requis**
```http
Authorization: Bearer <votre_token_jwt>
```

#### **Durée de vie des tokens**
- **Access Token** : 2 heures (7200 secondes)
- **Refresh Token** : 7 jours

---

## 📊 **Codes d'erreur**

### **🔴 Erreurs client (4xx)**
| Code | Description | Solution |
|------|-------------|-----------|
| 400 | Bad Request | Paramètres invalides |
| 401 | Unauthorized | Token manquant ou invalide |
| 403 | Forbidden | Permissions insuffisantes |
| 404 | Not Found | Ressource introuvable |
| 422 | Unprocessable Entity | Validation échouée |

### **🔴 Erreurs serveur (5xx)**
| Code | Description | Solution |
|------|-------------|-----------|
| 500 | Internal Server Error | Contacter l'admin |
| 503 | Service Unavailable | Service temporairement indisponible |

---

## 🚀 **Déploiement**

### **📋 Prérequis**
- .NET 6.0 Runtime
- MySQL 8.0+
- Redis (optionnel, pour le cache)

### **🔧 Configuration**
```bash
# Installation des dépendances
dotnet restore

# Compilation
dotnet build --configuration Release

# Publication
dotnet publish --configuration Release --output ./publish
```

### **🌍 Variables d'environnement**
```bash
ASPNETCORE_ENVIRONMENT=Production
ConnectionStrings__DefaultServer=votre_connection_mysql
JWT__Secret=votre_secret_jwt
JWT__Issuer=votre_domaine
JWT__Audience=votre_audience
```

---

## 📈 **Performance**

### **⚡ Optimisations implémentées**
- **Pagination côté serveur** avec IQueryable
- **Indexation** des colonnes fréquemment filtrées
- **Lazy Loading** pour les relations
- **Cache Redis** pour les données fréquemment accédées
- **Compression Gzip** des réponses

### **📊 Métriques recommandées**
- **Temps de réponse** : < 200ms (95th percentile)
- **Débit** : > 1000 requêtes/seconde
- **Disponibilité** : > 99.9%

---

## 🧪 **Tests**

### **🔬 Tests unitaires**
```bash
# Exécution des tests unitaires
dotnet test ./Prosoc.Tests.Unit

# Avec couverture de code
dotnet test ./Prosoc.Tests.Unit --collect:"XPlat Code Coverage"
```

### **🔬 Tests d'intégration**
```bash
# Exécution des tests d'intégration
dotnet test ./Prosoc.Tests.Integration
```

---

## 📞 **Support**

### **🆘 En cas de problème**
1. **Vérifier les logs** de l'application
2. **Consulter Swagger UI** pour valider les requêtes
3. **Vérifier le statut** des services dépendants
4. **Contacter l'équipe** de support technique

### **📧 Contact support**
- **Email** : support@prosoc.cd
- **Documentation** : https://docs.prosoc.cd
- **Status Page** : https://status.prosoc.cd

---

## 📝 **Notes de version**

### **🆕 Version 2.0.0**
- ✅ **Pagination universelle** sur tous les endpoints
- ✅ **Swagger UI** amélioré
- ✅ **Performance** optimisée
- ✅ **Architecture** unifiée
- ✅ **Gestion d'erreurs** robuste

### **📜 Historique**
- **v1.0.0** : Version initiale
- **v1.5.0** : Ajout des dashboards
- **v1.8.0** : Optimisations de performance
- **v2.0.0** : Pagination universelle complète

---

## 🎯 **Bonnes pratiques**

### **✅ Recommandations**
1. **Utiliser la pagination** pour les grandes collections
2. **Implémenter le retry** pour les appels réseau
3. **Valider les entrées** côté client
4. **Utiliser les filtres** pour réduire la charge
5. **Mettre en cache** les données statiques

### **❌ À éviter**
1. **Désactiver la pagination** (risque de timeout)
2. **Ignorer les codes d'erreur**
3. **Envoyer des données sensibles** en clair
4. **Surcharger le serveur** avec des requêtes massives

---

## 🏆 **Conclusion**

L'API Prosoc offre une solution complète, performante et évolutive pour la gestion mutualiste. Avec sa **pagination universelle** et son architecture moderne, elle constitue une base solide pour le développement d'applications robustes.

### **🌟 Points forts de la version 2.0.0**
- **43 endpoints** avec pagination intégrée
- **31 contrôleurs** transformés
- **Performance** côté serveur optimisée
- **Swagger** sans conflits de routes
- **Documentation** complète et interactive

**Pour plus d'informations, consultez le Swagger UI :** `https://votre-domaine/swagger`

---

*📅 Dernière mise à jour : Mars 2026*  
*👨‍💻 Auteur : Équipe de développement Prosoc*  
*📄 Version : 2.0.0*

#### 🔄 Modèle Utilisateur - Simplification
- **Suppression** des champs `PrenomUtilisateur` et `PostNomUtilisateur`
- **Conservation** du champ `NomUtilisateur` comme identifiant principal
- **Ajout** des champs `EmailUtilisateur` et `PhoneUtilisateur` (nullable, unique)
- **Modification** du champ `NomComplet` : utilise maintenant `NomUtilisateur` comme source unique

#### 🔄 Modèle Affilie - Amélioration
- **Ajout** du champ `NomComplet` (required, varchar(200))
- **Génération automatique** du `NomComplet` : `Nom + " " + Postnom + " " + Prenom`
- **Logique implémentée** dans `AffilieService.UpdateAsync` et `AdhesionService.CreateWithAffilieAsync`

#### 📸 Nouveaux Champs PhotoUrl - Mars 2026
- **Ajout** du champ `PhotoUrl` au modèle `Agent` (VARCHAR(500), nullable)
- **Ajout** du champ `PhotoUrl` au modèle `Affilie` (VARCHAR(500), nullable)
- **Mise à jour** des DTOs, services et contrôleurs pour gérer les URLs de photos
- **Scripts SQL** de production générés : `AddPhotoUrlToAgent-Production.sql` et `AddPhotoUrlToAffilie-Production.sql`

#### 🔐 Authentification
- **Consolidation** des endpoints sous `/api/Utilisateur/login`
- **Suppression** des contrôleurs legacy : `Auth`, `AuthTest`, `EnhancedAuth`
- **Réponse unifiée** pour `GET /api/Utilisateur/{id}` et `POST /api/Utilisateur/login`

#### 📊 Base de Données
- **Migration** générée : `20260309064518_RemovePrenomPostNomFromUtilisateur.cs`
- **Suppression** des colonnes `PostNomUtilisateur` et `PrenomUtilisateur` de la table `Utilisateurs`
- **Ajout** des colonnes `EmailUtilisateur` et `PhoneUtilisateur` avec contraintes uniques
- **Nouvelles migrations** : `AddPhotoUrlToAgent`, `AddPhotoUrlToAffilie`, `AddRetraitAgentSystem`

---

## Table des matières
1. [Généralités](#généralités)
2. [Authentification](#authentification)
3. [Agents](#agents)
4. [Adhésions](#adhésions)
5. [Affiliés](#affiliés)
6. [📸 Gestion des Photos de Profil](#-gestion-des-photos-de-profil)
7. [💰 Module Retrait Agent](#-module-retrait-agent)
8. [📊 Dashboard Affilié](#-dashboard-affilié)
9. [Zones Sociales](#zones-sociales)
10. [Communes](#communes)
11. [Provinces](#provinces)
12. [Collectes](#collectes)
13. [Devises](#devises)
14. [Prestations](#prestations)
15. [Catégories](#catégories)
16. [Utilisateurs et Rôles](#utilisateurs-et-rôles)
17. [Exemples d'intégration](#exemples-dintégration)
   - [Vue.js](#vuejs)
   - [Flutter](#flutter)

---

## Généralités

### Base URL
- **Production**: `https://dev-prosoc.asdc-rdc.org`
- **Local**: `https://localhost:7116`

### Format des réponses
Toutes les réponses sont au format JSON.

### En-têtes requis
```http
Content-Type: application/json
Authorization: Bearer {token_jwt}
```

### Gestion des erreurs
- **200**: Succès
- **201**: Créé avec succès
- **400**: Requête invalide
- **401**: Non authentifié
- **403**: Non autorisé
- **404**: Ressource non trouvée
- **429**: Trop de requêtes (rate limiting)
- **500**: Erreur serveur interne

---

## Authentification

### POST /api/utilisateur/login
Permet d'obtenir un token JWT pour les requêtes authentifiées.

#### Corps de la requête
```json
{
  "nomUtilisateur": "admin@prosoc.cd",
  "motDePasse": "Admin"
}
```

#### Réponse réussie
```json
{
  "success": true,
  "message": "Authentification réussie",
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "ZYdGc2lF84g+4XLEDWmK4LgpYp8...",
  "tokenType": "Bearer",
  "expiresIn": 7200,
  "expiresAt": "2026-03-12T10:33:06.5645666Z",
  "doitChangerMotDePasse": true,
  "acceptNotification": true,
  "utilisateur": {
    "idUtilisateur": 3,
    "referenceUtilisateur": "",
    "nomComplet": "Sofnatte Panea Obed",
    "nomUtilisateur": "Sofnatte Panea Obed",
    "email": null,
    "telephone": "+243825099299",
    "photoUrl": null,
    "genre": null,
    "statut": true,
    "dateCreation": "2026-03-12T09:28:09.45561",
    "isConnecte": false,
    "doitChangerMotDePasse": true,
    "agentId": 3,
    "affilieId": null
  },
  "nomRole": "Agent (AT)",
  "permissions": [
    "CREATE_USER",
    "READ_USER",
    "UPDATE_USER",
    "CREATE_AGENT",
    "READ_AGENT",
    "UPDATE_AGENT"
  ],
  "primaryRole": {
    "idRole": 8,
    "nom": "Agent (AT)",
    "description": "Agent de Terrain",
    "niveau": 7,
    "statut": true
  },
  "roles": [
    {
      "idRole": 8,
      "nom": "Agent (AT)",
      "description": "Agent de Terrain",
      "niveau": 7,
      "statut": true
    }
  ]
}
```

#### Champs de réponse
| Champ | Type | Description |
|-------|------|-------------|
| `success` | boolean | Indique si l'authentification a réussi |
| `message` | string | Message de confirmation |
| `accessToken` | string | Token JWT d'accès |
| `refreshToken` | string | Token de rafraîchissement |
| `tokenType` | string | Type de token (Bearer) |
| `expiresIn` | int | Durée de vie en secondes (7200 = 2h) |
| `expiresAt` | datetime | Date d'expiration du token |
| `doitChangerMotDePasse` | boolean | Indique si l'utilisateur doit changer son mot de passe |
| `acceptNotification` | boolean | Préférence de notification |
| `utilisateur` | object | Détails de l'utilisateur |
| `nomRole` | string | Nom du rôle principal |
| `permissions` | array | Liste des permissions de l'utilisateur |
| `primaryRole` | object | Rôle principal avec détails |
| `roles` | array | Liste des rôles de l'utilisateur |

#### Notes importantes
- L'authentification peut se faire par `nomUtilisateur`, `EmailUtilisateur` ou `PhoneUtilisateur`
- Les anciens endpoints `/api/auth/login`, `/api/authtest/*` et `/api/enhancedauth/*` ont été supprimés
- Le champ `NomComplet` dans la réponse utilise maintenant `NomUtilisateur` comme source unique
- La réponse inclut `doitChangerMotDePasse` pour forcer le changement de mot de passe
- Les `permissions` et `roles` sont retournés pour le contrôle d'accès
- Le `refreshToken` permet de renouveler l'accessToken sans re-authentification

#### Erreurs possibles
- **401**: Identifiants invalides

---

## 👥 Utilisateurs

### GET /api/utilisateurs
Récupère la liste paginée des utilisateurs.

#### Paramètres de requête
| Paramètre | Type | Description |
|-----------|------|-------------|
| pageNumber | int | Numéro de page (défaut: 1) |
| pageSize | Taille de page (défaut: 20) |
| search | string | Terme de recherche |
| sortBy | string | Champ de tri |
| sortDirection | string | Direction du tri |

#### Réponse
```json
{
  "data": [
    {
      "idUtilisateur": 1,
      "nomUtilisateur": "admin",
      "email": "admin@prosoc.cd",
      "telephone": "+243999999999",
      "statut": true,
      "dateCreation": "2026-03-03T20:56:51.622409"
    }
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalItems": 100,
    "totalPages": 5,
    "hasNext": true,
    "hasPrevious": false
  }
}
```

### POST /api/utilisateurs
Crée un nouvel utilisateur.

#### Corps de la requête
```json
{
  "nomUtilisateur": "nouveau_user",
  "motDePasse": "MotDePasse123!",
  "email": "user@prosoc.cd",
  "telephone": "+243812345678"
}
```

### GET /api/utilisateurs/{id}
Récupère un utilisateur par ID.

### PUT /api/utilisateurs/{id}
Met à jour un utilisateur existant.

### DELETE /api/utilisateurs/{id}
Supprime un utilisateur.

---

## 👨‍⚕️ Agents

### GET /api/agents
Récupère la liste paginée des agents.

#### Réponse
```json
{
  "data": [
    {
      "idAgent": 1,
      "nomAgent": "Kambala",
      "postnomAgent": "M",
      "prenomAgent": "John",
      "telephoneAgent": "+243812345678",
      "photoUrl": "https://storage.prosoc.cd/agents/photo.jpg",
      "statutAgent": true,
      "categorieAgentId": 1
    }
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalItems": 50,
    "totalPages": 3,
    "hasNext": true,
    "hasPrevious": false
  }
}
```

### POST /api/agents
Crée un nouvel agent.

#### Corps de la requête
```json
{
  "nomAgent": "Kambala",
  "postnomAgent": "M",
  "prenomAgent": "John",
  "telephoneAgent": "+243812345678",
  "emailAgent": "john.kambala@prosoc.cd",
  "adresseAgent": "Kinshasa, Gombe",
  "categorieAgentId": 1,
  "superviseurId": null
}
```

### GET /api/agents/{id}
Récupère un agent par ID.

### PUT /api/agents/{id}
Met à jour un agent existant.

#### Corps de la requête
```json
{
  "nomAgent": "Kambala Updated",
  "postnomAgent": "M",
  "prenomAgent": "John",
  "telephoneAgent": "+243812345678",
  "emailAgent": "john.updated@prosoc.cd",
  "adresseAgent": "Kinshasa, Lingwala",
  "photoUrl": "https://storage.prosoc.cd/agents/newphoto.jpg",
  "categorieAgentId": 1,
  "superviseurId": null
}
```

### DELETE /api/agents/{id}
Supprime un agent.

### GET /api/agents/by-superviseur/{superviseurId}
Récupère les agents par superviseur.

---

## 🏥 Affiliés

### GET /api/affilies
Récupère la liste paginée des affiliés.

#### Paramètres de requête
| Paramètre | Type | Description |
|-----------|------|-------------|
| pageNumber | int | Numéro de page |
| pageSize | int | Taille de page |
| search | string | Recherche par nom |
| sortBy | string | Champ de tri |
| sortDirection | string | Direction du tri |

#### Réponse
```json
{
  "data": [
    {
      "idAffilie": 1,
      "nomAffilie": "Mwendanga",
      "postnomAffilie": "K",
      "prenomAffilie": "Pierre",
      "nomComplet": "Mwendanga K Pierre",
      "sexeAffilie": "M",
      "telephoneAffilie": "+243812345678",
      "adresseAffilie": "Kinshasa",
      "dateNaissance": "1990-01-15",
      "photoUrl": "https://storage.prosoc.cd/affilies/photo.jpg",
      "statutAffilie": true,
      "dateAdhesion": "2026-01-01"
    }
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalItems": 1000,
    "totalPages": 50,
    "hasNext": true,
    "hasPrevious": false
  }
}
```

### POST /api/affilies
Crée un nouvel affilié.

#### Corps de la requête
```json
{
  "nomAffilie": "Mwendanga",
  "postnomAffilie": "K",
  "prenomAffilie": "Pierre",
  "sexeAffilie": "M",
  "telephoneAffilie": "+243812345678",
  "adresseAffilie": "Kinshasa, Gombe",
  "dateNaissance": "1990-01-15",
  "emailAffilie": "pierre@email.com",
  "categorieAdhesionId": 1,
  "zoneSocialeId": 1,
  "communeId": 1,
  "dateAdhesion": "2026-01-01"
}
```

### GET /api/affilies/{id}
Récupère un affilié par ID.

### PUT /api/affilies/{id}
Met à jour un affilié existant.

### DELETE /api/affilies/{id}
Supprime un affilié.

### GET /api/affilies/by-agent/{agentId}/paginated
Récupère les affiliés par agent avec pagination.

---

## 📝 Adhésions

### GET /api/adhesions
Récupère la liste paginée des adhésions.

#### Réponse
```json
{
  "data": [
    {
      "idAdhesion": 1,
      "affilieId": 1,
      "produitMutuelId": 1,
      "typeAdhesionId": 1,
      "categorieAdhesionId": 1,
      "dateDebut": "2026-01-01",
      "dateFin": "2026-12-31",
      "statutAdhesion": "ACTIVE",
      "prime": 5000.00,
      "montantCotisation": 5000.00
    }
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalItems": 500,
    "totalPages": 25,
    "hasNext": true,
    "hasPrevious": false
  }
}
```

### POST /api/adhesions
Crée une nouvelle adhésion.

#### Corps de la requête
```json
{
  "affilieId": 1,
  "produitMutuelId": 1,
  "typeAdhesionId": 1,
  "categorieAdhesionId": 1,
  "dateDebut": "2026-01-01",
  "prime": 5000.00,
  "montantCotisation": 5000.00
}
```

### GET /api/adhesions/{id}
Récupère une adhésion par ID.

### PUT /api/adhesions/{id}
Met à jour une adhésion existante.

### DELETE /api/adhesions/{id}
Supprime une adhésion.

---

## 👨‍👩‍👧 Dépendants

### GET /api/dependants
Récupère la liste paginée des dépendants.

#### Réponse
```json
{
  "data": [
    {
      "idDependant": 1,
      "affilieId": 1,
      "nomDependant": "Mwendanga",
      "postnomDependant": "K",
      "prenomDependant": "Marie",
      "sexeDependant": "F",
      "dateNaissance": "2015-06-20",
      "lienParente": "ENFANT",
      "statutDependant": true
    }
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalItems": 300,
    "totalPages": 15,
    "hasNext": true,
    "hasPrevious": false
  }
}
```

### POST /api/dependants
Crée un nouveau dépendant.

#### Corps de la requête
```json
{
  "affilieId": 1,
  "nomDependant": "Mwendanga",
  "postnomDependant": "K",
  "prenomDependant": "Marie",
  "sexeDependant": "F",
  "dateNaissance": "2015-06-20",
  "lienParente": "ENFANT"
}
```

### GET /api/dependants/{id}
Récupère un dépendant par ID.

### PUT /api/dependants/{id}
Met à jour un dépendant existant.

### DELETE /api/dependants/{id}
Supprime un dépendant.

---

## 💰 Collectes

### GET /api/collectes
Récupère la liste paginée des collectes.

#### Réponse
```json
{
  "data": [
    {
      "idCollecte": 1,
      "agentId": 1,
      "affilieId": 1,
      "deviseId": 1,
      "montantCollecte": 5000.00,
      "dateCollecte": "2026-03-10",
      "modePaiement": "ESPECE",
      "statutCollecte": "VALIDEE",
      "referencePaiement": "COL-2026-001"
    }
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalItems": 1000,
    "totalPages": 50,
    "hasNext": true,
    "hasPrevious": false
  }
}
```

### POST /api/collectes
Crée une nouvelle collecte.

#### Corps de la requête
```json
{
  "agentId": 1,
  "affilieId": 1,
  "deviseId": 1,
  "montantCollecte": 5000.00,
  "dateCollecte": "2026-03-10",
  "modePaiement": "ESPECE",
  "referencePaiement": "COL-2026-001"
}
```

### GET /api/collectes/{id}
Récupère une collecte par ID.

### PUT /api/collectes/{id}
Met à jour une collecte existante.

### DELETE /api/collectes/{id}
Supprime une collecte.

### GET /api/collectes/by-affilie/{affilieId}/paginated
Récupère les collectes par affilié avec pagination.

### GET /api/collectes/by-agent/{agentId}
Récupère les collectes par agent.

### GET /api/collectes/by-devise/{deviseId}
Récupère les collectes par devise.

---

## 💳 Wallets Agents

### GET /api/walletagents
Récupère la liste paginée des wallets agents.

#### Réponse
```json
{
  "data": [
    {
      "idWalletAgent": 1,
      "agentId": 1,
      "soldeWallet": 15000.00,
      "deviseId": 1,
      "dateDerniereTransaction": "2026-03-10T15:30:00Z",
      "statutWallet": "ACTIF"
    }
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalItems": 50,
    "totalPages": 3,
    "hasNext": true,
    "hasPrevious": false
  }
}
```

### GET /api/walletagents/{id}
Récupère un wallet agent par ID.

### GET /api/walletagents/by-agent/{agentId}
Récupère le wallet d'un agent.

### GET /api/walletagents/by-agent/{agentId}/paginated
Récupère les wallets d'un agent avec pagination.

---

## 🏥 Hôpitaux Partenaires

### GET /api/hopitalpartenaires
Récupère la liste paginée des hôpitaux partenaires.

#### Réponse
```json
{
  "data": [
    {
      "idHopital": 1,
      "nomHopital": "Hôpital General de Kinshasa",
      "adresseHopital": "Kinshasa, Gombe",
      "telephoneHopital": "+243812345678",
      "emailHopital": "contact@hgk.cd",
      "statutHopital": true
    }
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalItems": 30,
    "totalPages": 2,
    "hasNext": true,
    "hasPrevious": false
  }
}
```

### POST /api/hopitalpartenaires
Crée un nouvel hôpital partenaire.

### GET /api/hopitalpartenaires/{id}
Récupère un hôpital par ID.

### PUT /api/hopitalpartenaires/{id}
Met à jour un hôpital existant.

### DELETE /api/hopitalpartenaires/{id}
Supprime un hôpital.

---

## 🎫 Jetons Médicaux

### GET /api/jetonmedicals
Récupère la liste paginée des jetons médicaux.

#### Réponse
```json
{
  "data": [
    {
      "idJetonMedical": 1,
      "affilieId": 1,
      "hopitalPartenaireId": 1,
      "numeroJeton": "JET-2026-0001",
      "dateCreation": "2026-03-10T10:00:00Z",
      "dateExpiration": "2026-03-17T10:00:00Z",
      "statutJeton": "VALIDE",
      "montant": 10000.00
    }
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalItems": 200,
    "totalPages": 10,
    "hasNext": true,
    "hasPrevious": false
  }
}
```

### POST /api/jetonmedicals
Crée un nouveau jeton médical.

### GET /api/jetonmedicals/{id}
Récupère un jeton médical par ID.

### GET /api/jetonmedicals/by-affilie/{affilieId}
Récupère les jetons médicaux d'un affilié.

---

## 📄 Demandes de Bon d'Envoi

### GET /api/demandebonenvoys
Récupère la liste paginée des demandes de bon d'envoi.

#### Réponse
```json
{
  "data": [
    {
      "idDemande": 1,
      "affilieId": 1,
      "typeDemande": "SOINS_MEDICAUX",
      "statutDemande": "EN_ATTENTE",
      "dateDemande": "2026-03-10T10:00:00Z",
      "montantDemande": 15000.00,
      "motif": "Consultation spécialisée"
    }
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalItems": 100,
    "totalPages": 5,
    "hasNext": true,
    "hasPrevious": false
  }
}
```

### POST /api/demandebonenvoys
Crée une nouvelle demande de bon d'envoi.

### GET /api/demandebonenvoys/{id}
Récupère une demande par ID.

### PUT /api/demandebonenvoys/{id}
Met à jour une demande existante.

### GET /api/demandebonenvoys/by-affilie/{affilieId}
Récupère les demandes par affilié.

### GET /api/demandebonenvoys/by-statut/{statut}/paginated
Récupère les demandes par statut avec pagination.

---

## 🔄 Demandes de Retrait Agent

### GET /api/retraitagents
Récupère la liste paginée des demandes de retrait.

#### Réponse
```json
{
  "data": [
    {
      "idRetrait": 1,
      "agentId": 1,
      "montant": 10000.00,
      "statut": "EN_ATTENTE",
      "dateDemande": "2026-03-15T10:00:00Z",
      "motif": "Retrait pour necesidades personnelles"
    }
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalItems": 50,
    "totalPages": 3,
    "hasNext": true,
    "hasPrevious": false
  }
}
```

### POST /api/retraitagents
Crée une nouvelle demande de retrait.

#### Corps de la requête
```json
{
  "agentId": 1,
  "montant": 10000.00,
  "motif": "Retrait pour necesidades personnelles"
}
```

### GET /api/retraitagents/{id}
Récupère une demande de retrait par ID.

### GET /api/retraitagents/by-agent/{agentId}
Récupère les demandes de retrait par agent.

### GET /api/retraitagents/by-statut/{statut}
Récupère les demandes de retrait par statut.

---

## 📊 Zones Sociales

### GET /api/zonessociales
Récupère la liste paginée des zones sociales.

#### Réponse
```json
{
  "data": [
    {
      "idZoneSociale": 1,
      "nomZoneSociale": "Zone Sociale Kinshasa Est",
      "codeZone": "ZSE-001",
      "provinceId": 1,
      "statutZone": true
    }
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalItems": 20,
    "totalPages": 1,
    "hasNext": false,
    "hasPrevious": false
  }
}
```

### POST /api/zonessociales
Crée une nouvelle zone sociale.

### GET /api/zonessociales/{id}
Récupère une zone sociale par ID.

### PUT /api/zonessociales/{id}
Met à jour une zone sociale existante.

### DELETE /api/zonessociales/{id}
Supprime une zone sociale.

---

## 🏛️ Communes

### GET /api/communes
Récupère la liste paginée des communes.

#### Réponse
```json
{
  "data": [
    {
      "idCommune": 1,
      "nomCommune": "Gombe",
      "provinceId": 1,
      "statutCommune": true
    }
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalItems": 50,
    "totalPages": 3,
    "hasNext": true,
    "hasPrevious": false
  }
}
```

### POST /api/communes
Crée une nouvelle commune.

### GET /api/communes/{id}
Récupère une commune par ID.

### PUT /api/communes/{id}
Met à jour une commune existante.

### DELETE /api/communes/{id}
Supprime une commune.

---

## 🗺️ Provinces

### GET /api/provinces
Récupère la liste paginée des provinces.

#### Réponse
```json
{
  "data": [
    {
      "idProvince": 1,
      "nomProvince": "Kinshasa",
      "codeProvince": "KIN",
      "pays": "RDC",
      "statutProvince": true
    }
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalItems": 26,
    "totalPages": 2,
    "hasNext": true,
    "hasPrevious": false
  }
}
```

### POST /api/provinces
Crée une nouvelle province.

### GET /api/provinces/{id}
Récupère une province par ID.

### PUT /api/provinces/{id}
Met à jour une province existante.

### DELETE /api/provinces/{id}
Supprime une province.

---

## 💱 Devises

### GET /api/devises
Récupère la liste paginée des devises.

#### Réponse
```json
{
  "data": [
    {
      "idDevise": 1,
      "codeDevise": "CDF",
      "nomDevise": "Franc Congolais",
      "symboleDevise": "FC",
      "tauxChange": 1.0,
      "statutDevise": true
    },
    {
      "idDevise": 2,
      "codeDevise": "USD",
      "nomDevise": "Dollar Américain",
      "symboleDevise": "$",
      "tauxChange": 2500.0,
      "statutDevise": true
    }
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalItems": 5,
    "totalPages": 1,
    "hasNext": false,
    "hasPrevious": false
  }
}
```

### POST /api/devises
Crée une nouvelle devise.

### GET /api/devises/{id}
Récupère une devise par ID.

### PUT /api/devises/{id}
Met à jour une devise existante.

### DELETE /api/devises/{id}
Supprime une devise.

---

## 🎫 Prestations

### GET /api/prestations
Récupère la liste paginée des prestations.

#### Réponse
```json
{
  "data": [
    {
      "idPrestation": 1,
      "libellePrestation": "Consultation Médecin Généraliste",
      "typePrestation": "CONSULTATION",
      "produitMutuelId": 1,
      "produitAssureurId": 1,
      "tarifReference": 5000.00,
      "statutPrestation": true
    }
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalItems": 100,
    "totalPages": 5,
    "hasNext": true,
    "hasPrevious": false
  }
}
```

### POST /api/prestations
Crée une nouvelle prestation.

### GET /api/prestations/{id}
Récupère une prestation par ID.

### PUT /api/prestations/{id}
Met à jour une prestation existante.

### DELETE /api/prestations/{id}
Supprime une prestation.

### GET /api/prestations/by-produit-mutuel/{produitMutuelId}/paginated
Récupère les prestations par produit mutuel avec pagination.

### GET /api/prestations/by-produit-assureur/{produitAssuteurId}
Récupère les prestations par produit assureur.

---

## 📦 Produits Mutuels

### GET /api/produitsmutuels
Récupère la liste paginée des produits mutuels.

#### Réponse
```json
{
  "data": [
    {
      "idProduitMutuel": 1,
      "libelleProduit": "Mutuelle Santé Familiale",
      "descriptionProduit": "Couverture santé pour toute la famille",
      "categorieId": 1,
      "tarifAnnuel": 60000.00,
      "statutProduit": true
    }
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalItems": 10,
    "totalPages": 1,
    "hasNext": false,
    "hasPrevious": false
  }
}
```

### POST /api/produitsmutuels
Crée un nouveau produit mutuel.

### GET /api/produitsmutuels/{id}
Récupère un produit mutuel par ID.

### PUT /api/produitsmutuels/{id}
Met à jour un produit mutuel existant.

### DELETE /api/produitsmutuels/{id}
Supprime un produit mutuel.

---

## 🏢 Produits Assureurs

### GET /api/produitsassureurs
Récupère la liste paginée des produits assureurs.

#### Réponse
```json
{
  "data": [
    {
      "idProduitAssuteur": 1,
      "libelleProduit": "Assurance Santé Premium",
      "assureurId": 1,
      "tarifAnnuel": 120000.00,
      "statutProduit": true
    }
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalItems": 15,
    "totalPages": 1,
    "hasNext": false,
    "hasPrevious": false
  }
}
```

### POST /api/produitsassureurs
Crée un nouveau produit assureur.

### GET /api/produitsassureurs/{id}
Récupère un produit assureur par ID.

### PUT /api/produitsassureurs/{id}
Met à jour un produit assureur existant.

### DELETE /api/produitsassureurs/{id}
Supprime un produit assureur.

---

## 🏢 Assureurs

### GET /api/assureurs
Récupère la liste paginée des assureurs.

#### Réponse
```json
{
  "data": [
    {
      "idAssureur": 1,
      "nomAssureur": "Assurance Nationale du Congo",
      "adresseAssureur": "Kinshasa",
      "telephoneAssureau": "+243812345678",
      "emailAssereur": "contact@anc.cd",
      "statutAssureur": true
    }
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalItems": 8,
    "totalPages": 1,
    "hasNext": false,
    "hasPrevious": false
  }
}
```

### POST /api/assureurs
Crée un nouvel assureur.

### GET /api/assureurs/{id}
Récupère un assureur par ID.

### PUT /api/assureurs/{id}
Met à jour un assureur existant.

### DELETE /api/assureurs/{id}
Supprime un assureur.

---

## 📋 Catégories d'Adhésion

### GET /api/categoriesadhesions
Récupère la liste paginée des catégories d'adhésion.

#### Réponse
```json
{
  "data": [
    {
      "idCategorieAdhesion": 1,
      "libelleCategorie": "Standard",
      "descriptionCategorie": "Catégorie d'adhésion standard",
      "tarifMensuel": 5000.00,
      "statutCategorie": true
    }
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalItems": 5,
    "totalPages": 1,
    "hasNext": false,
    "hasPrevious": false
  }
}
```

### POST /api/categoriesadhesions
Crée une nouvelle catégorie d'adhésion.

### GET /api/categoriesadhesions/{id}
Récupère une catégorie d'adhésion par ID.

### PUT /api/categoriesadhesions/{id}
Met à jour une catégorie d'adhésion existante.

### DELETE /api/categoriesadhesions/{id}
Supprime une catégorie d'adhésion.

---

## 📋 Types d'Adhésion

### GET /api/typesadhesions
Récupère la liste paginée des types d'adhésion.

#### Réponse
```json
{
  "data": [
    {
      "idTypeAdhesion": 1,
      "libelleType": "Individuelle",
      "descriptionType": "Adhésion individuelle",
      "statutType": true
    },
    {
      "idTypeAdhesion": 2,
      "libelleType": "Familiale",
      "descriptionType": "Adhésion familiale",
      "statutType": true
    }
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalItems": 3,
    "totalPages": 1,
    "hasNext": false,
    "hasPrevious": false
  }
}
```

### POST /api/typesadhesions
Crée un nouveau type d'adhésion.

### GET /api/typesadhesions/{id}
Récupère un type d'adhésion par ID.

### PUT /api/typesadhesions/{id}
Met à jour un type d'adhésion existant.

### DELETE /api/typesadhesions/{id}
Supprime un type d'adhésion.

---

## 👮 Catégories d'Agents

### GET /api/categoriesagents
Récupère la liste paginée des catégories d'agents.

#### Réponse
```json
{
  "data": [
    {
      "idCategorieAgent": 1,
      "libelleCategorie": "Agent Commercial",
      "descriptionCategorie": "Agent de terrain",
      "commissionTaux": 10.0,
      "statutCategorie": true
    }
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalItems": 4,
    "totalPages": 1,
    "hasNext": false,
    "hasPrevious": false
  }
}
```

### POST /api/categoriesagents
Crée une nouvelle catégorie d'agent.

### GET /api/categoriesagents/{id}
Récupère une catégorie d'agent par ID.

### PUT /api/categoriesagents/{id}
Met à jour une catégorie d'agent existante.

### DELETE /api/categoriesagents/{id}
Supprime une catégorie d'agent.

---

## 🛡️ Rôles

### GET /api/roles
Récupère la liste paginée des rôles.

#### Réponse
```json
{
  "data": [
    {
      "idRole": 1,
      "nomRole": "Admin",
      "descriptionRole": "Administrateur système",
      "statutRole": true
    }
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalItems": 5,
    "totalPages": 1,
    "hasNext": false,
    "hasPrevious": false
  }
}
```

### POST /api/roles
Crée un nouveau rôle.

### GET /api/roles/{id}
Récupère un rôle par ID.

### PUT /api/roles/{id}
Met à jour un rôle existant.

### DELETE /api/roles/{id}
Supprime un rôle.

---

## 🔑 Permissions

### GET /api/permissions
Récupère la liste paginée des permissions.

#### Réponse
```json
{
  "data": [
    {
      "idPermission": 1,
      "nomPermission": "users.read",
      "descriptionPermission": "Lecture des utilisateurs",
      "module": "users"
    }
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalItems": 30,
    "totalPages": 2,
    "hasNext": true,
    "hasPrevious": false
  }
}
```

### POST /api/permissions
Crée une nouvelle permission.

### GET /api/permissions/{id}
Récupère une permission par ID.

### PUT /api/permissions/{id}
Met à jour une permission existante.

### DELETE /api/permissions/{id}
Supprime une permission.

---

## 👨‍⚕️ Superviseurs

### GET /api/superviseurs
Récupère la liste paginée des superviseurs.

#### Réponse
```json
{
  "data": [
    {
      "idSuperviseur": 1,
      "nomSuperviseur": "Manager",
      "postnomSuperviseur": "T",
      "prenomSuperviseur": "Jean",
      "telephoneSuperviseur": "+243812345678",
      "emailSuperviseur": "jean.manager@prosoc.cd",
      "statutSuperviseur": true
    }
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalItems": 10,
    "totalPages": 1,
    "hasNext": false,
    "hasPrevious": false
  }
}
```

### POST /api/superviseurs
Crée un nouveau superviseur.

### GET /api/superviseurs/{id}
Récupère un superviseur par ID.

### PUT /api/superviseurs/{id}
Met à jour un superviseur existant.

### DELETE /api/superviseurs/{id}
Supprime un superviseur.

---

## 📋 Antécédents

### GET /api/antecedents
Récupère la liste paginée des antécédents.

#### Réponse
```json
{
  "data": [
    {
      "idAntecedent": 1,
      "affilieId": 1,
      "typeAntecedent": "MEDICAL",
      "descriptionAntecedent": "Diabète type 2",
      "dateDebut": "2020-01-01",
      "statutAntecedent": true
    }
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalItems": 150,
    "totalPages": 8,
    "hasNext": true,
    "hasPrevious": false
  }
}
```

### POST /api/antecedents
Crée un nouvel antécédent.

### GET /api/antecedents/{id}
Récupère un antécédent par ID.

### PUT /api/antecedents/{id}
Met à jour un antécédent existant.

### DELETE /api/antecedents/{id}
Supprime un antécédent.

---

## 📄 Bons d'Envoi

### GET /api/bonsenvoi
Récupère la liste paginée des bons d'envoi.

#### Réponse
```json
{
  "data": [
    {
      "idBonEnvoi": 1,
      "affilieId": 1,
      "demandeBonEnvoiId": 1,
      "numeroBon": "BE-2026-0001",
      "dateEmission": "2026-03-10T10:00:00Z",
      "dateValidite": "2026-03-20T10:00:00Z",
      "montantAutorise": 15000.00,
      "statutBon": "VALIDE"
    }
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalItems": 80,
    "totalPages": 4,
    "hasNext": true,
    "hasPrevious": false
  }
}
```

### POST /api/bonsenvoi
Crée un nouveau bon d'envoi.

### GET /api/bonsenvoi/{id}
Récupère un bon d'envoi par ID.

### PUT /api/bonsenvoi/{id}
Met à jour un bon d'envoi existant.

### DELETE /api/bonsenvoi/{id}
Supprime un bon d'envoi.

---

## 📊 Souscriptions Prestations

### GET /api/souscriptionsprestations
Récupère la liste paginée des souscriptions prestations.

#### Réponse
```json
{
  "data": [
    {
      "idSouscription": 1,
      "adhesionId": 1,
      "prestationId": 1,
      "dateSouscription": "2026-03-10T10:00:00Z",
      "statutSouscription": "ACTIVE",
      "montant": 5000.00
    }
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalItems": 200,
    "totalPages": 10,
    "hasNext": true,
    "hasPrevious": false
  }
}
```

### POST /api/souscriptionsprestations
Crée une nouvelle souscription prestation.

### GET /api/souscriptionsprestations/{id}
Récupère une souscription par ID.

### PUT /api/souscriptionsprestations/{id}
Met à jour une souscription existante.

### DELETE /api/souscriptionsprestations/{id}
Supprime une souscription.

---

## 🎯 Cibles Agents

### GET /api/targetagents
Récupère la liste paginée des cibles agents.

#### Réponse
```json
{
  "data": [
    {
      "idTarget": 1,
      "agentId": 1,
      "annee": 2026,
      "mois": 3,
      "cibleNombreAffilies": 50,
      "cibleMontantCollecte": 250000.00,
      "realisationAffilies": 30,
      "realisationMontant": 150000.00
    }
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalItems": 100,
    "totalPages": 5,
    "hasNext": true,
    "hasPrevious": false
  }
}
```

### POST /api/targetagents
Crée une nouvelle cible agent.

### GET /api/targetagents/{id}
Récupère une cible par ID.

### PUT /api/targetagents/{id}
Met à jour une cible existante.

### DELETE /api/targetagents/{id}
Supprime une cible.

---

## 💳 Mouvement Wallets

### GET /api/walletmouvements
Récupère la liste paginée des mouvements wallets.

#### Réponse
```json
{
  "data": [
    {
      "idMouvement": 1,
      "walletAgentId": 1,
      "typeMouvement": "CREDIT",
      "montant": 5000.00,
      "dateMouvement": "2026-03-10T10:00:00Z",
      "reference": "COL-2026-001",
      "description": "Collecte effectuée"
    }
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalItems": 500,
    "totalPages": 25,
    "hasNext": true,
    "hasPrevious": false
  }
}
```

### POST /api/walletmouvements
Crée un nouveau mouvement wallet.

### GET /api/walletmouvements/{id}
Récupère un mouvement par ID.

---

## 💰 Wallets Virtuels Agents

### GET /api/walletsvirtuelsagents
Récupère la liste paginée des wallets virtuels agents.

#### Réponse
```json
{
  "data": [
    {
      "idWalletVirtuel": 1,
      "agentId": 1,
      "numeroCompte": "VV-2026-0001",
      "solde": 10000.00,
      "deviseId": 1,
      "statut": "ACTIF"
    }
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalItems": 50,
    "totalPages": 3,
    "hasNext": true,
    "hasPrevious": false
  }
}
```

### POST /api/walletsvirtuelsagents
Crée un nouveau wallet virtuel agent.

### GET /api/walletsvirtuelsagents/{id}
Récupère un wallet virtuel par ID.

### PUT /api/walletsvirtuelsagents/{id}
Met à jour un wallet virtuel existant.

---

## 💰 Module Retrait Agent - Documentation Complète

### Vue d'ensemble
Le module de retrait agent permet aux agents de demander des retraits de leurs wallets. Ce module comprend :
- **Demandes de retrait** : Les agents peuvent soumettre des demandes de retrait
- **Jetons de retrait** : Des jetons uniques sont générés pour valider les retraits
- **Validation périodique** : Les retraits ne sont autorisés que pendant certaines périodes du mois

### Périodes autorisées
- **15-20 du mois** : Première période de retrait
- **30+ du mois** : Deuxième période de retrait (fin de mois)

### Format des jetons
Les jetons de retrait utilisent le format : `JRT` + 8 caractères aléatoires
Exemple : `JRT1A2B3C4D`

### Endpoints

#### POST /api/retraitagents
Crée une nouvelle demande de retrait.

```json
{
  "agentId": 1,
  "montant": 10000.00,
  "motif": "Retrait pour necesidades personnelles"
}
```

#### GET /api/retraitagents
Récupère toutes les demandes de retrait avec pagination.

#### GET /api/retraitagents/{id}
Récupère une demande de retrait spécifique.

#### PUT /api/retraitagents/{id}/approuver
Approuve une demande de retrait.

#### PUT /api/retraitagents/{id}/rejeter
Rejette une demande de retrait.

#### POST /api/jetonsretraits/generer
Génère un jeton de retrait pour une demande approuvée.

```json
{
  "demandeRetraitId": 1
}
```

#### GET /api/jetonsretraits/valider/{jeton}
Valide un jeton de retrait.

---

## 📸 Gestion des Photos de Profil

### Mise à jour de la photo de profil

#### PUT /api/utilisateurs/{id}/photo
Met à jour la photo de profil d'un utilisateur.

**Content-Type**: multipart/form-data

**Corps de la requête**:
- `file`: Fichier image (JPEG, PNG, max 5MB)

**Réponse**:
```json
{
  "photoUrl": "https://storage.prosoc.cd/users/1/photo.jpg",
  "message": "Photo mise à jour avec succès"
}
```

#### PUT /api/agents/{id}/photo
Met à jour la photo de profil d'un agent.

**Content-Type**: multipart/form-data

**Corps de la requête**:
- `file`: Fichier image (JPEG, PNG, max 5MB)

**Réponse**:
```json
{
  "photoUrl": "https://storage.prosoc.cd/agents/1/photo.jpg",
  "message": "Photo mise à jour avec succès"
}
```

#### PUT /api/affilies/{id}/photo
Met à jour la photo de profil d'un affilié.

**Content-Type**: multipart/form-data

**Corps de la requête**:
- `file`: Fichier image (JPEG, PNG, max 5MB)

**Réponse**:
```json
{
  "photoUrl": "https://storage.prosoc.cd/affilies/1/photo.jpg",
  "message": "Photo mise à jour avec succès"
}
```

### Notes
- Les URLs de photos sont stockées dans le champ `PhotoUrl` (VARCHAR(500))
- Les photos sont servies via un CDN sécurisé
- La compression automatique est appliquée pour optimiser la bande passante

---

## 📊 Dashboard Affilié

### GET /api/affilies/{id}/dashboard
Récupère le tableau de bord d'un affilié.

#### Réponse
```json
{
  "affilie": {
    "idAffilie": 1,
    "nomComplet": "Mwendanga K Pierre",
    "statutAdhesion": "ACTIVE",
    "dateFinValidite": "2026-12-31"
  },
  "prestations": {
    "totalPrestations": 5,
    "montantTotal": 25000.00,
    "prestationsRecentes": [
      {
        "date": "2026-03-10",
        "libelle": "Consultation",
        "montant": 5000.00,
        "statut": "REMBOURSE"
      }
    ]
  },
  "cotisations": {
    "totalVerse": 60000.00,
    "soldeRestant": 0.00,
    "prochainEcheance": "2026-04-01"
  },
  "historique": {
    "collectes": 12,
    "derniereCollecte": "2026-03-10"
  }
}
```

---

## 🧪 Exemples d'Intégration

### Vue.js

#### Installation
```bash
npm install axios
```

#### Configuration
```javascript
// api.js
import axios from 'axios';

const api = axios.create({
  baseURL: 'https://dev-prosoc.asdc-rdc.org',
  headers: {
    'Content-Type': 'application/json'
  }
});

api.interceptors.request.use(config => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export default api;
```

#### Exemple d'utilisation
```javascript
// Authentification
const login = async (nomUtilisateur, motDePasse) => {
  const response = await api.post('/api/utilisateur/login', {
    nomUtilisateur,
    motDePasse
  });
  localStorage.setItem('token', response.data.accessToken);
  return response.data;
};

// Liste paginée d'agents
const getAgents = async (page = 1, pageSize = 20) => {
  const response = await api.get('/api/agents', {
    params: { pageNumber: page, pageSize }
  });
  return response.data;
};

// Créer un nouvel agent
const createAgent = async (agentData) => {
  const response = await api.post('/api/agents', agentData);
  return response.data;
};
```

### Flutter

#### Configuration
```dart
// api_client.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiClient {
  static const String baseUrl = 'https://dev-prosoc.asdc-rdc.org';
  
  Future<Map<String, dynamic>> get(String endpoint, {Map<String, dynamic>? params}) async {
    final queryParams = params?.map((key, value) => MapEntry(key, value.toString()));
    final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);
    
    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    
    return json.decode(response.body);
  }
  
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );
    
    return json.decode(response.body);
  }
}
```

#### Exemple d'utilisation
```dart
// Authentification
final api = ApiClient();
final loginResponse = await api.post('/api/utilisateur/login', {
  'nomUtilisateur': 'admin@prosoc.cd',
  'motDePasse': 'Admin'
});

// Liste paginée d'agents
final agentsResponse = await api.get('/api/agents', params: {
  'pageNumber': 1,
  'pageSize': 20
});

// Créer un nouvel agent
final newAgent = await api.post('/api/agents', {
  'nomAgent': 'Kambala',
  'postnomAgent': 'M',
  'prenomAgent': 'John',
  'telephoneAgent': '+243812345678',
  'categorieAgentId': 1
});
```

---

## 📋 Modifications Récentes - Mars 2026

### Nouvelles Fonctionnalités
1. **Pagination Universelle**
   - Tous les endpoints de liste utilisent maintenant la pagination
   - Paramètres standardisés : pageNumber, pageSize, sortBy, sortDirection, search, filters
   - Réponse structurée avec métadonnées de pagination

2. **Module Retrait Agent**
   - Système complet de demandes de retrait
   - Génération de jetons de validation
   - Périodes de retrait limitées (15-20 et 30+ du mois)

3. **Photos de Profil**
   - Champ PhotoUrl ajouté aux modèles Agent et Affilie
   - Upload de photos via endpoints REST
   - URLs sécurisées avec CDN

### Corrections de Bugs
- Correction du tri sur les champs date
- Amélioration de la performance des requêtes paginées
- Correction des fuites de mémoire dans Swagger

### Améliorations de Performance
- Index optimisés pour les colonnes de recherche
- Pagination côté serveur avec IQueryable
- Cache Redis pour les données statiques

---

## 🔒 Sécurité

### Bonnes pratiques de sécurité
1. **HTTPS uniquement** - Toutes les communications doivent être chiffrées
2. **Stockage sécurisé** - Les tokens JWT doivent être stockés de manière sécurisée
3. **Rotation des tokens** - Implémenter le renouvellement automatique des tokens
4. **Validation des entrées** - Toujours valider les données côté serveur
5. **Rate limiting** - Limiter le nombre de requêtes pour prévenir les attaques

### Headers de sécurité recommandés
```http
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Content-Security-Policy: default-src 'self'
```

---

## 📞 Support Technique

### Ressources
- **Email**: support@prosoc.cd
- **Documentation**: https://docs.prosoc.cd
- **Status Page**: https://status.prosoc.cd

### Signalement de bugs
Pour signaler un bug, veuillez fournir :
1. Description détaillée du problème
2. Étapes pour reproduire
3. Logs applicatifs
4. Version de l'API utilisée

---

*Document généré automatiquement - Dernière mise à jour : Mars 2026*
*Version API : 2.0.0*
*Version Documentation : 2.0.0*
