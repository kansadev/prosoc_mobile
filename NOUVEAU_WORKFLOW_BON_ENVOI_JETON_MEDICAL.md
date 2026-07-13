# Nouveau Workflow : Bon d'envoi lie au Jeton Medical

## Objectif

Documenter le nouveau workflow backend ou le `BonEnvoi` et le `JetonMedical` sont crees et utilises comme un couple coherent.

Regles cibles :
- Un bon ne doit pas exister sans jeton lie.
- Le point d'entree metier de creation du couple est la confirmation de `DemandeBonEnvoi`.
- Les creations standalone (`POST /api/BonEnvoi`, `POST /api/JetonMedical`) sont desactivees.

## Flux metier principal

1. Un utilisateur cree une `DemandeBonEnvoi` (`EN_ATTENTE`).
2. Un agent confirme la demande via `POST /api/DemandeBonEnvoi/{id}/confirmer`.
3. Le backend execute une transaction atomique :
   - creation du `JetonMedical`,
   - creation du `BonEnvoi` avec `JetonMedicalId`,
   - generation QR du bon,
   - mise a jour de la demande (`VALIDEE`, `BonEnvoiId`, `JetonMedicalId`).
4. Les usages cote hopital verifient desormais la coherence du couple.

## Endpoints impactes

### Creation du couple (autorisee)
- `POST /api/DemandeBonEnvoi/{id}/confirmer`
- `POST /api/DemandeBonEnvoi/valider-et-generer` (legacy qui passe par le meme workflow)

### Creation standalone (desactivee)
- `POST /api/BonEnvoi` -> retourne `400` avec message de transition
- `POST /api/JetonMedical` -> retourne `400` avec message de transition

### Utilisation/controle
- `POST /api/BonEnvoi/scanner`
  - refuse le scan si le jeton lie est introuvable, invalide, expire ou deja utilise.
- `POST /api/JetonMedical/utiliser`
  - refuse l'utilisation si aucun bon actif n'est lie au jeton.

## Evolution du modele

### BonEnvoi
- Ajout de `JetonMedicalId`.
- Navigation vers `JetonMedical`.

### JetonMedical
- Navigation inverse `BonEnvoiLie`.

### EF Core
- Relation 1-1 configuree en Fluent API.
- Index unique sur `BonsEnvoi.JetonMedicalId`.

## Strategie de deploiement (2 releases)

## Release 1 (compatibilite)
- Ajout colonne nullable `JetonMedicalId` sur `BonsEnvoi`.
- Backfill depuis `DemandesBonEnvoi`.
- Ajout index unique + FK.
- Activation du nouveau workflow transactionnel.
- Blocage des creations standalone.

Script prod :
- `sql/MigrateBonEnvoiJetonMedicalLinkR1.idempotent.sql`

## Release 2 (durcissement)
- Passage de `BonsEnvoi.JetonMedicalId` en `NOT NULL`.
- Abort si donnees incoherentes encore presentes (bons sans jeton).

Script prod :
- `sql/MigrateBonEnvoiJetonMedicalLinkR2.idempotent.sql`

## Contrats API (lecture)

Les DTOs exposent le lien :
- `BonEnvoiReadDto`: `JetonMedicalId`, `JetonMedicalCode`
- `JetonMedicalReadDto`: `BonEnvoiId`, `BonEnvoiNumero`

## Impacts QA

Cas a tester en priorite :
1. Confirmation demande -> creation du couple lie + demande `VALIDEE`.
2. Echec intermediaire -> rollback transactionnel (pas de creation partielle).
3. `POST /api/BonEnvoi` et `POST /api/JetonMedical` -> rejet.
4. Scan bon avec jeton invalide/expire/utilise -> rejet.
5. Utilisation jeton sans bon actif lie -> rejet.
6. Migration R1 puis R2 sur base pre-existante.

## Verifications SQL post-deploiement

Apres R1 :
- `SELECT COUNT(*) FROM BonsEnvoi WHERE JetonMedicalId IS NULL;`
- `SELECT JetonMedicalId, COUNT(*) FROM BonsEnvoi WHERE JetonMedicalId IS NOT NULL GROUP BY JetonMedicalId HAVING COUNT(*) > 1;`

Apres R2 :
- `SELECT COUNT(*) FROM BonsEnvoi WHERE JetonMedicalId IS NULL;` attendu `0`

## Notes d'exploitation

- Forcer la reconnexion des utilisateurs si adaptation des permissions/claims attendue.
- Surveiller les logs de confirmation de demande et les erreurs de validation scan/use pendant la phase de transition.
