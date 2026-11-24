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
    // Police appliquée **ici**, et pas seulement via `ThemeData.fontFamily` :
    // ce dernier ne touche que `textTheme`. Les styles repris tels quels
    // ailleurs — titre de l'AppBar, libellés des boutons — restaient sinon
    // en Roboto, la police par défaut d'Android.
    final TextTheme texte = _typographie(scheme).apply(fontFamily: _police);

    /// Fond de tout ce qui surgit par-dessus la page — feuilles, menus,
    /// dialogues. Identique à la surface des cartes, pour qu'un élément
    /// flottant ne se distingue que par son ombre.
    final Color surfaceFlottante = clair
        ? AppColors.surfaceClaire
        : AppColors.surfaceSombre;

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

      // Champs aux formes de la plateforme web — rectangle arrondi à
      // `Rayon.champ`, trait fin — pour qu'un candidat passant du site à
      // l'application retrouve les mêmes repères. Fond blanc comme les cartes
      // de « Mon dossier » ; seul un champ inactif reste grisé. Le contour ne
      // s'affirme qu'au focus.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: WidgetStateColor.resolveWith(
          (etats) => etats.contains(WidgetState.disabled) && clair
              ? AppColors.champDesactiveClair
              : (clair ? AppColors.champClair : AppColors.champSombre),
        ),
        // Hauteur de champ ramenée à 48 dp, la cible tactile de référence
        // (Material, WCAG) : au-delà, un formulaire de trente champs défile
        // sans fin sur un téléphone.
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Espace.md,
          vertical: Espace.sm + 2,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 48,
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 48,
        ),
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
          minimumSize: const Size.fromHeight(52),
          shape: _formeBouton,
          textStyle: texte.labelLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: _formeBouton,
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
          borderRadius: BorderRadius.circular(Rayon.md),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Rayon.md),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: Espace.md),
      ),

      // --- Surfaces flottantes ---
      //
      // Material 3 sert ces surfaces depuis les rôles `surfaceContainer*`,
      // que `fromSeed` teinte de vert. Une feuille de sélection ou un menu
      // arrivaient donc en vert pâle, alors que la page qu'ils recouvrent est
      // blanche : l'élément *surgissant* paraissait moins net que le fond.
      // On les ramène tous sur la même surface, et on coupe la teinte
      // d'élévation qui la reverdirait.
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceFlottante,
        modalBackgroundColor: surfaceFlottante,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Rayon.lg)),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: surfaceFlottante,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Rayon.md),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),

      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll<Color>(surfaceFlottante),
          surfaceTintColor: const WidgetStatePropertyAll<Color>(
            Colors.transparent,
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surfaceFlottante,
        surfaceTintColor: Colors.transparent,
      ),

      datePickerTheme: DatePickerThemeData(
        backgroundColor: surfaceFlottante,
        surfaceTintColor: Colors.transparent,
      ),

      timePickerTheme: TimePickerThemeData(backgroundColor: surfaceFlottante),

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
        contentTextStyle: texte.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.outlineVariant,
        linearMinHeight: 6,
      ),
    );
  }

  /// Boutons au même rayon que les champs, comme sur le web.
  static const RoundedRectangleBorder _formeBouton = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(Rayon.champ)),
  );

  static OutlineInputBorder _bordure(Color couleur, {double epaisseur = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(Rayon.champ),
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

      // **Un seul jaune, #FFCC34, et aucune variante.**
      //
      // Les quatre rôles « secondary » sont recalés sur la même valeur. Sans
      // cela, `fromSeed` en dérive des teintes voisines — un jaune pâle pour
      // `secondaryContainer`, un brun pour `onSecondaryContainer` — que
      // Material 3 applique ensuite tout seul, notamment au fond des segments
      // sélectionnés d'un `SegmentedButton`. Deux jaunes cohabitaient donc à
      // l'écran sans que personne les ait choisis.
      //
      // Le texte posé dessus est toujours anthracite : un jaune de marque ne
      // porte pas de blanc.
      secondary: AppColors.jaune,
      onSecondary: AppColors.anthracite,
      secondaryContainer: AppColors.jaune,
      onSecondaryContainer: AppColors.anthracite,

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
