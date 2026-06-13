import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';
import 'cotisationsScreen.dart';

/// Onglet cotisations — enveloppe [ContributionsScreen] avec l'ID affilié connecté.
class AdherentContributionsTabScreen extends StatelessWidget {
  const AdherentContributionsTabScreen({super.key});

  static ({String nom, String prenom}) _splitName(String full) {
    final parts = full.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return (nom: '', prenom: '');
    if (parts.length == 1) return (nom: parts.first, prenom: '');
    return (nom: parts.sublist(1).join(' '), prenom: parts.first);
  }

  @override
  Widget build(BuildContext context) {
    final affilieId = AuthService.affilieId;
    if (affilieId == null || affilieId <= 0) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mes cotisations'),
          backgroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Impossible d\'afficher les cotisations : profil affilié non lié à ce compte.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ),
      );
    }

    final fullName = AuthService.userName ?? '';
    final names = _splitName(fullName);

    return ContributionsScreen(
      affilieId: affilieId,
      affilieNom: names.nom,
      affiliePrenom: names.prenom,
    );
  }
}
