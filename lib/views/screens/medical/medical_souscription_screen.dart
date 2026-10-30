import 'package:flutter/material.dart';

import '../../../config/api.dart';
import '../../../config/colors.dart';
import '../../../models/medical/catalogue_medical_model.dart';
import '../../../models/medical/souscription_medicale_model.dart';
import '../../../utils/medical_permissions.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/prosoc_message_dialog.dart';
import '../../widgets/prosoc_resource_error_view.dart';
import 'medical_catalogue_screen.dart';
import 'medical_periode_screen.dart';
import 'widgets/medical_ui.dart';

/// Périodes mensuelles d'une souscription médicale.
class MedicalSouscriptionScreen extends StatefulWidget {
  const MedicalSouscriptionScreen({
    super.key,
    required this.souscription,
    this.affilieNom,
  });

  final SouscriptionMedicale souscription;
  final String? affilieNom;

  @override
  State<MedicalSouscriptionScreen> createState() =>
      _MedicalSouscriptionScreenState();
}

class _MedicalSouscriptionScreenState extends State<MedicalSouscriptionScreen>
    with WidgetsBindingObserver, MedicalResumeRefresh {
  OffreMedicale? _offre;
  List<PeriodeCouvertureMedicale> _periodes = const [];
  bool _isLoading = true;
  String? _error;
  int? _errorStatus;

  SouscriptionMedicale get _souscription => widget.souscription;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Future<void> onResumeRefresh() => _load(showLoader: false);

  Future<void> _load({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    await MedicalDevises.ensureLoaded();
    final results = await Future.wait([
      ApiService.getOffreMedicale(_souscription.offreMedicaleHopitalId),
      ApiService.getPeriodesMedicales(_souscription.id),
    ]);
    if (!mounted) return;
    final offre = results[0] as ApiResponse<OffreMedicale>;
    final periodes = results[1] as ApiResponse<List<PeriodeCouvertureMedicale>>;
    setState(() {
      _isLoading = false;
      _offre = offre.data ?? _offre;
      if (periodes.success && periodes.data != null) {
        _periodes = [...periodes.data!]
          ..sort((a, b) => (b.annee * 12 + b.mois).compareTo(a.annee * 12 + a.mois));
        _error = null;
      } else {
        _error = periodes.message;
        _errorStatus = periodes.statusCode;
      }
    });
  }

  Future<void> _preparer() async {
    final periode = await showModalBottomSheet<PeriodeCouvertureMedicale>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PreparationPeriodeSheet(souscription: _souscription),
    );
    await _load(showLoader: false);
    if (periode != null && mounted) _ouvrir(periode);
  }

  Future<void> _ouvrir(PeriodeCouvertureMedicale periode) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MedicalPeriodeScreen(
          periodeId: periode.id,
          offreId: _souscription.offreMedicaleHopitalId,
          affilieId: _souscription.affilieId,
          affilieNom: widget.affilieNom,
        ),
      ),
    );
    await _load(showLoader: false);
  }

  @override
  Widget build(BuildContext context) {
    final offre = _offre;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(offre?.nom ?? 'Souscription médicale'),
        backgroundColor: AppColors.prosocGreen,
        foregroundColor: Colors.white,
      ),
      floatingActionButton:
          MedicalPermissions.peutSouscrire && _souscription.statut && !_isLoading
          ? FloatingActionButton.extended(
              onPressed: _preparer,
              backgroundColor: AppColors.prosocGreen,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.event_available),
              label: const Text('Préparer un mois'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => _load(showLoader: false),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  MedicalSection(
                    title: offre?.hopitalNom ?? 'Hôpital',
                    icon: Icons.local_hospital_outlined,
                    trailing: _souscription.statut
                        ? null
                        : const MedicalBadge(
                            label: 'Inactive',
                            color: Colors.grey,
                          ),
                    child: Column(
                      children: [
                        MedicalInfoRow(
                          'Catégorie de soins',
                          offre?.categorieSoinNom ?? '—',
                        ),
                        MedicalInfoRow(
                          'Souscrite le',
                          MedicalFormat.date(_souscription.dateSouscriptionUtc),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null)
                    ProsocResourceErrorView(
                      message: _error!,
                      statusCode: _errorStatus,
                      onRetry: _load,
                      compact: true,
                    )
                  else if (_periodes.isEmpty)
                    const EmptyStateWidget(
                      icon: Icons.event_note_outlined,
                      title: 'Aucun mois préparé',
                      subtitle:
                          'Préparez le mois à couvrir, puis payez-le '
                          'intégralement pour ouvrir les droits.',
                      expandVertically: false,
                    )
                  else
                    ..._periodes.map(_buildPeriodeCard),
                ],
              ),
      ),
    );
  }

  Widget _buildPeriodeCard(PeriodeCouvertureMedicale p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          MedicalFormat.mois(p.annee, p.mois),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          'Payé ${MedicalDevises.montant(p.montantValide, deviseId: p.deviseId)}'
          ' / ${MedicalDevises.montant(p.montantDu, deviseId: p.deviseId)}',
        ),
        trailing: MedicalBadge.periode(p.etat()),
        onTap: () => _ouvrir(p),
      ),
    );
  }
}

/// Choix du mois et acceptation explicite de la version courante de l'offre.
class _PreparationPeriodeSheet extends StatefulWidget {
  const _PreparationPeriodeSheet({required this.souscription});

  final SouscriptionMedicale souscription;

  @override
  State<_PreparationPeriodeSheet> createState() =>
      _PreparationPeriodeSheetState();
}

class _PreparationPeriodeSheetState extends State<_PreparationPeriodeSheet> {
  late final List<DateTime> _moisPossibles;
  late DateTime _mois;
  OffreMedicale? _offre;
  bool _accepte = false;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Mois courant ou futur uniquement (le serveur reste juge du mois métier).
    final now = DateTime.now();
    _moisPossibles = List.generate(12, (i) => DateTime(now.year, now.month + i));
    _mois = _moisPossibles.first;
    _loadOffre();
  }

  /// Toujours relire l'offre : la version acceptée doit être la dernière.
  Future<void> _loadOffre() async {
    setState(() {
      _isLoading = true;
      _accepte = false;
      _error = null;
    });
    final response = await ApiService.getOffreMedicale(
      widget.souscription.offreMedicaleHopitalId,
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _offre = response.data;
      if (!response.success || response.data?.version == null) {
        _error = response.message ?? 'Tarif de l\'offre indisponible.';
      }
    });
  }

  Future<void> _submit() async {
    final version = _offre?.version;
    if (version == null || !_accepte || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    final response = await ApiService.preparerPeriodeMedicale(
      widget.souscription.id,
      annee: _mois.year,
      mois: _mois.month,
      versionOffreMedicaleId: version.id,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (response.success && response.data != null) {
      Navigator.of(context).pop(response.data);
      return;
    }
    if (response.statusCode == 409) {
      // Version devenue obsolète : nouvelle acceptation requise, jamais de
      // remplacement silencieux de l'ID accepté.
      await ProsocMessageDialog.show(
        context,
        variant: ProsocMessageVariant.warning,
        title: 'Offre mise à jour',
        message:
            response.message ??
            'Le tarif ou les soins de l\'offre ont changé. Vérifiez la '
                'nouvelle version avant de confirmer.',
      );
      await _loadOffre();
      return;
    }
    await ProsocMessageDialog.show(
      context,
      variant: ProsocMessageVariant.error,
      title: 'Préparation impossible',
      message: response.message ?? 'Le mois n\'a pas pu être préparé.',
      statusCode: response.statusCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final version = _offre?.version;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Préparer un mois',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<DateTime>(
                  initialValue: _mois,
                  decoration: const InputDecoration(
                    labelText: 'Mois à couvrir',
                    border: OutlineInputBorder(),
                  ),
                  items: _moisPossibles
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(MedicalFormat.mois(m.year, m.month)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _mois = v);
                  },
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (version == null)
                  ProsocResourceErrorView(
                    message: _error ?? 'Tarif indisponible.',
                    onRetry: _loadOffre,
                    compact: true,
                  )
                else ...[
                  MedicalSection(
                    title: 'Tarif de la version actuelle',
                    icon: Icons.sell_outlined,
                    child: MedicalInfoRow(
                      'Prix mensuel',
                      MedicalDevises.montant(
                        version.montantMensuel,
                        deviseId: version.deviseId,
                        deviseCode: version.deviseCode,
                      ),
                      emphasize: true,
                    ),
                  ),
                  MedicalSoinsSection(soins: version.soins),
                  CheckboxListTile(
                    value: _accepte,
                    onChanged: (v) => setState(() => _accepte = v ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.prosocGreen,
                    title: const Text(
                      'J\'accepte ce tarif et cette liste de soins pour ce mois.',
                      style: TextStyle(fontSize: 13.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _accepte && !_isSubmitting ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.prosocGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Préparer ce mois'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
