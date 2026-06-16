import 'package:flutter/material.dart';

import '../../../config/api.dart';
import '../../../config/colors.dart';
import '../../../services/auth_service.dart';
import '../../../utils/api_error_helper.dart';
import '../at/change_password_screen.dart';

/// Édition du profil percepteur via GET/PUT /api/Agent/{id}.
class EditPercepteurProfileScreen extends StatefulWidget {
  const EditPercepteurProfileScreen({super.key});

  @override
  State<EditPercepteurProfileScreen> createState() =>
      _EditPercepteurProfileScreenState();
}

class _EditPercepteurProfileScreenState
    extends State<EditPercepteurProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomCompletController;
  late final TextEditingController _matriculeController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _fonctionController;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _roleAgent;
  String? _photoUrl;
  int? _zoneSocialeId;
  int? _categorieAgentId;
  bool _statut = true;

  @override
  void initState() {
    super.initState();
    _nomCompletController = TextEditingController();
    _matriculeController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _fonctionController = TextEditingController();
    _loadAgentProfile();
  }

  @override
  void dispose() {
    _nomCompletController.dispose();
    _matriculeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _fonctionController.dispose();
    super.dispose();
  }

  String _field(Map<String, dynamic> json, String key) {
    final pascal = key.isEmpty ? key : key[0].toUpperCase() + key.substring(1);
    final value = json[key] ?? json[pascal];
    return value?.toString() ?? '';
  }

  int? _intField(Map<String, dynamic> json, String key) {
    final pascal = key.isEmpty ? key : key[0].toUpperCase() + key.substring(1);
    final value = json[key] ?? json[pascal];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  Future<void> _loadAgentProfile() async {
    final agentId = AuthService.agentId;
    if (agentId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Profil agent non lié à ce compte. Contactez votre administrateur.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getAgent(agentId);

      if (!mounted) return;

      if (response.success && response.data != null) {
        final data = response.data!;
        _nomCompletController.text = _field(data, 'nomComplet');
        _matriculeController.text = _field(data, 'matricule');
        _phoneController.text = _field(data, 'phone');
        _emailController.text = _field(data, 'emailAgent');
        _fonctionController.text = _field(data, 'fonction');
        _roleAgent = _field(data, 'roleAgent');
        _photoUrl = _field(data, 'photoUrl');
        _zoneSocialeId = _intField(data, 'zoneSocialeId');
        _categorieAgentId = _intField(data, 'categorieAgentId');
        final statutRaw = data['statut'] ?? data['Statut'];
        _statut = statutRaw is bool ? statutRaw : true;

        setState(() => _isLoading = false);
      } else {
        setState(() {
          _errorMessage = ApiErrorHelper.messageForApiFailure(
            statusCode: response.statusCode,
            serverDetail: response.message,
            fallback: 'Impossible de charger le profil agent.',
          );
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException(
        'EditPercepteurProfile/load',
        e,
        stackTrace,
        false,
      );
      if (!mounted) return;
      setState(() {
        _errorMessage = ApiErrorHelper.userFacingNetwork();
        _isLoading = false;
      });
    }
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.prosocGreen),
      filled: true,
      fillColor: AppColors.cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.prosocGreen, width: 2),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final agentId = AuthService.agentId;
    final utilisateur = AuthService.currentUser?.utilisateur;
    if (agentId == null || utilisateur == null) {
      setState(() => _errorMessage = 'Utilisateur non connecté');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.updateAgent(
        agentId,
        nomComplet: _nomCompletController.text.trim(),
        matricule: _matriculeController.text.trim(),
        phone: _phoneController.text.trim(),
        emailAgent: _emailController.text.trim(),
        fonction: _fonctionController.text.trim(),
        roleAgent: _roleAgent,
        photoUrl: _photoUrl,
        zoneSocialeId: _zoneSocialeId,
        categorieAgentId: _categorieAgentId,
        statut: _statut,
      );

      if (!mounted) return;

      if (response.success) {
        await AuthService.applyProfileUpdate(
          utilisateur.copyWith(
            nomComplet: _nomCompletController.text.trim(),
            email: _emailController.text.trim(),
            telephone: _phoneController.text.trim(),
          ),
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès'),
            backgroundColor: AppColors.prosocGreen,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage = ApiErrorHelper.messageForApiFailure(
            statusCode: response.statusCode,
            serverDetail: response.message,
            fallback: 'Échec de la mise à jour du profil.',
          );
          _isSaving = false;
        });
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException(
        'EditPercepteurProfile/save',
        e,
        stackTrace,
        false,
      );
      if (!mounted) return;
      setState(() {
        _errorMessage = ApiErrorHelper.userFacingNetwork();
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Modifier le profil',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.prosocGreen),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.errorColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.errorColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.grey.shade800),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (_roleAgent != null && _roleAgent!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.prosocGreen.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.badge_outlined,
                              color: AppColors.prosocGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Rôle : $_roleAgent',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    TextFormField(
                      controller: _nomCompletController,
                      textCapitalization: TextCapitalization.words,
                      decoration: _fieldDecoration(
                        'Nom complet',
                        Icons.person_outline_rounded,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Nom complet requis'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _matriculeController,
                      decoration: _fieldDecoration(
                        'Matricule',
                        Icons.badge_outlined,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Matricule requis'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _fieldDecoration(
                        'Téléphone',
                        Icons.phone_outlined,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Téléphone requis'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _fieldDecoration(
                        'Email',
                        Icons.email_outlined,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email requis';
                        }
                        if (!v.contains('@')) return 'Email invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fonctionController,
                      decoration: _fieldDecoration(
                        'Fonction',
                        Icons.work_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.prosocGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Enregistrer',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ChangePasswordScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.lock_outline_rounded),
                      label: const Text('Changer le mot de passe'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
