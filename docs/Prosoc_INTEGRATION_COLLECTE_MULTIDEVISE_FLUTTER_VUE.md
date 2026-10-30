# Intégration frontend — Collecte multidevise (Vue 3 et Flutter)

Contrat vérifié dans les sources du dépôt le 27 octobre 2026. Les exemples sont illustratifs : aucun paiement réel n'a été effectué.

## 1. Exemple métier et prérequis

Un affilié règle une **souscription existante** dont le produit coûte **10 USD**. Il choisit de payer en **CDF**. Pour cet exemple seulement, le taux configuré vaut **1 USD = 2 800 CDF**, donc le montant à collecter est **28 000 CDF**.

Identifiants fictifs à remplacer par les données de votre environnement :

- USD : `idDevise = 1` ; CDF : `idDevise = 2`.
- Affilié : `101` ; agent : `7` ; souscription existante : `501`.
- Période à payer : octobre 2026, encore non soldée.
- Tarif du produit lié à la souscription : 10 USD ; affilié éligible au produit.
- Devises actives, devise principale active et taux de change applicable configurés côté serveur.

Ne pas créer une nouvelle souscription pour chaque paiement : `souscriptionPrestationId` identifie ici la souscription déjà existante. Ne pas le remplacer par l'identifiant du produit ou de la prestation.

Les exemples utilisent `API_BASE_URL` comme origine de l'API, sans suffixe `/api`. Le jeton JWT vient de la session utilisateur. Les droits du compte doivent autoriser l'opération ; le parcours membre impose des restrictions supplémentaires sur ses propres arriérés.

## 2. Sens des montants et règles serveur

- `montant` : montant de la collecte **dans la devise de paiement**.
- `deviseId` : identifiant de cette devise de paiement. Ici : CDF, donc `2`.
- La devise du produit reste USD. Ne pas modifier le produit pour permettre un paiement en CDF.
- Le serveur retrouve le tarif à partir de la référence métier, convertit le montant reçu vers la devise du tarif et vérifie l'égalité, avec une tolérance configurée de `0.01` dans cette devise.
- Aucun paiement partiel ou supplément arbitraire n'est accepté par cette validation.
- Le dernier taux direct actif dont `dateEffet <= dateReference` est utilisé. À défaut, le serveur recherche le taux inverse ; il ne recherche pas de chemin via une troisième devise.
- La conversion est arrondie à deux décimales, les demis étant arrondis en s'éloignant de zéro.
- Pour une collecte synchrone, `dateReference` est la date de collecte fixée par le serveur. Le client ne transmet pas `dateCollecte` dans le DTO de création.
- La prévisualisation ne réserve pas le taux : un changement de taux entre aperçu et soumission peut provoquer un refus. Refaire alors l'aperçu et faire confirmer le nouveau montant.

Le serveur conserve `deviseTarifId`, `montantTarifAttendu`, `devisePrincipaleId`, `tauxVersDevisePrincipale` et `montantDevisePrincipale` en base. **Ces champs ne figurent pas dans `CollecteReadDto` actuellement** : ne pas les attendre dans la réponse de création ou de lecture.

`montantRecu` et `montantAttendu` sont des champs optionnels distincts. Ils ne remplacent pas `montant` et ne déterminent pas le tarif serveur ; les exemples les omettent.

## 3. Parcours HTTP en espèces

### 3.1 Charger les devises

```http
GET /api/Devise/actives
Authorization: Bearer <jeton de session>
```

Réponse `200` : tableau d'objets contenant notamment `idDevise`, `code`, `nom`, `symbole`, `estDevisePrincipale`, `statut`. Retrouver l'identifiant via le code ; ne pas coder `1` et `2` en dur dans l'application.

Récupérer aussi le tarif et sa devise depuis le produit associé à la souscription, via les services métier existants de l'application. Pour une cotisation, utiliser le calcul métier incluant les dépendants, pas un simple prix unitaire.

### 3.2 Prévisualiser le montant à payer

La source est **la devise du tarif**, la cible **la devise du paiement**. Toujours préciser la cible : sinon l'API utilise la devise principale.

```http
GET /api/Devise/preview-conversion?codeDeviseSource=USD&montant=10&codeDeviseCible=CDF
Authorization: Bearer <jeton de session>
```

Réponse `200` illustrative, si USD est la devise principale :

```json
{
  "codeDeviseSource": "USD",
  "codeDeviseCible": "CDF",
  "codeDevisePrincipale": "USD",
  "datePaiement": "2026-10-27T10:00:00Z",
  "taux": 2800,
  "montantSource": 10,
  "montantConverti": 28000
}
```

Afficher avant confirmation : « Tarif : 10 USD · Taux : 1 USD = 2 800 CDF · À payer : 28 000 CDF ». Utiliser `montantConverti` pour la soumission ; ne pas reconstruire le montant à partir du texte formaté.

Le paramètre facultatif `datePaiement` sert à simuler une conversion à une date donnée. Pour une nouvelle collecte, l'omettre afin d'utiliser la date serveur actuelle.

### 3.3 Enregistrer après encaissement réel

```http
POST /api/Collecte
Authorization: Bearer <jeton de session>
Content-Type: application/json
```

```json
{
  "typeCollecte": "SOUSCRIPTION",
  "affilieId": 101,
  "agentId": 7,
  "souscriptionPrestationId": 501,
  "montant": 28000,
  "deviseId": 2,
  "modePaiement": "ESPECE",
  "statutPaiement": "VALIDE",
  "mois": 10,
  "annee": 2026,
  "observation": "Souscription octobre 2026 payée en CDF",
  "statut": true
}
```

`VALIDE` signifie ici que l'opérateur a effectivement encaissé les espèces. Ne pas l'utiliser pour anticiper une confirmation électronique.

Réponse attendue : **`201 Created`**, en-tête `Location` vers la collecte et objet `CollecteReadDto`. Extrait illustratif de cet objet :

```json
{
  "idCollecte": 9001,
  "typeCollecte": "SOUSCRIPTION",
  "affilieId": 101,
  "agentId": 7,
  "souscriptionPrestationId": 501,
  "montant": 28000,
  "deviseId": 2,
  "deviseCode": "CDF",
  "modePaiement": "ESPECE",
  "statutPaiement": "VALIDE",
  "mois": 10,
  "annee": 2026,
  "statut": true
}
```

Pour relire la collecte : `GET /api/Collecte/9001`, avec authentification et droits appropriés.

### 3.4 Autres types de collecte

Conserver la même logique de conversion et transmettre une seule référence métier :

- `"FRAIS"` avec `fraisId` ; omettre `cotisationAffilieId` et `souscriptionPrestationId`.
- `"COTISATION"` avec `cotisationAffilieId` ; omettre `fraisId` et `souscriptionPrestationId`.
- `"SOUSCRIPTION"` avec `souscriptionPrestationId` ; omettre les deux autres.

Envoyer ces valeurs comme chaînes JSON. Le convertisseur actuel lit une chaîne ; éviter les nombres JSON `1`, `2`, `3` malgré le commentaire du convertisseur.

## 4. Vue 3 / TypeScript — service et utilisation

Exemple autonome utilisant `fetch`. Dans le projet, intégrer ces méthodes au client HTTP existant afin de conserver sa gestion de session. `VITE_API_BASE_URL` doit être configurée par environnement.

```ts
// services/collecteApi.ts — exemple à adapter
export interface Conversion {
  codeDeviseSource: string;
  codeDeviseCible: string;
  codeDevisePrincipale: string | null;
  datePaiement: string;
  taux: number;
  montantSource: number;
  montantConverti: number;
}
export interface SouscriptionCollecte {
  typeCollecte: 'SOUSCRIPTION';
  affilieId: number;
  agentId: number;
  souscriptionPrestationId: number;
  montant: number;
  deviseId: number;
  modePaiement: 'ESPECE';
  statutPaiement: 'VALIDE';
  mois: number;
  annee: number;
  statut: boolean;
}
// Projection des seuls champs utilisés ici ; le DTO serveur en contient d'autres.
export interface CollecteResult {
  idCollecte: number;
  montant: number;
  deviseId: number;
  deviseCode: string | null;
  statutPaiement: string | null;
}
const baseUrl = import.meta.env.VITE_API_BASE_URL?.replace(/\/$/, '');
if (!baseUrl) throw new Error('VITE_API_BASE_URL manquante');

async function request<T>(path: string, token: string, init: RequestInit = {}): Promise<T> {
  const response = await fetch(`${baseUrl}${path}`, {
    ...init,
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
      ...init.headers,
    },
  });
  const body = await response.json().catch(() => null);
  if (!response.ok) {
    const validation = body?.errors
      ? Object.values(body.errors).flat().join(' ')
      : undefined;
    throw new Error(body?.message ?? validation ?? body?.detail ?? body?.title
      ?? `Erreur HTTP ${response.status}`);
  }
  return body as T;
}
export function previewConversion(token: string, montant: number, source: string, cible: string) {
  const query = new URLSearchParams({
    montant: String(montant), codeDeviseSource: source, codeDeviseCible: cible,
  });
  return request<Conversion>(`/api/Devise/preview-conversion?${query}`, token);
}
export function creerCollecte(token: string, payload: SouscriptionCollecte) {
  return request<CollecteResult>('/api/Collecte', token, {
    method: 'POST', body: JSON.stringify(payload),
  });
}
```

Utilisation dans `setup` ou un composable :

```ts
import { ref } from 'vue';
import { previewConversion, creerCollecte, type Conversion } from './services/collecteApi';

const conversion = ref<Conversion | null>(null);
const pending = ref(false);
const erreur = ref('');
const collecteId = ref<number | null>(null);

async function chargerApercu(token: string) {
  conversion.value = null;
  erreur.value = '';
  try {
    conversion.value = await previewConversion(token, 10, 'USD', 'CDF');
  } catch (e) {
    erreur.value = e instanceof Error ? e.message : 'Conversion indisponible';
  }
}

async function confirmerEncaissement(token: string, deviseCdfId: number) {
  if (pending.value || collecteId.value !== null || !conversion.value) return;
  pending.value = true;
  erreur.value = '';
  try {
    const collecte = await creerCollecte(token, {
      typeCollecte: 'SOUSCRIPTION', affilieId: 101, agentId: 7,
      souscriptionPrestationId: 501,
      montant: conversion.value.montantConverti, deviseId: deviseCdfId,
      modePaiement: 'ESPECE', statutPaiement: 'VALIDE',
      mois: 10, annee: 2026, statut: true,
    });
    collecteId.value = collecte.idCollecte;
  } catch (e) {
    erreur.value = e instanceof Error ? e.message : 'Collecte impossible';
  } finally {
    pending.value = false;
  }
}
```

Lier le bouton à `pending`, à la présence de l'aperçu et à l'absence de collecte déjà créée. Afficher `erreur` dans une zone `role="alert"`. Invalider l'aperçu quand le produit, le tarif ou la devise change ; ignorer/annuler les réponses d'aperçus devenues obsolètes. Remplacer les identifiants fictifs par la sélection courante.

## 5. Flutter / Dart — service et utilisation

Exemple avec le package `http` (à déclarer dans `pubspec.yaml` s'il n'est pas déjà présent). Réutiliser le client et la gestion de session du projet lorsqu'ils existent. Fournir l'origine API via `--dart-define=API_BASE_URL=...` ou la configuration existante ; ne pas fixer `localhost` pour un téléphone.

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class Conversion {
  final double montantConverti;
  final double taux;
  final String codeDeviseCible;
  Conversion.fromJson(Map<String, dynamic> json)
      : montantConverti = (json['montantConverti'] as num).toDouble(),
        taux = (json['taux'] as num).toDouble(),
        codeDeviseCible = json['codeDeviseCible'] as String;
}

class CollecteApi {
  final http.Client client;
  final String baseUrl;
  CollecteApi(this.client, String apiBaseUrl)
      : baseUrl = apiBaseUrl.replaceFirst(RegExp(r'/$'), '') {
    if (baseUrl.isEmpty) throw ArgumentError('API_BASE_URL manquante');
  }

  Map<String, String> headers(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Map<String, dynamic> decode(http.Response response) {
    dynamic body;
    try { body = jsonDecode(response.body); } catch (_) { body = null; }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = body is Map<String, dynamic> ? body : <String, dynamic>{};
      final errors = data['errors'];
      final validation = errors is Map
          ? errors.values.expand((value) => value is List ? value : [value]).join(' ')
          : null;
      throw Exception(data['message'] ?? validation ?? data['detail']
          ?? data['title'] ?? 'Erreur HTTP ${response.statusCode}');
    }
    if (body is! Map<String, dynamic>) {
      throw const FormatException('Réponse API inattendue');
    }
    return body;
  }

  Future<Conversion> preview(String token, double montant,
      String source, String cible) async {
    final uri = Uri.parse('$baseUrl/api/Devise/preview-conversion')
        .replace(queryParameters: {
      'montant': montant.toString(),
      'codeDeviseSource': source,
      'codeDeviseCible': cible,
    });
    final response = await client.get(uri, headers: headers(token));
    return Conversion.fromJson(decode(response));
  }

  Future<int> creerSouscriptionCollecte({
    required String token,
    required int affilieId,
    required int agentId,
    required int souscriptionId,
    required int devisePaiementId,
    required double montant,
    required int mois,
    required int annee,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/Collecte'), headers: headers(token),
      body: jsonEncode({
        'typeCollecte': 'SOUSCRIPTION',
        'affilieId': affilieId, 'agentId': agentId,
        'souscriptionPrestationId': souscriptionId,
        'montant': montant, 'deviseId': devisePaiementId,
        'modePaiement': 'ESPECE', 'statutPaiement': 'VALIDE',
        'mois': mois, 'annee': annee, 'statut': true,
      }),
    );
    return decode(response)['idCollecte'] as int;
  }
}
```

Séquence d'utilisation :

```dart
// Le propriétaire du client doit appeler client.close() à sa destruction.
final client = http.Client();
final api = CollecteApi(client, const String.fromEnvironment('API_BASE_URL'));

// token : session courante ; deviseCdfId : identifiant chargé par code CDF.
final apercu = await api.preview(token, 10, 'USD', 'CDF');
// Afficher apercu.montantConverti et attendre la confirmation de l'encaissement.
final id = await api.creerSouscriptionCollecte(
  token: token, affilieId: 101, agentId: 7, souscriptionId: 501,
  devisePaiementId: deviseCdfId, montant: apercu.montantConverti,
  mois: 10, annee: 2026,
);
// Afficher le reçu correspondant à id.
```

Dans le widget ou le notifier Riverpod, intercepter les exceptions, bloquer le bouton pendant la requête et après succès, puis vérifier `mounted` avant de mettre à jour un widget après un `await`. Invalider l'aperçu si la sélection change. Ces extraits transportent les nombres JSON ; laisser le calcul et les arrondis monétaires au serveur.

## 6. Variante paiement électronique

### Initiation

Pour un opérateur authentifié, `POST /api/Collecte` avec `modePaiement = "MOBILE_MONEY"`, `phone` et `statutPaiement = "EN_ATTENTE"` renvoie **`200` avec `InitiateFlexPayResponseDto`**, et non une collecte créée. Séparer ce traitement du service espèces ci-dessus.

L'endpoint dédié `POST /api/Collecte/with-paiement-electronique` autorise aussi l'initiation anonyme et renvoie **`202 Accepted`**. Son corps imbriqué, pour le même exemple, est :

```json
{
  "modePaiement": "MOBILE_MONEY",
  "telephonePaiement": "<numéro Mobile Money saisi par le payeur>",
  "devisePaiementId": 2,
  "collecte": {
    "typeCollecte": "SOUSCRIPTION",
    "affilieId": 101,
    "agentId": 7,
    "souscriptionPrestationId": 501,
    "montant": 28000,
    "deviseId": 2,
    "modePaiement": "MOBILE_MONEY",
    "statutPaiement": "EN_ATTENTE",
    "mois": 10,
    "annee": 2026,
    "statut": true
  }
}
```

Le téléphone est une indication à remplacer, pas une valeur valide à envoyer. `agentId` reste requis par le DTO imbriqué actuel. `devisePaiementId` doit être égal à `collecte.deviseId`. Le mode imbriqué reste nécessaire à la validation du DTO, même si le contrôleur le réaffecte depuis le mode externe.

La prévisualisation des devises demeure authentifiée : le caractère public de cet endpoint ne rend pas `/api/Devise/preview-conversion` public.

Les champs utiles de la réponse sont `idCollecteEnAttente`, `orderNumberFlexPay`, `referenceFlexPay`, `montantTarif`, `codeDeviseTarif`, `montantFlexPay`, `codeDevisePaiement`, `tauxApplique`, `holdExpireAt`, `paymentUrl`, `flexPayAccepted` et `message`.

Le serveur valide d'abord le montant soumis, puis recalcule le montant électronique depuis le tarif au taux courant. Seuls CDF et USD sont acceptés dans ce parcours. Le montant CDF est arrondi à l'unité ; une règle de frais peut aussi intervenir selon le canal. Afficher le `montantFlexPay` retourné comme montant d'initiation ; ne pas supposer qu'il est toujours égal à l'aperçu générique.

### Confirmation réelle

Une initiation acceptée ne signifie pas que le paiement est effectué. La collecte définitive est créée après confirmation serveur.

1. Conserver `idCollecteEnAttente`, la référence et, s'il est présent, `orderNumberFlexPay` pour la reprise du parcours.
2. Pour une carte, ouvrir `paymentUrl` lorsqu'elle est fournie. Pour Mobile Money, inviter le payeur à valider sur son téléphone.
3. Écouter `FlexPayPaymentUpdated` sur le hub `/flexPayHub`, après appel à `JoinFlexPayPayment(idCollecteEnAttente)` ; se désabonner via `LeaveFlexPayPayment` en quittant le parcours.
4. Confirmer le succès métier avec un événement `success` ou `alreadyProcessed` et l'identifiant de collecte attendu. Traiter `failed` comme un échec et afficher le message serveur.
5. En secours FlexPay, appeler `GET /api/FlexPay/verifier/{orderNumber}` avec la valeur retournée, encodée pour une URL. Cette route peut finaliser le paiement : un simple HTTP `200` ne suffit pas à annoncer un succès ; examiner le résultat métier et `idCollecte`. Si `pending = true`, conserver l’état d’attente et poursuivre la vérification à intervalle raisonnable, sans annoncer un refus.

Après reconnexion au hub, vérifier l'état pour récupérer une confirmation éventuellement manquée. Ne jamais marquer le paiement réussi à partir du seul retour navigateur d'une carte. Pour Moko et les détails des canaux, consulter le guide spécifique référencé ci-dessous ; ne pas présumer que la route de secours FlexPay convient à tout fournisseur.

## 7. Erreurs et comportement UI

Le contrat d'erreur actuel n'est pas uniforme : les erreurs métier synchrones peuvent être `{ "message": "..." }`, la validation automatique ASP.NET utilise notamment `errors`, `title`, `status`, et l'initiation électronique peut ajouter `code` et des informations de passerelle. Les clients ci-dessus lisent ces formats.

- Montant incorrect (`400`) : afficher le message, recharger tarif/aperçu et faire confirmer à nouveau. Exemple : `montant = 10` avec `deviseId = CDF` signifie **10 CDF**, pas 10 USD.
- Aucun taux actif (`400`) : bloquer la confirmation et demander la configuration du taux ; ne pas inventer un taux côté client.
- Référence absente, tarif incompatible ou période déjà soldée : afficher le message et rafraîchir le dossier.
- `401` : reprendre l'authentification ; `403` : expliquer le refus d'accès.
- Canal électronique inactif (`409` dans le parcours concerné) : rafraîchir les canaux disponibles.
- Erreur réseau après soumission : l'issue peut être inconnue. Vérifier les collectes ou l'état du paiement avant de renvoyer un `POST`. Ces exemples ne fournissent pas de clé d'idempotence serveur.
- Hold électronique en cours : reprendre le suivi existant avant une nouvelle initiation.

## 8. Vérifications d'intégration à effectuer

- Tarif 10 USD, paiement USD : soumettre 10 dans la devise USD ; aucune conversion nécessaire.
- Tarif 10 USD, paiement CDF avec le taux fictif 2 800 : aperçu 28 000 ; collecte espèces `201` et montant retourné en CDF.
- Soumettre 10 CDF pour le même tarif : rejet métier.
- Aucun taux direct ou inverse applicable : rejet sans création.
- Taux changé entre aperçu et validation : message affiché et aperçu renouvelé.
- Souscription déjà soldée pour la période : refus, sans nouvelle collecte.
- Double clic : une seule requête depuis l'interface ; reprise après erreur réseau sans renvoi aveugle.
- Mobile Money : réponse d'initiation affichée comme attente ; reçu uniquement après confirmation métier.
- Contrôler que l'écran et le reçu affichent explicitement la devise et restent utilisables avec lecteur d'écran.

Ces cas sont une recette à exécuter avec des données et un canal de test ; ils ne constituent pas des résultats de tests déjà exécutés.

## 9. Sources du contrat et guides complémentaires

- [CollecteController](../Controllers/CollecteController.cs) : routes, codes HTTP, date de collecte, mapping de lecture.
- [CollecteDtos](../Models/DTOs/Core/CollecteDtos.cs) : validation et champs exposés.
- [TypeCollecte](../Models/Core/TypeCollecte.cs) : chaînes JSON des types de collecte.
- [DeviseController](../Controllers/DeviseController.cs) et [DTO de conversion](../Models/DTOs/Core/TauxChangeDeviseDtos.cs).
- [DeviseConversionService](../Services/DeviseConversionService.cs) : taux, validation et snapshot.
- [CollecteService](../Services/CollecteService.cs) : validation métier synchrone.
- [FlexPayCollecteService](../Services/FlexPayCollecteService.cs) et [DTO FlexPay](../Models/DTOs/FlexPay/FlexPayDtos.cs).
- [Guide carte bancaire Moko](../../prosoc_mobile/Prosoc_FRONTEND_INTEGRATION_CARTE_BANCAIRE_MOKO.md).

Le fichier `DOCUMENTATION_MODULE_MULTIDEVISE.md` à la racine API contient actuellement des références à RusaTravel, sociétés et voyages : il ne doit pas servir de contrat pour ce parcours Prosoc. Le présent guide décrit les contrôleurs et DTO Prosoc inspectés.
