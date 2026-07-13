import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../config/api.dart';
import '../../../config/colors.dart';
import '../../../models/adhesion_with_affilie_model.dart';
import '../../../models/devise_model.dart';
import '../../../models/frais_model.dart';
import '../../../models/prestation_model.dart';
import '../../../models/type_adhesion_model.dart';
import '../../../utils/affilie_payment_modes.dart';
import '../../../utils/api_error_helper.dart';
import '../../../utils/email_utils.dart';
import '../../../utils/phone_utils.dart';
import '../../../utils/picked_image_data.dart';
import '../../widgets/flex_pay_card_payment_bottom_sheet.dart';
import '../../widgets/flex_pay_payment_error_dialog.dart';
import '../../widgets/prosoc_date_picker.dart';
import '../at/flex_pay_payment_waiting_screen.dart';
import '../at/payment_webview_screen.dart';

/// Inscription publique adhérent (sans agent) — paiement FlexPay MM/Carte.
class AdherentRegisterScreen extends StatefulWidget {
  const AdherentRegisterScreen({super.key});

  @override
  State<AdherentRegisterScreen> createState() => _AdherentRegisterScreenState();
}

class _AdherentRegisterScreenState extends State<AdherentRegisterScreen> {
  final _pageController = PageController();
  final _identityFormKey = GlobalKey<FormState>();
  final _paymentFormKey = GlobalKey<FormState>();

  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _postnomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _provinceController = TextEditingController();
  final _communeController = TextEditingController();
  final _dateNController = TextEditingController();
  final _telephonePaiementController = TextEditingController();

  int _currentStep = 0;
  bool _isLoadingCatalog = true;
  bool _isSubmitting = false;
  String? _catalogError;

  List<TypeAdhesion> _typeAdhesions = [];
  List<Frais> _fraisAdhesion = [];
  List<Prestation> _prestations = [];
  List<Devise> _devises = [];

  TypeAdhesion? _selectedType;
  Frais? _selectedFrais;
  Prestation? _selectedPrestation;
  Devise? _selectedDevise;
  String _selectedModePaiement = AffiliePaymentModes.mobileMoney;

  PickedImageData? _photo;
  PickedImageData? _carteIdentite;

  static const _steps = [
    'Identité',
    'Adhésion',
    'Documents',
    'Paiement',
  ];

  @override
  void initState() {
    super.initState();
    _loadCatalogs();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _postnomController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _provinceController.dispose();
    _communeController.dispose();
    _dateNController.dispose();
    _telephonePaiementController.dispose();
    super.dispose();
  }

  bool get _isMobileMoney =>
      AffiliePaymentModes.isMobileMoney(_selectedModePaiement);

  Future<void> _loadCatalogs() async {
    setState(() {
      _isLoadingCatalog = true;
      _catalogError = null;
    });

    try {
      final results = await Future.wait([
        ApiService.getTypeAdhesions(),
        ApiService.getFrais(),
        ApiService.getPrestations(),
        ApiService.getDevises(),
      ]);

      if (!mounted) return;

      final failed = results.where((r) => !r.success).toList();
      if (failed.isNotEmpty) {
        setState(() {
          _catalogError = failed.first.message ??
              'Impossible de charger les catalogues. Réessayez plus tard.';
          _isLoadingCatalog = false;
        });
        return;
      }

      final types = _extractList(results[0].data)
          .whereType<Map>()
          .map((j) => TypeAdhesion.fromJson(Map<String, dynamic>.from(j)))
          .where((t) => t.statut)
          .toList();

      final frais = _extractList(results[1].data)
          .whereType<Map>()
          .map((j) => Frais.fromJson(Map<String, dynamic>.from(j)))
          .where((f) => f.statut && f.isPourAdhesion)
          .toList();

      final prestations = _extractList(results[2].data)
          .whereType<Map>()
          .map((j) => Prestation.fromJson(Map<String, dynamic>.from(j)))
          .toList();

      final devises = _extractList(results[3].data)
          .whereType<Map>()
          .map((j) => Devise.fromJson(Map<String, dynamic>.from(j)))
          .toList();

      setState(() {
        _typeAdhesions = types;
        _fraisAdhesion = frais;
        _prestations = prestations;
        _devises = devises;
        _selectedType = types.isNotEmpty ? types.first : null;
        _selectedFrais = frais.isNotEmpty ? frais.first : null;
        _selectedPrestation =
            prestations.isNotEmpty ? prestations.first : null;
        _selectedDevise = devises.isNotEmpty ? devises.first : null;
        _isLoadingCatalog = false;
      });
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('Register/catalogs', e, stackTrace, false);
      if (!mounted) return;
      setState(() {
        _catalogError = ApiErrorHelper.userFacingNetwork();
        _isLoadingCatalog = false;
      });
    }
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const [];
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _nextStep() async {
    if (_currentStep == 0) {
      if (!_identityFormKey.currentState!.validate()) return;
      final tel = PhoneUtils.normalizeDrcPhone(_telephoneController.text);
      if (tel == null) {
        _showSnack(PhoneUtils.invalidFormatMessage, isError: true);
        return;
      }
    }
    if (_currentStep == 1) {
      if (_selectedType == null ||
          _selectedFrais == null ||
          _selectedPrestation == null) {
        _showSnack('Veuillez compléter les choix d\'adhésion.', isError: true);
        return;
      }
    }
    if (_currentStep < _steps.length - 1) {
      _goToStep(_currentStep + 1);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) _goToStep(_currentStep - 1);
  }

  Future<void> _pickImage(bool isPhoto) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Appareil photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galerie'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await PickedImageData.pick(source: source);
    if (picked == null || !mounted) return;

    final compressed = PickedImageData.compressForApiUpload(picked);
    if (!compressed.isWithinApiLimit) {
      _showSnack(
        'Image trop volumineuse (max ${PickedImageData.formatByteSize(PickedImageData.maxApiImageBytes)}).',
        isError: true,
      );
      return;
    }

    setState(() {
      if (isPhoto) {
        _photo = compressed;
      } else {
        _carteIdentite = compressed;
      }
    });
  }

  Future<void> _submit() async {
    if (!_paymentFormKey.currentState!.validate()) return;
    if (_selectedType == null ||
        _selectedFrais == null ||
        _selectedPrestation == null ||
        _selectedDevise == null) {
      _showSnack('Catalogues incomplets.', isError: true);
      return;
    }

    final telAffilie = PhoneUtils.normalizeDrcPhone(_telephoneController.text);
    if (telAffilie == null) {
      _showSnack(PhoneUtils.invalidFormatMessage, isError: true);
      return;
    }

    final dateParts = _dateNController.text.split('/');
    if (dateParts.length != 3) {
      _showSnack('Date de naissance invalide.', isError: true);
      return;
    }

    final dateNaissance = DateTime.utc(
      int.parse(dateParts[2]),
      int.parse(dateParts[1]),
      int.parse(dateParts[0]),
    );

    final souscriptionMontant = _selectedPrestation!.resolveMontant() ?? 0;
    if (souscriptionMontant <= 0) {
      _showSnack('Montant de prestation invalide.', isError: true);
      return;
    }

    final telephonePaiement = _isMobileMoney
        ? PhoneUtils.normalizeDrcPhone(_telephonePaiementController.text)
        : telAffilie;
    if (telephonePaiement == null) {
      _showSnack('Téléphone de paiement invalide.', isError: true);
      return;
    }

    final reference =
        'REG-${DateTime.now().millisecondsSinceEpoch}-${telAffilie.substring(telAffilie.length - 4)}';

    final request = AdhesionWithAffilieRequest(
      nom: _nomController.text.trim(),
      prenom: _prenomController.text.trim(),
      postnom: _postnomController.text.trim(),
      dateNaissance: dateNaissance,
      telephone: PhoneUtils.toInternationalFormat(telAffilie) ?? telAffilie,
      emailAffilie: EmailUtils.isValid(_emailController.text)
          ? _emailController.text.trim()
          : null,
      provinceResidence: _provinceController.text.trim(),
      communeResidence: _communeController.text.trim().isEmpty
          ? null
          : _communeController.text.trim(),
      photoBase64: _photo?.base64,
      photoContentType: _photo?.contentType,
      carteIdentiteBase64: _carteIdentite?.base64,
      carteIdentiteContentType: _carteIdentite?.contentType,
      affilieStatut: true,
      typeAdhesionId: _selectedType!.id,
      adhesionStatut: true,
      statutDossier: AdhesionApiValues.statutDossierEnLigne,
      collectes: [
        CollecteRequest(
          typeCollecte: AdhesionApiValues.typeCollecteFrais,
          fraisId: _selectedFrais!.idFrais,
          montant: _selectedFrais!.montant,
          mois: DateTime.now().month,
          annee: DateTime.now().year,
          modePaiement: _selectedModePaiement,
          statutPaiement: 'EN_ATTENTE',
          montantRecu: _selectedFrais!.montant,
          montantAttendu: _selectedFrais!.montant,
          deviseId: _selectedFrais!.deviseId,
          referencePaiement: reference,
          statut: true,
        ),
        CollecteRequest(
          typeCollecte: AdhesionApiValues.typeCollecteSouscription,
          subscription: SouscriptionRequest(
            prestationId: _selectedPrestation!.id,
            dateSouscription: DateTime.now().toUtc(),
            statut: true,
          ),
          montant: souscriptionMontant,
          mois: DateTime.now().month,
          annee: DateTime.now().year,
          modePaiement: _selectedModePaiement,
          statutPaiement: 'EN_ATTENTE',
          montantRecu: souscriptionMontant,
          montantAttendu: souscriptionMontant,
          deviseId: _selectedPrestation!.deviseId > 0
              ? _selectedPrestation!.deviseId
              : _selectedFrais!.deviseId,
          referencePaiement: reference,
          statut: true,
        ),
      ],
    );

    setState(() => _isSubmitting = true);

    try {
      final response =
          await ApiService.createAdhesionWithAffiliePaiementElectronique(
        adhesion: request,
        modePaiement: _selectedModePaiement,
        telephonePaiement: telephonePaiement,
        devisePaiementId: _selectedDevise!.idDevise,
      );

      if (!mounted) return;

      if (!response.success || response.data == null) {
        await FlexPayPaymentErrorDialog.show(
          context,
          message: response.message,
          statusCode: response.statusCode,
        );
        return;
      }

      final payment = response.data!;
      if (!payment.flexPayAccepted) {
        await FlexPayPaymentErrorDialog.show(
          context,
          message: payment.message ?? 'Paiement non accepté.',
        );
        return;
      }

      if (_isMobileMoney || !_hasPaymentUrl(payment)) {
        final paid = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => FlexPayPaymentWaitingScreen(
              payment: payment,
              isMobileMoney: _isMobileMoney,
            ),
          ),
        );
        if (paid == true && mounted) {
          await _showRegisterSuccess();
        }
        return;
      }

      await FlexPayCardPaymentBottomSheet.show(
        context,
        payment: payment,
        onPay: () async {
          final url = payment.paymentUrl?.trim() ?? '';
          if (url.isEmpty) return;
          await PaymentWebViewScreen.open(context, url);
          if (!mounted) return;
          final paid = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => FlexPayPaymentWaitingScreen(
                payment: payment,
                isMobileMoney: false,
              ),
            ),
          );
          if (paid == true && mounted) {
            await _showRegisterSuccess();
          }
        },
      );
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('Register/submit', e, stackTrace);
      if (mounted) {
        _showSnack(ApiErrorHelper.userFacingNetwork(), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  bool _hasPaymentUrl(AdhesionElectronicPaymentResponse payment) {
    final url = payment.paymentUrl?.trim() ?? '';
    return url.isNotEmpty && url.toLowerCase() != 'null';
  }

  Future<void> _showRegisterSuccess() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.prosocGreen, size: 32),
            SizedBox(width: 12),
            Expanded(child: Text('Inscription réussie')),
          ],
        ),
        content: const Text(
          'Votre adhésion a été enregistrée.\n\n'
          'Connectez-vous avec votre code d\'adhésion (reçu par SMS/e-mail) '
          'et le mot de passe temporaire : 123456\n\n'
          'Vous devrez changer votre mot de passe à la première connexion.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.prosocGreen,
            ),
            child: const Text('Aller à la connexion'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.errorColor : AppColors.prosocGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Créer un compte adhérent',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: isDark ? theme.appBarTheme.backgroundColor : Colors.white,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: _isLoadingCatalog
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.prosocGreen),
            )
          : _catalogError != null
              ? _buildCatalogError()
              : Column(
                  children: [
                    _buildStepIndicator(isDark),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildIdentityStep(isDark),
                          _buildAdhesionStep(isDark),
                          _buildDocumentsStep(isDark),
                          _buildPaymentStep(isDark),
                        ],
                      ),
                    ),
                    _buildBottomBar(isDark),
                  ],
                ),
    );
  }

  Widget _buildCatalogError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.errorColor),
            const SizedBox(height: 16),
            Text(
              _catalogError!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loadCatalogs,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.prosocGreen,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: List.generate(_steps.length, (index) {
          final active = index <= _currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 4,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.prosocGreen
                          : (isDark ? Colors.white24 : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                if (index < _steps.length - 1) const SizedBox(width: 6),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildIdentityStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _identityFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle('Identité', isDark),
            _textField(_nomController, 'Nom *', validator: _required),
            const SizedBox(height: 12),
            _textField(_prenomController, 'Prénom *', validator: _required),
            const SizedBox(height: 12),
            _textField(_postnomController, 'Post-nom *', validator: _required),
            const SizedBox(height: 12),
            ProsocDateField(
              controller: _dateNController,
              label: 'Date de naissance *',
              isRequired: true,
              initialDateFallback: DateTime(1990),
            ),
            const SizedBox(height: 12),
            _textField(
              _telephoneController,
              'Téléphone *',
              keyboardType: TextInputType.phone,
              validator: _required,
            ),
            const SizedBox(height: 12),
            _textField(
              _emailController,
              'E-mail (optionnel)',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            _sectionTitle('Adresse', isDark),
            _textField(
              _provinceController,
              'Province de résidence *',
              validator: _required,
            ),
            const SizedBox(height: 12),
            _textField(_communeController, 'Commune (optionnel)'),
          ],
        ),
      ),
    );
  }

  Widget _buildAdhesionStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Type d\'adhésion', isDark),
          DropdownButtonFormField<TypeAdhesion>(
            value: _selectedType,
            decoration: _inputDecoration('Type d\'adhésion'),
            items: _typeAdhesions
                .map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.libelle),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _selectedType = v),
          ),
          const SizedBox(height: 16),
          _sectionTitle('Frais d\'adhésion', isDark),
          DropdownButtonFormField<Frais>(
            value: _selectedFrais,
            decoration: _inputDecoration('Frais'),
            items: _fraisAdhesion
                .map(
                  (f) => DropdownMenuItem(
                    value: f,
                    child: Text('${f.libelle} — ${f.montant}'),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _selectedFrais = v),
          ),
          const SizedBox(height: 16),
          _sectionTitle('Prestation / cotisation', isDark),
          DropdownButtonFormField<Prestation>(
            value: _selectedPrestation,
            decoration: _inputDecoration('Prestation'),
            items: _prestations
                .map(
                  (p) => DropdownMenuItem(
                    value: p,
                    child: Text(p.nomPrestation),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _selectedPrestation = v),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Pièces jointes (optionnel)', isDark),
          const SizedBox(height: 8),
          Text(
            'Photo et carte d\'identité — max 1 Mo chacune.',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          _documentTile(
            label: 'Photo affilié',
            value: _photo,
            onPick: () => _pickImage(true),
            onClear: () => setState(() => _photo = null),
          ),
          const SizedBox(height: 12),
          _documentTile(
            label: 'Carte d\'identité',
            value: _carteIdentite,
            onPick: () => _pickImage(false),
            onClear: () => setState(() => _carteIdentite = null),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _paymentFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle('Mode de paiement', isDark),
            ...AffiliePaymentModes.electronicOnly.entries.map(
              (entry) => RadioListTile<String>(
                value: entry.key,
                groupValue: _selectedModePaiement,
                activeColor: AppColors.prosocGreen,
                title: Text(entry.value),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedModePaiement = v);
                },
              ),
            ),
            if (_devises.length > 1) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<Devise>(
                value: _selectedDevise,
                decoration: _inputDecoration('Devise de paiement'),
                items: _devises
                    .map(
                      (d) => DropdownMenuItem(
                        value: d,
                        child: Text(d.code),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedDevise = v),
              ),
            ],
            if (_isMobileMoney) ...[
              const SizedBox(height: 16),
              _textField(
                _telephonePaiementController,
                'Téléphone Mobile Money *',
                keyboardType: TextInputType.phone,
                validator: _required,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _documentTile({
    required String label,
    required PickedImageData? value,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(
          value != null ? Icons.check_circle : Icons.add_a_photo_outlined,
          color: AppColors.prosocGreen,
        ),
        title: Text(label),
        subtitle: Text(value != null ? 'Fichier joint' : 'Non fourni'),
        trailing: value != null
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClear,
              )
            : null,
        onTap: onPick,
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Row(
          children: [
            if (_currentStep > 0)
              OutlinedButton(
                onPressed: _isSubmitting ? null : _previousStep,
                child: const Text('Retour'),
              ),
            const Spacer(),
            FilledButton(
              onPressed: _isSubmitting
                  ? null
                  : (_currentStep < _steps.length - 1 ? _nextStep : _submit),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.prosocGreen,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _currentStep < _steps.length - 1 ? 'Suivant' : 'Payer',
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.prosocGreen, width: 2),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label),
      validator: validator,
      keyboardType: keyboardType,
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Champ obligatoire';
    return null;
  }
}
