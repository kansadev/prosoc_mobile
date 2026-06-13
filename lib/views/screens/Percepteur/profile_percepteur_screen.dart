import 'package:flutter/material.dart';
import '../../../config/colors.dart';
import '../../../services/auth_service.dart';
import '../at/change_password_screen.dart';

// ============================================
// ÉCRAN PROFIL PERCEPTEUR
// ============================================
class ProfilePercepteurScreen extends StatelessWidget {
  final VoidCallback? onLogout;

  const ProfilePercepteurScreen({super.key, this.onLogout});

  Widget _buildProfileAvatar({
    required String userName,
    required String? userPhotoUrl,
  }) {
    final trimmed = userName.trim();
    final initial = trimmed.isNotEmpty ? trimmed[0].toUpperCase() : 'P';

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
      ),
      child: CircleAvatar(
        radius: 45,
        backgroundColor: Colors.grey[200],
        backgroundImage: userPhotoUrl != null && userPhotoUrl.isNotEmpty
            ? NetworkImage(userPhotoUrl)
            : null,
        child: userPhotoUrl == null || userPhotoUrl.isEmpty
            ? Text(
                initial,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.prosocGreen,
                ),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.currentUser;
    final userName = currentUser?.utilisateur.nomComplet ?? 'Percepteur';
    final userRole = currentUser?.nomRole ?? 'Non défini';
    final userEmail = currentUser?.utilisateur.email ?? '';
    final userPhone = currentUser?.utilisateur.telephone ?? '';
    final userPhotoUrl = currentUser?.utilisateur.photoUrl;
    final agentId = currentUser?.utilisateur.agentId;
    final referenceUtilisateur =
        currentUser?.utilisateur.referenceUtilisateur ?? '';
    final nomUtilisateur = currentUser?.utilisateur.nomUtilisateur ?? '';
    final userId = currentUser?.utilisateur.idUtilisateur;
    final statutUtilisateur = currentUser?.utilisateur.statut ?? true;
    final isConnecte = currentUser?.utilisateur.isConnecte ?? false;
    final acceptNotification = currentUser?.acceptNotification ?? false;
    final dateCreation = currentUser?.utilisateur.dateCreation;
    final doitChangerMotDePasse = currentUser?.doitChangerMotDePasse ?? false;
    final permissions = currentUser?.permissions ?? [];
    final roles = currentUser?.roles ?? [];
    final primaryRole = currentUser?.primaryRole;

    // Formater la date d'adhésion
    String memberSince = "Membre depuis";
    if (dateCreation != null) {
      final months = [
        'janvier',
        'février',
        'mars',
        'avril',
        'mai',
        'juin',
        'juillet',
        'août',
        'septembre',
        'octobre',
        'novembre',
        'décembre',
      ];
      memberSince =
          "Membre depuis ${months[dateCreation.month - 1]} ${dateCreation.year}";
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Header style Twitter (Bannière + Back button)
          SliverAppBar(
            expandedHeight: 160,
            backgroundColor: AppColors.prosocGreen,
            floating: false,
            pinned: true,
            elevation: 0,
            clipBehavior: Clip.none,
            flexibleSpace: Stack(
              clipBehavior: Clip.none,
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.prosocGreen,
                        AppColors.prosocGreen.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: -45,
                  child: _buildProfileAvatar(
                    userName: userName,
                    userPhotoUrl: userPhotoUrl,
                  ),
                ),
              ],
            ),
            actions: [
              // Indicateur de mot de passe à changer
              if (doitChangerMotDePasse)
                IconButton(
                  icon: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                  ),
                  onPressed: () {
                    _showPasswordChangeDialog(context);
                  },
                  tooltip: 'Changer le mot de passe',
                ),
            ],
          ),

          // Contenu du profil
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      child: const Text(
                        "Modifier le profil",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Nom et Role
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    userRole,
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 15),

                  // Infos rapides
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            memberSince,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Alerte mot de passe à changer
                  if (doitChangerMotDePasse)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Veuillez changer votre mot de passe',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _showPasswordChangeDialog(context);
                            },
                            child: const Text('Changer'),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 25),

                  // Onglets factices (Twitter Style: Tweets, Media, Likes...)
                  const Divider(thickness: 0.5),

                  _buildTwitterRow(
                    Icons.email_outlined,
                    userEmail.isNotEmpty ? userEmail : "Email non renseigné",
                  ),
                  _buildTwitterRow(
                    Icons.phone_outlined,
                    userPhone.isNotEmpty
                        ? userPhone
                        : "Téléphone non renseigné",
                  ),

                  // Afficher la description du rôle principal
                  if (primaryRole != null && primaryRole.description.isNotEmpty)
                    _buildTwitterRow(
                      Icons.badge_outlined,
                      primaryRole.description,
                    ),

                  // Infos compte utilisateur (basées sur l'utilisateur connecté)
                  _buildTwitterRow(
                    Icons.alternate_email_outlined,
                    nomUtilisateur.trim().isNotEmpty
                        ? 'Nom utilisateur: $nomUtilisateur'
                        : 'Nom utilisateur non renseigné',
                  ),
                  _buildTwitterRow(
                    Icons.qr_code_2_outlined,
                    referenceUtilisateur.trim().isNotEmpty
                        ? 'Référence: $referenceUtilisateur'
                        : 'Référence non renseigné',
                  ),
                  _buildTwitterRow(
                    Icons.numbers,
                    agentId != null ? 'ID Agent: $agentId' : 'ID Agent non défini',
                  ),
                  _buildTwitterRow(
                    statutUtilisateur
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    statutUtilisateur ? 'Compte actif' : 'Compte inactif',
                  ),
                  _buildTwitterRow(
                    isConnecte ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                    isConnecte ? 'Connecté' : 'Hors ligne',
                  ),
                  _buildTwitterRow(
                    acceptNotification
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                    acceptNotification
                        ? 'Notifications activées'
                        : 'Notifications désactivées',
                  ),

                  // Section Rôles
                  if (roles.isNotEmpty) ...[
                    const Divider(thickness: 0.5),
                    const SizedBox(height: 8),
                    const Text(
                      'Rôles',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: roles
                          .map(
                            (role) => Chip(
                              label: Text(
                                role.description,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: AppColors.prosocGreen
                                  .withValues(alpha: 0.1),
                              side: BorderSide.none,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Section Permissions (afficher les 5 premières)
                  if (permissions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Permissions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '${permissions.length} total',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children:
                          (permissions.length > 5
                                  ? permissions.take(5)
                                  : permissions)
                              .map(
                                (perm) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    perm,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                    if (permissions.length > 5)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '+${permissions.length - 5} autres permissions',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],

                  const Divider(thickness: 0.5),

                  // Menu d'options
                  _buildListMenu(Icons.notifications_none, "Notifications"),
                  _buildListMenu(
                    Icons.lock_outline,
                    "Sécurité et accès",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                  ),
                  _buildListMenu(Icons.help_outline, "Centre d'assistance"),
                  _buildListMenu(
                    Icons.logout,
                    "Déconnexion",
                    isDestructive: true,
                    onTap: () async {
                      final logoutCallback = onLogout;
                      await AuthService.logout();
                      if (logoutCallback != null) {
                        logoutCallback();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour les lignes d'info simples (Email, Tel)
  Widget _buildTwitterRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: value.toLowerCase().contains('non renseigné')
                    ? Colors.grey.shade400
                    : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour le menu type liste
  Widget _buildListMenu(
    IconData icon,
    String title, {
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.black87),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : Colors.black87,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
    );
  }

  // Dialog pour le changement de mot de passe
  void _showPasswordChangeDialog(BuildContext context) {
    showDialog(
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
              Navigator.push(
                context,
                MaterialPageRoute(
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
}
