import 'package:flutter/material.dart';
import 'package:prosoc/config/api.dart';
import 'package:prosoc/config/colors.dart';
import 'package:prosoc/models/adhesion_with_affilie_model.dart';
import 'package:prosoc/models/penalite_affilie_model.dart';
import 'package:prosoc/utils/affilie_payment_modes.dart';
import 'package:prosoc/utils/api_error_helper.dart';
import 'package:prosoc/utils/collecte_agent_resolver.dart';
import 'package:prosoc/utils/collecte_montant_helper.dart';
import 'package:prosoc/utils/cotisation_montant_helper.dart';
import 'package:prosoc/utils/paginated_response_helper.dart';
import 'package:prosoc/utils/phone_utils.dart';
import 'package:prosoc/views/screens/at/flex_pay_payment_waiting_screen.dart';
import 'package:prosoc/views/screens/at/payment_webview_screen.dart';
import 'package:prosoc/views/widgets/flex_pay_card_payment_bottom_sheet.dart';
import 'package:prosoc/views/widgets/flex_pay_payment_error_dialog.dart';

/// Paiement d'une cotisation affilié (`typeCollecte = Cotisation`).
class PayerContributionScreen extends StatefulWidget {
  final int affilieId;
  final String affilieNom;
  final String affiliePrenom;
  final int nombreDependants;
  final int? initialTarifId;
  final int? initialArrieresAffilieId;
  final double? initialMontant;
  final String? affilieTelephone;
  /// Agent territorial explicite (encaissement AT / percepteur).
  final int? agentId;
  final String screenTitle;
  /// Adhérent : Mobile Money / Carte. Agent ou percepteur : inclut compte virtuel.
  final bool allowVirtualAccount;

  const PayerContributionScreen({
    super.key,
    required this.affilieId,
    required this.affilieNom,
    required this.affiliePrenom,
    this.nombreDependants = 0,
    this.initialTarifId,
    this.initialArrieresAffilieId,
    this.initialMontant,
    this.affilieTelephone,
    this.agentId,
    this.screenTitle = 'Payer une cotisation',
    this.allowVirtualAccount = false,
  });

  @override
  State<PayerContributionScreen> createState() => _PayerContributionScreenState();
}

class _PayerContributionScreenState extends State<PayerContributionScreen>
    with TickerProviderStateMixin {
  Map<String, String> get _modesPaiement =>
      AffiliePaymentModes.modesFor(
        allowVirtualAccount: widget.allowVirtualAccount,
      );

  late String? _selectedModePaiement;
  int? _selectedTarifId;
  List<Map<String, dynamic>> _tarifs = [];
  bool _isLoadingTarifs = false;
  String? _selectedDevise;
  int? _selectedDeviseId;
  List<dynamic> _devises = [];
  bool _isLoadingDevises = false;
  bool _isLoading = false;
  bool _isLoadingDependants = false;
  int _nombreDependantsEffectif = 0;
  int? _agentId;
  double? _montantAttendu;
  List<PenaliteAffilieModel> _penalites = [];
  bool _isLoadingPenalites = false;

  final TextEditingController _montantController = TextEditingController();
  final TextEditingController _observationController = TextEditingController();
  final TextEditingController _telephonePaiementController =
      TextEditingController();

  bool get _isMobileMoneyPayment =>
      AffiliePaymentModes.isMobileMoney(_selectedModePaiement);

  bool get _isElectronicPayment =>
      AffiliePaymentModes.isElectronic(_selectedModePaiement);

  /// Référence auto pour Mobile Money / Carte (non affichée à l'utilisateur).
  String _referencePaiementElectronique(DateTime now) {
    return 'COT-ELEC-${now.millisecondsSinceEpoch}';
  }

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _selectedModePaiement = AffiliePaymentModes.defaultModeFor(
      allowVirtualAccount: widget.allowVirtualAccount,
    );
    final tel = widget.affilieTelephone?.trim();
    if (tel != null && tel.isNotEmpty) {
      _telephonePaiementController.text = tel;
    }
    _nombreDependantsEffectif = widget.nombreDependants;
    _initializeAnimations();
    _loadAgentId();
    _loadNombreDependants();
    _loadPenalites();
    _loadTarifs();
    _loadDevises();
  }

  @override
  void dispose() {
    _montantController.dispose();
    _observationController.dispose();
    _telephonePaiementController.dispose();
    _animationController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  int? _intFrom(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  double? _doubleFrom(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  Map<String, dynamic> _mapFrom(dynamic item) {
    if (item is Map<String, dynamic>) return item;
    if (item is Map) return Map<String, dynamic>.from(item);
    return const {};
  }

  bool _isTarifActif(Map<String, dynamic> tarif) {
    final statut = tarif['statut'];
    if (statut is bool) return statut;
    if (statut is num) return statut != 0;
    return true;
  }

  String _typeAdhesionLibelleFromTarif(Map<String, dynamic> tarif) {
    return (tarif['typeAdhesionLibelle'] ??
            tarif['TypeAdhesionLibelle'] ??
            '')
        .toString()
        .trim();
  }

  String? get _montantCalculLibelle {
    final tarif = _tarifById(_selectedTarifId);
    final montantUnitaire = tarif != null ? _doubleFrom(tarif['montant']) : null;
    if (tarif == null || montantUnitaire == null || montantUnitaire <= 0) {
      return null;
    }
    return CotisationMontantHelper.libelleCalculComplet(
      tarifUnitaire: montantUnitaire,
      typeAdhesionLibelle: _typeAdhesionLibelleFromTarif(tarif),
      nombreDependants: _nombreDependantsEffectif,
      penalites: _penalites,
      deviseCode: _selectedDevise,
    );
  }

  Future<void> _loadPenalites() async {
    final arriereId = widget.initialArrieresAffilieId;
    if (arriereId == null || arriereId <= 0) return;

    setState(() => _isLoadingPenalites = true);

    try {
      final response = await ApiService.getPenalitesByArriere(arriereId);
      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _penalites = response.data!
              .where((penalite) => penalite.estPayable)
              .toList();
        });
        final selectedTarifId = _selectedTarifId;
        if (selectedTarifId != null) {
          _applyTarifSelection(selectedTarifId);
        } else if (widget.initialMontant != null && widget.initialMontant! > 0) {
          _applyMontantAvecPenalites(widget.initialMontant!);
        }
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException(
        'Contribution/penalites',
        e,
        stackTrace,
        false,
      );
    } finally {
      if (mounted) setState(() => _isLoadingPenalites = false);
    }
  }

  void _applyMontantAvecPenalites(double montantCotisation) {
    final montantEffectif = CotisationMontantHelper.montantTotalAvecPenalites(
          montantCotisation: montantCotisation,
          penalites: _penalites,
        ) ??
        montantCotisation;

    setState(() {
      _montantAttendu = montantEffectif;
      if (montantEffectif > 0) {
        _montantController.text = montantEffectif.toString();
      }
    });
  }

  String _tarifLabel(Map<String, dynamic> tarif) {
    final libelle = _typeAdhesionLibelleFromTarif(tarif);
    final periodicite = tarif['periodicite']?.toString().trim() ?? '';
    final montant = _doubleFrom(tarif['montant']);
    final montantLabel = montant != null ? ' - $montant (unitaire)' : '';
    final parts = <String>[
      if (libelle.isNotEmpty) libelle,
      if (periodicite.isNotEmpty) periodicite,
    ];
    return '${parts.join(' · ')}$montantLabel';
  }

  Map<String, dynamic>? _tarifById(int? id) {
    if (id == null) return null;
    for (final item in _tarifs) {
      if (_intFrom(item['id']) == id) return item;
    }
    return null;
  }

  String _deviseCodeFromMap(Map<String, dynamic> devise) {
    return (devise['code'] ?? devise['codeDevise'] ?? '').toString().trim();
  }

  int? _deviseIdFromMap(Map<String, dynamic> devise) {
    return _intFrom(devise['idDevise'] ?? devise['id']);
  }

  String _deviseCodeFromTarif(Map<String, dynamic> tarif) {
    return (tarif['deviseCode'] ??
            tarif['DeviseCode'] ??
            tarif['codeDevise'] ??
            tarif['CodeDevise'] ??
            '')
        .toString()
        .trim();
  }

  int? _deviseIdFromTarif(Map<String, dynamic> tarif) {
    return _intFrom(tarif['deviseId'] ?? tarif['DeviseId']);
  }

  void _applyDeviseFromTarif(Map<String, dynamic> tarif) {
    final deviseId = _deviseIdFromTarif(tarif);
    final codeFromTarif = _deviseCodeFromTarif(tarif);

    if (_devises.isNotEmpty) {
      if (deviseId != null && deviseId > 0) {
        for (final item in _devises) {
          final map = _mapFrom(item);
          if (_deviseIdFromMap(map) == deviseId) {
            _selectedDeviseId = deviseId;
            _selectedDevise = _deviseCodeFromMap(map);
            return;
          }
        }
      }
      if (codeFromTarif.isNotEmpty) {
        for (final item in _devises) {
          final map = _mapFrom(item);
          final code = _deviseCodeFromMap(map);
          if (code.toUpperCase() == codeFromTarif.toUpperCase()) {
            _selectedDevise = code;
            _selectedDeviseId = _deviseIdFromMap(map);
            return;
          }
        }
      }
    }

    if (deviseId != null && deviseId > 0) {
      _selectedDeviseId = deviseId;
    }
    if (codeFromTarif.isNotEmpty) {
      _selectedDevise = codeFromTarif;
    } else if (deviseId == 2) {
      _selectedDevise = 'USD';
    } else if (deviseId == 1) {
      _selectedDevise = 'CDF';
    }
  }

  String _deviseDisplayLabel() {
    if (_selectedDevise == null || _selectedDevise!.isEmpty) {
      return '';
    }
    for (final item in _devises) {
      final map = _mapFrom(item);
      final code = _deviseCodeFromMap(map);
      if (code.toUpperCase() == _selectedDevise!.toUpperCase()) {
        final nom = (map['nom'] ?? map['nomDevise'] ?? '').toString().trim();
        return nom.isNotEmpty ? '$code - $nom' : code;
      }
    }
    return _selectedDevise!;
  }

  String? get _montantPrefix {
    final code = _selectedDevise?.toUpperCase();
    if (code == 'USD') return r'$ ';
    if (code == 'CDF') return null;
    if (code != null && code.isNotEmpty) return '$code ';
    return r'$ ';
  }

  Future<void> _loadTarifs() async {
    setState(() {
      _isLoadingTarifs = true;
      _selectedTarifId = null;
      _selectedDevise = null;
      _selectedDeviseId = null;
    });

    try {
      final byAffilie = await ApiService.getTarifCotisationByAffilie(
        widget.affilieId,
      );
      if (!mounted) return;

      List<Map<String, dynamic>> rows = [];
      if (byAffilie.success && byAffilie.data != null) {
        rows = byAffilie.data!
            .map(_mapFrom)
            .where((t) => t.isNotEmpty && _isTarifActif(t))
            .toList();
      }

      setState(() {
        _tarifs = rows;
        _isLoadingTarifs = false;
      });
      if (rows.length == 1) {
        final onlyId = _intFrom(rows.first['id']);
        if (onlyId != null) {
          _applyTarifSelection(onlyId);
          return;
        }
      }
      final initialId = widget.initialTarifId;
      if (initialId != null && _tarifById(initialId) != null) {
        _applyTarifSelection(initialId);
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('Contribution/tarifs', e, stackTrace, false);
      if (!mounted) return;
      setState(() {
        _tarifs = [];
        _isLoadingTarifs = false;
      });
    }
  }

  void _applyTarifSelection(int tarifId) {
    final tarif = _tarifById(tarifId);
    if (tarif == null) return;

    final montantTarif = _doubleFrom(tarif['montant']);
    final montantTotal = CotisationMontantHelper.montantTotal(
      tarifUnitaire: montantTarif,
      typeAdhesionLibelle: _typeAdhesionLibelleFromTarif(tarif),
      nombreDependants: _nombreDependantsEffectif,
    );
    final montantOverride = widget.initialMontant;
    final montantBase = (montantOverride != null && montantOverride > 0)
        ? montantOverride
        : (montantTotal ?? montantTarif);
    final montantEffectif = CotisationMontantHelper.montantTotalAvecPenalites(
          montantCotisation: montantBase,
          penalites: _penalites,
        ) ??
        montantBase;

    setState(() {
      _selectedTarifId = tarifId;
      _montantAttendu = montantEffectif;
      if (montantEffectif != null && montantEffectif > 0) {
        _montantController.text = montantEffectif.toString();
      } else if (montantTarif != null && montantTarif > 0) {
        _montantController.text = montantTarif.toString();
      }
      _applyDeviseFromTarif(tarif);
    });
  }

  Future<void> _loadNombreDependants() async {
    setState(() => _isLoadingDependants = true);

    try {
      final response = await ApiService.getDependantsByAffilie(
        widget.affilieId,
        pageSize: 100,
      );
      if (!mounted) return;

      if (response.success && response.data != null) {
        final total = PaginatedResponseHelper.extractTotalItems(response.data!);
        setState(() => _nombreDependantsEffectif = total);
        final selectedTarifId = _selectedTarifId;
        if (selectedTarifId != null) {
          _applyTarifSelection(selectedTarifId);
        }
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException(
        'Contribution/dependants',
        e,
        stackTrace,
        false,
      );
    } finally {
      if (mounted) setState(() => _isLoadingDependants = false);
    }
  }

  void _initializeAnimations() {
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

  Future<void> _loadAgentId() async {
    final resolved = await CollecteAgentResolver.resolveForAffilie(
      widget.affilieId,
      explicitAgentId: widget.agentId,
    );
    if (!mounted) return;
    setState(() => _agentId = resolved);
  }

  Future<void> _loadDevises() async {
    setState(() => _isLoadingDevises = true);

    try {
      final response = await ApiService.getDevises();
      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _devises = response.data as List<dynamic>;
          _isLoadingDevises = false;
          final tarif = _tarifById(_selectedTarifId);
          if (tarif != null) {
            _applyDeviseFromTarif(tarif);
          }
        });
      } else {
        setState(() => _isLoadingDevises = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingDevises = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildAffilieBanner(),
                    const SizedBox(height: 16),
                    _buildForm(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.prosocGreen),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAffilieBanner() {
    final name = '${widget.affiliePrenom} ${widget.affilieNom}'.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.prosocGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.prosocGreen.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline, color: AppColors.prosocGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? name : 'Affilié #${widget.affilieId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if (widget.nombreDependants > 0)
                  Text(
                    '${widget.nombreDependants} personne(s) à charge',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_rounded,
          color: AppColors.textPrimary,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.screenTitle,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        _buildFormField(
          label: 'Tarif de cotisation',
          icon: Icons.receipt_long_outlined,
          required: true,
          child: _isLoadingTarifs
              ? const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _tarifs.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Aucun tarif de cotisation disponible pour cet affilié.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                )
              : DropdownButtonFormField<int?>(
                  initialValue: _selectedTarifId,
                  decoration: _inputDecoration('Sélectionner un tarif'),
                  items: _tarifs.map((tarif) {
                    final id = _intFrom(tarif['id']);
                    return DropdownMenuItem<int?>(
                      value: id,
                      child: Text(
                        _tarifLabel(tarif),
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    _applyTarifSelection(value);
                  },
                ),
        ),
        const SizedBox(height: 16),
        _buildFormField(
          label: 'Montant',
          icon: Icons.payments_outlined,
          required: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _montantController,
                decoration: _inputDecoration(
                  CollecteMontantHelper.montantFieldHint(
                    montantAttendu: _montantAttendu,
                  ),
                  prefix: _montantPrefix != null ? Text(_montantPrefix!) : null,
                  suffix: _selectedDevise?.toUpperCase() == 'CDF'
                      ? const Text(' CDF')
                      : null,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (CollecteMontantHelper.montantAttenduLibelle(
                    montantAttendu: _montantAttendu,
                  ) !=
                  null) ...[
                const SizedBox(height: 8),
                Text(
                  CollecteMontantHelper.montantAttenduLibelle(
                    montantAttendu: _montantAttendu,
                  )!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
              if (_isLoadingDependants) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Chargement des dépendants…',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ] else if (_isLoadingPenalites) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Calcul des pénalités…',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ] else if (_montantCalculLibelle != null) ...[
                const SizedBox(height: 8),
                Text(
                  _montantCalculLibelle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildFormField(
          label: 'Devise',
          icon: Icons.attach_money,
          required: true,
          child: _isLoadingDevises
              ? const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : InputDecorator(
                  decoration: _inputDecoration(
                    _selectedTarifId == null
                        ? 'Choisir un tarif de cotisation'
                        : 'Devise du tarif sélectionné',
                  ).copyWith(
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  child: Text(
                    _deviseDisplayLabel().isEmpty ? '—' : _deviseDisplayLabel(),
                    style: TextStyle(
                      fontSize: 14,
                      color: _selectedDevise == null
                          ? Colors.grey.shade500
                          : const Color(0xFF2D3436),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 16),
        _buildFormField(
          label: 'Mode de paiement',
          icon: Icons.payment_outlined,
          required: true,
          child: DropdownButtonFormField<String>(
            initialValue: _selectedModePaiement,
            decoration: _inputDecoration('Mode de paiement'),
            items: _modesPaiement.entries
                .map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedModePaiement = value;
                if (value == 'MOBILE_MONEY' &&
                    _telephonePaiementController.text.trim().isEmpty) {
                  final tel = widget.affilieTelephone?.trim() ?? '';
                  if (tel.isNotEmpty) {
                    _telephonePaiementController.text = tel;
                  }
                }
              });
            },
          ),
        ),
        if (_isMobileMoneyPayment) ...[
          const SizedBox(height: 16),
          _buildFormField(
            label: 'Numéro Mobile Money (affilié)',
            icon: Icons.phone_android_outlined,
            required: true,
            child: TextField(
              controller: _telephonePaiementController,
              decoration: _inputDecoration('243987654321'),
              keyboardType: TextInputType.phone,
            ),
          ),
        ],
        const SizedBox(height: 16),
        _buildFormField(
          label: 'Observation',
          icon: Icons.note_outlined,
          child: TextField(
            controller: _observationController,
            maxLines: 3,
            decoration: _inputDecoration('Notes supplémentaires...'),
          ),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required IconData icon,
    required Widget child,
    bool required = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.prosocGreen),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3436),
                  ),
                ),
                if (required)
                  Text(
                    ' *',
                    style: TextStyle(color: Colors.red.shade400, fontSize: 14),
                  ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    String hint, {
    Widget? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefix: prefix,
      suffix: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.prosocGreen, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitContribution,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.prosocGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Enregistrer le paiement',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }

  Map<String, dynamic> _buildCollecteBody({
    required double montantRecu,
    required double montantAttendu,
    required int tarifId,
    required String referencePaiement,
    required int deviseId,
    required String modePaiement,
    required String statutPaiement,
    required DateTime now,
  }) {
    final observation = _observationController.text.trim();
    return {
      'typeCollecte': 'Cotisation',
      'cotisationAffilieId': tarifId,
      'affilieId': widget.affilieId,
      'agentId': _agentId,
      'montant': montantRecu,
      'mois': now.month,
      'annee': now.year,
      'referencePaiement': referencePaiement,
      'modePaiement': modePaiement,
      'statutPaiement': statutPaiement,
      'montantRecu': montantRecu,
      'montantAttendu': montantAttendu,
      'deviseId': deviseId,
      if (observation.isNotEmpty) 'observation': observation,
      if (_isMobileMoneyPayment &&
          _telephonePaiementController.text.trim().isNotEmpty)
        'phone': PhoneUtils.normalizeDrcPhone(
          _telephonePaiementController.text,
        ),
      'statut': true,
    };
  }

  Future<void> _submitContribution() async {
    if (_selectedTarifId == null) {
      _showErrorSnackBar('Veuillez sélectionner un tarif de cotisation');
      return;
    }
    if (_selectedDevise == null || _montantController.text.isEmpty) {
      _showErrorSnackBar('Veuillez sélectionner un tarif avec un montant valide');
      return;
    }
    if (_selectedModePaiement == null) {
      _showErrorSnackBar('Veuillez choisir un mode de paiement');
      return;
    }

    if (_agentId == null) {
      await _loadAgentId();
    }
    final collecteAgentId = _agentId;
    if (collecteAgentId == null) {
      _showErrorSnackBar(
        'Agent territorial introuvable pour cet affilié. Contactez votre agent.',
      );
      return;
    }

    if (_isMobileMoneyPayment &&
        !PhoneUtils.isValidDrcPhone(_telephonePaiementController.text)) {
      _showErrorSnackBar(PhoneUtils.invalidFormatMessage);
      return;
    }

    final selectedTarif = _tarifById(_selectedTarifId);
    if (selectedTarif == null) {
      _showErrorSnackBar('Tarif invalide. Réessayez la sélection.');
      return;
    }

    final montantRecu = double.tryParse(_montantController.text);
    final montantAttendu = CotisationMontantHelper.montantTotalAvecPenalites(
          montantCotisation: _montantAttendu ??
              CotisationMontantHelper.montantTotal(
                tarifUnitaire: _doubleFrom(selectedTarif['montant']),
                typeAdhesionLibelle: _typeAdhesionLibelleFromTarif(selectedTarif),
                nombreDependants: _nombreDependantsEffectif,
              ),
          penalites: _penalites,
        ) ??
        _montantAttendu ??
        CotisationMontantHelper.montantTotal(
          tarifUnitaire: _doubleFrom(selectedTarif['montant']),
          typeAdhesionLibelle: _typeAdhesionLibelleFromTarif(selectedTarif),
          nombreDependants: _nombreDependantsEffectif,
        ) ??
        montantRecu ??
        0;

    final montantError = CollecteMontantHelper.validatePartialPayment(
      montantRecu: montantRecu ?? 0,
      montantAttendu: montantAttendu > 0 ? montantAttendu : null,
    );
    if (montantError != null) {
      _showErrorSnackBar(montantError);
      return;
    }

    final montantPaye = montantRecu!;

    final deviseId = _selectedDeviseId;
    if (deviseId == null || deviseId <= 0) {
      _showErrorSnackBar(
        'Devise introuvable pour ce tarif. Réessayez la sélection.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final tarifId = _selectedTarifId!;
      final modePaiement = _selectedModePaiement!;
      final statutPaiement = _isElectronicPayment ? 'EN_ATTENTE' : 'OK';

      if (_isElectronicPayment) {
        final referencePaiement = _referencePaiementElectronique(now);
        final telephonePaiement = _isMobileMoneyPayment
            ? PhoneUtils.normalizeDrcPhone(_telephonePaiementController.text)!
            : PhoneUtils.normalizeDrcPhone(widget.affilieTelephone) ??
                  PhoneUtils.normalizeDrcPhone(
                    _telephonePaiementController.text,
                  ) ??
                  '';

        if (telephonePaiement.isEmpty) {
          _showErrorSnackBar(PhoneUtils.invalidFormatMessage);
          return;
        }

        final collecte = _buildCollecteBody(
          montantRecu: montantPaye,
          montantAttendu: montantAttendu,
          tarifId: tarifId,
          referencePaiement: referencePaiement,
          deviseId: deviseId,
          modePaiement: modePaiement,
          statutPaiement: statutPaiement,
          now: now,
        );

        final flexResponse =
            await ApiService.createCollecteWithPaiementElectronique(
              collecte: collecte,
              modePaiement: modePaiement,
              telephonePaiement: telephonePaiement,
              devisePaiementId: deviseId,
            );

        if (!mounted) return;
        ScaffoldMessenger.of(context).clearSnackBars();

        if (flexResponse.success && flexResponse.data != null) {
          await _handleFlexPayResponse(flexResponse.data!);
        } else {
          setState(() => _isLoading = false);
          await FlexPayPaymentErrorDialog.show(
            context,
            message: flexResponse.message,
            statusCode: flexResponse.statusCode,
          );
        }
        return;
      }

      final response = await ApiService.createCollecte(
        typeCollecte: 'Cotisation',
        affilieId: widget.affilieId,
        agentId: collecteAgentId,
        cotisationAffilieId: tarifId,
        montant: montantPaye,
        mois: now.month,
        annee: now.year,
        referencePaiement: '',
        modePaiement: modePaiement,
        statutPaiement: statutPaiement,
        montantRecu: montantPaye,
        montantAttendu: montantAttendu,
        deviseId: deviseId,
        observation: _observationController.text.trim(),
        phone: _telephonePaiementController.text.trim().isNotEmpty
            ? PhoneUtils.normalizeDrcPhone(_telephonePaiementController.text)
            : null,
      );

      if (!mounted) return;

      if (response.success) {
        _showSuccessSnackBar('Cotisation enregistrée avec succès');
        Navigator.pop(context, true);
      } else {
        await FlexPayPaymentErrorDialog.show(
          context,
          message: response.message,
          statusCode: response.statusCode,
        );
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('ContributionScreen/submit', e, stackTrace);
      if (!mounted) return;
      _showErrorSnackBar(ApiErrorHelper.userFacingNetwork());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _hasFlexPayPaymentUrl(AdhesionElectronicPaymentResponse payment) {
    final url = payment.paymentUrl?.trim() ?? '';
    return url.isNotEmpty && url.toLowerCase() != 'null';
  }

  bool _shouldOpenPaymentWaitingPage(
    AdhesionElectronicPaymentResponse payment,
  ) {
    if (!payment.flexPayAccepted) return false;
    if (_isMobileMoneyPayment) return true;
    return !_hasFlexPayPaymentUrl(payment);
  }

  Future<void> _handleFlexPayResponse(
    AdhesionElectronicPaymentResponse payment,
  ) async {
    if (payment.flexPayAccepted && _shouldOpenPaymentWaitingPage(payment)) {
      setState(() => _isLoading = false);
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => FlexPayPaymentWaitingScreen(
            payment: payment,
            isMobileMoney: _isMobileMoneyPayment,
          ),
        ),
      );
      if (result == true && mounted) {
        Navigator.pop(context, true);
      }
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
    );
  }

  Future<void> _showFlexPayCardPaymentBottomSheet(
    AdhesionElectronicPaymentResponse payment,
  ) async {
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
        await PaymentWebViewScreen.open(context, url);
        if (!mounted) return;
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => FlexPayPaymentWaitingScreen(
              payment: payment,
              isMobileMoney: false,
            ),
          ),
        );
        if (result == true && mounted) {
          Navigator.pop(context, true);
        }
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.prosocGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
