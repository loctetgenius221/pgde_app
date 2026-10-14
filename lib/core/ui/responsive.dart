import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';

/// Formats d'écran visés, selon la **largeur courante**.
///
/// Le téléphone est verrouillé en portrait (§8.1) ; la tablette tourne. Une
/// tablette couchée passe donc en général de [tablette] à [large].
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

  /// Tablette couchée : la page doit occuper toute la largeur et répartir
  /// son contenu en colonnes, plutôt que d'empiler une colonne étroite au
  /// milieu d'un écran vide.
  bool get enPaysageTablette {
    final Size taille = MediaQuery.sizeOf(this);
    return taille.width > taille.height && taille.shortestSide >= 600;
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
    this.pleineLargeurEnPaysage = false,
    super.key,
  });

  final Widget child;
  final double largeurMax;
  final EdgeInsetsGeometry? padding;

  /// Lève le plafond sur une tablette couchée : la page prend tout l'écran.
  ///
  /// Réservé aux pages qui savent **répartir** leur contenu en colonnes
  /// (accueil, formulaire de demande, résumé). Un formulaire de connexion de
  /// trois champs n'a rien à mettre dans 1200 px : il reste plafonné.
  final bool pleineLargeurEnPaysage;

  @override
  Widget build(BuildContext context) => Center(
    // `heightFactor: 1` : le conteneur ne contraint que la **largeur**. Sans
    // lui, `Center` occupe toute la hauteur disponible — anodin dans le corps
    // d'une page, mais désastreux dans une barre de navigation basse, qui
    // s'étirerait alors sur tout l'écran.
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: pleineLargeurEnPaysage && context.enPaysageTablette
            ? double.infinity
            : largeurMax,
      ),
      child: Padding(
        padding:
            padding ?? EdgeInsets.symmetric(horizontal: context.margeLaterale),
        child: child,
      ),
    ),
  );
}

/// Marque un enfant de [GrilleChamps] qui doit occuper toute la ligne —
/// un choix segmenté à quatre options, une zone de texte longue.
class PleineLargeur extends StatelessWidget {
  const PleineLargeur({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// Champs répartis en colonnes selon la largeur **disponible**.
///
/// Une colonne sur téléphone, deux puis [colonnesMax] quand la place le
/// permet — comme les deux et trois colonnes du formulaire web. On mesure la
/// largeur du parent et non celle de l'écran : la même grille placée dans
/// une carte ou dans une demi-page fait le bon choix d'elle-même.
class GrilleChamps extends StatelessWidget {
  const GrilleChamps({required this.children, this.colonnesMax = 2, super.key});

  final List<Widget> children;
  final int colonnesMax;

  /// Largeur minimale d'une colonne : en dessous, un libellé comme
  /// « Département de résidence » passerait sur deux lignes.
  static const double _largeurColonneMin = 260;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, contraintes) {
      final double largeur = contraintes.maxWidth;
      final int colonnes =
          ((largeur + Espace.md) / (_largeurColonneMin + Espace.md))
              .floor()
              .clamp(1, colonnesMax);
      final double cellule = (largeur - Espace.md * (colonnes - 1)) / colonnes;

      return Wrap(
        spacing: Espace.md,
        runSpacing: Espace.md,
        children: <Widget>[
          for (final Widget enfant in children)
            SizedBox(
              width: enfant is PleineLargeur || colonnes == 1
                  ? largeur
                  : cellule,
              child: enfant,
            ),
        ],
      );
    },
  );
}
