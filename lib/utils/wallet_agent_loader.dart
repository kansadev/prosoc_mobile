import '../config/api.dart';
import '../models/devise_model.dart';
import '../models/wallet_agent_model.dart';
import 'api_error_helper.dart';

/// Résultat du chargement wallet agent (devises disponibles + wallet sélectionné).
class WalletAgentLoadResult {
  final WalletAgentModel? wallet;
  final Set<int> availableDeviseIds;
  final int? resolvedDeviseId;
  final Map<int, WalletAgentModel> walletsByDevise;
  final String? errorMessage;
  final int? errorStatusCode;

  const WalletAgentLoadResult({
    this.wallet,
    this.availableDeviseIds = const {},
    this.resolvedDeviseId,
    this.walletsByDevise = const {},
    this.errorMessage,
    this.errorStatusCode,
  });

  bool get hasWallet => wallet != null;
}

/// Charge les wallets agent en listant d'abord les devises, puis en interrogeant
/// uniquement les devises pertinentes (évite les 404 sur une devise sans wallet).
abstract final class WalletAgentLoader {
  static Future<WalletAgentLoadResult> load({
    required int agentId,
    int? preferredDeviseId,
    Map<int, WalletAgentModel>? cachedWallets,
  }) async {
    final orderedDeviseIds = await _fetchActiveDeviseIds();
    final wallets = Map<int, WalletAgentModel>.from(cachedWallets ?? {});
    final available = <int>{...wallets.keys};

    for (final deviseId in orderedDeviseIds) {
      if (wallets.containsKey(deviseId)) {
        available.add(deviseId);
        continue;
      }

      final response = await ApiService.getWalletAgentByAgentAndDevise(
        agentId,
        deviseId: deviseId,
      );

      if (response.success && response.data != null) {
        wallets[deviseId] = response.data!;
        available.add(deviseId);
      }
    }

    if (available.isEmpty) {
      return WalletAgentLoadResult(
        errorMessage: ApiErrorHelper.messageForWalletAgentError(
          statusCode: 404,
        ),
        errorStatusCode: 404,
      );
    }

    final resolvedId = _resolveDeviseId(
      preferredDeviseId: preferredDeviseId,
      available: available,
      orderedDeviseIds: orderedDeviseIds,
    );

    return WalletAgentLoadResult(
      wallet: wallets[resolvedId],
      availableDeviseIds: available,
      resolvedDeviseId: resolvedId,
      walletsByDevise: wallets,
    );
  }

  static Future<WalletAgentLoadResult> loadSingleDevise({
    required int agentId,
    required int deviseId,
    required Set<int> availableDeviseIds,
    Map<int, WalletAgentModel>? cachedWallets,
  }) async {
    final wallets = Map<int, WalletAgentModel>.from(cachedWallets ?? {});

    if (wallets.containsKey(deviseId)) {
      return WalletAgentLoadResult(
        wallet: wallets[deviseId],
        availableDeviseIds: availableDeviseIds,
        resolvedDeviseId: deviseId,
        walletsByDevise: wallets,
      );
    }

    if (!availableDeviseIds.contains(deviseId)) {
      return WalletAgentLoadResult(
        availableDeviseIds: availableDeviseIds,
        walletsByDevise: wallets,
        errorMessage: ApiErrorHelper.messageForWalletAgentError(
          statusCode: 404,
        ),
        errorStatusCode: 404,
      );
    }

    final response = await ApiService.getWalletAgentByAgentAndDevise(
      agentId,
      deviseId: deviseId,
    );

    if (response.success && response.data != null) {
      wallets[deviseId] = response.data!;
      return WalletAgentLoadResult(
        wallet: response.data,
        availableDeviseIds: availableDeviseIds,
        resolvedDeviseId: deviseId,
        walletsByDevise: wallets,
      );
    }

    return WalletAgentLoadResult(
      availableDeviseIds: availableDeviseIds,
      walletsByDevise: wallets,
      errorMessage: ApiErrorHelper.messageForWalletAgentError(
        statusCode: response.statusCode,
        serverMessage: response.message,
      ),
      errorStatusCode: response.statusCode,
    );
  }

  static Future<List<int>> _fetchActiveDeviseIds() async {
    final response = await ApiService.getDevises();
    if (!response.success || response.data == null) {
      return const [
        WalletAgentDeviseIds.cdf,
        WalletAgentDeviseIds.usd,
      ];
    }

    final devises = response.data!
        .whereType<Map>()
        .map((e) => Devise.fromJson(Map<String, dynamic>.from(e)))
        .where((d) => d.statut && d.idDevise > 0)
        .toList();

    if (devises.isEmpty) {
      return const [
        WalletAgentDeviseIds.cdf,
        WalletAgentDeviseIds.usd,
      ];
    }

    devises.sort(Devise.compareByPriority);

    return devises.map((d) => d.idDevise).toList();
  }

  static int _resolveDeviseId({
    required int? preferredDeviseId,
    required Set<int> available,
    required List<int> orderedDeviseIds,
  }) {
    if (preferredDeviseId != null && available.contains(preferredDeviseId)) {
      return preferredDeviseId;
    }

    for (final deviseId in orderedDeviseIds) {
      if (available.contains(deviseId)) return deviseId;
    }

    return available.first;
  }

  static bool isUsdDeviseId(int deviseId) =>
      deviseId == WalletAgentDeviseIds.usd;
}
