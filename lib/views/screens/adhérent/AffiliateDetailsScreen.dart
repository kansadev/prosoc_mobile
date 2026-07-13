import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:prosoc/config/api.dart';
import 'package:prosoc/config/colors.dart';
import 'package:prosoc/models/dependant_model.dart';
import 'package:prosoc/models/recent_affilie_model.dart';
import 'package:prosoc/models/arriere_affilie_model.dart';
import 'package:prosoc/utils/api_error_helper.dart';
import 'package:prosoc/utils/arriere_payment_navigator.dart';
import 'package:prosoc/utils/formatters.dart';
import 'package:prosoc/utils/paginated_response_helper.dart';
import 'widgets/payer_contributionScreen.dart';
import 'widgets/payer_souscription_screen.dart';
import 'widgets/payer_frais_screen.dart';
import 'arrieres_affilie_screen.dart';
import 'package:prosoc/widgets/antecedent_bottom_sheet.dart';
import 'package:prosoc/widgets/dependant_bottom_sheet.dart';
import 'package:prosoc/widgets/souscription_bottom_sheet.dart';
import 'package:prosoc/widgets/popup_menu_widget.dart';

class AffiliateDetailsScreen extends StatefulWidget {
  final int affilieId;
  final RecentAffilieModel? preview;

  const AffiliateDetailsScreen({
    super.key,
    required this.affilieId,
    this.preview,
  });

  @override
  State<AffiliateDetailsScreen> createState() => _AffiliateDetailsScreenState();
}

class _AffiliateDetailsScreenState extends State<AffiliateDetailsScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _data;
  List<Dependant> _dependants = [];
  int _dependantsTotal = 0;
  bool _isLoadingDependants = false;
  List<dynamic> _souscriptions = [];
  bool _isLoadingSouscriptions = false;
  List<ArriereAffilieModel> _arrieres = [];
  bool _isLoadingArrieres = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  String _resolveTypeAdhesionLibelle() {
    final api = _apiData;
    final fromApi = _stringFrom(api, [
      'typeAdhesionLibelle',
      'typeAdhesion',
      'libelleTypeAdhesion',
    ]);
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;

    final root = _data ?? const <String, dynamic>{};
    final adhesion = root['adhesion'];
    if (adhesion is Map) {
      final adhesionMap = adhesion is Map<String, dynamic>
          ? adhesion
          : Map<String, dynamic>.from(adhesion);
      final fromAdhesion = _stringFrom(adhesionMap, [
        'typeAdhesionLibelle',
        'typeAdhesion',
      ]);
      if (fromAdhesion != null && fromAdhesion.isNotEmpty) return fromAdhesion;
    }

    return widget.preview?.typeAdhesion ?? '';
  }

  bool get _isSoloAdhesion {
    final label = _resolveTypeAdhesionLibelle().toLowerCase().trim();
    if (label.isEmpty) return false;
    return label.contains('solo');
  }

  void _showSoloDependantsLockedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Adhésion Solo : l\'ajout de dépendants n\'est pas autorisé.',
        ),
        backgroundColor: Colors.orange.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadAffilie();
    _loadDependants();
    _loadSouscriptions();
    _loadArrieres();

    // Animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _animationController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadAffilie() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getAffilie(widget.affilieId);
      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _data = response.data;
          _isLoading = false;
        });
        _loadDependants();
      } else {
        setState(() {
          _errorMessage =
              response.message ??
              ApiErrorHelper.userFacingMessage(statusCode: response.statusCode);
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('AffiliateDetails', e, stackTrace);
      if (!mounted) return;
      setState(() {
        _errorMessage = ApiErrorHelper.userFacingNetwork();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDependants() async {
    setState(() {
      _isLoadingDependants = true;
    });

    try {
      final response = await ApiService.getDependantsByAffilie(
        widget.affilieId,
      );
      if (!mounted) return;

      final payload = response.data;
      if (response.success && payload != null) {
        final rows = PaginatedResponseHelper.extractRows(payload);
        final dependants = <Dependant>[];
        for (final item in rows) {
          if (item is! Map) continue;
          try {
            final map = item is Map<String, dynamic>
                ? item
                : Map<String, dynamic>.from(item);
            dependants.add(Dependant.fromJson(map));
          } catch (e, stackTrace) {
            ApiErrorHelper.logException('Dependant/fromJson', e, stackTrace);
          }
        }

        if (kDebugMode) {
          debugPrint(
            '[Dependants] affilieId=${widget.affilieId} '
            'status=${response.statusCode} rows=${dependants.length} '
            'total=${PaginatedResponseHelper.extractTotalItems(payload)}',
          );
        }

        setState(() {
          _dependants = dependants;
          _dependantsTotal = PaginatedResponseHelper.extractTotalItems(
            payload,
            fallback: dependants.length,
          );
          _isLoadingDependants = false;
        });
      } else {
        if (kDebugMode) {
          debugPrint(
            '[Dependants] échec affilieId=${widget.affilieId} '
            'success=${response.success} status=${response.statusCode}',
          );
        }
        setState(() {
          _dependants = [];
          _dependantsTotal = 0;
          _isLoadingDependants = false;
        });
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('Dependant/by-affilie', e, stackTrace);
      if (!mounted) return;
      setState(() {
        _dependants = [];
        _dependantsTotal = 0;
        _isLoadingDependants = false;
      });
    }
  }

  String _formatDependantBirthDate(DateTime? date) {
    if (date == null) return '';
    return AppFormatters.formatDate(date);
  }

  Future<void> _loadSouscriptions() async {
    setState(() {
      _isLoadingSouscriptions = true;
    });

    try {
      final response = await ApiService.getSouscriptionsByAffilie(
        widget.affilieId,
      );
      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _souscriptions = response.data as List<dynamic>;
          _isLoadingSouscriptions = false;
        });
      } else {
        setState(() {
          _isLoadingSouscriptions = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingSouscriptions = false;
      });
    }
  }

  Future<void> _loadArrieres() async {
    setState(() {
      _isLoadingArrieres = true;
    });

    try {
      final response = await ApiService.getArrieresAffilie(widget.affilieId);
      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _arrieres = response.data!;
          _isLoadingArrieres = false;
        });
      } else {
        setState(() {
          _arrieres = [];
          _isLoadingArrieres = false;
        });
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('ArriereAffilie/details', e, stackTrace);
      if (!mounted) return;
      setState(() {
        _arrieres = [];
        _isLoadingArrieres = false;
      });
    }
  }

  List<ArriereAffilieModel> get _sortedArrieres {
    final copy = List<ArriereAffilieModel>.from(_arrieres);
    copy.sort((a, b) {
      if (a.estImpaye != b.estImpaye) {
        return a.estImpaye ? -1 : 1;
      }
      return b.restAPayer.compareTo(a.restAPayer);
    });
    return copy;
  }

  int get _arrieresImpayesCount =>
      _arrieres.where((arriere) => arriere.estImpaye).length;

  double get _arrieresTotalReste => _arrieres
      .where((arriere) => arriere.estImpaye)
      .fold<double>(0, (sum, arriere) => sum + arriere.restAPayer);

  Map<String, dynamic> get _apiData {
    final data = _data ?? const <String, dynamic>{};
    final nested = data['affilie'];
    if (nested is Map<String, dynamic>) return nested;
    if (nested is Map) return Map<String, dynamic>.from(nested);
    return data;
  }

  String? _stringFrom(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  DateTime? _dateFrom(Map<String, dynamic> data, List<String> keys) {
    final raw = _stringFrom(data, keys);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  bool? _boolFrom(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true') return true;
        if (normalized == 'false') return false;
      }
    }
    return null;
  }

  String _initials(String prenom, String nom) {
    final p = prenom.trim();
    final n = nom.trim();
    final a = p.isNotEmpty ? p[0].toUpperCase() : '?';
    final b = n.isNotEmpty ? n[0].toUpperCase() : '?';
    return '$a$b';
  }

  String? _formatAddress(Map<String, dynamic> data) {
    final adresse = _stringFrom(data, [
      'adresseAffilie',
      'adresseResidence',
      'adresse',
    ]);
    if (adresse != null && adresse.trim().isNotEmpty) return adresse.trim();

    final numero = _stringFrom(data, [
      'numeroResidence',
      'numeroResidenceAffilie',
    ]);
    final avenue = _stringFrom(data, [
      'avenueResidence',
      'avenueResidenceAffilie',
    ]);
    final quartier = _stringFrom(data, [
      'quartierResidence',
      'quartierResidenceAffilie',
    ]);
    final commune = _stringFrom(data, [
      'communeResidence',
      'communeResidenceAffilie',
    ]);

    final parts = <String>[];
    if ((numero != null && numero.isNotEmpty) ||
        (avenue != null && avenue.isNotEmpty)) {
      final firstParts = <String>[];
      if (numero != null && numero.isNotEmpty) firstParts.add(numero);
      if (avenue != null && avenue.isNotEmpty) firstParts.add('Av. $avenue');
      parts.add(firstParts.join(', '));
    }
    if (quartier != null && quartier.isNotEmpty) parts.add('Q/$quartier');
    if (commune != null && commune.isNotEmpty) parts.add(commune);

    final result = parts.join(', ').trim();
    return result.isEmpty ? null : result;
  }

  @override
  Widget build(BuildContext context) {
    final api = _apiData;

    final nom =
        _stringFrom(api, ['nom', 'nomAffilie']) ?? widget.preview?.nom ?? '';
    final prenom =
        _stringFrom(api, ['prenom', 'prenomAffilie']) ??
        widget.preview?.prenom ??
        '';
    final postnom = _stringFrom(api, ['postnom', 'postnomAffilie']) ?? '';
    final nomComplet =
        _stringFrom(api, ['nomComplet']) ??
        [
          nom,
          postnom,
          prenom,
        ].where((e) => e.trim().isNotEmpty).join(' ').trim();

    final telephone =
        _stringFrom(api, ['telephone', 'phone', 'telephoneAffilie']) ??
        widget.preview?.telephone ??
        '';
    final email = _stringFrom(api, ['emailAffilie', 'email']) ?? '';

    final dateNaissance = _dateFrom(api, [
      'dateNaissance',
      'dateNaissanc',
      'datenaissance',
      'dateN',
    ]);
    final dateCreation = _dateFrom(api, [
      'dateCreation',
      'dateCreationAffilie',
    ]);
    final dateAdhesion =
        _dateFrom(api, ['dateAdhesion']) ??
        widget.preview?.dateAdhesion ??
        dateCreation;

    final provinceResidence =
        _stringFrom(api, ['provinceResidence', 'province']) ?? '';
    final communeResidence =
        _stringFrom(api, ['communeResidence', 'commune']) ?? '';

    final codeAdhesion =
        _stringFrom(api, ['codeAdhesion', 'matricule', 'matriculeAffilie']) ??
        '';
    final statut = _boolFrom(api, ['statut', 'statutAffilie']) ?? true;

    final canRenderPreview = widget.preview != null;
    if (_isLoading && _data == null && !canRenderPreview) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.prosocGreen),
        ),
      );
    }

    if (_errorMessage != null && _data == null && !canRenderPreview) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                const SizedBox(height: 12),
                Text(
                  _errorMessage ?? 'Erreur de chargement',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade400),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadAffilie,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.prosocGreen,
                  ),
                  child: const Text(
                    'Réessayer',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final badgeText = codeAdhesion.trim().isNotEmpty
        ? codeAdhesion.trim()
        : (widget.preview?.typeAdhesion.trim().isNotEmpty == true
              ? widget.preview!.typeAdhesion.trim()
              : 'Affilié #${widget.affilieId}');

    final address = _formatAddress(api);

    final headerNameParts = <String>[];
    if (prenom.trim().isNotEmpty) headerNameParts.add(prenom.trim());
    if (nom.trim().isNotEmpty) headerNameParts.add(nom.trim());
    final headerName = headerNameParts.join(' ').trim();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Content
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildProfileHeader(
                      initials: _initials(prenom, nom),
                      name: headerName.isEmpty ? 'Affilié' : headerName,
                      badge: badgeText,
                      statut: statut,
                    ),

                    const SizedBox(height: 20),

                    // Main Content Cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          // Quick Stats
                          _buildQuickStats(
                            telephone: telephone,
                            email: email,
                            dateNaissance: dateNaissance,
                          ),

                          const SizedBox(height: 20),

                          // Personal Information Card
                          _buildModernCard(
                            title: "Informations Personnelles",
                            icon: Icons.person_outline,
                            children: [
                              _buildInfoRow("Nom Complet", nomComplet),
                              _buildInfoRow(
                                "Date de Naissance",
                                AppFormatters.formatDate(dateNaissance),
                              ),
                              _buildInfoRow("Téléphone", telephone),
                              _buildInfoRow("Email", email),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Location Card
                          _buildModernCard(
                            title: "Localisation",
                            icon: Icons.location_on_outlined,
                            children: [
                              _buildInfoRow("Province", provinceResidence),
                              _buildInfoRow("Commune", communeResidence),
                              _buildInfoRow("Adresse", address),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Status Card
                          _buildModernCard(
                            title: "Statut d'Adhésion",
                            icon: Icons.verified_outlined,
                            children: [
                              _buildInfoRow(
                                "Code Adhésion",
                                codeAdhesion,
                                isBold: true,
                              ),
                              _buildInfoRow(
                                "Date d'Inscription",
                                AppFormatters.formatDate(dateAdhesion),
                              ),
                              _buildInfoRow(
                                "État du Compte",
                                statut ? "ACTIF" : "INACTIF",
                                textColor: statut
                                    ? AppColors.prosocGreen
                                    : Colors.red.shade400,
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          if (!_isSoloAdhesion || _dependants.isNotEmpty) ...[
                            _buildDependantsCard(),
                            const SizedBox(height: 16),
                          ],
                          _buildArrieresCard(),
                          const SizedBox(height: 16),
                          _buildSouscriptionsCard(),

                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            _buildErrorCard(),
                          ],

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading indicator
          if (_isLoading)
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LinearProgressIndicator(
                color: AppColors.prosocGreen,
                backgroundColor: Colors.transparent,
                minHeight: 2,
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToContributionScreen,
        backgroundColor: AppColors.prosocGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.payments_outlined),
        label: const Text('Payer une cotisation'),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textPrimary,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.preview != null
            ? '${widget.preview!.prenom} ${widget.preview!.nom}'
            : 'Profil Affilié',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      actions: [
        AffiliatePopupMenuWidget(
          onCollecte: _navigateToContributionScreen,
          onPayerFrais: _navigateToPayerFraisScreen,
          onPayerSouscription: _navigateToPayerSouscriptionScreen,
          onDependants: _isSoloAdhesion ? null : _showAddDependantBottomSheet,
          onSouscription: _showSouscriptionBottomSheet,
          onAntecedents: _showAddAntecedentBottomSheet,
          onArrieres: _navigateToArrieresScreen,
        ),
      ],
    );
  }

  Widget _buildProfileHeader({
    required String initials,
    required String name,
    required String badge,
    required bool statut,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          // Avatar with status indicator
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.prosocGreen.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.prosocGreen,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: statut ? AppColors.prosocGreen : Colors.red.shade400,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: statut
                      ? Icon(Icons.check, color: Colors.white, size: 12)
                      : Icon(Icons.close, color: Colors.white, size: 12),
                ),
              ),
            ],
          ),

          const SizedBox(width: 20),

          // Name and badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.prosocGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: AppColors.prosocGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats({
    required String telephone,
    required String email,
    required DateTime? dateNaissance,
  }) {
    // Calcul de l'âge
    String age;
    if (dateNaissance != null) {
      final now = DateTime.now();
      int calculatedAge = now.year - dateNaissance.year;

      // Ajuster si l'anniversaire n'est pas encore passé cette année
      if (now.month < dateNaissance.month ||
          (now.month == dateNaissance.month && now.day < dateNaissance.day)) {
        calculatedAge--;
      }

      age = "$calculatedAge ans";
    } else {
      age = "N/A";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.phone_outlined,
              label: "Téléphone",
              value: telephone.isNotEmpty ? telephone : "Non défini",
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          Expanded(
            child: _buildStatItem(
              icon: Icons.email_outlined,
              label: "Email",
              value: email.isNotEmpty ? email : "Non défini",
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          Expanded(
            child: _buildStatItem(
              icon: Icons.cake_outlined,
              label: "Âge",
              value: age,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.prosocGreen, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildModernCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.prosocGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.prosocGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            color: Colors.grey.shade200,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildDependantsCard() {
    final isLocked = _isSoloAdhesion;

    return Opacity(
      opacity: isLocked ? 0.65 : 1,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isLocked ? Border.all(color: Colors.grey.shade300) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isLocked
                          ? Colors.grey.shade200
                          : AppColors.prosocGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isLocked ? Icons.lock_outline : Icons.people,
                      color: isLocked
                          ? Colors.grey.shade600
                          : AppColors.prosocGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _dependantsTotal > 0
                              ? 'Dépendants ($_dependantsTotal)'
                              : 'Dépendants',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isLocked)
                          Text(
                            'Non disponible (adhésion Solo)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!isLocked)
                    TextButton.icon(
                      onPressed: _showAddDependantBottomSheet,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Ajouter'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.prosocGreen,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              height: 1,
              color: Colors.grey.shade200,
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: isLocked && _dependants.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            Icon(
                              Icons.person_off_outlined,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Cette adhésion Solo ne permet pas de personnes à charge.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _isLoadingDependants
                  ? const Center(child: CircularProgressIndicator())
                  : _dependants.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Aucun dépendant',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _dependants.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final dependant = _dependants[index];
                        final birthLabel = _formatDependantBirthDate(
                          dependant.dateNaissance,
                        );
                        final subtitleParts = <String>[
                          dependant.lienParenteLabel,
                          if (birthLabel.isNotEmpty) 'Né(e) le $birthLabel',
                        ];

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          isThreeLine:
                              dependant.adresse != null &&
                              dependant.adresse!.isNotEmpty,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.prosocGreen.withValues(
                              alpha: 0.1,
                            ),
                            child: Text(
                              dependant.nom.isNotEmpty
                                  ? dependant.nom[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: AppColors.prosocGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            dependant.nom,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(subtitleParts.join(' • ')),
                              if (dependant.adresse != null &&
                                  dependant.adresse!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    dependant.adresse!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: dependant.statut
                                      ? AppColors.prosocGreen.withValues(
                                          alpha: 0.1,
                                        )
                                      : Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  dependant.statut ? 'Actif' : 'Inactif',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: dependant.statut
                                        ? AppColors.prosocGreen
                                        : Colors.red,
                                  ),
                                ),
                              ),
                              if (dependant.possedeCertificatScolarite) ...[
                                const SizedBox(height: 4),
                                Icon(
                                  Icons.school_outlined,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArrieresCard() {
    final previewItems = _sortedArrieres.take(3).toList();
    final hasMore = _arrieres.length > previewItems.length;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warningColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.history_toggle_off_rounded,
                    color: AppColors.warningColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Arriérés',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_arrieresImpayesCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warningColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$_arrieresImpayesCount impayé${_arrieresImpayesCount > 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: AppColors.warningColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: Colors.grey.shade200,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _isLoadingArrieres
                ? const Center(child: CircularProgressIndicator())
                : _arrieres.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Aucun arriéré',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_arrieresImpayesCount > 0)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppColors.warningColor
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Reste à payer : ${AppFormatters.formatCurrencyDollar(_arrieresTotalReste)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.warningColor,
                                ),
                              ),
                            ),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: previewItems.length,
                            separatorBuilder: (context, index) =>
                                const Divider(),
                            itemBuilder: (context, index) {
                              final arriere = previewItems[index];
                              final isImpaye = arriere.estImpaye;
                              final statusColor = isImpaye
                                  ? AppColors.warningColor
                                  : AppColors.prosocGreen;

                              return Column(
                                children: [
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          statusColor.withValues(alpha: 0.1),
                                      child: Icon(
                                        Icons.receipt_long_outlined,
                                        color: statusColor,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      arriere.titre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          arriere.typeObligationLabel,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        if (arriere.periode.isNotEmpty)
                                          Text(
                                            arriere.periode,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          AppFormatters.formatCurrencyDollar(
                                            arriere.restAPayer,
                                          ),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: statusColor,
                                          ),
                                        ),
                                        Text(
                                          arriere.statutPaiement.isNotEmpty
                                              ? arriere.statutPaiement
                                              : (isImpaye ? 'Impayé' : 'Payé'),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isImpaye)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: () => _payerArriere(arriere),
                                        icon: const Icon(
                                          Icons.payments_outlined,
                                          size: 18,
                                        ),
                                        label: const Text('Payer'),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          if (hasMore || _arrieres.isNotEmpty)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _navigateToArrieresScreen,
                                child: const Text('Voir tout'),
                              ),
                            ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSouscriptionsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.prosocGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.description,
                    color: AppColors.prosocGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Souscriptions',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            color: Colors.grey.shade200,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: _isLoadingSouscriptions
                ? const Center(child: CircularProgressIndicator())
                : _souscriptions.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Aucune subscription',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _souscriptions.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final souscription =
                          _souscriptions[index] as Map<String, dynamic>;
                      final prestationNom = souscription['prestationNom'] ?? '';
                      final dateSouscription = souscription['dateSouscription'];
                      final statut = souscription['statut'] as bool? ?? false;
                      final nombreCollectes =
                          souscription['nombreCollectes'] ?? 0;
                      final totalCollectes =
                          souscription['totalCollectes'] ?? 0;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.prosocGreen.withValues(
                            alpha: 0.1,
                          ),
                          child: const Icon(
                            Icons.description,
                            color: AppColors.prosocGreen,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          prestationNom,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (dateSouscription != null)
                              Text(
                                'Depuis: ${AppFormatters.formatDate(DateTime.tryParse(dateSouscription))}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            Text(
                              'Collectes: $nombreCollectes - Total: ${totalCollectes} \$',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statut
                                ? AppColors.prosocGreen.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statut ? 'Actif' : 'Inactif',
                            style: TextStyle(
                              fontSize: 12,
                              color: statut
                                  ? AppColors.prosocGreen
                                  : Colors.red,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String? value, {
    bool isBold = false,
    Color? textColor,
  }) {
    final displayValue = (value == null || value.trim().isEmpty)
        ? "Non renseigné"
        : value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),

          // Value
          Expanded(
            child: Text(
              displayValue,
              style: TextStyle(
                color: textColor ?? AppColors.textPrimary,
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_outlined,
                color: Colors.red.shade400,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                "Synchronisation",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Impossible de charger toutes les informations",
            style: TextStyle(color: Colors.red.shade600, fontSize: 14),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loadAffilie,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Réessayer'),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToContributionScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PayerContributionScreen(
          affilieId: widget.affilieId,
          affilieNom: widget.preview?.nom ?? '',
          affiliePrenom: widget.preview?.prenom ?? '',
          nombreDependants: _dependantsTotal,
          allowVirtualAccount: true,
        ),
      ),
    );
  }

  void _navigateToPayerFraisScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PayerFraisScreen(
          affilieId: widget.affilieId,
          affilieNom: widget.preview?.nom ?? '',
          affiliePrenom: widget.preview?.prenom ?? '',
          allowVirtualAccount: true,
        ),
      ),
    );
  }

  void _navigateToArrieresScreen() {
    final telephone =
        _stringFrom(_apiData, ['telephone', 'phone', 'telephoneAffilie']) ??
        widget.preview?.telephone;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArrieresAffilieScreen(
          affilieId: widget.affilieId,
          affilieNom: widget.preview?.nom ?? '',
          affiliePrenom: widget.preview?.prenom ?? '',
          affilieTelephone: telephone,
          nombreDependants: _dependantsTotal,
          allowVirtualAccount: true,
        ),
      ),
    ).then((_) {
      if (mounted) {
        _loadArrieres();
      }
    });
  }

  Future<void> _payerArriere(ArriereAffilieModel arriere) async {
    final telephone =
        _stringFrom(_apiData, ['telephone', 'phone', 'telephoneAffilie']) ??
        widget.preview?.telephone;

    final paid = await ArrierePaymentNavigator.openPayment(
      context: context,
      arriere: arriere,
      affilieId: widget.affilieId,
      affilieNom: widget.preview?.nom ?? '',
      affiliePrenom: widget.preview?.prenom ?? '',
      affilieTelephone: telephone,
      nombreDependants: _dependantsTotal,
      allowVirtualAccount: true,
    );

    if (paid == true && mounted) {
      await _loadArrieres();
    }
  }

  void _navigateToPayerSouscriptionScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PayerSouscriptionScreen(
          affilieId: widget.affilieId,
          affilieNom: widget.preview?.nom ?? '',
          affiliePrenom: widget.preview?.prenom ?? '',
          allowVirtualAccount: true,
        ),
      ),
    ).then((paid) {
      if (paid == true && mounted) {
        _loadSouscriptions();
      }
    });
  }

  Future<void> _showAddDependantBottomSheet() async {
    if (_isSoloAdhesion) {
      _showSoloDependantsLockedMessage();
      return;
    }

    final created = await DependantBottomSheet.show(
      context,
      affilieId: widget.affilieId,
      affilieNom: widget.preview?.nom ?? '',
      affiliePrenom: widget.preview?.prenom ?? '',
    );
    if (created == true && mounted) {
      await _loadDependants();
    }
  }

  Future<void> _showSouscriptionBottomSheet() async {
    final telephone =
        _stringFrom(_apiData, ['telephone', 'phone', 'telephoneAffilie']) ??
        widget.preview?.telephone;
    final created = await SouscriptionBottomSheet.show(
      context,
      affilieId: widget.affilieId,
      affilieNom: widget.preview?.nom ?? '',
      affiliePrenom: widget.preview?.prenom ?? '',
      affilieTelephone: telephone,
    );
    if (created == true && mounted) {
      await _loadSouscriptions();
    }
  }

  Future<void> _showAddAntecedentBottomSheet() async {
    await AntecedentBottomSheet.show(
      context,
      affilieId: widget.affilieId,
      affilieNom: widget.preview?.nom ?? '',
      affiliePrenom: widget.preview?.prenom ?? '',
    );
  }
}
