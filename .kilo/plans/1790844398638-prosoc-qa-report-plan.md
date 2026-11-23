# Plan — Traitement du rapport QA PROSOC (test_doc.md)

Périmètre : application mobile Flutter uniquement (dépôt `prosoc`).
Source de vérité API : Swagger dev `https://dev-prosoc.asdc-rdc.org/swagger/v1/swagger.json` (contrat réel lu, 49 546 lignes, OpenAPI 3.0.1, noms de propriétés PascalCase).

## Contexte et point de méthode

Le rapport QA contient 15 demandes sur 5 rôles. Le dépôt ne contient que l'app Flutter : c'est normal, l'API est un service distant. J'ai donc confronté chaque demande au contrat OpenAPI réellement déployé avant de planifier, car la doc Markdown locale (`lib/docs/API-DOCUMENTATION.md`) est en avance sur le déploiement — elle mentionne par exemple `sexeAffilie`, absent du contrat réel.

Trois demandes se sont révélées non réalisables depuis le mobile et sont traitées en conséquence (voir « Hors périmètre »).

## Décisions prises

| # | Décision |
|---|---|
| 1.1 | Retirer le plafond de 25 ans (le message QA « Le dépend ne peut pas être âgé que l'affilié » n'existe pas dans l'app) |
| 1.2 | **Hors périmètre** — aucun champ sexe côté API |
| 1.3 | Partage + impression PDF via `printing` + `pdf`, depuis `CollecteReceiptData` existant |
| 1.4 | Retirer les antécédents du process d'adhésion (déjà envoyés en `const []`) |
| 1.5 | Sélecteur de période sur le **réalisé** ; objectif mensuel affiché tel quel, avec libellé explicite |
| 1.6 | Clarifier Commission / Solde commission + cohérence avec le détail |
| 1.7 | Demande de rechargement : `POST /api/DemandeRechargeWalletVirtuel` (montant calculé serveur) |
| 2.1 | Corriger le scoping de l'historique + utiliser le scope affilié |
| 2.2 | Appel `GET /api/Agent/{id}` pour le téléphone/email de l'Agent AT |
| 2.3 | Compter depuis `beneficiaires[]` plutôt que `nombreBeneficiaires` |
| 3.1 | **Partiel** — endpoint mensuel seul, pas de paramètre période |
| 4.1 | Semaine calculée en fenêtre `dateDebut`/`dateFin` sur 7 jours |
| 4.2 | **Diagnostic seulement** — 403 backend, aucun param manquant côté mobile |
| 5.1 | Grouper par zone sociale (le chef d'équipe n'est pas lisible en GET) |
| 5.2 | Compléter l'existant avec réaffectation + traçabilité |

## Tâches ordonnées

### Phase 1 — Corrections de bugs (dépendances nulles)

1. **1.1 Retirer le plafond d'âge des dépendants**
   - `lib/widgets/dependant_bottom_sheet.dart:147-158` : supprimer le bloc `if (lien != 'Conjoint(e)' && age > 25)`.
   - `lib/views/screens/at/new_adhesion_screen.dart:1240-1244`, `:1291-1292`, `:2163` : le certificat de scolarité 18-25 ans reste exigé (règle métier distincte, non remise en cause par QA) mais ne doit plus être justifié par un plafond bloquant.

2. **1.4 Retirer les antécédents du process d'adhésion**
   - L'écran d'adhésion envoie déjà `antecedants: const []` (`new_adhesion_screen.dart:3244`) : le payload est conforme.
   - Retirer les points d'entrée UI hors `AppFeatures.healthUiEnabled` : `my_network_screen.dart:591` et `AffiliateDetailsScreen.dart:686,1810-1811`.
   - `lib/widgets/antecedent_bottom_sheet.dart` devient inutilisé — supprimer ou laisser en place selon jugement ; le gate `healthUiEnabled` (`lib/config/app_features.dart`) le masque déjà par défaut.

3. **2.1 Corriger l'historique des cotisations affilié**
   Cause racine : `lib/views/screens/adhérent/cotisationsScreen.dart:130-133` appelle `getAffiliePaiementsHistorique` **sans `affilieId`**, donc récupère la page 1 de l'historique global, puis filtre côté client. Les lignes de l'affilié sont absentes de la page 1.
   - Basculer sur `ApiService.getAffiliePaiementsHistoriqueList` (`lib/config/api.dart:1271-1320`) qui passe déjà `filters: 'affilieId=$affilieId'` et `sortBy: 'dateCollecte', sortDirection: 'desc'`.
   - Corriger le filtre strict `typeCollecte` (`cotisationsScreen.dart:102-106`) : le contrat expose l'enum `TypeCollecte` = `FRAIS | SOUSCRIPTION | COTISATION`. Comparer à `COTISATION` explicitement plutôt que `contains('cotisation')`, et ne pas rejeter silencieusement une valeur inconnue.
   - Enveloppe à lire : `data` / `currentPage` / `hasNextPage` / `totalItems` (pas `rows`). Vérifier la compatibilité avec `PaginatedResponseHelper.extractRows`.

4. **2.3 Corriger le nombre de personnes à charge**
   `lib/views/screens/adhérent/adherent_profile_screen.dart:315` lit `info?.nombreBeneficiaires`. Le profil affiche 0 quand l'API ne le renseigne pas.
   - Compter `data.beneficiaires.length` (tableau `AffilieBeneficiaireDto[]` présent dans `AffilieDashboardResumeDto`) avec repli sur `nombreBeneficiaires`.
   - Exclure l'affilié lui-même : filtrer `estPrincipal == false` si le champ est présent.

5. **4.1 Collecte hebdomadaire Percepteur**
   Aucun paramètre semaine n'existe dans le contrat. Passer par les fenêtres de dates.
   - `lib/views/screens/Percepteur/dashboard_percepteur_screen.dart:211-212` n'affiche que mois + jour. Ajouter un sélecteur de période (Aujourd'hui / 7 derniers jours / Mois en cours).
   - Alimenter via `GET /api/DashboardPercepteur/resume-journalier?debut&fin` (params `debut`/`fin`, **pas** `dateDebut`/`dateFin` — l'incohérence de nommage est réelle dans le contrat) et/ou `/montant-percu?debut&fin`.
   - Pour l'encaissement : `GET /api/PerceptionVirtuelle/historique` accepte `dateDebut`/`dateFin` (nommage différent de DashboardPercepteur, à respecter).

6. **1.6 Clarifier Commission / Solde commission**
   Le libellé actuel « Solde commissions » (`at/dashboard_screen.dart:586`) affiche `commissions.soldeWallet` à côté de `kpis.totalCommissionsMois` (`:618`), sans période ni définition — d'où la confusion QA.
   - Renommer explicitement : « Solde commission disponible » vs « Commissions du mois ».
   - Ajouter une ligne de définition / info-bulle reprenant la proposition fonctionnelle QA (total généré/acquis vs disponible après retraits).
   - Renvoyer vers `/api/AgentCommission/dashboard?idAgent` (`CommissionDashboardDto` : `totalCommissions`, `soldeActuel`, `nombreCommissions`, `ceMois`, `laSemaine`, `aujourdhui`) qui porte la séparation attendue. À noter : le contrat n'expose **aucun** champ « acquis moins retiré ».

### Phase 2 — Nouveaux parcours sur endpoints existants

7. **1.7 Demande de rechargement de wallet (Agent AT)**
   Contrat complet : `POST /api/DemandeRechargeWalletVirtuel` (`DemandeRechargeWalletVirtuelCreateDto` : `agentId` requis, `motif` max 500), `GET .../en-attente`, `GET .../by-agent/{agentId}`, `POST .../{id}/confirmer`, `POST .../{id}/rejeter`.
   - **Le montant n'est pas envoyé par le client** — il est calculé par le serveur (`montantCalcule`, `plafondAuMomentDemande`, `soldeAuMomentDemande`). Le parcours QA « il renseigne le montant » (étape 3) n'est donc pas réalisable tel quel : afficher le montant calculé + le plafond en lecture seule, et garder la saisie du motif.
   - Les statuts ne sont pas documentés (aucun enum) : déduire l'état des champs `statutDemande`, `dateConfirmation`, `dateRejet`, `motifRejet` plutôt que d'une liste figée.
   - Écran : bouton « Demander un rechargement » dans `lib/views/screens/at/wallet_screen.dart` (bloc d'actions `:414-458`), + écran de suivi de statut alimenté par `by-agent/{agentId}`.
   - Ne pas confondre avec `PUT /api/WalletVirtuelAgent/{id}/ajouter-solde` (crédit direct, réservé au superviseur/chef d'équipe via `superviseur_recharge_wallet_sheet.dart`).

8. **2.2 Contact de l'Agent AT dans le profil affilié**
   `AgentReadDto` expose bien `phone` et `emailAgent` (noms **différents** du côté affilié qui utilise `telephone`/`emailAffilie`) via `GET /api/Agent/{id}`. L'ID est déjà connu de l'affilié : `AdhesionWithAffilieReadDto.agentId`.
   - Ajouter la méthode API `getAgentDetail` (déjà présente, `api.dart:393`) et l'appeler depuis le profil.
   - Afficher téléphone + email, avec action `tel:` (`url_launcher` déjà dans pubspec).
   - Risque à signaler : le contrat ne documente aucune restriction de rôle sur `GET /api/Agent/{id}`. Si un token affilié reçoit un 403, l'app doit degrader proprement (carte masquée, pas d'écran bloqué).

9. **1.3 Reçu imprimable et partageable**
   L'écran `lib/views/widgets/collecte_receipt_screen.dart` ne fait que copier le texte dans le presse-papiers. Aucune impression, aucun PDF, mention « Document généré localement par Prosoc Mobile ».
   - Ajouter `printing: ^5.x` et `pdf: ^3.x` (ou `share_plus` pour le partage) au `pubspec.yaml`.
   - Générer un PDF depuis `CollecteReceiptData` (`lib/models/collecte_receipt_data.dart`) : n° de référence, affilié, type d'opération, montant, date/heure, agent, référence de paiement.
   - Le contrat **n'a aucun endpoint de reçu** ni `numeroRecu`. Les données viennent de `CollecteReadDto.referencePaiement`, `montant`, `montantRecu`, `dateCollecte`, `agentNom`, `deviseCode`, `statutPaiement`, `modePaiement`.
   - Garder l'action « Copier » existante ; ajouter Partager + Imprimer.

10. **1.5 Sélecteur de période sur les targets (Agent AT)**
    - Le réalisé par période existe : `GET /api/DashboardAgent/activite-quotidienne?jours` et `GET /api/DashboardAgent/performances-mensuelles?mois`.
    - Les objectifs n'existent que mensuels : `GET /api/DashboardAgent/objectifs?mois&annee` (`AgentObjectifDto`). **Pas de `dateDebut`/`dateFin` sur cet endpoint** — ne pas en envoyer.
    - Ajouter un sélecteur Jour / Semaine / Mois qui pilote la période du réalisé, et conserver les 4 cartes d'objectif existantes (`at/dashboard_screen.dart:387-422`) avec un libellé « Objectif mensuel » explicite quand la période sélectionnée n'est pas le mois.
    - Les cibles par fréquence existent ailleurs (`PeriodiciteTarget` = `Journaliere|Hebdomadaire|Mensuelle` sur `/api/TargetAgent`) mais ne sont pas reliées au réalisé de l'agent : hors périmètre de cet item.

### Phase 3 — Périmètres partiellement couverts

11. **3.1 Résumé des collectes Chef d'équipe**
    - `GET /api/DashboardChefEquipe/agents` renvoie déjà par agent : `collectesMois`, `totalCollectesMois`, `collectesEnAttente` — c'est-à-dire exactement les « informations à afficher » demandées par QA.
    - **Aucun paramètre de période** : les champs sont figés sur le mois. Le sélecteur jour/semaine/mois demandé ne peut pas être alimenté par cet endpoint.
    - Travail réel : afficher proprement `telephone`, `nombre de collectes`, `montant`, `période` (« Mois en cours ») + total d'équipe (`kpis.totalCollectesMoisZone`). Le sélecteur de période reste non implémentable et doit être signalé comme tel plutôt que simulé.
    - Enrichissement possible via `GET /api/DashboardChefEquipe/agents/{agentId}/collectes?limit` (lignes détaillées) et `.../mouvements-wallet` (mouvements de commission).

12. **5.1 Gestion des Chefs d'équipe (Superviseur)**
    - **Il n'existe aucun endpoint pour lister les chefs d'équipe.** Pas de contrôleur `/api/ChefEquipe`. L'affectation d'un chef d'équipe à une zone s'écrit via `PUT /api/ZoneSociale/{id}/chef-equipe` et n'est **pas lisible** en GET (`ZoneSocialeReadDto` ne contient ni `agentId` ni `chefEquipeId`).
    - Un chef d'équipe est un agent, désigné par son rattachement à une zone. Modélisation retenue : regrouper par zone sociale via `GET /api/ZoneSociale` puis `GET /api/Agent?Filters=zoneSocialeId:X`, ou s'appuyer sur `GET /api/Superviseur/agents-directs/{superviseurId}`.
    - Enrichir `superviseur_team_screen.dart` / `superviseur_agent_details_screen.dart` pour couvrir le parcours Superviseur → Chef d'équipe → Agents → Activités, en s'appuyant sur les 24 endpoints `/api/Superviseur` et 16 `/api/DashboardSuperviseur` existants (`activite-journaliere`, `performances-detaillees`, `objectifs`, `alertes-equipe`).
    - Attention : `ZoneSociale` expose aussi un id de zone pour un simple agent non-chef. Le regroupement par zone est une approximation, à valider avec le métier.

13. **5.2 Affectation des affiliés (Superviseur)**
    - `PUT /api/Agent/{agentId}/affecter-affilies` **existe et est déjà branché** (`api.dart:2253`, utilisé par `superviseur_affectation_screen.dart:252`).
    - Le contrat permet ce que QA demande et qui manque : le body accepte `sourceAgentId` → **réaffectation** traçable, et la réponse `AgentAffecterAffiliesResultDto` contient `totalDemandes`/`totalReussites`/`totalEchecs` et un `resultats[]` par affilié avec `succes`, `message`, `ancienAgentId` → **traçabilité**.
    - Compléter l'écran existant : confirmer avant envoi, afficher le résultat ligne par ligne, et recharger le profil de l'affilié après affectation (`GET /api/Affilie/{id}` ou `/mon-profil`).
    - `GET /api/Superviseur/affectations-recentes/{superviseurId}` et `/historique-affectations/{agentId}` fournissent l'historique.

## Hors périmètre — à remonter à QA / backend

Ces items ne sont pas corrigeables depuis l'app mobile. Les documenter explicitement plutôt que de les implémenter à moitié.

- **1.2 Sexe de l'affilié** — `AffilieCreateDto`, `AffilieUpdateDto`, `AdhesionWithAffilieCreateDto`, `AffilieReadDto`, `DependantCreateDto`, `DependantReadDto` : **aucun** champ `sexe` ou `genre` dans le contrat déployé. Seul `UtilisateurDto.genre` existe (nullable, string libre, pertains au compte utilisateur, pas à l'affilié). Impossible d'envoyer ou de récupérer la donnée. **À corriger côté backend.** La doc locale `lib/docs/API-DOCUMENTATION.md:721,750` mentionne `sexeAffilie` : elle est en avance sur le déploiement, ou erronée — à réconcilier.
- **4.2 Erreur « Non autorisé » (Percepteur, Encaissement Agent)** — le contrat ne déclare aucune restriction de rôle et **tous** les query params de `GET /api/PerceptionVirtuelle/collectes-en-attente` sont optionnels, sans défaut documenté. L'app envoie déjà `agentId`, `Page`, `pageNumber`, `PageSize`, `pageSize` (`api.dart:689-709`). Aucun param manquant côté mobile → le 403 est émis par le backend. Fournir au QA : le rôle et l'ID de l'agent concernés, le token décodé, la requête exacte, et l'endpoint à tester directement sur Swagger. Amélioration mobile possible : remplacer le message générique « Action non autorisée » (`api_error_helper.dart:19`) par un message actionnable, et afficher un état vide plutôt qu'une erreur si le 403 survient sur une liste.
- **1.1 (partiel)** — le message QA « Le dépend ne peut pas être âgé que l'affilié » ne correspond à aucune chaîne de l'app. Le contrat ne documente **aucune** règle d'âge sur les dépendants (seul `AffilieBeneficiaireDto.age`, calculé en lecture, et `minDependants`/`maxDependants` sans valeur sur la fiche encodeur). Si un contrôle backend envoie ce message, il est invisible et incorrectible depuis l'app. Le retrait du plafond 25 ans traite l'interprétation la plus probable ; à confirmer avec QA.

## Risques et points d'attention

- **Dépréciations de contrat à surveiller** : `/api/Affilie/paiements/historique` mixes `Antecedant*` (legacy, sans `dependantId`) dans `AdhesionWithAffilie*` alors que `/api/Antecedent` utilise `Antecedent*`. Sans impact tant que 1.4 supprime les antécédents de l'adhésion, mais à noter si le module santé est réactivé (`HEALTH_UI_ENABLED=true`).
- **Nommage de props très incohérent** côté API, source de bugs silencieux : `phone` vs `telephone`, `emailAgent` vs `emailAffilie`, `dateDebut`/`dateFin` vs `debut`/`fin`, `totalCommissionsMois` vs `totalCommissions`, `id` vs `idAgent` vs `agentId`. Les modèles Dart utilisent des parseurs tolérants (`_dashInt`, `_dashField`) : s'appuyer dessus, ne pas resserrer.
- **Aucun test n'existe** dans le dépôt (`test/` absent). Les filters `Filters` de l'API ne sont documentés nulle part — le scoping `affilieId` doit être vérifié en conditions réelles, pas supposé.
- **Feature flag santé** : `AppFeatures.healthUiEnabled` est `false` par défaut. Plusieurs items (1.4) touchent du code déjà masqué en production ; vérifier le comportement en build avec `HEALTH_UI_ENABLED=true`.

## Validation

1. `flutter analyze` doit passer sans nouveau warning.
2. Test manuel du cas 2.1 : affilié avec 1 cotisation, avec plusieurs, sans aucune → la ligne doit apparaître, l'état vide doit s'afficher. Vérifier que les enregistrements d'autres affiliés n'apparaissent pas.
3. Test manuel du cas 2.3 : affilié avec 3 personnes à charge → le profil doit afficher 3, pas 0.
4. Test 1.1 : adhésion avec un dépendant de 30 ans (lien Enfant) doit aboutir. Le certificat 18-25 ans reste exigé pour un mineur de 20 ans.
5. Test 1.7 : une demande de rechargement doit passer le statut En attente → confirmée, et le montant doit correspondre au `montantCalcule` serveur (ne pas saisir de montant côté client).
6. Test 1.3 : PDF généré, imprimable et partageable ; vérifier le contenu sur les 7 champs exigés par QA.
7. Test 4.1 : la fenêtre 7 jours doit isoler les collectes de la semaine et totter celles des semaines voisines.
8. Test 1.5 : le sélecteur de période change le réalisé affiché ; l'objectif reste libellé « Objectif mensuel » hors période mensuelle.
9. Test 5.2 : réaffectation d'un affilié depuis un agent source vers un agent cible, avec affichage du résultat par ligne et mise à jour du profil.

## Hors périmètre de ce plan

- Backend : ajout du champ sexe, correction du 403 superviseur/Percepteur, ajout de paramètres de période sur `DashboardAgent/objectifs` et `DashboardChefEquipe/*`, endpoint de reçu, endpoint de lecture des chefs d'équipe, endpoint d'historique de cotisations scopé affilié.
- Refonte de la couche HTTP, migration de state management, mise en place de tests automatisés (aucun test n'existe aujourd'hui).
