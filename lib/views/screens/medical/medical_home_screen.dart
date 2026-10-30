import 'package:flutter/material.dart';

import '../../../config/api.dart';
import '../../../config/colors.dart';
import '../../../models/medical/catalogue_medical_model.dart';
import '../../../models/medical/souscription_medicale_model.dart';
import '../../../utils/medical_permissions.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/prosoc_resource_error_view.dart';
import 'medical_catalogue_screen.dart';
import 'medical_souscription_screen.dart';
import 'widgets/medical_ui.dart';

/// Rubrique « Prestations médicales » d'un affilié (membre ou personnel).
/// Distincte du parcours historique des prestations.
class MedicalHomeScreen extends StatefulWidget {
  const MedicalHomeScreen({
    super.key,
    required this.affilieId,
    this.affilieNom,
  });

  final int affilieId;
  final String? affilieNom;

  @override
  State<MedicalHomeScreen> createState() => _MedicalHomeScreenState();
}

class _MedicalHomeScreenState extends State<MedicalHomeScreen>
    with WidgetsBindingObserver, MedicalResumeRefresh {
  List<SouscriptionMedicale> _souscriptions = const [];
  final Map<int, OffreMedicale> _offres = {};
  bool _isLoading = true;
  String? _error;
  int? _errorStatus;

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
    final response = await ApiService.getSouscriptionsMedicalesByAffilie(
      widget.affilieId,
    );
    if (!mounted) return;
    if (!response.success || response.data == null) {
      setState(() {
        _isLoading = false;
        _error = response.message;
        _errorStatus = response.statusCode;
      });
      return;
    }
    final souscriptions = response.data!;
    // Libellés d'offre : une lecture par offre souscrite.
    for (final id in souscriptions.map((s) => s.offreMedicaleHopitalId).toSet()) {
      if (_offres.containsKey(id)) continue;
      final offre = await ApiService.getOffreMedicale(id);
      if (offre.success && offre.data != null) _offres[id] = offre.data!;
    }
    if (!mounted) return;
    setState(() {
      _souscriptions = souscriptions;
      _isLoading = false;
      _error = null;
    });
  }

  /// Un affilié reste rattaché à un seul hôpital.
  int? get _hopitalVerrouille => _souscriptions.isEmpty
      ? null
      : _souscriptions.first.hopitalPartenaireId;

  Future<void> _ouvrirCatalogue() async {
    final created = await Navigator.of(context).push<SouscriptionMedicale>(
      MaterialPageRoute(
        builder: (_) => MedicalCatalogueScreen(
          affilieId: widget.affilieId,
          hopitalId: _hopitalVerrouille,
        ),
      ),
    );
    await _load(showLoader: false);
    if (created != null && mounted) _ouvrirSouscription(created);
  }

  void _ouvrirSouscription(SouscriptionMedicale souscription) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MedicalSouscriptionScreen(
          souscription: souscription,
          affilieNom: widget.affilieNom,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Prestations médicales'),
        backgroundColor: AppColors.prosocGreen,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: MedicalPermissions.peutSouscrire && !_isLoading
          ? FloatingActionButton.extended(
              onPressed: _ouvrirCatalogue,
              backgroundColor: AppColors.prosocGreen,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Souscrire une offre'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => _load(showLoader: false),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        if (widget.affilieNom != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              widget.affilieNom!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Souscrire ne suffit pas pour être couvert : chaque mois doit être '
            'préparé puis payé intégralement pour ouvrir les droits.',
            style: TextStyle(fontSize: 12.5, color: Colors.blue.shade900),
          ),
        ),
        if (_souscriptions.isEmpty)
          const EmptyStateWidget(
            icon: Icons.medical_services_outlined,
            title: 'Aucune souscription médicale',
            subtitle: 'Choisissez une offre de votre hôpital pour commencer.',
            expandVertically: false,
          )
        else
          ..._souscriptions.map(_buildSouscriptionCard),
      ],
    );
  }

  Widget _buildSouscriptionCard(SouscriptionMedicale s) {
    final offre = _offres[s.offreMedicaleHopitalId];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: Color(0x1A2DB467),
          child: Icon(Icons.local_hospital_outlined, color: AppColors.prosocGreen),
        ),
        title: Text(
          offre?.nom ?? 'Offre #${s.offreMedicaleHopitalId}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          [
            offre?.hopitalNom,
            offre?.categorieSoinNom,
            'Depuis le ${MedicalFormat.date(s.dateSouscriptionUtc)}',
          ].whereType<String>().join(' · '),
        ),
        trailing: s.statut
            ? const Icon(Icons.chevron_right)
            : const MedicalBadge(label: 'Inactive', color: Colors.grey),
        onTap: () => _ouvrirSouscription(s),
      ),
    );
  }
}
