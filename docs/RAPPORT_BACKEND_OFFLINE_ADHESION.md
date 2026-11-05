# Adhésion hors ligne : points à valider côté backend

Date : 31 octobre 2026, mis à jour le 5 novembre 2026 · Application mobile Prosoc (Flutter) · Référence de contrat : `FRONTEND_INTEGRATION_OFFLINE_SYNC.md`

## Contexte

Un agent AT doit pouvoir faire une adhésion **sans réseau**, payée uniquement par **compte virtuel** (`VIRTUAL_ACCOUNT`). L'adhésion est enregistrée dans une file locale, puis envoyée par `POST /api/sync/writes/batch` au retour du réseau.

Symptôme en recette : hors ligne, le formulaire affiche « Frais d'adhésion indisponibles » et ne permet pas de continuer. Le frais d'adhésion, les types d'adhésion et les devises doivent venir de `GET /api/sync/referentials`, mis en cache sur l'appareil.

## Corrections déjà faites côté application

Ces erreurs venaient de l'app. Elles sont corrigées et ne demandent aucune action backend. Elles sont listées pour que vous sachiez comment l'app appelle désormais vos endpoints.

| Problème | Correction |
|---|---|
| Le watermark du bootstrap était enregistré **avant** le premier chargement. `referentials`, `affilies` et `wallets` étaient donc appelés avec `since` dès le cold start, et ne renvoyaient presque rien. | Cold start **sans `since`**. Le watermark du bootstrap n'est enregistré qu'une fois toutes les étapes réussies, puis sert de `since` à la passe suivante. |
| La réponse de `referentials` **remplaçait** tout le cache, même quand c'était un delta. | Les deltas sont fusionnés **par identifiant** (« upsert local par id », conforme au contrat). |
| Les données relues depuis le cache local faisaient planter le parsing (`_Map<dynamic, dynamic>`). | Conversion des données corrigée. |
| Les modèles `TypeAdhesion` et `Frais` refusaient des éléments plus légers que ceux de l'API classique. Un seul élément mal formé bloquait tout le formulaire. | Parsing tolérant (camelCase / PascalCase, champs facultatifs). Chaque liste est chargée indépendamment des autres. |
| La première synchronisation n'avait lieu qu'environ 45 s après l'ouverture. | Synchronisation lancée dès l'ouverture de session, si le compte a `READ_SYNC`. |
| Le hors ligne n'était jamais détecté : une coupure réseau ne faisait pas échouer le test de connexion. | Aucune réponse HTTP = hors ligne ; toute réponse, même en erreur = en ligne. |
| Le lot envoyé à `writes/batch` n'avait pas le format du contrat (clé `payload`, champs de suivi locaux). | Chaque élément porte `collecte`, `adhesion` ou `souscriptionPrestation` au premier niveau, sans champ local. |
| Une erreur sur un élément pouvait relancer le même lot sans fin, et une écriture interrompue par l'arrêt de l'app restait bloquée. | Un seul essai par passe ; reprise au redémarrage avec le même `clientRequestId`. |

Les appareils déjà synchronisés repartent automatiquement sur un cold start à la mise à jour. La file d'écritures en attente est conservée.

## Ce que nous vous demandons de valider

### 1. `GET /api/sync/referentials` sans `since` = catalogue complet

Au cold start, l'app appelle :

```http
GET /api/sync/referentials
Authorization: Bearer {jwt}
```

**À confirmer** : sans `since`, la réponse contient **tous** les éléments actifs de chaque liste, et en particulier le **frais d'adhésion**.

Vérification rapide avec un compte AT de dev :

```bash
curl -s -H "Authorization: Bearer $JWT" \
  "https://dev-prosoc.asdc-rdc.org/api/sync/referentials" | jq '{
    types: (.typeAdhesions | length),
    frais: [.frais[] | {idFrais, code, libelle, montant, deviseId, statut}],
    devises: (.devises | length),
    prestations: (.prestations | length)
  }'
```

Résultat attendu : au moins un type d'adhésion, au moins une devise, et un frais dont le `code` vaut `FRAIS_ADHESION`.

### 2. Champs lus par l'app pour chaque liste

L'app accepte le camelCase et le PascalCase. Les champs en gras sont indispensables au formulaire d'adhésion.

| Liste | Champs lus |
|---|---|
| `typeAdhesions` | **`id`**, **`libelle`**, `maxDependants`, `montant`, `statut`, `description`, `categorieAdhesionId` |
| `frais` | **`idFrais`**, **`code`** (le frais d'adhésion doit valoir `FRAIS_ADHESION`), `libelle`, **`montant`**, **`deviseId`**, `statut`, `estSupprime` |
| `devises` | **`idDevise`**, **`code`** (`CDF`, `USD`), `nom`, `statut`, `estDevisePrincipale` |
| `prestations` | **`id`**, **`nomPrestation`**, `montant`, **`deviseId`**, `estGratuit`, `statut` |

Si le `code` du frais est absent, l'app le cherche aussi dans le `libelle` (« Frais d'adhésion »), mais le `code` reste la source fiable.

**Constaté en recette** : hors ligne, les prestations du cache s'affichent sans leur nom, seulement avec le montant. **À confirmer** : le nom du champ qui porte le libellé dans `prestations`. L'app attend `nomPrestation`, comme dans l'API classique, et tolère plusieurs variantes en attendant.

### 3. Sémantique des deltas de référentiels

Avec `since`, l'app considère la réponse comme un **delta** et fait un upsert par identifiant (`id`, ou à défaut `idFrais`, `idDevise`, `idPrestation`…).

**À confirmer :**
- un élément désactivé ou supprimé est renvoyé dans le delta avec `statut: false` ou `estSupprime: true`. `GET /api/sync/deletions` ne couvre que les affiliés et les adhésions : sans cela, un frais supprimé resterait dans le cache ;
- les identifiants sont stables dans le temps.

### 4. Watermark

L'app enregistre le `watermark` du **bootstrap** pris au début de la passe, et l'utilise comme `since` à la passe suivante, pour `referentials`, `affilies`, `wallets`, `souscriptions-prestations` et `deletions`. Les `nextSince` des pages ne sont plus utilisés pour faire avancer le watermark.

**À confirmer** : ce watermark est un `since` valide pour ces cinq endpoints. Votre guide mentionne aussi `nextSince`.

### 5. Valeurs de `sexe` et de `typeCollecte`

- **`sexe`** : l'app envoie désormais `Masculin` / `Féminin` dans les endpoints d'adhésion et la file offline, comme dans l'exemple de votre doc. **À vérifier** à la première adhésion en recette.
- **`typeCollecte`** : un exemple du guide est numérique, alors que l'app envoie les chaînes de l'API classique (`Cotisation`, `Frais`…). **À confirmer** : les deux formes sont acceptées par le batch.

### 6. Permissions `READ_SYNC` / `WRITE_SYNC`

Point tranché par votre guide : Agent (AT), Chef d'équipe, Admin et Superviseur. Le Percepteur n'est pas concerné : aucune synchronisation pour ce rôle, donc pas d'opération hors ligne. Sans `WRITE_SYNC`, l'app ne met jamais une écriture en file et affiche l'échec réseau.

### 7. Batch d'écritures `POST /api/sync/writes/batch`

L'app envoie jusqu'à **50 écritures par lot**. Une adhésion contient les photos en base64 : affilié, et éventuellement carte d'identité, chacune compressée à moins de 1 Mo.

**À confirmer** : la **taille maximale du corps** acceptée. Un lot de 50 adhésions avec photos peut dépasser plusieurs dizaines de Mo, et nous réduirons la taille des lots si besoin.

L'app affiche un message dédié pour `SOLDE_INSUFFISANT`, `MODE_NON_VA`, `ADHESION_EXISTANTE`, `AFFILIE_DOUBLON`, `AFFILIE_HORS_SCOPE`, `AGENT_HORS_ZONE` et `AGENT_ID_INTERDIT`. Pour tout autre code, dont `VALIDATION` et `METIER`, elle affiche le `message` tel quel : merci de le rédiger en français et de façon lisible pour un agent.

### 8. `plafondWalletVirtuel`

Le bootstrap et les référentiels renvoient `plafondWalletVirtuel`, mais la doc ne précise pas son rôle.

**À préciser** : s'agit-il d'un montant maximal d'écritures hors ligne en attente, d'un solde maximal, ou d'autre chose ? L'app ne l'utilise pas encore. Aujourd'hui, avant d'enregistrer une adhésion hors ligne, elle ne compare le montant qu'au **dernier solde virtuel synchronisé**.

### 9. Test de connexion

Pour savoir si l'appareil est en ligne, l'app appelle `GET /api/sync/bootstrap` (timeout de 6 s) au démarrage puis toutes les 45 s. Toute réponse HTTP, même une erreur, est considérée comme « en ligne ».

**Proposition** : exposer un endpoint léger, par exemple `GET /api/health` (200, corps vide, sans authentification), pour éviter de calculer un bootstrap complet toutes les 45 s par appareil.

## Recette commune proposée

1. Compte AT de dev, en ligne : se connecter. Dans la console de debug, la ligne `[Sync] référentiels complets reçus : types=… frais=…` doit afficher des nombres supérieurs à 0.
2. Passer en mode avion et ouvrir « Nouvelle adhésion » : bandeau orange, frais d'adhésion affiché, seul le mode « Compte virtuel » est proposé.
3. Enregistrer l'adhésion : un n° de suivi s'affiche et le compteur « en attente » passe à 1.
4. Remettre le réseau : le lot est envoyé, l'affilié apparaît côté serveur et le solde virtuel est mis à jour.
5. Refaire le test avec un solde virtuel insuffisant : rejet `SOLDE_INSUFFISANT`, affiché dans un bandeau rouge sur l'app.

Merci de nous retourner les réponses aux points encore ouverts. Les points 1, 2 et 5 sont prioritaires pour la recette.
