import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/colors.dart';
import '../../../config/api.dart';
import '../../../services/auth_service.dart';
import '../../../models/type_adhesion_model.dart';
import '../../../models/devise_model.dart';
import '../../../models/prestation_model.dart';
import '../../../models/adhesion_with_affilie_model.dart';
import '../../../models/frais_model.dart';
import '../../../models/wallet_agent_model.dart';
import 'package:flutter/foundation.dart';
import '../../../utils/api_error_helper.dart';
import '../../../utils/email_utils.dart';
import '../../../utils/phone_utils.dart';
import '../../../utils/picked_image_data.dart';
import 'flex_pay_payment_waiting_screen.dart';
import 'payment_webview_screen.dart';
import '../../widgets/flex_pay_card_payment_bottom_sheet.dart';
import '../../widgets/flex_pay_payment_error_dialog.dart';
import '../../widgets/prosoc_date_picker.dart';
import '../../widgets/prosoc_message_dialog.dart';

class NewAdhesionScreen extends StatefulWidget {
  const NewAdhesionScreen({super.key});

  @override
  State<NewAdhesionScreen> createState() => _NewAdhesionScreenState();
}

class _NewAdhesionScreenState extends State<NewAdhesionScreen>
    with TickerProviderStateMixin {
  static const int _stepDependants = 3;
  static const int _stepConfirmation = 4;

  late final PageController _pageController;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  int _currentStep = 0;
  bool _isLoading = false;

  // Lists for dropdowns
  List<TypeAdhesion> _typeAdhesions = [];
  List<Devise> _devises = [];
  List<Prestation> _prestations = [];
  List<Frais> _frais = [];

  // Selected items
  TypeAdhesion? _selectedTypeAdhesion;
  Devise? _selectedDevise;
  Prestation? _selectedPrestation;
  Frais? _selectedFraisAdhesion;
  String? _selectedModePaiement;

  // Liste des modes de paiement (API value -> Display value)
  static const Map<String, String> _modesPaiement = {
    'VIRTUAL_ACCOUNT': 'Compte virtuel',
    'MOBILE_MONEY': 'Mobile money',
    'CARTE_BANCAIRE': 'Carte',
  };

  // Liste des liens de parenté
  static const List<String> _liensParente = [
    'Conjoint(e)',
    'Enfant',
    'Frère',
    'Sœur',
    'Oncle',
    'Tante',
    'Cousin(e)',
  ];

  String? _selectedLienParente;

  PickedImageData? _photoAffilie;
  PickedImageData? _carteIdentite;

  // Loading states
  bool _isLoadingTypeAdhesions = true;
  bool _isLoadingDevises = true;
  bool _isLoadingPrestations = true;
  bool _isLoadingFrais = true;

  // Liste des dépendants
  final List<Map<String, dynamic>> _dependants = [];
  bool _dependantsDeferredToAdmin = false;

  static const String _adminDependantsHint =
      'Vous pourrez enregistrer les personnes à charge (avec certificat de '
      'scolarité pour les enfants de 18 à 25 ans) auprès d\'un agent '
      'administratif Prosoc pour finaliser le dossier.';

  // Controllers pour le formulaire
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _postnomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailAffilieController = TextEditingController();
  final _dateNController = TextEditingController();

  // Adresse résidence
  final _provinceController = TextEditingController();
  final _communeResidenceController = TextEditingController();
  final _quartierResidenceController = TextEditingController();
  final _avenueResidenceController = TextEditingController();
  final _numeroResidenceController = TextEditingController();

  // Adresse activité
  final _communeActiviteController = TextEditingController();
  final _quartierActiviteController = TextEditingController();
  final _avenueActiviteController = TextEditingController();
  final _numeroActiviteController = TextEditingController();

  // Souscription
  final _typeAdhesionIdController = TextEditingController();
  final _prestationIdController = TextEditingController();
  final _statutDossierController = TextEditingController();
  final _montantController = TextEditingController();
  final _modePaiementController = TextEditingController();
  final _operateurController = TextEditingController();
  final _statutPaiementController = TextEditingController();
  final _deviseIdController = TextEditingController();
  final _telephonePaiementController = TextEditingController();

  // Stepper items pour la progression
  final List<StepItem> _steps = const [
    StepItem(
      icon: Icons.person_outline,
      label: 'Infos',
      color: AppColors.prosocGreen,
    ),
    StepItem(
      icon: Icons.location_on_outlined,
      label: 'Adresse',
      color: AppColors.prosocGreen,
    ),
    StepItem(
      icon: Icons.subscriptions_outlined,
      label: 'Souscription',
      color: AppColors.prosocGreen,
    ),
    StepItem(
      icon: Icons.people_outline,
      label: 'Dépendants',
      color: AppColors.prosocGreen,
    ),
    StepItem(
      icon: Icons.check_circle_outline,
      label: 'Confirmation',
      color: AppColors.prosocGreen,
    ),
  ];

  bool get _isMobileMoneyPayment => _selectedModePaiement == 'MOBILE_MONEY';

  bool get _isElectronicPayment =>
      _selectedModePaiement == 'MOBILE_MONEY' ||
      _selectedModePaiement == 'CARTE_BANCAIRE';

  String get _statutPaiementCollecte =>
      _isElectronicPayment ? 'EN_ATTENTE' : 'OK';

  String? get _modePaiementLibelle => _selectedModePaiement != null
      ? _modesPaiement[_selectedModePaiement!] ?? _selectedModePaiement
      : null;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    _loadTypeAdhesions();
    _loadDevises();
    _loadPrestations();
    _loadFrais();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _postnomController.dispose();
    _telephoneController.dispose();
    _dateNController.dispose();
    _provinceController.dispose();
    _communeResidenceController.dispose();
    _quartierResidenceController.dispose();
    _avenueResidenceController.dispose();
    _numeroResidenceController.dispose();
    _communeActiviteController.dispose();
    _quartierActiviteController.dispose();
    _avenueActiviteController.dispose();
    _numeroActiviteController.dispose();
    _typeAdhesionIdController.dispose();
    _prestationIdController.dispose();
    _statutDossierController.dispose();
    _montantController.dispose();
    _modePaiementController.dispose();
    _operateurController.dispose();
    _statutPaiementController.dispose();
    _deviseIdController.dispose();
    _telephonePaiementController.dispose();
    super.dispose();
  }

  Future<void> _loadTypeAdhesions() async {
    try {
      final response = await ApiService.getTypeAdhesions();
      debugPrint('[DEBUG] Réponse API TypeAdhesion brute: $response');

      if (!mounted) return;

      if (response.success && response.data != null) {
        List<dynamic> dataList;
        if (response.data is List) {
          dataList = response.data as List<dynamic>;
        } else if (response.data is Map &&
            (response.data as Map).containsKey('data')) {
          dataList = (response.data as Map)['data'] as List<dynamic>;
          debugPrint(
            '[DEBUG] Données extraites de la réponse paginée: ${dataList.length} éléments',
          );
        } else {
          debugPrint(
            '[DEBUG] Format de données inattendu: ${response.data.runtimeType}',
          );
          setState(() => _isLoadingTypeAdhesions = false);
          return;
        }

        setState(() {
          _typeAdhesions = dataList
              .map(
                (json) => TypeAdhesion.fromJson(json as Map<String, dynamic>),
              )
              .toList();
          if (_typeAdhesions.isNotEmpty) {
            _selectedTypeAdhesion = _typeAdhesions.first;
            _typeAdhesionIdController.text = _selectedTypeAdhesion!.id
                .toString();
            debugPrint(
              '[DEBUG] Type d\'adhésion sélectionné par défaut: ${_selectedTypeAdhesion!.libelle} (ID: ${_selectedTypeAdhesion!.id})',
            );
          }
          _isLoadingTypeAdhesions = false;
          debugPrint(
            '[DEBUG] Nombre de types d\'adhésion chargés: ${_typeAdhesions.length}',
          );
        });
      } else {
        debugPrint(
          '[DEBUG] Échec du chargement des types d\'adhésion: ${response.message}',
        );
        setState(() => _isLoadingTypeAdhesions = false);
      }
    } catch (e, stackTrace) {
      debugPrint('[DEBUG] Erreur lors du chargement des types d\'adhésion: $e');
      debugPrint('[DEBUG] Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoadingTypeAdhesions = false);
      }
    }
  }

  Future<void> _loadDevises() async {
    try {
      final response = await ApiService.getDevises();
      debugPrint('[DEBUG] Réponse API Devise brute: $response');

      if (!mounted) return;

      if (response.success && response.data != null) {
        List<dynamic> dataList;
        if (response.data is List) {
          dataList = response.data as List<dynamic>;
        } else if (response.data is Map &&
            (response.data as Map).containsKey('data')) {
          dataList = (response.data as Map)['data'] as List<dynamic>;
          debugPrint(
            '[DEBUG] Données extraites de la réponse paginée: ${dataList.length} éléments',
          );
        } else {
          debugPrint(
            '[DEBUG] Format de données inattendu: ${response.data.runtimeType}',
          );
          setState(() => _isLoadingDevises = false);
          return;
        }

        setState(() {
          _devises = dataList
              .whereType<Map>()
              .map((json) => Devise.fromJson(Map<String, dynamic>.from(json)))
              .where((d) => d.idDevise > 0 && d.code.isNotEmpty)
              .toList();
          if (_selectedPrestation != null) {
            _applyPrestationSelection(_selectedPrestation);
          } else if (_devises.isNotEmpty) {
            _selectedDevise = _devises.first;
            _deviseIdController.text = _selectedDevise!.idDevise.toString();
          }
          if (_selectedDevise != null) {
            debugPrint(
              '[DEBUG] Devise sélectionnée: ${_selectedDevise!.code} '
              '(ID: ${_selectedDevise!.idDevise})',
            );
          }
          _isLoadingDevises = false;
          debugPrint('[DEBUG] Nombre de devises chargées: ${_devises.length}');
        });
      } else {
        debugPrint(
          '[DEBUG] Échec du chargement des devises: ${response.message}',
        );
        setState(() => _isLoadingDevises = false);
      }
    } catch (e, stackTrace) {
      debugPrint('[DEBUG] Erreur lors du chargement des devises: $e');
      debugPrint('[DEBUG] Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoadingDevises = false);
      }
    }
  }

  Future<void> _loadPrestations() async {
    try {
      final response = await ApiService.getPrestations();
      debugPrint('[DEBUG] Réponse API Prestations brute: $response');

      if (!mounted) return;

      if (response.success && response.data != null) {
        List<dynamic> dataList;
        if (response.data is List) {
          dataList = response.data as List<dynamic>;
        } else if (response.data is Map &&
            (response.data as Map).containsKey('data')) {
          dataList = (response.data as Map)['data'] as List<dynamic>;
          debugPrint(
            '[DEBUG] Données extraites de la réponse paginée: ${dataList.length} éléments',
          );
        } else {
          debugPrint(
            '[DEBUG] Format de données inattendu: ${response.data.runtimeType}',
          );
          setState(() => _isLoadingPrestations = false);
          return;
        }

        setState(() {
          _prestations = dataList
              .whereType<Map>()
              .map(
                (json) => Prestation.fromJson(Map<String, dynamic>.from(json)),
              )
              .toList();
          if (_prestations.isNotEmpty) {
            _selectedPrestation = _prestations.first;
            _prestationIdController.text = _selectedPrestation!.id.toString();
            _applyPrestationSelection(_selectedPrestation);
            debugPrint(
              '[DEBUG] Prestation sélectionnée par défaut: ${_selectedPrestation!.nomPrestation} (ID: ${_selectedPrestation!.id})',
            );
          }
          _isLoadingPrestations = false;
          debugPrint(
            '[DEBUG] Nombre de prestations chargées: ${_prestations.length}',
          );
        });
      } else {
        debugPrint(
          '[DEBUG] Échec du chargement des prestations: ${response.message}',
        );
        setState(() => _isLoadingPrestations = false);
      }
    } catch (e, stackTrace) {
      debugPrint('[DEBUG] Erreur lors du chargement des prestations: $e');
      debugPrint('[DEBUG] Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoadingPrestations = false);
      }
    }
  }

  void _syncDeviseFromId(int deviseId) {
    if (_devises.isEmpty || deviseId <= 0) return;
    Devise? devise;
    for (final d in _devises) {
      if (d.idDevise == deviseId) {
        devise = d;
        break;
      }
    }
    if (devise == null) return;
    _selectedDevise = devise;
    _deviseIdController.text = devise.idDevise.toString();
  }

  void _applyPrestationSelection(Prestation? prestation) {
    if (prestation == null) return;
    final montant = prestation.resolveMontant();
    if (montant != null && montant > 0) {
      _montantController.text = montant == montant.truncateToDouble()
          ? montant.toInt().toString()
          : montant.toString();
    }
    if (prestation.deviseId > 0) {
      _syncDeviseFromId(prestation.deviseId);
    } else if (prestation.resolveDeviseCode().isNotEmpty &&
        _devises.isNotEmpty) {
      final code = prestation.resolveDeviseCode();
      final match = _devises
          .where((d) => d.code.toUpperCase() == code.toUpperCase())
          .firstOrNull;
      if (match != null) {
        _selectedDevise = match;
        _deviseIdController.text = match.idDevise.toString();
      }
    }
  }

  /// Uniquement le frais d'adhésion (exclut carte membre et autres frais).
  List<Frais> get _fraisAdhesionOptions => _frais
      .where((f) => f.statut && !f.estSupprime && f.isFraisAdhesion)
      .toList();

  static const String _fraisAdhesionDeviseCode = 'USD';

  int get _fraisAdhesionDeviseId => WalletAgentDeviseIds.usd;

  String _deviseCodeFor(int deviseId, {String? fallbackCode}) {
    if (fallbackCode != null && fallbackCode.isNotEmpty) return fallbackCode;
    return _devises
            .where((d) => d.idDevise == deviseId)
            .map((d) => d.code)
            .firstOrNull ??
        (deviseId == 2
            ? 'USD'
            : deviseId == 1
            ? 'CDF'
            : '');
  }

  String _prestationDeviseCode(Prestation? prestation) {
    if (prestation == null) return '';
    final code = prestation.resolveDeviseCode();
    if (code.isNotEmpty) return code;
    return _deviseCodeFor(prestation.deviseId);
  }

  Future<void> _loadFrais() async {
    try {
      final response = await ApiService.getFrais();
      debugPrint('[DEBUG] Réponse API Frais brute: $response');

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _frais = response.data!;
          final options = _fraisAdhesionOptions;
          _selectedFraisAdhesion =
              options.isNotEmpty ? options.first : null;
          _isLoadingFrais = false;
          debugPrint(
            '[DEBUG] Frais chargés: ${_frais.length}, '
            'options adhésion: ${options.length}',
          );
        });
      } else {
        debugPrint(
          '[DEBUG] Échec du chargement des frais: ${response.message}',
        );
        setState(() => _isLoadingFrais = false);
      }
    } catch (e, stackTrace) {
      debugPrint('[DEBUG] Erreur lors du chargement des frais: $e');
      debugPrint('[DEBUG] Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoadingFrais = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
              size: 22,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Nouvelle adhésion',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Stepper horizontal moderne
          Container(
            margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: List.generate(_steps.length, (index) {
                return Expanded(child: _buildModernStepIndicator(index));
              }),
            ),
          ),

          // Contenu principal avec animation
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentStep = index);
                  _animationController.reset();
                  _animationController.forward();
                },
                children: [
                  _buildPersonalInfoStep(),
                  _buildAddressStep(),
                  _buildSouscriptionStep(),
                  _buildDependantsStep(),
                  _buildConfirmationStep(),
                ],
              ),
            ),
          ),

          // Bottom navigation moderne
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildModernStepIndicator(int index) {
    final isDependantsStepSkipped =
        index == _stepDependants && _skipDependantsStep;
    final isActive = _currentStep == index && !isDependantsStepSkipped;
    final isCompleted =
        _currentStep > index ||
        (isDependantsStepSkipped && _currentStep >= _stepConfirmation);

    return GestureDetector(
      onTap: () {
        if (isDependantsStepSkipped) return;
        if (index <= _currentStep + 1) {
          _animateToPage(index);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            // Indicateur avec animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 4,
              decoration: BoxDecoration(
                gradient: isCompleted || isActive
                    ? const LinearGradient(
                        colors: [AppColors.prosocGreen, Color(0xFF45B7AF)],
                      )
                    : null,
                color: isCompleted || isActive ? null : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Icône avec badge
            Stack(
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? AppColors.prosocGreen.withValues(alpha: 0.1)
                        : isCompleted
                        ? AppColors.prosocGreen.withValues(alpha: 0.1)
                        : Colors.transparent,
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? AppColors.prosocGreen
                        : isActive
                        ? Colors.white
                        : Colors.grey.shade100,
                    border: isActive
                        ? Border.all(color: AppColors.prosocGreen, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : Icon(
                            _steps[index].icon,
                            color: isActive
                                ? AppColors.prosocGreen
                                : Colors.grey.shade400,
                            size: 18,
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Label
            Text(
              isDependantsStepSkipped ? '—' : _steps[index].label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isDependantsStepSkipped
                    ? Colors.grey.shade400
                    : isActive
                    ? AppColors.textPrimary
                    : isCompleted
                    ? AppColors.textSecondary
                    : Colors.grey.shade400,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: _buildNavButton(
                  label: 'Précédent',
                  icon: Icons.arrow_back_rounded,
                  isOutlined: true,
                  onPressed: _goToPreviousStep,
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: _currentStep > 0 ? 2 : 1,
              child: _buildNavButton(
                label: _currentStep == _stepConfirmation
                    ? 'Confirmer'
                    : 'Continuer',
                icon: _currentStep == _stepConfirmation
                    ? Icons.check_rounded
                    : Icons.arrow_forward_rounded,
                isOutlined: false,
                isLoading: _isLoading,
                onPressed: () {
                  if (_currentStep < _stepConfirmation) {
                    _goToNextStep();
                  } else {
                    _submitAdhesion();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required String label,
    required IconData icon,
    required bool isOutlined,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: isOutlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(
                  color: AppColors.prosocGreen,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20, color: AppColors.prosocGreen),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.prosocGreen,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.prosocGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(icon, size: 20),
                      ],
                    ),
            ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.prosocGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.prosocGreen.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.prosocGreen.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.prosocGreen, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint ?? 'Entrez $label',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: Icon(icon, color: AppColors.prosocGreen, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _fraisAdhesionLabel(Frais frais) =>
      '${frais.libelle} ($_fraisAdhesionDeviseCode ${frais.montant})';

  Widget _buildReadOnlyInfoField({
    required String label,
    required String value,
    required IconData icon,
    String? helperText,
    bool isRequired = false,
    bool isLoading = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : InputDecorator(
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      icon,
                      color: AppColors.prosocGreen,
                      size: 20,
                    ),
                    suffixIcon: Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: Colors.grey.shade500,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  child: Text(
                    value.isNotEmpty ? value : '—',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
        ),
        if (helperText != null && helperText.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            helperText,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required Future<void> Function(T?) onChanged,
    required String Function(T) itemLabel,
    IconData? icon,
    bool isLoading = false,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : DropdownButtonFormField<T>(
                  initialValue: value,
                  isExpanded: true,
                  decoration: InputDecoration(
                    hintText: 'Sélectionner $label',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    prefixIcon: icon != null
                        ? Icon(icon, color: AppColors.prosocGreen, size: 20)
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, // Réduit de 16 à 12
                      vertical: 14,
                    ),
                    isDense: true, // Rend le dropdown plus compact
                  ),
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey.shade600,
                  ),
                  items: items.map((item) {
                    return DropdownMenuItem<T>(
                      value: item,
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          itemLabel(item),
                          style: const TextStyle(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: onChanged,
                ),
        ),
      ],
    );
  }

  bool get _skipDependantsStep =>
      _selectedTypeAdhesion?.libelle.toLowerCase().contains('solo') ?? false;

  int _nextPageIndex(int current) {
    if (current == 2 && _skipDependantsStep) return _stepConfirmation;
    return current + 1;
  }

  int _previousPageIndex(int current) {
    if (current == _stepConfirmation && _skipDependantsStep) {
      return 2;
    }
    return current - 1;
  }

  void _animateToPage(int pageIndex) {
    _pageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _goToNextStep() async {
    if (_currentStep == _stepDependants && _hasDependantMissingCertificat()) {
      if (!await _validateDependantsCertificats()) return;
    } else if (!_validateStep(_currentStep)) {
      return;
    }
    if (!mounted) return;
    _animateToPage(_nextPageIndex(_currentStep));
  }

  void _goToPreviousStep() {
    _animateToPage(_previousPageIndex(_currentStep));
  }

  Future<void> _showSnack(String message, {bool isError = true}) async {
    if (!mounted) return;
    await ProsocMessageDialog.show(
      context,
      variant: isError
          ? ProsocMessageVariant.error
          : ProsocMessageVariant.success,
      title: isError ? 'Attention' : 'Succès',
      message: message,
    );
  }

  Future<void> _showApiError(String? message, {int? statusCode}) async {
    if (!mounted) return;
    await ProsocMessageDialog.show(
      context,
      variant: ProsocMessageVariant.error,
      title: statusCode != null && statusCode >= 500
          ? 'Erreur serveur'
          : 'Adhésion impossible',
      message: message?.trim().isNotEmpty == true
          ? message!.trim()
          : ApiErrorHelper.userFacingMessage(statusCode: statusCode),
      statusCode: statusCode,
      hint: statusCode != null && statusCode >= 500
          ? 'Vérifiez les personnes à charge (certificat de scolarité 18–25 ans), '
                'les documents et le paiement, puis réessayez.'
          : null,
    );
  }

  int? _dependantAgeYears(String dateDdMmYyyy) {
    final parts = dateDdMmYyyy.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;

    final birth = DateTime(year, month, day);
    final now = DateTime.now();
    var age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }

  bool _requiresCertificatScolarite(String? lienParente, String dateNaissance) {
    final age = _dependantAgeYears(dateNaissance);
    if (age == null) return false;
    final lien = lienParente?.toLowerCase() ?? '';
    final isEnfant = lien.contains('enfant');
    return isEnfant && age >= 18 && age <= 25;
  }

  Future<bool> _confirmSkipDependantsForAdmin({String? contextMessage}) async {
    if (!mounted) return false;
    return ProsocMessageDialog.showChoice(
      context,
      variant: ProsocMessageVariant.warning,
      title: 'Certificat de scolarité requis',
      message:
          contextMessage ??
          'Pour un enfant de 18 à 25 ans, le certificat de scolarité est '
              'obligatoire pour l\'enregistrer comme personne à charge.',
      hint: _adminDependantsHint,
      primaryLabel: 'Joindre le certificat',
      secondaryLabel: 'Continuer sans personne à charge',
    );
  }

  Future<void> _skipDependantsStepForAdminFinalization({
    String? contextMessage,
  }) async {
    final skip = await _confirmSkipDependantsForAdmin(
      contextMessage: contextMessage,
    );
    if (!skip || !mounted) return;

    setState(() {
      _dependants.clear();
      _dependantsDeferredToAdmin = true;
    });

    if (_currentStep == _stepDependants) {
      _animateToPage(_stepConfirmation);
    }
  }

  bool _hasDependantMissingCertificat() {
    for (final d in _dependants) {
      final lien = d['lienParente']?.toString();
      final date = d['dateNaissance']?.toString() ?? '';
      if (_requiresCertificatScolarite(lien, date) &&
          d['certificatScolarite'] == null) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _validateDependantsCertificats() async {
    for (final d in _dependants) {
      final nom = d['nom']?.toString() ?? 'Personne à charge';
      final lien = d['lienParente']?.toString();
      final date = d['dateNaissance']?.toString() ?? '';
      if (_requiresCertificatScolarite(lien, date) &&
          d['certificatScolarite'] == null) {
        final age = _dependantAgeYears(date);
        final skip = await _confirmSkipDependantsForAdmin(
          contextMessage:
              'Pour $nom (${age ?? '?'} ans), un certificat de scolarité est '
              'obligatoire (tranche 18–25 ans).',
        );
        if (skip && mounted) {
          setState(() {
            _dependants.clear();
            _dependantsDeferredToAdmin = true;
          });
          return true;
        }
        return false;
      }
    }
    return true;
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        if (_nomController.text.trim().isEmpty ||
            _prenomController.text.trim().isEmpty ||
            _telephoneController.text.trim().isEmpty ||
            _dateNController.text.trim().isEmpty) {
          _showSnack('Remplissez les champs obligatoires de l\'étape Infos.');
          return false;
        }
        if (_photoAffilie == null) {
          _showSnack('La photo de l\'affilié est obligatoire.');
          return false;
        }
        if (!EmailUtils.isEmptyOrValid(_emailAffilieController.text)) {
          _showSnack(EmailUtils.invalidFormatMessage);
          return false;
        }
        return true;
      case 1:
        if (_provinceController.text.trim().isEmpty) {
          _showSnack('Indiquez la province de résidence.');
          return false;
        }
        return true;
      case 2:
        if (_selectedTypeAdhesion == null ||
            _selectedPrestation == null ||
            _montantController.text.trim().isEmpty ||
            _selectedFraisAdhesion == null ||
            _selectedModePaiement == null) {
          _showSnack('Complétez la souscription et le paiement.');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _pickDocument({
    required bool isCarteIdentite,
    required ImageSource source,
  }) async {
    try {
      final picked = await PickedImageData.pickForAdhesion(
        source: source,
        isIdentityDocument: isCarteIdentite,
      );
      if (picked == null || !mounted) return;
      setState(() {
        if (isCarteIdentite) {
          _carteIdentite = picked;
        } else {
          _photoAffilie = picked;
        }
      });
    } catch (e) {
      _showSnack('Impossible de charger l\'image: $e');
    }
  }

  void _showImageSourceSheet({
    required bool isCarteIdentite,
    void Function(PickedImageData picked)? onPicked,
  }) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Galerie'),
                onTap: () async {
                  Navigator.pop(context);
                  if (onPicked != null) {
                    final picked = await PickedImageData.pickForAdhesion(
                      source: ImageSource.gallery,
                      isIdentityDocument: isCarteIdentite,
                    );
                    if (picked != null) onPicked(picked);
                  } else {
                    _pickDocument(
                      isCarteIdentite: isCarteIdentite,
                      source: ImageSource.gallery,
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Appareil photo'),
                onTap: () async {
                  Navigator.pop(context);
                  if (onPicked != null) {
                    final picked = await PickedImageData.pickForAdhesion(
                      source: ImageSource.camera,
                      isIdentityDocument: isCarteIdentite,
                    );
                    if (picked != null) onPicked(picked);
                  } else {
                    _pickDocument(
                      isCarteIdentite: isCarteIdentite,
                      source: ImageSource.camera,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentPicker({
    required String label,
    required IconData icon,
    required PickedImageData? value,
    required VoidCallback onPick,
    required VoidCallback onClear,
    bool compact = false,
    bool isRequired = true,
  }) {
    final labelStyle = TextStyle(
      fontSize: compact ? 12 : 14,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
    );
    final imageHeight = compact ? 88.0 : 120.0;
    final cardPadding = compact ? 10.0 : 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: labelStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: value != null
                  ? AppColors.prosocGreen.withValues(alpha: 0.4)
                  : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              if (value != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    value.bytes,
                    height: imageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 8),
                if (!compact)
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.prosocGreen,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          value.fileName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                else
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.prosocGreen,
                    size: 18,
                  ),
                SizedBox(height: compact ? 8 : 12),
              ] else
                Icon(
                  icon,
                  size: compact ? 32 : 40,
                  color: Colors.grey.shade400,
                ),
              if (value == null) const SizedBox(height: 8),
              if (compact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onPick,
                      icon: const Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 18,
                      ),
                      label: Text(
                        value == null ? 'Ajouter' : 'Changer',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.prosocGreen,
                        side: const BorderSide(color: AppColors.prosocGreen),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                    if (value != null) ...[
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: onClear,
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 18,
                        ),
                        label: const Text(
                          'Supprimer',
                          style: TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                    ],
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onPick,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: Text(value == null ? 'Ajouter' : 'Remplacer'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.prosocGreen,
                          side: const BorderSide(color: AppColors.prosocGreen),
                        ),
                      ),
                    ),
                    if (value != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: onClear,
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        tooltip: 'Supprimer',
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSectionHeader(
            icon: Icons.person_outline,
            title: 'Informations personnelles',
            subtitle: 'Remplissez les informations de base de l\'affilié',
          ),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildInputField(
                  controller: _nomController,
                  label: 'Nom',
                  icon: Icons.person_outline,
                  hint: 'Ex: KANGUDJA',
                  isRequired: true,
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  controller: _prenomController,
                  label: 'Prénom',
                  icon: Icons.person_outline,
                  hint: 'Ex: Obed',
                  isRequired: true,
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  controller: _postnomController,
                  label: 'Postnom',
                  icon: Icons.person_outline,
                  hint: 'Ex: PANEA (optionnel)',
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  controller: _telephoneController,
                  label: 'Téléphone',
                  icon: Icons.phone_outlined,
                  hint: 'Ex: +243 123 456 789',
                  keyboardType: TextInputType.phone,
                  isRequired: true,
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  controller: _emailAffilieController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  hint: 'Ex: obed@gmail.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                ProsocDateField(
                  controller: _dateNController,
                  label: 'Date de naissance',
                  icon: Icons.calendar_today_outlined,
                  isRequired: true,
                  initialDateFallback: DateTime(1990),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildDocumentPicker(
                        compact: true,
                        label: 'Photo de l\'affilié',
                        icon: Icons.account_circle_outlined,
                        value: _photoAffilie,
                        isRequired: true,
                        onPick: () =>
                            _showImageSourceSheet(isCarteIdentite: false),
                        onClear: () => setState(() => _photoAffilie = null),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDocumentPicker(
                        compact: true,
                        label: 'Carte d\'identité',
                        icon: Icons.badge_outlined,
                        value: _carteIdentite,
                        isRequired: false,
                        onPick: () =>
                            _showImageSourceSheet(isCarteIdentite: true),
                        onClear: () => setState(() => _carteIdentite = null),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSectionHeader(
            icon: Icons.location_on_outlined,
            title: 'Adresse de résidence',
            subtitle: 'Informations sur le lieu de résidence',
          ),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildInputField(
                  controller: _provinceController,
                  label: 'Province',
                  icon: Icons.map_outlined,
                  hint: 'Ex: Kinshasa',
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  controller: _communeResidenceController,
                  label: 'Commune',
                  icon: Icons.location_city_outlined,
                  hint: 'Ex: Gombe',
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  controller: _quartierResidenceController,
                  label: 'Quartier',
                  icon: Icons.house_outlined,
                  hint: 'Ex: Batetela',
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildInputField(
                        controller: _avenueResidenceController,
                        label: 'Avenue',
                        icon: Icons.streetview_outlined,
                        hint: 'Ex: Kasa-Vubu',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInputField(
                        controller: _numeroResidenceController,
                        label: 'N°',
                        icon: Icons.numbers_outlined,
                        hint: '12',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSouscriptionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSectionHeader(
            icon: Icons.subscriptions_outlined,
            title: 'Souscription et paiement',
            subtitle: 'Choisissez les options et les montants',
          ),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildDropdownField<TypeAdhesion>(
                  label: "Type d'adhésion",
                  value: _selectedTypeAdhesion,
                  items: _typeAdhesions,
                  isLoading: _isLoadingTypeAdhesions,
                  isRequired: true,
                  icon: Icons.category_outlined,
                  itemLabel: (type) => type.libelle,
                  onChanged: (newValue) async {
                    setState(() {
                      _selectedTypeAdhesion = newValue;
                      if (newValue != null) {
                        _typeAdhesionIdController.text = newValue.id.toString();
                        if (newValue.libelle.toLowerCase().contains('solo')) {
                          _dependants.clear();
                        }
                      }
                    });

                    if (newValue != null) {
                      _showTypeAdhesionInfo(newValue);
                    }
                  },
                ),
                const SizedBox(height: 20),
                _buildDropdownField<Prestation>(
                  label: "Prestation",
                  value: _selectedPrestation,
                  items: _prestations,
                  isLoading: _isLoadingPrestations,
                  isRequired: true,
                  icon: Icons.health_and_safety_outlined,
                  itemLabel: (prestation) {
                    final montant = prestation.resolveMontant();
                    final codeDevise = _prestationDeviseCode(prestation);
                    if (montant != null) {
                      final suffix = codeDevise.isNotEmpty ? codeDevise : '';
                      return '${prestation.nomPrestation} ($montant $suffix)'
                          .trim();
                    }
                    return prestation.nomPrestation;
                  },
                  onChanged: (newValue) async {
                    setState(() {
                      _selectedPrestation = newValue;
                      if (newValue != null) {
                        _prestationIdController.text = newValue.id.toString();
                        _applyPrestationSelection(newValue);
                      }
                    });
                  },
                ),
                const SizedBox(height: 20),
                // Montant de la Prestation (Souscription)
                TextFormField(
                  controller: _montantController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Montant de la prestation',
                    hintText: _selectedPrestation?.resolveMontant() != null
                        ? 'Tarif API: ${_selectedPrestation!.resolveMontant()} '
                              '${_prestationDeviseCode(_selectedPrestation)}'
                        : null,
                    prefixIcon: const Icon(Icons.money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer le montant de la prestation';
                    }
                    final montant = double.tryParse(value);
                    if (montant == null || montant <= 0) {
                      return 'Le montant doit être supérieur à 0';
                    }
                    return null;
                  },
                ),
                if (_selectedPrestation != null &&
                    _prestationDeviseCode(_selectedPrestation).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.currency_exchange,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Devise : ${_prestationDeviseCode(_selectedPrestation)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                if (_fraisAdhesionOptions.isNotEmpty) ...[
                  if (_fraisAdhesionOptions.length == 1)
                    _buildReadOnlyInfoField(
                      label: "Frais d'adhésion",
                      value: _fraisAdhesionLabel(_fraisAdhesionOptions.first),
                      icon: Icons.money_outlined,
                      isRequired: true,
                      isLoading: _isLoadingFrais,
                      helperText:
                          'Les frais d\'adhésion sont toujours libellés en '
                          'dollars (USD).',
                    )
                  else
                    _buildDropdownField<Frais>(
                      label: "Frais d'adhésion",
                      value: _selectedFraisAdhesion,
                      items: _fraisAdhesionOptions,
                      isLoading: _isLoadingFrais,
                      isRequired: true,
                      icon: Icons.money_outlined,
                      itemLabel: _fraisAdhesionLabel,
                      onChanged: (newValue) async {
                        setState(() => _selectedFraisAdhesion = newValue);
                      },
                    ),
                  if (_fraisAdhesionOptions.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Les frais d\'adhésion sont toujours libellés en '
                        'dollars (USD).',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.35,
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 20),
                _buildReadOnlyInfoField(
                  label: 'Devise',
                  value: _selectedDevise?.code ??
                      _prestationDeviseCode(_selectedPrestation),
                  icon: Icons.currency_exchange,
                  isRequired: true,
                  isLoading: _isLoadingDevises,
                  helperText:
                      'Devise déterminée par la prestation sélectionnée '
                      '(non modifiable).',
                ),
                const SizedBox(height: 20),
                _buildDropdownField<String>(
                  label: 'Mode de paiement',
                  value: _selectedModePaiement,
                  items: _modesPaiement.keys.toList(),
                  isLoading: false,
                  isRequired: true,
                  itemLabel: (mode) => _modesPaiement[mode] ?? mode,
                  onChanged: (newValue) async {
                    setState(() {
                      _selectedModePaiement = newValue;
                      _modePaiementController.text = newValue ?? '';
                      if (newValue == 'MOBILE_MONEY') {
                        final telAffilie = _telephoneController.text.trim();
                        if (_telephonePaiementController.text.trim().isEmpty &&
                            telAffilie.isNotEmpty) {
                          _telephonePaiementController.text = telAffilie;
                        }
                      } else {
                        _telephonePaiementController.clear();
                      }
                    });
                  },
                ),
                if (_isMobileMoneyPayment) ...[
                  const SizedBox(height: 20),
                  _buildInputField(
                    controller: _telephonePaiementController,
                    label: 'Numéro Mobile Money (affilié)',
                    icon: Icons.phone_android_outlined,
                    hint: '243987654321',
                    keyboardType: TextInputType.phone,
                    isRequired: true,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Numéro de l\'affilié pour le paiement (modifiable). '
                      'Format : 243XXXXXXXXX (+243, 0… ou 9 chiffres).',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDependantsStep() {
    if (_skipDependantsStep) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _currentStep == _stepDependants) {
          _pageController.jumpToPage(_stepConfirmation);
        }
      });
      return const SizedBox.shrink();
    }

    // Validation pour F3 et F6
    if (_selectedTypeAdhesion != null) {
      final typeAdhesionLibelle = _selectedTypeAdhesion!.libelle.toLowerCase();
      int maxDependants = 0;

      if (typeAdhesionLibelle.contains('f6')) {
        maxDependants = 5;
      } else if (typeAdhesionLibelle.contains('f3')) {
        maxDependants = 3;
      }

      // Si on a déjà dépassé la limite, afficher un message
      if (maxDependants > 0 && _dependants.length > maxDependants) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildSectionHeader(
                icon: Icons.people_outline,
                title: 'Personnes à charge',
                subtitle: 'Limite de dépendants atteinte',
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 64,
                      color: Colors.orange.shade600,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Limite atteinte',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Le type d\'adhésion ${_selectedTypeAdhesion!.libelle} permet maximum $maxDependants dépendants.\nVous en avez ajouté ${_dependants.length}.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          // Supprimer le dernier dépendant ajouté
                          if (_dependants.isNotEmpty) {
                            _dependants.removeLast();
                          }
                        });
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Supprimer le dernier dépendant'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSectionHeader(
            icon: Icons.people_outline,
            title: 'Personnes à charge',
            subtitle: _selectedTypeAdhesion != null
                ? 'Ajoutez les personnes à charge (${_dependants.length}/${_getMaxDependants()} maximum). '
                      'Enfant 18–25 ans : certificat de scolarité obligatoire.'
                : 'Ajoutez les personnes à charge de l\'affilié',
          ),
          if (_dependantsDeferredToAdmin) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _adminDependantsHint,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                if (_dependants.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune personne à charge',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _dependants.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final dependant = _dependants[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.prosocGreen.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.person_outline,
                                color: AppColors.prosocGreen,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dependant['nom'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.prosocGreen
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          dependant['lienParente'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.prosocGreen,
                                          ),
                                        ),
                                      ),
                                      if (dependant['certificatScolarite'] !=
                                          null) ...[
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.school_outlined,
                                          size: 16,
                                          color: Colors.green.shade700,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                setState(() {
                                  _dependants.removeAt(index);
                                  if (_dependants.isEmpty) {
                                    _dependantsDeferredToAdmin = false;
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 20),

                OutlinedButton.icon(
                  onPressed: _showAddDependantDialog,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Ajouter une personne à charge'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.prosocGreen,
                    side: const BorderSide(color: AppColors.prosocGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 0),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => _skipDependantsStepForAdminFinalization(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Continuer sans personne à charge',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSectionHeader(
            icon: Icons.check_circle_outline,
            title: 'Confirmation',
            subtitle: 'Vérifiez les informations avant de soumettre',
          ),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Récapitulatif',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),

                _buildSummarySection(
                  title: 'Informations personnelles',
                  icon: Icons.person_outline,
                  children: [
                    _buildSummaryRow(
                      'Nom complet',
                      '${_nomController.text} ${_prenomController.text} ${_postnomController.text}'
                          .trim(),
                    ),
                    _buildSummaryRow('Téléphone', _telephoneController.text),
                    _buildSummaryRow(
                      'Date de naissance',
                      _dateNController.text,
                    ),
                    _buildSummaryRow(
                      'Photo affilié',
                      _photoAffilie != null ? 'Jointe' : 'Manquante',
                    ),
                    _buildSummaryRow(
                      'Carte d\'identité',
                      _carteIdentite != null
                          ? 'Jointe'
                          : 'Non jointe (optionnel)',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildSummarySection(
                  title: 'Adresse',
                  icon: Icons.location_on_outlined,
                  children: [
                    if (_provinceController.text.isNotEmpty)
                      _buildSummaryRow('Province', _provinceController.text),
                    if (_communeResidenceController.text.isNotEmpty)
                      _buildSummaryRow(
                        'Commune',
                        _communeResidenceController.text,
                      ),
                    if (_avenueResidenceController.text.isNotEmpty ||
                        _numeroResidenceController.text.isNotEmpty)
                      _buildSummaryRow(
                        'Adresse complète',
                        '${_avenueResidenceController.text} ${_numeroResidenceController.text}, ${_quartierResidenceController.text}'
                            .trim(),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildSummarySection(
                  title: 'Souscription',
                  icon: Icons.subscriptions_outlined,
                  children: [
                    _buildSummaryRow(
                      "Type d'adhésion",
                      _selectedTypeAdhesion?.libelle ?? '',
                    ),
                    _buildSummaryRow(
                      'Prestation',
                      _selectedPrestation?.nomPrestation ?? '',
                    ),
                    _buildSummaryRow(
                      'Montant',
                      '${_montantController.text} ${_selectedDevise?.code ?? ''}',
                    ),
                    if (_modePaiementLibelle != null)
                      _buildSummaryRow(
                        'Mode de paiement',
                        _modePaiementLibelle!,
                      ),
                    if (_isMobileMoneyPayment &&
                        _telephonePaiementController.text.trim().isNotEmpty)
                      _buildSummaryRow(
                        'Mobile Money (affilié)',
                        PhoneUtils.formatForDisplay(
                          _telephonePaiementController.text.trim(),
                        ),
                      ),
                  ],
                ),

                if (_dependantsDeferredToAdmin && _dependants.isEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSummarySection(
                    title: 'Personnes à charge',
                    icon: Icons.people_outline,
                    children: [
                      _buildSummaryRow('Statut', 'À finaliser avec un agent'),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _adminDependantsHint,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_dependants.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSummarySection(
                    title: 'Personnes à charge',
                    icon: Icons.people_outline,
                    children: [
                      _buildSummaryRow('Nombre', '${_dependants.length}'),
                      ..._dependants
                          .map(
                            (d) => Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      color: AppColors.prosocGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${d['nom']} (${d['lienParente']})',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.prosocGreen),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDependantDialog() {
    final nomController = TextEditingController();
    final dateController = TextEditingController();
    PickedImageData? certificatScolarite;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ajouter une personne à charge',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Remplissez les informations du dépendant',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 32),

                      _buildInputField(
                        controller: nomController,
                        label: 'Nom complet',
                        icon: Icons.person_outline,
                        hint: 'Ex: Kangudja Obed',
                        isRequired: true,
                      ),

                      const SizedBox(height: 20),

                      _buildDropdownField<String>(
                        label: 'Lien parental',
                        value: _selectedLienParente,
                        items: _liensParente,
                        isLoading: false,
                        isRequired: true,
                        icon: Icons.family_restroom_outlined,
                        itemLabel: (lien) => lien,
                        onChanged: (newValue) async {
                          setDialogState(() {
                            _selectedLienParente = newValue;
                          });
                        },
                      ),

                      const SizedBox(height: 20),

                      ProsocDateField(
                        controller: dateController,
                        label: 'Date de naissance',
                        icon: Icons.calendar_today_outlined,
                        isRequired: true,
                        initialDateFallback: DateTime(2005),
                        onChanged: () => setDialogState(() {}),
                      ),
                      if (_requiresCertificatScolarite(
                        _selectedLienParente,
                        dateController.text,
                      )) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Text(
                            'Enfant de 18 à 25 ans : joignez un certificat de '
                            'scolarité ou justificatif d\'études.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDocumentPicker(
                          label: 'Certificat de scolarité',
                          icon: Icons.school_outlined,
                          value: certificatScolarite,
                          compact: true,
                          onPick: () => _showImageSourceSheet(
                            isCarteIdentite: true,
                            onPicked: (picked) {
                              setDialogState(
                                () => certificatScolarite = picked,
                              );
                            },
                          ),
                          onClear: () {
                            setDialogState(() => certificatScolarite = null);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _skipDependantsStepForAdminFinalization(
                              contextMessage:
                                  'Sans certificat de scolarité, cette personne '
                                  'ne peut pas être enregistrée pour le moment.',
                            );
                          },
                          child: const Text(
                            'Je n\'ai pas le certificat — continuer sans '
                            'personne à charge',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            nomController.text.isNotEmpty &&
                                _selectedLienParente != null &&
                                dateController.text.isNotEmpty &&
                                (!_requiresCertificatScolarite(
                                      _selectedLienParente,
                                      dateController.text,
                                    ) ||
                                    certificatScolarite != null)
                            ? () async {
                                final maxDependants = _getMaxDependants();
                                if (maxDependants > 0 &&
                                    _dependants.length >= maxDependants) {
                                  await _showSnack(
                                    'Limite atteinte : maximum $maxDependants '
                                    'personnes à charge pour ce type d\'adhésion.',
                                  );
                                  return;
                                }

                                PickedImageData? certPayload;
                                if (certificatScolarite != null) {
                                  certPayload =
                                      PickedImageData.compressForApiUpload(
                                        certificatScolarite!,
                                        maxSide: 1400,
                                        jpegQuality: 78,
                                      );
                                  if (!certPayload.isWithinApiLimit) {
                                    await _showSnack(
                                      'Le certificat de scolarité dépasse 1 Mo. '
                                      'Choisissez une image plus légère.',
                                    );
                                    return;
                                  }
                                }

                                final addedName = nomController.text.trim();
                                setState(() {
                                  _dependantsDeferredToAdmin = false;
                                  _dependants.add({
                                    'nom': addedName,
                                    'lienParente': _selectedLienParente,
                                    'dateNaissance': dateController.text,
                                    if (certPayload != null)
                                      'certificatScolarite': certPayload,
                                  });
                                });
                                Navigator.pop(context);
                                await _showSnack(
                                  '$addedName a été ajouté.',
                                  isError: false,
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.prosocGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Ajouter'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Corps de requête adhésion lisible en debug (base64 tronqués).
  Map<String, dynamic> _sanitizeAdhesionPayloadForLog(
    Map<String, dynamic> payload,
  ) {
    const base64Keys = {
      'photoBase64',
      'carteIdentiteBase64',
      'certificatScolariteBase64',
    };

    final sanitized = <String, dynamic>{};
    payload.forEach((key, value) {
      if (base64Keys.contains(key) && value is String && value.isNotEmpty) {
        sanitized[key] = '<base64 ${value.length} caractères>';
      } else if (value is List) {
        sanitized[key] = value
            .map(
              (item) => item is Map<String, dynamic>
                  ? _sanitizeAdhesionPayloadForLog(item)
                  : item,
            )
            .toList();
      } else if (value is Map<String, dynamic>) {
        sanitized[key] = _sanitizeAdhesionPayloadForLog(value);
      } else {
        sanitized[key] = value;
      }
    });
    return sanitized;
  }

  /// Référence auto pour Mobile Money / Carte uniquement (pas compte virtuel).
  String? _referencePaiementElectronique() {
    if (!_isElectronicPayment) return null;
    return 'ADM-ELEC-${DateTime.now().millisecondsSinceEpoch}';
  }

  void _logAdhesionRequestBody(AdhesionWithAffilieRequest request) {
    final raw = request.toJson();
    if (kDebugMode) {
      final photoLen = (raw['photoBase64'] as String?)?.length ?? 0;
      final carteLen = (raw['carteIdentiteBase64'] as String?)?.length ?? 0;
      debugPrint(
        '[Adhesion] payload JSON ~${jsonEncode(raw).length} octets | '
        'photo base64: $photoLen | carte base64: $carteLen',
      );
    }
    final adhesionBody = _sanitizeAdhesionPayloadForLog(raw);

    if (_isElectronicPayment) {
      final telephonePaiement = _isMobileMoneyPayment
          ? PhoneUtils.normalizeDrcPhone(_telephonePaiementController.text)
          : PhoneUtils.normalizeDrcPhone(_telephoneController.text);

      ApiErrorHelper.logRequest(
        'Adhesion/with-affilie-paiement-electronique',
        {
          'adhesion': adhesionBody,
          'modePaiement': _selectedModePaiement,
          'telephonePaiement': telephonePaiement,
          'devisePaiementId': _selectedDevise?.idDevise,
        },
        endpoint: '/api/Adhesion/with-affilie-paiement-electronique',
      );
      return;
    }

    ApiErrorHelper.logRequest(
      'Adhesion/with-affilie',
      adhesionBody,
      endpoint: '/api/Adhesion/with-affilie',
    );
  }

  List<DependantRequest> _buildDependantsPayload() {
    return _dependants.map((d) {
      final dateParts = (d['dateNaissance'] as String).split('/');
      final dateNaissance = DateTime.utc(
        int.parse(dateParts[2]),
        int.parse(dateParts[1]),
        int.parse(dateParts[0]),
      );
      final certificat = d['certificatScolarite'] as PickedImageData?;
      return DependantRequest(
        nom: d['nom'] as String,
        lienParente: d['lienParente'] as String,
        dateNaissance: dateNaissance,
        adresse: d['adresse'] as String?,
        certificatScolariteBase64: certificat?.base64,
        certificatScolariteContentType: certificat?.contentType,
      );
    }).toList();
  }

  Future<void> _submitAdhesion() async {
    if (!_validateStep(0) || !_validateStep(1) || !_validateStep(2)) {
      return;
    }

    if (_photoAffilie == null) {
      _showSnack('La photo de l\'affilié est obligatoire.');
      return;
    }

    _photoAffilie = PickedImageData.compressForApiUpload(
      _photoAffilie!,
      maxSide: 960,
      jpegQuality: 72,
    );
    if (_carteIdentite != null) {
      _carteIdentite = PickedImageData.compressForApiUpload(
        _carteIdentite!,
        maxSide: 1400,
        jpegQuality: 78,
      );
    }

    if (!_photoAffilie!.isWithinApiLimit ||
        (_carteIdentite != null && !_carteIdentite!.isWithinApiLimit)) {
      _showSnack(
        'Chaque image jointe doit faire au plus 1 Mo '
        '(photo: ${PickedImageData.formatByteSize(_photoAffilie!.byteLength)}'
        '${_carteIdentite != null ? ', carte: ${PickedImageData.formatByteSize(_carteIdentite!.byteLength)}' : ''}). '
        'Reprenez des images plus légères.',
      );
      return;
    }

    if (!EmailUtils.isEmptyOrValid(_emailAffilieController.text)) {
      _showSnack(EmailUtils.invalidFormatMessage);
      return;
    }

    if (_nomController.text.isEmpty ||
        _prenomController.text.isEmpty ||
        _telephoneController.text.isEmpty ||
        _dateNController.text.isEmpty ||
        _selectedTypeAdhesion == null ||
        _selectedPrestation == null ||
        _montantController.text.isEmpty ||
        _selectedDevise == null ||
        _selectedFraisAdhesion == null ||
        _selectedModePaiement == null) {
      _showSnack('Veuillez remplir tous les champs obligatoires');
      return;
    }

    if (_isMobileMoneyPayment) {
      if (!PhoneUtils.isValidDrcPhone(_telephonePaiementController.text)) {
        _showSnack(PhoneUtils.invalidFormatMessage);
        return;
      }
    }

    final telAffilieNormalise = PhoneUtils.normalizeDrcPhone(
      _telephoneController.text,
    );
    if (telAffilieNormalise == null) {
      _showSnack(
        'Le téléphone de l\'affilié est invalide. ${PhoneUtils.invalidFormatMessage}',
      );
      return;
    }

    // Validations basées sur le type d'adhésion
    final typeAdhesionLibelle = _selectedTypeAdhesion!.libelle.toLowerCase();

    // Solo: ne doit pas avoir de dépendants
    if (!await _validateDependantsCertificats()) {
      return;
    }

    if (typeAdhesionLibelle.contains('solo') && _dependants.isNotEmpty) {
      await _showSnack(
        'Le type d\'adhésion Solo ne permet pas d\'ajouter des personnes à charge.',
      );
      return;
    }

    // F6: doit avoir exactement 5 dépendants maximum
    if (typeAdhesionLibelle.contains('f6') && _dependants.length > 5) {
      await _showSnack(
        'Le type d\'adhésion F6 permet maximum 5 personnes à charge '
        '(${_dependants.length} ajoutées).',
      );
      return;
    }

    if (typeAdhesionLibelle.contains('f3') && _dependants.length > 3) {
      await _showSnack(
        'Le type d\'adhésion F3 permet maximum 3 personnes à charge '
        '(${_dependants.length} ajoutées).',
      );
      return;
    }

    // F6 et F3: l'adhérent lui-même ne doit pas être compté comme dépendant
    if ((typeAdhesionLibelle.contains('f6') ||
        typeAdhesionLibelle.contains('f3'))) {
      // Ces types incluent l'adhérent principal + les dépendants
      // Pas de validation supplémentaire nécessaire car c'est le comportement normal
      debugPrint(
        '[DEBUG] Type d\'adhésion ${_selectedTypeAdhesion!.libelle} - Dépendants: ${_dependants.length}',
      );
    }

    setState(() => _isLoading = true);

    try {
      final agentId = AuthService.currentUser?.utilisateur.agentId;
      if (agentId == null) {
        throw Exception(
          'Identifiant agent introuvable. Reconnectez-vous avec un compte agent.',
        );
      }

      final typeAdhesionId = int.tryParse(
        _typeAdhesionIdController.text.trim(),
      );
      if (typeAdhesionId == null) {
        throw Exception('TypeAdhesionId invalide');
      }

      final prestationId = int.tryParse(_prestationIdController.text.trim());
      if (prestationId == null) {
        throw Exception('PrestationId invalide');
      }

      if (_selectedFraisAdhesion == null) {
        throw Exception('Veuillez sélectionner les frais d\'adhésion');
      }

      if (_selectedPrestation == null) {
        throw Exception('Veuillez sélectionner une prestation');
      }

      final fraisDeviseId = _fraisAdhesionDeviseId;
      final prestationDeviseId = _selectedPrestation!.deviseId;

      final souscriptionMontant =
          _selectedPrestation?.resolveMontant() ??
          double.tryParse(_montantController.text.trim());
      if (souscriptionMontant == null || souscriptionMontant <= 0) {
        throw Exception(
          'Montant de prestation invalide. Saisissez un montant ou choisissez une prestation tarifée.',
        );
      }

      final referencePaiement = _referencePaiementElectronique();

      final dateParts = _dateNController.text.split('/');
      if (dateParts.length != 3) {
        throw Exception('Format de date invalide');
      }
      final dateNaissance = DateTime.utc(
        int.parse(dateParts[2]),
        int.parse(dateParts[1]),
        int.parse(dateParts[0]),
      );

      final request = AdhesionWithAffilieRequest(
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        postnom: _postnomController.text.trim(),
        dateNaissance: dateNaissance,
        telephone:
            PhoneUtils.toInternationalFormat(telAffilieNormalise) ??
            telAffilieNormalise,
        emailAffilie: EmailUtils.isValid(_emailAffilieController.text)
            ? _emailAffilieController.text.trim()
            : null,
        provinceResidence: _provinceController.text.trim(),
        communeResidence: _communeResidenceController.text.trim().isEmpty
            ? null
            : _communeResidenceController.text.trim(),
        quartierResidence: _quartierResidenceController.text.trim().isEmpty
            ? null
            : _quartierResidenceController.text.trim(),
        avenueResidence: _avenueResidenceController.text.trim().isEmpty
            ? null
            : _avenueResidenceController.text.trim(),
        numeroResidence: _numeroResidenceController.text.trim().isEmpty
            ? null
            : _numeroResidenceController.text.trim(),
        communeActivite: _communeActiviteController.text.trim().isEmpty
            ? null
            : _communeActiviteController.text.trim(),
        quartierActivite: _quartierActiviteController.text.trim().isEmpty
            ? null
            : _quartierActiviteController.text.trim(),
        avenueActivite: _avenueActiviteController.text.trim().isEmpty
            ? null
            : _avenueActiviteController.text.trim(),
        numeroActivite: _numeroActiviteController.text.trim().isEmpty
            ? null
            : _numeroActiviteController.text.trim(),
        photoBase64: _photoAffilie!.base64,
        photoContentType: _photoAffilie!.contentType,
        carteIdentiteBase64: _carteIdentite?.base64,
        carteIdentiteContentType: _carteIdentite?.contentType,
        affilieStatut: true,
        typeAdhesionId: typeAdhesionId,
        agentId: agentId,
        adhesionStatut: true,
        // Règle métier: une adhésion nouvellement créée doit toujours démarrer en "En Attente",
        // que des dépendants soient renseignés ou non.
        statutDossier: AdhesionApiValues.statutDossierEnAttente,
        collectes: [
          CollecteRequest(
            typeCollecte: AdhesionApiValues.typeCollecteFrais,
            fraisId: _selectedFraisAdhesion!.idFrais,
            montant: _selectedFraisAdhesion!.montant,
            mois: DateTime.now().month,
            annee: DateTime.now().year,
            modePaiement: _selectedModePaiement,
            statutPaiement: _statutPaiementCollecte,
            montantRecu: _selectedFraisAdhesion!.montant,
            montantAttendu: _selectedFraisAdhesion!.montant,
            deviseId: fraisDeviseId,
            referencePaiement: referencePaiement,
            statut: true,
          ),
          CollecteRequest(
            typeCollecte: AdhesionApiValues.typeCollecteSouscription,
            subscription: SouscriptionRequest(
              prestationId: prestationId,
              dateSouscription: DateTime.now().toUtc(),
              statut: true,
            ),
            montant: souscriptionMontant,
            mois: DateTime.now().month,
            annee: DateTime.now().year,
            modePaiement: _selectedModePaiement,
            statutPaiement: _statutPaiementCollecte,
            montantRecu: souscriptionMontant,
            montantAttendu: souscriptionMontant,
            deviseId: prestationDeviseId > 0
                ? prestationDeviseId
                : fraisDeviseId,
            referencePaiement: referencePaiement,
            statut: true,
          ),
        ],
        dependants: _buildDependantsPayload(),
        antecedants: const [],
      );

      _logAdhesionRequestBody(request);

      if (_isElectronicPayment) {
        final telephonePaiement = _isMobileMoneyPayment
            ? PhoneUtils.normalizeDrcPhone(_telephonePaiementController.text)!
            : telAffilieNormalise;
        final flexResponse =
            await ApiService.createAdhesionWithAffiliePaiementElectronique(
              adhesion: request,
              modePaiement: _selectedModePaiement!,
              telephonePaiement: telephonePaiement,
              devisePaiementId: _selectedDevise!.idDevise,
            );
        if (!mounted) return;
        ScaffoldMessenger.of(context).clearSnackBars();

        if (flexResponse.success && flexResponse.data != null) {
          final payment = flexResponse.data!;
          if (payment.flexPayAccepted &&
              _shouldOpenPaymentWaitingPage(payment)) {
            await _navigateToPaymentWaitingPage(payment);
            return;
          }
          if (payment.flexPayAccepted && _hasFlexPayPaymentUrl(payment)) {
            setState(() => _isLoading = false);
            await _showFlexPayCardPaymentBottomSheet(payment);
            return;
          }
          setState(() => _isLoading = false);
          await FlexPayPaymentErrorDialog.show(
            context,
            message: payment.message ?? 'Paiement non accepté par FlexPay.',
            statusCode: null,
          );
        } else {
          setState(() => _isLoading = false);
          await FlexPayPaymentErrorDialog.show(
            context,
            message: flexResponse.message,
            statusCode: flexResponse.statusCode,
          );
        }
      } else {
        final response = await ApiService.createAdhesionWithAffilieV2(request);
        if (kDebugMode) {
          debugPrint(
            '[Adhesion] success=${response.success} code=${response.statusCode}',
          );
        }
        if (response.success) {
          await _showAdhesionSuccessDialog(
            codeAdhesion: response.data?.codeAdhesion,
          );
        } else if (mounted) {
          await _showApiError(
            response.message,
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('Adhesion/create', e, stackTrace);
      if (mounted) {
        await _showApiError(ApiErrorHelper.userFacingNetwork());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAdhesionSuccessDialog({String? codeAdhesion}) async {
    if (!mounted) return;
    final parentContext = context;
    final hasCode = codeAdhesion != null && codeAdhesion.isNotEmpty;
    await ProsocMessageDialog.show(
      context,
      variant: ProsocMessageVariant.success,
      title: 'Adhésion créée',
      message: hasCode
          ? 'L\'adhésion a été enregistrée avec succès.'
          : 'L\'adhésion a été enregistrée avec succès.',
      hint: hasCode ? 'Code d\'adhésion : $codeAdhesion' : null,
      confirmLabel: 'Fermer',
      onConfirm: () {
        if (parentContext.mounted) {
          Navigator.of(parentContext).pop(true);
        }
      },
    );
  }

  bool _hasFlexPayPaymentUrl(AdhesionElectronicPaymentResponse payment) {
    final url = payment.paymentUrl?.trim() ?? '';
    return url.isNotEmpty && url.toLowerCase() != 'null';
  }

  /// Mobile Money accepté → toujours la page d'attente (pas de SnackBar / dialogue).
  bool _shouldOpenPaymentWaitingPage(
    AdhesionElectronicPaymentResponse payment,
  ) {
    if (!payment.flexPayAccepted) return false;
    if (_isMobileMoneyPayment) return true;
    return !_hasFlexPayPaymentUrl(payment);
  }

  Future<void> _navigateToPaymentWaitingPage(
    AdhesionElectronicPaymentResponse payment,
  ) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    setState(() => _isLoading = false);
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => FlexPayPaymentWaitingScreen(
          payment: payment,
          isMobileMoney: _isMobileMoneyPayment,
        ),
      ),
    );
  }

  Future<void> _showFlexPayCardPaymentBottomSheet(
    AdhesionElectronicPaymentResponse payment,
  ) async {
    if (!mounted) return;
    final url = payment.paymentUrl?.trim() ?? '';
    if (url.isEmpty || url.toLowerCase() == 'null') {
      await FlexPayPaymentErrorDialog.show(
        context,
        message: 'Lien de paiement carte indisponible.',
      );
      return;
    }

    await FlexPayCardPaymentBottomSheet.show(
      context,
      payment: payment,
      onPay: () async {
        if (!mounted) return;
        await PaymentWebViewScreen.open(context, url);
        if (!mounted) return;
        ScaffoldMessenger.of(context).clearSnackBars();
        await _navigateToPaymentWaitingPage(payment);
      },
    );
  }

  int _getMaxDependants() {
    if (_selectedTypeAdhesion == null) return 0;

    final libelle = _selectedTypeAdhesion!.libelle.toLowerCase();
    if (libelle.contains('solo')) return 0;
    if (libelle.contains('f6')) return 5;
    if (libelle.contains('f3')) return 3;
    return 0; // Par défaut, aucun dépendant autorisé
  }

  void _showTypeAdhesionInfo(TypeAdhesion typeAdhesion) {
    final libelle = typeAdhesion.libelle.toLowerCase();
    String message = '';
    Color color = AppColors.prosocGreen;

    if (libelle.contains('solo')) {
      message = 'Solo: Adhésion individuelle sans dépendants autorisés';
    } else if (libelle.contains('f6')) {
      message =
          'F6: Adhérent + maximum 5 dépendants (${_dependants.length}/5 ajoutés)';
      if (_dependants.length > 5) {
        color = Colors.orange;
      }
    } else if (libelle.contains('f3')) {
      message =
          'F3: Adhérent + maximum 3 dépendants (${_dependants.length}/3 ajoutés)';
      if (_dependants.length > 3) {
        color = Colors.orange;
      }
    } else {
      message = 'Type d\'adhésion: ${typeAdhesion.libelle}';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

class StepItem {
  final IconData icon;
  final String label;
  final Color color;

  const StepItem({
    required this.icon,
    required this.label,
    required this.color,
  });
}
