import 'package:flutter/material.dart';
import '../../../config/api.dart';
import '../../../config/colors.dart';
import '../../../services/auth_service.dart';
import '../../../utils/api_error_helper.dart';
import '../../../utils/withdrawal_window_helper.dart';

class WithdrawalScreen extends StatefulWidget {
  final double? soldeDisponible;

  const WithdrawalScreen({super.key, this.soldeDisponible});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montantController = TextEditingController();
  final _motifController = TextEditingController();

  String _selectedTypeRetrait = 'Espèces';
  bool _isLoading = false;
  String? _serverMessage;
  bool _isSuccess = false;

  final List<String> _typeRetraitOptions = [
    'Espèces',
    'Virement bancaire',
    'Mobile Money',
  ];

  bool get _windowOpen => WithdrawalWindowHelper.isOpen();

  @override
  void dispose() {
    _montantController.dispose();
    _motifController.dispose();
    super.dispose();
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
        _serverMessage = WithdrawalWindowHelper.statusDescription();
        _isSuccess = false;
      });
      return;
    }

    if (!_formKey.currentState!.validate()) return;

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
      final response = await ApiService.createDemandeRetraitAgent(
        agentId: agentId,
        montant: montant,
        typeRetrait: _selectedTypeRetrait,
        motifRetrait: _motifController.text.trim(),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.soldeDisponible != null) _buildBalanceCard(),
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
              enabled: _windowOpen && !_isLoading,
              decoration: _fieldDecoration(
                label: 'Montant demandé (CDF)',
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
                final solde = widget.soldeDisponible;
                if (solde != null && montant > solde) {
                  return 'Montant supérieur au solde disponible';
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
              onChanged: _windowOpen && !_isLoading
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
              enabled: _windowOpen && !_isLoading,
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
              onPressed: _windowOpen && !_isLoading ? _submitWithdrawal : null,
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

  Widget _buildBalanceCard() {
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
          const Text(
            'Solde disponible',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.soldeDisponible!.toStringAsFixed(2)} \$',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowBanner() {
    final open = _windowOpen;
    final hint = WithdrawalWindowHelper.nextWindowHint();
    final color = open ? AppColors.prosocGreen : AppColors.warningColor;

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
                  WithdrawalWindowHelper.statusLabel(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  WithdrawalWindowHelper.statusDescription(),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade800,
                    height: 1.35,
                  ),
                ),
                if (hint.isNotEmpty) ...[
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
