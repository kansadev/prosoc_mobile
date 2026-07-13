import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

enum ProsocLoadingShimmerVariant {
  /// Remplace un `CircularProgressIndicator` centré (défaut).
  center,

  /// Remplace un indicateur inline (bouton, AppBar, etc.).
  inline,

  /// Liste de cartes skeleton.
  list,

  /// Page complète avec header + cartes.
  page,
}

/// Couleurs shimmer adaptées au thème clair / sombre.
abstract final class ProsocShimmer {
  ProsocShimmer._();

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color skeletonFill(BuildContext context) =>
      isDark(context) ? const Color(0xFF2A2A2A) : Colors.white;

  static Color baseColor(BuildContext context) =>
      isDark(context) ? const Color(0xFF3A3A3A) : Colors.grey.shade300;

  static Color highlightColor(BuildContext context) =>
      isDark(context) ? const Color(0xFF4A4A4A) : Colors.grey.shade100;

  static Widget wrap(
    BuildContext context, {
    required Widget child,
    bool enabled = true,
  }) {
    return Shimmer.fromColors(
      baseColor: baseColor(context),
      highlightColor: highlightColor(context),
      enabled: enabled,
      child: child,
    );
  }

  /// Bloc rectangle shimmer réutilisable.
  static Widget box(
    BuildContext context, {
    double? width,
    double? height,
    double radius = 12,
    Color? color,
  }) {
    return wrap(
      context,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color ?? skeletonFill(context),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  /// Carte type liste (historique, transactions…).
  static Widget listCard(BuildContext context) {
    Color block() => skeletonFill(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: block(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark(context) ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 20,
                      width: 120,
                      decoration: BoxDecoration(
                        color: block(),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: block(),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 28,
                width: 72,
                decoration: BoxDecoration(
                  color: block(),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 12,
            width: 90,
            decoration: BoxDecoration(
              color: block(),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 12,
            width: 140,
            decoration: BoxDecoration(
              color: block(),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Remplace [CircularProgressIndicator] par une animation shimmer Prosoc.
///
/// ```dart
/// // Plein écran
/// const ProsocLoadingShimmer()
///
/// // Dans un bouton
/// const ProsocLoadingShimmer.inline(size: 24)
///
/// // Liste
/// ProsocLoadingShimmer.list(itemCount: 6)
/// ```
class ProsocLoadingShimmer extends StatelessWidget {
  const ProsocLoadingShimmer({
    super.key,
    this.variant = ProsocLoadingShimmerVariant.center,
    this.padding,
    this.itemCount = 4,
    this.size = 24,
  });

  const ProsocLoadingShimmer.inline({
    super.key,
    this.size = 24,
  })  : variant = ProsocLoadingShimmerVariant.inline,
        padding = null,
        itemCount = 1;

  const ProsocLoadingShimmer.list({
    super.key,
    this.itemCount = 5,
    this.padding,
  })  : variant = ProsocLoadingShimmerVariant.list,
        size = 24;

  const ProsocLoadingShimmer.page({
    super.key,
    this.padding,
  })  : variant = ProsocLoadingShimmerVariant.page,
        itemCount = 4,
        size = 24;

  final ProsocLoadingShimmerVariant variant;
  final EdgeInsetsGeometry? padding;
  final int itemCount;
  final double size;

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      ProsocLoadingShimmerVariant.inline => ProsocShimmer.wrap(
          context,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: ProsocShimmer.skeletonFill(context),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ProsocLoadingShimmerVariant.center => Center(
          child: Padding(
            padding: padding ?? const EdgeInsets.all(32),
            child: ProsocShimmer.wrap(
              context,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: ProsocShimmer.skeletonFill(context),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 14,
                    width: 160,
                    decoration: BoxDecoration(
                      color: ProsocShimmer.skeletonFill(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 12,
                    width: 120,
                    decoration: BoxDecoration(
                      color: ProsocShimmer.skeletonFill(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ProsocLoadingShimmerVariant.list => ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          padding: padding ?? const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: itemCount,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => ProsocShimmer.wrap(
            context,
            child: ProsocShimmer.listCard(context),
          ),
        ),
      ProsocLoadingShimmerVariant.page => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: padding ?? const EdgeInsets.all(20),
          child: ProsocShimmer.wrap(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _pageBlock(context, height: 28, radius: 8),
                const SizedBox(height: 14),
                _pageBlock(context, height: 72, radius: 14),
                const SizedBox(height: 14),
                _pageBlock(context, height: 140, radius: 18),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _pageBlock(context, height: 100)),
                    const SizedBox(width: 10),
                    Expanded(child: _pageBlock(context, height: 100)),
                  ],
                ),
                const SizedBox(height: 20),
                for (var i = 0; i < itemCount; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  ProsocShimmer.listCard(context),
                ],
              ],
            ),
          ),
        ),
    };
  }

  static Widget _pageBlock(
    BuildContext context, {
    required double height,
    double radius = 12,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: ProsocShimmer.skeletonFill(context),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Helper pour remplacer rapidement un [CircularProgressIndicator] dans un [Center].
Widget prosocLoadingCenter({EdgeInsetsGeometry? padding}) =>
    ProsocLoadingShimmer(padding: padding);

/// Helper inline (boutons, petites zones).
Widget prosocLoadingInline({double size = 24, Color? color}) {
  return Builder(
    builder: (context) {
      if (color != null) {
        return SizedBox(
          width: size,
          height: size,
          child: ProsocShimmer.wrap(
            context,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }
      return ProsocLoadingShimmer.inline(size: size);
    },
  );
}

/// Indicateur compact avec teinte Prosoc (sur fond vert).
Widget prosocLoadingInlineOnPrimary({double size = 24}) {
  return Builder(
    builder: (context) {
      return SizedBox(
        width: size,
        height: size,
        child: ProsocShimmer.wrap(
          context,
          child: Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    },
  );
}

/// Skeletons structurés pour les écrans d'accueil (adhérent, agent, percepteur, superviseur).
abstract final class ProsocHomeShimmer {
  ProsocHomeShimmer._();

  static Color _block(BuildContext context) =>
      ProsocShimmer.skeletonFill(context);

  static Color _blockOnPrimary() => Colors.white24;

  static Widget _rect(
    BuildContext context, {
    double? width,
    double? height,
    double radius = 8,
    Color? color,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? _block(context),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  /// Chargement initial écran adhérent.
  static Widget adherent({EdgeInsetsGeometry? padding}) {
    return Builder(
      builder: (context) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: padding ?? const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: ProsocShimmer.wrap(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _rect(context, height: 14, width: 140, radius: 6),
                const SizedBox(height: 12),
                _rect(context, height: 140, radius: 16),
                const SizedBox(height: 20),
                _rect(context, height: 16, width: 120, radius: 6),
                const SizedBox(height: 12),
                quickActionsRow(context),
                const SizedBox(height: 20),
                _rect(context, height: 76, radius: 14),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _rect(context, height: 90, radius: 14)),
                    const SizedBox(width: 10),
                    Expanded(child: _rect(context, height: 90, radius: 14)),
                  ],
                ),
                const SizedBox(height: 24),
                _rect(context, height: 180, radius: 16),
                const SizedBox(height: 24),
                _rect(context, height: 16, width: 160, radius: 6),
                const SizedBox(height: 12),
                for (var i = 0; i < 2; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  cotisationTile(context),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Chargement initial écran percepteur.
  static Widget percepteur({EdgeInsetsGeometry? padding}) {
    return Builder(
      builder: (context) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: padding ?? const EdgeInsets.all(20),
          child: ProsocShimmer.wrap(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _rect(context, height: 220, radius: 24),
                const SizedBox(height: 24),
                _rect(context, height: 22, width: 150, radius: 6),
                const SizedBox(height: 16),
                quickServicesGrid(context, count: 4),
                const SizedBox(height: 24),
                _rect(context, height: 22, width: 160, radius: 6),
                const SizedBox(height: 16),
                activityList(context, itemCount: 3),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Carte wallet / solde (agent AT).
  static Widget walletCard(
    BuildContext context, {
    EdgeInsetsGeometry? padding,
    double height = 180,
  }) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(20),
      child: ProsocShimmer.wrap(
        context,
        child: _rect(context, height: height, radius: 20),
      ),
    );
  }

  /// Bandeau KPI mensuel (agent AT).
  static Widget kpiStrip(
    BuildContext context, {
    EdgeInsetsGeometry? padding,
  }) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: ProsocShimmer.wrap(
        context,
        child: _rect(context, height: 72, radius: 16),
      ),
    );
  }

  /// Carte vue d'ensemble (superviseur).
  static Widget overviewCard(
    BuildContext context, {
    double height = 160,
  }) {
    return ProsocShimmer.wrap(
      context,
      child: _rect(context, height: height, radius: 20),
    );
  }

  /// Grille de stats 2×2 (superviseur).
  static Widget statsGrid(
    BuildContext context, {
    EdgeInsetsGeometry? padding,
    int count = 4,
  }) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: ProsocShimmer.wrap(
        context,
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: List.generate(
            count,
            (_) => _rect(context, radius: 16),
          ),
        ),
      ),
    );
  }

  /// Liste d'activité récente.
  static Widget activityList(
    BuildContext context, {
    EdgeInsetsGeometry? padding,
    int itemCount = 3,
  }) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        children: List.generate(
          itemCount,
          (index) => Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
            child: ProsocShimmer.wrap(
              context,
              child: ProsocShimmer.listCard(context),
            ),
          ),
        ),
      ),
    );
  }

  /// Rangée d'actions rapides (adhérent).
  static Widget quickActionsRow(BuildContext context, {int count = 4}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        count,
        (_) => Column(
          children: [
            _rect(context, width: 52, height: 52, radius: 26),
            const SizedBox(height: 8),
            _rect(context, width: 48, height: 10, radius: 4),
          ],
        ),
      ),
    );
  }

  /// Grille de services rapides (percepteur / agent).
  static Widget quickServicesGrid(
    BuildContext context, {
    int count = 4,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        count,
        (_) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                _rect(context, width: 48, height: 48, radius: 24),
                const SizedBox(height: 6),
                _rect(context, height: 10, radius: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Tuile cotisation (adhérent).
  static Widget cotisationTile(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _block(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ProsocShimmer.isDark(context)
              ? Colors.white12
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          _rect(context, width: 40, height: 40, radius: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _rect(context, height: 14, width: 120, radius: 4),
                const SizedBox(height: 6),
                _rect(context, height: 12, width: 80, radius: 4),
              ],
            ),
          ),
          _rect(context, height: 14, width: 56, radius: 4),
        ],
      ),
    );
  }

  /// Bloc section compact (ex. arriérés adhérent).
  static Widget sectionCard(
    BuildContext context, {
    double height = 76,
  }) {
    return ProsocShimmer.wrap(
      context,
      child: _rect(context, height: height, width: double.infinity, radius: 14),
    );
  }

  /// Skeleton wallet sur fond dégradé (cartes flip percepteur / superviseur).
  static Widget walletOnPrimary(BuildContext context) {
    return ProsocShimmer.wrap(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _rect(context, height: 14, width: 90, radius: 6, color: _blockOnPrimary()),
              const Spacer(),
              _rect(context, width: 28, height: 28, radius: 14, color: _blockOnPrimary()),
            ],
          ),
          const Spacer(),
          _rect(context, height: 32, width: 180, radius: 8, color: _blockOnPrimary()),
          const SizedBox(height: 8),
          _rect(context, height: 14, width: 120, radius: 6, color: _blockOnPrimary()),
        ],
      ),
    );
  }
}
