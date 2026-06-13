import 'package:flutter/material.dart';
import '../../../config/colors.dart';
import '../../../config/api.dart';
import '../../../services/auth_service.dart';

// ============================================
// MODÈLE JETON DE RETRAIT
// ============================================
class JetonRetraitModel {
  final int idDemande;
  final String? jeton;
  final DateTime? dateGeneration;
  final bool estUtilise;
  final DateTime? dateExpiration;

  JetonRetraitModel({
    required this.idDemande,
    this.jeton,
    this.dateGeneration,
    this.estUtilise = false,
    this.dateExpiration,
  });

  factory JetonRetraitModel.fromJson(Map<String, dynamic> json) {
    return JetonRetraitModel(
      idDemande: json['idDemande'] ?? 0,
      jeton: json['jeton'],
      dateGeneration: json['dateGeneration'] != null 
          ? DateTime.parse(json['dateGeneration']) 
          : null,
      estUtilise: json['estUtilise'] ?? false,
      dateExpiration: json['dateExpiration'] != null 
          ? DateTime.parse(json['dateExpiration']) 
          : null,
    );
  }
}

// ============================================
// ÉCRAN GÉNÉRATION JETON (VIEW)
// ============================================
class TokenScreen extends StatefulWidget {
  const TokenScreen({super.key});

  @override
  State<TokenScreen> createState() => _TokenScreenState();
}

class _TokenScreenState extends State<TokenScreen> {
  List<JetonRetraitModel> _jetons = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadJetons();
  }

  Future<void> _loadJetons() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getDemandesRetraitAgent();
      
      if (!mounted) return;
      
      if (response.success && response.data != null) {
        setState(() {
          _jetons = (response.data as List)
              .map((json) => JetonRetraitModel.fromJson(json as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Erreur lors du chargement des jetons';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erreur de connexion: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _genererJeton(int idDemande) async {
    try {
      final userId = AuthService.userId;
      if (userId == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Utilisateur non connecté';
          });
        }
        return;
      }

      final response = await ApiService.validerEtGenererJetonRetrait(
        idDemande: idDemande,
        statutDemande: 'APPROUVE',
        agentValidationId: userId,
      );

      if (!mounted) return;
      
      if (response.success) {
        _loadJetons(); // Refresh the list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Jeton généré avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Erreur lors de la génération du jeton';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erreur de connexion: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Gestion des Jetons',style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),),
        backgroundColor: AppColors.prosocGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.generating_tokens_outlined, color: Colors.white),
            onPressed: _loadJetons,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.prosocGreen,
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadJetons,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _jetons.isEmpty
                  ? const Center(child: Text('Aucun jeton disponible'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _jetons.length,
                      itemBuilder: (context, index) {
                        final jeton = _jetons[index];
                        return _buildJetonCard(jeton);
                      },
                    ),
    );
  }

  Widget _buildJetonCard(JetonRetraitModel jeton) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Demande #${jeton.idDemande}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: jeton.estUtilise 
                        ? Colors.grey.shade200 
                        : AppColors.prosocGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    jeton.estUtilise ? 'Utilisé' : 'Actif',
                    style: TextStyle(
                      color: jeton.estUtilise 
                          ? Colors.grey 
                          : AppColors.prosocGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (jeton.jeton != null) ...[
              Text(
                'Jeton: ${jeton.jeton}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              if (jeton.dateGeneration != null)
                Text(
                  'Généré le: ${jeton.dateGeneration!.day}/${jeton.dateGeneration!.month}/${jeton.dateGeneration!.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: jeton.estUtilise 
                    ? null 
                    : () => _genererJeton(jeton.idDemande),
                icon: const Icon(Icons.qr_code),
                label: const Text('Générer le jeton'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.prosocGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
