/// Modes de paiement pour les collectes liées à un affilié.
abstract final class AffiliePaymentModes {
  static const virtualAccount = 'VIRTUAL_ACCOUNT';
  static const mobileMoney = 'MOBILE_MONEY';
  static const carteBancaire = 'CARTE_BANCAIRE';

  static const Map<String, String> electronicOnly = {
    mobileMoney: 'Mobile money',
    carteBancaire: 'Carte',
  };

  static const Map<String, String> withVirtualAccount = {
    virtualAccount: 'Compte virtuel',
    mobileMoney: 'Mobile money',
    carteBancaire: 'Carte',
  };

  static Map<String, String> modesFor({required bool allowVirtualAccount}) =>
      allowVirtualAccount ? withVirtualAccount : electronicOnly;

  static String defaultModeFor({required bool allowVirtualAccount}) =>
      allowVirtualAccount ? virtualAccount : mobileMoney;

  static bool isElectronic(String? mode) =>
      mode == mobileMoney || mode == carteBancaire;

  static bool isMobileMoney(String? mode) => mode == mobileMoney;
}
