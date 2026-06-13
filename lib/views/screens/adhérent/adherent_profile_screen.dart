import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../config/api.dart';
import '../../../config/colors.dart';
import '../../../models/dashboard_affilie_model.dart';
import '../../../services/auth_service.dart';
import '../../../utils/api_error_helper.dart';
import '../../../utils/formatters.dart';
import '../../../utils/photo_url_helper.dart';
import '../at/change_password_screen.dart';
import '../at/edit_profile_screen.dart';

/// Profil affilié connecté — vue compacte.
class AdherentProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final VoidCallback? onOpenDependants;

  const AdherentProfileScreen({
    super.key,
    required this.onLogout,
    this.onOpenDependants,
  });

  @override
  State<AdherentProfileScreen> createState() => _AdherentProfileScreenState();
}

class _AdherentProfileScreenState extends State<AdherentProfileScreen> {
  DashboardAffilieResumeModel? _data;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile({bool silent = false}) async {
    final affilieId = AuthService.affilieId;
    if (affilieId == null || affilieId <= 0) {
      setState(() {
        _errorMessage =
            'Profil affilié introuvable. Reconnectez-vous ou contactez le support.';
        _isLoading = false;
      });
      return;
    }

    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await ApiService.getDashboardAffilieResume(affilieId);
      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _data = response.data;
          _errorMessage = null;
          _isLoading = false;
        });
      } else {
        setState(() {
          if (!silent || _data == null) {
            _errorMessage =
                response.message ??
                ApiErrorHelper.userFacingMessage(
                  statusCode: response.statusCode,
                );
          }
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('AdherentProfile', e, stackTrace, false);
      if (!mounted) return;
      setState(() {
        if (!silent || _data == null) {
          _errorMessage = ApiErrorHelper.userFacingNetwork();
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _openEditProfile() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
    );
    if (updated == true && mounted) {
      setState(() {});
      _loadProfile(silent: true);
    }
  }

  void _openChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
    );
  }

  void _openDependants() {
    if (widget.onOpenDependants != null) {
      widget.onOpenDependants!();
    }
  }

  String _displayName() {
    final fromApi = _data?.informations.nomComplet.trim();
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;
    return AuthService.userName ?? 'Adhérent';
  }

  String? _photoUrl() {
    return PhotoUrlHelper.resolve(
      AuthService.currentUser?.utilisateur.photoUrl,
    );
  }

  Widget _profileAvatarPlaceholder() {
    return Icon(
      Icons.person_outline,
      size: 36,
      color: AppColors.prosocGreen.withValues(alpha: 0.7),
    );
  }

  Widget _buildAvatar(String? url) {
    return CircleAvatar(
      radius: 32,
      backgroundColor: AppColors.prosocGreen.withValues(alpha: 0.1),
      child: url != null
          ? ClipOval(
              child: Image.network(
                url,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                headers: PhotoUrlHelper.networkHeaders(url),
                errorBuilder: (_, __, ___) => _profileAvatarPlaceholder(),
              ),
            )
          : _profileAvatarPlaceholder(),
    );
  }

  Widget _compactRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final empty = value.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.prosocGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Flexible(
            child: Text(
              empty ? '—' : value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: empty ? Colors.grey.shade400 : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? trailing,
    Color? titleColor,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, size: 22, color: iconColor ?? AppColors.prosocGreen),
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
              if (trailing != null)
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.prosocGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    trailing,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.prosocGreen,
                    ),
                  ),
                ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.currentUser;
    final utilisateur = currentUser?.utilisateur;
    final userName = _displayName();
    final userPhotoUrl = _photoUrl();
    final nomUtilisateur = utilisateur?.nomUtilisateur ?? '';
    final userRole = currentUser?.nomRole ?? 'Adhérent';
    final doitChangerMotDePasse = currentUser?.doitChangerMotDePasse ?? false;
    final info = _data?.informations;
    final estActif = info?.estActif ?? _data?.kpis.estActif ?? true;
    final dependantsCount = info?.nombreBeneficiaires ?? 0;

    final userEmail = info?.email.trim().isNotEmpty == true
        ? info!.email
        : (utilisateur?.email ?? '');
    final userPhone = info?.telephone.trim().isNotEmpty == true
        ? info!.telephone
        : (utilisateur?.telephone ?? '');

    if (_isLoading && _data == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text('Mon profil'),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
        ),
        body: _buildLoading(),
      );
    }

    if (_errorMessage != null && _data == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text('Mon profil'),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadProfile,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.prosocGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Mon profil'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          if (doitChangerMotDePasse)
            IconButton(
              icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              onPressed: _openChangePassword,
              tooltip: 'Changer le mot de passe',
            ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _openEditProfile,
            tooltip: 'Modifier',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.prosocGreen,
        onRefresh: () => _loadProfile(silent: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  _buildAvatar(userPhotoUrl),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (nomUtilisateur.trim().isNotEmpty)
                          Text(
                            '@${nomUtilisateur.trim()}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _badge(userRole, AppColors.prosocGreen),
                            if (info?.codeAdhesion.isNotEmpty == true)
                              _badge(info!.codeAdhesion, Colors.blue.shade700),
                            _badge(
                              estActif ? 'Actif' : 'Inactif',
                              estActif ? AppColors.prosocGreen : Colors.red,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (doitChangerMotDePasse) ...[
              const SizedBox(height: 10),
              Material(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _openChangePassword,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
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
                            'Mot de passe à changer',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _card(
              title: 'Coordonnées',
              children: [
                _compactRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: userEmail,
                ),
                _compactRow(
                  icon: Icons.phone_outlined,
                  label: 'Téléphone',
                  value: userPhone,
                ),
                if (utilisateur?.referenceUtilisateur.isNotEmpty == true)
                  _compactRow(
                    icon: Icons.qr_code_2_outlined,
                    label: 'Référence',
                    value: utilisateur!.referenceUtilisateur,
                  ),
              ],
            ),
            if (info != null)
              _card(
                title: 'Adhésion',
                children: [
                  _compactRow(
                    icon: Icons.badge_outlined,
                    label: 'Code',
                    value: info.codeAdhesion,
                  ),
                  _compactRow(
                    icon: Icons.verified_outlined,
                    label: 'Statut',
                    value: info.statutAdhesion,
                  ),
                  if (info.typeAdhesion.trim().isNotEmpty)
                    _compactRow(
                      icon: Icons.category_outlined,
                      label: 'Type',
                      value: info.typeAdhesion,
                    ),
                  if (info.dateAdhesion != null)
                    _compactRow(
                      icon: Icons.event_outlined,
                      label: 'Depuis',
                      value: AppFormatters.formatDate(info.dateAdhesion),
                    ),
                  if (info.communeResidence.trim().isNotEmpty ||
                      info.provinceResidence.trim().isNotEmpty)
                    _compactRow(
                      icon: Icons.location_on_outlined,
                      label: 'Résidence',
                      value: [
                        info.communeResidence,
                        info.provinceResidence,
                      ].where((s) => s.trim().isNotEmpty).join(', '),
                    ),
                ],
              ),
            _card(
              title: 'Compte',
              children: [
                _menuTile(
                  icon: Icons.people_outline,
                  title: 'Personnes à charge',
                  trailing: dependantsCount > 0 ? '$dependantsCount' : null,
                  onTap: _openDependants,
                ),
                const Divider(height: 1),
                _menuTile(
                  icon: Icons.lock_outline,
                  title: 'Changer le mot de passe',
                  onTap: _openChangePassword,
                ),
                const Divider(height: 1),
                _menuTile(
                  icon: Icons.logout,
                  title: 'Déconnexion',
                  iconColor: Colors.red,
                  titleColor: Colors.red,
                  onTap: widget.onLogout,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
