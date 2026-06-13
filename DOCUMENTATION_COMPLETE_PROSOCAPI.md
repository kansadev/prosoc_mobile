# Documentation Complete - ProsocAPI

## 1) Vue d'ensemble

`ProsocAPI` est une API backend ASP.NET Core (`net6.0`) orientée gestion mutualiste.  
Elle couvre des workflows métiers complets: authentification/RBAC, adhésion, gestion des affiliés et dépendants, collecte et commissions, produits/prestations, wallets/retraits agents, notifications multi-canaux, synchronisation utilisateur, dashboards multi-rôles et fonctionnalités mobiles.

Le projet suit principalement une architecture en couches:
- `Controllers`: exposition des endpoints HTTP.
- `Services`: logique métier et orchestration.
- `Models`: entités domaine, modèles d'authentification, DTOs.
- `Data`: accès EF Core via `ProsocDbContext`, seed et migrations.
- `Hubs`: communication temps réel (SignalR).

---

## 2) Architecture technique

### Stack principale
- **Framework**: ASP.NET Core Web API.
- **ORM**: Entity Framework Core.
- **Base de données**: MySQL (Pomelo).
- **Auth**: JWT + refresh token + rôles/permissions.
- **Realtime**: SignalR.
- **Background processing**: service hébergé pour la file de notifications.
- **Observabilité**: Serilog (console/fichier/MySQL selon configuration).

### Pattern applicatif observé
- L'application adopte largement un pattern **service-as-repository**:
  - des interfaces `I*Repository` sont implémentées par des classes `*Service`.
  - les services utilisent directement `ProsocDbContext`.
- Les services sont injectés via DI (`Program.cs`) et consommés par les contrôleurs.

### Couche data
- `Data/ProsocDbContext.cs` centralise les `DbSet<>`, les relations et contraintes.
- Les migrations EF sont présentes dans `Migrations/`.
- Les données initiales/ajustements sont appuyées par des composants comme `SeedData`.

---

## 3) Cartographie des modèles

## 3.1 Entités métier (domaine)

### Adhésion et bénéficiaires
- `Adhesion`
- `Affilie`
- `Dependant`
- `Antecedant`

### Agent, encadrement et objectifs
- `Agent`
- `CategorieAgent`
- `Superviseur` (via DTOs/services dédiés)
- `TargetAgent`
- `CodeAdhesionSequence`

### Collecte, commissions et finances
- `Collecte`
- `TarifCotisation` (anciennement `CotisationAffilie`)
- `Commission`
- `Frais`
- `Transaction`
- `SouscriptionsArrierees`
- `ArrieresAffilie`
- `PenaliteAffilie`

### Produits, prestations et partenaires
- `ProduitMutuel`
- `ProduitAssureur`
- `ProduitBase`
- `Prestation`
- `SouscriptionPrestation`
- `Assureur`

### Flux médicaux / bons / jetons
- `DemandeBonEnvoi`
- `BonEnvoi`
- `JetonMedical`
- `HopitalPartenaire`

### Wallet et retraits agent
- `WalletAgent`
- `WalletVirtuelAgent`
- `WalletMouvement`
- `DemandeRetraitAgent`
- `RetraitAgent`
- `JetonRetrait`

### Référentiels
- `Province`
- `Commune`
- `ZoneSociale`
- `TypeAdhesion`
- `CategorieAdhesion`
- `Devise`
- `TypeCollecte`

### Notifications
- `Notification`
- `NotificationType`
- `UserNotificationPreferences`

## 3.2 Modèles d'authentification / sécurité
- `Utilisateur`
- `Role`
- `Permission`
- `UserRole`
- `RolePermission`
- `UserPermission`
- `RefreshToken`
- `PasswordResetToken`
- `UserDevice`

## 3.3 Modèles mobiles
- `MobileAppConfig`
- `MobileUserSession`
- `MobileSyncData`
- objets de support: états de sync et fonctionnalités mobile.

## 3.4 Pagination et réponses standardisées
- `PaginationRequest`
- `AdvancedPaginationRequest`
- `PaginatedResponse`
- `ExtendedPaginatedResponse`
- `CursorPaginationRequest`
- `CursorPaginatedResult`

## 3.5 DTOs

Les DTOs sont nombreux et bien segmentés:
- `Models/DTOs/Core/*`: DTOs fonctionnels (adhésion, affilié, collecte, dashboards, prestations, notifications, etc.).
- `Models/DTOs/Authentication/*`: login, token, rôles/permissions.
- `Models/DTOs/DashboardAdmin/*`: agrégats statistiques administration.
- DTOs de pagination et réponses API standardisées.

---

## 4) Cartographie des interfaces

Le projet expose un ensemble important d'interfaces, structurées en deux familles:

### 4.1 Interfaces applicatives/transverses
- Auth et identité: `IAuthService`, `ISimpleJwtService`
- Notifications: `INotificationService`, `ICommissionNotificationService`, `INotificationQueueService`, `IEmailService`, `ISmsService`, `IPushNotificationService`
- Mobile/sync: `IMobileAppServiceSimple`, `IUserSynchronizationService`
- Finance: `ICommissionService`, `ITransactionService`, `IFraisService`, `IPaiementAffilieService`, `ICommissionDashboardService`
- Cotisation tarifaire: `ITarifCotisationRepository`, `ITarifCotisationMetierService`  
  (compatibilité legacy maintenue via `ICotisationAffilieRepository` et `ICotisationAffilieMetierService`)
- Helpers: `IPaginationService`, `IMatriculeGeneratorService`, `ICodeAdhesionGeneratorService`, `IGeographicDataService`

### 4.2 Interfaces repository métier
- Famille adhésion/affilié/agent: `IAdhesionRepository`, `IAffilieRepository`, `IAgentRepository`, `IDependantRepository`, `IAntecedentRepository`
- Produits et prestations: `IPrestationRepository`, `IProduitMutuelRepository`, `IProduitAssureurRepository`, `IAssureurRepository`
- Finance: `ICollecteRepository`, `IWalletAgentRepository`, `IRetraitAgentRepository`, `IDemandeRetraitAgentRepository`, `ITargetAgentRepository`
- Cotisation tarifaire: `ITarifCotisationRepository` (legacy `ICotisationAffilieRepository`)
- Référentiels: `IProvinceRepository`, `ICommuneRepository`, `IZoneSocialeRepository`, `IDeviseRepository`, `ITypeAdhesionRepository`, `ICategorieAdhesionRepository`, `ICategorieAgentRepository`
- Auth/RBAC: `IUtilisateurRepository`, `IRoleRepository`, `IPermissionRepository`, `IRefreshTokenRepository`, `IUserDeviceRepository`
- Dashboards: `IDashboardAdminRepository`, `IDashboardAgentRepository`, `IDashboardAffilieRepository`, `IDashboardFinancierRepository`, `IDashboardPercepteurRepository`, `ISuperviseurRepository`

---

## 5) Cartographie des services

## 5.1 Services métier principaux
- `AdhesionService`
- `AffilieService`
- `AgentService`
- `DependantService`
- `AntecedentService`
- `CollecteService`
- `TarifCotisationService` (legacy `CotisationAffilieService`)
- `TarifCotisationMetierService` (legacy `CotisationAffilieMetierService`)
- `CommissionService`
- `PrestationService`
- `ProduitMutuelService`
- `ProduitAssureurService`
- `AssureurService`
- `FraisService`
- `PaiementAffilieService`
- `SouscriptionsArriereesService`
- `TransactionService`

## 5.2 Services wallet/retraits
- `WalletAgentService`
- `RetraitAgentService`
- `DemandeRetraitAgentService`
- `TargetAgentService`

## 5.3 Services auth, sécurité et permissions
- `EnhancedAuthService` (service d'auth principal branché sur `IAuthService`)
- `AuthService` (présence historique/complémentaire selon endpoints)
- `UtilisateurService`
- `RoleService`
- `PermissionService`
- `RefreshTokenService`
- `UserDeviceService`
- `UpdatePermissionsService`

## 5.4 Services notifications
- `NotificationService` (orchestration multi-canaux)
- `CommissionNotificationService`
- `NotificationTypeService`
- `Queue/NotificationQueueService` (queue + retry + hosted service)
- `EmailService`
- `SmsService`
- `PushNotificationService`

## 5.5 Services mobile et synchronisation
- `Mobile/MobileAppServiceSimple`
- `Synchronization/UserSynchronizationService`

## 5.6 Services dashboards
- `DashboardAdminService`
- `DashboardAffilieService`
- `DashboardAgentService`
- `DashboardFinancierService`
- `DashboardPercepteurService`
- `SuperviseurService`

### Observations structurantes
- Les services sont globalement asynchrones.
- L'API couvre des workflows inter-modules riches (adhésion -> collecte -> commission -> notification).
- Certaines responsabilités peuvent être consolidées (naming repository/service, duplication potentielle DI).

---

## 6) Cartographie des contrôleurs

## 6.1 Convention de routage
- Convention majoritaire: `api/[controller]`.
- Existence d'une base versionnée (`api/v{version:apiVersion}/[controller]`) via `BaseApiController`.
- L'usage du versioning n'est pas homogène sur tous les contrôleurs.

## 6.2 Contrôleurs par domaine

### Auth / IAM / permissions
- `AuthController`
- `EnhancedAuthController`
- `UtilisateurController`
- `RoleController`
- `PermissionController`
- `UserDeviceController`
- `UpdatePermissionsController`

### Adhésion / affiliés / dépendants
- `AdhesionController`
- `AffilieController`
- `DependantController`
- `AntecedentController`
- `TypeAdhesionController`
- `CategorieAdhesionController`

### Agents et pilotage
- `AgentController`
- `CategorieAgentController`
- `TargetAgentController`
- `SuperviseurController`
- `AgentCommissionController`

### Finance / collecte / produits
- `CollecteController`
- `TarifCotisationController`
- `ArrieresAffilieController`
- `FraisController`
- `PrestationController`
- `SouscriptionPrestationController`
- `SouscriptionsArriereesController`
- `AssureurController`
- `ProduitMutuelController`
- `ProduitAssureurController`
- `DeviseController`
- `TransactionController`

### Wallet / retraits / bons / jetons
- `WalletAgentController`
- `WalletVirtuelAgentController`
- `WalletMouvementController`
- `RetraitAgentController`
- `DemandeBonEnvoiController`
- `BonEnvoiController`
- `JetonMedicalController`
- `HopitalPartenaireController`

### Notifications / mobile / sync
- `NotificationController`
- `NotificationTypeController`
- `NotificationQueueController`
- `UserNotificationPreferencesController`
- `AgentNotificationPreferencesController`
- `MobileController`
- `SynchronizationController`

### Référentiels géographiques
- `ProvinceController`
- `CommuneController`
- `ZoneSocialeController`

### Dashboards
- `DashboardAdminController`
- `DashboardAffilieController`
- `DashboardAgentController`
- `DashboardFinancierController`
- `DashboardPercepteurController`
- `DashboardSuperviseurController`

## 6.3 Sécurité
- `[Authorize]` est très utilisé.
- Certains endpoints restent publics via `[AllowAnonymous]` pour des cas métier spécifiques.
- Le contrôle d'accès combine rôles et permissions selon les endpoints.

## 6.4 Focus API tarif cotisation (front/QA)

La route de référence est désormais:
- `POST /api/TarifCotisation`
- `GET /api/TarifCotisation`
- `GET /api/TarifCotisation/{id}`
- `PUT /api/TarifCotisation/{id}`
- `DELETE /api/TarifCotisation/{id}`

Endpoints de calcul/lookup utiles pour les parcours métier:
- `GET /api/TarifCotisation/{id}/montant-total?nombreDependants={n}`
  - calcule `montantUnitaire x (1 + nombreDependants)`.
- `GET /api/TarifCotisation/type-adhesion/{typeAdhesionId}`
  - retourne la grille des tarifs par type d'adhésion.
- `GET /api/TarifCotisation/Affilie?idAffilie={id}`
  - retourne les tarifs applicables à l'affilié selon son adhésion active.

Notes d'usage:
- `TarifCotisation` représente un **catalogue tarifaire**; ce n'est pas une transaction de paiement.
- Le paiement réel d'une cotisation passe par `Collecte` (`TypeCollecte = Cotisation`), avec référence au tarif.

Exemples QA (copier-coller):

```http
POST /api/TarifCotisation
Authorization: Bearer {token}
Content-Type: application/json

{
  "montant": 5.0,
  "periodicite": "Mensuel",
  "typeAdhesionId": 1,
  "statut": true
}
```

```json
{
  "id": 12,
  "montant": 5.0,
  "periodicite": "Mensuel",
  "typeAdhesionId": 1,
  "typeAdhesionLibelle": "F3",
  "statut": true,
  "dateCreation": "2026-05-28T09:00:00Z",
  "dateModification": null
}
```

```http
GET /api/TarifCotisation/12/montant-total?nombreDependants=3
Authorization: Bearer {token}
```

```json
{
  "cotisationAffilieId": 12,
  "typeAdhesionId": 1,
  "typeAdhesionLibelle": "F3",
  "periodicite": "Mensuel",
  "montantUnitaire": 5.0,
  "nombreDependants": 3,
  "nombrePersonnes": 4,
  "montantTotal": 20.0
}
```

```http
POST /api/Collecte
Authorization: Bearer {token}
Content-Type: application/json

{
  "typeCollecte": "Cotisation",
  "affilieId": 3,
  "agentId": 1,
  "cotisationAffilieId": 12,
  "montant": 20.0,
  "mois": 5,
  "annee": 2026,
  "modePaiement": "MOBILE_MONEY",
  "statutPaiement": "PAYE",
  "deviseId": 1,
  "statut": true
}
```

```http
GET /api/TarifCotisation/type-adhesion/1
Authorization: Bearer {token}
```

```json
[
  {
    "id": 12,
    "montant": 5.0,
    "periodicite": "Mensuel",
    "typeAdhesionId": 1,
    "typeAdhesionLibelle": "F3",
    "statut": true,
    "dateCreation": "2026-05-28T09:00:00Z",
    "dateModification": null
  },
  {
    "id": 13,
    "montant": 50.0,
    "periodicite": "Annuel",
    "typeAdhesionId": 1,
    "typeAdhesionLibelle": "F3",
    "statut": true,
    "dateCreation": "2026-05-28T09:05:00Z",
    "dateModification": null
  }
]
```

```http
GET /api/TarifCotisation/Affilie?idAffilie=3
Authorization: Bearer {token}
```

```json
[
  {
    "id": 12,
    "montant": 5.0,
    "periodicite": "Mensuel",
    "typeAdhesionId": 1,
    "typeAdhesionLibelle": "F3",
    "statut": true,
    "dateCreation": "2026-05-28T09:00:00Z",
    "dateModification": null
  }
]
```

---

## 7) Analyse des fichiers Markdown existants

Le projet contient un volume important de docs (`.md`) réparties entre:
- documentation API,
- guides d'auth/permissions,
- instructions de déploiement/migration,
- rapports et plans de tests,
- docs techniques ciblées sur certains workflows.

### Points forts
- Documentation abondante.
- Forte orientation opérationnelle (tests/procédures/instructions).
- Présence de docs spécialisées par module.

### Limites observées
- Redondance de documents API.
- Risque d'obsolescence sur certaines pages.
- Références hétérogènes selon les contextes et périodes.
- Absence d'un index documentaire unique et stable.

### Recommandation documentaire
- Conserver les docs historiques mais établir **une source de vérité unique**.
- Ajouter un index global avec statut de fraîcheur par document.
- Harmoniser vocabulaire, routes et exemples payload.

---

## 8) Flux métiers clés (vue synthétique)

## 8.1 Authentification
1. Login utilisateur.
2. Emission JWT + refresh token.
3. Contrôle d'accès sur rôles/permissions.
4. Renouvellement / révocation des tokens.

## 8.2 Adhésion
1. Création adhésion (avec ou sans affilié selon cas).
2. Validation des règles métier.
3. Génération des identifiants métier.
4. Notifications et suivi.

## 8.3 Collecte et commission
1. Saisie/validation d'une collecte.
2. Calcul et traçabilité des commissions (taux dynamique par frais/produit).
3. Impact dashboard financier/agent.
4. Notification des parties prenantes.

## 8.4 Wallet et retrait agent
1. Suivi solde wallet.
2. Soumission d'une demande de retrait.
3. Validation / exécution.
4. Historisation des mouvements.

## 8.5 Notifications
1. Création événement notification.
2. Passage en queue si asynchrone.
3. Dispatch email/sms/push/in-app.
4. SignalR pour temps réel.

---

## 9) Data, migrations et qualité

### Base de données
- Schéma géré par EF Core.
- Relations et contraintes centralisées via `ProsocDbContext`.

### Migrations
- Présence de migration initiale puis ajustements ciblés.
- Recommandé: gouvernance stricte des migrations par environnement.
- Migration récente de renommage métier:
  - `20260528082741_RenameCotisationAffilieToTarifCotisation`
  - opérations: renommage table `CotisationsAffilie` -> `TarifsCotisation`, colonnes FK `CotisationAffilieId` -> `TarifCotisationId`, index/FK associés.

### Tests
- Présence de tests unitaires et d'intégration.
- Les scénarios critiques sont partiellement couverts.
- Recommandé: matrice de couverture par module pour combler les angles morts.

---

## 10) Forces et dettes techniques

## 10.1 Forces
- Couverture métier large et utile.
- Modularité claire côté services et contrôleurs.
- Auth avancée (JWT + refresh + permissions).
- Infrastructure de notification complète (temps réel + queue).
- Présence de tests et documentation opérationnelle.

## 10.2 Dettes et risques
- Standardisation incomplète du versioning d'API.
- Ambiguïté de naming entre repository/service.
- Possibles duplications d'enregistrements DI.
- File de notifications en mémoire (résilience limitée en cas de redémarrage).
- Hétérogénéité documentaire.
- Vigilance forte requise sur la gestion des secrets et paramètres sensibles.

---

## 11) Plan de consolidation recommandé (avant changements workflow)

1. **Stabiliser la documentation unique**
   - garder ce document comme référence principale.
   - ajouter un changelog des évolutions workflow.
2. **Normaliser les conventions API**
   - uniformiser versioning, format d'erreur, pagination, sécurité.
3. **Clarifier architecture services/repositories**
   - définir explicitement le pattern cible.
4. **Renforcer résilience des traitements asynchrones**
   - évaluer queue persistante selon criticité métier.
5. **Mettre en place une matrice de couverture tests**
   - modules x scénarios x niveau de test.
6. **Nettoyer/archiver les docs historiques**
   - tagger les documents actifs vs obsolètes.

---

## 12) Référence de départ pour les changements majeurs

Ce document sert de base de cadrage pour les changements workflow à venir.  
Lors des prochains ajustements, la recommandation est de tracer systématiquement:
- les impacts par module (`Models`, `Interfaces`, `Services`, `Controllers`);
- les impacts data (migrations/contrainte/intégrité);
- les impacts sécurité (rôles/permissions/endpoints publics);
- les impacts documentaires et tests.

