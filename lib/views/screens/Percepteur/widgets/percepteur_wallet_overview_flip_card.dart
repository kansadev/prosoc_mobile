import 'dart:math' show pi;

import 'package:flutter/material.dart';

import '../../../../config/colors.dart';
import '../../../../models/dashboard_percepteur_model.dart';
import '../../../../models/wallet_agent_model.dart';
import '../../../widgets/prosoc_shimmer_loading.dart';
import '../../../widgets/wallet_devise_switch.dart';

/// Carte recto-verso : recto = wallet agent, verso = vue d'ensemble percepteur.
class PercepteurWalletOverviewFlipCard extends StatefulWidget {
  final WalletAgentModel? wallet;
  final bool isLoadingWallet;
  final bool isUsdSelected;
  final ValueChanged<bool>? onDeviseChanged;
  final VoidCallback? onOpenWallet;
  final DashboardPercepteurModel? dashboard;
  final Set<int>? availableDeviseIds;
  final bool enableAllDevises;
  final String? walletUnavailableMessage;

  const PercepteurWalletOverviewFlipCard({
    super.key,
    this.wallet,
    this.isLoadingWallet = false,
    this.isUsdSelected = false,
    this.onDeviseChanged,
    this.onOpenWallet,
    this.dashboard,
    this.availableDeviseIds,
    this.enableAllDevises = false,
    this.walletUnavailableMessage,
  });

  @override
  State<PercepteurWalletOverviewFlipCard> createState() =>
      _PercepteurWalletOverviewFlipCardState();
}

class _PercepteurWalletOverviewFlipCardState
    extends State<PercepteurWalletOverviewFlipCard>
    with SingleTickerProviderStateMixin {
  static const double _cardHeight = 240;

  late final AnimationController _controller;
  late final Animation<double> _animation;
  bool _showOverview = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _animation = Tween<double>(
      begin: 0,
      end: pi,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_showOverview) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() => _showOverview = !_showOverview);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _cardHeight,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value;
          final showBack = angle >= pi / 2;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: showBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _buildOverviewFace(),
                  )
                : _buildWalletFace(),
          );
        },
      ),
    );
  }

  Widget _buildWalletFace() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onOpenWallet,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: widget.isLoadingWallet && widget.wallet == null
                ? ProsocHomeShimmer.walletOnPrimary(context)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Mon Wallet',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          _FlipButton(onPressed: _flip),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              (widget.wallet?.statut ?? true)
                                  ? 'Actif'
                                  : 'Inactif',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Text(
                        'Solde disponible',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      if (widget.walletUnavailableMessage != null)
                        Text(
                          widget.walletUnavailableMessage!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        )
                      else
                        Text(
                          widget.wallet?.formattedSolde ?? '0.00',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Matricule',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  widget.wallet?.agentMatricule ?? '—',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.onDeviseChanged != null)
                            WalletDeviseSwitch(
                              isUsdSelected: widget.isUsdSelected,
                              availableDeviseIds: widget.availableDeviseIds,
                              enableAllDevises: widget.enableAllDevises,
                              onChanged: widget.onDeviseChanged!,
                            ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewFace() {
    final dashboard = widget.dashboard;
    final kpis = dashboard?.kpis;
    final formatMontant = kpis?.formatMontant ??
        (double value) => dashboard?.formatMontant(value) ?? '0 CDF';

    final montantTotal = kpis?.formattedMontantTotal ?? formatMontant(0);
    final montantMois = kpis?.formattedMontantMois ?? formatMontant(0);
    final agentsActifs = kpis?.nombreAgentsActifs ?? 0;
    final transactionsEnAttente = dashboard?.transactionsEnAttente ?? 0;
    final montantEnAttente = dashboard?.montantEnAttente ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _flip,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.prosocGreen,
                AppColors.prosocGreen.withValues(alpha: 0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.prosocGreen.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Vue percepteur',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),
                    _FlipButton(onPressed: _flip),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Percepteur',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  montantTotal,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total perçu',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                if (dashboard != null && dashboard.soldeAPercevoir > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'À percevoir : ${formatMontant(dashboard.soldeAPercevoir)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (transactionsEnAttente > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '$transactionsEnAttente en attente (${formatMontant(montantEnAttente)})',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const Spacer(),
                Row(
                  children: [
                    _miniStat('Ce mois', montantMois),
                    const SizedBox(width: 8),
                    _miniStat('Agents actifs', '$agentsActifs'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 9),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlipButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _FlipButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.flip, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
