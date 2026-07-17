import 'package:flutter/material.dart';
import 'package:prosoc/config/colors.dart';

/// Widget réutilisable pour les items de menu popup
class PopupMenuItemWidget extends PopupMenuItem<String> {
  PopupMenuItemWidget({
    super.key,
    required String value,
    required IconData icon,
    required String label,
    Color? iconColor,
    double? iconSize,
    double? spacing,
  }) : super(
          value: value,
          child: Row(
            children: [
              Icon(
                icon,
                color: iconColor ?? AppColors.prosocGreen,
                size: iconSize ?? 20,
              ),
              SizedBox(width: spacing ?? 12),
              Text(label),
            ],
          ),
        );
}

/// Widget réutilisable pour le menu popup complet avec actions
class AffiliatePopupMenuWidget extends StatelessWidget {
  final VoidCallback? onCollecte;
  final VoidCallback? onPayerFrais;
  final VoidCallback? onPayerSouscription;
  final VoidCallback? onDependants;
  final VoidCallback? onSouscription;
  final VoidCallback? onDemandeBon;
  final VoidCallback? onAntecedents;
  final VoidCallback? onArrieres;
  final Color? iconColor;

  const AffiliatePopupMenuWidget({
    super.key,
    this.onCollecte,
    this.onPayerFrais,
    this.onPayerSouscription,
    this.onDependants,
    this.onSouscription,
    this.onDemandeBon,
    this.onAntecedents,
    this.onArrieres,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: iconColor ?? AppColors.textPrimary),
      onSelected: (value) {
        switch (value) {
          case 'collecte':
            onCollecte?.call();
            break;
          case 'payer_frais':
            onPayerFrais?.call();
            break;
          case 'payer_souscription':
            onPayerSouscription?.call();
            break;
          case 'dependants':
            onDependants?.call();
            break;
          case 'souscription':
            onSouscription?.call();
            break;
          case 'demande_bon':
            onDemandeBon?.call();
            break;
          case 'antecedents':
            onAntecedents?.call();
            break;
          case 'arrieres':
            onArrieres?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        // Collecte
        if (onCollecte != null)
          PopupMenuItemWidget(
            value: 'collecte',
            icon: Icons.payments_outlined,
            label: 'Payer une cotisation',
          ),

        if (onPayerFrais != null)
          PopupMenuItemWidget(
            value: 'payer_frais',
            icon: Icons.receipt_long_outlined,
            label: 'Payer un frais',
          ),

        if (onPayerSouscription != null)
          PopupMenuItemWidget(
            value: 'payer_souscription',
            icon: Icons.medical_services_outlined,
            label: 'Payer une souscription',
          ),

        // Dépendants
        if (onDependants != null)
          PopupMenuItemWidget(
            value: 'dependants',
            icon: Icons.people_outline,
            label: 'Ajouter un dépendant',
          ),

        // Souscription
        if (onSouscription != null)
          PopupMenuItemWidget(
            value: 'souscription',
            icon: Icons.library_add_rounded,
            label: 'Souscrire à une prestation',
          ),

        if (onDemandeBon != null)
          PopupMenuItemWidget(
            value: 'demande_bon',
            icon: Icons.confirmation_number_outlined,
            label: 'Demander un bon',
          ),

        // Antécédents
        if (onAntecedents != null)
          PopupMenuItemWidget(
            value: 'antecedents',
            icon: Icons.health_and_safety_rounded,
            label: 'Ajouter un antécédent',
          ),

        if (onArrieres != null)
          PopupMenuItemWidget(
            value: 'arrieres',
            icon: Icons.history_toggle_off_rounded,
            label: 'Voir les arriérés',
          ),
      ],
    );
  }
}

/// Méthode utilitaire pour créer un AppBar avec le menu popup
AppBar createAppBarWithPopupMenu({
  required String title,
  List<Widget>? actions,
  VoidCallback? onCollecte,
  VoidCallback? onPayerFrais,
  VoidCallback? onPayerSouscription,
  VoidCallback? onDependants,
  VoidCallback? onSouscription,
  VoidCallback? onDemandeBon,
  VoidCallback? onAntecedents,
  VoidCallback? onArrieres,
  bool automaticallyImplyLeading = true,
  Widget? leading,
}) {
  return AppBar(
    title: Text(title),
    automaticallyImplyLeading: automaticallyImplyLeading,
    leading: leading,
    actions: [
      AffiliatePopupMenuWidget(
        onCollecte: onCollecte,
        onPayerFrais: onPayerFrais,
        onPayerSouscription: onPayerSouscription,
        onDependants: onDependants,
        onSouscription: onSouscription,
        onDemandeBon: onDemandeBon,
        onAntecedents: onAntecedents,
        onArrieres: onArrieres,
      ),
      const SizedBox(width: 8),
      ...?actions,
    ],
  );
}
