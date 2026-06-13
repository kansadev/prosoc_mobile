import 'package:flutter/material.dart';

import '../../../config/api.dart';
import '../../../config/colors.dart';
import '../../../models/dependant_model.dart';
import '../../../services/auth_service.dart';
import '../../../utils/api_error_helper.dart';
import '../../../utils/formatters.dart';
import '../../../utils/paginated_response_helper.dart';
import '../../widgets/empty_state_widget.dart';
import 'widgets/dependant_detail_sheet.dart';
import 'widgets/dependant_form_sheet.dart';

/// Personnes à charge — GET /api/Dependant/by-affilie/{affilieId}.
class AdherentDependantsScreen extends StatefulWidget {
  const AdherentDependantsScreen({super.key});

  @override
  State<AdherentDependantsScreen> createState() =>
      _AdherentDependantsScreenState();
}

class _AdherentDependantsScreenState extends State<AdherentDependantsScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  List<Dependant> _dependants = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _page = 1;
  int _totalItems = 0;
  bool _hasNext = false;
  String _searchQuery = '';
  String _typeAdhesion = '';

  static const int _pageSize = 20;

  int? get _affilieId => AuthService.affilieId;

  bool get _isSoloAdhesion {
    final label = _typeAdhesion.toLowerCase().trim();
    return label.isNotEmpty && label.contains('solo');
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadProfileInfo();
    _loadDependants(reset: true);
  }

  Future<void> _loadProfileInfo() async {
    final affilieId = _affilieId;
    if (affilieId == null || affilieId <= 0) return;

    try {
      final response = await ApiService.getDashboardAffilieResume(affilieId);
      if (!mounted || !response.success || response.data == null) return;
      setState(() {
        _typeAdhesion = response.data!.informations.typeAdhesion;
      });
    } catch (e, stackTrace) {
      ApiErrorHelper.logException(
        'AdherentDependants/profile',
        e,
        stackTrace,
        false,
      );
    }
  }

  void _showSoloLockedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Adhésion Solo : les personnes à charge ne sont pas autorisées.',
        ),
        backgroundColor: Colors.orange.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasNext || _isLoadingMore || _isLoading) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadDependants();
    }
  }

  Future<void> _loadDependants({bool reset = false}) async {
    final affilieId = _affilieId;
    if (affilieId == null || affilieId <= 0) {
      setState(() {
        _errorMessage = 'Profil affilié introuvable.';
        _isLoading = false;
      });
      return;
    }

    if (reset) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _page = 1;
        _hasNext = false;
      });
    } else {
      if (!_hasNext) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final response = await ApiService.getDependantsByAffilie(
        affilieId,
        page: reset ? 1 : _page,
        pageSize: _pageSize,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (!mounted) return;

      final payload = response.data;
      if (response.success && payload != null) {
        final rows = PaginatedResponseHelper.extractRows(payload);
        final parsed = <Dependant>[];
        for (final item in rows) {
          if (item is! Map) continue;
          try {
            final map = item is Map<String, dynamic>
                ? item
                : Map<String, dynamic>.from(item);
            parsed.add(Dependant.fromJson(map));
          } catch (e, stackTrace) {
            ApiErrorHelper.logException('Dependant/fromJson', e, stackTrace);
          }
        }

        setState(() {
          if (reset) {
            _dependants = parsed;
          } else {
            _dependants = [..._dependants, ...parsed];
          }
          _totalItems = PaginatedResponseHelper.extractTotalItems(
            payload,
            fallback: _dependants.length,
          );
          _hasNext = PaginatedResponseHelper.extractHasNext(payload);
          if (_hasNext) {
            _page = PaginatedResponseHelper.extractCurrentPage(payload) + 1;
          }
          _errorMessage = null;
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          if (reset) {
            _dependants = [];
            _totalItems = 0;
            _errorMessage =
                response.message ??
                ApiErrorHelper.userFacingMessage(
                  statusCode: response.statusCode,
                );
          }
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('AdherentDependants', e, stackTrace, false);
      if (!mounted) return;
      setState(() {
        if (reset) {
          _errorMessage = ApiErrorHelper.userFacingNetwork();
          _dependants = [];
        }
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onSearchSubmitted(String value) {
    _searchQuery = value.trim();
    _loadDependants(reset: true);
  }

  Future<void> _openForm({Dependant? dependant}) async {
    if (_isSoloAdhesion) {
      _showSoloLockedMessage();
      return;
    }

    final affilieId = _affilieId;
    if (affilieId == null) return;

    final saved = await DependantFormSheet.show(
      context,
      affilieId: affilieId,
      dependant: dependant,
    );
    if (saved == true) {
      _loadDependants(reset: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              dependant == null
                  ? 'Personne à charge ajoutée'
                  : 'Personne à charge mise à jour',
            ),
            backgroundColor: AppColors.prosocGreen,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(Dependant d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text(
          'Supprimer « ${d.nom} » de vos personnes à charge ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorColor),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    try {
      final response =
          await ApiService.deleteDependant(d.idDependant);
      if (!mounted) return;

      if (response.success) {
        _loadDependants(reset: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Personne à charge supprimée'),
            backgroundColor: AppColors.prosocGreen,
          ),
        );
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
      ApiErrorHelper.logException('Dependant/delete', e, stackTrace, false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiErrorHelper.userFacingNetwork()),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _deleteCertificat(Dependant d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer le certificat'),
        content: const Text(
          'Supprimer le certificat de scolarité de cette personne ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    try {
      final response = await ApiService.deleteDependantCertificatScolarite(
        d.idDependant,
      );
      if (!mounted) return;

      if (response.success) {
        _loadDependants(reset: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Certificat retiré'),
            backgroundColor: AppColors.prosocGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.message ?? 'Impossible de retirer le certificat',
            ),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException(
        'Dependant/certificat-delete',
        e,
        stackTrace,
        false,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiErrorHelper.userFacingNetwork()),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  void _openDetail(Dependant d) {
    DependantDetailSheet.show(
      context,
      dependant: d,
      onEdit: _isSoloAdhesion ? null : () => _openForm(dependant: d),
      onDeleteCertificat: _isSoloAdhesion || !d.possedeCertificatScolarite
          ? null
          : () => _deleteCertificat(d),
      onDelete: _isSoloAdhesion ? null : () => _confirmDelete(d),
    );
  }

  Widget _buildDependantTile(Dependant d) {
    final birthLabel = d.dateNaissance != null
        ? AppFormatters.formatDate(d.dateNaissance)
        : null;
    final subtitleParts = <String>[
      d.lienParenteLabel,
      if (birthLabel != null) 'Né(e) le $birthLabel',
      if (d.telephone != null && d.telephone!.isNotEmpty) d.telephone!,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _openDetail(d),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor:
                            AppColors.prosocGreen.withValues(alpha: 0.1),
                        child: Text(
                          d.nom.isNotEmpty ? d.nom[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: AppColors.prosocGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.nom,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitleParts.join(' • '),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (d.possedeCertificatScolarite) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.school_outlined,
                                    size: 14,
                                    color: Colors.blue.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Certificat',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey.shade400,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 4),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: d.statut
                          ? AppColors.prosocGreen.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      d.statut ? 'Actif' : 'Inactif',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: d.statut ? AppColors.prosocGreen : Colors.red,
                      ),
                    ),
                  ),
                  if (!_isSoloAdhesion)
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                      onSelected: (action) {
                        switch (action) {
                          case 'edit':
                            _openForm(dependant: d);
                            break;
                          case 'certificat':
                            _deleteCertificat(d);
                            break;
                          case 'delete':
                            _confirmDelete(d);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined, size: 22),
                            title: Text('Modifier'),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                        if (d.possedeCertificatScolarite)
                          const PopupMenuItem(
                            value: 'certificat',
                            child: ListTile(
                              leading: Icon(Icons.school_outlined, size: 22),
                              title: Text('Retirer le certificat'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(
                              Icons.delete_outline,
                              size: 22,
                              color: AppColors.errorColor,
                            ),
                            title: Text(
                              'Supprimer',
                              style: TextStyle(color: AppColors.errorColor),
                            ),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoloBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, color: Colors.orange.shade800, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Votre adhésion Solo ne permet pas d\'ajouter des personnes à charge.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.orange.shade900,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoloEmptyState() {
    return EmptyStateScrollable(
      icon: Icons.person_off_outlined,
      title: 'Non disponible',
      subtitle:
          'L\'adhésion Solo est individuelle et ne couvre pas de personnes à charge.',
      iconColor: Colors.grey.shade400,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          _totalItems > 0
              ? 'Personnes à charge ($_totalItems)'
              : 'Personnes à charge',
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: _affilieId != null && !_isSoloAdhesion
          ? FloatingActionButton(
              heroTag: 'fab_adherent_dependants',
              onPressed: () => _openForm(),
              backgroundColor: AppColors.prosocGreen,
              child: const Icon(Icons.person_add_outlined, color: Colors.white),
            )
          : null,
      body: Column(
        children: [
          if (_isSoloAdhesion) _buildSoloBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom…',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchSubmitted('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: _onSearchSubmitted,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.prosocGreen,
                    ),
                  )
                : _errorMessage != null && _dependants.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _loadDependants(reset: true),
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
                  )
                : RefreshIndicator(
                    color: AppColors.prosocGreen,
                    onRefresh: () async {
                      await _loadProfileInfo();
                      await _loadDependants(reset: true);
                    },
                    child: _dependants.isEmpty
                        ? (_isSoloAdhesion
                              ? _buildSoloEmptyState()
                              : EmptyStateScrollable(
                                  icon: Icons.people_outline,
                                  title: 'Aucune personne à charge',
                                  subtitle: 'Appuyez sur + pour en ajouter.',
                                  iconColor: Colors.grey.shade400,
                                ))
                        : ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                            itemCount:
                                _dependants.length + (_isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= _dependants.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.prosocGreen,
                                    ),
                                  ),
                                );
                              }
                              return _buildDependantTile(_dependants[index]);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
