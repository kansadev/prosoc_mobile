import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/api.dart';
import '../../models/conversion_preview_model.dart';
import '../../models/devise_model.dart';
import '../../utils/currency_formatter.dart';
import 'prosoc_message_dialog.dart';

/// Montant et devise à soumettre pour une collecte.
class PaiementDeviseResult {
  const PaiementDeviseResult._({
    this.deviseId,
    this.montant,
    this.blockingMessage,
  });

  const PaiementDeviseResult.ready({required int deviseId, required double montant})
    : this._(deviseId: deviseId, montant: montant);

  const PaiementDeviseResult.blocked(String message)
    : this._(blockingMessage: message);

  /// Devise de paiement → `collecte.deviseId` **et** `devisePaiementId`.
  final int? deviseId;

  /// Montant dans la devise de paiement → `collecte.montant`.
  final double? montant;

  /// Non nul : la soumission doit être interrompue et ce message affiché.
  final String? blockingMessage;

  bool get isReady => blockingMessage == null;
}

/// Devise et montant d'une collecte payée dans une autre devise que celle du
/// tarif (contrat multidevise) :
/// - le tarif reste dans la devise du produit ;
/// - la collecte porte la devise de paiement et le montant converti
///   (`GET /api/Devise/preview-conversion`) ;
/// - le serveur reconvertit et vérifie l'égalité avec le tarif.
class DevisePaiementController extends ChangeNotifier {
  DevisePaiementController({required this.operation, Listenable? triggers})
    : _triggers = triggers {
    _triggers?.addListener(_onOperationChanged);
  }

  /// Devise et montant de l'opération (tarif), lus à chaque utilisation.
  final ({int? deviseId, double? montant}) Function() operation;
  final Listenable? _triggers;

  /// FlexPay n'accepte que ces devises.
  static const Set<String> codesFlexPay = {'CDF', 'USD'};

  static List<Devise>? _cache;

  List<Devise> devises = const [];
  bool isLoadingDevises = false;
  String? devisesError;

  int? _selectedDeviseId;
  ConversionPreview? _preview;
  String? _previewKey;
  String? _previewError;
  String? _previewErrorKey;
  bool isLoadingPreview = false;
  Timer? _debounce;
  int _requestSeq = 0;
  bool _disposed = false;

  int? get operationDeviseId {
    final id = operation().deviseId;
    return id != null && id > 0 ? id : null;
  }

  double? get operationMontant => operation().montant;

  Devise? deviseById(int? id) =>
      devises.where((d) => d.idDevise == id).firstOrNull;

  /// Devise de paiement retenue (par défaut : celle du tarif).
  int? get paymentDeviseId => _selectedDeviseId ?? operationDeviseId;

  bool get needsConversion {
    final op = operationDeviseId;
    final pay = paymentDeviseId;
    return op != null && pay != null && op != pay;
  }

  String? get _currentKey {
    final source = deviseById(operationDeviseId)?.code;
    final cible = deviseById(paymentDeviseId)?.code;
    final montant = operationMontant;
    if (source == null || cible == null || montant == null || montant <= 0) {
      return null;
    }
    return '$source|$montant|$cible';
  }

  /// Aperçu valable pour la sélection courante (sinon `null`).
  ConversionPreview? get preview =>
      _previewKey != null && _previewKey == _currentKey ? _preview : null;

  String? get previewError =>
      _previewErrorKey != null && _previewErrorKey == _currentKey
      ? _previewError
      : null;

  Future<void> loadDevises() async {
    if (_cache != null) {
      devises = _cache!;
      _notify();
      _schedulePreview();
      return;
    }
    isLoadingDevises = true;
    devisesError = null;
    _notify();
    final response = await ApiService.getDevisesActives();
    if (_disposed) return;
    isLoadingDevises = false;
    if (response.success && response.data != null) {
      devises = response.data!
          .where((d) => codesFlexPay.contains(d.code.toUpperCase()))
          .toList();
      _cache = devises;
    } else {
      devisesError = response.message ?? 'Impossible de charger les devises.';
    }
    _notify();
    _schedulePreview();
  }

  void select(int deviseId) {
    _selectedDeviseId = deviseId;
    _notify();
    _schedulePreview(immediate: true);
  }

  /// Recalcule l'aperçu si nécessaire (sans notifier : appelable après un
  /// build sans risque de boucle).
  void refresh() => _schedulePreview();

  void _onOperationChanged() {
    _notify();
    _schedulePreview();
  }

  void _schedulePreview({bool immediate = false}) {
    _debounce?.cancel();
    if (!needsConversion || _currentKey == null || preview != null) return;
    _debounce = Timer(
      immediate ? Duration.zero : const Duration(milliseconds: 400),
      () => _fetchPreview(),
    );
  }

  Future<ConversionPreview?> _fetchPreview() async {
    final key = _currentKey;
    final source = deviseById(operationDeviseId)?.code;
    final cible = deviseById(paymentDeviseId)?.code;
    final montant = operationMontant;
    if (key == null || source == null || cible == null || montant == null) {
      return null;
    }
    final seq = ++_requestSeq;
    isLoadingPreview = true;
    _notify();
    final response = await ApiService.previewConversionVerifiee(
      codeDeviseSource: source,
      montant: montant,
      codeDeviseCible: cible,
    );
    if (_disposed) return null;
    // Une sélection plus récente a été demandée : réponse obsolète.
    if (seq != _requestSeq) return null;
    isLoadingPreview = false;
    if (response.success && response.data != null) {
      _preview = response.data;
      _previewKey = key;
      _previewError = null;
      _previewErrorKey = null;
    } else {
      _previewError =
          response.message ??
          'Conversion indisponible (aucun taux de change applicable).';
      _previewErrorKey = key;
    }
    _notify();
    return seq == _requestSeq && _previewKey == key ? _preview : null;
  }

  /// Devise et montant à soumettre. Avec conversion, l'aperçu est recalculé :
  /// si le montant a changé (taux modifié) ou n'avait pas encore été affiché,
  /// la soumission est bloquée pour faire confirmer le nouveau montant.
  Future<PaiementDeviseResult> resolve({required bool enabled}) async {
    final op = operationDeviseId;
    final montant = operationMontant;
    if (op == null || montant == null) {
      return const PaiementDeviseResult.blocked(
        'Devise ou montant du tarif introuvable.',
      );
    }
    if (!enabled || !needsConversion) {
      return PaiementDeviseResult.ready(deviseId: op, montant: montant);
    }
    if (_currentKey == null) {
      return const PaiementDeviseResult.blocked(
        'Devise de paiement indisponible. Rechargez les devises et réessayez.',
      );
    }

    final affiche = preview;
    _debounce?.cancel();
    final frais = await _fetchPreview();
    if (frais == null) {
      return PaiementDeviseResult.blocked(
        previewError ??
            'Conversion indisponible. Vérifiez votre connexion et réessayez.',
      );
    }
    if (affiche == null || affiche.montantConverti != frais.montantConverti) {
      return PaiementDeviseResult.blocked(
        affiche == null
            ? 'Vérifiez le montant à payer (${frais.montantConvertiLabel}) '
                  'puis validez à nouveau.'
            : 'Le taux de change a été mis à jour : nouveau montant à payer '
                  '${frais.montantConvertiLabel}. Vérifiez puis validez à '
                  'nouveau.',
      );
    }
    return PaiementDeviseResult.ready(
      deviseId: paymentDeviseId!,
      montant: frais.montantConverti,
    );
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    _triggers?.removeListener(_onOperationChanged);
    super.dispose();
  }
}

/// Choix de la devise de paiement (Mobile Money) et aperçu de conversion.
class DevisePaiementSelector extends StatelessWidget {
  const DevisePaiementSelector({
    super.key,
    required this.controller,
    this.decoration,
  });

  final DevisePaiementController controller;
  final InputDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.isLoadingDevises) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        if (controller.devises.isEmpty) {
          return _message(
            controller.devisesError ?? 'Aucune devise disponible.',
            isError: true,
            onRetry: controller.loadDevises,
          );
        }

        final current = controller.deviseById(controller.paymentDeviseId);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<int>(
              // La clé reconstruit le champ quand la devise du tarif change.
              key: ValueKey('devise-paiement-${current?.idDevise}'),
              initialValue: current?.idDevise,
              isExpanded: true,
              decoration:
                  decoration ??
                  const InputDecoration(hintText: 'Devise de paiement'),
              items: controller.devises
                  .map(
                    (d) => DropdownMenuItem(
                      value: d.idDevise,
                      child: Text(
                        d.nom.isNotEmpty ? '${d.code} — ${d.nom}' : d.code,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) controller.select(v);
              },
            ),
            const SizedBox(height: 8),
            _buildConversionInfo(),
          ],
        );
      },
    );
  }

  Widget _buildConversionInfo() {
    if (!controller.needsConversion) {
      return _message(
        'Vous pouvez payer dans une autre devise : le montant est converti '
        'au taux de change en vigueur.',
      );
    }
    final montant = controller.operationMontant;
    if (montant == null || montant <= 0) {
      return _message('Saisissez le montant pour calculer la conversion.');
    }
    final preview = controller.preview;
    if (preview == null &&
        controller.previewError == null &&
        !controller.isLoadingPreview) {
      // Tarif modifié sans passer par les déclencheurs : aperçu à recalculer.
      WidgetsBinding.instance.addPostFrameCallback((_) => controller.refresh());
    }
    if (preview != null) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Text(
          preview.recapLabel,
          style: TextStyle(
            fontSize: 12.5,
            height: 1.4,
            fontWeight: FontWeight.w600,
            color: Colors.orange.shade900,
          ),
        ),
      );
    }
    final error = controller.previewError;
    if (error != null && !controller.isLoadingPreview) {
      return _message(error, isError: true, onRetry: controller.refresh);
    }
    return _message('Calcul du montant à payer…');
  }

  Widget _message(String text, {bool isError = false, VoidCallback? onRetry}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: isError ? Colors.red.shade700 : Colors.grey.shade600,
            ),
          ),
        ),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
      ],
    );
  }
}

/// Collecte d'une adhésion à payer dans la devise choisie.
typedef CollecteAConvertir = ({String libelle, double montant, int deviseId});

/// Conversion des collectes d'une adhésion (frais + souscription éventuelle)
/// vers la devise de paiement, avec confirmation du récapitulatif.
abstract final class AdhesionConversion {
  /// Montants dans la devise de paiement, dans l'ordre de [lignes] ;
  /// `null` si la conversion échoue (message affiché) ou si l'utilisateur
  /// annule. Sans conversion nécessaire, aucun dialogue n'est affiché.
  static Future<List<double>?> convertirEtConfirmer(
    BuildContext context, {
    required List<CollecteAConvertir> lignes,
    required Devise devisePaiement,
    required String Function(int deviseId) codeFor,
  }) async {
    final cible = devisePaiement.code;
    final montants = <double>[];
    final recap = <String>[];

    for (final ligne in lignes) {
      final source = codeFor(ligne.deviseId);
      if (ligne.deviseId == devisePaiement.idDevise || ligne.montant <= 0) {
        montants.add(ligne.montant);
        continue;
      }
      if (source.isEmpty) {
        await _erreur(context, 'Devise de « ${ligne.libelle} » introuvable.');
        return null;
      }
      final response = await ApiService.previewConversionVerifiee(
        codeDeviseSource: source,
        montant: ligne.montant,
        codeDeviseCible: cible,
      );
      if (!context.mounted) return null;
      if (!response.success || response.data == null) {
        await _erreur(
          context,
          response.message ??
              'Conversion indisponible (aucun taux de change applicable).',
        );
        return null;
      }
      montants.add(response.data!.montantConverti);
      recap.add('${ligne.libelle}\n${response.data!.recapLabel}');
    }

    if (recap.isEmpty) return montants;

    final total = montants.fold<double>(0, (a, b) => a + b);
    final confirme = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ProsocMessageDialog(
        variant: ProsocMessageVariant.info,
        icon: Icons.currency_exchange,
        title: 'Montant à payer en $cible',
        message: recap.join('\n\n'),
        hint:
            'Total à payer : ${CurrencyFormatter.format(amount: total, deviseCode: cible)}. '
            'Le taux n\'est pas réservé : s\'il change avant la validation, '
            'le paiement sera refusé et un nouveau montant proposé.',
        confirmLabel: 'Confirmer le paiement',
        onConfirm: () => Navigator.of(dialogContext).pop(true),
        secondaryLabel: 'Annuler',
        onSecondary: () => Navigator.of(dialogContext).pop(false),
      ),
    );
    return confirme == true ? montants : null;
  }

  static Future<void> _erreur(BuildContext context, String message) {
    return ProsocMessageDialog.show(
      context,
      variant: ProsocMessageVariant.error,
      title: 'Conversion impossible',
      message: message,
    );
  }
}
