/// Données d'un reçu de collecte généré côté frontend.
enum CollecteReceiptOperation {
  adhesion,
  encaissement,
  souscription,
  cotisation,
  frais,
}

extension CollecteReceiptOperationLabel on CollecteReceiptOperation {
  String get label => switch (this) {
        CollecteReceiptOperation.adhesion => 'Adhésion',
        CollecteReceiptOperation.encaissement => 'Encaissement',
        CollecteReceiptOperation.souscription => 'Souscription',
        CollecteReceiptOperation.cotisation => 'Cotisation',
        CollecteReceiptOperation.frais => 'Frais',
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
    this.idCollecte,
    this.idAdhesion,
    this.statutPaiement,
    this.observation,
    DateTime? date,
    this.extras = const {},
  }) : date = date ?? DateTime.now();

  String get title => 'Reçu — ${operation.label}';

  String get numeroRecu {
    final ts = date.millisecondsSinceEpoch.toString();
    final suffix = ts.length > 8 ? ts.substring(ts.length - 8) : ts;
    return 'RCU-$suffix';
  }
}
