import 'package:flutter/material.dart';

import '../../../../config/colors.dart';
import '../../../../models/dependant_model.dart';
import '../../../../utils/formatters.dart';

/// Détail d'une personne à charge (bottom sheet).
class DependantDetailSheet extends StatelessWidget {
  final Dependant dependant;
  final VoidCallback? onEdit;
  final VoidCallback? onDeleteCertificat;
  final VoidCallback? onDelete;

  const DependantDetailSheet({
    super.key,
    required this.dependant,
    this.onEdit,
    this.onDeleteCertificat,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    required Dependant dependant,
    VoidCallback? onEdit,
    VoidCallback? onDeleteCertificat,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DependantDetailSheet(
        dependant: dependant,
        onEdit: onEdit,
        onDeleteCertificat: onDeleteCertificat,
        onDelete: onDelete,
      ),
    );
  }

  int? _ageYears() {
    final birth = dependant.dateNaissance;
    if (birth == null) return null;
    final now = DateTime.now();
    var age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age >= 0 ? age : null;
  }

  @override
  Widget build(BuildContext context) {
    final d = dependant;
    final age = _ageYears();

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  children: [
                    //_buildHeader(context, d, age),
                    const SizedBox(height: 20),
                    _section(
                      title: 'Informations',
                      children: [
                        _infoRow(
                          Icons.family_restroom_outlined,
                          'Lien de parenté',
                          d.lienParenteLabel,
                        ),
                        _infoRow(
                          Icons.cake_outlined,
                          'Date de naissance',
                          d.dateNaissance != null
                              ? AppFormatters.formatDate(d.dateNaissance)
                              : null,
                        ),
                        if (age != null)
                          _infoRow(
                            Icons.cake_outlined,
                            'Âge',
                            '$age ans',
                          ),
                        _infoRow(
                          Icons.phone_outlined,
                          'Téléphone',
                          d.telephone,
                        ),
                        _infoRow(
                          Icons.location_on_outlined,
                          'Adresse',
                          d.adresse,
                          multiline: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _section(
                      title: 'Documents',
                      children: [
                        _certificatTile(d.possedeCertificatScolarite),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _section(
                      title: 'Suivi',
                      children: [
                        _infoRow(
                          Icons.tag_outlined,
                          'Identifiant',
                          '#${d.idDependant}',
                        ),
                        _infoRow(
                          Icons.event_outlined,
                          'Enregistré le',
                          d.dateCreation != null
                              ? AppFormatters.formatDateTime(d.dateCreation)
                              : null,
                        ),
                        if (d.dateModification != null)
                          _infoRow(
                            Icons.update_outlined,
                            'Dernière modification',
                            AppFormatters.formatDateTime(d.dateModification),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildActions(context),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  

  Widget _section({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String? value, {
    bool multiline = false,
  }) {
    final empty = value == null || value.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.prosocGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.prosocGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  empty ? 'Non renseigné' : value.trim(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: empty ? Colors.grey.shade400 : AppColors.textPrimary,
                    height: multiline ? 1.35 : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _certificatTile(bool possede) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: possede
            ? Colors.blue.shade50
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: possede ? Colors.blue.shade100 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.school_outlined,
            color: possede ? Colors.blue.shade700 : Colors.grey.shade500,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Certificat de scolarité',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  possede
                      ? 'Document enregistré sur le dossier'
                      : 'Aucun certificat joint',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            possede ? Icons.check_circle : Icons.info_outline,
            color: possede ? Colors.blue.shade600 : Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onEdit != null)
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onEdit!();
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Modifier'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.prosocGreen,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        if (onDeleteCertificat != null && dependant.possedeCertificatScolarite) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onDeleteCertificat!();
            },
            icon: const Icon(Icons.school_outlined),
            label: const Text('Retirer le certificat'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue.shade700,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
        if (onDelete != null) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onDelete!();
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Supprimer'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.errorColor,
              side: const BorderSide(color: AppColors.errorColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
