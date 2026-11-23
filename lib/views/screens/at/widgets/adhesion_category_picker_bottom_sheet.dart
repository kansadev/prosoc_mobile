import 'package:flutter/material.dart';

import '../../../../config/colors.dart';

class AdhesionCategoryPickerBottomSheet extends StatelessWidget {
  const AdhesionCategoryPickerBottomSheet({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AdhesionCategoryPickerBottomSheet(),
    );
  }

  static const _choices = <_CategoryChoice>[
    _CategoryChoice(
      code: 'PARTICULIER',
      title: 'Particulier',
      description: 'Adhésion sans rattachement à un partenaire',
      icon: Icons.person_outline_rounded,
      color: AppColors.prosocGreen,
    ),
    _CategoryChoice(
      code: 'STRUCTURE',
      title: 'Structure',
      description: 'Rattacher l’affilié à une structure partenaire',
      icon: Icons.account_balance_outlined,
      color: Color(0xFF3977C5),
    ),
    _CategoryChoice(
      code: 'ENTREPRISE',
      title: 'Entreprise',
      description: 'Rattacher l’affilié à une entreprise partenaire',
      icon: Icons.business_outlined,
      color: Color(0xFFDA8B28),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Nouvelle adhésion',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Quel type d’adhésion souhaitez-vous créer ?',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            for (final choice in _choices) ...[
              _CategoryChoiceTile(
                choice: choice,
                onTap: () => Navigator.of(context).pop(choice.code),
              ),
              if (choice != _choices.last) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryChoiceTile extends StatelessWidget {
  const _CategoryChoiceTile({required this.choice, required this.onTap});

  final _CategoryChoice choice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: ValueKey('adhesion-category-${choice.code}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: choice.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(choice.icon, color: choice.color, size: 25),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      choice.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      choice.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChoice {
  const _CategoryChoice({
    required this.code,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String code;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
}
