# Intégration des prestations médicales — Vue et Flutter

Contrat vérifié dans les contrôleurs et DTO du dépôt le 28 octobre 2026. Ce guide décrit les lots 1 à 4 livrés côté API. Il complète [le suivi technique du module](./ModuleMedical.md). Les identifiants, prix, dates et taux des exemples sont fictifs ; les identifiants doivent venir des réponses de l'environnement cible.

## 1. Préparer l'intégration

Pour la mise à niveau de la base, le backend dispose du [script SQL consolidé](../sql/AppliquerModuleMedical.idempotent.sql) et de sa [procédure d'exécution](../sql/AppliquerModuleMedical.README.md). Son application relève de l'équipe backend/exploitation avant la recette frontend.

Créer une rubrique « Prestations médicales » distincte du parcours générique des prestations. Les nouvelles offres ne sont pas des `Prestation` : ne pas envoyer leurs identifiants aux endpoints génériques Collecte, SouscriptionPrestation, DemandeBonEnvoi ou BonEnvoi.

Configurer l'URL de base par environnement, avec un hôte joignable depuis les appareils mobiles. Les chemins ci-dessous partent de cette URL. Envoyer `Authorization: Bearer <JWT>` et, pour les corps JSON, `Content-Type: application/json`. Réutiliser l'authentification et le renouvellement de session existants.

Les réponses médicales sont des objets ou tableaux JSON directs, sans enveloppe `data`/`success`. Les propriétés sont en camelCase. Une réponse 204 n'a pas de corps. Les listes paginées acceptent `page=1&pageSize=20`, taille limitée à 100, et retournent un tableau sans total : poursuivre jusqu'à une page plus courte que la taille demandée. Cela concerne les offres, périodes et prises en charge ; les référentiels, versions et souscriptions par affilié ne sont pas paginés.

Les dates sont ISO 8601 UTC. Le mois est calculé par le serveur dans le fuseau métier, `Africa/Kinshasa` par défaut. La fin de couverture est exclusive. Ne pas recréer les droits à partir de l'heure du téléphone : afficher `droitsOuverts` retourné par l'API et rafraîchir avant une action.

Les montants sont des nombres JSON, à deux décimales maximum ; ne pas envoyer de virgule décimale ni de séparateur de milliers. Le serveur calcule conversion, solde et commission. Les IDs métier sont des entiers ; les identifiants de paiement sont des GUID sous forme de chaîne.

Avant recette, le backend doit confirmer l'application des quatre migrations médicales et la configuration des paiements. Elles ont été préparées, mais pas appliquées pendant le développement décrit ici. Ne pas démarrer une API contre une base partagée pour obtenir un Swagger : son démarrage applique automatiquement les migrations.

L'OpenAPI configuré est `/swagger/v1/swagger.json` lorsqu'il est exposé sur l'environnement autorisé. Conserver sa version avec l'intégration et comparer les schémas avant livraison. Ce guide a été vérifié statiquement dans le code ; il ne constitue pas un export OpenAPI d'un serveur déployé.

## 2. Règles à traduire dans les écrans

- La catégorie d'hôpital est descriptive. Deux hôpitaux de même catégorie peuvent proposer des prix différents.
- Une offre concerne une catégorie de soins et énumère les soins effectivement couverts. Afficher cette liste avant acceptation.
- Un affilié reste rattaché à un seul hôpital. Plusieurs offres du même hôpital sont possibles. Aucun changement d'hôpital n'est exposé.
- Une nouvelle souscription médicale exige que la cotisation courante soit entièrement réglée. Des versements de cotisation partiels peuvent être cumulés, mais ne satisfont pas cette règle avant paiement du total dû.
- Souscrire ne signifie pas être couvert. Chaque mois doit être préparé puis intégralement payé pour ouvrir les droits.
- Le prix mensuel complet est dû même pour un paiement en fin de mois, sans prorata ni condition de trois collectes.
- Les versements partiels sont autorisés, mais n'ouvrent pas les droits. Les mois futurs sont payables ; leurs droits commencent au début de leur mois.
- Chaque paiement concerne une seule période. Pour plusieurs mois, préparer et régler chaque période séparément ; aucune répartition automatique n'existe.
- Les soins inclus sont accessibles sans quota pendant la couverture. Chaque bon et jeton est à usage unique ; une nouvelle demande du même soin reste possible.
- Un retrait commercial d'offre ne supprime pas les droits payés. Une désactivation de l'affilié, de la souscription ou de l'hôpital peut toutefois empêcher l'accès.

## 3. Catalogue et administration des offres

### Lecture, accessible aux utilisateurs authentifiés

```http
GET /api/CatalogueMedical/referentiels/categories-hopitaux
GET /api/CatalogueMedical/referentiels/categories-soins
GET /api/CatalogueMedical/referentiels/soins
GET /api/CatalogueMedical/referentiels/{type}/{id}
GET /api/CatalogueMedical/offres?hopitalId=4&page=1&pageSize=20
GET /api/CatalogueMedical/offres/12
GET /api/CatalogueMedical/offres/12/versions
```

`hopitalId` est facultatif. Le compte hospitalier est automatiquement limité à son hôpital. Les offres retournées peuvent être retirées : utiliser `statut` pour distinguer le catalogue commercial des historiques ; ne pas supposer que la liste ne contient que les offres actives.

Un référentiel retourne `{ "id": 2, "nom": "Consultation", "description": null, "statut": true }`. Les trois types autorisés sont exactement ceux des chemins ci-dessus. Les soins sont un référentiel indépendant ; la couverture effective est `version.soins`.

Exemple d'offre (`GET offres/12`, 200 ; même forme dans les listes) :

```json
{
  "id": 12,
  "nom": "Soins ambulatoires",
  "hopitalPartenaireId": 4,
  "hopitalNom": "Hôpital exemple",
  "categorieHopitalId": 2,
  "categorieHopitalNom": "Catégorie exemple",
  "categorieSoinId": 3,
  "categorieSoinNom": "Ambulatoire",
  "statut": true,
  "periodicite": "Mensuel",
  "version": {
    "id": 25,
    "montantMensuel": 20,
    "deviseId": 1,
    "deviseCode": "USD",
    "datePublicationUtc": "2026-10-28T10:00:00Z",
    "soins": [{ "soinId": 7, "nom": "Consultation générale", "description": null }],
    "tauxCommissionAT": 20,
    "tauxCommissionAA": 10,
    "tauxCommissionAAMash": 5,
    "tauxCommissionAAStructure": 3
  }
}
```

`categorieHopitalId` et `categorieHopitalNom` sont nullable pour les établissements historiques. `description` des soins est nullable. Une offre publiée utilise une classification et des référentiels actifs.

### Gestion par le personnel habilité

```http
POST /api/CatalogueMedical/referentiels/{type}
PUT /api/CatalogueMedical/referentiels/{type}/{id}
```

Corps : `{ "nom": "Catégorie exemple", "description": null, "statut": true }`. Nom de 1 à 200 caractères, description de 1 000 maximum ; création 201, modification 200.

```http
PUT /api/CatalogueMedical/hopitaux/4/categorie
```

Corps : `{ "categorieHopitalId": 2 }` ; réponse 204. La création/consultation des hôpitaux et devises reste dans les modules existants : ce catalogue ne fournit pas de nouvel annuaire d'hôpitaux.

```http
POST /api/CatalogueMedical/offres
```

```json
{
  "hopitalPartenaireId": 4,
  "categorieSoinId": 3,
  "nom": "Soins ambulatoires",
  "version": {
    "montantMensuel": 20,
    "deviseId": 1,
    "soinIds": [7, 8],
    "tauxCommissionAT": 20,
    "tauxCommissionAA": 10,
    "tauxCommissionAAMash": 5,
    "tauxCommissionAAStructure": 3
  }
}
```

Réponse 201 : offre complète. Une offre existe par couple hôpital–catégorie de soins ; un doublon retourne 409. Nom : 200 caractères maximum. Montant strictement positif, deux décimales maximum ; de 1 à 500 identifiants de soins dans la requête. Chaque taux va de 0 à 100 avec deux décimales maximum. Les exemples de taux ne fixent aucune politique métier.

```http
POST /api/CatalogueMedical/offres/12/versions
PUT /api/CatalogueMedical/offres/12/statut
```

Pour publier, envoyer uniquement l'objet `version` de l'exemple précédent : réponse 201, objet version. Pour le statut, envoyer `{ "statut": false }` : réponse 204. Une version publiée est immuable ; aucun PUT/DELETE de version n'existe. Un nouveau tarif ou une nouvelle liste de soins implique une nouvelle publication.

Création/publication : `CREATE_PRODUIT_MUTUEL` **ou** `CREATE_PRODUIT_ASSUREUR`. Modification/classification/statut : `UPDATE_PRODUIT_MUTUEL` **ou** `UPDATE_PRODUIT_ASSUREUR`. Le périmètre hospitalier reste appliqué. Admin/SuperAdmin ont le bypass de permissions existant ; les contrôles de périmètre restent côté serveur.

## 4. Souscrire et préparer le mois

```http
POST /api/SouscriptionMedicale
```

Corps : `{ "affilieId": 31, "offreMedicaleHopitalId": 12 }`.

Réponse 201 :

```json
{
  "id": 40,
  "affilieId": 31,
  "hopitalPartenaireId": 4,
  "offreMedicaleHopitalId": 12,
  "statut": true,
  "dateSouscriptionUtc": "2026-10-28T10:30:00Z"
}
```

```http
GET /api/SouscriptionMedicale/40
GET /api/SouscriptionMedicale/by-affilie/31
POST /api/SouscriptionMedicale/40/periodes
```

Préparation : `{ "annee": 2026, "mois": 10, "versionOffreMedicaleId": 25 }`. Année 2020–2100, mois 1–12, mois courant ou futur uniquement. Afficher le tarif et les soins de la dernière version puis envoyer son ID accepté. Si elle a changé, recharger l'offre et demander une nouvelle acceptation ; ne pas remplacer silencieusement l'ID accepté. Une période déjà préparée conserve sa version et son prix ; sa préparation répétée est idempotente.

Réponse 201 à la préparation, 200 à la consultation :

```json
{
  "id": 62,
  "souscriptionMedicaleId": 40,
  "versionOffreMedicaleId": 25,
  "annee": 2026,
  "mois": 10,
  "montantDu": 20,
  "montantValide": 8,
  "soldeRestant": 12,
  "deviseId": 1,
  "dateDebutDroitsUtc": null,
  "dateFinExclusiveUtc": "2026-10-31T23:00:00Z",
  "droitsOuverts": false
}
```

```http
GET /api/SouscriptionMedicale/40/periodes?page=1&pageSize=20
GET /api/SouscriptionMedicale/periodes/62
```

Pour afficher les soins d'une période, charger les versions de son offre et sélectionner celle dont `id == versionOffreMedicaleId`. Ne pas remplacer par `offre.version`, qui représente le tarif courant. Garder séparément les IDs d'offre, de version, de souscription et de période.

Membre : `READ_SOUSCRIPTION_PRESTATION` et dossier propre pour lire, souscrire et préparer. Personnel : `CREATE_COLLECTE` pour souscrire/préparer, `READ_SOUSCRIPTION_PRESTATION` pour consulter. Les agents hospitaliers n'accèdent pas à ces endpoints financiers.

États d'affichage proposés, dérivés des réponses : « À payer » si montant validé nul, « Paiement partiel » si solde positif après versement, « Payé — à venir » si soldé mais droits futurs, « Couvert » si `droitsOuverts`, « Expiré » après la fin. Un solde nul seul ne prouve pas une couverture active ; garder un état « Droits indisponibles » si la réponse ne permet pas d'affirmer la cause.

## 5. Paiements partiels, complets et anticipés

### Encaissement par opérateur

```http
POST /api/PaiementMedical
```

```json
{
  "idPaiement": "d1c13f65-b77a-4cc2-9233-fbe5f47bd843",
  "periodeCouvertureMedicaleId": 62,
  "montant": 8,
  "deviseId": 1,
  "modePaiement": "ESPECE"
}
```

Réponse 201 :

```json
{
  "idPaiement": "d1c13f65-b77a-4cc2-9233-fbe5f47bd843",
  "collecteId": 150,
  "periodeCouvertureMedicaleId": 62,
  "montant": 8,
  "deviseId": 1,
  "montantCredite": 8,
  "deviseTarifId": 1
}
```

`montant` est dans la devise de paiement ; `montantCredite` dans celle du tarif. Le plafond est le solde après conversion serveur. Maximum du DTO : 999999999.99, minimum 0.01, deux décimales maximum côté métier. Modes synchrones : `ESPECE`, `CHEQUE`, `VIREMENT_BANCAIRE`, `VIRTUAL_ACCOUNT`. Ils exigent `CREATE_COLLECTE`, ne sont jamais déclarables par un membre ; espèces avec caisse ouverte et autorisée, wallet avec rôle autorisé et agent connecté. Chèque/virement : l'opérateur doit avoir confirmé la réception des fonds avant saisie.

Générer un GUID par versement au guichet et le conserver jusqu'au résultat définitif. Après timeout, consulter puis reprendre avec **le même GUID et le même corps** : pas de nouveau débit ni commission dupliquée. Un GUID réutilisé avec un autre contenu retourne 409. Pour un nouveau versement partiel, générer un nouveau GUID. Ne jamais produire un GUID différent à chaque tentative réseau.

```http
GET /api/PaiementMedical/{idPaiement}
```

Réponse 200 de même forme. Un membre autorisé consulte ses propres paiements ; le personnel utilise `CREATE_COLLECTE`. L'API n'expose pas ici de liste paginée de paiements médicaux.

### Paiement électronique par membre ou opérateur

Même POST, corps :

```json
{
  "periodeCouvertureMedicaleId": 62,
  "montant": 12,
  "deviseId": 1,
  "modePaiement": "MOBILE_MONEY",
  "telephonePaiement": "<numéro saisi par le payeur>"
}
```

Modes : `MOBILE_MONEY`, `CARTE_BANCAIRE`, `CARTE_BANCAIRE_MOKO`, selon configuration active. Téléphone nullable dans le DTO, 20 caractères maximum, à collecter selon le canal utilisé. Membre : permission `READ_SOUSCRIPTION_PRESTATION`, propre dossier uniquement ; personnel : `CREATE_COLLECTE`. Agent hospitalier refusé.

Réponse **200 d'initiation**, distincte du 201 d'encaissement :

```json
{
  "idCollecteEnAttente": "0c8daa21-ab60-45b7-b7d2-13b416730110",
  "orderNumberFlexPay": "EXEMPLE-ORDRE",
  "referenceFlexPay": "EXEMPLE-REFERENCE",
  "montantTarif": 12,
  "codeDeviseTarif": "USD",
  "montantFlexPay": 12,
  "codeDevisePaiement": "USD",
  "tauxApplique": null,
  "holdExpireAt": "2026-10-28T11:00:00Z",
  "paymentUrl": null,
  "flexPayAccepted": true,
  "message": "Exemple d'initiation acceptée",
  "paymentGateway": null,
  "providerEffectif": "FlexPay"
}
```

`orderNumberFlexPay`, `paymentUrl`, `tauxApplique`, `paymentGateway` et `providerEffectif` sont nullable. `paymentGateway` reprend le contrat de configuration existant du login ; `providerEffectif` indique le prestataire réellement utilisé (`FlexPay` ou `MokoAfrika`). Les noms historiques FlexPay restent utilisés même si le routage effectif change. Les montants/frais affichés doivent venir de la réponse serveur et de l'intégration de paiement existante.

1. Conserver `idCollecteEnAttente`, numéro d'ordre, prestataire et période. Désactiver la double soumission pendant l'initiation.
2. Si une `paymentUrl` est fournie, ouvrir le parcours hébergé avec les mécanismes existants ; sinon afficher les instructions du canal. Un retour de navigateur ou deep link n'est pas une preuve de paiement.
3. Après confirmation serveur, le GUID `idCollecteEnAttente` devient l'`idPaiement`. Recharger le paiement puis la période pour afficher le montant crédité et les droits.
4. Un 404 de `GET PaiementMedical/{idCollecteEnAttente}` avant finalisation signifie seulement qu'aucun encaissement final n'est consultable : il ne permet pas de conclure à un refus. Il n'existe pas de GET médical du statut d'une attente.
5. Pour le circuit FlexPay existant, `GET /api/FlexPay/verifier/{orderNumber}` renvoie directement `success`, `alreadyProcessed`, `pending`, `message`, `idCollecte`, `idAdhesion`, `idCollecteEnAttente`. Respecter `pending` et recharger les données médicales après succès. Réutiliser le suivi existant adapté au prestataire effectif ; ne pas supposer que ce secours FlexPay convient à tous les paiements Moko.

Le GUID client de guichet n'est **pas** une clé d'idempotence de l'initiation électronique : cette branche génère son attente côté serveur. Après une réponse réseau perdue, ne pas relancer automatiquement une nouvelle initiation ; reprendre le suivi disponible ou proposer une vérification opérateur. Ne jamais appeler un callback prestataire depuis le frontend pour déclarer le succès.

Un paiement confirmé tardivement, après expiration du mois ou après règlement concurrent, peut nécessiter une régularisation financière. Afficher « À vérifier » et orienter vers le support, sans promettre de nouveaux droits ni de remboursement automatique. Annulations/remboursements médicaux non exposés.

## 6. Demandes, bons d'envoi et jetons

### Créer et consulter

```http
POST /api/PriseEnChargeMedicale
```

Corps : `{ "periodeCouvertureMedicaleId": 62, "soinId": 7, "motif": "Consultation demandée" }`. Motif nullable, 500 caractères maximum. Exige `CREATE_DEMANDE_BON_ENVOI`, un dossier autorisé, des droits ouverts et un soin inclus dans la version payée. Un agent hospitalier ne crée pas de demande dans ce parcours.

```http
GET /api/PriseEnChargeMedicale/{id}
GET /api/PriseEnChargeMedicale/by-periode/62?page=1&pageSize=20
```

Création 201, consultations 200. Le membre consulte son propre dossier avec `READ_DEMANDE_BON_ENVOI`. Le personnel utilise cette permission ; un compte hospitalier consulte uniquement les prises en charge confirmées de son établissement.

### File des demandes médicales à confirmer

Pour le tableau de travail des agents habilités, utiliser la route dédiée suivante :

```http
GET /api/PriseEnChargeMedicale/en-attente?page=1&pageSize=20
```

Elle retourne les prises en charge médicales `EN_ATTENTE`, tous affiliés confondus, sous forme d'un tableau JSON direct (sans enveloppe ni total). `page` commence à 1 ; `pageSize` est limité à 100. Charger les pages suivantes jusqu'à obtenir une page plus courte que la taille demandée. Permission requise : `READ_DEMANDE_BON_ENVOI`. Les comptes affiliés et agents d'hôpital sont refusés ; l'agent d'hôpital ne voit que les demandes déjà confirmées via le parcours par période.

Exemple de ligne en attente :

```json
{
  "id": 90,
  "periodeCouvertureMedicaleId": 62,
  "affilieId": 31,
  "hopitalPartenaireId": 4,
  "soinId": 7,
  "soinNom": "Consultation générale",
  "statut": "EN_ATTENTE",
  "motif": "Consultation demandée",
  "dateDemandeUtc": "2026-10-28T12:00:00Z",
  "agentId": null,
  "numeroBon": null,
  "jetonMedicalId": null,
  "codeJeton": null,
  "qrCodePayload": null,
  "qrCodeImageBase64": null,
  "dateExpirationUtc": null,
  "estUtilise": false,
  "observation": null,
  "dateConfirmationUtc": null
}
```

Une demande se confirme ou se rejette avec `POST /api/PriseEnChargeMedicale/{id}/confirmer` et la permission `CONFIRM_DEMANDE_BON_ENVOI`. Après succès, retirer la ligne de la file en attente puis rafraîchir les listes pertinentes. En cas de timeout, relire la demande par son ID avant de réessayer.

La route historique `GET /api/DemandeBonEnvoi/en-attente` continue de lister les demandes de bon classiques stockées dans `DemandesBonEnvoi` ; elle ne retourne pas les prises en charge médicales de cette nouvelle file. Les deux contrats et leurs modèles frontend restent distincts. Pour les demandes classiques, conserver les routes `DemandeBonEnvoi` et leur DTO existant.

### Confirmer ou rejeter

```http
POST /api/PriseEnChargeMedicale/90/confirmer
```

Corps : `{ "agentId": 6, "accepter": true, "observation": null }`. `agentId` entier positif requis par validation du DTO, même si le serveur privilégie l'agent connecté. Sans agent connecté résolu, cet ID doit désigner un agent actif. Observation nullable, 500 caractères maximum. Pour rejeter : `accepter: false`. Permission `CONFIRM_DEMANDE_BON_ENVOI`, membre interdit, périmètre de consultation également requis.

Forme commune de réponse, exemple après confirmation (200) :

```json
{
  "id": 90,
  "periodeCouvertureMedicaleId": 62,
  "affilieId": 31,
  "hopitalPartenaireId": 4,
  "soinId": 7,
  "soinNom": "Consultation générale",
  "statut": "VALIDEE",
  "motif": "Consultation demandée",
  "dateDemandeUtc": "2026-10-28T12:00:00Z",
  "agentId": 6,
  "numeroBon": "BM-exemple",
  "jetonMedicalId": 100,
  "codeJeton": "JMEXEMPLE",
  "qrCodePayload": "<chaîne signée retournée par le serveur>",
  "qrCodeImageBase64": "<PNG encodé en base64 sans préfixe data URI>",
  "dateExpirationUtc": "2026-10-31T23:00:00Z",
  "estUtilise": false,
  "observation": null,
  "dateConfirmationUtc": "2026-10-28T12:05:00Z"
}
```

Statuts : `EN_ATTENTE`, `VALIDEE`, `REJETEE`. À la création, les informations d'agent, de bon, de jeton, de QR, d'expiration et de confirmation peuvent être nulles. `motif` et `observation` sont également nullable. `estUtilise` est indépendant du statut : après consommation, le statut peut rester `VALIDEE`. Ne pas inventer un statut serveur `UTILISE` ou `EXPIRE` ; les badges peuvent être dérivés sans modifier le modèle.

La confirmation revalide les droits et génère bon, QR et jeton. Une confirmation déjà validée ne crée pas de second jeton. La durée est limitée par la configuration métier et la fin de couverture. `id` désigne la prise en charge, pas une ligne de la table historique BonsEnvoi ; conserver ce type de ressource dans la navigation.

### Scanner et utiliser

```http
POST /api/PriseEnChargeMedicale/scanner
```

Corps : `{ "qrCodePayload": "<contenu exact lu par la caméra>", "marquerUtilise": false }`. Permission `SCAN_BON_ENVOI` et périmètre de consultation. Réponse 200 : prise en charge vérifiée. Envoyer la chaîne signée telle quelle, sans la reconstruire, ni considérer son contenu décodé comme une autorisation.

Pour consommer, envoyer `marquerUtilise: true` ou appeler :

```http
POST /api/PriseEnChargeMedicale/90/utiliser
```

Ce dernier POST n'a pas de corps. Consommation : `USE_JETON_MEDICAL`, membre interdit, périmètre autorisé ; le scan avec consommation exige également `SCAN_BON_ENVOI`. Réponse 200 avec `estUtilise: true`. Bon et jeton sont consommés ensemble. Mauvais hôpital, expiration, droits fermés ou usage antérieur sont refusés.

Afficher d'abord les informations vérifiées puis demander l'action explicite de consommation dans l'interface. Après timeout de consommation, relire la prise en charge avant toute répétition : la consommation n'est pas un POST rejouable indéfiniment. Ne jamais utiliser le endpoint historique de consommation de JetonMedical pour ces bons.

Pour afficher le QR : Vue utilise `data:image/png;base64,` suivi de `qrCodeImageBase64` ; Flutter décode le base64 puis affiche les octets PNG. Ne pas ajouter ce préfixe au payload envoyé au scanner. Ne pas journaliser QR, jetons, motifs ou numéros de téléphone ; éviter leur conservation en cache persistant/offline.

## 7. Commissions automatiques

L'administration configure les quatre taux lors de chaque publication. Le moteur serveur utilise le rôle de l'agent gestionnaire de l'adhésion, les taux de la version figée et chaque versement réellement encaissé, y compris partiel. Le wallet de commission et la notification suivent la logique non médicale. La répétition d'un encaissement ne doit pas créer une deuxième commission.

Les clients n'envoient aucun bénéficiaire ni montant de commission au paiement. Aucun nouvel endpoint médical de calcul ou paiement de commission n'est requis dans l'interface. Réutiliser les écrans de commission existants selon leurs contrats. Les anciennes versions médicales ont des taux initiaux à zéro ; pas de recalcul rétroactif. Présenter les taux dans l'administration, sans les confondre avec le prix payé par l'affilié.

## 8. Erreurs et reprise

Les erreurs métier des quatre contrôleurs utilisent `application/problem+json`, par exemple :

```json
{ "type": "about:blank", "title": "Permission ou périmètre insuffisant.", "status": 403 }
```

`type` peut varier ; `detail`, `instance`, `traceId` et autres extensions sont facultatifs. Les erreurs de validation peuvent ajouter `errors`, dictionnaire de champs vers listes de messages. Ne pas lier le comportement métier au texte français de `title` : aucun catalogue stable de codes médicaux n'est exposé.

- **400** : données invalides, soin non couvert, QR invalide/expiré, bon déjà utilisé selon l'opération. Afficher le message et corriger/rafraîchir.
- **401** : session absente/expirée. Suivre le renouvellement existant ; ne pas présumer qu'un corps ProblemDetails est présent.
- **403** : permission ou périmètre insuffisant. Masquer les actions non autorisées et afficher l'interdiction ; ne pas changer d'affilié/hôpital pour contourner.
- **404** : ressource introuvable ou encaissement non finalisé dans le cas électronique expliqué plus haut.
- **409** : conflit métier, version devenue obsolète, autre hôpital, collision d'idempotence, concurrence ou canal indisponible. Recharger l'état ; ne pas relancer aveuglément une mutation.
- **5xx / coupure réseau** : état possiblement inconnu. Relire les ressources ; pour le guichet garder le GUID. Le suivi FlexPay historique peut retourner un objet `message` plutôt que ProblemDetails : garder un parseur de secours.

La création de souscription ou de demande ne fournit pas de clé d'idempotence client. Désactiver le bouton pendant l'appel ; après réponse perdue, consulter les listes avant de proposer une nouvelle création. Ne pas mettre les mutations financières ou la consommation de bons dans une file automatique offline.

## 9. Organisation recommandée pour Vue et Flutter

### Vue 3 / TypeScript

Créer des types DTO distincts et un service médical utilisant le client HTTP authentifié existant. Garder les appels réseau hors composants. Séparer catalogue courant, historique des versions, souscriptions, périodes et prises en charge ; indexer les caches par ID de ressource et utilisateur. Ne pas mélanger `PriseEnChargeMedicale` avec le type BonEnvoi historique.

Modéliser le résultat du POST paiement par deux méthodes de service ou une union discriminée locale selon le mode choisi : `PaiementMedicalReadDto` pour le guichet, `InitiateFlexPayResponseDto` pour l'électronique. Ne pas lire `collecteId` dans une réponse d'initiation. Après mutation, invalider/recharger les caches concernés, en particulier période et solde ; ne pas incrémenter optimistement les droits.

### Flutter / Riverpod

Créer des DTO Dart et un repository médical autour du transport authentifié existant. Décoder les nombres JSON via `num` plutôt que supposer `double` pour tous les montants ; les exemples peuvent contenir des entiers. Parser les dates UTC avec `DateTime.parse`, conserver les bornes serveur et formater pour l'utilisateur sans redéfinir le mois métier.

Exposer les lectures via les providers existants et invalider période/prise en charge après action. Séparer les résultats d'initiation et d'encaissement dans les modèles applicatifs. À la reprise de l'application ou au retour du paiement hébergé, rafraîchir le serveur ; ne pas réutiliser un ancien `droitsOuverts`. Conserver le contexte d'une tentative financière dans le stockage sécurisé déjà utilisé par le projet, sans y enregistrer QR ni données de soins en clair.

Ces recommandations n'imposent aucune dépendance nouvelle. Aucun client généré ou changement Vue/Flutter n'est inclus dans ce guide.

## 10. Recette commune web et mobile

- Parcours membre : catalogue, soins inclus, souscription, préparation du mois courant, paiement partiel puis solde ; aucun droit avant solde.
- Paiement en fin de mois au prix complet ; mois futur soldé sans droits immédiats ; expiration à la borne exclusive.
- Offre republiée : acceptation explicite de la nouvelle version pour une nouvelle période ; prix et soins anciens conservés pour une période déjà préparée.
- Refus de deuxième hôpital ; plusieurs offres du même hôpital autorisées.
- Timeout guichet et répétition avec même GUID : une collecte et une commission ; GUID réutilisé avec contenu différent refusé.
- Électronique en attente/échec/succès, retour navigateur sans callback, retour application mobile, double clic et réponse réseau perdue ; aucun succès affiché sur la seule initiation.
- Demande d'un soin couvert puis confirmation/rejet ; refus de soin hors version, droits expirés ou période partielle.
- QR PNG web/mobile, scan dans le bon hôpital, refus dans un autre, consommation puis refus de réutilisation ; nouvelle demande du même soin permise.
- Couverture désactivée après émission du QR : utilisation refusée ; deux opérateurs concurrents ne consomment pas deux fois le bon.
- Vérifier les profils membre/personnel/hôpital, les permissions manquantes, les réponses nullables, les pages vides et les erreurs de validation.
- Vérifier les quatre taux de commission avec l'équipe backend ; aucun calcul local faisant foi.

Les 111 tests unitaires ciblés et 10 tests HTTP du backend ont réussi avant la rédaction de ce guide. Ils ne remplacent pas cette recette Vue/Flutter, les tests sur MySQL/MariaDB réel ou ceux des prestataires : ces contrôles n'ont pas été exécutés pour cette documentation. Les écrans existants de statistiques/historique et la reprise des anciennes prestations médicales ne sont pas automatiquement adaptés au nouveau circuit.

## Références de contrat

- [Contrôleur catalogue](../Controllers/CatalogueMedicalController.cs) et [DTO catalogue](../Models/DTOs/Core/CatalogueMedicalDtos.cs).
- [Contrôleur souscriptions](../Controllers/SouscriptionMedicaleController.cs) et [DTO souscriptions/périodes](../Models/DTOs/Core/SouscriptionMedicaleDtos.cs).
- [Contrôleur paiements](../Controllers/PaiementMedicalController.cs), [DTO médicaux](../Models/DTOs/Core/PaiementMedicalDtos.cs) et [DTO d'initiation électronique](../Models/DTOs/FlexPay/FlexPayDtos.cs).
- [Contrôleur prises en charge](../Controllers/PriseEnChargeMedicaleController.cs), [DTO prises en charge](../Models/DTOs/Core/PriseEnChargeMedicaleDtos.cs) et [DTO scanner](../Models/DTOs/Core/BonEnvoiDtos.cs).
- Requêtes manuelles : [catalogue](../test-catalogue-medical.http), [souscriptions](../test-souscription-medicale.http), [paiements](../test-paiement-medical.http), [prises en charge](../test-prise-en-charge-medicale.http).
