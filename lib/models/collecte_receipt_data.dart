/// Données d'un reçu de collecte généré côté frontend.
enum CollecteReceiptOperation {
  adhesion,
  encaissement,
  souscription,
  cotisation,
  frais,
  prestationMedicale,
}

extension CollecteReceiptOperationLabel on CollecteReceiptOperation {
  String get label => switch (this) {
        CollecteReceiptOperation.adhesion => 'Adhésion',
        CollecteReceiptOperation.encaissement => 'Encaissement',
        CollecteReceiptOperation.souscription => 'Souscription',
        CollecteReceiptOperation.cotisation => 'Cotisation',
        CollecteReceiptOperation.frais => 'Frais',
        CollecteReceiptOperation.prestationMedicale => 'Prestation médicale',
      };
}

class CollecteReceiptData {
  final CollecteReceiptOperation operation;
  final double montant;
  final String? deviseCode;
  final int? deviseId;
  final String? reference;
  final String? modePaiement;
  final String? affilieNom;
  final String? codeAdhesion;
  final String? agentNom;
  final String? collecteurNom;
  final int? agentId;
  final int? idCollecte;
  final int? idAdhesion;
  final String? statutPaiement;
  final String? observation;
  final DateTime date;
  final Map<String, String> extras;

  CollecteReceiptData({
    required this.operation,
    required this.montant,
    this.deviseCode,
    this.deviseId,
    this.reference,
    this.modePaiement,
    this.affilieNom,
    this.codeAdhesion,
    this.agentNom,
    this.collecteurNom,
    this.agentId,
    this.idCollecte,
    this.idAdhesion,
    this.statutPaiement,
    this.observation,
    DateTime? date,
    this.extras = const {},
  }) : date = date ?? DateTime.now();

  String get _collecteurDisplay =>
      (collecteurNom?.trim().isNotEmpty == true
          ? collecteurNom!.trim()
          : (agentNom?.trim().isNotEmpty == true ? agentNom!.trim() : ''));

  String get title => 'Reçu  ${operation.label}';

  String get agentCollecteur => _collecteurDisplay;

  String get numeroRecu {
    final ts = date.millisecondsSinceEpoch.toString();
    final suffix = ts.length > 8 ? ts.substring(ts.length - 8) : ts;
    return 'RCU-$suffix';
  }
}
