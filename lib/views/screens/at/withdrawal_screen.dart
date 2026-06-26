import 'package:flutter/material.dart';

import '../../../config/api.dart';
import '../../../config/colors.dart';
import '../../../models/retrait_agent_periode_model.dart';
import '../../../models/wallet_agent_model.dart';
import '../../../services/auth_service.dart';
import '../../../utils/api_error_helper.dart';
import '../../../utils/wallet_agent_loader.dart';
import '../../../utils/withdrawal_window_helper.dart';
import '../../widgets/wallet_devise_switch.dart';
import 'retrait_historique_screen.dart';

class WithdrawalScreen extends StatefulWidget {
  final int? initialDeviseId;
  final Map<int, WalletAgentModel>? initialWalletsByDevise;

  const WithdrawalScreen({
    super.key,
    this.initialDeviseId,
    this.initialWalletsByDevise,
  });

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montantController = TextEditingController();
  final _motifController = TextEditingController();
  final _pageController = PageController();

  String _selectedTypeRetrait = 'Espèces';
  bool _isLoading = false;
  bool _isLoadingWallets = true;
  bool _isLoadingPeriode = true;
  String? _serverMessage;
  bool _isSuccess = false;

  RetraitAgentPeriodeCourante? _periodeCourante;

  Set<int> _availableDeviseIds = {};
  Map<int, WalletAgentModel> _walletsByDevise = {};
  int? _selectedDeviseId;
  bool _isUsdSelected = false;

  final List<String> _typeRetraitOptions = [
    'Espèces',
    'Virement bancaire',
    'Mobile Money',
  ];

  bool get _windowOpen =>
      _periodeCourante?.estPeriodeAutorisee ?? WithdrawalWindowHelper.isOpen();

  bool get _isRetraitTotal => _periodeCourante?.isRetraitTotal ?? false;

  List<int> get _orderedDeviseIds {
    final ids = _availableDeviseIds.toList();
    ids.sort();
    return ids;
  }

  WalletAgentModel? get _selectedWallet {
    final id = _selectedDeviseId;
    if (id == null) return null;
    return _walletsByDevise[id];
  }

  @override
  void initState() {
    super.initState();
    _walletsByDevise = Map<int, WalletAgentModel>.from(
      widget.initialWalletsByDevise ?? {},
    );
    _availableDeviseIds = _walletsByDevise.keys.toSet();
    _selectedDeviseId = widget.initialDeviseId;
    if (_selectedDeviseId != null) {
      _isUsdSelected = WalletAgentLoader.isUsdDeviseId(_selectedDeviseId!);
    }
    _loadInitialData();
  }

  @override
  void dispose() {
    _montantController.dispose();
    _motifController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadWallets(),
      _loadPeriodeCourante(),
    ]);
  }

  Future<void> _loadPeriodeCourante() async {
    setState(() => _isLoadingPeriode = true);

    try {
      final response = await ApiService.getRetraitAgentPeriodeCourante();
      if (!mounted) return;

      setState(() {
        if (response.success && response.data != null) {
          _periodeCourante = response.data;
        }
        _isLoadingPeriode = false;
      });
      _syncMontantForRetraitType();
    } catch (e, stackTrace) {
      ApiErrorHelper.logException(
        'WithdrawalScreen/periode',
        e,
        stackTrace,
        false,
      );
      if (!mounted) return;
      setState(() => _isLoadingPeriode = false);
    }
  }

  void _syncMontantForRetraitType() {
    if (!_isRetraitTotal) return;
    final wallet = _selectedWallet;
    if (wallet == null || wallet.soldeDisponible <= 0) return;
    _montantController.text = _formatAmountInput(wallet.soldeDisponible);
  }

  String _formatAmountInput(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toStringAsFixed(0);
    }
    return amount.toStringAsFixed(2);
  }

  Future<void> _loadWallets() async {
    final agentId = AuthService.currentUser?.utilisateur.agentId;
    if (agentId == null) {
      setState(() => _isLoadingWallets = false);
      return;
    }

    final result = await WalletAgentLoader.load(
      agentId: agentId,
      preferredDeviseId: _selectedDeviseId,
      cachedWallets: _walletsByDevise.isNotEmpty ? _walletsByDevise : null,
    );

    if (!mounted) return;

    setState(() {
      _walletsByDevise = result.walletsByDevise;
      _availableDeviseIds = result.availableDeviseIds;
      if (result.resolvedDeviseId != null) {
        _selectedDeviseId = result.resolvedDeviseId;
        _isUsdSelected = WalletAgentLoader.isUsdDeviseId(result.resolvedDeviseId!);
      }
      _isLoadingWallets = false;
    });

    _jumpToSelectedDevisePage();
    _syncMontantForRetraitType();
  }

  void _jumpToSelectedDevisePage() {
    final ids = _orderedDeviseIds;
    final selected = _selectedDeviseId;
    if (selected == null || ids.length < 2) return;

    final index = ids.indexOf(selected);
    if (index >= 0 && _pageController.hasClients) {
      _pageController.jumpToPage(index);
    } else if (index >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(index);
        }
      });
    }
  }

  void _onDeviseSwitchChanged(bool isUsd) {
    final targetId =
        isUsd ? WalletAgentDeviseIds.usd : WalletAgentDeviseIds.cdf;
    if (!_availableDeviseIds.contains(targetId)) return;

    setState(() {
      _isUsdSelected = isUsd;
      _selectedDeviseId = targetId;
      _montantController.clear();
    });
    _jumpToSelectedDevisePage();
    _syncMontantForRetraitType();
  }

  void _onWalletPageChanged(int index) {
    final ids = _orderedDeviseIds;
    if (index < 0 || index >= ids.length) return;
    final deviseId = ids[index];
    setState(() {
      _selectedDeviseId = deviseId;
      _isUsdSelected = WalletAgentLoader.isUsdDeviseId(deviseId);
      _montantController.clear();
    });
    _syncMontantForRetraitType();
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.prosocGreen),
      filled: true,
      fillColor: AppColors.cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.prosocGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.errorColor),
      ),
    );
  }

  Future<void> _submitWithdrawal() async {
    if (!_windowOpen) {
      setState(() {
        _serverMessage = _periodeCourante?.message.isNotEmpty == true
            ? _periodeCourante!.message
            : WithdrawalWindowHelper.statusDescription();
        _isSuccess = false;
      });
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final wallet = _selectedWallet;
    if (wallet == null) {
      setState(() {
        _serverMessage = 'Aucun wallet disponible pour cette devise.';
        _isSuccess = false;
      });
      return;
    }

    final agentId = AuthService.currentUser?.utilisateur.agentId;
    if (agentId == null) {
      setState(() {
        _serverMessage = 'Agent non identifié. Reconnectez-vous.';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _serverMessage = null;
      _isSuccess = false;
    });

    try {
      final montant = double.parse(_montantController.text.trim());

      final verif = await ApiService.verifierSoldeRetraitAgent(
        agentId: agentId,
        montantDemande: montant,
        deviseId: wallet.deviseId > 0 ? wallet.deviseId : null,
      );

      if (!mounted) return;

      if (!verif.success || verif.data == null) {
        setState(() {
          _serverMessage =
              verif.message ??
              ApiErrorHelper.userFacingMessage(statusCode: verif.statusCode);
          _isLoading = false;
        });
        return;
      }

      if (!verif.data!.soldeSuffisant) {
        setState(() {
          _serverMessage = verif.data!.message.isNotEmpty
              ? verif.data!.message
              : 'Solde insuffisant pour ce montant.';
          _isLoading = false;
        });
        return;
      }

      final response = await ApiService.createDemandeRetraitAgent(
        agentId: agentId,
        montant: montant,
        typeRetrait: _selectedTypeRetrait,
        motifRetrait: _motifController.text.trim(),
        deviseId: wallet.deviseId > 0 ? wallet.deviseId : null,
      );

      if (!mounted) return;

      if (response.success) {
        setState(() {
          _isSuccess = true;
          _isLoading = false;
          _serverMessage = null;
        });
      } else {
        setState(() {
          _serverMessage =
              response.message ??
              ApiErrorHelper.userFacingMessage(statusCode: response.statusCode);
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('WithdrawalScreen', e, stackTrace, false);
      if (!mounted) return;
      setState(() {
        _serverMessage = ApiErrorHelper.userFacingNetwork();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Demande de retrait',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppColors.textPrimary,
            ),
            tooltip: 'Menu',
            onSelected: (value) {
              if (value == 'historique') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RetraitHistoriqueScreen(),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'historique',
                child: Row(
                  children: [
                    Icon(Icons.history_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Historique des retraits'),
                  ],
                ),
              ),
            ],
          ),
        ],
        elevation: 0,
      ),
      body: _isSuccess ? _buildSuccessView() : _buildFormView(),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.prosocGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.prosocGreen,
                size: 52,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Demande envoyée',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Votre demande de retrait a été enregistrée. '
              'Vous pourrez générer un jeton depuis l\'écran Jeton.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.prosocGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Retour au wallet',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormView() {
    final wallet = _selectedWallet;
    final canWithdraw = _windowOpen &&
        !_isLoading &&
        !_isLoadingPeriode &&
        wallet != null &&
        wallet.soldeDisponible > 0;
    final currencyLabel = wallet?.currencyLabel ?? 'devise';
    final montantReadOnly = _isRetraitTotal;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWalletSwipeSection(),
            const SizedBox(height: 16),
            _buildRetenueInfoBanner(),
            const SizedBox(height: 16),
            _buildWindowBanner(),
            if (_serverMessage != null) ...[
              const SizedBox(height: 16),
              _buildFeedbackBanner(),
            ],
            const SizedBox(height: 24),
            TextFormField(
              controller: _montantController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              enabled: canWithdraw && !montantReadOnly,
              readOnly: montantReadOnly,
              decoration: _fieldDecoration(
                label: montantReadOnly
                    ? 'Montant total ($currencyLabel)'
                    : 'Montant demandé ($currencyLabel)',
                icon: Icons.payments_outlined,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer un montant';
                }
                final montant = double.tryParse(value.trim());
                if (montant == null || montant <= 0) {
                  return 'Montant invalide';
                }
                final solde = wallet?.soldeDisponible;
                if (solde == null || solde <= 0) {
                  return 'Aucun solde disponible pour le retrait';
                }
                if (montant > solde) {
                  return 'Montant supérieur au solde disponible '
                      '(${wallet!.formattedSoldeDisponible})';
                }
                if (_isRetraitTotal && (montant - solde).abs() > 0.009) {
                  return 'Le retrait total du solde disponible est requis';
                }
                final minPartiel = _periodeCourante?.montantMinimumPartiel ?? 0;
                if (!_isRetraitTotal &&
                    minPartiel > 0 &&
                    montant < minPartiel) {
                  return 'Montant minimum : $minPartiel';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedTypeRetrait,
              decoration: _fieldDecoration(
                label: 'Type de retrait',
                icon: Icons.account_balance_wallet_outlined,
              ),
              items: _typeRetraitOptions
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
                  .toList(),
              onChanged: canWithdraw
                  ? (value) {
                      if (value != null) {
                        setState(() => _selectedTypeRetrait = value);
                      }
                    }
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _motifController,
              maxLines: 3,
              enabled: canWithdraw,
              decoration: _fieldDecoration(
                label: 'Motif du retrait',
                icon: Icons.edit_note_outlined,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez indiquer un motif';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: canWithdraw ? _submitWithdrawal : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.prosocGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Soumettre la demande',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletSwipeSection() {
    if (_isLoadingWallets) {
      return const SizedBox(
        height: 170,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.prosocGreen),
        ),
      );
    }

    final ids = _orderedDeviseIds;
    if (ids.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          ApiErrorHelper.walletAgentUnavailableMessage(),
          style: TextStyle(color: Colors.grey.shade700),
        ),
      );
    }

    return Column(
      children: [
        if (ids.length > 1) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Glissez pour changer de devise',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              WalletDeviseSwitch(
                isUsdSelected: _isUsdSelected,
                availableDeviseIds: _availableDeviseIds,
                onChanged: _onDeviseSwitchChanged,
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          height: 170,
          child: ids.length == 1
              ? _buildBalanceCard(_walletsByDevise[ids.first]!)
              : PageView.builder(
                  controller: _pageController,
                  itemCount: ids.length,
                  onPageChanged: _onWalletPageChanged,
                  itemBuilder: (context, index) {
                    final wallet = _walletsByDevise[ids[index]];
                    if (wallet == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _buildBalanceCard(wallet),
                    );
                  },
                ),
        ),
        if (ids.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(ids.length, (index) {
              final selected = ids[index] == _selectedDeviseId;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: selected ? 18 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.prosocGreen
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildBalanceCard(WalletAgentModel wallet) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.prosocGreen.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Solde disponible · ${wallet.currencyLabel}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
              if (wallet.statut)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Actif',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            wallet.formattedSoldeDisponible,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Solde courant : ${wallet.formattedSolde}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetenueInfoBanner() {
    final wallet = _selectedWallet;
    if (wallet == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2196F3).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF2196F3).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF2196F3),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              wallet.hasRetenue
                  ? 'Le retrait est limité au solde disponible. '
                      'Une partie du solde courant est retenue à la source '
                      'pour maintenir votre compte actif.'
                  : 'Seul le solde disponible peut être retiré. '
                      'Votre compte ne peut pas être vidé entièrement.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowBanner() {
    if (_isLoadingPeriode) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.prosocGreen,
              ),
            ),
            SizedBox(width: 12),
            Text('Vérification de la période de retrait…'),
          ],
        ),
      );
    }

    final periode = _periodeCourante;
    final open = _windowOpen;
    final color = open ? AppColors.prosocGreen : AppColors.warningColor;
    final title = periode?.statusLabel ?? WithdrawalWindowHelper.statusLabel();
    final description = periode?.message.isNotEmpty == true
        ? periode!.message
        : WithdrawalWindowHelper.statusDescription();
    final hint = periode == null ? WithdrawalWindowHelper.nextWindowHint() : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            open ? Icons.event_available_rounded : Icons.event_busy_rounded,
            color: color,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade800,
                    height: 1.35,
                  ),
                ),
                if (periode != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    periode.fenetresDescription,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  if (open && periode.activeWindowLabel.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Fenêtre active : ${periode.activeWindowLabel}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    periode.typeRetraitLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ] else if (hint.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    hint,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
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

  Widget _buildFeedbackBanner() {
    final message = _serverMessage!;
    final isWindowError =
        message.contains('retraits ne sont autorisés') ||
        message.contains('retraits sont autorisés') ||
        message.contains('Jour actuel');
    final color = isWindowError ? AppColors.warningColor : AppColors.errorColor;
    final icon = isWindowError
        ? Icons.calendar_month_rounded
        : Icons.error_outline_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isWindowError ? 'Retrait indisponible' : 'Demande refusée',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    height: 1.35,
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
