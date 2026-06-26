import 'package:intl/intl.dart';

/// Formatage des montants Prosoc par devise.
///
/// - USD : `$200.00`
/// - CDF : `200 CDF`
abstract final class CurrencyFormatter {
  static const int cdfDeviseId = 1;
  static const int usdDeviseId = 2;

  static final NumberFormat _usdFormatter = NumberFormat('#,##0.00', 'en_US');
  static final NumberFormat _cdfFormatter = NumberFormat('#,##0', 'en_US');

  static bool isUsd({int? deviseId, String? deviseCode}) {
    final code = deviseCode?.trim().toUpperCase();
    if (code == 'USD') return true;
    if (code == 'CDF') return false;
    return deviseId == usdDeviseId;
  }

  static String formatUsd(num? amount) {
    if (amount == null) return r'$0.00';
    return '\$${_usdFormatter.format(amount)}';
  }

  static String formatCdf(num? amount) {
    if (amount == null) return '0 CDF';
    return '${_cdfFormatter.format(amount)} CDF';
  }

  static String format({
    required num? amount,
    int? deviseId,
    String? deviseCode,
    String? deviseSymbole,
    bool withSign = false,
  }) {
    if (amount == null) {
      return isUsd(deviseId: deviseId, deviseCode: deviseCode)
          ? r'$0.00'
          : '0 CDF';
    }

    final sign = withSign
        ? (amount > 0 ? '+' : amount < 0 ? '-' : '')
        : '';
    final absolute = amount.abs();

    if (isUsd(deviseId: deviseId, deviseCode: deviseCode)) {
      return '$sign${formatUsd(absolute)}';
    }

    return '$sign${formatCdf(absolute)}';
  }

  /// Affiche le montant tel que renvoyé par l'API, sans arrondi [NumberFormat].
  static String formatMovementAmount({
    required num amount,
    int? deviseId,
    String? deviseCode,
    String? deviseSymbole,
    bool withSign = false,
  }) {
    final sign = withSign
        ? (amount > 0 ? '+' : amount < 0 ? '-' : '')
        : '';
    final absolute = amount.abs();
    final amountText = _rawAmountString(absolute);

    if (isUsd(deviseId: deviseId, deviseCode: deviseCode)) {
      final symbole = deviseSymbole?.trim();
      final prefix = (symbole != null && symbole.isNotEmpty) ? symbole : r'$';
      return '$sign$prefix$amountText';
    }

    final code = deviseCode?.trim();
    final suffix = (code != null && code.isNotEmpty)
        ? code.toUpperCase()
        : 'CDF';
    return '$sign$amountText $suffix';
  }

  static String _rawAmountString(num value) {
    final text = value.toString();
    if (text.contains('e') || text.contains('E')) {
      return value
          .toStringAsFixed(12)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    }
    return text;
  }
}
