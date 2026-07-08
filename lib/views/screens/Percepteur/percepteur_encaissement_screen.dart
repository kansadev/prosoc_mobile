import 'dart:async';

import 'package:flutter/material.dart';

import 'package:prosoc/config/api.dart';
import 'package:prosoc/config/colors.dart';
import 'package:prosoc/utils/affilie_id_helper.dart';
import 'package:prosoc/utils/api_error_helper.dart';
import 'package:prosoc/utils/paginated_response_helper.dart';
import 'package:prosoc/views/screens/adh%C3%A9rent/widgets/payer_contributionScreen.dart';
import 'package:prosoc/views/screens/adh%C3%A9rent/widgets/payer_frais_screen.dart';
import 'package:prosoc/views/screens/adh%C3%A9rent/widgets/payer_souscription_screen.dart';
import 'package:prosoc/widgets/popup_menu_widget.dart';
import 'package:prosoc/widgets/souscription_bottom_sheet.dart';

/// Sélection d'un affilié (GET /api/Affilie) puis encaissement via [PayerContributionScreen].
class PercepteurEncaissementScreen extends StatefulWidget {
  const PercepteurEncaissementScreen({super.key});

  @override
  State<PercepteurEncaissementScreen> createState() =>
      _PercepteurEncaissementScreenState();
}

class _PercepteurEncaissementScreenState
    extends State<PercepteurEncaissementScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;

  List<Map<String, dynamic>> _affilies = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasNextPage = false;
  String? _activeSearch;

  static const _pageSize = 15;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadAffilies(reset: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoading || _isLoadingMore || !_hasNextPage) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadAffilies();
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      final query = value.trim();
      _loadAffilies(
        reset: true,
        search: query.isEmpty ? null : query,
      );
    });
  }

  Future<void> _loadAffilies({bool reset = false, String? search}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _isLoadingMore = false;
        _errorMessage = null;
        _affilies = [];
        _currentPage = 1;
        _hasNextPage = false;
        _activeSearch = search;
      });
    } else {
      if (_isLoadingMore || !_hasNextPage) return;
      setState(() {
        _isLoadingMore = true;
        _errorMessage = null;
      });
    }

    final pageToLoad = reset ? 1 : _currentPage + 1;

    try {
      final response = await ApiService.searchAffilies(
        page: pageToLoad,
        pageSize: _pageSize,
        search: search ?? _activeSearch,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        final payload = response.data!;
        final rows = PaginatedResponseHelper.extractRows(payload);
        final pageItems = rows
            .map((e) {
              if (e is Map<String, dynamic>) return e;
              if (e is Map) return Map<String, dynamic>.from(e);
              return <String, dynamic>{};
            })
            .where((m) => m.isNotEmpty)
            .toList();

        setState(() {
          _affilies = reset ? pageItems : [..._affilies, ...pageItems];
          _currentPage = payload['currentPage'] is int
              ? payload['currentPage'] as int
              : pageToLoad;
          _hasNextPage = payload['hasNextPage'] == true;
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _errorMessage = ApiErrorHelper.messageForApiFailure(
            statusCode: response.statusCode,
            serverDetail: response.message,
            fallback: 'Impossible de charger les affiliés.',
          );
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException(
        'PercepteurEncaissement/affilies',
        e,
        stackTrace,
        false,
      );
      if (!mounted) return;
      setState(() {
        _errorMessage = ApiErrorHelper.userFacingNetwork();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _openPayerCotisation(Map<String, dynamic> membre) {
    final ctx = _affilieContext(membre);
    if (ctx == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PayerContributionScreen(
          affilieId: ctx.affilieId,
          affilieNom: ctx.nom,
          affiliePrenom: ctx.prenom,
          affilieTelephone: ctx.telephone,
          screenTitle: 'Encaisser une cotisation',
        ),
      ),
    );
  }

  void _openPayerFrais(Map<String, dynamic> membre) {
    final ctx = _affilieContext(membre);
    if (ctx == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PayerFraisScreen(
          affilieId: ctx.affilieId,
          affilieNom: ctx.nom,
          affiliePrenom: ctx.prenom,
          affilieTelephone: ctx.telephone,
          screenTitle: 'Encaisser un frais',
        ),
      ),
    );
  }

  void _openPayerSouscription(Map<String, dynamic> membre) {
    final ctx = _affilieContext(membre);
    if (ctx == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PayerSouscriptionScreen(
          affilieId: ctx.affilieId,
          affilieNom: ctx.nom,
          affiliePrenom: ctx.prenom,
          affilieTelephone: ctx.telephone,
          screenTitle: 'Encaisser une souscription',
        ),
      ),
    );
  }

  void _openSouscriptionBottomSheet(Map<String, dynamic> membre) {
    final ctx = _affilieContext(membre);
    if (ctx == null) return;

    SouscriptionBottomSheet.show(
      context,
      affilieId: ctx.affilieId,
      affilieNom: ctx.nom,
      affiliePrenom: ctx.prenom,
      affilieTelephone: ctx.telephone,
    );
  }

  _AffilieEncaissementContext? _affilieContext(Map<String, dynamic> membre) {
    final affilieId = resolveAffilieId(membre);
    if (affilieId <= 0) return null;

    final nom = (membre['nom'] ?? '').toString();
    final prenom = (membre['prenom'] ?? '').toString();
    final phone = (membre['phone'] ?? membre['telephone'] ?? '').toString();

    return _AffilieEncaissementContext(
      affilieId: affilieId,
      nom: nom,
      prenom: prenom,
      telephone: phone.isNotEmpty ? phone : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Encaisser',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un affilié (nom, matricule…)',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {});
                _onSearchChanged(value);
              },
            ),
          ),
          if (_activeSearch == null && !_isLoading && _affilies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Suggestions — affiliés',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
              ),
            ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.prosocGreen),
      );
    }

    if (_affilies.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _activeSearch != null
                ? 'Aucun affilié trouvé pour « $_activeSearch ».'
                : 'Aucun affilié disponible.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.prosocGreen,
      onRefresh: () => _loadAffilies(reset: true, search: _activeSearch),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: _affilies.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index >= _affilies.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.prosocGreen,
                  strokeWidth: 2,
                ),
              ),
            );
          }

          final membre = _affilies[index];
          final nom = (membre['nom'] ?? '').toString();
          final prenom = (membre['prenom'] ?? '').toString();
          final matricule = (membre['matricule'] ?? '').toString();
          final phone = (membre['phone'] ?? membre['telephone'] ?? '')
              .toString();
          final typeAdhesion = (membre['typeAdhesion'] ?? '').toString();

          final initials = [
            if (prenom.trim().isNotEmpty) prenom.trim()[0],
            if (nom.trim().isNotEmpty) nom.trim()[0],
          ].join().toUpperCase();

          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        AppColors.prosocGreen.withValues(alpha: 0.12),
                    child: Text(
                      initials.isNotEmpty ? initials : '?',
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
                          '$prenom $nom'.trim(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        if (matricule.isNotEmpty)
                          Text(
                            matricule,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        if (phone.isNotEmpty)
                          Text(
                            phone,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        if (typeAdhesion.isNotEmpty)
                          Text(
                            typeAdhesion,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  AffiliatePopupMenuWidget(
                    iconColor: AppColors.prosocGreen,
                    onCollecte: () => _openPayerCotisation(membre),
                    onPayerFrais: () => _openPayerFrais(membre),
                    onPayerSouscription: () => _openPayerSouscription(membre),
                    onSouscription: () => _openSouscriptionBottomSheet(membre),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AffilieEncaissementContext {
  final int affilieId;
  final String nom;
  final String prenom;
  final String? telephone;

  const _AffilieEncaissementContext({
    required this.affilieId,
    required this.nom,
    required this.prenom,
    this.telephone,
  });
}
