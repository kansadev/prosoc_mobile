# Retours de recette : points à traiter côté backend

Date : 3 novembre 2026, mis à jour le 5 novembre 2026 après réception de `FRONTEND_INTEGRATION_RETOURS_RECETTE.md` · Application mobile Prosoc (Flutter) · Complète [RAPPORT_BACKEND_OFFLINE_ADHESION.md](./RAPPORT_BACKEND_OFFLINE_ADHESION.md)

La recette a remonté 9 anomalies. Celles qui venaient de l'application sont corrigées et listées en fin de document pour information. Les points ci-dessous indiquent ce qui est intégré et ce qui demande encore une action ou une confirmation backend.

## 1. Paiement fractionné de la cotisation : intégré, une route manque pour les agents

Votre guide est intégré. L'app accepte un versement inférieur au reste, recharge le résumé après FlexPay et après un refus.

- **Membre connecté** : résumé lu sur `GET /api/arrieres-affilie/mes-cotisations/{id}/periode/{mois}/{annee}`, plafond sur `resteDisponible`.
- **Agent** : cette route ne lui est pas ouverte. L'app utilise la ligne des arriérés de l'affilié pour le même tarif et la même période, sinon le tarif.

**Limite** : les arriérés ne donnent pas `montantReserve`, et le mois courant peut en être absent. Un agent peut donc voir un maximum trop élevé ; l'API refuse alors le dépassement, et l'app affiche ce refus.

**À prévoir côté API** : une route agent pour le résumé de période, par exemple `GET /api/arrieres-affilie/affilie/{affilieId}/cotisations/{id}/periode/{mois}/{annee}`, limitée au périmètre de l'agent.

## 2. Mot de passe oublié : endpoint à créer

Votre guide indique que les routes actuelles renvoient le token dans la réponse et révèlent si un compte existe. L'app ne les utilise donc pas.

L'app affiche pour l'instant la marche à suivre (contacter le superviseur ou l'administrateur).

**Proposition de contrat :**
- `POST /api/Utilisateur/mot-de-passe-oublie` avec `{ "emailOuTelephone": "…" }` → envoi d'un code à usage unique (SMS ou e-mail). La réponse doit être identique que le compte existe ou non ;
- `POST /api/Utilisateur/reinitialiser-mot-de-passe` avec `{ "emailOuTelephone", "code", "nouveauMotDePasse" }`.

## 3. Souscription médicale et cotisation à jour : intégré

Votre guide confirme que `POST /api/SouscriptionMedicale` contrôle la cotisation de la **période courante**, versements cumulés. Le contrôle préalable de l'app ne porte plus que sur cette période : d'anciens arriérés ne bloquent plus. Si le mois courant est absent des arriérés, seul le serveur le contrôle, et son message de refus est affiché tel quel.

**À vérifier en recette** : la règle est bien active sur dev (la souscription passait auparavant pour un affilié qui n'était pas en ordre).

## 4. Retrait agent en période TOTAL : erreur d'analyse corrigée, règle à confirmer

**Correction de notre précédente analyse.** Nous avions écrit que le serveur retirait tout le solde. Votre guide précise au contraire que le serveur retient `montantDemande` et ignore `typeRetrait`. Le « 30 $ au lieu de 10 $ » venait de l'app, qui réécrivait le montant saisi à la fin de ses chargements.

**Dans l'app** : le solde est proposé une seule fois, le montant reste modifiable et n'est plus jamais écrasé. Il est plafonné au solde disponible.

**À confirmer** : cet affichage de `typeRetraitAutorise = TOTAL` comme simple proposition est-il la règle métier attendue ? L'équipe a choisi le montant libre en attendant, et un refus serveur reste affiché.

## 5. Agents d'un superviseur : hiérarchie en priorité

L'app charge désormais l'équipe avec `GET /api/Superviseur/hierarchie/{id}`, comme le prévoit votre guide. `GET /api/Agents/by-superviseur/{id}` ne sert plus qu'en repli. Les refus de périmètre sont affichés.

**À vérifier en recette** : `PUT /api/Agent/{agentId}/affecter-affilies` accepte chaque agent remonté par la hiérarchie sur l'environnement cible.

## 6. Permissions médicales des profils terrain

D'après les réponses de login de dev :

| Profil | Permissions médicales présentes | Manquantes pour le parcours prévu |
|---|---|---|
| Agent (AT) | `CREATE_COLLECTE`, `READ_SOUSCRIPTION_PRESTATION`, `CREATE/READ_DEMANDE_BON_ENVOI`, `SCAN_BON_ENVOI` | `USE_JETON_MEDICAL` (consommer un bon) |
| Percepteur | `CREATE_COLLECTE`, `READ_SOUSCRIPTION_PRESTATION`, `CREATE/READ/CONFIRM_DEMANDE_BON_ENVOI` | `SCAN_BON_ENVOI`, `USE_JETON_MEDICAL` ; `READ_SYNC` / `WRITE_SYNC` s'il doit travailler hors ligne |
| Superviseur | `CREATE_COLLECTE`, `READ_SOUSCRIPTION_PRESTATION`, `CREATE/READ/CONFIRM_DEMANDE_BON_ENVOI`, `SCAN_BON_ENVOI`, `READ_SYNC`, `WRITE_SYNC` | `USE_JETON_MEDICAL` |

Aucun rôle mobile n'a `USE_JETON_MEDICAL` : la consommation d'un bon est donc impossible depuis l'application.

**À confirmer** : qui consomme les bons au moment du soin, et à quels rôles attribuer les permissions manquantes.

## 7. Libellés de rôles

Votre seed indique désormais « Agent percepteur » pour le rôle 7. L'app affiche le **nom** du rôle, sur les profils percepteur et agent.

**À vérifier** : la mise à jour de données a bien été exécutée sur chaque environnement.

---

## Corrections faites côté application (pour information)

| # | Anomalie | Correction |
|---|---|---|
| 2 | Pas de compte virtuel dans « Souscrire à une prestation » | Mode proposé depuis la fiche affilié pour tout le personnel |
| 4 | Hors ligne bloqué sur frais / types | Cold start sans `since`, deltas fusionnés, parsing tolérant (voir rapport offline) |
| 4 bis | Adhésion hors ligne acceptée avec un compte virtuel vide | Contrôle du solde avant **toute** mise en file, opérations en attente déduites, wallets stockés par agent et par devise |
| 3 | Cotisation non payable en plusieurs fois | Versements partiels, résumé de période et plafond (voir point 1) |
| 5 | Affectation impossible | Hiérarchie en priorité et message d'erreur explicite (voir point 5) |
| 6 | Profil percepteur affiché « Superviseur » | Affichage du nom du rôle (voir point 7) |
| 7 | Retrait de 10 $ transformé en 30 $ | Montant saisi conservé et envoyé tel quel (voir point 4) |
| 8 | Pas de prestations médicales chez le percepteur / superviseur | Accès « Médical » sur leur accueil : file `PriseEnChargeMedicale/en-attente`, recherche d'affiliés, scan |
| 9 | « Mot de passe oublié » sans effet | Marche à suivre affichée en attendant l'endpoint (voir point 2) |
