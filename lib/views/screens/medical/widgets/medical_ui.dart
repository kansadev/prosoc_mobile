import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../config/api.dart';
import '../../../../config/colors.dart';
import '../../../../models/devise_model.dart';
import '../../../../models/medical/prise_en_charge_medicale_model.dart';
import '../../../../models/medical/souscription_medicale_model.dart';
import '../../../../utils/currency_formatter.dart';

/// Devises actives (identifiants à résoudre par code, jamais codés en dur).
abstract final class MedicalDevises {
  static List<Devise>? _cache;
  static Future<void>? _loading;

  static Future<void> ensureLoaded() {
    if (_cache != null) return Future.value();
    return _loading ??= ApiService.getDevisesActives().then((response) {
      if (response.success && response.data != null) _cache = response.data;
      _loading = null;
    });
  }

  static List<Devise> get all => _cache ?? const [];

  static String? codeFor(int deviseId) =>
      _cache?.where((d) => d.idDevise == deviseId).firstOrNull?.code;

  static String montant(num amount, {int? deviseId, String? deviseCode}) {
    return CurrencyFormatter.format(
      amount: amount,
      deviseCode: deviseCode ?? (deviseId == null ? null : codeFor(deviseId)),
      deviseId: deviseId,
    );
  }
}

abstract final class MedicalFormat {
  static final DateFormat _date = DateFormat('dd/MM/yyyy', 'fr_FR');
  static final DateFormat _dateHeure = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
  static final DateFormat _mois = DateFormat('MMMM yyyy', 'fr_FR');

  static String date(DateTime? value) =>
      value == null ? '—' : _date.format(value.toLocal());

  static String dateHeure(DateTime? value) =>
      value == null ? '—' : _dateHeure.format(value.toLocal());

  static String mois(int annee, int mois) {
    final label = _mois.format(DateTime(annee, mois));
    return label[0].toUpperCase() + label.substring(1);
  }
}

class MedicalBadge extends StatelessWidget {
  const MedicalBadge({super.key, required this.label, required this.color});

  factory MedicalBadge.periode(EtatPeriodeMedicale etat) {
    final color = switch (etat) {
      EtatPeriodeMedicale.couvert => AppColors.prosocGreen,
      EtatPeriodeMedicale.payeAVenir => Colors.blue.shade700,
      EtatPeriodeMedicale.paiementPartiel => Colors.orange.shade800,
      EtatPeriodeMedicale.aPayer => Colors.red.shade600,
      EtatPeriodeMedicale.expire => Colors.grey.shade600,
      EtatPeriodeMedicale.droitsIndisponibles => Colors.brown.shade400,
    };
    return MedicalBadge(label: etat.label, color: color);
  }

  factory MedicalBadge.priseEnCharge(BadgePriseEnCharge badge) {
    final color = switch (badge) {
      BadgePriseEnCharge.validee => AppColors.prosocGreen,
      BadgePriseEnCharge.enAttente => Colors.orange.shade800,
      BadgePriseEnCharge.rejetee => Colors.red.shade600,
      BadgePriseEnCharge.utilisee => Colors.blueGrey.shade600,
      BadgePriseEnCharge.expiree => Colors.grey.shade600,
      BadgePriseEnCharge.inconnu => Colors.grey.shade500,
    };
    return MedicalBadge(label: badge.label, color: color);
  }

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class MedicalSection extends StatelessWidget {
  const MedicalSection({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.trailing,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.prosocGreen, size: 20),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class MedicalInfoRow extends StatelessWidget {
  const MedicalInfoRow(this.label, this.value, {super.key, this.emphasize = false});

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: emphasize ? 16 : 14,
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
                color: emphasize ? AppColors.prosocGreen : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Recharge les données au retour au premier plan : les droits ne sont jamais
/// réutilisés depuis un état ancien. À combiner avec `WidgetsBindingObserver`.
mixin MedicalResumeRefresh<T extends StatefulWidget>
    on State<T>, WidgetsBindingObserver {
  Future<void> onResumeRefresh();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      unawaited(onResumeRefresh());
    }
  }
}
