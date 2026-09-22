import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimens.dart';

/// Thème unique de l'application.
///
/// Langage visuel repris des inspirations — beaucoup de blanc, formes très
/// arrondies, boutons pilule, grands titres — mais **palette du logo** :
/// l'indigo des maquettes n'a rien à faire dans une application d'État.
abstract final class AppTheme {
  static const String _police = 'Poppins';

  static ThemeData light() => _construire(Brightness.light);
  static ThemeData dark() => _construire(Brightness.dark);

  static ThemeData _construire(Brightness brightness) {
    final bool clair = brightness == Brightness.light;
    final ColorScheme scheme = _scheme(brightness);
    final TextTheme texte = _typographie(scheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: _police,
      textTheme: texte,
      scaffoldBackgroundColor: clair
          ? AppColors.fondClair
          : AppColors.fondSombre,

      appBarTheme: AppBarTheme(
        backgroundColor: clair ? AppColors.fondClair : AppColors.fondSombre,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: texte.titleLarge,
      ),

      // Champs **en pilule**, comme les boutons : une seule famille de formes
      // pour toute l'application. Le contraste vient du fond, pas d'un trait ;
      // le contour ne s'affirme qu'au focus.
      //
      // Un champ multiligne (résumé de CV) devra surcharger `border` avec un
      // rayon plus faible : une pilule de six lignes de haut serait absurde.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: clair ? AppColors.surfaceClaire : AppColors.surfaceSombre,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Espace.lg,
          vertical: Espace.md + 2,
        ),
        // Laisse respirer les icônes de début et de fin de champ : collées au
        // bord, elles entreraient dans la courbe de la pilule.
        prefixIconConstraints: const BoxConstraints(minWidth: 52, minHeight: 52),
        suffixIconConstraints: const BoxConstraints(minWidth: 52, minHeight: 52),
        hintStyle: texte.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        labelStyle: texte.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        floatingLabelStyle: texte.bodySmall?.copyWith(color: scheme.primary),
        helperStyle: texte.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        // Les messages d'erreur du serveur sont des phrases entières (§7.1).
        errorMaxLines: 3,
        errorStyle: texte.bodySmall?.copyWith(color: scheme.error),
        // Aligne les messages sous le texte du champ, pas sous sa courbe.
        helperMaxLines: 2,
        border: _bordure(scheme.outlineVariant),
        enabledBorder: _bordure(scheme.outlineVariant),
        focusedBorder: _bordure(scheme.primary, epaisseur: 1.6),
        errorBorder: _bordure(scheme.error),
        focusedErrorBorder: _bordure(scheme.error, epaisseur: 1.6),
        disabledBorder: _bordure(scheme.outlineVariant.withValues(alpha: 0.5)),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: const StadiumBorder(),
          textStyle: texte.labelLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: const StadiumBorder(),
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: texte.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: texte.labelLarge,
          foregroundColor: scheme.primary,
        ),
      ),

      cardTheme: CardThemeData(
        color: clair ? AppColors.surfaceClaire : AppColors.surfaceSombre,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Rayon.lg),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Rayon.md),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: Espace.md),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Rayon.md),
        ),
        contentTextStyle: texte.bodyMedium?.copyWith(color: scheme.onInverseSurface),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.outlineVariant,
        linearMinHeight: 6,
      ),
    );
  }

  static OutlineInputBorder _bordure(Color couleur, {double epaisseur = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(Rayon.pilule),
        borderSide: BorderSide(color: couleur, width: epaisseur),
      );

  /// Schéma dérivé du vert du logo, puis **recalé** sur les couleurs exactes.
  ///
  /// `fromSeed` seul décalerait le vert de marque vers une teinte voisine :
  /// acceptable pour une application quelconque, pas pour une identité d'État.
  static ColorScheme _scheme(Brightness brightness) {
    final bool clair = brightness == Brightness.light;
    return ColorScheme.fromSeed(
      seedColor: AppColors.vert,
      brightness: brightness,
    ).copyWith(
      primary: clair ? AppColors.vert : const Color(0xFF4FD394),
      onPrimary: clair ? Colors.white : const Color(0xFF00301A),
      primaryContainer: clair ? AppColors.vertPale : const Color(0xFF00603A),
      onPrimaryContainer: clair ? const Color(0xFF00301A) : AppColors.vertPale,

      // Le jaune n'est jamais une action : il sert de fond d'accent, avec du
      // texte anthracite dessus — un jaune de marque ne porte pas de blanc.
      secondary: AppColors.jaune,
      onSecondary: AppColors.anthracite,
      secondaryContainer: clair ? AppColors.jaunePale : const Color(0xFF574400),
      onSecondaryContainer: clair ? const Color(0xFF3D2F00) : AppColors.jaunePale,

      error: clair ? AppColors.rouge : const Color(0xFFFF8A8C),
      onError: clair ? Colors.white : const Color(0xFF5C0004),

      surface: clair ? AppColors.surfaceClaire : AppColors.surfaceSombre,
      onSurface: clair ? AppColors.anthracite : const Color(0xFFE8EBE9),
      onSurfaceVariant: clair
          ? AppColors.texteSecondaireClair
          : AppColors.texteSecondaireSombre,
      outlineVariant: clair ? AppColors.contourClair : AppColors.contourSombre,
    );
  }

  static TextTheme _typographie(ColorScheme scheme) {
    final Color principal = scheme.onSurface;
    final Color secondaire = scheme.onSurfaceVariant;

    return TextTheme(
      // Titres d'accroche : gros, serrés, très gras — signature des maquettes.
      displaySmall: TextStyle(
        fontSize: 34,
        height: 1.18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: principal,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        height: 1.22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: principal,
      ),
      headlineSmall: TextStyle(
        fontSize: 23,
        height: 1.26,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: principal,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: principal,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: principal,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: principal,
      ),
      bodyMedium: TextStyle(
        fontSize: 14.5,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: secondaire,
      ),
      bodySmall: TextStyle(
        fontSize: 12.5,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: secondaire,
      ),
      labelLarge: const TextStyle(
        fontSize: 15.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: secondaire,
      ),
    );
  }
}
