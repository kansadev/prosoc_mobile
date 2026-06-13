import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prosoc/config/api.dart';
import 'package:prosoc/config/colors.dart';
import 'package:prosoc/models/dependant_model.dart';
import 'package:prosoc/utils/api_error_helper.dart';
import 'package:prosoc/utils/picked_image_data.dart';
import 'package:prosoc/views/widgets/prosoc_date_picker.dart';
import 'package:prosoc/views/widgets/prosoc_message_dialog.dart';

/// Formulaire ajout / modification d'une personne à charge (bottom sheet).
class DependantBottomSheet extends StatefulWidget {
  final int affilieId;
  final String affilieNom;
  final String affiliePrenom;
  final Dependant? dependant;

  const DependantBottomSheet({
    super.key,
    required this.affilieId,
    this.affilieNom = '',
    this.affiliePrenom = '',
    this.dependant,
  });

  bool get isEdit => dependant != null;

  static Future<bool?> show(
    BuildContext context, {
    required int affilieId,
    String affilieNom = '',
    String affiliePrenom = '',
    Dependant? dependant,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DependantBottomSheet(
          affilieId: affilieId,
          affilieNom: affilieNom,
          affiliePrenom: affiliePrenom,
          dependant: dependant,
        ),
      ),
    );
  }

  @override
  State<DependantBottomSheet> createState() => _DependantBottomSheetState();
}

class _DependantBottomSheetState extends State<DependantBottomSheet> {
  static const _liensParente = [
    'Conjoint(e)',
    'Enfant',
    'Frère',
    'Sœur',
    'Oncle',
    'Tante',
    'Cousin(e)',
  ];

  final _nomController = TextEditingController();
  final _adresseController = TextEditingController();

  String? _selectedLienParente;
  DateTime? _selectedDate;
  PickedImageData? _certificat;
  bool _removeCertificat = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final d = widget.dependant;
    if (d != null) {
      _nomController.text = d.nom;
      _adresseController.text = d.adresse ?? '';
      _selectedLienParente =
          Dependant.lienParenteToFormValue(d.lienParente) ?? d.lienParenteLabel;
      _selectedDate = d.dateNaissance;
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  String get _affilieLabel {
    final parts = <String>[
      if (widget.affiliePrenom.trim().isNotEmpty) widget.affiliePrenom.trim(),
      if (widget.affilieNom.trim().isNotEmpty) widget.affilieNom.trim(),
    ];
    return parts.join(' ');
  }

  int _computeAge(DateTime birthDate) {
    final now = DateTime.now();
    var age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _pickCertificat(ImageSource source) async {
    final picked = await PickedImageData.pick(source: source);
    if (picked != null && mounted) {
      setState(() {
        _certificat = picked;
        _removeCertificat = false;
      });
    }
  }

  Future<void> _showError(String message, {int? statusCode}) {
    return ProsocMessageDialog.show(
      context,
      variant: ProsocMessageVariant.error,
      title: widget.isEdit
          ? 'Modification impossible'
          : 'Ajout impossible',
      message: message,
      statusCode: statusCode,
    );
  }

  Future<void> _submit() async {
    final nom = _nomController.text.trim();
    final lien = _selectedLienParente;
    final date = _selectedDate;

    if (nom.isEmpty || lien == null || date == null) {
      await _showError('Veuillez remplir le nom, le lien de parenté et la date de naissance.');
      return;
    }

    final age = _computeAge(date);
    if (lien != 'Conjoint(e)' && age > 25) {
      await ProsocMessageDialog.show(
        context,
        variant: ProsocMessageVariant.warning,
        title: 'Âge invalide',
        message:
            'Un dépendant avec le lien « $lien » ne peut pas dépasser 25 ans.',
        hint: 'Âge actuel : $age ans',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dateStr = date.toIso8601String().split('T').first;
      final lienApi = Dependant.lienParenteForApi(lien);
      final adresse = _adresseController.text.trim();

      final ApiResponse<Map<String, dynamic>> response;

      if (widget.isEdit) {
        response = await ApiService.updateDependant(
          id: widget.dependant!.idDependant,
          nom: nom,
          lienParente: lienApi,
          affilieId: widget.affilieId,
          dateNaissance: dateStr,
          adresse: adresse.isNotEmpty ? adresse : null,
          certificatScolariteBase64: _certificat?.base64,
          certificatScolariteContentType: _certificat?.contentType,
        );
      } else {
        response = await ApiService.createDependant(
          nom: nom,
          lienParente: lienApi,
          affilieId: widget.affilieId,
          dateNaissance: dateStr,
          adresse: adresse.isNotEmpty ? adresse : null,
          certificatScolariteBase64: _certificat?.base64,
          certificatScolariteContentType: _certificat?.contentType,
        );
      }

      if (!mounted) return;

      if (response.success) {
        if (widget.isEdit &&
            _removeCertificat &&
            widget.dependant!.possedeCertificatScolarite) {
          await ApiService.deleteDependantCertificatScolarite(
            widget.dependant!.idDependant,
          );
        }

        await ProsocMessageDialog.show(
          context,
          variant: ProsocMessageVariant.success,
          title: widget.isEdit ? 'Dépendant mis à jour' : 'Dépendant ajouté',
          message: widget.isEdit
              ? 'Les informations ont été enregistrées avec succès.'
              : 'La personne à charge a été ajoutée avec succès.',
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
      ApiErrorHelper.logException('DependantBottomSheet/submit', e, stackTrace);
      if (!mounted) return;
      await _showError(ApiErrorHelper.userFacingNetwork());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _fieldDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      hintText: label,
      prefixIcon: icon != null
          ? Icon(icon, color: AppColors.prosocGreen, size: 20)
          : null,
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
        borderSide: const BorderSide(color: AppColors.prosocGreen, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.92;

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
                    Icons.people_outline,
                    color: AppColors.prosocGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isEdit
                            ? 'Modifier le dépendant'
                            : 'Ajouter un dépendant',
                        style: const TextStyle(
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
                  _fieldLabel('Nom *'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nomController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _fieldDecoration(
                      'Nom complet du dépendant',
                      icon: Icons.person_outline,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _fieldLabel('Lien de parenté *'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<String>(
                      initialValue: _liensParente.contains(_selectedLienParente)
                          ? _selectedLienParente
                          : null,
                      decoration: const InputDecoration(
                        hintText: 'Sélectionner le lien',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: _liensParente
                          .map(
                            (l) => DropdownMenuItem(value: l, child: Text(l)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedLienParente = v),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _fieldLabel('Date de naissance *'),
                  const SizedBox(height: 8),
                  ProsocDateFieldCompact(
                    label: 'Sélectionner une date',
                    value: _selectedDate,
                    initialDateFallback:
                        DateTime.now().subtract(const Duration(days: 365 * 10)),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    onDateSelected: (date) =>
                        setState(() => _selectedDate = date),
                  ),
                  const SizedBox(height: 20),
                  _fieldLabel('Adresse'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _adresseController,
                    maxLines: 2,
                    decoration: _fieldDecoration(
                      'Adresse (optionnel)',
                      icon: Icons.location_on_outlined,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _fieldLabel('Certificat de scolarité'),
                  const SizedBox(height: 4),
                  Text(
                    'Optionnel — requis pour les enfants de 18 à 25 ans',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  if (widget.isEdit &&
                      widget.dependant!.possedeCertificatScolarite &&
                      !_removeCertificat &&
                      _certificat == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 18,
                            color: Colors.blue.shade600,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Certificat enregistré',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                setState(() => _removeCertificat = true),
                            child: const Text(
                              'Retirer',
                              style: TextStyle(color: AppColors.errorColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_certificat != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Fichier : ${_certificat!.fileName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isSubmitting
                              ? null
                              : () => _pickCertificat(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined, size: 18),
                          label: const Text('Galerie'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isSubmitting
                              ? null
                              : () => _pickCertificat(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined, size: 18),
                          label: const Text('Photo'),
                        ),
                      ),
                    ],
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
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  widget.isEdit
                                      ? Icons.save_outlined
                                      : Icons.check_circle_outline,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.isEdit
                                      ? 'Enregistrer'
                                      : 'Confirmer l\'ajout',
                                ),
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
