import 'package:flutter/material.dart';

import '../../../config/colors.dart';
import '../../../services/auth_service.dart';
import '../at/change_password_screen.dart';

class SuperviseurProfileScreen extends StatelessWidget {
  final VoidCallback? onLogout;

  const SuperviseurProfileScreen({super.key, this.onLogout});

  void _showPasswordChangeDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer le mot de passe'),
        content: const Text(
          'Vous devez changer votre mot de passe pour continuer à utiliser l\'application.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => const ChangePasswordScreen(),
                ),
              );
            },
            child: const Text('Changer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.currentUser;
    final userName = currentUser?.utilisateur.nomComplet ?? 'Superviseur';
    final userRole = currentUser?.nomRole ?? 'Superviseur';
    final userEmail = currentUser?.utilisateur.email ?? '';
    final userPhone = currentUser?.utilisateur.telephone ?? '';
    final agentId = currentUser?.utilisateur.agentId;
    final doitChangerMotDePasse = currentUser?.doitChangerMotDePasse ?? false;
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'S';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.prosocGreen,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.prosocGreen,
                      AppColors.prosocGreen.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              if (doitChangerMotDePasse)
                IconButton(
                  icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  onPressed: () => _showPasswordChangeDialog(context),
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -40),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.prosocGreen.withValues(alpha: 0.12),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.prosocGreen,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    userRole,
                    style: TextStyle(color: Colors.grey[600], fontSize: 15),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        if (doitChangerMotDePasse)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: Colors.orange.shade700, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Veuillez changer votre mot de passe',
                                    style: TextStyle(
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _showPasswordChangeDialog(context),
                                  child: const Text('Changer'),
                                ),
                              ],
                            ),
                          ),
                        _infoCard(
                          children: [
                            if (userEmail.isNotEmpty)
                              _infoRow(Icons.email_outlined, 'Email', userEmail),
                            if (userPhone.isNotEmpty)
                              _infoRow(Icons.phone_outlined, 'Téléphone', userPhone),
                            if (agentId != null)
                              _infoRow(Icons.badge_outlined, 'Agent ID', '$agentId'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _infoCard(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.lock_outline),
                              title: const Text('Changer le mot de passe'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push<void>(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (context) =>
                                        const ChangePasswordScreen(),
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.logout, color: Colors.red),
                              title: const Text(
                                'Déconnexion',
                                style: TextStyle(color: Colors.red),
                              ),
                              onTap: onLogout,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({required List<Widget> children}) {
    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: AppColors.prosocGreen),
      title: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
