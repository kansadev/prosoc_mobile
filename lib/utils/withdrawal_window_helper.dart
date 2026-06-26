/// Fenêtres de retrait agent : quinzaine (15–20) et 5 derniers jours du mois.
class WithdrawalWindowHelper {
  WithdrawalWindowHelper._();

  static bool isQuinzaine([DateTime? date]) {
    final day = (date ?? DateTime.now()).day;
    return day >= 15 && day <= 20;
  }

  static bool isLastFiveDaysOfMonth([DateTime? date]) {
    final now = date ?? DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    return now.day >= lastDay - 4;
  }

  static bool isOpen([DateTime? date]) {
    return isQuinzaine(date) || isLastFiveDaysOfMonth(date);
  }

  static String statusLabel([DateTime? date]) {
    if (isOpen(date)) {
      return 'Fenêtre de retrait ouverte';
    }
    return 'Fenêtre de retrait fermée';
  }

  static String statusDescription([DateTime? date]) {
    final now = date ?? DateTime.now();
    if (isOpen(now)) {
      if (isQuinzaine(now) && isLastFiveDaysOfMonth(now)) {
        return 'Période de quinzaine et fin de mois : vous pouvez soumettre '
            'une demande de retrait aujourd\'hui.';
      }
      if (isQuinzaine(now)) {
        return 'Période de quinzaine (15–20) : vous pouvez soumettre '
            'une demande de retrait aujourd\'hui.';
      }
      return 'Fin de mois (5 derniers jours) : vous pouvez soumettre '
          'une demande de retrait aujourd\'hui.';
    }
    return 'Les retraits sont autorisés du 15 au 20 (quinzaine) et durant '
        'les 5 derniers jours du mois. Jour actuel : ${now.day}.';
  }

  static String nextWindowHint([DateTime? date]) {
    final now = date ?? DateTime.now();
    if (isOpen(now)) return '';

    final day = now.day;
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final lastFiveStart = lastDay - 4;

    if (day < 15) {
      return 'Prochaine ouverture : le 15 ${_monthName(now.month)}.';
    }
    if (day < lastFiveStart) {
      return 'Prochaine ouverture : le $lastFiveStart ${_monthName(now.month)} '
          '(5 derniers jours du mois).';
    }

    final nextMonth = now.month == 12 ? 1 : now.month + 1;
    return 'Prochaine ouverture : le 15 ${_monthName(nextMonth)}.';
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
