import 'package:intl/intl.dart';

class AppFormatters {
  
  /// Formate un montant en monnaie (ex: 1250.5 -> $1,250.50)
  static String formatCurrency(double? amount, {String symbol = 'CDF'}) {
    if (amount == null) return '\$0.00';
    
    // Le pattern '#,##0.00' gère les séparateurs de milliers et 2 décimales
    final formatter = NumberFormat('#,##0.00', 'en_US'); 
    return '\$${formatter.format(amount)}';
  }

  /// Formate un montant en dollars (ex: 1250.5 -> $1,250.50)
  static String formatCurrencyDollar(double? amount) {
    if (amount == null) return '\$0.00';
    
    final formatter = NumberFormat('#,##0.00', 'en_US'); 
    return '\$${formatter.format(amount)}';
  }

  /// Formate une date de manière lisible (ex: 2024-03-12 -> 12 Mars 2024)
  static String formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    
    // 'dd MMMM yyyy' donne "12 Mars 2026"
    // 'dd/MM/yyyy' donnerait "12/03/2026"
    return DateFormat('dd MMMM yyyy', 'fr_FR').format(date);
  }

  /// Formate une date avec l'heure (ex: 12 Mars 2024 à 14:30)
  static String formatDateTime(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat("dd MMM yyyy 'à' HH:mm", 'fr_FR').format(date);
  }
  // Formate l'adresse complète
  static String formatAddress(dynamic data) {
    return "${data['numeroResidence'] ?? ''}, Av. ${data['avenueResidence'] ?? ''}, Q/${data['quartierResidence'] ?? ''}, ${data['communeResidence'] ?? ''}";
  }
}