import 'package:flutter/material.dart';

import '../../config/colors.dart';
import '../../models/wallet_mouvement_model.dart';
import '../../models/wallet_virtuel_mouvement_model.dart';

/// Carte mouvement wallet — source sur toute la 2ᵉ ligne, montant en bas à droite.
class WalletMovementCard extends StatelessWidget {
  final String title;
  final String sourceLabel;
  final String dateLabel;
  final String amountLabel;
  final bool isPositive;
  final VoidCallback? onTap;
  final bool showDetailChevron;

  const WalletMovementCard({
    super.key,
    required this.title,
    required this.sourceLabel,
    required this.dateLabel,
    required this.amountLabel,
    required this.isPositive,
    this.onTap,
    this.showDetailChevron = false,
  });

  factory WalletMovementCard.fromWalletMovement({
    required WalletMouvementModel movement,
    required String amountLabel,
    bool? isPositive,
    VoidCallback? onTap,
    bool showDetailChevron = false,
  }) {
    final positive = isPositive ??
        (movement.isCredit || (!movement.isDebit && movement.montant >= 0));

    return WalletMovementCard(
      title: movement.title,
      sourceLabel: movement.sourceDisplay,
      dateLabel: movement.formattedDate,
      amountLabel: amountLabel,
      isPositive: positive,
      onTap: onTap,
      showDetailChevron: showDetailChevron,
    );
  }

  factory WalletMovementCard.fromVirtuelMovement({
    required WalletVirtuelMouvementModel movement,
    required String amountLabel,
    bool? isPositive,
    VoidCallback? onTap,
  }) {
    final positive = isPositive ??
        (movement.isCredit || (!movement.isDebit && movement.montant >= 0));

    return WalletMovementCard(
      title: movement.title,
      sourceLabel: movement.sourceDisplay,
      dateLabel: movement.formattedDate,
      amountLabel: amountLabel,
      isPositive: positive,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? AppColors.prosocGreen : AppColors.errorColor;

    final card = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPositive
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sourceLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateLabel,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    amountLabel,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (showDetailChevron) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: card,
      ),
    );
  }
}
