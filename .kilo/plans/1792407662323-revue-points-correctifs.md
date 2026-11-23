# Plan d'implémentation - Revue des 6 points + retour formulaire adhésion

**Date** : 2026-10-19  
**Fichier** : `.kilo/plans/1792407662323-revue-points-correctifs.md`

## Objectifs

Corriger les points remontés + améliorer UX formulaire d'adhésion (retour dans PageView). 
Garder des changements ciblés, testables et cohérents avec code existant.

## Point 1 - Annulation d'adhésion / retour arrière après confirmation

**Contexte** : Blocage "pas de retour en arrière" après transaction/adhésion confirmée.

**Vérifications nécessaires**
- Rechercher annulation/retour : `ApiService` pour méthodes annulation adhésion, écrans confirmés (liste adhésions, détail). 
- Chercher états : `statutDossier`, transitions autorisées.
- Comparer avec Perception Virtuelle (annulation réservée Admin/Financier) pour voir logique droits.

**Actions**
- [ ] Rechercher endpoints annulation adhésion : grep `annuler.*adhesion|adhesion.*annuler|cancel.*adhesion` dans `lib/config/api.dart` + écrans.
- [ ] Identifier écrans/listes où bouton "Annuler" est masqué après confirmation. Vérifier conditions (statut, rôle, permissions).
- [ ] Assouplir règles UI si métier permet annulation avant validation/comptabilisation. Si réservé Admin/Financier, afficher message explicatif + action (rediriger ou alerter).
- [ ] Ajouter dialogue confirmation avec impact + gestion erreur API (code/ message) - éviter verrouillage silencieux.
- [ ] Tests : adhésion EN_ATTENTE/COMPLET non comptabilisée -> tester flux.

**Fichiers cibles** : `lib/config/api.dart`, écrans adhésion (liste/détail), éventuellement `lib/views/screens/at/new_adhesion_screen.dart` si retour en arrière demandé (cf point 7).

## Point 2 - Devise paiement Mobile Money + conversion frais d'adhésion

**Constat** : Frais fixés en devise métier (non modifiable). Changement devise paiement ne déclenche pas conversion. Peut causer rejet.

**Analyse code** : `new_adhesion_screen.dart`
- `_deviseManuallySelected` empêche écrasement (L86, 416-426)
- Affichage frais "devise déterminée par paramétrage" (L2133-2161)
- `_applyDefaultDevise()` privilégie devise frais si présente (L414-426)
- Pas de taux de change visible.

**Actions**
- [ ] Rechercher taux change : `taux.*change|TauxChange|tauxChange` dans `lib/models`, `lib/config/api.dart`. Si absent, voir si endpoint existe dans docs.
- [ ] Si taux dispo : créer helper `CurrencyConverter` (montant source + devise src -> devise cible via taux). Gérer arrondi (2 décimales cohérent).
- [ ] Quand `_selectedDevise` change (devise paiement), recalculer montant affiché/à valider pour frais adhésion dans devise paiement. Afficher : "Montant équivalent : X YYY (taux appliqué : ZZZ)".
- [ ] Ne pas masquer frais ni forcer égalité ; permettre paiement dans autre devise avec conversion explicite. Mettre à jour libellé (_fraisAdhesionLabel) pour montrer équiv si différent.
- [ ] Mettre à jour payload si API attend montant+devise paiement cohérents (vérifier contrat `AdhesionWithAffilieRequest.collectes` + modèle CollecteRequest).
- [ ] Si pas de taux configuré : afficher avertissement clair + bloquer validation avec message explicite (plutôt que message générique).

**Fichiers** : `lib/views/screens/at/new_adhesion_screen.dart`, `lib/utils/currency_converter.dart` (nouveau si utile), modèles taux change.

## Point 3 - Reçu : table + nom du collecteur

**Constat** : `CollecteReceiptData` manque `agentNom/collecteur`. PDF/écran n'affichent pas collecteur. Déjà présent "Agent collecteur" dans cotisations.

**Actions**
- [ ] Étendre `CollecteReceiptData` (L1-60) : ajouter `agentNom`, `agentId`, `collecteurNom?`. Préserver rétrocompat (optionnels).
- [ ] `CollecteReceiptPdfService._rows()` (L38-68) : insérer "Collecteur"/"Agent collecteur" après "Affilié" (ordre logique). Ajouter dans `_plainText` écran.
- [ ] `collecte_receipt_screen.dart` : afficher ligne collecteur dans liste détails + dans copie presse-papier.
- [ ] Propager partout où construit : `souscription_bottom_sheet.dart`, écrans Percepteur, helpers. Remplir depuis `AuthService.currentUser` (nom complet) si contexte agent, ou depuis réponse API.
- [ ] Mettre à jour ordre/table clair FR.

**Fichiers** : `lib/models/collecte_receipt_data.dart`, `lib/utils/collecte_receipt_pdf_service.dart`, `lib/views/widgets/collecte_receipt_screen.dart`, `lib/widgets/souscription_bottom_sheet.dart`, `lib/views/screens/Percepteur/percepteur_encaissement*.dart`, autres constructeurs.

## Point 4 - Cotisation payée 1 seule fois par an (revoir vérification)

**Constat** : Règle "1 fois/an" mal appliquée (bloque même cas légitimes ?).

**Vérifications**
- Paiement cotisation : `popup_menu_widget.dart` "Payer une cotisation", `arriere_payment_navigator.dart`, écrans Percepteur. Chercher validations "déjà payée".
- Modèles cotisation (exercice/année, date dernière cotisation).

**Actions**
- [ ] Localiser vérification bloquante (UI + message). 
- [ ] Corriger condition : baser sur **exercice/année** (pas bool global). Permettre si autre année ou si en retard (régularisation). Respecter règle "1x/exercice" selon métier.
- [ ] Afficher message explicite : "Cotisation déjà réglée pour l'année X" si applicable.
- [ ] S'assurer mapping erreur API correcte (pas masquer cause).
- [ ] Tests : 2026 payée -> empêcher 2026 ; 2027 libre ; retard 2026 selon règle.

**Fichiers** : écrans paiement cotisation + navigation.

## Point 5 - Rechargement wallet : superviseur ne doit pas se recharger lui-même

**Constat** : Superviseur peut voir/traiter sa propre demande. Doit traiter demandes autres agents.

**Actions**
- [ ] `superviseur_rechargement_screen.dart` : filtrer `_demandes` pour exclure demandes émises par utilisateur connecté. Comparer `demandeParUtilisateurId` vs `AuthService.currentUser?.id` ou `AuthService.utilisateurId`.
- [ ] Désactiver actions (confirmer/rejeter) si demande est "self" + tooltip. Ou simplement masquer actions + afficher badge "Ma demande" (readonly).
- [ ] Vérifier accès écran demande rechargement pour rôle superviseur : masquer bouton "Demander rechargement" si rôle superviseur (wallet agent AT).
- [ ] Double garde : si malgré filtrage, empêcher appel API sur self (vérif).

**Fichiers** : `lib/views/screens/superviseur/superviseur_rechargement_screen.dart`, wallet agent screen (si accessible), auth/rôle checks.

## Point 6 - Modules TOP AGENT, MON EQUIPE, Performance (chargement)

**Constat** : Problème affichage/chargement "response body chargé" - semble état/UI.

**Analyse existant**
- Top agents : `superviseur_top_agents_screen.dart` OK (gestion mounted, error, empty).
- Mon équipe : `superviseur_team_screen.dart` + `superviseur_controller.dart` (charge 4 appels en parallèle). 
- Performance/indicateurs : widget `superviseur_indicateurs_section.dart`, chargé par controller.
- Controller : si aucun succès global, construit erreur via `messageForSuperviseurTeamError` - peut masquer cause.

**Actions**
- [ ] Auditer `superviseur_controller.load()` : quand un endpoint échoue partiellement, afficher-t-il données dispo ? Actuellement si `hasAnyData` true -> pas d'erreur (OK). Si tous échouent -> erreur. Cohérent.
- [ ] Vérifier `indicateursResponse.success` mapping (L52-56) OK. 
- [ ] Ajouter logs debug dev-only pour payload brut si nécessaire (sans données sensibles). 
- [ ] Uniformiser états vides + retry. Vérifier shimmer vs spinner cohérents (Top agents utilise spinner, Mon équipe utilise shimmer - OK).
- [ ] Tester cas réseau partiel : s'assurer UI n'affiche pas "loading infini" (finally set isLoading false - OK). 
- [ ] Si "response body chargé" signifie données arrivent mais pas affichées : inspecter bindings (setState monté). Déjà protégé.

**Fichiers** : `superviseur_controller.dart`, `superviseur_team_screen.dart`, `superviseur_top_agents_screen.dart`, `superviseur_indicateurs_section.dart`.

## Point 7 - Formulaire adhésion : retour dans PageView

**Demande utilisateur** : "on annule pas une traction mais plutôt on donne la possibilité de retour dans le pageview du formulaire d'adhésion dans @lib/views/screens/at/new_adhesion_screen.dart"

**Constat** : Déjà boutons Précédent/Suivant gérés (_goToPreviousStep/_goToNextStep). Peut manquer navigation arrière depuis certains états ou UX à améliorer.

**Actions**
- [ ] Vérifier `_goToPreviousStep` (L1269-1273) + `_previousPageIndex` (L1238-1248). Gère skip dépendants OK.
- [ ] S'assurer qu'on peut revenir depuis toutes étapes sans perte données (state conservé - OK controllers + state vars).
- [ ] Ajouter possibilité retour via AppBar back si pas en soumission ? Actuellement back pop écran (L534-542). Confirmer comportement souhaité : "retour dans le pageview" vs quitter. 
- [ ] Peut-être confirmer avant quitter si formulaire modifié (éviter perte). 
- [ ] Tester navigation : étape 4 (dépendants skipped?) vers 2, etc. Cohérent.

**Fichiers** : `lib/views/screens/at/new_adhesion_screen.dart`.

## Validation

- [ ] Lint/typecheck : lancer selon scripts projet (`flutter analyze` si dispo).
- [ ] Tests manuels par point.
- [ ] Non-régression reçus, adhésion, rechargements, superviseur.
- [ ] Vérifier contrats API vs `good_request_body.json`, docs.

## Risques & Mitigations

- **Conversion devise (P2)** : nécessite taux existant -> fallback avec message clair si absent.
- **Propagation reçu (P3)** : toucher plusieurs constructeurs -> risques oubli -> grep exhaustif `CollecteReceiptData(`.
- **Filtrage self (P5)** : mauvais ID -> filtrer trop/peu -> comparer plusieurs champs (userId, agentId, demandeParUtilisateurId).
- **Cotisation annuel (P4)** : changer règle UI peut désaligner API -> vérifier côté serveur message erreur.

## Ordre d'implémentation suggéré

1. Point 3 (reçu + collecteur) - impact large mais isolé modèle/helpers.
2. Point 7 (adhésion retour) - petit UX.
3. Point 5 (rechargement self-filter) - sécurité/UX.
4. Point 6 (superviseur chargement) - robustesse.
5. Point 4 (cotisation) - logique métier.
6. Point 2 (conversion devise) - plus complexe (taux). 
7. Point 1 (annulation adhésion) - selon découverte.

**Plan prêt pour exécution.**