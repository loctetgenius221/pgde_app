import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';

/// Formats d'écran visés. L'app est verrouillée en portrait (§8.1) : ces
/// seuils décrivent donc une largeur de portrait, pas une orientation.
enum FormatEcran {
  /// Téléphone — le cas nominal.
  telephone,

  /// Tablette 7–11 pouces en portrait.
  tablette,

  /// Grande tablette.
  large;

  bool get estTablette => this != FormatEcran.telephone;
}

extension FormatEcranDeContexte on BuildContext {
  FormatEcran get format {
    final double largeur = MediaQuery.sizeOf(this).width;
    if (largeur >= 900) return FormatEcran.large;
    if (largeur >= 600) return FormatEcran.tablette;
    return FormatEcran.telephone;
  }

  /// Marge latérale : une tablette ne doit pas coller le texte au bord.
  double get margeLaterale => switch (format) {
    FormatEcran.telephone => Espace.lg,
    FormatEcran.tablette => Espace.xl,
    FormatEcran.large => Espace.xxl,
  };

  /// Renvoie la valeur correspondant au format courant.
  T selonFormat<T>({required T telephone, T? tablette, T? large}) =>
      switch (format) {
        FormatEcran.telephone => telephone,
        FormatEcran.tablette => tablette ?? telephone,
        FormatEcran.large => large ?? tablette ?? telephone,
      };
}

/// Largeurs de lecture confortables, en pixels logiques.
abstract final class LargeurMax {
  /// Formulaires : au-delà, l'œil perd le lien entre libellé et champ, et les
  /// boutons pilule deviennent des barres absurdes.
  static const double formulaire = 520;

  /// Contenu lu ou parcouru : listes, résumé du dossier.
  static const double contenu = 760;
}

/// Centre le contenu et plafonne sa largeur.
///
/// C'est **la** pièce qui rend l'app utilisable sur tablette : sans elle, un
/// champ de saisie s'étire sur 1200 px et la page paraît vide.
class ConteneurPage extends StatelessWidget {
  const ConteneurPage({
    required this.child,
    this.largeurMax = LargeurMax.formulaire,
    this.padding,
    super.key,
  });

  final Widget child;
  final double largeurMax;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Center(
    // `heightFactor: 1` : le conteneur ne contraint que la **largeur**. Sans
    // lui, `Center` occupe toute la hauteur disponible — anodin dans le corps
    // d'une page, mais désastreux dans une barre de navigation basse, qui
    // s'étirerait alors sur tout l'écran.
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: largeurMax),
      child: Padding(
        padding:
            padding ?? EdgeInsets.symmetric(horizontal: context.margeLaterale),
        child: child,
      ),
    ),
  );
}
