import 'package:flutter/material.dart';

import '../config/colors.dart';
import '../services/sync_service.dart';

/// Bandeau d'etat du mode hors ligne.
///
/// - hors ligne : les saisies partent en file locale ;
/// - en ligne avec des ecritures en attente : propose la synchronisation ;
/// - en ligne, file vide : rien (ecran non encombre).
class OfflineSyncBanner extends StatefulWidget {
  final bool dense;

  const OfflineSyncBanner({super.key, this.dense = false});

  @override
  State<OfflineSyncBanner> createState() => _OfflineSyncBannerState();
}

class _OfflineSyncBannerState extends State<OfflineSyncBanner> {
  /// Message hors ligne fermé par l'agent ; il revient à la prochaine coupure.
  /// Les rejets et les erreurs restent toujours affichés.
  bool _offlineFerme = false;

  bool get dense => widget.dense;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SyncState>(
      valueListenable: SyncService.instance.state,
      builder: (context, state, _) {
        if (state.isOnline) _offlineFerme = false;
        if (state.rejets.isNotEmpty) return _rejets(state);
        if (!state.isOnline) {
          return _offlineFerme ? const SizedBox.shrink() : _offline(state);
        }
        if (state.isSyncing || state.isFlushing) return _syncing(state);
        if (state.pendingCount > 0) return _pending(state);
        if (state.lastError != null) return _error(state);
        return const SizedBox.shrink();
      },
    );
  }

  Widget _offline(SyncState state) {
    final text =
        'Mode hors ligne : vos saisies sont enregistrées localement et '
        'seront envoyées au retour du réseau.';
    return _shell(
      background: const Color(0xFFFEF3C7),
      border: const Color(0xFFF59E0B),
      icon: Icons.cloud_off_rounded,
      iconColor: const Color(0xFFB45309),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: dense ? 11.5 : 12.5,
                height: 1.35,
                color: const Color(0xFF92400E),
              ),
            ),
          ),
          if (state.pendingCount > 0) ...[
            const SizedBox(width: 8),
            _badge(state.pendingCount),
          ],
          IconButton(
            tooltip: 'Fermer',
            onPressed: () => setState(() => _offlineFerme = true),
            icon: const Icon(Icons.close_rounded, color: Color(0xFFB45309)),
            iconSize: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          ),
        ],
      ),
    );
  }

  Widget _syncing(SyncState state) {
    final label = state.isFlushing
        ? 'Envoi des écritures en attente…'
        : 'Synchronisation des données…';
    return _shell(
      background: AppColors.prosocGreen.withValues(alpha: 0.08),
      border: AppColors.prosocGreen.withValues(alpha: 0.3),
      icon: Icons.sync_rounded,
      iconColor: AppColors.prosocGreen,
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.prosocGreen,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: dense ? 11.5 : 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.prosocGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pending(SyncState state) {
    return _shell(
      background: const Color(0xFFEFF6FF),
      border: const Color(0xFF3B82F6),
      icon: Icons.cloud_upload_outlined,
      iconColor: const Color(0xFF1D4ED8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${state.pendingCount} écriture(s) en attente de synchronisation'
              '${state.lastError != null ? ' — ${state.lastError}' : ''}',
              style: TextStyle(
                fontSize: dense ? 11.5 : 12.5,
                height: 1.35,
                color: const Color(0xFF1E40AF),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const _SyncButton(),
        ],
      ),
    );
  }

  /// Opérations hors ligne refusées par le serveur : affichées jusqu'à
  /// confirmation de l'agent (sinon il croirait la saisie enregistrée).
  Widget _rejets(SyncState state) {
    return _shell(
      background: const Color(0xFFFEF2F2),
      border: const Color(0xFFEF4444),
      icon: Icons.report_gmailerrorred_rounded,
      iconColor: const Color(0xFFB91C1C),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${state.rejets.length} opération(s) hors ligne rejetée(s) — '
              '${state.rejets.join(' ; ')}',
              style: TextStyle(
                fontSize: dense ? 11.5 : 12.5,
                height: 1.35,
                color: const Color(0xFF991B1B),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: SyncService.instance.acknowledgeRejets,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFB91C1C),
              backgroundColor: Colors.white,
              minimumSize: const Size(0, 30),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text(
              'Compris',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _error(SyncState state) {
    return _shell(
      background: const Color(0xFFFEF2F2),
      border: const Color(0xFFEF4444),
      icon: Icons.error_outline_rounded,
      iconColor: const Color(0xFFB91C1C),
      child: Row(
        children: [
          Expanded(
            child: Text(
              state.lastError ?? '',
              style: TextStyle(
                fontSize: dense ? 11.5 : 12.5,
                color: const Color(0xFF991B1B),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const _SyncButton(),
        ],
      ),
    );
  }

  Widget _badge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE68A),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.upload_rounded, size: 12, color: Color(0xFF92400E)),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF92400E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shell({
    required Color background,
    required Color border,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 10 : 14,
        vertical: dense ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: background,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: dense ? 16 : 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SyncButton extends StatefulWidget {
  const _SyncButton();

  @override
  State<_SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends State<_SyncButton> {
  bool _busy = false;

  Future<void> _run() async {
    if (_busy) return;
    setState(() => _busy = true);
    final service = SyncService.instance;
    try {
      if (service.pendingCount > 0) {
        await service.flushQueue();
      } else {
        await service.syncAll();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF1D4ED8),
              ),
            )
          : TextButton(
              onPressed: _run,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1D4ED8),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                ),
              ),
              child: const Text(
                'Synchroniser',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
            ),
    );
  }
}
