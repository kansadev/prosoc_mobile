DOCUMENT QA — DEMANDES DE CORRECTIONS ET ÉVOLUTIONS FONCTIONNELLES
Application : PROSOC
Périmètre : Application Mobile
Destinataire : Équipe Développement Mobile
Rédigé par : QA / Test & Validation
Objet : Corrections fonctionnelles, améliorations UX et nouvelles fonctionnalités
________________________________________
1. AGENT AT
1.1 Adhésion — Vérification de l’âge du conjoint(e)
Constat :
Lors de l’adhésion, une vérification empêche l’enregistrement lorsque le conjoint(e) est plus âgé(e) que l’affilié.
Comportement actuel :
Le système affiche un message du type :
« Le dépend ne peut pas être âgé que l’affilié. »
Demande :
Retirer cette règle de contrôle sur l’âge du conjoint(e).
Résultat attendu :
L’agent AT doit pouvoir enregistrer un conjoint(e) quel que soit son âge par rapport à celui de l’affilié.
________________________________________
1.2 Adhésion — Ajout du sexe de l’affilié
Demande :
Ajouter le champ Sexe dans les informations de l’affilié.
Périmètre :

	API
	Application mobile
	Formulaire d’adhésion
	Consultation / modification du profil

Résultat attendu :
Le sexe renseigné lors de l’adhésion doit être correctement :
envoyé par le mobile ;
accepté et enregistré par l’API ;
retourné lors de la consultation de l’affilié ;
affiché dans le profil.
________________________________________
1.3 Impression du reçu — Adhésion et cotisation
Demande :
Ajouter la possibilité d'imprimer ou de générer un reçu après :
une nouvelle adhésion ;
une cotisation.

Résultat attendu :
Après validation de l’opération, l’utilisateur doit pouvoir accéder au reçu correspondant.
Le reçu devrait notamment contenir les informations essentielles :

numéro/référence de l’opération ;
nom de l’affilié ;
type d’opération ;
montant ;
date et heure ;
agent ayant effectué l’opération ;
référence de paiement, si disponible.
________________________________________
1.4 Adhésion — Antécédents médicaux
Demande :
Retirer le champ / la section Antécédents médicaux du processus d’adhésion.
Résultat attendu :
Le champ ne doit plus apparaître dans l’application mobile et ne doit plus être obligatoire pour finaliser une adhésion.
________________________________________
1.5 Indicateurs de performance — Target
Constat :
Les objectifs (targets) doivent être disponibles sur plusieurs périodes.
Demande :
Ajouter les targets suivants :
Target journalier ;
Target hebdomadaire ;
Target mensuel, si déjà prévu dans le système.
Carte de performance
Ajouter une carte permettant de visualiser clairement :
objectif en nombre d’adhésions ;
objectif financier ;
réalisation actuelle ;
progression par rapport à l’objectif.

Exemple :
Target : 50 adhésions
Équivalent : 500 $
La carte peut également afficher :
35 / 50 adhésions réalisées
350 $ / 500 $ réalisés
Résultat attendu :
L’agent AT doit pouvoir comprendre rapidement son niveau de réalisation par rapport à son objectif.
________________________________________
1.6 Tableau de bord — Commissions
Constat :
Le tableau de bord affiche actuellement deux indicateurs :

Commission
Solde commission
Leur différence n’est pas suffisamment claire.
Demande :
Clarifier la signification et l’utilisation de ces deux indicateurs.
Proposition fonctionnelle à valider avec le métier :

Commission : montant total des commissions générées / acquises.
Solde commission : montant de commission actuellement disponible ou restant après les retraits/paiements effectués.
Résultat attendu :
Les deux indicateurs doivent avoir une définition fonctionnelle claire et être cohérents avec les données affichées dans le détail des commissions.
________________________________________
1.7 Wallet — Demande de rechargement
Demande :
Ajouter la fonctionnalité permettant à l’agent AT d’effectuer une demande de rechargement de son wallet.
Parcours attendu :
1.	L’agent accède a son wallet
2.	Il sélectionne « Demander un rechargement ».
3.	Il renseigne le montant.
4.	Il confirme la demande.
5.	La demande est transmise au responsable concerné.
6.	Le statut de la demande est visible.
Statuts suggérés :
	En attente ;
	Approuvée ;
	Rejetée ;
	Traitée.
________________________________________
2. RÔLE AFFILIÉ
2.1 Module Cotisation — Historique des cotisations
Constat :
Le module Cotisation n’affiche pas les cotisations enregistrées pour l’affilié.
Résultat attendu :
L’affilié doit pouvoir consulter ses cotisations avec, au minimum :
	montant ;
	date ;
	période concernée ;
	référence de paiement ;
	statut ;
	moyen de paiement, si disponible.

Cas de test :
	Affilié avec une cotisation enregistrée → la cotisation doit apparaître.
	Affilié avec plusieurs cotisations → toutes les cotisations doivent être visibles.
	Affilié sans cotisation → afficher un état vide explicite.

________________________________________
2.2 Profil affilié — Contact de l’Agent AT
Demande :
Ajouter dans le profil de l’affilié les coordonnées de son Agent AT.
Informations proposées :
	Téléphone ;
	Email, si disponible.

Résultant attendu :
L’affilié doit pouvoir identifier et contacter facilement son Agent AT.
________________________________________
2.3 Profil affilié — Personnes à charge
Constat :
Le nombre de personnes à charge enregistrées doit être reflété dans le profil de l’affilié.
Demande :
Afficher le nombre réel de personnes enregistrées comme personnes à charge.
Exemple :
Personnes à charge : 3
Si 3 personnes sont enregistrées, le profil doit afficher 3 et non une valeur fixe ou incorrecte.
________________________________________
3. CHEF D’ÉQUIPE
3.1 Résumé des collectes des agents
Demande :
Permettre au Chef d’équipe de consulter le résumé des collectes réalisées par les agents de son équipe.
Périodes disponibles :

	Journalier ;
	Hebdomadaire ;
	Mensuel.
Informations à afficher :

	Agent 
	Nombre de collectes ;
	Montant collecté ;
	Période ;
	Total de l’équipe.
Résultat attendu :
Le Chef d’équipe doit pouvoir suivre rapidement les performances de collecte de son équipe selon la période sélectionnée.
________________________________________
4. PERCEPTEUR
4.1 Collecte hebdomadaire
Demande :
Ajouter la possibilité de consulter la collecte sur une période hebdomadaire.
Résultat attendu :
Le Percepteur doit pouvoir consulter le total collecté par semaine et, si nécessaire, le détail des opérations correspondant à cette période.
________________________________________
4.2 Encaissement Agent — Erreur « Non autorisé »
Constat :
Dans le module Encaissement Agent, lorsqu’on clique sur un agent, l’application retourne le message :
« Non autorisé »
Résultat attendu :
L’utilisateur disposant des droits nécessaires doit pouvoir accéder au détail de l’agent sans recevoir l’erreur « Non autorisé ».
À vérifier côté QA :
	Permissions du rôle Percepteur ;
	Autorisations API ;
	Token / authentification ;
	Endpoint appelé ;
	Contrôle d’accès côté backend ;
	Gestion des droits côté mobile.

________________________________________
5. SUPERVISEUR
5.1 Gestion des Chefs d’équipe
	Demande :
Permettre au Superviseur de gérer les Chefs d’équipe.
	Le Superviseur doit notamment pouvoir :
	consulter les Chefs d’équipe ;
	sélectionner un Chef d’équipe ;
	consulter les agents rattachés à ce Chef d’équipe ;
	consulter les activités des agents ;
	consulter les résultats / collectes de l’équipe.
Exemple de parcours
Superviseur → Chef d’équipe X → Agents → Activités
	Pour chaque agent, les informations pertinentes peuvent inclure :
	nombre d’adhésions ;
	nombre de cotisations ;
	montant collecté ;
	activité journalière ;
	activité hebdomadaire ;
	activité mensuelle.
________________________________________
5.2 Affectation des affiliés
Demande :
Permettre au Superviseur d’affecter un affilié à un agent / responsable selon les règles métier définies.
Résultat attendu :

	Le Superviseur sélectionne un affilié.
	Il sélectionne l’agent ou le responsable destinataire.
	Il confirme l’affectation.
	L’affectation est enregistrée.
	Le nouvel agent responsable apparaît dans le profil de l’affilié.
Contrôles à prévoir :
	Vérification des droits du Superviseur ;
	Confirmation avant affectation ;
	Traçabilité de l’affectation ;
	Mise à jour immédiate du profil de l’affilié ;
	Gestion d’une éventuelle réaffectation.
