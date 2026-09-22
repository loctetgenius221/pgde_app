import 'package:flutter/material.dart';

/// Couleurs de marque, relevées directement dans le logo du ministère.
///
/// Doctrine retenue : **vert dominant, tricolore en touches**.
/// - le vert porte l'interface (actions, liens, états actifs) ;
/// - le jaune ne sert qu'aux accents rares : étape en cours, badge brouillon ;
/// - le rouge reste **réservé aux erreurs**. L'utiliser en décoration lui
///   ferait perdre sa valeur d'alerte sur un formulaire de trente champs.
abstract final class AppColors {
  /// Vert du logo — couleur d'action de toute l'application.
  static const Color vert = Color(0xFF009454);

  /// Jaune du logo — accent, jamais une action.
  static const Color jaune = Color(0xFFFFCC34);

  /// Rouge du logo — erreurs uniquement.
  static const Color rouge = Color(0xFFF43438);

  /// Anthracite du logo — texte principal.
  static const Color anthracite = Color(0xFF272825);

  // --- Neutres ---
  static const Color fondClair = Color(0xFFF6F8F7);
  static const Color surfaceClaire = Color(0xFFFFFFFF);
  static const Color contourClair = Color(0xFFE3E7E5);
  static const Color texteSecondaireClair = Color(0xFF6B716E);

  static const Color fondSombre = Color(0xFF141615);
  static const Color surfaceSombre = Color(0xFF1E211F);
  static const Color contourSombre = Color(0xFF343936);
  static const Color texteSecondaireSombre = Color(0xFFA8AEAB);

  /// Vert clair pour les fonds de badge et d'icône.
  static const Color vertPale = Color(0xFFD9F2E5);
  static const Color jaunePale = Color(0xFFFFF3D2);
}
