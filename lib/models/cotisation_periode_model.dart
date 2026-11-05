import 'arriere_affilie_model.dart';

/// Résumé d'une période de cotisation : versements cumulés et reste payable.
///
/// Source : `GET /api/arrieres-affilie/mes-cotisations/{id}/periode/{mois}/{annee}`
/// (membre connecté uniquement) ; pour un agent, les arriérés de l'affilié via
/// [depuisArrieres].
class ResumePeriodeCotisation {
  final int affilieId;
  final int cotisationAffilieId;
  final int mois;
  final int annee;
  final String periodicite;
  final double montantAttendu;
  final double montantPaye;
  final double restAPayer;
  final double montantReserve;
  final double resteDisponible;
  final int deviseId;
  final String deviseCode;
  final String statutPaiement;
  final bool estCompletementPaye;

  const ResumePeriodeCotisation({
    required this.affilieId,
    required this.cotisationAffilieId,
    required this.mois,
    required this.annee,
    this.periodicite = '',
    required this.montantAttendu,
    required this.montantPaye,
    required this.restAPayer,
    this.montantReserve = 0,
    required this.resteDisponible,
    required this.deviseId,
    this.deviseCode = '',
    this.statutPaiement = '',
    required this.estCompletementPaye,
  });

  factory ResumePeriodeCotisation.fromJson(Map<String, dynamic> json) {
    dynamic champ(String nom) =>
        json[nom] ?? json['${nom[0].toUpperCase()}${nom.substring(1)}'];
    double montant(String nom) {
      final v = champ(nom);
      return v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;
    }

    int entier(String nom) {
      final v = champ(nom);
      return v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;
    }

    return ResumePeriodeCotisation(
      affilieId: entier('affilieId'),
      cotisationAffilieId: entier('cotisationAffilieId'),
      mois: entier('mois'),
      annee: entier('annee'),
      periodicite: '${champ('periodicite') ?? ''}',
      montantAttendu: montant('montantAttendu'),
      montantPaye: montant('montantPaye'),
      restAPayer: montant('restAPayer'),
      montantReserve: montant('montantReserve'),
      resteDisponible: montant('resteDisponible'),
      deviseId: entier('deviseId'),
      deviseCode: '${champ('deviseCode') ?? ''}',
      statutPaiement: '${champ('statutPaiement') ?? ''}',
      estCompletementPaye: champ('estCompletementPaye') == true,
    );
  }

  /// Écran agent : la route `mes-cotisations` lui est interdite. Les arriérés
  /// ne connaissent pas les paiements FlexPay en attente : le reste payable est
  /// donc le reste comptable, et le serveur tranche à l'envoi.
  static ResumePeriodeCotisation? depuisArrieres(
    List<ArriereAffilieModel> arrieres, {
    required int cotisationAffilieId,
    required int mois,
    required int annee,
  }) {
    for (final a in arrieres) {
      if (a.cotisationAffilieId != cotisationAffilieId ||
          a.mois != mois ||
          a.annee != annee) {
        continue;
      }
      return ResumePeriodeCotisation(
        affilieId: a.affilieId,
        cotisationAffilieId: cotisationAffilieId,
        mois: mois,
        annee: annee,
        periodicite: a.periodicite,
        montantAttendu: a.montantAttendu,
        montantPaye: a.montantPaye,
        restAPayer: a.restAPayer,
        resteDisponible: a.restAPayer,
        deviseId: a.deviseId,
        statutPaiement: a.statutPaiement,
        estCompletementPaye: a.estCompletementPaye,
      );
    }
    return null;
  }

  bool get estSoldee => estCompletementPaye || restAPayer <= 0;

  /// Il reste à payer, mais tout est réservé par des paiements en attente.
  bool get estEntierementReservee => !estSoldee && resteDisponible <= 0;

  /// Message empêchant un nouveau versement, ou `null`.
  String? get messageBlocage {
    if (estSoldee) {
      return 'La cotisation de cette période est déjà entièrement payée.';
    }
    if (estEntierementReservee) {
      return 'Le reste de cette période est réservé par un paiement en '
          'attente. Réessayez après sa confirmation ou son expiration.';
    }
    return null;
  }
}
