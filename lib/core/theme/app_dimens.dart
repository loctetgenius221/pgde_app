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

/// Rayons de bordure.
///
/// Les champs, boutons et sélecteurs reprennent le rayon de la plateforme web
/// ([champ]) : un candidat qui passe de l'un à l'autre retrouve les mêmes
/// formes, et ne se sent pas sur une autre application.
abstract final class Rayon {
  static const double sm = 10;

  /// Champs, boutons, sélecteurs segmentés et tuiles d'étape — comme le web.
  static const double champ = 12;

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
