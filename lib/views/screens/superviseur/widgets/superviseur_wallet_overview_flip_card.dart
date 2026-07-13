import 'dart:math' show pi;

import 'package:flutter/material.dart';

import '../../../../config/colors.dart';
import '../../../../models/dashboard_superviseur_model.dart';
import '../../../../models/wallet_agent_model.dart';
import '../../../widgets/prosoc_shimmer_loading.dart';
import '../../../widgets/wallet_devise_switch.dart';

/// Carte recto-verso : recto = wallet agent, verso = vue d'ensemble équipe.
class SuperviseurWalletOverviewFlipCard extends StatefulWidget {
  final WalletAgentModel? wallet;
  final bool isLoadingWallet;
  final bool isUsdSelected;
  final ValueChanged<bool>? onDeviseChanged;
  final VoidCallback? onOpenWallet;
  final StatsSuperviseur? kpis;
  final Set<int>? availableDeviseIds;
  final bool enableAllDevises;
  final String? walletUnavailableMessage;

  const SuperviseurWalletOverviewFlipCard({
    super.key,
    this.wallet,
    this.isLoadingWallet = false,
    this.isUsdSelected = false,
    this.onDeviseChanged,
    this.onOpenWallet,
    this.kpis,
    this.availableDeviseIds,
    this.enableAllDevises = false,
    this.walletUnavailableMessage,
  });

  @override
  State<SuperviseurWalletOverviewFlipCard> createState() =>
      _SuperviseurWalletOverviewFlipCardState();
}

class _SuperviseurWalletOverviewFlipCardState
    extends State<SuperviseurWalletOverviewFlipCard>
    with SingleTickerProviderStateMixin {
  static const double _cardHeight = 220;

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
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
        ),
      ],
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
    final kpis = widget.kpis;
    final montant = kpis?.formattedMontantEquipe ?? '—';
    final performance = kpis?.formattedPerformance ?? '—';

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
                        'Vue d\'ensemble équipe',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),
                    _FlipButton(onPressed: _flip),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  montant,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Montant total • Perf. moyenne $performance',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    _miniStat(
                      'Agents directs',
                      '${kpis?.nombreAgentsDirects ?? '—'}',
                    ),
                    const SizedBox(width: 8),
                    _miniStat(
                      'Total équipe',
                      '${kpis?.nombreAgentsTotal ?? '—'}',
                    ),
                    const SizedBox(width: 8),
                    _miniStat('Taux succès', kpis?.formattedTauxSucces ?? '—'),
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

class _FaceIndicator extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _FaceIndicator({
    required this.label,
    required this.isActive,
  }) : onTap = null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.prosocGreen.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppColors.prosocGreen.withValues(alpha: 0.4)
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppColors.prosocGreen : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
