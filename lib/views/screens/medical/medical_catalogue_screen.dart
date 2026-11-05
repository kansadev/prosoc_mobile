import 'package:flutter/material.dart';

import '../../../config/api.dart';
import '../../../config/colors.dart';
import '../../../models/medical/catalogue_medical_model.dart';
import '../../../models/medical/souscription_medicale_model.dart';
import '../../../utils/medical_permissions.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/prosoc_message_dialog.dart';
import '../../widgets/prosoc_resource_error_view.dart';
import 'widgets/medical_ui.dart';

/// Catalogue commercial des offres médicales. Renvoie la souscription créée.
class MedicalCatalogueScreen extends StatefulWidget {
  const MedicalCatalogueScreen({
    super.key,
    required this.affilieId,
    this.hopitalId,
  });

  final int affilieId;

  /// Hôpital déjà rattaché à l'affilié : seules ses offres sont proposées.
  final int? hopitalId;

  @override
  State<MedicalCatalogueScreen> createState() => _MedicalCatalogueScreenState();
}

class _MedicalCatalogueScreenState extends State<MedicalCatalogueScreen> {
  List<OffreMedicale> _offres = const [];
  bool _isLoading = true;
  String? _error;
  int? _errorStatus;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    await MedicalDevises.ensureLoaded();
    final response = await ApiService.getOffresMedicales(
      hopitalId: widget.hopitalId,
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (response.success && response.data != null) {
        // Les offres retirées restent dans la réponse (historique).
        _offres = response.data!.where((o) => o.statut).toList();
      } else {
        _error = response.message;
        _errorStatus = response.statusCode;
      }
    });
  }

  Future<void> _ouvrir(OffreMedicale offre) async {
    final created = await Navigator.of(context).push<SouscriptionMedicale>(
      MaterialPageRoute(
        builder: (_) => MedicalOffreDetailScreen(
          offreId: offre.id,
          affilieId: widget.affilieId,
        ),
      ),
    );
    if (created != null && mounted) Navigator.of(context).pop(created);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Offres médicales'),
        backgroundColor: AppColors.prosocGreen,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return ListView(
        children: [
          ProsocResourceErrorView(
            message: _error!,
            statusCode: _errorStatus,
            onRetry: _load,
          ),
        ],
      );
    }
    if (_offres.isEmpty) {
      return ListView(
        children: const [
          EmptyStateWidget(
            icon: Icons.storefront_outlined,
            title: 'Aucune offre disponible',
            subtitle: 'Aucune offre active pour le moment.',
            expandVertically: false,
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.hopitalId != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Vous êtes rattaché à un hôpital : seules ses offres sont '
              'proposées.',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
            ),
          ),
        ..._offres.map(
          (o) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              title: Text(
                o.nom,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                [
                  o.hopitalNom,
                  o.categorieSoinNom,
                  if (o.version != null)
                    '${o.version!.soins.length} soin(s) couvert(s)',
                ].whereType<String>().join(' · '),
              ),
              trailing: o.version == null
                  ? null
                  : Text(
                      '${MedicalDevises.montant(o.version!.montantMensuel, deviseId: o.version!.deviseId, deviseCode: o.version!.deviseCode)}\n/ mois',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.prosocGreen,
                      ),
                    ),
              onTap: () => _ouvrir(o),
            ),
          ),
        ),
      ],
    );
  }
}

/// Détail d'une offre : tarif et soins couverts affichés avant acceptation.
class MedicalOffreDetailScreen extends StatefulWidget {
  const MedicalOffreDetailScreen({
    super.key,
    required this.offreId,
    required this.affilieId,
  });

  final int offreId;
  final int affilieId;

  @override
  State<MedicalOffreDetailScreen> createState() =>
      _MedicalOffreDetailScreenState();
}

class _MedicalOffreDetailScreenState extends State<MedicalOffreDetailScreen> {
  OffreMedicale? _offre;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  int? _errorStatus;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final response = await ApiService.getOffreMedicale(widget.offreId);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _offre = response.data;
      if (!response.success) {
        _error = response.message;
        _errorStatus = response.statusCode;
      }
    });
  }

  /// Règle métier : une nouvelle souscription exige une cotisation à jour.
  /// Le serveur reste juge ; ce contrôle évite une demande vouée à l'échec et
  /// explique le montant restant. Retourne un message bloquant ou `null`.
  Future<String?> _controleCotisationAJour() async {
    final response = MedicalPermissions.estMembre
        ? await ApiService.getMesArrieresAffilie()
        : await ApiService.getArrieresAffilie(widget.affilieId);
    // Arriérés indisponibles : on laisse le serveur trancher.
    if (!response.success || response.data == null) return null;
    // Le serveur ne contrôle que la période courante : d'anciens arriérés ne
    // doivent pas bloquer ici. Une période absente de la liste lui reste soumise.
    final now = DateTime.now();
    final impayes = response.data!
        .where(
          (a) =>
              a.estImpaye &&
              a.typeObligation.toUpperCase() == 'COTISATION' &&
              a.mois == now.month &&
              a.annee == now.year,
        )
        .toList();
    if (impayes.isEmpty) return null;
    final reste = impayes.fold<double>(0, (t, a) => t + a.restAPayer);
    return 'La cotisation de la période en cours n\'est pas entièrement réglée : '
        '${MedicalDevises.montant(reste, deviseId: impayes.first.deviseId)} '
        'restant à payer. Réglez-la avant de souscrire à une offre médicale.';
  }

  Future<void> _souscrire() async {
    final offre = _offre;
    if (offre == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    final blocage = await _controleCotisationAJour();
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (blocage != null) {
      await ProsocMessageDialog.show(
        context,
        variant: ProsocMessageVariant.warning,
        title: 'Cotisation à régulariser',
        message: blocage,
      );
      return;
    }

    final accepte = await _confirmer(offre);
    if (!accepte || !mounted) return;

    setState(() => _isSubmitting = true);
    final response = await ApiService.createSouscriptionMedicale(
      affilieId: widget.affilieId,
      offreMedicaleHopitalId: offre.id,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (response.success && response.data != null) {
      Navigator.of(context).pop(response.data);
      return;
    }
    // Réponse perdue : l'appelant relit les souscriptions avant toute
    // nouvelle création (pas de clé d'idempotence côté client).
    await ProsocMessageDialog.show(
      context,
      variant: ProsocMessageVariant.error,
      title: 'Souscription impossible',
      message: response.message ?? 'La souscription n\'a pas pu être créée.',
      statusCode: response.statusCode,
      hint: response.statusCode == null
          ? 'Vérifiez votre liste de souscriptions avant de réessayer : '
                'l\'opération a pu aboutir.'
          : null,
    );
  }

  Future<bool> _confirmer(OffreMedicale offre) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmer la souscription'),
        content: Text(
          'Souscrire à « ${offre.nom} » (${offre.hopitalNom ?? 'hôpital'}). '
          'Vous resterez rattaché à cet hôpital. Chaque mois devra ensuite '
          'être préparé et payé intégralement pour ouvrir les droits.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.prosocGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Souscrire'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final offre = _offre;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Détail de l\'offre'),
        backgroundColor: AppColors.prosocGreen,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar:
          offre != null && offre.statut && MedicalPermissions.peutSouscrire
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _souscrire,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: const Text('Souscrire à cette offre'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.prosocGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : offre == null
          ? ProsocResourceErrorView(
              message: _error ?? 'Offre introuvable.',
              statusCode: _errorStatus,
              onRetry: _load,
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                MedicalSection(
                  title: offre.nom,
                  icon: Icons.local_hospital_outlined,
                  trailing: offre.statut
                      ? null
                      : const MedicalBadge(label: 'Retirée', color: Colors.grey),
                  child: Column(
                    children: [
                      MedicalInfoRow('Hôpital', offre.hopitalNom ?? '—'),
                      if (offre.categorieHopitalNom != null)
                        MedicalInfoRow(
                          'Catégorie hôpital',
                          offre.categorieHopitalNom!,
                        ),
                      MedicalInfoRow(
                        'Catégorie de soins',
                        offre.categorieSoinNom ?? '—',
                      ),
                      if (offre.version != null)
                        MedicalInfoRow(
                          'Prix mensuel',
                          MedicalDevises.montant(
                            offre.version!.montantMensuel,
                            deviseId: offre.version!.deviseId,
                            deviseCode: offre.version!.deviseCode,
                          ),
                          emphasize: true,
                        ),
                    ],
                  ),
                ),
                MedicalSoinsSection(soins: offre.version?.soins ?? const []),
                Text(
                  'Prix mensuel complet dû quel que soit le jour du paiement '
                  '(pas de prorata). Les versements partiels sont acceptés '
                  'mais n\'ouvrent les droits qu\'une fois le mois soldé.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
    );
  }
}

/// Liste des soins couverts par une version.
class MedicalSoinsSection extends StatelessWidget {
  const MedicalSoinsSection({
    super.key,
    required this.soins,
    this.title = 'Soins couverts',
  });

  final List<SoinCouvert> soins;
  final String title;

  @override
  Widget build(BuildContext context) {
    return MedicalSection(
      title: title,
      icon: Icons.healing_outlined,
      child: soins.isEmpty
          ? Text(
              'Aucun soin renseigné.',
              style: TextStyle(color: Colors.grey.shade600),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: soins
                  .map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 18,
                            color: AppColors.prosocGreen,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                text: s.nom,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                                children: [
                                  if (s.description != null)
                                    TextSpan(
                                      text: ' — ${s.description}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w400,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}
