import 'package:flutter/material.dart';
import 'package:prosoc/config/api.dart';
import 'package:prosoc/config/colors.dart';
import 'package:prosoc/models/adhesion_with_affilie_model.dart';
import 'package:prosoc/models/prestation_model.dart';
import 'package:prosoc/models/souscription_prestation_model.dart';
import 'package:prosoc/models/wallet_agent_model.dart';
import 'package:prosoc/utils/api_error_helper.dart';
import 'package:prosoc/utils/collecte_agent_resolver.dart';
import 'package:prosoc/utils/collecte_montant_helper.dart';
import 'package:prosoc/utils/phone_utils.dart';
import 'package:prosoc/views/screens/at/flex_pay_payment_waiting_screen.dart';
import 'package:prosoc/views/screens/at/payment_webview_screen.dart';
import 'package:prosoc/views/widgets/flex_pay_card_payment_bottom_sheet.dart';
import 'package:prosoc/views/widgets/flex_pay_payment_error_dialog.dart';

/// Paiement d'une souscription prestation (`typeCollecte = Souscription`).
class PayerSouscriptionScreen extends StatefulWidget {
  final int affilieId;
  final String affilieNom;
  final String affiliePrenom;
  final String? affilieTelephone;
  final int? agentId;
  final String screenTitle;

  const PayerSouscriptionScreen({
    super.key,
    required this.affilieId,
    required this.affilieNom,
    required this.affiliePrenom,
    this.affilieTelephone,
    this.agentId,
    this.screenTitle = 'Payer une souscription',
  });

  @override
  State<PayerSouscriptionScreen> createState() =>
      _PayerSouscriptionScreenState();
}

class _PayerSouscriptionScreenState extends State<PayerSouscriptionScreen> {
  static const Map<String, String> _modesPaiement = {
    'VIRTUAL_ACCOUNT': 'Compte virtuel',
    'MOBILE_MONEY': 'Mobile money',
    'CARTE_BANCAIRE': 'Carte',
  };

  List<SouscriptionPrestationModel> _souscriptions = [];
  Map<int, Prestation> _prestationsById = {};
  bool _isLoadingSouscriptions = false;
  String? _souscriptionsError;

  int? _selectedSouscriptionId;
  String? _selectedModePaiement = 'VIRTUAL_ACCOUNT';
  String? _selectedDevise;
  int? _selectedDeviseId;
  int? _agentId;
  double? _montantAttendu;
  bool _isLoading = false;

  final TextEditingController _montantController = TextEditingController();
  final TextEditingController _observationController = TextEditingController();
  final TextEditingController _telephonePaiementController =
      TextEditingController();

  bool get _isMobileMoneyPayment => _selectedModePaiement == 'MOBILE_MONEY';

  bool get _isElectronicPayment =>
      _selectedModePaiement == 'MOBILE_MONEY' ||
      _selectedModePaiement == 'CARTE_BANCAIRE';

  @override
  void initState() {
    super.initState();
    final tel = widget.affilieTelephone?.trim();
    if (tel != null && tel.isNotEmpty) {
      _telephonePaiementController.text = tel;
    }
    _loadAgentId();
    _loadData();
  }

  @override
  void dispose() {
    _montantController.dispose();
    _observationController.dispose();
    _telephonePaiementController.dispose();
    super.dispose();
  }

  SouscriptionPrestationModel? get _selectedSouscription {
    final id = _selectedSouscriptionId;
    if (id == null) return null;
    for (final item in _souscriptions) {
      if (item.id == id) return item;
    }
    return null;
  }

  Prestation? _prestationFor(SouscriptionPrestationModel souscription) {
    return _prestationsById[souscription.prestationId];
  }

  Future<void> _loadAgentId() async {
    final resolved = await CollecteAgentResolver.resolveForAffilie(
      widget.affilieId,
      explicitAgentId: widget.agentId,
    );
    if (!mounted) return;
    setState(() => _agentId = resolved);
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingSouscriptions = true;
      _souscriptionsError = null;
    });

    try {
      final results = await Future.wait([
        ApiService.getSouscriptionsPrestationByAffilie(widget.affilieId),
        ApiService.getPrestations(pageSize: 100),
      ]);
      if (!mounted) return;

      final souscriptionsResponse =
          results[0] as ApiResponse<List<SouscriptionPrestationModel>>;
      final prestationsResponse =
          results[1] as ApiResponse<Map<String, dynamic>>;

      final prestationsMap = <int, Prestation>{};
      if (prestationsResponse.success && prestationsResponse.data != null) {
        final rows = prestationsResponse.data!['data'] as List<dynamic>? ?? [];
        for (final item in rows) {
          if (item is! Map) continue;
          final prestation = Prestation.fromJson(
            Map<String, dynamic>.from(item),
          );
          if (prestation.id > 0) {
            prestationsMap[prestation.id] = prestation;
          }
        }
      }

      if (souscriptionsResponse.success && souscriptionsResponse.data != null) {
        final actives =
            souscriptionsResponse.data!
                .where((s) => s.statut && s.prestationId > 0)
                .toList()
              ..sort((a, b) => a.prestationNom.compareTo(b.prestationNom));

        setState(() {
          _prestationsById = prestationsMap;
          _souscriptions = actives;
          _isLoadingSouscriptions = false;
        });

        if (actives.length == 1) {
          _applySouscriptionSelection(actives.first.id);
        }
      } else {
        setState(() {
          _souscriptionsError =
              souscriptionsResponse.message ??
              ApiErrorHelper.userFacingMessage(
                statusCode: souscriptionsResponse.statusCode,
              );
          _isLoadingSouscriptions = false;
        });
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException(
        'PayerSouscription/load',
        e,
        stackTrace,
        false,
      );
      if (!mounted) return;
      setState(() {
        _souscriptionsError = ApiErrorHelper.userFacingNetwork();
        _isLoadingSouscriptions = false;
      });
    }
  }

  double? _resolveMontantFromDescription(String description) {
    final match = RegExp(
      r'Montant:\s*(\d+(?:[.,]\d+)?)',
      caseSensitive: false,
    ).firstMatch(description);
    if (match == null) return null;
    return double.tryParse(match.group(1)!.replaceAll(',', '.'));
  }

  double? _resolveMontantForSouscription(
    SouscriptionPrestationModel souscription,
  ) {
    final prestation = _prestationFor(souscription);
    if (prestation != null) {
      final montant = _resolveMontant(prestation);
      if (montant != null && montant > 0) return montant;
    }
    return _resolveMontantFromDescription(souscription.prestationDescription);
  }

  int? _resolveDeviseIdForSouscription(
    SouscriptionPrestationModel souscription,
  ) {
    final prestation = _prestationFor(souscription);
    if (prestation != null && prestation.deviseId > 0) {
      return prestation.deviseId;
    }
    return WalletAgentDeviseIds.cdf;
  }

  String? _resolveDeviseCodeForSouscription(
    SouscriptionPrestationModel souscription,
  ) {
    final prestation = _prestationFor(souscription);
    final code = prestation?.resolveDeviseCode();
    if (code != null && code.isNotEmpty) return code;
    final deviseId = _resolveDeviseIdForSouscription(souscription);
    return WalletAgentDeviseIds.labelForId(
      deviseId ?? WalletAgentDeviseIds.cdf,
    );
  }

  void _applySouscriptionSelection(int souscriptionId) {
    final souscription = _souscriptions.firstWhere(
      (s) => s.id == souscriptionId,
      orElse: () => _souscriptions.first,
    );
    final montant = _resolveMontantForSouscription(souscription);
    final deviseCode = _resolveDeviseCodeForSouscription(souscription);
    final deviseId = _resolveDeviseIdForSouscription(souscription);

    setState(() {
      _selectedSouscriptionId = souscription.id;
      _selectedDevise = deviseCode;
      _selectedDeviseId = deviseId;
      _montantAttendu = montant;
      if (montant != null && montant > 0) {
        _montantController.text = montant.toString();
      } else {
        _montantController.clear();
      }
    });
  }

  String _souscriptionLabel(SouscriptionPrestationModel souscription) {
    final montant = _resolveMontantForSouscription(souscription);
    final devise = _resolveDeviseCodeForSouscription(souscription) ?? '';
    final montantLabel = montant != null
        ? ' — $montant${devise.isNotEmpty ? ' $devise' : ''}'
        : '';
    return '${souscription.prestationNom}$montantLabel';
  }

  double? _resolveMontant(Prestation prestation) {
    final montant = prestation.resolveMontant();
    if (montant != null && montant > 0) return montant;

    final priceRegex = RegExp(
      r'Prix:\s*(\d+(?:[.,]\d+)?)\s*FCFA',
      caseSensitive: false,
    );
    final match = priceRegex.firstMatch(prestation.description);
    if (match != null) {
      return double.tryParse(match.group(1)!.replaceAll(',', '.'));
    }
    return null;
  }

  String _deviseDisplayLabel() {
    if (_selectedDevise == null || _selectedDevise!.isEmpty) return '—';
    return _selectedDevise!.toUpperCase();
  }

  String _referencePaiementElectronique(DateTime now) {
    return 'SOUS-ELEC-${now.millisecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
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
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
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
          const Icon(
            Icons.medical_services_outlined,
            color: AppColors.prosocGreen,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name.isNotEmpty ? name : 'Affilié #${widget.affilieId}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        _buildFormField(
          label: 'Souscription',
          icon: Icons.library_books_outlined,
          required: true,
          child: _isLoadingSouscriptions
              ? const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _souscriptionsError != null
              ? Text(
                  _souscriptionsError!,
                  style: TextStyle(fontSize: 14, color: Colors.red.shade700),
                )
              : _souscriptions.isEmpty
              ? Text(
                  'Aucune souscription active. Souscrivez d\'abord à une prestation.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                )
              : DropdownButtonFormField<int?>(
                  initialValue: _selectedSouscriptionId,
                  decoration: _inputDecoration('Sélectionner une souscription'),
                  items: _souscriptions.map((souscription) {
                    return DropdownMenuItem<int?>(
                      value: souscription.id,
                      child: Text(
                        _souscriptionLabel(souscription),
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    _applySouscriptionSelection(value);
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
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildFormField(
          label: 'Devise',
          icon: Icons.attach_money,
          required: true,
          child: InputDecorator(
            decoration: _inputDecoration(
              _selectedSouscriptionId == null
                  ? 'Choisir une souscription'
                  : 'Devise de la prestation',
            ).copyWith(filled: true, fillColor: Colors.grey.shade50),
            child: Text(
              _deviseDisplayLabel(),
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
        onPressed: _isLoading || _souscriptions.isEmpty ? null : _submitPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.prosocGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Row(
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
    required int souscriptionPrestationId,
    required String referencePaiement,
    required int deviseId,
    required String modePaiement,
    required String statutPaiement,
    required DateTime now,
  }) {
    final observation = _observationController.text.trim();
    return {
      'typeCollecte': 'Souscription',
      'souscriptionPrestationId': souscriptionPrestationId,
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

  Future<void> _submitPayment() async {
    final souscription = _selectedSouscription;
    if (souscription == null ||
        _selectedDeviseId == null ||
        _montantController.text.isEmpty ||
        _selectedModePaiement == null) {
      _showErrorSnackBar('Veuillez remplir tous les champs obligatoires');
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

    final montantRecu = double.tryParse(_montantController.text);
    final montantAttendu = _montantAttendu ?? montantRecu ?? 0;
    final montantError = CollecteMontantHelper.validatePartialPayment(
      montantRecu: montantRecu ?? 0,
      montantAttendu: montantAttendu > 0 ? montantAttendu : null,
    );
    if (montantError != null) {
      _showErrorSnackBar(montantError);
      return;
    }

    final montantPaye = montantRecu!;

    final souscriptionPrestationId = souscription.id;
    if (souscriptionPrestationId <= 0) {
      _showErrorSnackBar('Souscription sélectionnée invalide');
      return;
    }

    final deviseId = _selectedDeviseId!;
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
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
          souscriptionPrestationId: souscriptionPrestationId,
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
        typeCollecte: 'Souscription',
        affilieId: widget.affilieId,
        agentId: collecteAgentId,
        souscriptionPrestationId: souscriptionPrestationId,
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
        _showSuccessSnackBar('Paiement de souscription enregistré avec succès');
        Navigator.pop(context, true);
      } else {
        await FlexPayPaymentErrorDialog.show(
          context,
          message: response.message,
          statusCode: response.statusCode,
        );
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('PayerSouscription/submit', e, stackTrace);
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

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.prosocGreen),
    );
  }
}
