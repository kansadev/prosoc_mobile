import 'package:flutter/material.dart';

import '../../config/colors.dart';

/// Contenu visuel (icône + textes) de l'état vide.
class _EmptyStateBody extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final double iconSize;
  final Color? iconColor;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  const _EmptyStateBody({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.iconSize,
    this.iconColor,
    this.action,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor =
        iconColor ?? AppColors.prosocGreen.withValues(alpha: 0.4);

    return Padding(
      padding: padding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize, color: effectiveIconColor),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 20),
            action!,
          ],
        ],
      ),
    );
  }
}

/// État vide réutilisable (aucune donnée) — icône et textes configurables par page.
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final double iconSize;
  final Color? iconColor;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  /// Occupe la hauteur disponible du parent pour centrer verticalement.
  final bool expandVertically;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconSize = 56,
    this.iconColor,
    this.action,
    this.padding = const EdgeInsets.all(24),
    this.expandVertically = true,
  });

  @override
  Widget build(BuildContext context) {
    final body = _EmptyStateBody(
      icon: icon,
      title: title,
      subtitle: subtitle,
      iconSize: iconSize,
      iconColor: iconColor,
      action: action,
      padding: padding,
    );

    if (!expandVertically) {
      return Center(child: body);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasHeight =
            constraints.maxHeight.isFinite && constraints.maxHeight > 0;

        if (hasHeight) {
          return SizedBox(
            width: double.infinity,
            height: constraints.maxHeight,
            child: Center(child: body),
          );
        }

        return Center(child: body);
      },
    );
  }
}

/// Variante scrollable pour [RefreshIndicator] — centré dans l'espace visible.
class EmptyStateScrollable extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final double iconSize;
  final Color? iconColor;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  /// Contenu affiché au-dessus (ex. bannière), l'état vide reste centré en dessous.
  final Widget? header;

  /// Repli si la hauteur parente n'est pas bornée (rare).
  final double minHeightFactor;

  const EmptyStateScrollable({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconSize = 56,
    this.iconColor,
    this.action,
    this.padding = const EdgeInsets.all(24),
    this.header,
    this.minHeightFactor = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    final body = _EmptyStateBody(
      icon: icon,
      title: title,
      subtitle: subtitle,
      iconSize: iconSize,
      iconColor: iconColor,
      action: action,
      padding: padding,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final boundedHeight =
            constraints.maxHeight.isFinite && constraints.maxHeight > 0;

        if (boundedHeight) {
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (header != null)
                SliverToBoxAdapter(child: header!),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: body),
              ),
            ],
          );
        }

        final minHeight = MediaQuery.sizeOf(context).height * minHeightFactor;
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (header != null) header!,
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: Center(child: body),
            ),
          ],
        );
      },
    );
  }
}
