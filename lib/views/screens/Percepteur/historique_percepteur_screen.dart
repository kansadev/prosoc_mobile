import 'package:flutter/material.dart';
import '../../../config/colors.dart';

// ============================================
// ÉCRAN HISTORIQUE DES COLLECTES PERCEPTEUR
// ============================================
class HistoriquePercepteurScreen extends StatefulWidget {
  const HistoriquePercepteurScreen({super.key});

  @override
  State<HistoriquePercepteurScreen> createState() => _HistoriquePercepteurScreenState();
}

class _HistoriquePercepteurScreenState extends State<HistoriquePercepteurScreen> {
  String _selectedFilter = 'Tous';

  final List<String> _filters = [
    'Tous',
    'Aujourd\'hui',
    'Cette semaine',
    'Ce mois',
  ];

  // Mock data for historique
  final List<_CollecteItem> _collectes = [
    _CollecteItem(
      id: 'COL001',
      matricule: 'AFF001234',
      nom: 'Jean Dupont',
      type: 'Cotisation Mensuelle',
      montant: 50000,
      date: DateTime(2026, 3, 20),
      statut: 'Succès',
    ),
    _CollecteItem(
      id: 'COL002',
      matricule: 'AFF001235',
      nom: 'Marie Martin',
      type: 'Cotisation Trimestrielle',
      montant: 150000,
      date: DateTime(2026, 3, 19),
      statut: 'Succès',
    ),
    _CollecteItem(
      id: 'COL003',
      matricule: 'AFF001236',
      nom: 'Pierre Durant',
      type: 'Renouvellement',
      montant: 600000,
      date: DateTime(2026, 3, 18),
      statut: 'Succès',
    ),
    _CollecteItem(
      id: 'COL004',
      matricule: 'AFF001237',
      nom: 'Sophie Bernard',
      type: 'Cotisation Mensuelle',
      montant: 50000,
      date: DateTime(2026, 3, 17),
      statut: 'Succès',
    ),
    _CollecteItem(
      id: 'COL005',
      matricule: 'AFF001238',
      nom: 'Louis Petit',
      type: 'Cotisation Annuelle',
      montant: 600000,
      date: DateTime(2026, 3, 15),
      statut: 'Succès',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.prosocGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Historique des Collectes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.prosocGreen,
                  AppColors.prosocGreen.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Total Collecté',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '1,250,000 XOF',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMiniStat('Collectes', _collectes.length.toString()),
                    _buildMiniStat('Commissions', '+125,000 XOF'),
                  ],
                ),
              ],
            ),
          ),

          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = filter == _selectedFilter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      backgroundColor: Colors.grey.shade100,
                      selectedColor: AppColors.prosocGreen.withValues(alpha: 0.2),
                      checkmarkColor: AppColors.prosocGreen,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.prosocGreen : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // List of collectes
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _collectes.length,
              itemBuilder: (context, index) {
                final collecte = _collectes[index];
                return _buildCollecteCard(collecte);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCollecteCard(_CollecteItem collecte) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                collecte.id,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.prosocGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  collecte.statut,
                  style: const TextStyle(
                    color: AppColors.prosocGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.prosocGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.prosocGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collecte.nom,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${collecte.matricule} - ${collecte.type}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${collecte.montant.toStringAsFixed(0)} XOF',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.prosocGreen,
                    ),
                  ),
                  Text(
                    _formatDate(collecte.date),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _CollecteItem {
  final String id;
  final String matricule;
  final String nom;
  final String type;
  final double montant;
  final DateTime date;
  final String statut;

  _CollecteItem({
    required this.id,
    required this.matricule,
    required this.nom,
    required this.type,
    required this.montant,
    required this.date,
    required this.statut,
  });
}
