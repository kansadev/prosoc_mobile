import 'package:flutter/material.dart';

import '../../../../config/api.dart';
import '../../../../config/colors.dart';
import '../../../../models/hopital_partenaire_model.dart';
import '../../../../models/medical/catalogue_medical_model.dart';
import '../../../../utils/medical_permissions.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/prosoc_message_dialog.dart';
import '../../../widgets/prosoc_resource_error_view.dart';
import '../medical_catalogue_screen.dart';
import '../widgets/medical_ui.dart';

/// Toutes les offres (actives et retirées).
class MedicalOffresAdminScreen extends StatefulWidget {
  const MedicalOffresAdminScreen({super.key});

  @override
  State<MedicalOffresAdminScreen> createState() =>
      _MedicalOffresAdminScreenState();
}

class _MedicalOffresAdminScreenState extends State<MedicalOffresAdminScreen> {
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
    setState(() => _isLoading = true);
    await MedicalDevises.ensureLoaded();
    final response = await ApiService.getOffresMedicales();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _offres = response.data ?? _offres;
      _error = response.success ? null : response.message;
      _errorStatus = response.statusCode;
    });
  }

  Future<void> _ouvrir(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) await _load();
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
      floatingActionButton: MedicalPermissions.peutCreerProduit
          ? FloatingActionButton.extended(
              onPressed: () => _ouvrir(const MedicalOffreFormScreen()),
              backgroundColor: AppColors.prosocGreen,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle offre'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
                children: [
                  ProsocResourceErrorView(
                    message: _error!,
                    statusCode: _errorStatus,
                    onRetry: _load,
                  ),
                ],
              )
            : _offres.isEmpty
            ? ListView(
                children: const [
                  EmptyStateWidget(
                    icon: Icons.inventory_2_outlined,
                    title: 'Aucune offre',
                    expandVertically: false,
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: _offres
                    .map(
                      (o) => Card(
                        child: ListTile(
                          title: Text(
                            o.nom,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            [o.hopitalNom, o.categorieSoinNom]
                                .whereType<String>()
                                .join(' · '),
                          ),
                          trailing: MedicalBadge(
                            label: o.statut ? 'Active' : 'Retirée',
                            color: o.statut ? AppColors.prosocGreen : Colors.grey,
                          ),
                          onTap: () =>
                              _ouvrir(MedicalOffreAdminDetailScreen(offreId: o.id)),
                        ),
                      ),
                    )
                    .toList(),
              ),
      ),
    );
  }
}

/// Détail d'administration : versions publiées, publication, statut.
class MedicalOffreAdminDetailScreen extends StatefulWidget {
  const MedicalOffreAdminDetailScreen({super.key, required this.offreId});

  final int offreId;

  @override
  State<MedicalOffreAdminDetailScreen> createState() =>
      _MedicalOffreAdminDetailScreenState();
}

class _MedicalOffreAdminDetailScreenState
    extends State<MedicalOffreAdminDetailScreen> {
  OffreMedicale? _offre;
  List<VersionOffreMedicale> _versions = const [];
  bool _isLoading = true;
  bool _isActing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      ApiService.getOffreMedicale(widget.offreId),
      ApiService.getVersionsOffreMedicale(widget.offreId),
    ]);
    if (!mounted) return;
    final offre = results[0] as ApiResponse<OffreMedicale>;
    final versions = results[1] as ApiResponse<List<VersionOffreMedicale>>;
    setState(() {
      _isLoading = false;
      _offre = offre.data ?? _offre;
      _versions = [...?versions.data]
        ..sort(
          (a, b) => (b.datePublicationUtc ?? DateTime(0)).compareTo(
            a.datePublicationUtc ?? DateTime(0),
          ),
        );
      _error = offre.success ? null : offre.message;
    });
  }

  Future<void> _basculerStatut() async {
    final offre = _offre;
    if (offre == null || _isActing) return;
    final retirer = offre.statut;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(retirer ? 'Retirer l\'offre' : 'Remettre au catalogue'),
        content: Text(
          retirer
              ? 'L\'offre ne sera plus proposée. Les droits déjà payés sont '
                    'conservés.'
              : 'L\'offre sera de nouveau proposée aux affiliés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _isActing = true);
    final response = await ApiService.setStatutOffreMedicale(offre.id, !retirer);
    if (!mounted) return;
    setState(() => _isActing = false);
    if (!response.success) {
      await ProsocMessageDialog.show(
        context,
        variant: ProsocMessageVariant.error,
        title: 'Modification impossible',
        message: response.message ?? 'Le statut n\'a pas pu être modifié.',
        statusCode: response.statusCode,
      );
    }
    await _load();
  }

  Future<void> _publier() async {
    final offre = _offre;
    if (offre == null) return;
    final published = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => MedicalOffreFormScreen(offre: offre)),
    );
    if (published == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final offre = _offre;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(offre?.nom ?? 'Offre'),
        backgroundColor: AppColors.prosocGreen,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : offre == null
          ? ProsocResourceErrorView(
              message: _error ?? 'Offre introuvable.',
              onRetry: _load,
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                MedicalSection(
                  title: offre.hopitalNom ?? 'Hôpital',
                  icon: Icons.local_hospital_outlined,
                  trailing: MedicalBadge(
                    label: offre.statut ? 'Active' : 'Retirée',
                    color: offre.statut ? AppColors.prosocGreen : Colors.grey,
                  ),
                  child: Column(
                    children: [
                      MedicalInfoRow('Catégorie de soins', offre.categorieSoinNom ?? '—'),
                      MedicalInfoRow(
                        'Catégorie hôpital',
                        offre.categorieHopitalNom ?? 'Non classé',
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (MedicalPermissions.peutCreerProduit)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isActing ? null : _publier,
                          icon: const Icon(Icons.publish_outlined),
                          label: const Text('Nouvelle version'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.prosocGreen,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    if (MedicalPermissions.peutCreerProduit &&
                        MedicalPermissions.peutModifierProduit)
                      const SizedBox(width: 12),
                    if (MedicalPermissions.peutModifierProduit)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isActing ? null : _basculerStatut,
                          child: Text(offre.statut ? 'Retirer' : 'Réactiver'),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Versions publiées (immuables)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ..._versions.map(_buildVersion),
              ],
            ),
    );
  }

  Widget _buildVersion(VersionOffreMedicale v) {
    final courante = _offre?.version?.id == v.id;
    return MedicalSection(
      title: 'Version du ${MedicalFormat.dateHeure(v.datePublicationUtc)}',
      icon: Icons.history,
      trailing: courante
          ? const MedicalBadge(label: 'Courante', color: AppColors.prosocGreen)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MedicalInfoRow(
            'Prix mensuel',
            MedicalDevises.montant(
              v.montantMensuel,
              deviseId: v.deviseId,
              deviseCode: v.deviseCode,
            ),
            emphasize: true,
          ),
          MedicalInfoRow(
            'Commissions',
            'AT ${v.tauxCommissionAT}% · AA ${v.tauxCommissionAA}% · '
                'Mash ${v.tauxCommissionAAMash}% · '
                'Structure ${v.tauxCommissionAAStructure}%',
          ),
          Text(
            v.soins.map((s) => s.nom).join(', '),
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}

/// Création d'une offre (sans [offre]) ou publication d'une nouvelle version
/// pré-remplie depuis la version courante.
class MedicalOffreFormScreen extends StatefulWidget {
  const MedicalOffreFormScreen({super.key, this.offre});

  final OffreMedicale? offre;

  @override
  State<MedicalOffreFormScreen> createState() => _MedicalOffreFormScreenState();
}

class _MedicalOffreFormScreenState extends State<MedicalOffreFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _montant = TextEditingController();
  final _tauxAT = TextEditingController(text: '0');
  final _tauxAA = TextEditingController(text: '0');
  final _tauxMash = TextEditingController(text: '0');
  final _tauxStructure = TextEditingController(text: '0');

  List<HopitalPartenaireModel> _hopitaux = const [];
  List<ReferentielMedical> _categoriesSoins = const [];
  List<ReferentielMedical> _soins = const [];
  int? _hopitalId;
  int? _categorieSoinId;
  int? _deviseId;
  final Set<int> _soinIds = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  bool get _creation => widget.offre == null;

  @override
  void initState() {
    super.initState();
    final version = widget.offre?.version;
    if (version != null) {
      _montant.text = _fmt(version.montantMensuel);
      _deviseId = version.deviseId;
      _soinIds.addAll(version.soins.map((s) => s.soinId));
      _tauxAT.text = _fmt(version.tauxCommissionAT);
      _tauxAA.text = _fmt(version.tauxCommissionAA);
      _tauxMash.text = _fmt(version.tauxCommissionAAMash);
      _tauxStructure.text = _fmt(version.tauxCommissionAAStructure);
    }
    _load();
  }

  @override
  void dispose() {
    for (final c in [_nom, _montant, _tauxAT, _tauxAA, _tauxMash, _tauxStructure]) {
      c.dispose();
    }
    super.dispose();
  }

  static String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toString();

  Future<void> _load() async {
    setState(() => _isLoading = true);
    await MedicalDevises.ensureLoaded();
    final results = await Future.wait([
      ApiService.getReferentielsMedicaux(ReferentielMedicalType.soins),
      if (_creation)
        ApiService.getReferentielsMedicaux(ReferentielMedicalType.categoriesSoins),
      if (_creation) ApiService.getHopitauxPartenairesActifs(),
    ]);
    if (!mounted) return;
    final soins = results[0] as ApiResponse<List<ReferentielMedical>>;
    setState(() {
      _isLoading = false;
      // Une publication n'utilise que des référentiels actifs.
      _soins = (soins.data ?? const []).where((s) => s.statut).toList();
      if (_creation) {
        final categories = results[1] as ApiResponse<List<ReferentielMedical>>;
        final hopitaux = results[2] as ApiResponse<List<HopitalPartenaireModel>>;
        _categoriesSoins = (categories.data ?? const [])
            .where((c) => c.statut)
            .toList();
        _hopitaux = hopitaux.data ?? const [];
      }
      _deviseId ??= MedicalDevises.all.firstOrNull?.idDevise;
      _error = soins.success ? null : soins.message;
    });
  }

  static double? _parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  static bool _deuxDecimales(double v) =>
      ((v * 100).roundToDouble() - v * 100).abs() < 1e-6;

  String? _validerMontant(String? text) {
    final v = _parse(text ?? '');
    if (v == null || v <= 0) return 'Montant strictement positif requis.';
    if (!_deuxDecimales(v)) return 'Deux décimales maximum.';
    return null;
  }

  String? _validerTaux(String? text) {
    final v = _parse(text ?? '');
    if (v == null || v < 0 || v > 100) return 'Entre 0 et 100.';
    if (!_deuxDecimales(v)) return 'Deux décimales maximum.';
    return null;
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    if (_soinIds.isEmpty || _soinIds.length > 500) {
      await _erreur('Sélectionnez entre 1 et 500 soins couverts.');
      return;
    }
    if (_deviseId == null) {
      await _erreur('Choisissez la devise du tarif.');
      return;
    }
    final version = VersionOffreMedicaleRequest(
      montantMensuel: _parse(_montant.text)!,
      deviseId: _deviseId!,
      soinIds: _soinIds.toList(),
      tauxCommissionAT: _parse(_tauxAT.text)!,
      tauxCommissionAA: _parse(_tauxAA.text)!,
      tauxCommissionAAMash: _parse(_tauxMash.text)!,
      tauxCommissionAAStructure: _parse(_tauxStructure.text)!,
    );

    setState(() => _isSubmitting = true);
    final ApiResponse<Object?> response = _creation
        ? await ApiService.createOffreMedicale(
            hopitalPartenaireId: _hopitalId!,
            categorieSoinId: _categorieSoinId!,
            nom: _nom.text.trim(),
            version: version,
          )
        : await ApiService.publierVersionOffreMedicale(widget.offre!.id, version);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (response.success) {
      Navigator.of(context).pop(true);
      return;
    }
    await _erreur(
      response.statusCode == 409
          ? (response.message ??
                'Une offre existe déjà pour cet hôpital et cette catégorie de '
                    'soins.')
          : (response.message ?? 'L\'enregistrement a échoué.'),
      statusCode: response.statusCode,
    );
  }

  Future<void> _erreur(String message, {int? statusCode}) {
    return ProsocMessageDialog.show(
      context,
      variant: ProsocMessageVariant.error,
      title: _creation ? 'Création impossible' : 'Publication impossible',
      message: message,
      statusCode: statusCode,
    );
  }

  InputDecoration _deco(String label) =>
      InputDecoration(labelText: label, border: const OutlineInputBorder());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(_creation ? 'Nouvelle offre' : 'Publier une version'),
        backgroundColor: AppColors.prosocGreen,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: _isLoading
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.prosocGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(_creation ? 'Créer l\'offre' : 'Publier la version'),
                ),
              ),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ProsocResourceErrorView(message: _error!, onRetry: _load)
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_creation) ...[
                    DropdownButtonFormField<int>(
                      initialValue: _hopitalId,
                      isExpanded: true,
                      decoration: _deco('Hôpital partenaire'),
                      items: _hopitaux
                          .map(
                            (h) => DropdownMenuItem(
                              value: h.idHopital,
                              child: Text(h.nom),
                            ),
                          )
                          .toList(),
                      validator: (v) => v == null ? 'Champ requis.' : null,
                      onChanged: (v) => setState(() => _hopitalId = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: _categorieSoinId,
                      isExpanded: true,
                      decoration: _deco('Catégorie de soins'),
                      items: _categoriesSoins
                          .map(
                            (c) => DropdownMenuItem(value: c.id, child: Text(c.nom)),
                          )
                          .toList(),
                      validator: (v) => v == null ? 'Champ requis.' : null,
                      onChanged: (v) => setState(() => _categorieSoinId = v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nom,
                      maxLength: 200,
                      decoration: _deco('Nom de l\'offre'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Nom requis.' : null,
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'La version publiée sera immuable. Les périodes déjà '
                        'préparées conservent leur version et leur prix.',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _montant,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _deco('Prix mensuel'),
                          validator: _validerMontant,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _deviseId,
                          decoration: _deco('Devise'),
                          items: MedicalDevises.all
                              .map(
                                (d) => DropdownMenuItem(
                                  value: d.idDevise,
                                  child: Text(d.code),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _deviseId = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Taux de commission (%)',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.6,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 4,
                    children: [
                      for (final (label, controller) in [
                        ('AT', _tauxAT),
                        ('AA', _tauxAA),
                        ('AA Mash', _tauxMash),
                        ('AA Structure', _tauxStructure),
                      ])
                        TextFormField(
                          controller: controller,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _deco(label),
                          validator: _validerTaux,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Soins couverts (${_soinIds.length})',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _soins
                        .map(
                          (s) => FilterChip(
                            label: Text(s.nom),
                            selected: _soinIds.contains(s.id),
                            selectedColor: AppColors.prosocGreen.withValues(
                              alpha: 0.18,
                            ),
                            onSelected: (selected) => setState(() {
                              selected ? _soinIds.add(s.id) : _soinIds.remove(s.id);
                            }),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  MedicalSoinsSection(
                    title: 'Aperçu des soins',
                    soins: _soins
                        .where((s) => _soinIds.contains(s.id))
                        .map(
                          (s) => SoinCouvert(
                            soinId: s.id,
                            nom: s.nom,
                            description: s.description,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
    );
  }
}
