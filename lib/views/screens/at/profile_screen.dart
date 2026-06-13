import 'package:flutter/material.dart';
import '../../../config/api.dart';
import '../../../config/colors.dart';
import '../../../controllers/main_controller.dart';
import '../../../models/auth_user_model.dart';
import '../../../services/auth_service.dart';
import '../../../utils/api_error_helper.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ProfileController controller;
  final VoidCallback? onLogout;

  const ProfileScreen({super.key, required this.controller, this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isSettingPrimaryRole = false;

  void _refresh() => setState(() {});

  Future<void> _openEditProfile() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
    );
    if (updated == true && mounted) _refresh();
  }

  Future<void> _setPrimaryRole(RoleModel role) async {
    final userId = AuthService.userId;
    final currentUser = AuthService.currentUser;
    if (userId == null || currentUser == null) return;
    if (currentUser.primaryRole.idRole == role.idRole) return;

    setState(() => _isSettingPrimaryRole = true);

    try {
      final response = await ApiService.setUtilisateurPrimaryRole(
        id: userId,
        roleId: role.idRole,
      );

      if (!mounted) return;

      if (response.success) {
        await AuthService.applyPrimaryRole(role);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Rôle principal : ${role.description}'),
              backgroundColor: AppColors.prosocGreen,
            ),
          );
          _refresh();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.message ??
                  ApiErrorHelper.userFacingMessage(
                    statusCode: response.statusCode,
                  ),
            ),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('Profile/primaryRole', e, stackTrace, false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiErrorHelper.userFacingNetwork()),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSettingPrimaryRole = false);
    }
  }

  Widget _buildProfileAvatar({
    required String userName,
    required String? userPhotoUrl,
  }) {
    final trimmed = userName.trim();
    final initial = trimmed.isNotEmpty ? trimmed[0].toUpperCase() : 'A';

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
        radius: 48,
        backgroundColor: Colors.grey[200],
        backgroundImage: userPhotoUrl != null && userPhotoUrl.isNotEmpty
            ? NetworkImage(userPhotoUrl)
            : null,
        child: userPhotoUrl == null || userPhotoUrl.isEmpty
            ? Text(
                initial,
                style: const TextStyle(
                  fontSize: 34,
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
    required Color iconColor,
    required Color iconBgColor,
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

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
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

  void _showPasswordChangeDialog() {
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
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.prosocGreen,
            ),
            child: const Text('Changer maintenant'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.currentUser;
    final userName = currentUser?.utilisateur.nomComplet ?? 'Agent';
    final userRole = currentUser?.nomRole ?? 'Non défini';
    final userEmail = currentUser?.utilisateur.email ?? '';
    final userPhone = currentUser?.utilisateur.telephone ?? '';
    final userPhotoUrl = currentUser?.utilisateur.photoUrl;
    final referenceUtilisateur =
        currentUser?.utilisateur.referenceUtilisateur ?? '';
    final nomUtilisateur = currentUser?.utilisateur.nomUtilisateur ?? '';
    final statutUtilisateur = currentUser?.utilisateur.statut ?? true;
    final dateCreation = currentUser?.utilisateur.dateCreation;
    final doitChangerMotDePasse = currentUser?.doitChangerMotDePasse ?? false;
    final roles = currentUser?.roles ?? [];
    final primaryRole = currentUser?.primaryRole;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150,
            backgroundColor: AppColors.prosocGreen,
            pinned: true,
            elevation: 0,
            clipBehavior: Clip.none,
            automaticallyImplyLeading: false,
            flexibleSpace: Stack(
              clipBehavior: Clip.none,
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                ),
                Positioned(
                  left: 20,
                  bottom: -48,
                  child: _buildProfileAvatar(
                    userName: userName,
                    userPhotoUrl: userPhotoUrl,
                  ),
                ),
              ],
            ),
            actions: [
              if (doitChangerMotDePasse)
                IconButton(
                  icon: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                  ),
                  onPressed: _showPasswordChangeDialog,
                  tooltip: 'Changer le mot de passe',
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 64, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: _openEditProfile,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Modifier'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (nomUtilisateur.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '@${nomUtilisateur.trim()}',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.prosocGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      userRole,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.prosocGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
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
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  if (doitChangerMotDePasse) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Veuillez changer votre mot de passe',
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _showPasswordChangeDialog,
                            child: const Text('Changer'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _sectionCard(
                    title: 'Informations',
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
                      _infoTile(
                        icon: Icons.qr_code_2_outlined,
                        label: 'Référence',
                        value: referenceUtilisateur,
                      ),
                      _infoTile(
                        icon: statutUtilisateur
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                        label: 'Statut du compte',
                        value: statutUtilisateur ? 'Actif' : 'Inactif',
                      ),
                    ],
                  ),
                  if (roles.isNotEmpty)
                    _sectionCard(
                      title: 'Rôles',
                      children: [
                        if (_isSettingPrimaryRole)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: LinearProgressIndicator(
                              color: AppColors.prosocGreen,
                            ),
                          ),
                        Text(
                          'Appuyez sur un rôle pour le définir comme principal',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: roles.map((role) {
                            final isPrimary =
                                primaryRole?.idRole == role.idRole;
                            return FilterChip(
                              selected: isPrimary,
                              showCheckmark: false,
                              avatar: isPrimary
                                  ? const Icon(
                                      Icons.star_rounded,
                                      size: 18,
                                      color: AppColors.prosocGreen,
                                    )
                                  : null,
                              label: Text(role.description),
                              selectedColor:
                                  AppColors.prosocGreen.withValues(alpha: 0.15),
                              side: BorderSide(
                                color: isPrimary
                                    ? AppColors.prosocGreen
                                    : Colors.grey.shade300,
                              ),
                              onSelected: _isSettingPrimaryRole
                                  ? null
                                  : (_) => _setPrimaryRole(role),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  _sectionCard(
                    title: 'Compte',
                    children: [
                      _actionTile(
                        icon: Icons.lock_outline,
                        title: 'Changer le mot de passe',
                        iconColor: AppColors.prosocGreen,
                        iconBgColor: AppColors.prosocGreen.withValues(alpha: 0.1),
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
                        icon: Icons.logout,
                        title: 'Déconnexion',
                        iconColor: Colors.red,
                        iconBgColor: Colors.red.withValues(alpha: 0.08),
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
}
