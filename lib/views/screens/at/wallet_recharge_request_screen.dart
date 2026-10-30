import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/api.dart';
import '../../../config/colors.dart';
import '../../../models/demande_recharge_wallet_virtuel_model.dart';
import '../../../services/auth_service.dart';
import '../../../utils/api_error_helper.dart';
import '../../../utils/devise_principale_resolver.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/prosoc_resource_error_view.dart';

/// Demande de rechargement du wallet virtuel de l'Agent AT.
///
/// Le montant n'est pas saisi : l'API `POST /api/DemandeRechargeWalletVirtuel`
/// ne prend que `agentId` et `motif`, et calcule `montantCalcule` à partir du
/// plafond et du solde au moment de la demande.
class WalletRechargeRequestScreen extends StatefulWidget {
  const WalletRechargeRequestScreen({super.key});

  @override
  State<WalletRechargeRequestScreen> createState() =>
      _WalletRechargeRequestScreenState();
}

class _WalletRechargeRequestScreenState
    extends State<WalletRechargeRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _motifController = TextEditingController();

  bool _isSubmitting = false;
  bool _isLoadingHistory = true;
  String? _historyError;
  String? _errorMessage;
  List<DemandeRechargeWalletVirtuel> _demandes = const [];

  /// Devise principale configurée (cohérente avec le wallet virtuel crédité).
  ResolvedDevise _devise = DevisePrincipaleResolver.usdFallback;

  bool _motifSubmitted = false;

  @override
  void initState() {
    super.initState();
    _loadDevise();
    _loadHistory();
  }

  Future<void> _loadDevise() async {
    final devise = await DevisePrincipaleResolver.resolve();
    if (!mounted) return;
    setState(() {
      _devise = devise;
      _demandes = _demandes.map((d) => _withDevise(d)).toList();
    });
  }

  /// Applique la devise résolue à une demande (le plafond, le solde et le
  /// montant crédité sont exprimés dans la devise du wallet virtuel).
  DemandeRechargeWalletVirtuel _withDevise(
    DemandeRechargeWalletVirtuel demande,
  ) {
    return demande.withDevise(
      deviseId: _devise.deviseId,
      deviseCode: _devise.deviseCode,
      deviseSymbole: _devise.deviseSymbole,
    );
  }

  @override
  void dispose() {
    _motifController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final agentId = AuthService.currentUser?.utilisateur.agentId;
    if (agentId == null) {
      setState(() {
        _isLoadingHistory = false;
        _historyError = 'Agent non identifié. Reconnectez-vous.';
      });
      return;
    }

    setState(() {
      _isLoadingHistory = true;
      _historyError = null;
    });

    try {
      final response = await ApiService.getDemandesRechargeWalletByAgent(
        agentId,
      );
      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _demandes = response.data!.map(_withDevise).toList();
          _isLoadingHistory = false;
          _historyError = null;
        });
        return;
      }

      setState(() {
        _isLoadingHistory = false;
        _historyError =
            response.message ??
            ApiErrorHelper.userFacingMessage(statusCode: response.statusCode);
      });
    } catch (e, stackTrace) {
      if (!mounted) return;
      ApiErrorHelper.logException(
        'WalletRechargeRequestScreen',
        e,
        stackTrace,
        false,
      );
      setState(() {
        _isLoadingHistory = false;
        _historyError = ApiErrorHelper.userFacingNetwork();
      });
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final agentId = AuthService.currentUser?.utilisateur.agentId;
    if (agentId == null) {
      setState(() {
        _errorMessage = 'Agent non identifié. Reconnectez-vous.';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.createDemandeRechargeWalletVirtuel(
        agentId: agentId,
        motif: _motifSubmitted ? _motifController.text.trim() : null,
      );

      if (!mounted) return;

      if (!response.success || response.data == null) {
        setState(() {
          _isSubmitting = false;
          _errorMessage =
              response.message ??
              ApiErrorHelper.userFacingMessage(statusCode: response.statusCode);
        });
        return;
      }

      setState(() {
        _isSubmitting = false;
        _errorMessage = null;
        _motifController.clear();
        _motifSubmitted = false;
      });

      await _loadHistory();
      if (!mounted) return;

      final montant = _withDevise(response.data!).formattedMontantCalcule;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.prosocGreen,
          ),
          title: const Text('Demande enregistrée'),
          content: Text(
            'Votre demande n°${response.data!.idDemande} a été transmise '
            'pour validation.\n\nMontant calculé automatiquement : $montant',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e, stackTrace) {
      if (!mounted) return;
      ApiErrorHelper.logException(
        'WalletRechargeRequestScreen',
        e,
        stackTrace,
        false,
      );
      setState(() {
        _isSubmitting = false;
        _errorMessage = ApiErrorHelper.userFacingNetwork();
      });
    }
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const _DemandesRechargeHistoryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Demande de rechargement',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            tooltip: 'Historique',
            onPressed: _openHistory,
            icon: const Icon(Icons.history_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildAmountNotice(),
              const SizedBox(height: 20),
              _buildPendingRequest(),
              const SizedBox(height: 20),
              _buildMotifField(),
              const SizedBox(height: 20),
              if (_errorMessage != null) ...[
                _buildErrorBanner(_errorMessage!),
                const SizedBox(height: 16),
              ],
              _buildSubmitButton(),
              const SizedBox(height: 24),
              _buildHistoryPreview(),
            ],
          ),
        ),
      ),
    );
  }

  /// Le montant étant calculé côté serveur, on l'annonce explicitement.
  Widget _buildAmountNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.prosocGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.prosocGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: AppColors.prosocGreen,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Le montant du rechargement est calculé automatiquement par '
                  'la plateforme selon votre plafond et votre solde actuel. '
                  'Vous ne pouvez pas le saisir.',
                  style: const TextStyle(fontSize: 12.5, height: 1.4),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.currency_exchange,
                      size: 15,
                      color: AppColors.prosocGreen,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Devise du rechargement : ${_devise.deviseCode}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.prosocGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequest() {
    final pending = _demandes.where((d) => d.isEnAttente).toList();
    if (_isLoadingHistory && pending.isEmpty) {
      return const SizedBox.shrink();
    }
    if (pending.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.hourglass_top_rounded,
                size: 18,
                color: Color(0xFFB26A00),
              ),
              const SizedBox(width: 8),
              Text(
                'Demande en attente (${pending.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Montant annoncé : ${pending.first.formattedMontantCalcule}\n'
            'Elle doit être validée avant tout nouveau rechargement.',
            style: const TextStyle(fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildMotifField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Motif de la demande (optionnel)',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _motifController,
          enabled: !_isSubmitting,
          maxLength: 500,
          maxLines: 3,
          onChanged: (_) => setState(() => _motifSubmitted = true),
          decoration: InputDecoration(
            hintText: 'Ex. reconstitution du stock de collecte',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          validator: (value) {
            if ((value ?? '').length > 500) {
              return 'Le motif ne doit pas dépasser 500 caractères.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.errorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: AppColors.errorColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submit,
        icon: _isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.send_rounded, size: 18),
        label: Text(_isSubmitting ? 'Envoi en cours...' : 'Envoyer la demande'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.prosocGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryPreview() {
    if (_isLoadingHistory) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.prosocGreen),
        ),
      );
    }

    if (_historyError != null) {
      return ProsocResourceErrorView(
        message: _historyError!,
        onRetry: _loadHistory,
      );
    }

    if (_demandes.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.inbox_outlined,
        title: 'Aucune demande',
        subtitle: 'Vous n\'avez encore jamais demandé de rechargement.',
      );
    }

    final recent = _demandes.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Demandes récentes',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            TextButton(onPressed: _openHistory, child: const Text('Tout voir')),
          ],
        ),
        ...recent.map((demande) => _DemandeRechargeTile(demande: demande)),
      ],
    );
  }
}

class _DemandeRechargeTile extends StatelessWidget {
  final DemandeRechargeWalletVirtuel demande;

  const _DemandeRechargeTile({required this.demande});

  @override
  Widget build(BuildContext context) {
    final date = demande.dateDemande ?? demande.dateCreation;
    final dateLabel = date == null
        ? '—'
        : DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'N°${demande.idDemande}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              _StatutBadge(demande: demande),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            demande.formattedMontantCalcule,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.prosocGreen,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            dateLabel,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          if (demande.isRejetee && demande.motifRejet.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Motif du rejet : ${demande.motifRejet}',
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.errorColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatutBadge extends StatelessWidget {
  final DemandeRechargeWalletVirtuel demande;

  const _StatutBadge({required this.demande});

  @override
  Widget build(BuildContext context) {
    final (Color color, Color background) = switch (demande.statutLabel) {
      'Confirmée' => (AppColors.prosocGreen, const Color(0xFFE8F5E9)),
      'Rejetée' => (AppColors.errorColor, const Color(0xFFFDECEA)),
      'Annulée' => (Colors.grey[700]!, Colors.grey.shade200),
      _ => (const Color(0xFFB26A00), const Color(0xFFFFF3E0)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        demande.statutLabel,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DemandesRechargeHistoryScreen extends StatefulWidget {
  const _DemandesRechargeHistoryScreen();

  @override
  State<_DemandesRechargeHistoryScreen> createState() =>
      _DemandesRechargeHistoryScreenState();
}

class _DemandesRechargeHistoryScreenState
    extends State<_DemandesRechargeHistoryScreen> {
  bool _isLoading = true;
  String? _error;
  List<DemandeRechargeWalletVirtuel> _demandes = const [];

  /// Devise principale configurée (cohérente avec le wallet virtuel crédité).
  ResolvedDevise _devise = DevisePrincipaleResolver.usdFallback;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final agentId = AuthService.currentUser?.utilisateur.agentId;
    if (agentId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Agent non identifié. Reconnectez-vous.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final devise = await DevisePrincipaleResolver.resolve();

    try {
      final response = await ApiService.getDemandesRechargeWalletByAgent(
        agentId,
      );
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (response.success && response.data != null) {
          _devise = devise;
          _demandes = response.data!
              .map(
                (d) => d.withDevise(
                  deviseId: _devise.deviseId,
                  deviseCode: _devise.deviseCode,
                  deviseSymbole: _devise.deviseSymbole,
                ),
              )
              .toList();
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
        'DemandesRechargeHistoryScreen',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Mes demandes de rechargement',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.prosocGreen),
      );
    }

    if (_error != null) {
      return ProsocResourceErrorView(message: _error!, onRetry: _load);
    }

    if (_demandes.isEmpty) {
      return EmptyStateScrollable(
        icon: Icons.inbox_outlined,
        title: 'Aucune demande',
        subtitle: 'Vous n\'avez encore jamais demandé de rechargement.',
        header: const SizedBox(height: 24),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _demandes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) =>
          _DemandeRechargeTile(demande: _demandes[index]),
    );
  }
}
