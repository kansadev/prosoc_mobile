import 'package:flutter/material.dart';
import 'package:prosoc/config/api.dart';
import 'package:prosoc/config/colors.dart';
import 'package:prosoc/utils/api_error_helper.dart';
import 'package:prosoc/views/widgets/prosoc_message_dialog.dart';

/// Formulaire d'ajout d'un antécédent médical (bottom sheet).
class AntecedentBottomSheet extends StatefulWidget {
  final int affilieId;
  final String affilieNom;
  final String affiliePrenom;

  const AntecedentBottomSheet({
    super.key,
    required this.affilieId,
    this.affilieNom = '',
    this.affiliePrenom = '',
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
        child: AntecedentBottomSheet(
          affilieId: affilieId,
          affilieNom: affilieNom,
          affiliePrenom: affiliePrenom,
        ),
      ),
    );
  }

  @override
  State<AntecedentBottomSheet> createState() => _AntecedentBottomSheetState();
}

class _AntecedentBottomSheetState extends State<AntecedentBottomSheet> {
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  String get _affilieLabel {
    final parts = <String>[
      if (widget.affiliePrenom.trim().isNotEmpty) widget.affiliePrenom.trim(),
      if (widget.affilieNom.trim().isNotEmpty) widget.affilieNom.trim(),
    ];
    return parts.join(' ');
  }

  Future<void> _showError(String message, {int? statusCode}) {
    return ProsocMessageDialog.show(
      context,
      variant: ProsocMessageVariant.error,
      title: 'Enregistrement impossible',
      message: message,
      statusCode: statusCode,
    );
  }

  Future<void> _submit() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      await _showError('Veuillez décrire l\'antécédent.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await ApiService.createAntecedent(
        description: description,
        affilieId: widget.affilieId,
        statut: true,
      );

      if (!mounted) return;

      if (response.success) {
        await ProsocMessageDialog.show(
          context,
          variant: ProsocMessageVariant.success,
          title: 'Antécédent enregistré',
          message: 'L\'antécédent a été ajouté avec succès.',
          onConfirm: () {
            if (mounted) Navigator.pop(context, true);
          },
        );
      } else {
        await _showError(
          response.message ??
              ApiErrorHelper.userFacingMessage(
                statusCode: response.statusCode,
              ),
          statusCode: response.statusCode,
        );
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('AntecedentBottomSheet/submit', e, stackTrace);
      if (!mounted) return;
      await _showError(ApiErrorHelper.userFacingNetwork());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
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
                    Icons.health_and_safety_rounded,
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
                        'Ajouter un antécédent',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_affilieLabel.isNotEmpty)
                        Text(
                          _affilieLabel,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 5,
                    minLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText:
                          'Décrivez l\'antécédent médical ou autre information utile…',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.prosocGreen,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
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
                                Text('Confirmer l\'ajout'),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
