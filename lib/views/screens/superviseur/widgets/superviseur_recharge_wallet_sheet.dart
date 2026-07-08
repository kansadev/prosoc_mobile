import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/api.dart';
import '../../../../config/colors.dart';
import '../../../../models/wallet_virtuel_agent_model.dart';
import '../../../../utils/api_error_helper.dart';
import '../../../widgets/prosoc_message_dialog.dart';

/// Bottom sheet — recharge du compte virtuel d'un agent supervisé.
class SuperviseurRechargeWalletSheet extends StatefulWidget {
  final int agentId;
  final String agentNom;

  const SuperviseurRechargeWalletSheet({
    super.key,
    required this.agentId,
    required this.agentNom,
  });

  /// Retourne `true` si la recharge a réussi.
  static Future<bool> show(
    BuildContext context, {
    required int agentId,
    required String agentNom,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SuperviseurRechargeWalletSheet(
        agentId: agentId,
        agentNom: agentNom,
      ),
    ).then((value) => value == true);
  }

  @override
  State<SuperviseurRechargeWalletSheet> createState() =>
      _SuperviseurRechargeWalletSheetState();
}

class _SuperviseurRechargeWalletSheetState
    extends State<SuperviseurRechargeWalletSheet> {
  final _formKey = GlobalKey<FormState>();
  final _montantController = TextEditingController();
  final _observationController = TextEditingController();

  WalletVirtuelAgentModel? _wallet;
  bool _isLoadingWallet = true;
  bool _isSubmitting = false;
  String? _walletError;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  @override
  void dispose() {
    _montantController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  Future<void> _loadWallet() async {
    setState(() {
      _isLoadingWallet = true;
      _walletError = null;
    });

    final response = await ApiService.getWalletVirtuelAgent(widget.agentId);
    if (!mounted) return;

    if (response.success && response.data != null) {
      setState(() {
        _wallet = response.data;
        _isLoadingWallet = false;
      });
      return;
    }

    setState(() {
      _isLoadingWallet = false;
      _walletError = ApiErrorHelper.messageForWalletVirtuelError(
        statusCode: response.statusCode,
        serverMessage: response.message,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final wallet = _wallet;
    if (wallet == null || wallet.idWalletVirtuelAgent <= 0) {
      await ProsocMessageDialog.show(
        context,
        variant: ProsocMessageVariant.error,
        title: 'Compte introuvable',
        message: 'Impossible de recharger : compte virtuel non disponible.',
      );
      return;
    }

    final montant = double.tryParse(
      _montantController.text.trim().replaceAll(',', '.'),
    );
    if (montant == null || montant <= 0) {
      await ProsocMessageDialog.show(
        context,
        variant: ProsocMessageVariant.warning,
        title: 'Montant invalide',
        message: 'Saisissez un montant strictement positif.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await ApiService.ajouterSoldeWalletVirtuelAgent(
        wallet.idWalletVirtuelAgent,
        montant: montant,
        observation: _observationController.text.trim(),
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        final result = response.data!;
        await ProsocMessageDialog.show(
          context,
          variant: ProsocMessageVariant.success,
          title: 'Recharge effectuée',
          message:
              'Le compte virtuel de ${widget.agentNom} a été rechargé avec succès.',
          hint:
              'Nouveau solde : ${result.formattedNouveauSolde(result.wallet)}',
        );
        if (!mounted) return;
        Navigator.of(context).pop(true);
        return;
      }

      await ProsocMessageDialog.show(
        context,
        variant: ProsocMessageVariant.error,
        title: 'Échec de la recharge',
        message: response.message ?? 'La recharge n\'a pas pu être effectuée.',
        statusCode: response.statusCode,
      );
    } catch (_) {
      if (!mounted) return;
      await ProsocMessageDialog.show(
        context,
        variant: ProsocMessageVariant.error,
        title: 'Erreur réseau',
        message: ApiErrorHelper.userFacingNetwork(),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Recharger le compte virtuel',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.agentNom,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 20),
                if (_isLoadingWallet)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.prosocGreen,
                      ),
                    ),
                  )
                else if (_walletError != null)
                  _buildWalletError()
                else
                  _buildForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletError() {
    return Column(
      children: [
        Icon(Icons.account_balance_wallet_outlined,
            size: 48, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Text(
          _walletError!,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _loadWallet,
          icon: const Icon(Icons.refresh),
          label: const Text('Réessayer'),
        ),
      ],
    );
  }

  Widget _buildForm() {
    final wallet = _wallet!;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.prosocGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.savings_outlined, color: AppColors.prosocGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Solde actuel',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        wallet.formattedSolde,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: AppColors.prosocGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _montantController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              labelText: 'Montant à ajouter *',
              hintText: '0.00',
              prefixIcon: const Icon(Icons.add_circle_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            validator: (value) {
              final parsed = double.tryParse(
                (value ?? '').trim().replaceAll(',', '.'),
              );
              if (parsed == null || parsed <= 0) {
                return 'Montant invalide';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _observationController,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Observation (optionnel)',
              hintText: 'Motif de la recharge…',
              prefixIcon: const Icon(Icons.notes_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.prosocGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Confirmer la recharge',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }
}
