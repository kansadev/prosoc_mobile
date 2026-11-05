import 'package:flutter/material.dart';

import '../models/frais_model.dart';
import '../models/prestation_model.dart';
import '../services/sync_service.dart';
import '../utils/affilie_payment_modes.dart';
import 'offline_database.dart';
import 'sync_models.dart';

/// Règles communes aux écrans utilisables hors ligne : modes de paiement et
/// lecture des données synchronisées.
abstract final class OfflineMode {
  static bool get isOffline => !SyncService.instance.isOnline;

  /// Échec sans réponse HTTP : le réseau est en cause, pas le serveur.
  static bool sansReseau({required bool success, int? statusCode}) =>
      !success && statusCode == null;

  /// Hors ligne, seul le compte virtuel peut partir en file.
  static Map<String, String> modesDisponibles({
    required bool allowVirtualAccount,
    required bool offline,
  }) {
    final modes = AffiliePaymentModes.modesFor(
      allowVirtualAccount: allowVirtualAccount,
    );
    if (!offline) return modes;
    return {
      for (final e in modes.entries)
        if (e.key == AffiliePaymentModes.virtualAccount) e.key: e.value,
    };
  }

  static String? modeParDefaut({
    required bool allowVirtualAccount,
    required bool offline,
  }) {
    if (offline && !allowVirtualAccount) return null;
    return AffiliePaymentModes.defaultModeFor(
      allowVirtualAccount: allowVirtualAccount,
    );
  }

  /// Référentiels en cache ; `null` si absents ou illisibles.
  static SyncReferentials? get referentials {
    if (!OfflineDatabase.isInitialized) return null;
    try {
      return OfflineDatabase.referentials;
    } catch (_) {
      return null;
    }
  }

  static List<Frais> fraisLocaux() =>
      (referentials?.frais ?? const <Map<String, dynamic>>[])
          .map(Frais.fromJson)
          .toList();

  static List<Prestation> prestationsLocales() =>
      (referentials?.prestations ?? const <Map<String, dynamic>>[])
          .where((row) => (row['statut'] ?? row['Statut']) != false)
          .map(Prestation.fromJson)
          .where((p) => p.id > 0)
          .toList();

  static List<Map<String, dynamic>> devisesLocales() =>
      referentials?.devises ?? const [];

  /// Tarifs de cotisation applicables à un affilié du cache, d'après son type
  /// d'adhésion. Vide si l'affilié ou les tarifs ne sont pas synchronisés.
  static List<Map<String, dynamic>> tarifsLocaux(int affilieId) {
    final refs = referentials;
    if (refs == null || !OfflineDatabase.isInitialized) return const [];
    final affilie = OfflineDatabase.affilieById(affilieId);
    if (affilie == null) return const [];
    return tarifsPourType(
      tarifs: refs.tarifsCotisation,
      typeAdhesions: refs.typeAdhesions,
      typeAdhesionId: affilie.typeAdhesionId,
    );
  }

  /// Ramène les lignes du référentiel à la forme de
  /// `getTarifCotisationByAffilie` (`id`, `typeAdhesionLibelle`). Une ligne dont
  /// le type d'adhésion n'est pas connu est écartée plutôt que proposée à tort.
  static List<Map<String, dynamic>> tarifsPourType({
    required List<Map<String, dynamic>> tarifs,
    required List<Map<String, dynamic>> typeAdhesions,
    required int typeAdhesionId,
  }) {
    final resultat = <Map<String, dynamic>>[];
    for (final tarif in tarifs) {
      final id = _premierEntier(tarif, const [
        'id',
        'Id',
        'idCotisationAffilie',
        'IdCotisationAffilie',
        'cotisationAffilieId',
        'CotisationAffilieId',
        'idTarifCotisation',
        'IdTarifCotisation',
      ]);
      final type = _premierEntier(tarif, _clesTypeAdhesion);
      if (id == null || type == null || type != typeAdhesionId) continue;
      final libelle = (tarif['typeAdhesionLibelle'] ?? '').toString().trim();
      resultat.add({
        ...tarif,
        'id': id,
        'typeAdhesionLibelle': libelle.isNotEmpty
            ? libelle
            : libelleTypeAdhesion(typeAdhesions, typeAdhesionId),
      });
    }
    return resultat;
  }

  static const List<String> _clesTypeAdhesion = [
    'typeAdhesionId',
    'TypeAdhesionId',
    'idTypeAdhesion',
    'IdTypeAdhesion',
  ];

  static String libelleTypeAdhesion(
    List<Map<String, dynamic>> typeAdhesions,
    int typeAdhesionId,
  ) {
    for (final type in typeAdhesions) {
      final id = _premierEntier(type, const ['id', 'Id', ..._clesTypeAdhesion]);
      if (id != typeAdhesionId) continue;
      for (final cle in const [
        'libelle',
        'Libelle',
        'nom',
        'Nom',
        'libelleTypeAdhesion',
      ]) {
        final texte = type[cle]?.toString().trim() ?? '';
        if (texte.isNotEmpty) return texte;
      }
    }
    return '';
  }

  /// Affilié du cache sous la forme attendue par « Mon réseau » et la fiche.
  static Map<String, dynamic> membreDepuis(
    SyncAffilieRow row, {
    List<Map<String, dynamic>> typeAdhesions = const [],
  }) {
    return {
      'idAffilie': row.idAffilie,
      'affilieId': row.idAffilie,
      'prenom': row.prenom,
      'nom': row.nom,
      'nomComplet': row.nomComplet,
      'telephone': row.telephone,
      'phone': row.telephone,
      'codeAdhesion': row.codeAdhesion,
      'matricule': row.codeAdhesion,
      'provinceResidence': row.provinceResidence,
      'dateNaissance': row.dateNaissance,
      'sexe': row.sexe,
      'adhesionId': row.adhesionId,
      'typeAdhesionId': row.typeAdhesionId,
      'typeAdhesion': libelleTypeAdhesion(typeAdhesions, row.typeAdhesionId),
      'statutDossier': row.statutDossier,
      'statut': row.statut,
      'statutAffilie': row.statut,
    };
  }

  /// Affiliés du cache, sous la forme de [membreDepuis]. [agentId] limite aux
  /// affiliés de cet agent, comme `getAffiliesByAgent`.
  static List<Map<String, dynamic>> membresLocaux({
    String recherche = '',
    int? agentId,
  }) {
    if (!OfflineDatabase.isInitialized) return const [];
    final types = referentials?.typeAdhesions ?? const [];
    return OfflineDatabase.affilies
        .where(
          (a) =>
              a.matchesQuery(recherche.trim()) &&
              (agentId == null || a.agentGestionnaireId == agentId),
        )
        .map((a) => membreDepuis(a, typeAdhesions: types))
        .toList();
  }

  /// « données du … » : l'utilisateur doit savoir que l'affichage peut dater.
  static String get libelleDonnees {
    DateTime? date;
    if (OfflineDatabase.isInitialized) {
      try {
        date = OfflineDatabase.lastSyncAt;
      } catch (_) {
        date = null;
      }
    }
    if (date == null) return 'Données enregistrées sur cet appareil.';
    String deux(int v) => v.toString().padLeft(2, '0');
    return 'Données du ${deux(date.day)}/${deux(date.month)}/${date.year} '
        'à ${deux(date.hour)}:${deux(date.minute)}.';
  }

  static int? _premierEntier(Map<String, dynamic> row, List<String> cles) {
    for (final cle in cles) {
      final valeur = row[cle];
      if (valeur is num && valeur > 0) return valeur.toInt();
      final parse = int.tryParse(valeur?.toString() ?? '');
      if (parse != null && parse > 0) return parse;
    }
    return null;
  }
}

/// Suit le passage en ligne / hors ligne pour un écran.
mixin OfflineAwareState<T extends StatefulWidget> on State<T> {
  bool isOffline = false;

  @override
  void initState() {
    super.initState();
    isOffline = OfflineMode.isOffline;
    SyncService.instance.state.addListener(_onSyncStateChanged);
  }

  @override
  void dispose() {
    SyncService.instance.state.removeListener(_onSyncStateChanged);
    super.dispose();
  }

  void _onSyncStateChanged() {
    final offline = OfflineMode.isOffline;
    if (!mounted || offline == isOffline) return;
    setState(() => isOffline = offline);
    onOfflineChanged(offline);
  }

  /// Appelé après chaque changement d'état du réseau.
  void onOfflineChanged(bool offline) {}
}

/// Rappelle que les données affichées viennent du cache local.
class OfflineDataBanner extends StatefulWidget {
  final String? complement;

  const OfflineDataBanner({super.key, this.complement});

  @override
  State<OfflineDataBanner> createState() => _OfflineDataBannerState();
}

class _OfflineDataBannerState extends State<OfflineDataBanner> {
  bool _ferme = false;

  @override
  Widget build(BuildContext context) {
    if (_ferme) return const SizedBox.shrink();
    final texte = [
      OfflineMode.libelleDonnees,
      if (widget.complement != null) widget.complement!,
    ].join(' ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_off_rounded, size: 18, color: Colors.orange.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texte,
              style: TextStyle(fontSize: 12.5, color: Colors.orange.shade900),
            ),
          ),
          IconButton(
            tooltip: 'Fermer',
            onPressed: () => setState(() => _ferme = true),
            icon: Icon(Icons.close_rounded, color: Colors.orange.shade800),
            iconSize: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          ),
        ],
      ),
    );
  }
}
