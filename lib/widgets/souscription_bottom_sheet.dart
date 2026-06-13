import 'package:flutter/material.dart';
import 'package:prosoc/config/api.dart';
import 'package:prosoc/config/colors.dart';
import 'package:prosoc/models/prestation_model.dart';
import 'package:prosoc/services/auth_service.dart';
import 'package:prosoc/utils/api_error_helper.dart';
import 'package:prosoc/views/widgets/prosoc_message_dialog.dart';

/// Formulaire de souscription — POST /api/SouscriptionPrestation (souscription + collecte).
class SouscriptionBottomSheet extends StatefulWidget {
  final int affilieId;
  final String affilieNom;
  final String affiliePrenom;

  const SouscriptionBottomSheet({
    super.key,
    required this.affilieId,
    required this.affilieNom,
    required this.affiliePrenom,
  });

  static Future<bool?> show(
    BuildContext context, {
    required int affilieId,
    String affilieNom = '',
    String affiliePrenom = '',
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
        ),
      ),
    );
  }

  @override
  State<SouscriptionBottomSheet> createState() => _SouscriptionBottomSheetState();
}

class _SouscriptionBottomSheetState extends State<SouscriptionBottomSheet> {
  List<Prestation> _prestations = [];
  bool _isLoadingPrestations = false;
  bool _isSubmitting = false;
  Prestation? _selectedPrestation;
  int? _agentId;

  @override
  void initState() {
    super.initState();
    _agentId = AuthService.currentUser?.utilisateur.agentId;
    _loadPrestations();
  }

  Future<void> _loadPrestations() async {
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
              .toList();
          _isLoadingPrestations = false;
        });
      } else {
        setState(() => _isLoadingPrestations = false);
        await _showError(
          response.message ?? 'Impossible de charger les prestations.',
          statusCode: response.statusCode,
        );
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('SouscriptionBottomSheet/prestations', e, stackTrace);
      if (!mounted) return;
      setState(() => _isLoadingPrestations = false);
      await _showError(ApiErrorHelper.userFacingNetwork());
    }
  }

  double? _resolveMontant(Prestation prestation) {
    final montant = prestation.resolveMontant();
    if (montant != null && montant > 0) return montant;

    final priceRegex = RegExp(r'Prix:\s*(\d+(?:[.,]\d+)?)\s*FCFA', caseSensitive: false);
    final match = priceRegex.firstMatch(prestation.description);
    if (match != null) {
      return double.tryParse(match.group(1)!.replaceAll(',', '.'));
    }
    return null;
  }

  String _formatMontant(Prestation prestation) {
    final montant = _resolveMontant(prestation);
    if (montant == null) return '—';
    final code = prestation.resolveDeviseCode();
    return code.isNotEmpty ? '$montant $code' : montant.toString();
  }

  Future<void> _submitSouscription() async {
    if (_selectedPrestation == null) {
      await _showError('Veuillez sélectionner une prestation.');
      return;
    }

    final agentId = _agentId;
    if (agentId == null || agentId <= 0) {
      await _showError(
        'Agent non identifié. Veuillez vous reconnecter.',
      );
      return;
    }

    final montant = _resolveMontant(_selectedPrestation!);
    if (montant == null || montant <= 0) {
      await _showError('Montant de la prestation invalide.');
      return;
    }

    final deviseId = _selectedPrestation!.deviseId;
    if (deviseId <= 0) {
      await _showError('Devise de la prestation introuvable.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      final response = await ApiService.createSouscriptionPrestation(
        affilieId: widget.affilieId,
        prestationId: _selectedPrestation!.id,
        dateSouscription: now,
        statut: true,
        agentId: agentId,
        montant: montant,
        mois: now.month,
        annee: now.year,
        deviseId: deviseId,
        modePaiement: 'VIRTUAL_ACCOUNT',
        statutPaiement: 'OK',
        observation:
            'Souscription ${_selectedPrestation!.nomPrestation} — '
            '${widget.affiliePrenom} ${widget.affilieNom}',
      );

      if (!mounted) return;

      if (response.success) {
        await ProsocMessageDialog.show(
          context,
          variant: ProsocMessageVariant.success,
          title: 'Souscription enregistrée',
          message: 'La souscription à la prestation a été créée avec succès.',
          onConfirm: () {
            if (mounted) Navigator.pop(context, true);
          },
        );
      } else {
        await _showError(
          response.message ?? 'Erreur lors de la création de la souscription.',
          statusCode: response.statusCode,
        );
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('SouscriptionBottomSheet/submit', e, stackTrace);
      if (!mounted) return;
      await _showError(ApiErrorHelper.userFacingNetwork());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  child: Icon(
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
          Padding(
            padding: const EdgeInsets.all(20),
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
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isLoadingPrestations
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.prosocGreen,
                            ),
                          ),
                        )
                      : DropdownButtonFormField<Prestation>(
                          initialValue: _selectedPrestation,
                          decoration: const InputDecoration(
                            hintText: 'Sélectionner une prestation',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          items: _prestations.map((prestation) {
                            return DropdownMenuItem<Prestation>(
                              value: prestation,
                              child: Text(
                                '${prestation.nomPrestation} — ${_formatMontant(prestation)}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedPrestation = value);
                          },
                        ),
                ),
                if (_selectedPrestation != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.prosocGreen.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          size: 18,
                          color: AppColors.prosocGreen,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Montant : ${_formatMontant(_selectedPrestation!)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),
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
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
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
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
