# Recette : corrections suite aux retours de test

Application mobile Prosoc · 5 novembre 2026 · Environnement : **dev**

Ce document reprend les 9 points remontés lors de la dernière recette, le contrôle du compte virtuel hors ligne et les nouvelles opérations hors ligne (point 11). Pour chaque point : ce qui a changé, comment le tester, et le résultat attendu.

Certains points dépendent encore d'un développement backend. Ils sont marqués **⏳ en attente backend** : le comportement attendu décrit ci-dessous est celui de l'application **aujourd'hui**.

## Avant de commencer

1. **Installer la nouvelle version.** À la première ouverture, l'application remet à zéro ses données hors ligne et les recharge. Les opérations hors ligne déjà en attente sont conservées.
2. **Se connecter en ligne** au moins une fois avec chaque compte, avant tout test hors ligne.
3. **Comptes nécessaires** : un Agent (AT), un Percepteur, un Superviseur, et si possible un affilié (membre).
4. **Se déconnecter puis se reconnecter** si des permissions ont été modifiées côté administration : elles sont lues à la connexion.

---

## 1. Adhésion hors ligne

**Corrigé** : hors ligne, le formulaire restait bloqué sur « Frais d'adhésion indisponibles ». Les frais, types d'adhésion et devises sont maintenant chargés depuis les données enregistrées sur l'appareil.

**Tester (compte AT)**

1. En ligne, se connecter et attendre une dizaine de secondes, le temps de la synchronisation.
2. Activer le mode avion.
3. Ouvrir **Nouvelle adhésion** et remplir les étapes.

**Résultat attendu**

- Un bandeau orange indique « Mode hors ligne » avec la date des données.
- Le frais d'adhésion et les types d'adhésion sont affichés.
- Seul le mode de paiement **Compte virtuel** est proposé.
- À la confirmation : « Adhésion enregistrée hors ligne » avec un **n° de suivi**, repris sur le reçu.
- Désactiver le mode avion : le bandeau « écriture(s) en attente » se vide en moins d'une minute et l'affilié apparaît en ligne.

**Cas à vérifier aussi**

- Hors ligne **sans jamais s'être connecté en ligne** sur l'appareil : bandeau rouge demandant de se connecter une fois avant.
- Passer en mode avion **pendant** la saisie, après avoir choisi Mobile Money : le mode bascule automatiquement sur Compte virtuel.

## 2. Compte virtuel vide lors d'une adhésion hors ligne

**Corrigé** : une adhésion par compte virtuel était acceptée hors ligne même avec un solde nul. Le solde est maintenant contrôlé avant tout enregistrement sur l'appareil, en déduisant les opérations déjà en attente.

**Tester (compte AT avec un solde virtuel faible ou nul)**

1. En ligne, se connecter pour synchroniser le solde.
2. Mode avion, puis faire une adhésion dont le frais dépasse le solde virtuel.

**Résultat attendu**

- Message « Solde du compte virtuel insuffisant : X disponible… pour Y à payer ».
- Rien n'est mis en attente.

**Cas à vérifier aussi**

- Deux adhésions hors ligne de suite, chacune inférieure au solde mais dont le total le dépasse : la **deuxième** est refusée, avec la mention du montant déjà engagé.
- Une adhésion refusée par le serveur au retour du réseau (solde modifié entre-temps) : bandeau rouge « opération(s) hors ligne rejetée(s) » avec la raison, jusqu'au bouton **Compris**.

## 3. Rôle affiché dans le profil Percepteur (retour n°6)

**Corrigé** : le profil affichait « Superviseur d'équipe » au lieu de « Percepteur ».

**Tester (compte Percepteur)** : ouvrir **Profil**.

**Résultat attendu** : « Percepteur » sous le nom, dans « Rôle principal » et dans la liste des rôles.

## 4. Demande de retrait agent (retour n°7)

**Corrigé** : l'application remplaçait le montant saisi (10 $) par tout le solde (30 $) à la fin de ses chargements.

**Tester (compte AT, Wallet → Retrait)**

- **Période de retrait total** :
  - le solde est proposé, mais le montant **reste modifiable** ;
  - saisir 10 $ et patienter quelques secondes : le montant **ne change pas** ;
  - valider : la demande créée porte sur **10 $** ;
  - un montant supérieur au solde est refusé.
- **Période de retrait partiel** : saisir 10 $ ; la demande créée porte sur **10 $**, dans la limite du pourcentage maximal affiché.

## 5. Compte virtuel dans « Souscrire à une prestation » (retour n°2)

**Corrigé** : depuis la fiche d'un affilié, le mode Compte virtuel n'était pas proposé.

**Tester (comptes AT et Superviseur, qui disposent d'un compte virtuel)**

1. Ouvrir un affilié : Mon réseau → toucher l'affilié.
2. Menu ⋮ → **Souscrire à une prestation**.
3. Choisir **Compte virtuel** et valider.

**Résultat attendu** : « Compte virtuel » figure dans les modes de paiement, et la souscription est enregistrée et débitée du compte virtuel. Le même comportement existe déjà depuis le menu ⋮ de la liste « Mon réseau ».

Le Percepteur n'a pas de compte virtuel : si ce mode lui est proposé, un refus serveur est attendu. Merci de le signaler si c'est le cas.

## 6. Paiement fractionné de la cotisation (retour n°3)

**Corrigé** : une cotisation peut être payée en plusieurs versements.

**Tester (compte affilié, puis compte AT)**

1. Ouvrir **Payer une cotisation** et choisir le tarif. Sous le montant s'affiche « Maximum payable : … Un versement partiel est possible. »
2. Saisir 5 $ sur 20 $ et payer.
3. Rouvrir l'écran après confirmation du paiement.

**Résultat attendu**

- **Affilié** : « Déjà payé » et « Reste à payer » sont affichés, et le montant proposé est le reste.
- **Agent** : même affichage si la période figure dans les arriérés de l'affilié. Sinon, le montant du tarif est proposé.
- Un montant supérieur au maximum est refusé par l'application.
- Période soldée : message « déjà entièrement payée », aucun nouveau versement possible.
- **Affilié** avec un paiement FlexPay en attente : « Réservé » et « Payable maintenant » sont affichés. Si tout le reste est réservé, l'écran demande de réessayer plus tard.

**Limite côté agent** : l'application ne voit pas toujours les versements du mois en cours. Si le serveur refuse un dépassement, c'est le comportement attendu : son message est affiché.

## 7. Mot de passe oublié (retour n°9) ⏳ en attente backend

**Changement** : le bouton n'avait aucun effet. Il explique maintenant la marche à suivre : contacter le superviseur ou l'administrateur pour obtenir un mot de passe temporaire, à changer à la connexion.

**Tester** : écran de connexion → **Mot de passe oublié ?** Un message d'aide s'affiche.

**Limite** : la réinitialisation en autonomie (code par SMS ou e-mail) attend un nouvel endpoint backend.

## 8. Prestations médicales chez le Percepteur et le Superviseur (retour n°8)

**Corrigé** : ces profils n'avaient aucun accès dédié.

**Où les trouver**

- **Percepteur** : Accueil → service **Médical**.
- **Superviseur** : Accueil → **Prestations médicales**, en bas des actions de supervision.
- **Agent AT** : onglet **Médical** de la barre de navigation, et menu ⋮ d'un affilié → **Couverture médicale**.

**Tester**

1. Onglet **À confirmer**, pour le Percepteur et le Superviseur : les demandes de prise en charge en attente s'affichent. En ouvrir une, puis **Traiter la demande** → Valider ou Rejeter. La demande disparaît de la file.
2. Onglet **Affiliés** : rechercher un affilié, puis ouvrir sa couverture (souscriptions, mois, paiement, prises en charge).
3. Icône **scanner** en haut à droite (comptes ayant le droit de scan) : scanner le QR d'un bon validé, les informations du bon s'affichent.

**Résultat attendu selon le profil**

| Action | AT | Percepteur | Superviseur |
|---|---|---|---|
| Voir la couverture d'un affilié, souscrire, préparer un mois | ✅ | ✅ | ✅ |
| Guichet : compte virtuel | ✅ | ❌ | ✅ |
| Guichet : espèces (caisse ouverte) | ❌ | ✅ | ❌ |
| Guichet : chèque, virement | ✅ | ✅ | ✅ |
| Demander une prise en charge | ✅ | ✅ | ✅ |
| File « À confirmer », valider ou rejeter | ❌ | ✅ | ✅ |
| Scanner un bon | ✅ | ❌ | ✅ |
| **Consommer** un bon | ❌ | ❌ | ❌ |

Le bouton **Consommer le bon** n'apparaîtra chez personne tant que la permission de consommation n'aura pas été attribuée côté backend. C'est normal pour cette recette.

## 9. Affectation d'un affilié à un agent (retour n°5)

**Corrigé** : si la liste des agents ne se chargeait pas, l'écran affichait « Aucun agent disponible » sans explication. L'application utilise maintenant d'abord la liste de l'écran « Mon équipe » et affiche la vraie cause en cas d'échec.

**Tester (compte Superviseur)**

1. Accueil → **Affectation**.
2. Choisir une adhésion en ligne sans gestionnaire → choisir un agent → **Affecter**.

**Résultat attendu** : la liste des agents de l'équipe s'affiche, l'affectation réussit, et le dossier disparaît de la liste.

**Si ça échoue** : noter le message exact affiché. Il indique désormais la cause : équipe non rattachée, permission, etc.

## 10. Souscription médicale et cotisation à jour (retour n°1)

**Corrigé** : la règle porte sur la cotisation de la **période en cours**, entièrement réglée. D'anciens arriérés ne bloquent plus la souscription.

**Tester**

1. Choisir un affilié dont la cotisation du **mois en cours** n'est pas réglée, ou seulement en partie.
2. Couverture médicale → **Souscrire une offre** → choisir une offre → **Souscrire à cette offre**.
3. Refaire le test avec un affilié à jour pour le mois en cours mais ayant d'anciens arriérés.

**Résultat attendu**

- Premier cas : la souscription n'est pas créée. Message « Cotisation à régulariser » avec le montant restant, ou refus du serveur si le mois en cours n'apparaît pas dans les arriérés.
- Second cas : la souscription passe.

Si la souscription passe dans le premier cas, c'est une anomalie à remonter, avec le nom de l'affilié et la date.

## 11. Opérations hors ligne de l'agent

**Nouveau** : hors ligne, l'agent consulte son réseau, encaisse cotisations et frais, et achète une souscription de prestation. Tout passe par le **compte virtuel**.

**Préparer (compte AT)** : en ligne, se connecter et attendre une dizaine de secondes, puis activer le mode avion. Le bandeau hors ligne apparaît en moins d'une minute.

**Tester**

| Écran | Résultat attendu en mode avion |
|---|---|
| **Mon réseau** | Liste des affiliés avec « Données du … ». La recherche fonctionne sur le nom, le matricule et le téléphone. |
| Menu ⋮ d'un affilié | Uniquement **Payer une cotisation**, **Payer un frais** et **Souscrire à une prestation**. |
| **Fiche affilié** | Informations en lecture seule, avec un bandeau rappelant ce qui nécessite une connexion. |
| **Payer une cotisation** | Tarif de l'affilié proposé, seul mode **Compte virtuel**, rappel de contrôler le montant. |
| **Payer un frais** | Frais proposés, seul mode **Compte virtuel**. |
| **Souscrire à une prestation** | Prestations proposées, seul mode **Compte virtuel**. |

Après validation : message « enregistré(e) hors ligne », sans reçu définitif, et le compteur « en attente » augmente.

**Au retour du réseau** : la file se vide en moins d'une minute, les opérations apparaissent côté serveur et le solde virtuel se réaligne.

**Cas à vérifier aussi**

- Solde insuffisant : opération refusée sur l'appareil, rien n'est mis en attente.
- Acheter deux fois la même prestation pour le même affilié : la seconde est refusée sur l'appareil.
- Fermer l'application pendant l'envoi, puis la rouvrir : l'opération repart, sans doublon côté serveur.
- Opération refusée par le serveur au retour du réseau : bandeau rouge avec la raison.
- Première **adhésion** : vérifier que le sexe est accepté et bien enregistré, en ligne comme hors ligne.

---

## Comment remonter un problème

Pour chaque anomalie, merci d'indiquer :
- le **compte** utilisé (rôle) et l'**heure** du test ;
- le **numéro du point** dans ce document ;
- une **capture d'écran** du message affiché ;
- pour le hors ligne : si le mode avion était activé, et le **n° de suivi** de l'opération.
