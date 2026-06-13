import 'package:flutter/material.dart';

import '../../../../config/api.dart';
import '../../../../config/colors.dart';
import '../../../../models/souscription_prestation_model.dart';
import '../../../../utils/api_error_helper.dart';

/// Formulaire de création d'une demande de bon d'envoi.
class DemandeBonFormSheet extends StatefulWidget {
  final int affilieId;
  final List<SouscriptionPrestationModel> souscriptions;

  const DemandeBonFormSheet({
    super.key,
    required this.affilieId,
    required this.souscriptions,
  });

  static Future<bool?> show(
    BuildContext context, {
    required int affilieId,
    required List<SouscriptionPrestationModel> souscriptions,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DemandeBonFormSheet(
        affilieId: affilieId,
        souscriptions: souscriptions,
      ),
    );
  }

  @override
  State<DemandeBonFormSheet> createState() => _DemandeBonFormSheetState();
}

class _DemandeBonFormSheetState extends State<DemandeBonFormSheet> {
  static const _typesDemande = [
    'Consultation',
    'Hospitalisation',
    'Pharmacie',
    'Laboratoire',
    'Imagerie',
    'Autre',
  ];

  final _motifController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  SouscriptionPrestationModel? _selectedSouscription;
  String? _selectedType;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _motifController.dispose();
    super.dispose();
  }

  Future<bool> _verifierEligibilite() async {
    final response =
        await ApiService.verifierEligibiliteDemandeBon(widget.affilieId);
    if (!response.success) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message ??
                'Impossible de vérifier votre éligibilité.',
          ),
        ),
      );
      return false;
    }
    final elig = response.data;
    if (elig == null || !elig.eligible) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            elig?.message.isNotEmpty == true
                ? elig!.message
                : 'Vous n\'êtes pas éligible à une demande de bon.',
          ),
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final souscription = _selectedSouscription;
    final type = _selectedType;
    if (souscription == null || type == null) return;

    setState(() => _isSubmitting = true);

    try {
      if (!await _verifierEligibilite()) return;

      final response = await ApiService.createDemandeBonEnvoi(
        affilieId: widget.affilieId,
        prestationId: souscription.prestationId,
        typeDemande: type,
        motifDemande: _motifController.text.trim(),
      );

      if (!mounted) return;

      if (response.success) {
        Navigator.pop(context, true);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message ??
                'Impossible d\'enregistrer la demande.',
          ),
        ),
      );
    } catch (e, st) {
      ApiErrorHelper.logException('DemandeBonEnvoi/create', e, st, false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiErrorHelper.userFacingNetwork())),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final activeSouscriptions = widget.souscriptions
        .where((s) => s.statut && s.prestationId > 0)
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
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
                  const Text(
                    'Nouvelle demande de bon',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (activeSouscriptions.isEmpty)
                    Text(
                      'Aucune souscription active. Souscrivez à une prestation '
                      'avant de demander un bon.',
                      style: TextStyle(color: Colors.grey.shade700),
                    )
                  else ...[
                    DropdownButtonFormField<SouscriptionPrestationModel>(
                      initialValue: _selectedSouscription,
                      decoration: const InputDecoration(
                        labelText: 'Prestation',
                        border: OutlineInputBorder(),
                      ),
                      items: activeSouscriptions
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s.prestationNom.isNotEmpty
                                    ? s.prestationNom
                                    : 'Prestation #${s.prestationId}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _isSubmitting
                          ? null
                          : (v) => setState(() => _selectedSouscription = v),
                      validator: (v) =>
                          v == null ? 'Choisissez une prestation' : null,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Type de demande',
                        border: OutlineInputBorder(),
                      ),
                      items: _typesDemande
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: _isSubmitting
                          ? null
                          : (v) => setState(() => _selectedType = v),
                      validator: (v) =>
                          v == null ? 'Choisissez un type' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _motifController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Motif',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().length < 5) {
                          return 'Décrivez le motif (5 caractères min.)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed:
                          _isSubmitting || activeSouscriptions.isEmpty
                              ? null
                              : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.prosocGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                          : const Text('Envoyer la demande'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
