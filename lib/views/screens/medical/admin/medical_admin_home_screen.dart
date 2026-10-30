import 'package:flutter/material.dart';

import '../../../../config/api.dart';
import '../../../../config/colors.dart';
import '../../../../models/hopital_partenaire_model.dart';
import '../../../../models/medical/catalogue_medical_model.dart';
import '../../../../utils/medical_permissions.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/prosoc_message_dialog.dart';
import '../../../widgets/prosoc_resource_error_view.dart';
import 'medical_offres_admin_screen.dart';

/// Administration du catalogue médical (permissions produit mutuel/assureur).
class MedicalAdminHomeScreen extends StatelessWidget {
  const MedicalAdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void ouvrir(Widget screen) => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Catalogue médical'),
        backgroundColor: AppColors.prosocGreen,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(
            icon: Icons.inventory_2_outlined,
            title: 'Offres par hôpital',
            subtitle: 'Créer, publier une version, retirer',
            onTap: () => ouvrir(const MedicalOffresAdminScreen()),
          ),
          const SizedBox(height: 8),
          for (final type in ReferentielMedicalType.values) ...[
            _tile(
              icon: Icons.list_alt_outlined,
              title: type.label,
              subtitle: 'Référentiel',
              onTap: () => ouvrir(MedicalReferentielsAdminScreen(type: type)),
            ),
            const SizedBox(height: 8),
          ],
          if (MedicalPermissions.peutModifierProduit)
            _tile(
              icon: Icons.local_hospital_outlined,
              title: 'Catégorie des hôpitaux',
              subtitle: 'Classification descriptive',
              onTap: () => ouvrir(const MedicalHopitauxCategorieScreen()),
            ),
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.prosocGreen),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

/// Liste, création et modification d'un référentiel.
class MedicalReferentielsAdminScreen extends StatefulWidget {
  const MedicalReferentielsAdminScreen({super.key, required this.type});

  final ReferentielMedicalType type;

  @override
  State<MedicalReferentielsAdminScreen> createState() =>
      _MedicalReferentielsAdminScreenState();
}

class _MedicalReferentielsAdminScreenState
    extends State<MedicalReferentielsAdminScreen> {
  List<ReferentielMedical> _items = const [];
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
    final response = await ApiService.getReferentielsMedicaux(widget.type);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _items = response.data ?? _items;
      _error = response.success ? null : response.message;
      _errorStatus = response.statusCode;
    });
  }

  Future<void> _editer([ReferentielMedical? item]) async {
    final saved = await showDialog<ReferentielMedical>(
      context: context,
      builder: (_) => _ReferentielDialog(type: widget.type, item: item),
    );
    if (saved != null) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.type.label),
        backgroundColor: AppColors.prosocGreen,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: MedicalPermissions.peutCreerProduit
          ? FloatingActionButton(
              onPressed: () => _editer(),
              backgroundColor: AppColors.prosocGreen,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
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
            : _items.isEmpty
            ? ListView(
                children: const [
                  EmptyStateWidget(
                    icon: Icons.list_alt_outlined,
                    title: 'Aucun élément',
                    expandVertically: false,
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final item = _items[i];
                  return Card(
                    child: ListTile(
                      title: Text(item.nom),
                      subtitle: item.description == null
                          ? null
                          : Text(item.description!),
                      trailing: Icon(
                        item.statut ? Icons.check_circle : Icons.block,
                        color: item.statut ? AppColors.prosocGreen : Colors.grey,
                      ),
                      onTap: MedicalPermissions.peutModifierProduit
                          ? () => _editer(item)
                          : null,
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _ReferentielDialog extends StatefulWidget {
  const _ReferentielDialog({required this.type, this.item});

  final ReferentielMedicalType type;
  final ReferentielMedical? item;

  @override
  State<_ReferentielDialog> createState() => _ReferentielDialogState();
}

class _ReferentielDialogState extends State<_ReferentielDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nom;
  late final TextEditingController _description;
  late bool _statut;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nom = TextEditingController(text: widget.item?.nom ?? '');
    _description = TextEditingController(text: widget.item?.description ?? '');
    _statut = widget.item?.statut ?? true;
  }

  @override
  void dispose() {
    _nom.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    final description = _description.text.trim();
    final response = await ApiService.saveReferentielMedical(
      widget.type,
      id: widget.item?.id,
      nom: _nom.text.trim(),
      description: description.isEmpty ? null : description,
      statut: _statut,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (response.success && response.data != null) {
      Navigator.of(context).pop(response.data);
      return;
    }
    await ProsocMessageDialog.show(
      context,
      variant: ProsocMessageVariant.error,
      title: 'Enregistrement impossible',
      message: response.message ?? 'L\'élément n\'a pas pu être enregistré.',
      statusCode: response.statusCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Nouvel élément' : 'Modifier'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nom,
                maxLength: 200,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nom requis.' : null,
              ),
              TextFormField(
                controller: _description,
                maxLength: 1000,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (facultative)',
                ),
              ),
              SwitchListTile(
                value: _statut,
                onChanged: (v) => setState(() => _statut = v),
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.prosocGreen,
                title: const Text('Actif'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.prosocGreen,
            foregroundColor: Colors.white,
          ),
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

/// Classification descriptive des hôpitaux partenaires.
class MedicalHopitauxCategorieScreen extends StatefulWidget {
  const MedicalHopitauxCategorieScreen({super.key});

  @override
  State<MedicalHopitauxCategorieScreen> createState() =>
      _MedicalHopitauxCategorieScreenState();
}

class _MedicalHopitauxCategorieScreenState
    extends State<MedicalHopitauxCategorieScreen> {
  List<HopitalPartenaireModel> _hopitaux = const [];
  List<ReferentielMedical> _categories = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      ApiService.getHopitauxPartenairesActifs(),
      ApiService.getReferentielsMedicaux(ReferentielMedicalType.categoriesHopitaux),
    ]);
    if (!mounted) return;
    final hopitaux = results[0] as ApiResponse<List<HopitalPartenaireModel>>;
    final categories = results[1] as ApiResponse<List<ReferentielMedical>>;
    setState(() {
      _isLoading = false;
      _hopitaux = hopitaux.data ?? const [];
      _categories = (categories.data ?? const [])
          .where((c) => c.statut)
          .toList();
      _error = hopitaux.success && categories.success
          ? null
          : (hopitaux.message ?? categories.message);
    });
  }

  Future<void> _classer(HopitalPartenaireModel hopital) async {
    final categorie = await showModalBottomSheet<ReferentielMedical>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(
                hopital.nom,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Choisir la catégorie'),
            ),
            ..._categories.map(
              (c) => ListTile(
                title: Text(c.nom),
                onTap: () => Navigator.of(sheetContext).pop(c),
              ),
            ),
          ],
        ),
      ),
    );
    if (categorie == null || !mounted) return;
    final response = await ApiService.setCategorieHopital(
      hopital.idHopital,
      categorie.id,
    );
    if (!mounted) return;
    await ProsocMessageDialog.show(
      context,
      variant: response.success
          ? ProsocMessageVariant.success
          : ProsocMessageVariant.error,
      title: response.success ? 'Catégorie enregistrée' : 'Échec',
      message: response.success
          ? '${hopital.nom} : ${categorie.nom}.'
          : (response.message ?? 'La catégorie n\'a pas pu être enregistrée.'),
      statusCode: response.success ? null : response.statusCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Catégorie des hôpitaux'),
        backgroundColor: AppColors.prosocGreen,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ProsocResourceErrorView(message: _error!, onRetry: _load)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _hopitaux.length,
              itemBuilder: (_, i) {
                final h = _hopitaux[i];
                return Card(
                  child: ListTile(
                    title: Text(h.nom),
                    subtitle: Text(h.adresse),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: _categories.isEmpty ? null : () => _classer(h),
                  ),
                );
              },
            ),
    );
  }
}
