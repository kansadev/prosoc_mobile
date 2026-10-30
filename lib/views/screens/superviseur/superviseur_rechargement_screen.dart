import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prosoc/services/auth_service.dart';

import '../../../config/api.dart';
import '../../../config/colors.dart';
import '../../../models/demande_recharge_wallet_virtuel_model.dart';
import '../../../utils/api_error_helper.dart';
import '../../../utils/devise_principale_resolver.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/prosoc_resource_error_view.dart';

/// Module « Rechargement » (Superviseur).
///
/// Centralise la consultation des demandes de rechargement de wallet virtuel
/// en attente et leur traitement (confirmation = crédit du wallet, ou rejet).
///
/// Seuls les agents ayant effectivement soumis une demande sont listés : la
/// source est `GET /api/DemandeRechargeWalletVirtuel/en-attente`.
class SuperviseurRechargementScreen extends StatefulWidget {
  const SuperviseurRechargementScreen({super.key});

  @override
  State<SuperviseurRechargementScreen> createState() =>
      _SuperviseurRechargementScreenState();
}

class _SuperviseurRechargementScreenState
    extends State<SuperviseurRechargementScreen> {
  bool _isLoading = true;
  String? _error;
  List<DemandeRechargeWalletVirtuel> _demandes = const [];

  /// Devise principale configurée (cohérente avec le wallet virtuel crédité).
  ResolvedDevise _devise = DevisePrincipaleResolver.usdFallback;

  int? _demandeEnCoursId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final devise = await DevisePrincipaleResolver.resolve();
      final response = await ApiService.getDemandesRechargeEnAttente();
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _devise = devise;
        if (response.success && response.data != null) {
          var list = response.data!
              .map(
                (d) => d.withDevise(
                  deviseId: _devise.deviseId,
                  deviseCode: _devise.deviseCode,
                  deviseSymbole: _devise.deviseSymbole,
                ),
              )
              .toList();
          final currentUserId = AuthService.currentUser?.utilisateur.idUtilisateur;
          if (currentUserId != null) {
            list = list.where((d) => d.demandeParUtilisateurId != currentUserId).toList();
          }
          _demandes = list;
          _error = null;
        } else {
          _error =
              response.message ??
              ApiErrorHelper.userFacingMessage(statusCode: response.statusCode);
        }
      });
    } catch (e, stackTrace) {
      if (!mounted) return;
      ApiErrorHelper.logException(
        'SuperviseurRechargement',
        e,
        stackTrace,
        false,
      );
      setState(() {
        _isLoading = false;
        _error = ApiErrorHelper.userFacingNetwork();
      });
    }
  }

  String _agentLabel(DemandeRechargeWalletVirtuel d) {
    final nom = d.agentNom.trim();
    if (nom.isNotEmpty) return nom;
    return 'Agent #${d.agentId}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Rechargement'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.prosocGreen,
          onRefresh: _load,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.prosocGreen),
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.12),
          ProsocResourceErrorView(message: _error!, onRetry: _load),
        ],
      );
    }

    if (_demandes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          EmptyStateWidget(
            icon: Icons.inbox_outlined,
            title: 'Aucune demande en attente',
            subtitle:
                'Les agents de votre équipe qui soumettent une demande de '
                'rechargement apparaîtront ici.',
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _demandes.length,
      itemBuilder: (context, index) => _buildDemandeCard(_demandes[index]),
    );
  }

  Widget _buildDemandeCard(DemandeRechargeWalletVirtuel demande) {
    final busy = _demandeEnCoursId == demande.idDemande;
    final date = demande.dateDemande ?? demande.dateCreation;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.prosocGreen.withValues(alpha: 0.12),
                child: Text(
                  _agentLabel(demande).isNotEmpty
                      ? _agentLabel(demande)[0].toUpperCase()
                      : 'A',
                  style: const TextStyle(
                    color: AppColors.prosocGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _agentLabel(demande),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (demande.agentMatricule.isNotEmpty)
                      Text(
                        'Matricule ${demande.agentMatricule}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                  ],
                ),
              ),
              if (date != null)
                Text(
                  DateFormat('dd/MM HH:mm', 'fr_FR').format(date.toLocal()),
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _metricCell('Montant', demande.formattedMontantCalcule),
              const SizedBox(width: 8),
              _metricCell('Solde', demande.formattedSoldeAuMomentDemande),
              const SizedBox(width: 8),
              _metricCell('Plafond', demande.formattedPlafond),
            ],
          ),
          if (demande.motif.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.notes_outlined,
                  size: 15,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    demande.motif.trim(),
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: busy ? null : () => _confirmer(demande),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.prosocGreen,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Recharger'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: busy ? null : () => _rejeter(demande),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.errorColor,
                  side: BorderSide(
                    color: AppColors.errorColor.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Rejeter'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricCell(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmer(DemandeRechargeWalletVirtuel demande) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer le rechargement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_agentLabel(demande)),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 13, height: 1.4),
                children: [
                  const TextSpan(text: 'Montant à créditer : '),
                  TextSpan(
                    text: demande.formattedMontantCalcule,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Le wallet virtuel de l\'agent sera crédité immédiatement.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.prosocGreen,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _demandeEnCoursId = demande.idDemande);
    try {
      final response = await ApiService.confirmerDemandeRecharge(
        demande.idDemande,
      );
      if (!mounted) return;

      if (!response.success) {
        await _showBusinessError(response.message);
        return;
      }

      final credited = response.data?.formattedMontantCredite;
      final soldeApres = response.data?.formattedSoldeApresCredit;

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.prosocGreen,
            size: 40,
          ),
          title: const Text('Rechargement effectué'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_agentLabel(demande)),
              const SizedBox(height: 10),
              if (credited != null)
                Text(
                  'Montant crédité : $credited',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              if (soldeApres != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Nouveau solde : $soldeApres',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      await _load();
    } catch (e, stackTrace) {
      if (!mounted) return;
      ApiErrorHelper.logException(
        'SuperviseurRechargement/confirmer',
        e,
        stackTrace,
        false,
      );
      _showSnack(ApiErrorHelper.userFacingNetwork(), isError: true);
    } finally {
      if (mounted) setState(() => _demandeEnCoursId = null);
    }
  }

  Future<void> _rejeter(DemandeRechargeWalletVirtuel demande) async {
    final motif = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Rejeter la demande'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_agentLabel(demande)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Motif du rejet *',
                  hintText: 'Ex. : dossier incomplet',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.errorColor,
              ),
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Rejeter'),
            ),
          ],
        );
      },
    );

    if (motif == null || motif.isEmpty || !mounted) return;

    setState(() => _demandeEnCoursId = demande.idDemande);
    try {
      final response = await ApiService.rejeterDemandeRecharge(
        demande.idDemande,
        motif: motif,
      );
      if (!mounted) return;

      if (!response.success) {
        await _showBusinessError(response.message);
        return;
      }

      _showSnack('Demande rejetée');
      await _load();
    } catch (e, stackTrace) {
      if (!mounted) return;
      ApiErrorHelper.logException(
        'SuperviseurRechargement/rejeter',
        e,
        stackTrace,
        false,
      );
      _showSnack(ApiErrorHelper.userFacingNetwork(), isError: true);
    } finally {
      if (mounted) setState(() => _demandeEnCoursId = null);
    }
  }

  /// Traduit les codes métier du backend en message exploitable.
  Future<void> _showBusinessError(String? message) async {
    final text = message?.trim() ?? '';
    final hint = switch (true) {
      _ when text.contains('SOLDE_AU_PLAFOND') =>
        'Le solde de l\'agent est déjà au plafond.',
      _ when text.contains('DEMANDE_EN_ATTENTE_EXISTANTE') =>
        'Une autre demande est déjà en file pour cet agent.',
      _ when text.contains('HIERARCHIE_RECHARGE_INTERDITE') =>
        'Cet agent est hors de votre périmètre hiérarchique.',
      _ when text.isEmpty => 'Opération impossible pour le moment.',
      _ => text,
    };
    _showSnack(hint, isError: true);
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.errorColor : AppColors.prosocGreen,
      ),
    );
  }
}
