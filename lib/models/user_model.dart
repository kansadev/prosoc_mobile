import 'auth_user_model.dart';
import 'wallet_agent_model.dart';

class UserModel {
  final String firstName;
  final String lastName;
  final String memberSince;
  final double accountBalance;
  final double monthlyContribution;
  final double totalRefunded;
  final int insuredPersons;
  final int claimsCount;
  final double savings;

  UserModel({
    required this.firstName,
    required this.lastName,
    required this.memberSince,
    required this.accountBalance,
    required this.monthlyContribution,
    required this.totalRefunded,
    required this.insuredPersons,
    required this.claimsCount,
    required this.savings,
  });

  String get fullName => '$firstName $lastName';

  String get formattedBalance => '${accountBalance.toStringAsFixed(0)} €';
  String get formattedContribution => '${monthlyContribution.toStringAsFixed(0)}€/mois';
  String get formattedRefunded => '${totalRefunded.toStringAsFixed(0)}€';
  String get formattedSavings => '${(savings / 1000).toStringAsFixed(1)}K';

  /// Crée un UserModel à partir des données réelles de l'utilisateur et du wallet agent
  static UserModel fromUserData(UtilisateurModel utilisateur, WalletAgentModel? walletAgent) {
    // Extraire le nom et prénom du nom complet
    final nameParts = utilisateur.nomComplet.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    
    return UserModel(
      firstName: firstName,
      lastName: lastName,
      memberSince: utilisateur.dateCreation.year.toString(),
      accountBalance: walletAgent?.soldeCourant ?? 0.0,
      monthlyContribution: 5000, // À récupérer depuis l'API si disponible
      totalRefunded: 0, // À récupérer depuis l'API si disponible
      insuredPersons: 1, // À récupérer depuis l'API si disponible
      claimsCount: 0, // À récupérer depuis l'API si disponible
      savings: walletAgent?.soldeCourant ?? 0.0,
    );
  }

  /// Méthode par défaut pour les tests (à remplacer par fromUserData en production)
  static UserModel defaultUser() {
    return UserModel(
      firstName: 'Jean',
      lastName: 'Mbemba',
      memberSince: '2021',
      accountBalance: 150000,
      monthlyContribution: 5000,
      totalRefunded: 25000,
      insuredPersons: 4,
      claimsCount: 8,
      savings: 85000,
    );
  }
}
