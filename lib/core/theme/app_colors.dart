import 'package:flutter/material.dart';

/// Couleurs de marque, relevées directement dans le logo du ministère.
///
/// Doctrine retenue : **vert dominant, tricolore en touches**.
/// - le vert porte l'interface (actions, liens, états actifs) ;
/// - le jaune ne sert qu'aux accents : étape en cours, avertissement, et le
///   segment sélectionné d'un `SegmentedButton`, que Material peint avec
///   `secondaryContainer` ;
/// - le rouge reste **réservé aux erreurs**. L'utiliser en décoration lui
///   ferait perdre sa valeur d'alerte sur un formulaire de trente champs.
abstract final class AppColors {
  /// Vert du logo — couleur d'action de toute l'application.
  static const Color vert = Color(0xFF009454);

  /// Jaune du logo — **le seul jaune de l'application**.
  ///
  /// Aucune teinte dérivée n'est autorisée : ni éclaircie pour un fond, ni
  /// assombrie pour un texte. Material 3 en fabriquerait volontiers à partir
  /// de la graine, d'où le recalage explicite de tous les rôles « secondary »
  /// dans [AppTheme].
  static const Color jaune = Color(0xFFFFCC34);

  /// Rouge du logo — erreurs uniquement.
  static const Color rouge = Color(0xFFF43438);

  /// Anthracite du logo — texte principal.
  static const Color anthracite = Color(0xFF272825);

  // --- Neutres ---
  // static const Color fondClair = Color(0xFFF6F8F7);
  static const Color fondClair = Color(0xFFFFFFFF);
  static const Color surfaceClaire = Color(0xFFFFFFFF);
  static const Color contourClair = Color(0xFFE3E7E5);
  static const Color texteSecondaireClair = Color(0xFF6B716E);

  static const Color fondSombre = Color(0xFF141615);
  static const Color surfaceSombre = Color(0xFF1E211F);
  static const Color contourSombre = Color(0xFF343936);
  static const Color texteSecondaireSombre = Color(0xFFA8AEAB);

  /// Vert clair pour les fonds de badge et d'icône.
  static const Color vertPale = Color(0xFFD9F2E5);

  // --- Formulaires, alignés sur la plateforme web ---

  /// Fond des champs : blanc, comme les cartes de « Mon dossier ». Le filet
  /// fin suffit à délimiter le champ ; un fond gris alourdissait un
  /// formulaire de trente champs.
  static const Color champClair = Color(0xFFFFFFFF);

  /// Champ inactif (« Choisissez d'abord une région ») : le seul à garder un
  /// fond gris, pour qu'on voie d'un coup d'œil qu'il n'est pas encore
  /// accessible.
  static const Color champDesactiveClair = Color(0xFFF4F6F5);
  static const Color champSombre = Color(0xFF252926);

  /// Piste d'un choix segmenté, sur laquelle l'option retenue se détache en
  /// blanc.
  static const Color pisteClaire = Color(0xFFF1F3F4);
  static const Color pisteSombre = Color(0xFF2A2E2B);
}
