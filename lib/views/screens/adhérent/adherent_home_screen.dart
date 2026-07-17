import 'package:flutter/material.dart';

import '../../../config/api.dart';
import '../../../config/colors.dart';
import '../../../models/dashboard_affilie_model.dart';
import '../../../models/arriere_affilie_model.dart';
import '../../../models/penalite_affilie_model.dart';
import '../../../services/auth_service.dart';
import '../../../utils/api_error_helper.dart';
import '../../../utils/cotisation_montant_helper.dart';
import '../../../utils/formatters.dart';
import '../../widgets/prosoc_shimmer_loading.dart';
import '../../../widgets/souscription_bottom_sheet.dart';
import 'arrieres_affilie_screen.dart';

/// Accueil / dashboard affilié — données `/api/DashboardAffilie/resume/{affilieId}`.
class AdherentHomeScreen extends StatefulWidget {
  final VoidCallback? onPayCotisation;
  final VoidCallback? onOpenDemandeBon;
  final VoidCallback? onOpenDependants;

  const AdherentHomeScreen({
    super.key,
    this.onPayCotisation,
    this.onOpenDemandeBon,
    this.onOpenDependants,
  });

  @override
  State<AdherentHomeScreen> createState() => _AdherentHomeScreenState();
}

class _AdherentHomeScreenState extends State<AdherentHomeScreen> {
  DashboardAffilieResumeModel? _data;
  List<ArriereAffilieModel> _mesArrieres = [];
  List<PenaliteAffilieModel> _mesPenalites = [];
  bool _isLoading = true;
  bool _loadingArrieres = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard({bool silent = false}) async {
    final affilieId = AuthService.affilieId;
    if (affilieId == null || affilieId <= 0) {
      setState(() {
        _errorMessage =
            'Profil affilié introuvable. Reconnectez-vous ou contactez le support.';
        _isLoading = false;
      });
      return;
    }

    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final results = await Future.wait([
        ApiService.getDashboardAffilieResume(
          affilieId,
          annee: DateTime.now().year,
        ),
        ApiService.getMesArrieresAffilie(),
        ApiService.getMesPenalitesAffilie(),
      ]);

      if (!mounted) return;

      final resumeResponse =
          results[0] as ApiResponse<DashboardAffilieResumeModel>;
      final arrieresResponse =
          results[1] as ApiResponse<List<ArriereAffilieModel>>;
      final penalitesResponse =
          results[2] as ApiResponse<List<PenaliteAffilieModel>>;

      if (resumeResponse.success && resumeResponse.data != null) {
        setState(() {
          _data = resumeResponse.data;
          _mesArrieres = arrieresResponse.success
              ? (arrieresResponse.data ?? [])
              : _mesArrieres;
          _mesPenalites = penalitesResponse.success
              ? (penalitesResponse.data ?? [])
              : _mesPenalites;
          _errorMessage = null;
          _isLoading = false;
          _loadingArrieres = false;
        });
      } else {
        setState(() {
          if (!silent || _data == null) {
            _errorMessage =
                resumeResponse.message ??
                ApiErrorHelper.userFacingMessage(
                  statusCode: resumeResponse.statusCode,
                );
          }
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('AdherentHome', e, stackTrace, false);
      if (!mounted) return;
      setState(() {
        if (!silent || _data == null) {
          _errorMessage = ApiErrorHelper.userFacingNetwork();
        }
        _isLoading = false;
      });
    }
  }

  String _displayName() {
    final fromApi = _data?.informations.nomComplet.trim();
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;
    return AuthService.userName ?? 'Adhérent';
  }

  ({String nom, String prenom}) _splitDisplayName() {
    final full = _displayName().trim();
    final parts = full.split(RegExp(r'\s+'));
    if (parts.isEmpty) return (nom: '', prenom: '');
    if (parts.length == 1) return (nom: parts.first, prenom: '');
    return (nom: parts.sublist(1).join(' '), prenom: parts.first);
  }

  int get _arrieresImpayesCount =>
      _mesArrieres.where((arriere) => arriere.estImpaye).length;

  double get _arrieresTotalReste => _mesArrieres
      .where((arriere) => arriere.estImpaye)
      .fold<double>(
        0,
        (sum, arriere) =>
            sum +
            CotisationMontantHelper.resteArriereAvecPenalites(
              restAPayer: arriere.restAPayer,
              montantAttendu: arriere.montantAttendu,
              penalites: _mesPenalites,
              arrieresAffilieId: arriere.idArrieresAffilie,
            ),
      );

  void _openMesArrieres() {
    final names = _splitDisplayName();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ArrieresAffilieScreen.mesArrieres(
          affilieNom: names.nom,
          affiliePrenom: names.prenom,
        ),
      ),
    ).then((_) {
      if (mounted) _loadDashboard(silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenue,',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            Text(
              _displayName(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textPrimary,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.prosocGreen,
        onRefresh: () => _loadDashboard(silent: _data != null),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _data == null) {
      return ProsocHomeShimmer.adherent();
    }

    if (_errorMessage != null && _data == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          _buildErrorState(),
        ],
      );
    }

    if (_data == null) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: _buildContent(_data!),
    );
  }

  Widget _buildContent(DashboardAffilieResumeModel data) {
    final kpis = data.kpis;
    final info = data.informations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (info.codeAdhesion.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'N° adhésion : ${info.codeAdhesion}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
        _buildBalanceCard(kpis),
        const SizedBox(height: 8),
        _buildSectionTitle('Actions rapides'),
        const SizedBox(height: 12),
        _buildQuickActions(),
        const SizedBox(height: 20),
        _buildArrieresSection(),
        const SizedBox(height: 20),
        _buildKpiRow(kpis),

        if (data.documentsEnAttente.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSectionTitle('Documents en attente'),
          const SizedBox(height: 8),
          ...data.documentsEnAttente.take(3).map(_buildDocumentTile),
        ],
        if (data.prestationsRecentes.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSectionTitle('Prestations récentes'),
          const SizedBox(height: 8),
          ...data.prestationsRecentes.take(5).map(_buildPrestationTile),
        ],
        if (data.notificationsRecentes.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSectionTitle('Notifications'),
          const SizedBox(height: 8),
          ...data.notificationsRecentes.take(5).map(_buildNotificationTile),
        ],
        if (data.beneficiaires.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSectionTitle('Bénéficiaires (${data.beneficiaires.length})'),
          const SizedBox(height: 8),
          ...data.beneficiaires.take(4).map(_buildBeneficiaireChip),
        ],
      ],
    );
  }

  Widget _buildBalanceCard(DashboardAffilieKpis kpis) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.prosocGreen,
            AppColors.prosocGreen.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Solde disponible',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            AppFormatters.formatCurrencyDollar(kpis.soldeDisponible),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Solde total : ${AppFormatters.formatCurrencyDollar(kpis.soldeTotal)}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (kpis.nombreBeneficiaires > 0)
                _chip(
                  Icons.people_outline,
                  '${kpis.nombreBeneficiaires} bénéficiaire(s)',
                ),
              if (kpis.ancienneteMois > 0)
                _chip(Icons.schedule, '${kpis.ancienneteMois} mois'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow(DashboardAffilieKpis kpis) {
    return Row(
      children: [
        Expanded(
          child: _miniStat(
            'Cotisations',
            AppFormatters.formatCurrencyDollar(kpis.totalCotisations),
            Icons.payments_outlined,
            AppColors.prosocGreen,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniStat(
            'Prestations',
            AppFormatters.formatCurrencyDollar(kpis.totalPrestations),
            Icons.medical_services_outlined,
            const Color(0xFF2196F3),
          ),
        ),
      ],
    );
  }

  Widget _miniStat(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _quickAction(
                Icons.add_circle_outline,
                'Payer',
                AppColors.prosocGreen,
                widget.onPayCotisation,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _quickAction(
                Icons.medical_services_outlined,
                'Souscription',
                Colors.purple,
                _openSouscriptionPrestation,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _quickAction(
                Icons.receipt_long_outlined,
                'Demande Bon',
                Colors.blue,
                widget.onOpenDemandeBon,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _quickAction(
                Icons.people,
                'Dépendants',
                Colors.orange,
                () => widget.onOpenDependants?.call(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openSouscriptionPrestation() async {
    final affilieId = AuthService.affilieId;
    if (affilieId == null || affilieId <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil affilié introuvable.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    final info = _data?.informations;
    final nomComplet = info?.nomComplet ??
        AuthService.currentUser?.utilisateur.nomComplet ??
        '';
    final (prenom, nom) = _splitNomComplet(nomComplet);
    final telephone = info?.telephone.isNotEmpty == true
        ? info!.telephone
        : AuthService.currentUser?.utilisateur.telephone;

    final created = await SouscriptionBottomSheet.show(
      context,
      affilieId: affilieId,
      affilieNom: nom,
      affiliePrenom: prenom,
      affilieTelephone: telephone,
      allowVirtualAccount: false,
    );

    if (created == true && mounted) {
      await _loadDashboard(silent: _data != null);
    }
  }

  (String prenom, String nom) _splitNomComplet(String nomComplet) {
    final parts = nomComplet.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return ('', '');
    if (parts.length == 1) return (parts.first, '');
    return (parts.first, parts.sublist(1).join(' '));
  }

  Widget _buildArrieresSection() {
    if (_loadingArrieres && _mesArrieres.isEmpty) {
      return ProsocHomeShimmer.sectionCard(context);
    }

    final impayes = _arrieresImpayesCount;
    final hasArrieres = _mesArrieres.isNotEmpty;
    final accentColor =
        impayes > 0 ? AppColors.warningColor : AppColors.prosocGreen;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: _openMesArrieres,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accentColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.history_toggle_off_rounded,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mes arriérés',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      impayes > 0
                          ? '$impayes impayé${impayes > 1 ? 's' : ''} · '
                              'Reste ${AppFormatters.formatCurrencyDollar(_arrieresTotalReste)}'
                          : hasArrieres
                              ? 'Toutes vos obligations sont à jour'
                              : 'Aucun arriéré enregistré',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback? onTap,
  ) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrestationTile(DashboardAffiliePrestation p) {
    return _listTile(
      icon: Icons.local_hospital_outlined,
      title: p.prestationNom.isNotEmpty ? p.prestationNom : p.typePrestation,
      subtitle: [
        if (p.beneficiaire.isNotEmpty) p.beneficiaire,
        if (p.datePrestation != null)
          AppFormatters.formatDate(p.datePrestation),
        p.statut,
      ].where((s) => s.isNotEmpty).join(' · '),
      trailing: AppFormatters.formatCurrencyDollar(p.montantPriseEnCharge),
      trailingColor: const Color(0xFF2196F3),
    );
  }

  Widget _buildNotificationTile(DashboardAffilieNotification n) {
    return _listTile(
      icon: n.estLue ? Icons.notifications_none : Icons.notifications_active,
      title: n.titre.isNotEmpty ? n.titre : n.typeNotification,
      subtitle: n.message,
      trailing: n.dateNotification != null
          ? AppFormatters.formatDate(n.dateNotification)
          : null,
      trailingColor: Colors.grey.shade600,
    );
  }

  Widget _buildDocumentTile(DashboardAffilieDocument d) {
    return _listTile(
      icon: Icons.description_outlined,
      title: d.nomDocument.isNotEmpty ? d.nomDocument : d.typeDocument,
      subtitle: d.estObligatoire ? 'Obligatoire' : 'Facultatif',
      trailing: d.estValide ? 'Validé' : 'En attente',
      trailingColor: d.estValide
          ? AppColors.prosocGreen
          : AppColors.warningColor,
    );
  }

  Widget _buildBeneficiaireChip(DashboardAffilieBeneficiaire b) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _listTile(
        icon: Icons.person_outline,
        title: b.nomComplet,
        subtitle: [
          if (b.lienParente.isNotEmpty) b.lienParente,
          b.typeBeneficiaire,
          if (!b.estActif) 'Inactif',
        ].where((s) => s.isNotEmpty).join(' · '),
        trailing: b.estPrincipal ? 'Principal' : null,
        trailingColor: AppColors.prosocGreen,
      ),
    );
  }

  Widget _listTile({
    required IconData icon,
    required String title,
    required String subtitle,
    String? trailing,
    Color? trailingColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.prosocGreen, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Text(
              trailing,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: trailingColor ?? AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Erreur',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loadDashboard,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.prosocGreen,
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
