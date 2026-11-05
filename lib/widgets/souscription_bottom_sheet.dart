import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prosoc/config/api.dart';
import 'package:prosoc/config/colors.dart';
import 'package:prosoc/models/adhesion_with_affilie_model.dart';
import 'package:prosoc/models/prestation_model.dart';
import 'package:prosoc/models/souscription_prestation_model.dart';
import 'package:prosoc/models/collecte_receipt_data.dart';
import 'package:prosoc/offline/offline_mode.dart';
import 'package:prosoc/offline/offline_write_gateway.dart';
import 'package:prosoc/utils/affilie_payment_modes.dart';
import 'package:prosoc/utils/api_error_helper.dart';
import 'package:prosoc/utils/collecte_agent_resolver.dart';
import 'package:prosoc/utils/collecte_montant_helper.dart';
import 'package:prosoc/utils/collecte_receipt_helper.dart';
import 'package:prosoc/utils/currency_formatter.dart';
import 'package:prosoc/utils/electronic_payment_error_handler.dart';
import 'package:prosoc/utils/phone_utils.dart';
import 'package:prosoc/views/screens/at/flex_pay_payment_waiting_screen.dart';
import 'package:prosoc/views/screens/at/payment_webview_screen.dart';
import 'package:prosoc/views/widgets/flex_pay_card_payment_bottom_sheet.dart';
import 'package:prosoc/views/widgets/devise_paiement_selector.dart';
import 'package:prosoc/views/widgets/flex_pay_payment_error_dialog.dart';
import 'package:prosoc/views/widgets/prosoc_message_dialog.dart';

/// Formulaire de souscription — POST /api/SouscriptionPrestation
/// (cash) ou POST /api/SouscriptionPrestation/paiement-electronique (MM/Carte).
class SouscriptionBottomSheet extends StatefulWidget {
  final int affilieId;
  final String affilieNom;
  final String affiliePrenom;
  final String? affilieTelephone;
  /// Adhérent : Mobile Money / Carte uniquement. Agent/percepteur : inclut compte virtuel.
  final bool allowVirtualAccount;

  const SouscriptionBottomSheet({
    super.key,
    required this.affilieId,
    required this.affilieNom,
    required this.affiliePrenom,
    this.affilieTelephone,
    this.allowVirtualAccount = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    required int affilieId,
    String affilieNom = '',
    String affiliePrenom = '',
    String? affilieTelephone,
    bool allowVirtualAccount = false,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SouscriptionBottomSheet(
          affilieId: affilieId,
          affilieNom: affilieNom,
          affiliePrenom: affiliePrenom,
          affilieTelephone: affilieTelephone,
          allowVirtualAccount: allowVirtualAccount,
        ),
      ),
    );
  }

  @override
  State<SouscriptionBottomSheet> createState() => _SouscriptionBottomSheetState();
}

class _SouscriptionBottomSheetState extends State<SouscriptionBottomSheet>
    with OfflineAwareState<SouscriptionBottomSheet> {
  Map<String, String> get _modesPaiement => OfflineMode.modesDisponibles(
    allowVirtualAccount: widget.allowVirtualAccount,
    offline: isOffline,
  );

  final _formKey = GlobalKey<FormState>();
  final _montantController = TextEditingController();
  final _observationController = TextEditingController();
  final _telephonePaiementController = TextEditingController();

  List<Prestation> _prestations = [];
  bool _isLoadingPrestations = false;
  bool _isSubmitting = false;
  Prestation? _selectedPrestation;
  int? _agentId;
  String? _selectedModePaiement;
  double? _montantAttendu;
  /// Devise de paiement Mobile Money et conversion depuis la devise du tarif.
  late final DevisePaiementController _devisePaiement;

  bool get _isMobileMoneyPayment =>
      AffiliePaymentModes.isMobileMoney(_selectedModePaiement);

  bool get _isElectronicPayment =>
      AffiliePaymentModes.isElectronic(_selectedModePaiement);

  @override
  void initState() {
    super.initState();
    _selectedModePaiement = OfflineMode.modeParDefaut(
      allowVirtualAccount: widget.allowVirtualAccount,
      offline: isOffline,
    );
    final tel = widget.affilieTelephone?.trim();
    if (tel != null && tel.isNotEmpty) {
      _telephonePaiementController.text = tel;
    }
    _devisePaiement = DevisePaiementController(
      operation: () => (
        deviseId: _selectedPrestation?.deviseId,
        montant: double.tryParse(
          _montantController.text.trim().replaceAll(',', '.'),
        ),
      ),
      triggers: _montantController,
    )..loadDevises();
    _loadAgentId();
    _loadPrestations();
  }

  @override
  void dispose() {
    _devisePaiement.dispose();
    _montantController.dispose();
    _observationController.dispose();
    _telephonePaiementController.dispose();
    super.dispose();
  }

  @override
  void onOfflineChanged(bool offline) {
    setState(() {
      _selectedModePaiement = offline || _selectedModePaiement == null
          ? OfflineMode.modeParDefaut(
              allowVirtualAccount: widget.allowVirtualAccount,
              offline: offline,
            )
          : _selectedModePaiement;
    });
    if (!offline) {
      _devisePaiement.loadDevises();
      if (_prestations.isEmpty) _loadPrestations();
    }
  }

  Future<void> _loadAgentId() async {
    final resolved = await CollecteAgentResolver.resolveForAffilie(
      widget.affilieId,
    );
    if (!mounted) return;
    setState(() => _agentId = resolved);
  }

  void _appliquerPrestationsLocales() {
    setState(() {
      _prestations = OfflineMode.prestationsLocales();
      _isLoadingPrestations = false;
    });
  }

  Future<void> _loadPrestations() async {
    if (isOffline) {
      _appliquerPrestationsLocales();
      return;
    }
    setState(() => _isLoadingPrestations = true);

    try {
      final response = await ApiService.getPrestations(pageSize: 100);
      if (!mounted) return;

      if (response.success && response.data != null) {
        final data = response.data!;
        final rows = data['data'] as List<dynamic>? ?? [];
        setState(() {
          _prestations = rows
              .whereType<Map<String, dynamic>>()
              .map(Prestation.fromJson)
              .where((p) => p.id > 0)
              .toList();
          _isLoadingPrestations = false;
        });
      } else if (OfflineMode.sansReseau(
        success: response.success,
        statusCode: response.statusCode,
      )) {
        _appliquerPrestationsLocales();
      } else {
        setState(() => _isLoadingPrestations = false);
        await _showError(
          response.message ?? 'Impossible de charger les prestations.',
          statusCode: response.statusCode,
        );
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException(
        'SouscriptionBottomSheet/prestations',
        e,
        stackTrace,
      );
      if (!mounted) return;
      _appliquerPrestationsLocales();
      if (_prestations.isEmpty) {
        await _showError(ApiErrorHelper.userFacingNetwork());
      }
    }
  }

  double? _resolveMontant(Prestation prestation) {
    if (prestation.isGratuit) return 0;
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

  void _applyPrestationSelection(Prestation? prestation) {
    if (prestation == null) {
      setState(() {
        _selectedPrestation = null;
        _montantAttendu = null;
        _montantController.clear();
      });
      return;
    }

    final montant = _resolveMontant(prestation);
    setState(() {
      _selectedPrestation = prestation;
      _montantAttendu = montant;
      if (prestation.isGratuit) {
        _montantController.text = '0';
      } else {
        _montantController.text =
            montant != null && montant > 0 ? montant.toString() : '';
      }
    });
  }

  String _formatMontant(Prestation prestation) {
    if (prestation.isGratuit) return 'Gratuit';
    final montant = _resolveMontant(prestation);
    if (montant == null) return '—';
    return CurrencyFormatter.format(
      amount: montant,
      deviseId: prestation.deviseId,
      deviseCode: prestation.resolveDeviseCode(),
    );
  }

  String _referencePaiementElectronique(DateTime now) {
    return 'SOUSC-ELEC-${now.millisecondsSinceEpoch}';
  }

  Future<void> _submitSouscription() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPrestation == null) {
      await _showError('Veuillez sélectionner une prestation.');
      return;
    }

    if (_agentId == null) {
      await _loadAgentId();
    }
    final agentId = _agentId;
    if (agentId == null || agentId <= 0) {
      await _showError(
        'Agent territorial introuvable pour cet affilié. Contactez votre agent.',
      );
      return;
    }

    if (_isMobileMoneyPayment &&
        !PhoneUtils.isValidDrcPhone(_telephonePaiementController.text)) {
      await _showError(PhoneUtils.invalidFormatMessage);
      return;
    }

    final montantRecu = double.tryParse(
      _montantController.text.trim().replaceAll(',', '.'),
    );
    final montantAttendu = _montantAttendu ?? montantRecu;
    if (_selectedPrestation?.isGratuit != true) {
      final montantError = CollecteMontantHelper.validatePartialPayment(
        montantRecu: montantRecu ?? 0,
        montantAttendu: montantAttendu != null && montantAttendu > 0
            ? montantAttendu
            : null,
      );
      if (montantError != null) {
        await _showError(montantError);
        return;
      }
    } else if (montantRecu == null || montantRecu < 0) {
      await _showError('Montant invalide');
      return;
    }

    final prestation = _selectedPrestation!;
    final deviseId = prestation.deviseId;
    if (deviseId <= 0) {
      await _showError('Devise de la prestation introuvable.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      final modePaiement = _selectedModePaiement!;
      final statutPaiement = _isElectronicPayment ? 'EN_ATTENTE' : 'OK';
      // Paiement dans une autre devise : la collecte porte la devise et le
      // montant converti ; le serveur vérifie l'égalité avec le tarif.
      final paiement = await _devisePaiement.resolve(
        enabled: _isMobileMoneyPayment,
      );
      if (!mounted) return;
      if (!paiement.isReady) {
        await _showError(paiement.blockingMessage!);
        return;
      }
      final collecteDeviseId = paiement.deviseId!;
      final converti = collecteDeviseId != deviseId;
      final montantPaye = converti ? paiement.montant! : montantRecu!;
      final attendu = converti ? montantPaye : (montantAttendu ?? montantPaye);

      final observation = _observationController.text.trim().isNotEmpty
          ? _observationController.text.trim()
          : 'Souscription ${prestation.nomPrestation} — '
              '${widget.affiliePrenom} ${widget.affilieNom}';

      final request = SouscriptionPrestationCreateRequest(
        prestationId: prestation.id,
        dateSouscription: now,
        statut: true,
        collecte: SouscriptionPrestationCollecteRequest(
          agentId: agentId,
          montant: montantPaye,
          mois: now.month,
          annee: now.year,
          deviseId: collecteDeviseId,
          modePaiement: modePaiement,
          montantRecu: montantPaye,
          montantAttendu: attendu,
          statutPaiement: statutPaiement,
          referencePaiement: _isElectronicPayment
              ? _referencePaiementElectronique(now)
              : null,
          observation: observation,
        ),
      );

      if (_isElectronicPayment) {
        final telephonePaiement = _isMobileMoneyPayment
            ? PhoneUtils.normalizeDrcPhone(_telephonePaiementController.text)!
            : PhoneUtils.normalizeDrcPhone(widget.affilieTelephone) ??
                PhoneUtils.normalizeDrcPhone(
                  _telephonePaiementController.text,
                ) ??
                '';

        if (telephonePaiement.isEmpty) {
          await _showError(PhoneUtils.invalidFormatMessage);
          return;
        }

        final flexResponse =
            await ApiService.createSouscriptionPrestationPaiementElectronique(
          SouscriptionPrestationPaiementElectroniqueRequest(
            affilieId: widget.affilieId,
            modePaiement: modePaiement,
            telephonePaiement: telephonePaiement,
            devisePaiementId: collecteDeviseId,
            achat: request,
          ),
        );

        if (!mounted) return;

        if (flexResponse.success && flexResponse.data != null) {
          await _handleFlexPayResponse(flexResponse.data!);
        } else {
          await ElectronicPaymentErrorHandler.show(
            context,
            flexResponse,
            onChooseOtherMode: () {
              if (!mounted) return;
              setState(() => _selectedModePaiement = null);
            },
          );
        }
        return;
      }

      final outcome = await OfflineWriteGateway.souscriptionPrestation(
        affilieId: widget.affilieId,
        agentId: agentId,
        prestationId: prestation.id,
        montant: montantPaye,
        deviseId: collecteDeviseId,
        mois: now.month,
        annee: now.year,
        referencePaiement: 'SOUSC-VA-${now.millisecondsSinceEpoch}',
        request: request,
        label: 'Souscription ${widget.affiliePrenom}',
      );

      if (!mounted) return;

      if (outcome is OfflineQueued) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context, true);
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Souscription enregistrée hors ligne. Elle sera confirmée à la '
              'synchronisation, dès le retour du réseau.',
            ),
            backgroundColor: Color(0xFFF59E0B),
          ),
        );
        return;
      }

      if (outcome is OfflineSynced) {
        final montant = double.tryParse(_montantController.text.trim()) ?? 0;
        await CollecteReceiptHelper.open(
          context,
          receipt: CollecteReceiptData(
            operation: CollecteReceiptOperation.souscription,
            montant: montant,
            deviseId: _selectedPrestation?.deviseId,
            modePaiement: _selectedModePaiement,
            affilieNom: '${widget.affiliePrenom} ${widget.affilieNom}'.trim(),
            statutPaiement: 'OK',
            extras: {
              if (_selectedPrestation != null)
                'Prestation': _selectedPrestation!.nomPrestation,
            },
          ),
          popResult: true,
        );
        if (mounted) Navigator.pop(context, true);
      } else if (outcome is OfflineFailed) {
        await _showError(outcome.message, statusCode: outcome.statusCode);
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException(
        'SouscriptionBottomSheet/submit',
        e,
        stackTrace,
      );
      if (!mounted) return;
      await _showError(ApiErrorHelper.userFacingNetwork());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
      setState(() => _isSubmitting = false);
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => FlexPayPaymentWaitingScreen(
            payment: payment,
            isMobileMoney: _isMobileMoneyPayment,
            receiptOperation: CollecteReceiptOperation.souscription,
            affilieNom: '${widget.affiliePrenom} ${widget.affilieNom}'.trim(),
            modePaiement: _selectedModePaiement,
          ),
        ),
      );
      if (result == true && mounted) {
        Navigator.pop(context, true);
      }
      return;
    }

    if (payment.flexPayAccepted && _hasFlexPayPaymentUrl(payment)) {
      setState(() => _isSubmitting = false);
      await _showFlexPayCardPaymentBottomSheet(payment);
      return;
    }

    setState(() => _isSubmitting = false);
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
              receiptOperation: CollecteReceiptOperation.souscription,
              affilieNom: '${widget.affiliePrenom} ${widget.affilieNom}'.trim(),
              modePaiement: _selectedModePaiement,
            ),
          ),
        );
        if (result == true && mounted) {
          Navigator.pop(context, true);
        }
      },
    );
  }

  Future<void> _showError(String message, {int? statusCode}) {
    return ProsocMessageDialog.show(
      context,
      variant: ProsocMessageVariant.error,
      title: 'Souscription impossible',
      message: message,
      statusCode: statusCode,
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.prosocGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.library_add_rounded,
                    color: AppColors.prosocGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Souscrire à une prestation',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${widget.affiliePrenom} ${widget.affilieNom}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Prestation *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _isLoadingPrestations
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.prosocGreen,
                              ),
                            ),
                          )
                        : DropdownButtonFormField<Prestation>(
                            value: _selectedPrestation,
                            decoration: _inputDecoration(
                              'Sélectionner une prestation',
                            ),
                            items: _prestations.map((prestation) {
                              return DropdownMenuItem<Prestation>(
                                value: prestation,
                                child: Text(
                                  '${prestation.nomPrestation} — '
                                  '${_formatMontant(prestation)}',
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: _applyPrestationSelection,
                            validator: (v) =>
                                v == null ? 'Prestation requise' : null,
                          ),
                    if (_selectedPrestation != null) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _montantController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.,]'),
                          ),
                        ],
                        decoration: _inputDecoration(
                          CollecteMontantHelper.montantFieldHint(
                            montantAttendu: _montantAttendu,
                          ),
                        ),
                        validator: (value) {
                          final parsed = double.tryParse(
                            (value ?? '').trim().replaceAll(',', '.'),
                          );
                          if (_selectedPrestation?.isGratuit == true) {
                            if (parsed == null || parsed < 0) {
                              return 'Montant invalide';
                            }
                            return null;
                          }
                          if (parsed == null || parsed <= 0) {
                            return 'Montant invalide';
                          }
                          return null;
                        },
                      ),
                      if (CollecteMontantHelper.montantAttenduLibelle(
                            montantAttendu: _montantAttendu,
                          ) !=
                          null) ...[
                        const SizedBox(height: 6),
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
                    const SizedBox(height: 16),
                    const Text(
                      'Mode de paiement *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_modesPaiement.isEmpty)
                      const Text('Le paiement nécessite une connexion internet.')
                    else
                    DropdownButtonFormField<String>(
                      value: _selectedModePaiement,
                      decoration: _inputDecoration('Choisir un mode'),
                      items: _modesPaiement.entries
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedModePaiement = value);
                      },
                    ),
                    if (_isMobileMoneyPayment) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _telephonePaiementController,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration('Téléphone Mobile Money'),
                        validator: (value) {
                          if (!_isMobileMoneyPayment) return null;
                          if (!PhoneUtils.isValidDrcPhone(value ?? '')) {
                            return PhoneUtils.invalidFormatMessage;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DevisePaiementSelector(
                        controller: _devisePaiement,
                        decoration: _inputDecoration('Devise de paiement'),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _observationController,
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _inputDecoration(
                        'Observation (optionnel)',
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitSouscription,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.prosocGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('En cours...'),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline),
                                  SizedBox(width: 8),
                                  Text('Confirmer la souscription'),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
