/// Échelle d'espacement, de rayons et de durées.
///
/// Un seul jeu de valeurs pour toute l'app : aucun écran n'invente un `16.5`
/// ou un `EdgeInsets.all(13)`.
library;

/// Espacements — progression 4 / 8 / 12 / 16 / 24 / 32 / 48.
abstract final class Espace {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Rayons de bordure. Les inspirations reposent sur des formes très arrondies :
/// cartes à 20, champs à 16, boutons en pilule.
abstract final class Rayon {
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;

  /// Bouton pilule — rayon volontairement supérieur à la demi-hauteur.
  static const double pilule = 100;
}

/// Durées d'animation. Nommées par intention, pas par valeur.
abstract final class Duree {
  static const Duration rapide = Duration(milliseconds: 180);
  static const Duration moyenne = Duration(milliseconds: 320);
  static const Duration lente = Duration(milliseconds: 600);

  /// Durée minimale d'affichage du splash, même si la session est restaurée
  /// instantanément : en dessous, l'animation est perçue comme un clignotement.
  static const Duration splash = Duration(milliseconds: 2100);
}
