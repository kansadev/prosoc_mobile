# Intégration Flutter et Vue.js de l’adhésion de Structure

Ce guide couvre la création d’une adhésion `STRUCTURE` dans Flutter et Vue.js, ainsi que la gestion des rattachements et la consultation des affiliés par l’Agent Structure. Utiliser l’URL de l’environnement configurée dans le client HTTP et vérifier les schémas dans `/swagger/v1/swagger.json` si Swagger est exposé.

## Authentification

| Route | Accès |
|---|---|
| `GET /api/CategorieAdhesion/actives` | JWT requis |
| `GET /api/TypeAdhesion?categorieAdhesionId={id}` | Public |
| `GET /api/StructurePartenaire/actives` | Public |
| `GET /api/TarifCotisation/type-adhesion/{typeAdhesionId}` | JWT requis |
| Création terrain JSON ou multipart | Route publique qui exige un `agentId` terrain dans le dossier |
| Création avec paiement électronique | Route publique qui utilise l’agent résolu depuis la session quand elle en fournit un |
| `POST /api/sync/writes/batch` | JWT et permission `WRITE_SYNC` |

Pour un formulaire sans session, le référentiel public des structures reste accessible. Le chargement dynamique des catégories et des tarifs par les routes ci-dessus dépend d’une session authentifiée. Vérifier ce prérequis pour le parcours public avant la recette.

## Règles fonctionnelles

- Un affilié appartient à zéro ou un partenaire. Il utilise `entreprisePartenaireId` pour la catégorie `Entreprise` ou `structurePartenaireId` pour `Structure`.
- Une adhésion `Entreprise` exige une entreprise partenaire active; une adhésion `Structure` exige une structure partenaire active.
- Une adhésion `Particulier` n'accepte aucun de ces deux rattachements.
- Chaque catégorie et type expose un `code` stable. `libelle` est destiné à l'affichage et peut être identique dans des catégories différentes.
- Le type est identifié par son `id` ou son `code` dans la catégorie; les noms seuls ne doivent pas servir de clé.
- La catégorie est portée par `TypeAdhesion`; une adhésion persiste son `TypeAdhesionId`, et sa catégorie est obtenue par ce type. `Affilie` ne porte pas de `CategorieAdhesionId`.
- `Affilie` porte le partenaire auquel il est durablement rattaché. Il ne peut avoir qu'un seul des deux IDs partenaire.
- Une structure peut avoir plusieurs affiliés et au plus un Agent Structure.
- Un agent ne peut être associé qu'à une seule structure et doit avoir le rôle exact `Agent Structure`.
- Le rôle Agent Structure peut consulter les affiliés de sa propre structure uniquement via les routes dédiées.

## Référentiel des structures

### Liste publique minimale

`GET /api/StructurePartenaire/actives` ne demande pas de JWT et retourne uniquement l'identifiant et le nom des structures actives. Cette route sert au formulaire d'adhésion public.

```json
[
  { "idStructurePartenaire": 12, "nom": "Structure Exemple" }
]
```

### Gestion par Admin / SuperAdmin

La lecture utilise `READ_STRUCTURE_PARTENAIRE` et les écritures utilisent `MANAGE_STRUCTURE_PARTENAIRE`. Les rôles Admin et SuperAdmin disposent aussi de ces accès.

| Méthode | Route | Usage |
|---|---|---|
| `GET` | `/api/StructurePartenaire?page=1&pageSize=20` | Liste paginée avec Agent Structure associé |
| `GET` | `/api/StructurePartenaire/{id}` | Détail |
| `POST` | `/api/StructurePartenaire` | Créer une structure |
| `PUT` | `/api/StructurePartenaire/{id}` | Modifier ses informations ou son statut |
| `PUT` | `/api/StructurePartenaire/{id}/agent-structure` | Affecter ou retirer l'Agent Structure (`agentId: null` pour retirer) |
| `PUT` | `/api/StructurePartenaire/{id}/affilies/{affilieId}` | Rattacher un affilié ayant une adhésion de catégorie Structure |
| `DELETE` | `/api/StructurePartenaire/{id}/affilies/{affilieId}` | Détacher l'affilié, retour `204` |

Le `PUT` sur le chemin de rattachement de la structure cible permet un transfert. Le `DELETE` renvoie `409` avec `code: "STRUCTURE_ADHESION_ACTIVE"` si une adhésion active de catégorie `STRUCTURE` existe. Vue.js peut afficher l’action de transfert ou de changement de type à réception de ce conflit.

Exemple de création d’une structure

```json
{
  "nom": "Structure Exemple",
  "description": "Structure partenaire",
  "telephone": "+243000000000",
  "email": "contact@example.org"
}
```

L'affectation d'un agent attend son `agentId`. L'agent doit déjà exister avec `roleAgent: "Agent Structure"`; une affectation d'un agent d'un autre rôle renvoie `400`, et un agent déjà affecté ailleurs renvoie `409`.

## Gestion des entreprises partenaires

La liste minimale pour choisir une entreprise est `GET /api/EntreprisePartenaire/actives`. L'administration utilise `GET /api/EntreprisePartenaire`, `GET /api/EntreprisePartenaire/{id}`, `POST /api/EntreprisePartenaire` et `PUT /api/EntreprisePartenaire/{id}` avec les permissions `READ_ENTREPRISE_PARTENAIRE` et `MANAGE_ENTREPRISE_PARTENAIRE`.

`GET /api/EntreprisePartenaire/{id}/affilies?page=1&pageSize=20` retourne les affiliés rattachés à cette entreprise.

## Création d'une adhésion Entreprise ou Structure

1. Appeler `GET /api/CategorieAdhesion/actives` et identifier la catégorie par son `code`, par exemple `STRUCTURE`. Utiliser `idCategorieAdhesion` comme valeur de sélection.
2. Appeler `GET /api/TypeAdhesion?categorieAdhesionId={id}&page=1&pageSize=20`. Lire `data` dans la réponse paginée, afficher `libelle` et utiliser `id` pour les types dont `statut` vaut `true`. Les formules `SOLO`, `F3` et `F6` peuvent avoir le même libellé dans plusieurs catégories.
3. Pour `STRUCTURE`, charger `GET /api/StructurePartenaire/actives` et présenter `nom` avec `idStructurePartenaire` comme valeur. Pour `ENTREPRISE`, utiliser `GET /api/EntreprisePartenaire/actives`. Réinitialiser le type et le partenaire si la catégorie change.
4. Pour une session authentifiée, charger les cotisations du type sélectionné via `GET /api/TarifCotisation/type-adhesion/{typeAdhesionId}`. Utiliser leurs identifiants pour les collectes de cotisation. Envoyer ensuite le dossier avec les identifiants du référentiel.

### Création terrain

`POST /api/Adhesion/with-affilie` reçoit le dossier et les identifiants à la racine. Exemple de dossier Solo avec une collecte de frais. Remplacer les identifiants, la devise et le montant par les valeurs du référentiel, et adapter le mois et l’année à la période de collecte.

```json
{
  "nom": "Exemple",
  "prenom": "Aline",
  "dateNaissance": "1990-03-15",
  "provinceResidence": "Kinshasa",
  "communeResidence": "Gombe",
  "quartierResidence": "Centre",
  "statutDossier": "EN ATTENTE",
  "categorieAdhesionId": 3,
  "typeAdhesionId": 5,
  "structurePartenaireId": 12,
  "agentId": 25,
  "collectes": [
    {
      "typeCollecte": 1,
      "fraisId": 7,
      "montant": 25,
      "deviseId": 1,
      "modePaiement": "ESPECE",
      "statutPaiement": "VALIDE",
      "mois": 11,
      "annee": 2026,
      "statut": true
    }
  ]
}
```

Pour le dépôt de fichiers, `POST /api/Adhesion/with-affilie-multipart` reçoit le même JSON sérialisé dans le champ texte `payload` et les fichiers dans les champs `photo` et `carteIdentite`. Le client HTTP génère l’en-tête multipart avec sa délimitation.

Après `201 Created`, conserver `id`, `affilieId` et `codeAdhesion`. La réponse fournit également `categorieAdhesionCode`, `typeAdhesionCode` et `structurePartenaireId`. Avec les droits de lecture requis, `GET /api/Adhesion/{id}/affilie` permet de relire le rattachement et `structurePartenaireNom`. Les codes et identifiants renvoyés par le serveur font foi.

### Paiement électronique

Pour `POST /api/Adhesion/with-affilie-paiement-electronique`, placer le dossier précédent dans `adhesion` et renseigner à la racine `modePaiement`, `devisePaiementId` et `telephonePaiement` pour `MOBILE_MONEY`. Toutes les collectes du dossier doivent utiliser le mode de paiement électronique choisi et la devise annoncée. L’API détermine le gestionnaire depuis la session et peut laisser l’adhésion sans affectation.

Le retour `202 Accepted` contient les éléments de suivi du paiement, dont `idCollecteEnAttente`, `orderNumberFlexPay` et éventuellement `paymentUrl`. Afficher un état en attente et confirmer la création du dossier après le résultat serveur. [Guide FlexPay](./FRONTEND_INTEGRATION_ADHESION_FLEXPAY.md)

### Synchronisation Flutter

`POST /api/sync/writes/batch` reçoit un item de type `ADHESION_WITH_AFFILIE` avec le dossier dans `adhesion`. Conserver `categorieAdhesionId`, `typeAdhesionId`, `structurePartenaireId` et un `clientRequestId` stable pour les reprises de la même écriture. Toutes les collectes de ce flux utilisent `VIRTUAL_ACCOUNT` et le dossier doit inclure son agent gestionnaire.

Traiter le statut de chaque item. Un lot accepté peut contenir un item rejeté avec `errorCode: "VALIDATION"` si la structure est devenue inactive. Rafraîchir le référentiel et demander à l’utilisateur de corriger son choix avant de renvoyer la saisie. [Guide de synchronisation](./FRONTEND_INTEGRATION_OFFLINE_SYNC.md)

Pour le parcours direct, le serveur renvoie `400` avec `code: "STRUCTURE_ADHESION_INVALIDE"` si la catégorie et le type diffèrent, si la structure est absente, inconnue ou inactive, ou si le partenaire transmis appartient à une autre catégorie. L’absence de `categorieAdhesionId` déclenche la validation du DTO. FlexPay et la synchronisation utilisent leurs enveloppes d’erreur respectives.

Pour `ENTREPRISE`, sélectionner la catégorie et le type correspondants et renseigner `entreprisePartenaireId`. Pour `PARTICULIER`, omettre les deux champs partenaire.

Avec la permission `CHANGE_TYPE_ADHESION`, appeler `POST /api/Adhesion/{id}/changer-type-adhesion`, envoyer `nouveauTypeAdhesionId` et fournir le partenaire correspondant à la catégorie cible (`entreprisePartenaireId` ou `structurePartenaireId`). En passant à `Particulier`, les deux rattachements sont supprimés.

## Espace Agent Structure

Le compte utilisateur doit avoir le rôle `Agent Structure` et la permission propre à la route. L’API résout l’agent à partir du JWT ou du compte utilisateur. Une structure active doit être affectée à cet agent.

| Méthode | Route | Permission | Résultat |
|---|---|---|---|
| `GET` | `/api/StructurePartenaire/mienne` | `READ_STRUCTURE_PARTENAIRE` + rôle Agent Structure | Sa structure |
| `GET` | `/api/StructurePartenaire/mienne/affilies?page=1&pageSize=20` | `READ_STRUCTURE_AFFILIES` + rôle Agent Structure | Affiliés de sa seule structure |

Les routes génériques de consultation des affiliés continuent d'appliquer leurs propres permissions. Ne pas accorder `READ_AFFILIE` au rôle Agent Structure pour remplacer le périmètre dédié.

## Préparation au déploiement

1. Aligner la base de recette avec les migrations EF ou le [script SQL consolidé](./sql/AdhesionStructure.test.idempotent.sql).
2. Au démarrage de l’API, le seed ajoute les codes `SOLO`, `F3` et `F6` manquants dans `STRUCTURE` à partir des types Particulier. Il copie les montants, devises, limites de dépendants et tarifs de cotisation actifs disponibles à la création de chaque type. Les types déjà configurés conservent leurs paramètres. Vérifier les tarifs de cotisation avant la recette si le référentiel Particulier était vide de tarifs.
3. Créer l'agent avec `roleAgent: "Agent Structure"` et la catégorie `AST`, puis créer/affecter la structure.
4. Recenser les affiliés historiquement enregistrés avec `StructurePartenaireId` et confirmer s'ils relèvent réellement de la catégorie Structure ou Entreprise avant de les rattacher.
5. Faire mettre à jour les formulaires afin d'envoyer `categorieAdhesionId`, `typeAdhesionId` et le seul identifiant partenaire correspondant.
6. Demander à l'Agent Structure de se reconnecter pour recevoir les permissions actualisées dans son JWT.

Le nouveau champ `EntreprisePartenaireId` reste nul pour les affiliés existants. Aucun rattachement historique n'est déplacé automatiquement : l'ancien modèle utilisait le champ Structure aussi pour des adhésions Entreprise, et une entreprise partenaire correspondante ne peut pas être déduite sans validation métier. Les enregistrements de catégories/types non reconnus reçoivent un code technique `LEGACY_<id>` ou `TYPE_<id>` à remapper après vérification.

## Lister les affiliés d'une structure depuis la route Affilié

L'endpoint paginé suivant est disponible pour les écrans qui utilisent déjà le module Affilié :

```http
GET /api/Affilie/structure/{structurePartenaireId}?page=1&pageSize=20
```

- Les utilisateurs ayant `READ_AFFILIE` (ainsi que Admin/SuperAdmin) peuvent consulter les affiliés de la structure demandée.
- Un utilisateur avec le rôle `Agent Structure` doit avoir `READ_STRUCTURE_AFFILIES`; l'API limite alors la requête à sa propre structure active. Toute autre structure renvoie `403`.
- Une structure inexistante renvoie `404`. La réponse utilise le format paginé standard et les mêmes champs affilié que `GET /api/Affilie`.

Pour l'espace Agent Structure, `GET /api/StructurePartenaire/mienne/affilies` reste disponible quand l'identifiant de structure n'est pas nécessaire côté frontend.


## Intégration par client

### Flutter

- Faire évoluer le modèle de requête et son `toJson()` pour inclure `categorieAdhesionId` et, pour `STRUCTURE`, `structurePartenaireId`.
- Conserver la sélection dans l’état du formulaire, avec un état de chargement ou d’échec pour chaque référentiel. Charger et enregistrer les choix disponibles avant une saisie hors ligne.
- Au retour du réseau, exploiter le résultat de chaque item pour afficher le dossier créé ou le champ à corriger.

### Vue.js

- Placer les appels aux référentiels et mutations dans le service HTTP existant. Réinitialiser la formule, le partenaire et les tarifs dépendants quand la catégorie change.
- Côté administration, envoyer explicitement `statut` dans le `PUT` d’une structure. Utiliser le détail ou recharger la liste après une modification ou un transfert.
- Dans l’espace Agent Structure, prendre la liste depuis `mienne/affilies` et lire `data`, `currentPage` et `hasNextPage` pour la pagination.

## Recette commune

- Vérifier que la sélection `STRUCTURE` affiche les formules de sa catégorie et seulement les structures actives.
- Créer un dossier terrain et relire le rattachement. Vérifier le refus d’une structure manquante ou inactive et d’un type d’une autre catégorie.
- Vérifier la création électronique après confirmation et un refus de rattachement en synchronisation.
- Transférer un affilié `STRUCTURE` vers un partenaire actif et vérifier le conflit `STRUCTURE_ADHESION_ACTIVE` lors d’un détachement direct.
- Avec un compte Agent Structure, vérifier la liste de sa structure et le refus de consultation d’une autre structure.
