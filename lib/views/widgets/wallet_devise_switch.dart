import 'package:flutter/material.dart';

import '../../config/colors.dart';

import '../../models/wallet_agent_model.dart';

/// Bascule CDF / USD pour les wallets agent multi-devises.
class WalletDeviseSwitch extends StatelessWidget {
  final bool isUsdSelected;
  final ValueChanged<bool> onChanged;
  final Set<int>? availableDeviseIds;

  const WalletDeviseSwitch({
    super.key,
    required this.isUsdSelected,
    required this.onChanged,
    this.availableDeviseIds,
  });

  bool get _cdfEnabled =>
      availableDeviseIds == null ||
      availableDeviseIds!.contains(WalletAgentDeviseIds.cdf);

  bool get _usdEnabled =>
      availableDeviseIds == null ||
      availableDeviseIds!.contains(WalletAgentDeviseIds.usd);

  bool get _showSwitch {
    if (availableDeviseIds == null) return true;
    return _cdfEnabled && _usdEnabled;
  }

  @override
  Widget build(BuildContext context) {
    if (!_showSwitch) {
      final label = isUsdSelected ? 'USD' : 'CDF';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption(
            label: 'CDF',
            selected: !isUsdSelected,
            enabled: _cdfEnabled,
            onTap: () => onChanged(false),
          ),
          _buildOption(
            label: 'USD',
            selected: isUsdSelected,
            enabled: _usdEnabled,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required String label,
    required bool selected,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: !enabled
                ? Colors.white38
                : selected
                    ? AppColors.prosocGreen
                    : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
