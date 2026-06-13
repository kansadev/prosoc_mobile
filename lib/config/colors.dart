import 'package:flutter/material.dart';


class AppColors {
  // ============================================
  // COULEURS PRÉSENTATION PROSOC (VERT & BLANC)
  // ============================================
  
  // Vert Prosoc (utilisé dans le login et onboarding)
  static const Color prosocGreen = Color(0xFF2DB467);
  
  // Couleurs principales
  static const Color primaryColor = Color(0xFF2DB467);  // Vert Prosoc
  static const Color secondaryColor = Color(0xFF1E8A4A);  // Vert plus foncé
  static const Color accentColor = Color(0xFF737373);     // Gris moyen (neutre)
  
  // Arrière-plans et cartes (THÈME CLAIR)
  static const Color backgroundColor = Color(0xFFFFFFFF); // Blanc
  static const Color cardColor = Color(0xFFF5F5F5);      // Gris très clair

  // Couleurs de texte
  static const Color textPrimary = Color(0xFF1A1A1A);    // Noir pour lisibilité
  static const Color textSecondary = Color(0xFF666666);  // Gris moyen pour légendes
  
  // Gradients (Effet vert)
  static const Color gradientStart = Color(0xFF2DB467);
  static const Color gradientEnd = Color(0xFF1E8A4A);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Status
  static const Color successColor = Color(0xFF2DB467);
  static const Color warningColor = Color(0xFFF57C00);
  static const Color errorColor = Color(0xFFC62828);
}