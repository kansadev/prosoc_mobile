import 'package:flutter/material.dart';

import '../../../config/colors.dart';
import '../../../services/auth_service.dart';
import '../at/change_password_screen.dart';
import 'edit_percepteur_profile_screen.dart';

// ============================================
// ÉCRAN PROFIL PERCEPTEUR
// ============================================
class ProfilePercepteurScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const ProfilePercepteurScreen({super.key, this.onLogout});

  @override
  State<ProfilePercepteurScreen> createState() =>
      _ProfilePercepteurScreenState();
}

class _ProfilePercepteurScreenState extends State<ProfilePercepteurScreen> {

  static const double _headerBandHeight = 120;
  static const double _avatarRadius = 45;
  static const double _avatarOverlap = 45;

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: _avatarRadius,
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

  String _memberSince(DateTime? dateCreation) {
    if (dateCreation == null) return 'Membre Prosoc';
    const months = [
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
    return 'Membre depuis ${months[dateCreation.month - 1]} ${dateCreation.year}';
  }

  Future<void> _openEditProfile() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const EditPercepteurProfileScreen(),
      ),
    );
    if (updated == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.currentUser;
    final userName = currentUser?.utilisateur.nomComplet ?? 'Percepteur';
    final userRole = currentUser?.nomRole ?? 'Non défini';
    final userEmail = currentUser?.utilisateur.email ?? '';
    final userPhone = currentUser?.utilisateur.telephone ?? '';
    final userPhotoUrl = currentUser?.utilisateur.photoUrl;
    final referenceUtilisateur =
        currentUser?.utilisateur.referenceUtilisateur ?? '';
    final nomUtilisateur = currentUser?.utilisateur.nomUtilisateur ?? '';
    final statutUtilisateur = currentUser?.utilisateur.statut ?? true;
    final acceptNotification = currentUser?.acceptNotification ?? false;
    final dateCreation = currentUser?.utilisateur.dateCreation;
    final doitChangerMotDePasse = currentUser?.doitChangerMotDePasse ?? false;
    final roles = currentUser?.roles ?? [];
    final primaryRole = currentUser?.primaryRole;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          _buildFixedHeader(
            context: context,
            userName: userName,
            userPhotoUrl: userPhotoUrl,
            doitChangerMotDePasse: doitChangerMotDePasse,
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      onPressed: _openEditProfile,
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        backgroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Modifier le profil',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
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
                      letterSpacing: -0.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userRole,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _memberSince(dateCreation),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (doitChangerMotDePasse) ...[
                    const SizedBox(height: 16),
                    _buildPasswordAlert(context),
                  ],
                  const SizedBox(height: 24),
                  _sectionCard(
                    title: 'Coordonnées',
                    children: [
                      _infoTile(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: userEmail,
                      ),
                      _infoTile(
                        icon: Icons.phone_outlined,
                        label: 'Téléphone',
                        value: userPhone,
                      ),
                      if (nomUtilisateur.trim().isNotEmpty)
                        _infoTile(
                          icon: Icons.alternate_email_outlined,
                          label: 'Identifiant',
                          value: nomUtilisateur,
                        ),
                      if (referenceUtilisateur.trim().isNotEmpty)
                        _infoTile(
                          icon: Icons.qr_code_2_outlined,
                          label: 'Référence',
                          value: referenceUtilisateur,
                        ),
                    ],
                  ),
                  _sectionCard(
                    title: 'Compte',
                    children: [
                      if (primaryRole != null &&
                          primaryRole.description.isNotEmpty)
                        _infoTile(
                          icon: Icons.badge_outlined,
                          label: 'Rôle principal',
                          value: primaryRole.description,
                        ),
                      _infoTile(
                        icon: statutUtilisateur
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                        label: 'Statut',
                        value: statutUtilisateur ? 'Actif' : 'Inactif',
                      ),
                      _infoTile(
                        icon: acceptNotification
                            ? Icons.notifications_active_outlined
                            : Icons.notifications_off_outlined,
                        label: 'Notifications',
                        value: acceptNotification ? 'Activées' : 'Désactivées',
                      ),
                    ],
                  ),
                  if (roles.isNotEmpty)
                    _sectionCard(
                      title: 'Rôles',
                      children: [
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
                      ],
                    ),
                  _sectionCard(
                    title: 'Paramètres',
                    children: [
                      _actionTile(
                        icon: Icons.lock_outline_rounded,
                        title: 'Sécurité et accès',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ChangePasswordScreen(),
                            ),
                          );
                        },
                      ),
                      _actionTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Centre d\'assistance',
                        onTap: () {},
                      ),
                      _actionTile(
                        icon: Icons.logout_rounded,
                        title: 'Déconnexion',
                        iconColor: Colors.red,
                        iconBgColor: Colors.red.withValues(alpha: 0.1),
                        titleColor: Colors.red,
                        showChevron: false,
                        onTap: () async {
                          final logoutCallback = widget.onLogout;
                          await AuthService.logout();
                          logoutCallback?.call();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedHeader({
    required BuildContext context,
    required String userName,
    required String? userPhotoUrl,
    required bool doitChangerMotDePasse,
  }) {
    return SizedBox(
      height: _headerBandHeight + _avatarOverlap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _headerBandHeight,
            child: Container(
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
              child: SafeArea(
                bottom: false,
                child: Align(
                  alignment: Alignment.topRight,
                  child: doitChangerMotDePasse
                      ? IconButton(
                          icon: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                          ),
                          onPressed: () => _showPasswordChangeDialog(context),
                          tooltip: 'Changer le mot de passe',
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: _headerBandHeight - _avatarRadius,
            child: _buildProfileAvatar(
              userName: userName,
              userPhotoUrl: userPhotoUrl,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordAlert(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
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
            onPressed: () => _showPasswordChangeDialog(context),
            child: const Text('Changer'),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final empty = value.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.prosocGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.prosocGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  empty ? 'Non renseigné' : value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: empty ? Colors.grey.shade400 : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    Color iconColor = AppColors.prosocGreen,
    Color iconBgColor = const Color(0x1A4CAF50),
    VoidCallback? onTap,
    Color? titleColor,
    bool showChevron = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: titleColor ?? AppColors.textPrimary,
                  ),
                ),
              ),
              if (showChevron)
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }

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
