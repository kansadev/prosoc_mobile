import '../utils/currency_formatter.dart';
import 'offline_database.dart';

/// Contrôle local du compte virtuel avant de mettre une écriture en file.
///
/// Le serveur reste juge au batch (`SOLDE_INSUFFISANT`) ; ce contrôle évite
/// d'accepter hors ligne une opération qu'on sait déjà impossible :
/// solde synchronisé, moins les débits déjà en attente dans la file.
abstract final class OfflineWalletCheck {
  /// Message bloquant, ou `null` si l'opération peut être mise en file.
  static String? verifier({
    required int agentId,
    required Map<int, double> debits,
  }) {
    final aDebiter = {
      for (final e in debits.entries)
        if (e.value > 0) e.key: e.value,
    };
    if (aDebiter.isEmpty) return null;

    final wallets = OfflineDatabase.wallets
        .where((w) => w.agentId == agentId && w.statut)
        .toList();
    if (wallets.isEmpty) {
      return 'Solde du compte virtuel inconnu sur cet appareil. '
          'Connectez-vous une fois pour synchroniser avant d\'encaisser hors '
          'ligne.';
    }

    final enAttente = OfflineDatabase.debitsEnAttente(agentId);
    for (final entry in aDebiter.entries) {
      final wallet = wallets
          .where((w) => w.deviseId == entry.key)
          .firstOrNull;
      String fmt(double v) => CurrencyFormatter.format(
        amount: v,
        deviseId: entry.key,
        deviseCode: wallet?.deviseCode,
      );
      if (wallet == null) {
        return 'Aucun compte virtuel synchronisé dans la devise de cette '
            'opération (${fmt(entry.value)}). Synchronisez en ligne ou payez '
            'dans une autre devise.';
      }
      final dejaEngage = enAttente[entry.key] ?? 0;
      final disponible = wallet.soldeVirtuel - dejaEngage;
      if (disponible + 0.001 < entry.value) {
        final detailAttente = dejaEngage > 0
            ? ' (dont ${fmt(dejaEngage)} déjà engagés par des opérations en '
                  'attente de synchronisation)'
            : '';
        return 'Solde du compte virtuel insuffisant : '
            '${fmt(disponible < 0 ? 0 : disponible)} disponible$detailAttente '
            'pour ${fmt(entry.value)} à payer. Rechargez votre compte virtuel '
            'ou attendez la synchronisation.';
      }
    }
    return null;
  }
}
