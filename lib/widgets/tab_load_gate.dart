import 'package:flutter/material.dart';

/// Monte l'enfant uniquement après la première visite de l'onglet (évite les appels API simultanés).
class TabLoadGate extends StatefulWidget {
  final int tabIndex;
  final int currentIndex;
  final Widget child;

  const TabLoadGate({
    super.key,
    required this.tabIndex,
    required this.currentIndex,
    required this.child,
  });

  @override
  State<TabLoadGate> createState() => _TabLoadGateState();
}

class _TabLoadGateState extends State<TabLoadGate> {
  bool _activated = false;

  @override
  void didUpdateWidget(covariant TabLoadGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_activated && widget.currentIndex == widget.tabIndex) {
      _activated = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_activated && widget.currentIndex != widget.tabIndex) {
      return const SizedBox.shrink();
    }
    if (!_activated) {
      _activated = true;
    }
    return widget.child;
  }
}
