import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import 'bordure_pointillee.dart';
import 'icone.dart';

/// Liste d'éléments que l'utilisateur ajoute et retire lui-même.
///
/// Formations et expériences ont exactement le même comportement — ajouter,
/// retirer, éditer une ligne. Les écrire deux fois inviterait les deux copies
/// à diverger ; seul le contenu d'une ligne change, et c'est [contenu] qui le
/// décrit.
class ListeDynamique<T> extends StatelessWidget {
  const ListeDynamique({
    required this.elements,
    required this.onChange,
    required this.nouveau,
    required this.titre,
    required this.contenu,
    required this.libelleAjout,
    this.messageVide,
    this.onRetirer,
    this.icone,
    super.key,
  });

  /// Pictogramme de l'étiquette de chaque carte.
  final DonneesIcone? icone;

  final List<T> elements;
  final ValueChanged<List<T>> onChange;

  /// Fabrique une ligne vierge.
  final T Function() nouveau;

  /// Titre d'une ligne, par exemple « Formation 2 ».
  final String Function(int index) titre;

  /// Champs d'une ligne. [modifier] remplace l'élément à cet index.
  final Widget Function(int index, T element, ValueChanged<T> modifier) contenu;

  final String libelleAjout;
  final String? messageVide;

  /// Prévenu **avant** le retrait de la ligne [index].
  ///
  /// Une ligne peut posséder quelque chose qui ne vit pas dans la liste — un
  /// fichier déjà sur le serveur, par exemple. Sans ce préavis, l'élément
  /// aurait disparu avant qu'on puisse savoir ce qu'il emportait.
  final void Function(int index)? onRetirer;

  void _remplacer(int index, T valeur) =>
      onChange(<T>[...elements]..[index] = valeur);

  void _retirer(int index) {
    onRetirer?.call(index);
    onChange(<T>[...elements]..removeAt(index));
  }

  void _ajouter() => onChange(<T>[...elements, nouveau()]);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (elements.isEmpty && messageVide != null)
          Padding(
            padding: const EdgeInsets.only(bottom: Espace.md),
            child: Text(messageVide!, style: theme.textTheme.bodyMedium),
          ),

        for (int i = 0; i < elements.length; i++) ...<Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Espace.md,
                Espace.sm,
                Espace.xs,
                Espace.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      _Badge(icone: icone, texte: titre(i)),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Retirer',
                        onPressed: () => _retirer(i),
                        icon: Icone(
                          Icones.supprimer,
                          taille: 20,
                          couleur: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Espace.xs),
                  Padding(
                    // Compense la marge droite réduite, laissée au bouton
                    // « Retirer » pour qu'il s'aligne sur le bord de carte.
                    padding: const EdgeInsets.only(right: Espace.xs),
                    child: contenu(
                      i,
                      elements[i],
                      (valeur) => _remplacer(i, valeur),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Espace.sm),
        ],

        ZonePointillee(
          onTap: _ajouter,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icone(
                Icones.ajouter,
                taille: 18,
                couleur: theme.colorScheme.primary,
              ),
              const SizedBox(width: Espace.xs),
              Flexible(
                child: Text(
                  libelleAjout,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Étiquette d'une carte — « Diplôme 1 » —, pastille vert pâle du web.
class _Badge extends StatelessWidget {
  const _Badge({required this.icone, required this.texte});

  final DonneesIcone? icone;
  final String texte;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool clair = theme.brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Espace.sm,
        vertical: Espace.xxs + 2,
      ),
      decoration: BoxDecoration(
        color: clair
            ? AppColors.vertPale.withValues(alpha: 0.6)
            : scheme.primaryContainer,
        borderRadius: BorderRadius.circular(Rayon.pilule),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icone != null) ...<Widget>[
            Icone(icone!, taille: 16, couleur: scheme.primary),
            const SizedBox(width: Espace.xs - 2),
          ],
          Text(
            texte,
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 13.5,
              color: clair ? scheme.primary : scheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
