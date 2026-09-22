import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
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
    super.key,
  });

  final List<T> elements;
  final ValueChanged<List<T>> onChange;

  /// Fabrique une ligne vierge.
  final T Function() nouveau;

  /// Titre d'une ligne, par exemple « Formation 2 ».
  final String Function(int index) titre;

  /// Champs d'une ligne. [modifier] remplace l'élément à cet index.
  final Widget Function(T element, ValueChanged<T> modifier) contenu;

  final String libelleAjout;
  final String? messageVide;

  void _remplacer(int index, T valeur) =>
      onChange(<T>[...elements]..[index] = valeur);

  void _retirer(int index) => onChange(<T>[...elements]..removeAt(index));

  void _ajouter() => onChange(<T>[...elements, nouveau()]);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (elements.isEmpty && messageVide != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Espace.md),
            child: Text(messageVide!, style: theme.textTheme.bodyMedium),
          ),

        for (int i = 0; i < elements.length; i++) ...<Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Espace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          titre(i),
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
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
                  contenu(elements[i], (valeur) => _remplacer(i, valeur)),
                ],
              ),
            ),
          ),
          const SizedBox(height: Espace.sm),
        ],

        OutlinedButton.icon(
          onPressed: _ajouter,
          icon: const Icone(Icones.ajouter, taille: 20),
          label: Text(libelleAjout),
        ),
      ],
    );
  }
}
