import 'package:flutter/material.dart';
import '../../../config/colors.dart';
import '../../../config/api.dart';
import '../../../services/auth_service.dart';

// Model for Affilie search result
class AffilieSearchResult {
  final int idAffilie;
  final String codeAdhesion;
  final String nom;
  final String prenom;
  final String nomComplet;

  AffilieSearchResult({
    required this.idAffilie,
    required this.codeAdhesion,
    required this.nom,
    required this.prenom,
    required this.nomComplet,
  });

  factory AffilieSearchResult.fromJson(Map<String, dynamic> json) {
    return AffilieSearchResult(
      idAffilie: json['idAffilie'] ?? 0,
      codeAdhesion: json['codeAdhesion'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      nomComplet: json['nomComplet'] ?? '',
    );
  }
}

// Model for Devise
class DeviseModel {
  final int idDevise;
  final String code;
  final String nom;
  final double tauxChange;
  final bool statut;

  DeviseModel({
    required this.idDevise,
    required this.code,
    required this.nom,
    required this.tauxChange,
    required this.statut,
  });

  factory DeviseModel.fromJson(Map<String, dynamic> json) {
    return DeviseModel(
      idDevise: json['idDevise'] ?? 0,
      code: json['code'] ?? '',
      nom: json['nom'] ?? '',
      tauxChange: (json['tauxChange'] ?? 1).toDouble(),
      statut: json['statut'] ?? false,
    );
  }
}

// Model for Prestation
class PrestationModel {
  final int id;
  final String nomPrestation;
  final double? montant;
  final String description;
  final int produitMutuelId;
  final String produitMutuelNom;

  PrestationModel({
    required this.id,
    required this.nomPrestation,
    this.montant,
    required this.description,
    required this.produitMutuelId,
    required this.produitMutuelNom,
  });

  factory PrestationModel.fromJson(Map<String, dynamic> json) {
    return PrestationModel(
      id: json['id'] ?? 0,
      nomPrestation: json['nomPrestation'] ?? '',
      montant: json['montant']?.toDouble(),
      description: json['description'] ?? '',
      produitMutuelId: json['produitMutuelId'] ?? 0,
      produitMutuelNom: json['produitMutuelNom'] ?? '',
    );
  }
}

// ============================================
// ÉCRAN DE COLLECTE PERCEPTEUR
// ============================================
class CollectePercepteurScreen extends StatefulWidget {
  const CollectePercepteurScreen({super.key});

  @override
  State<CollectePercepteurScreen> createState() =>
      _CollectePercepteurScreenState();
}

class _CollectePercepteurScreenState extends State<CollectePercepteurScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montantController = TextEditingController();
  final _matriculeController = TextEditingController();
  final _observationController = TextEditingController();

  // Fixed type to Souscription
  static const String _selectedType = 'Souscription';

  int? _selectedPrestationId;
  int? _selectedDeviseId;
  bool _isLoading = false;
  String? _errorMessage;

  // Affilie search
  final TextEditingController _searchAffilieController =
      TextEditingController();
  List<AffilieSearchResult> _affilieResults = [];
  bool _isSearchingAffilie = false;
  bool _showAffilieDropdown = false;
  AffilieSearchResult? _selectedAffilie;

  // Devises loaded from API
  List<DeviseModel> _devises = [];
  bool _isLoadingDevises = false;

  // Type de collecte is fixed to 'Souscription'

  @override
  void initState() {
    super.initState();
    _loadDevises();
    _loadPrestations();
  }

  Future<void> _loadDevises() async {
    setState(() {
      _isLoadingDevises = true;
    });

    try {
      final response = await ApiService.getDevises();
      if (response.success && response.data != null) {
        final List<dynamic> data = response.data as List<dynamic>;
        setState(() {
          _devises = data
              .map((item) => DeviseModel.fromJson(item as Map<String, dynamic>))
              .where((d) => d.statut)
              .toList();
          _isLoadingDevises = false;
        });
      } else {
        setState(() {
          _isLoadingDevises = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingDevises = false;
      });
    }
  }

  // Prestations loaded from API
  List<PrestationModel> _prestations = [];
  bool _isLoadingPrestations = false;

  Future<void> _loadPrestations() async {
    setState(() {
      _isLoadingPrestations = true;
    });

    try {
      final response = await ApiService.getPrestations();
      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> prestations = data['data'] ?? [];
        setState(() {
          _prestations = prestations
              .map(
                (item) =>
                    PrestationModel.fromJson(item as Map<String, dynamic>),
              )
              .toList();
          _isLoadingPrestations = false;
        });
      } else {
        setState(() {
          _isLoadingPrestations = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingPrestations = false;
      });
    }
  }

  Future<void> _searchAffilie(String query) async {
    if (query.isEmpty) {
      setState(() {
        _affilieResults = [];
        _showAffilieDropdown = false;
      });
      return;
    }

    setState(() {
      _isSearchingAffilie = true;
      _showAffilieDropdown = true;
    });

    try {
      final response = await ApiService.searchAffilies(
        search: query,
        pageSize: 10,
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> affilies = data['data'] ?? [];
        setState(() {
          _affilieResults = affilies
              .map(
                (item) =>
                    AffilieSearchResult.fromJson(item as Map<String, dynamic>),
              )
              .toList();
          _isSearchingAffilie = false;
        });
      } else {
        setState(() {
          _affilieResults = [];
          _isSearchingAffilie = false;
        });
      }
    } catch (e) {
      setState(() {
        _affilieResults = [];
        _isSearchingAffilie = false;
      });
    }
  }

  void _selectAffilie(AffilieSearchResult affilie) {
    setState(() {
      _selectedAffilie = affilie;
      _searchAffilieController.text = affilie.codeAdhesion;
      _showAffilieDropdown = false;
    });
  }

  @override
  void dispose() {
    _montantController.dispose();
    _matriculeController.dispose();
    _observationController.dispose();
    _searchAffilieController.dispose();
    super.dispose();
  }

  String _generateReference() {
    return 'AUTO-${DateTime.now().millisecondsSinceEpoch}';
  }

  void _handleCollecte() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedAffilie == null) {
      _showError('Veuillez sélectionner un affilié');
      return;
    }

    // Type is fixed to 'Souscription'

    if (_selectedPrestationId == null) {
      _showError('Veuillez sélectionner la prestation');
      return;
    }

    if (_selectedDeviseId == null) {
      _showError('Veuillez sélectionner la devise');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = AuthService.userId;
      final agentId = userId ?? 0;

      final now = DateTime.now();
      final reference = _generateReference();
      final montant = double.parse(_montantController.text);

      // Debug: Afficher le payload
      debugPrint('=== PAYLOAD COLLECTE ===');
      debugPrint('typeCollecte: $_selectedType');
      debugPrint('affilieId: ${_selectedAffilie?.idAffilie ?? 0}');
      debugPrint('agentId: $agentId');
      debugPrint('montant: $montant');
      debugPrint('mois: ${now.month}');
      debugPrint('annee: ${now.year}');
      debugPrint('referencePaiement: $reference');
      debugPrint('modePaiement: VIRTUAL_ACCOUNT');
      debugPrint('statutPaiement: OK');
      debugPrint('subscriptionPrestationId: $_selectedPrestationId');
      debugPrint('montantRecu: $montant');
      debugPrint('montantAttendu: $montant');
      debugPrint('deviseId: $_selectedDeviseId');
      debugPrint('observation: ${_observationController.text.isNotEmpty ? _observationController.text : "Collecte effectuée par le percepteur"}');
      debugPrint('=======================');

      // Appel API avec tous les champs requis
      final response = await ApiService.createCollecte(
        typeCollecte: _selectedType,
        affilieId: _selectedAffilie?.idAffilie ?? 0,
        agentId: agentId,
        montant: montant,
        mois: now.month,
        annee: now.year,
        referencePaiement: reference,
        modePaiement: 'VIRTUAL_ACCOUNT',
        statutPaiement: 'OK',
        prestationId: _selectedPrestationId,
        montantRecu: montant,
        montantAttendu: montant,
        deviseId: _selectedDeviseId!,
        observation: _observationController.text.isNotEmpty
            ? _observationController.text
            : 'Collecte effectuée par le percepteur',
      );

      // Debug: Afficher la réponse API
      debugPrint('=== RESPONSE COLLECTE ===');
      debugPrint('success: ${response.success}');
      debugPrint('message: ${response.message}');
      debugPrint('data: ${response.data}');
      debugPrint('==========================');

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Collecte enregistrée avec succès!'),
              backgroundColor: AppColors.prosocGreen,
            ),
          );

          // Clear form
          _clearForm();
        }
      } else {
        setState(() {
          _errorMessage =
              response.message ?? 'Erreur lors de l\'enregistrement';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de connexion: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _clearForm() {
    _montantController.clear();
    _matriculeController.clear();
    _observationController.clear();
    _searchAffilieController.clear();
    setState(() {
      _selectedAffilie = null;
      _selectedPrestationId = null;
      _selectedDeviseId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.prosocGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Nouvelle Collecte', style: TextStyle(color: Colors.white)),
        
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Matricule Affilié - Search Bar
              _buildLabel('Matricule Affilié'),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _searchAffilieController,
                    keyboardType: TextInputType.text,
                    decoration: _inputDecoration(
                      hintText: 'Rechercher un affilié...',
                      icon: Icons.search,
                    ),
                    onChanged: (value) {
                      _searchAffilie(value);
                    },
                    validator: (value) {
                      if (_selectedAffilie == null) {
                        return 'Veuillez sélectionner un affilié';
                      }
                      return null;
                    },
                  ),
                  // Dropdown results
                  if (_showAffilieDropdown)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _isSearchingAffilie
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            )
                          : _affilieResults.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'Aucun résultat trouvé',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _affilieResults.length,
                              itemBuilder: (context, index) {
                                final affilie = _affilieResults[index];
                                return ListTile(
                                  leading: const Icon(
                                    Icons.person,
                                    color: AppColors.prosocGreen,
                                  ),
                                  title: Text(
                                    affilie.codeAdhesion,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(affilie.nomComplet),
                                  onTap: () => _selectAffilie(affilie),
                                );
                              },
                            ),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // Type de collecte (fixed to Souscription)
              _buildLabel('Type de Collecte'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.prosocGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.prosocGreen),
                ),
                child: Row(
                  children: [
                    Icon(Icons.category, color: AppColors.prosocGreen),
                    const SizedBox(width: 12),
                    Text(
                      'Souscription',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.prosocGreen,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Prestation (loaded from API)
              _buildLabel('Prestation'),
              const SizedBox(height: 8),
              _isLoadingPrestations
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<int>(
                      initialValue: _selectedPrestationId,
                      decoration: _inputDecoration(
                        hintText: 'Sélectionnez la prestation',
                        icon: Icons.medical_services,
                      ),
                      items: _prestations.map((item) {
                        return DropdownMenuItem(
                          value: item.id,
                          child: Text(item.nomPrestation),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPrestationId = value;
                          // Auto-fill montant from selected prestation
                          if (value != null) {
                            final selectedPrestation = _prestations.firstWhere(
                              (p) => p.id == value,
                              orElse: () => _prestations.first,
                            );
                            if (selectedPrestation.montant != null) {
                              _montantController.text = selectedPrestation.montant.toString();
                            }
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Veuillez sélectionner la prestation';
                        }
                        return null;
                      },
                    ),

              const SizedBox(height: 20),
              // Montant
              _buildLabel('Montant'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _montantController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _inputDecoration(
                  hintText: 'Ex: 50000',
                  icon: Icons.attach_money,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le montant';
                  }
                  final montant = double.tryParse(value);
                  if (montant == null || montant <= 0) {
                    return 'Veuillez entrer un montant valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Devise
              _buildLabel('Devise'),
              const SizedBox(height: 8),
              _isLoadingDevises
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<int>(
                      initialValue: _selectedDeviseId,
                      decoration: _inputDecoration(
                        hintText: 'Sélectionnez la devise',
                        icon: Icons.currency_exchange,
                      ),
                      items: _devises.map((devise) {
                        return DropdownMenuItem(
                          value: devise.idDevise,
                          child: Text('${devise.code} - ${devise.nom}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDeviseId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Veuillez sélectionner la devise';
                        }
                        return null;
                      },
                    ),

              const SizedBox(height: 20),

              // Observation (optionnel)
              _buildLabel('Observation (optionnel)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _observationController,
                maxLines: 3,
                decoration: _inputDecoration(
                  hintText: 'Ajouter une observation...',
                  icon: Icons.note,
                ),
              ),

              const SizedBox(height: 32),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'La collecte sera automatiquement créditée sur le compte de l\'affilié et votre commission sera calculée.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Submit button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleCollecte,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.prosocGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Enregistrer la Collecte',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

         


            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, color: AppColors.prosocGreen),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.prosocGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}

