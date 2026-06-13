/// Fenêtres de retrait agent : du 15 au 20, et à partir du 30 de chaque mois.
class WithdrawalWindowHelper {
  WithdrawalWindowHelper._();

  static bool isOpen([DateTime? date]) {
    final day = (date ?? DateTime.now()).day;
    return (day >= 15 && day <= 20) || day >= 30;
  }

  static String statusLabel([DateTime? date]) {
    final now = date ?? DateTime.now();
    if (isOpen(now)) {
      return 'Fenêtre de retrait ouverte';
    }
    return 'Fenêtre de retrait fermée';
  }

  static String statusDescription([DateTime? date]) {
    final now = date ?? DateTime.now();
    if (isOpen(now)) {
      return 'Vous pouvez soumettre une demande de retrait aujourd\'hui.';
    }
    return 'Les retraits ne sont autorisés que du 15 au 20 '
        'et à partir du 30 de chaque mois. '
        'Jour actuel : ${now.day}.';
  }

  static String nextWindowHint([DateTime? date]) {
    final now = date ?? DateTime.now();
    if (isOpen(now)) return '';

    final day = now.day;
    if (day < 15) {
      return 'Prochaine ouverture : le 15 ${ _monthName(now.month) }.';
    }
    if (day < 30) {
      return 'Prochaine ouverture : le 30 ${ _monthName(now.month) }.';
    }
    return 'Prochaine ouverture : le 15 ${ _monthName(now.month == 12 ? 1 : now.month + 1) }.';
  }

  static String _monthName(int month) {
    const names = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    if (month < 1 || month > 12) return '';
    return names[month - 1];
  }
}
