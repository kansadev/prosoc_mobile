# Intégration Frontend — suites aux retours de recette

Ce guide sépare les comportements backend utilisables des sujets encore à confirmer à la suite de [`RAPPORT_BACKEND_RETOURS_RECETTE.md`](RAPPORT_BACKEND_RETOURS_RECETTE.md). Il complète les guides détaillés existants et ne remplace pas leurs contrats.

## Changements backend prêts à intégrer

### 1. Paiement fractionné d’une cotisation

Les versements d’une cotisation sont cumulés par affilié, tarif, mois et année. L’API accepte un montant inférieur au reste à payer et refuse un montant qui le dépasse. Pour FlexPay, le montant débité est celui transmis par le client ; les collectes en attente réservent leur montant normalisé afin d’empêcher plusieurs paiements concurrents de dépasser le solde.

#### Lire le résumé d’une période

```http
GET /api/arrieres-affilie/mes-cotisations/{cotisationAffilieId}/periode/{mois}/{annee}
Authorization: Bearer {jwt}
```

Cette route est destinée à l’affilié connecté et exige `READ_MES_ARRIERES_AFFILIE`. Elle accepte le mois courant comme toute autre période : fournir le mois et l’année voulus, même si l’arriéré courant n’apparaît pas encore dans la liste des échéances.

Réponse `200` (`CotisationPeriodeReadDto`) :

```json
{
  "affilieId": 34,
  "cotisationAffilieId": 2,
  "mois": 11,
  "annee": 2026,
  "periodicite": "Mensuel",
  "montantAttendu": 200,
  "montantPaye": 50,
  "restAPayer": 150,
  "montantReserve": 20,
  "resteDisponible": 130,
  "deviseId": 1,
  "deviseCode": "CDF",
  "statutPaiement": "PARTIEL",
  "estCompletementPaye": false
}
```

- Afficher `restAPayer` comme solde comptable de la période.
- Utiliser `resteDisponible` comme maximum immédiatement payable : il déduit aussi les paiements FlexPay en attente (`montantReserve`).
- Après confirmation ou expiration FlexPay, recharger ce résumé.
- La route ci-dessus renvoie le résumé de l’affilié connecté. Pour un écran agent qui doit consulter la période d’un autre affilié, le contrat actuel ne fournit pas cette même route avec `affilieId` explicite ; ne pas fabriquer cet accès en appelant la route « mes-cotisations » avec un autre identifiant.

#### Envoyer un versement FlexPay

Endpoint : `POST /api/Collecte/with-paiement-electronique` (`202 Accepted`, traitement asynchrone). Pour une cotisation, `collecte.montant` doit contenir le montant du versement dans `collecte.deviseId` ; il ne faut pas le remplacer par le tarif entier. La conversion vers la devise du tarif et le contrôle du reste sont effectués par l’API.

```json
{
  "modePaiement": "MOBILE_MONEY",
  "telephonePaiement": "0822222222",
  "devisePaiementId": 1,
  "collecte": {
    "typeCollecte": "Cotisation",
    "affilieId": 34,
    "agentId": 12,
    "cotisationAffilieId": 2,
    "mois": 11,
    "annee": 2026,
    "montant": 50,
    "deviseId": 1
  }
}
```

La réponse `202` signifie que le paiement est initié, pas encore validé. Écouter l’événement SignalR documenté dans le guide FlexPay, puis rafraîchir la période après confirmation. En cas de refus car le montant dépasse le disponible, rafraîchir le résumé et proposer à l’utilisateur de réviser le montant.

> Cette règle de paiement partiel concerne les versements d’une cotisation existante. Elle ne transforme pas le paiement initial complet d’une nouvelle adhésion en paiement fractionné.

Le schéma doit inclure la colonne `CollectesEnAttente.MontantTarifVersement` de la migration `AddCotisationPaymentReservation`. Le déploiement doit appliquer la migration ou le script SQL correspondant selon le mode de gestion du schéma choisi par l’équipe.

### 2. Souscription médicale et cotisation à jour

`POST /api/SouscriptionMedicale` vérifie côté serveur que la cotisation de la période courante est entièrement réglée. Les versements validés sont cumulés ; une cotisation seulement partiellement payée ne rend pas l’affilié éligible. Le contrôle inclut le mois courant sans dépendre de la présence d’une ligne échue dans les arriérés.

Le frontend peut utiliser les arriérés pour informer l’utilisateur, mais doit traiter le refus serveur comme autoritaire et afficher le `message` retourné. Le parcours, les payloads et les erreurs médicales sont détaillés dans [`Documentation/IntegrationFrontendMedical.md`](Documentation/IntegrationFrontendMedical.md).

### 3. Mode offline — souscriptions prestation

Le batch offline peut synchroniser les souscriptions existantes via `GET /api/sync/souscriptions-prestations` et créer une nouvelle souscription pour un affilié déjà connu avec `type: "SOUSCRIPTION_PRESTATION"`. Consulter [`FRONTEND_INTEGRATION_OFFLINE_SYNC.md`](FRONTEND_INTEGRATION_OFFLINE_SYNC.md) pour le payload, les permissions et la gestion de l’idempotence.

## Sujets du rapport qui ne constituent pas encore un contrat frontend stabilisé

| Sujet | État vérifié | Consigne d’intégration |
|---|---|---|
| Mot de passe oublié | Les routes existantes génèrent un token et le renvoient dans la réponse ; la réponse distingue aussi un compte inexistant. Ce n’est pas le flux OTP neutre proposé par le rapport. | Ne pas présenter ce mécanisme comme un reset e-mail/SMS prêt à l’emploi. Attendre un flux sécurisé et une réponse non énumérante. |
| Retrait en période `TOTAL` | `montantDemande` est obligatoire. Le serveur vérifie qu’il ne dépasse pas le disponible et détermine le type effectif d’après le montant ; `typeRetrait` fourni par le client est ignoré. Cela ne correspond pas sans ambiguïté au libellé `typeRetraitAutorise` de la période. | Le comportement métier attendu pour un retrait partiel pendant cette fenêtre doit être confirmé avant d’aligner les validations UI. Voir [`FRONTEND_INTEGRATION_RETRAIT_AGENT.md`](FRONTEND_INTEGRATION_RETRAIT_AGENT.md). |
| Agents affectables d’un superviseur | La hiérarchie est exposée par `GET /api/Superviseur/hierarchie/{superviseurId}`. La modification d’affectation passe par `PUT /api/Agent/{agentId}/affecter-affilies`, réservé aux rôles `Admin` et `Superviseur`. | Le frontend peut charger la hiérarchie, mais doit afficher les refus de périmètre du serveur ; la compatibilité de chaque agent retourné avec l’affectation doit être validée sur l’environnement cible. |
| Permissions médicales | Le rôle `Percepteur` dans `SeedData` inclut `CONFIRM_DEMANDE_BON_ENVOI`, mais pas `SCAN_BON_ENVOI` ni `USE_JETON_MEDICAL`. Les permissions réellement utilisables dépendent des attributions en base et des claims du JWT. | Construire les menus depuis les permissions reçues au login. Ne pas afficher la consommation d’un jeton sans `USE_JETON_MEDICAL`; après changement des permissions, renouveler le JWT. |
| Description du rôle `Percepteur` | La valeur du seed est désormais « Agent percepteur ». Le seed ne prouve pas à lui seul que la base de l’environnement a été mise à jour. | Afficher le nom du rôle plutôt que sa description comme libellé principal ; vérifier la description après exécution de la mise à jour de données. |

## Références

- [`FRONTEND_INTEGRATION_COLLECTE_FLEXPAY.md`](FRONTEND_INTEGRATION_COLLECTE_FLEXPAY.md) — détails du paiement électronique.
- [`FRONTEND_INTEGRATION_AFFILIE_SOUSCRIPTIONS.md`](FRONTEND_INTEGRATION_AFFILIE_SOUSCRIPTIONS.md) — espace affilié et paiement de souscription.
- [`FRONTEND_INTEGRATION_OFFLINE_SYNC.md`](FRONTEND_INTEGRATION_OFFLINE_SYNC.md) — synchronisation offline et écritures idempotentes.
- [`Documentation/IntegrationFrontendMedical.md`](Documentation/IntegrationFrontendMedical.md) — parcours médical complet.
