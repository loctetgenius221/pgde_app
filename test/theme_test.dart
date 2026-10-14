import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pgde_app/core/theme/app_colors.dart';
import 'package:pgde_app/core/theme/app_theme.dart';

/// Tous les rôles de couleur qu'un composant Material peut appliquer seul.
///
/// C'est par l'un d'eux qu'un second jaune s'était introduit :
/// `SegmentedButton` peint le segment sélectionné avec `secondaryContainer`,
/// que `fromSeed` avait dérivé en `#FFF3D2`.
Map<String, Color> _roles(ColorScheme s) => <String, Color>{
  'primary': s.primary,
  'onPrimary': s.onPrimary,
  'primaryContainer': s.primaryContainer,
  'onPrimaryContainer': s.onPrimaryContainer,
  'primaryFixed': s.primaryFixed,
  'primaryFixedDim': s.primaryFixedDim,
  'onPrimaryFixed': s.onPrimaryFixed,
  'onPrimaryFixedVariant': s.onPrimaryFixedVariant,
  'secondary': s.secondary,
  'onSecondary': s.onSecondary,
  'secondaryContainer': s.secondaryContainer,
  'onSecondaryContainer': s.onSecondaryContainer,
  'secondaryFixed': s.secondaryFixed,
  'secondaryFixedDim': s.secondaryFixedDim,
  'onSecondaryFixed': s.onSecondaryFixed,
  'onSecondaryFixedVariant': s.onSecondaryFixedVariant,
  'tertiary': s.tertiary,
  'onTertiary': s.onTertiary,
  'tertiaryContainer': s.tertiaryContainer,
  'onTertiaryContainer': s.onTertiaryContainer,
  'tertiaryFixed': s.tertiaryFixed,
  'tertiaryFixedDim': s.tertiaryFixedDim,
  'onTertiaryFixed': s.onTertiaryFixed,
  'onTertiaryFixedVariant': s.onTertiaryFixedVariant,
  'error': s.error,
  'onError': s.onError,
  'errorContainer': s.errorContainer,
  'onErrorContainer': s.onErrorContainer,
  'surface': s.surface,
  'onSurface': s.onSurface,
  'onSurfaceVariant': s.onSurfaceVariant,
  'outline': s.outline,
  'outlineVariant': s.outlineVariant,
  'inverseSurface': s.inverseSurface,
  'onInverseSurface': s.onInverseSurface,
  'inversePrimary': s.inversePrimary,
  'surfaceTint': s.surfaceTint,
};

/// Une couleur perçue comme « jaune » : teinte entre 35° et 70°, assez saturée
/// et ni noire ni blanche.
bool _percuJaune(Color couleur) {
  final HSLColor hsl = HSLColor.fromColor(couleur);
  return hsl.hue >= 35 &&
      hsl.hue <= 70 &&
      hsl.saturation >= 0.25 &&
      hsl.lightness > 0.12 &&
      hsl.lightness < 0.96;
}

void main() {
  for (final (String nom, ThemeData theme) in <(String, ThemeData)>[
    ('clair', AppTheme.light()),
    ('sombre', AppTheme.dark()),
  ]) {
    group('Thème $nom', () {
      final ColorScheme scheme = theme.colorScheme;

      test('les couleurs de marque sont exactement celles du logo', () {
        expect(scheme.secondary, AppColors.jaune);
        expect(scheme.secondaryContainer, AppColors.jaune);
        expect(scheme.onSecondary, AppColors.anthracite);
        expect(scheme.onSecondaryContainer, AppColors.anthracite);
      });

      test('aucun autre jaune ne circule dans le schéma', () {
        final Iterable<String> intrus = _roles(scheme).entries
            .where((e) => _percuJaune(e.value) && e.value != AppColors.jaune)
            .map((e) => '${e.key} = #${_hex(e.value)}');

        expect(
          intrus,
          isEmpty,
          reason:
              'Ces rôles portent un jaune qui n’est pas #FFCC34. Material les '
              'applique sans qu’on le demande : il faut les recaler dans '
              'AppTheme._scheme.',
        );
      });
    });
  }

  test('le vert et le rouge de marque sont exacts en thème clair', () {
    final ColorScheme scheme = AppTheme.light().colorScheme;
    expect(scheme.primary, AppColors.vert);
    expect(scheme.error, AppColors.rouge);
    expect(scheme.onSurface, AppColors.anthracite);
  });

  test('rien de ce qui surgit n’arrive teinté de vert', () {
    // `ColorScheme.fromSeed` teinte les rôles `surfaceContainer*` avec la
    // graine verte, et Material 3 y puise le fond des feuilles, menus et
    // dialogues. Une feuille de sélection arrivait donc en vert pâle
    // au-dessus d'une page blanche.
    final ThemeData clair = AppTheme.light();

    expect(clair.bottomSheetTheme.backgroundColor, AppColors.surfaceClaire);
    expect(
      clair.bottomSheetTheme.modalBackgroundColor,
      AppColors.surfaceClaire,
    );
    expect(clair.popupMenuTheme.color, AppColors.surfaceClaire);
    expect(clair.dialogTheme.backgroundColor, AppColors.surfaceClaire);
    expect(clair.datePickerTheme.backgroundColor, AppColors.surfaceClaire);

    // La teinte d'élévation reverdirait la surface dès qu'elle s'élève :
    // la couper est aussi nécessaire que de poser le fond.
    expect(clair.bottomSheetTheme.surfaceTintColor, Colors.transparent);
    expect(clair.popupMenuTheme.surfaceTintColor, Colors.transparent);
    expect(clair.dialogTheme.surfaceTintColor, Colors.transparent);
  });

  test('le thème sombre garde ses surfaces sombres', () {
    // Forcer le blanc partout aurait crevé l'écran en thème sombre.
    final ThemeData sombre = AppTheme.dark();
    expect(sombre.bottomSheetTheme.backgroundColor, AppColors.surfaceSombre);
    expect(sombre.popupMenuTheme.color, AppColors.surfaceSombre);
  });
}

String _hex(Color c) =>
    ((c.r * 255).round() << 16 | (c.g * 255).round() << 8 | (c.b * 255).round())
        .toRadixString(16)
        .padLeft(6, '0')
        .toUpperCase();
