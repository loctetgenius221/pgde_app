import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import 'icone.dart';
import 'responsive.dart';

/// Champs de saisie du wizard.
///
/// Le dossier compte une trentaine de champs répartis sur quatre écrans. Les
/// écrire un par un produirait des centaines de lignes quasi identiques — et
/// autant d'occasions d'oublier une marge, un clavier ou un message d'erreur.
/// Quatre composants couvrent l'ensemble ; les écrans ne décrivent plus que
/// *quoi* saisir, jamais *comment*.

/// Libellé de champ, suivi d'un astérisque quand la saisie est obligatoire.
///
/// L'astérisque porte la couleur d'erreur. C'est la convention universelle, et
/// elle ne dilue pas la règle de la palette : un champ obligatoire laissé vide
/// **est** ce qui bloquera l'envoi. Le rouge reste donc réservé à ce qui
/// empêche d'avancer.
Widget libelleObligatoire(BuildContext context, String libelle) => Text.rich(
  TextSpan(
    text: libelle,
    children: <InlineSpan>[
      TextSpan(
        text: ' *',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    ],
  ),
);

/// Libellé posé **au-dessus** du champ, comme sur la plateforme web.
///
/// Un libellé flottant disparaît dans la bordure une fois le champ rempli ;
/// au-dessus, il reste lisible — et le candidat retrouve la disposition qu'il
/// connaît déjà sur le site.
class ChampLibelle extends StatelessWidget {
  const ChampLibelle({
    required this.libelle,
    required this.child,
    this.obligatoire = false,
    this.facultatif = false,
    super.key,
  });

  final String libelle;
  final bool obligatoire;

  /// Ajoute la pastille « facultatif » du web. À réserver aux champs qu'on
  /// pourrait croire exigés — téléphone secondaire, justificatif — et non à
  /// tout ce qui n'a pas d'astérisque : trente pastilles ne diraient plus rien.
  final bool facultatif;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Widget texte = obligatoire
        ? libelleObligatoire(context, libelle)
        : Text(libelle);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        DefaultTextStyle.merge(
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
          child: facultatif
              ? Wrap(
                  spacing: Espace.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[texte, const PastilleFacultatif()],
                )
              : texte,
        ),
        const SizedBox(height: Espace.xs - 2),
        child,
      ],
    );
  }
}

/// Petite pastille grise « facultatif », comme sur la plateforme web.
class PastilleFacultatif extends StatelessWidget {
  const PastilleFacultatif({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool clair = theme.brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Espace.xs, vertical: 1),
      decoration: BoxDecoration(
        color: clair ? AppColors.pisteClaire : AppColors.pisteSombre,
        borderRadius: BorderRadius.circular(Rayon.pilule),
      ),
      child: Text(
        'facultatif',
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Phrase d'introduction en tête d'étape : dit en une ligne ce qu'on attend,
/// comme le fait le formulaire web.
class IntroEtape extends StatelessWidget {
  const IntroEtape(this.texte, {super.key});

  final String texte;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Espace.sm, bottom: Espace.md),
    child: Text(texte, style: Theme.of(context).textTheme.bodyMedium),
  );
}

/// Rappel de la convention, à placer une fois en tête d'étape.
class LegendeObligatoire extends StatelessWidget {
  const LegendeObligatoire({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Espace.xxs, bottom: Espace.sm),
    child: Text(
      '* Champs obligatoires',
      style: Theme.of(context).textTheme.bodySmall,
    ),
  );
}

/// Champ texte piloté par l'état, sans `TextEditingController` chez l'appelant.
class ChampTexte extends StatefulWidget {
  const ChampTexte({
    required this.libelle,
    required this.valeur,
    required this.onChange,
    this.icone,
    this.aide,
    this.erreur,
    this.clavier,
    this.formatteurs,
    this.lignes = 1,
    this.longueurMax,
    this.majusculesAutomatiques = false,
    this.obligatoire = false,
    this.facultatif = false,
    this.indication,
    this.masquerLibelle = false,
    super.key,
  });

  /// N'affiche pas le libellé : un intitulé de section le porte déjà.
  final bool masquerLibelle;

  final String libelle;
  final String valeur;
  final ValueChanged<String> onChange;
  final DonneesIcone? icone;
  final String? aide;
  final String? erreur;
  final TextInputType? clavier;
  final List<TextInputFormatter>? formatteurs;
  final int lignes;
  final int? longueurMax;
  final bool majusculesAutomatiques;
  final bool obligatoire;
  final bool facultatif;

  /// Exemple affiché dans le champ vide — « ex : Licence en comptabilité ».
  final String? indication;

  @override
  State<ChampTexte> createState() => _ChampTexteState();
}

class _ChampTexteState extends State<ChampTexte> {
  late final TextEditingController _controleur = TextEditingController(
    text: widget.valeur,
  );

  @override
  void didUpdateWidget(ChampTexte oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ne réécrit que si la valeur vient d'ailleurs — reprise d'un brouillon,
    // réinitialisation. Pendant la frappe les deux sont déjà égales, donc le
    // curseur ne bouge pas.
    if (widget.valeur != _controleur.text) {
      _controleur.text = widget.valeur;
    }
  }

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget champ = _champ();
    if (widget.masquerLibelle) {
      // Le libellé reste annoncé aux lecteurs d'écran, même invisible.
      return Semantics(label: widget.libelle, child: champ);
    }
    return ChampLibelle(
      libelle: widget.libelle,
      obligatoire: widget.obligatoire,
      facultatif: widget.facultatif,
      child: champ,
    );
  }

  Widget _champ() => TextField(
    controller: _controleur,
    onChanged: widget.onChange,
    keyboardType: widget.clavier,
    inputFormatters: widget.formatteurs,
    minLines: widget.lignes,
    maxLines: widget.lignes,
    maxLength: widget.longueurMax,
    textCapitalization: widget.majusculesAutomatiques
        ? TextCapitalization.words
        : TextCapitalization.none,
    decoration: InputDecoration(
      hintText: widget.indication,
      helperText: widget.aide,
      errorText: widget.erreur,
      prefixIcon: widget.icone == null ? null : PrefixeChamp(widget.icone!),
    ),
  );
}

/// Sélection dans une liste, présentée en feuille modale.
///
/// Un `DropdownButton` est inutilisable au-delà de quelques dizaines
/// d'entrées : le référentiel compte 491 emplois et ~195 pays (§8.9). La
/// feuille modale offre la place et, au besoin, une recherche.
class ChampSelection<T> extends StatelessWidget {
  const ChampSelection({
    required this.libelle,
    required this.valeur,
    required this.elements,
    required this.etiquette,
    required this.onChange,
    this.icone,
    this.aide,
    this.erreur,
    this.recherche = false,
    this.messageListeVide,
    this.obligatoire = false,
    this.facultatif = false,
    this.indication = 'Sélectionner',
    super.key,
  });

  final String libelle;
  final T? valeur;
  final List<T> elements;
  final String Function(T) etiquette;
  final ValueChanged<T?> onChange;
  final DonneesIcone? icone;
  final String? aide;
  final String? erreur;

  /// Ajoute un filtre textuel. À activer dès que la liste dépasse l'écran.
  final bool recherche;

  /// Affiché **dans** le champ tant que la liste est vide — « Choisissez
  /// d'abord une région » —, là où le regard cherche la valeur.
  final String? messageListeVide;
  final bool obligatoire;
  final bool facultatif;

  /// Texte du champ tant que rien n'est choisi.
  final String indication;

  bool get _actif => elements.isNotEmpty;

  Future<void> _ouvrir(BuildContext context) async {
    if (!_actif) return;
    final T? choix = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FeuilleSelection<T>(
        titre: libelle,
        elements: elements,
        etiquette: etiquette,
        selection: valeur,
        recherche: recherche,
      ),
    );
    if (choix != null) onChange(choix);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool vide = valeur == null;

    return ChampLibelle(
      libelle: libelle,
      obligatoire: obligatoire,
      facultatif: facultatif,
      child: InkWell(
        onTap: _actif ? () => _ouvrir(context) : null,
        borderRadius: BorderRadius.circular(Rayon.champ),
        child: InputDecorator(
          isEmpty: false,
          decoration: InputDecoration(
            helperText: aide,
            errorText: erreur,
            enabled: _actif,
            prefixIcon: icone == null ? null : PrefixeChamp(icone!),
            suffixIcon: const SuffixeChamp(HugeIcons.strokeRoundedArrowDown01),
          ),
          child: Text(
            !_actif && messageListeVide != null
                ? messageListeVide!
                : vide
                ? indication
                : etiquette(valeur as T),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: vide || !_actif
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeuilleSelection<T> extends StatefulWidget {
  const _FeuilleSelection({
    required this.titre,
    required this.elements,
    required this.etiquette,
    required this.selection,
    required this.recherche,
  });

  final String titre;
  final List<T> elements;
  final String Function(T) etiquette;
  final T? selection;
  final bool recherche;

  @override
  State<_FeuilleSelection<T>> createState() => _FeuilleSelectionState<T>();
}

class _FeuilleSelectionState<T> extends State<_FeuilleSelection<T>> {
  String _filtre = '';

  List<T> get _visibles {
    if (_filtre.trim().isEmpty) return widget.elements;
    final String recherche = _sansAccent(_filtre);
    return widget.elements
        .where((e) => _sansAccent(widget.etiquette(e)).contains(recherche))
        .toList();
  }

  /// Les libellés du référentiel sont accentués et parfois mal orthographiés
  /// (§5.4). Chercher « telecom » doit trouver « Télécom ».
  static String _sansAccent(String texte) {
    const String accents = 'àâäáãçéèêëíìîïñóòôöõúùûüýÿ';
    const String simples = 'aaaaaceeeeiiiinooooouuuuyy';
    final StringBuffer sortie = StringBuffer();
    for (final int unite in texte.toLowerCase().runes) {
      final int position = accents.indexOf(String.fromCharCode(unite));
      sortie.write(
        position == -1 ? String.fromCharCode(unite) : simples[position],
      );
    }
    return sortie.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<T> visibles = _visibles;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.78,
          ),
          child: ConteneurPage(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(widget.titre, style: theme.textTheme.titleLarge),
                const SizedBox(height: Espace.md),
                if (widget.recherche) ...<Widget>[
                  TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Rechercher…',
                      prefixIcon: PrefixeChamp(HugeIcons.strokeRoundedSearch01),
                    ),
                    onChanged: (v) => setState(() => _filtre = v),
                  ),
                  const SizedBox(height: Espace.sm),
                ],
                Flexible(
                  child: visibles.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(Espace.xl),
                          child: Text(
                            'Aucun résultat pour « $_filtre ».',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: visibles.length,
                          itemBuilder: (context, i) {
                            final T element = visibles[i];
                            final bool choisi = element == widget.selection;
                            return ListTile(
                              title: Text(widget.etiquette(element)),
                              selected: choisi,
                              trailing: choisi
                                  ? Icone(
                                      HugeIcons.strokeRoundedTick02,
                                      couleur: theme.colorScheme.primary,
                                    )
                                  : null,
                              onTap: () => Navigator.of(context).pop(element),
                            );
                          },
                        ),
                ),
                const SizedBox(height: Espace.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Choix parmi quelques options courtes, affichées d'un bloc.
///
/// Même dessin que sur la plateforme web : une piste grise sur laquelle
/// l'option retenue se détache en blanc, texte vert et gras. Au-delà de trois
/// options, la largeur d'un téléphone ne suffit plus : [colonnes] répartit
/// alors les options sur plusieurs lignes (4 situations matrimoniales → 2 × 2).
class ChoixSegmente<T> extends StatelessWidget {
  const ChoixSegmente({
    required this.libelle,
    required this.valeur,
    required this.options,
    required this.etiquette,
    required this.onChange,
    this.erreur,
    this.obligatoire = false,
    this.facultatif = false,
    this.colonnes,
    this.icone,
    super.key,
  });

  final String libelle;
  final T? valeur;
  final List<T> options;
  final String Function(T) etiquette;
  final ValueChanged<T> onChange;
  final String? erreur;
  final bool obligatoire;
  final bool facultatif;

  /// Options par ligne quand la place manque. Par défaut, toutes sur une
  /// seule. Dès que la largeur offre [_largeurOptionMin] par option, elles
  /// repassent toutes sur une ligne — sur tablette notamment.
  final int? colonnes;

  /// Pictogramme posé devant le libellé de chaque option. Facultatif.
  final DonneesIcone Function(T)? icone;

  static const double _largeurOptionMin = 120;

  @override
  Widget build(BuildContext context) => ChampLibelle(
    libelle: libelle,
    obligatoire: obligatoire,
    facultatif: facultatif,
    child: LayoutBuilder(
      builder: (context, contraintes) =>
          _choix(context, _parLigne(context, contraintes.maxWidth)),
    ),
  );

  /// Options par ligne pour une piste large de [largeur].
  ///
  /// On part du plus large possible, puis on resserre tant qu'un libellé ne
  /// tient pas sur **une** ligne dans sa case : « Oui, j'ai de l'expérience »
  /// coupé en deux, icône décentrée, faisait brouillon. Au pire, les options
  /// s'empilent une par ligne, comme des cartes de choix.
  int _parLigne(BuildContext context, double largeur) {
    final int initial = largeur >= options.length * _largeurOptionMin
        ? options.length
        : colonnes ?? options.length;

    final TextStyle style = Theme.of(
      context,
    ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600);
    final TextScaler echelle = MediaQuery.textScalerOf(context);
    final double plusLarge = options
        .map((o) {
          final TextPainter mesure = TextPainter(
            text: TextSpan(text: etiquette(o), style: style),
            textDirection: Directionality.of(context),
            textScaler: echelle,
            maxLines: 1,
          )..layout();
          // Marges du segment, plus l'icône et son écart s'il y en a une.
          return mesure.width +
              Espace.xxs * 2 +
              Espace.sm +
              (icone == null ? 0 : 18 + Espace.xs - 2);
        })
        .fold<double>(0, (a, b) => a > b ? a : b);

    // Largeur utile de la piste : sa marge intérieure et son filet en moins.
    final double utile = largeur - Espace.xxs * 2 - 2;
    for (int n = initial; n > 1; n--) {
      if (utile / n >= plusLarge) return n;
    }
    return 1;
  }

  Widget _choix(BuildContext context, int parLigne) {
    final theme = Theme.of(context);
    final bool clair = theme.brightness == Brightness.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(Espace.xxs),
          decoration: BoxDecoration(
            // Piste blanche en clair, comme les champs : l'option retenue se
            // distingue par son vert pâle, pas par un fond gris autour d'elle.
            color: clair ? theme.colorScheme.surface : AppColors.pisteSombre,
            borderRadius: BorderRadius.circular(Rayon.champ),
            border: Border.all(
              color: erreur != null
                  ? theme.colorScheme.error
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            children: <Widget>[
              for (int debut = 0; debut < options.length; debut += parLigne)
                Row(
                  children: <Widget>[
                    for (int i = debut; i < debut + parLigne; i++)
                      Expanded(
                        child: i < options.length
                            ? _Segment(
                                libelle: etiquette(options[i]),
                                icone: icone?.call(options[i]),
                                choisi: options[i] == valeur,
                                onTap: () => onChange(options[i]),
                              )
                            // Case vide : garde la largeur des colonnes
                            // quand la dernière ligne est incomplète.
                            : const SizedBox.shrink(),
                      ),
                  ],
                ),
            ],
          ),
        ),
        if (erreur != null)
          Padding(
            padding: const EdgeInsets.only(top: Espace.xxs, left: Espace.sm),
            child: Text(
              erreur!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.libelle,
    required this.choisi,
    required this.onTap,
    this.icone,
  });

  final String libelle;
  final DonneesIcone? icone;
  final bool choisi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool clair = theme.brightness == Brightness.light;
    // Rayon intérieur = rayon de la piste moins sa marge : les deux courbes
    // restent parallèles.
    final BorderRadius arrondi = BorderRadius.circular(
      Rayon.champ - Espace.xxs,
    );
    final Color couleur = choisi ? scheme.primary : scheme.onSurfaceVariant;
    final Widget texte = Text(
      libelle,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );

    return Semantics(
      button: true,
      selected: choisi,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: Duree.rapide,
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 42),
          padding: const EdgeInsets.symmetric(
            horizontal: Espace.xxs,
            vertical: Espace.xs,
          ),
          alignment: Alignment.center,
          decoration: clair
              // Option retenue en vert pâle cerné de vert : le langage des
              // tuiles de « Mon dossier ».
              ? BoxDecoration(
                  color: choisi
                      ? AppColors.vertPale.withValues(alpha: 0.6)
                      : Colors.transparent,
                  borderRadius: arrondi,
                  border: Border.all(
                    color: choisi
                        ? scheme.primary.withValues(alpha: 0.45)
                        : Colors.transparent,
                  ),
                )
              : BoxDecoration(
                  color: choisi ? scheme.surface : Colors.transparent,
                  borderRadius: arrondi,
                  boxShadow: choisi
                      ? <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : const <BoxShadow>[],
                ),
          child: AnimatedDefaultTextStyle(
            duration: Duree.rapide,
            style: theme.textTheme.bodyMedium!.copyWith(
              fontWeight: choisi ? FontWeight.w600 : FontWeight.w400,
              color: couleur,
            ),
            child: icone == null
                ? texte
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icone(icone!, taille: 18, couleur: couleur),
                      const SizedBox(width: Espace.xs - 2),
                      Flexible(child: texte),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Saisie d'un petit nombre entier par boutons − / +, comme sur le web.
///
/// Plus sûr qu'un clavier numérique pour un nombre d'enfants : pas de valeur
/// négative, pas de « 1O » tapé au pouce.
class ChampCompteur extends StatelessWidget {
  const ChampCompteur({
    required this.libelle,
    required this.valeur,
    required this.onChange,
    this.minimum = 0,
    this.maximum = 30,
    this.erreur,
    this.obligatoire = false,
    this.facultatif = false,
    super.key,
  });

  final String libelle;
  final int valeur;
  final ValueChanged<int> onChange;
  final int minimum;
  final int maximum;
  final String? erreur;
  final bool obligatoire;
  final bool facultatif;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final BorderSide trait = BorderSide(
      color: erreur != null
          ? theme.colorScheme.error
          : theme.colorScheme.outlineVariant,
    );

    Widget bouton(
      DonneesIcone icone,
      String description,
      VoidCallback? action,
    ) => Semantics(
      button: true,
      label: description,
      child: InkWell(
        onTap: action,
        child: SizedBox(
          width: 52,
          height: 48,
          child: Center(
            child: Icone(
              icone,
              taille: 18,
              couleur: action == null
                  ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );

    return ChampLibelle(
      libelle: libelle,
      obligatoire: obligatoire,
      facultatif: facultatif,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Material(
            color: theme.colorScheme.surface,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Rayon.champ),
              side: trait,
            ),
            child: Row(
              children: <Widget>[
                bouton(
                  Icones.moins,
                  'Diminuer',
                  valeur > minimum ? () => onChange(valeur - 1) : null,
                ),
                Expanded(
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border(left: trait, right: trait),
                    ),
                    child: Text('$valeur', style: theme.textTheme.bodyLarge),
                  ),
                ),
                bouton(
                  Icones.ajouter,
                  'Augmenter',
                  valeur < maximum ? () => onChange(valeur + 1) : null,
                ),
              ],
            ),
          ),
          if (erreur != null)
            Padding(
              padding: const EdgeInsets.only(top: Espace.xxs, left: Espace.sm),
              child: Text(
                erreur!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Saisie d'une date par le sélecteur natif.
///
/// Affichage en `jj/MM/aaaa`, envoi en `AAAA-MM-JJ` — la conversion est faite
/// par le convertisseur du domaine, jamais ici (§8.9).
class ChampDate extends StatelessWidget {
  const ChampDate({
    required this.libelle,
    required this.valeur,
    required this.onChange,
    this.icone,
    this.erreur,
    this.premiereDate,
    this.derniereDate,
    this.obligatoire = false,
    this.facultatif = false,
    super.key,
  });

  final String libelle;
  final DateTime? valeur;
  final ValueChanged<DateTime> onChange;
  final DonneesIcone? icone;
  final String? erreur;
  final DateTime? premiereDate;
  final DateTime? derniereDate;
  final bool obligatoire;
  final bool facultatif;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final DateTime aujourdhui = DateTime.now();

    return ChampLibelle(
      libelle: libelle,
      obligatoire: obligatoire,
      facultatif: facultatif,
      child: InkWell(
        borderRadius: BorderRadius.circular(Rayon.champ),
        onTap: () async {
          final DateTime? choix = await showDatePicker(
            context: context,
            initialDate: valeur ?? DateTime(aujourdhui.year - 25),
            firstDate: premiereDate ?? DateTime(aujourdhui.year - 80),
            lastDate: derniereDate ?? aujourdhui,
            locale: const Locale('fr', 'FR'),
          );
          if (choix != null) onChange(choix);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            errorText: erreur,
            prefixIcon: icone == null ? null : PrefixeChamp(icone!),
            suffixIcon: const SuffixeChamp(HugeIcons.strokeRoundedCalendar03),
          ),
          child: Text(
            valeur == null
                ? 'Sélectionner'
                : DateFormat('dd/MM/yyyy', 'fr_FR').format(valeur!),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: valeur == null
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

/// Intertitre d'un groupe de champs.
class TitreSection extends StatelessWidget {
  const TitreSection(this.titre, {this.aide, super.key});

  final String titre;
  final String? aide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: Espace.lg, bottom: Espace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(titre, style: theme.textTheme.titleMedium),
          if (aide != null)
            Padding(
              padding: const EdgeInsets.only(top: Espace.xxs),
              child: Text(aide!, style: theme.textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}

/// Formateurs prêts à l'emploi.
abstract final class Formats {
  static final List<TextInputFormatter> chiffres = <TextInputFormatter>[
    FilteringTextInputFormatter.digitsOnly,
  ];

  /// Numéros de téléphone : chiffres, espaces et `+` (varchar 45, §8.9).
  static final List<TextInputFormatter> telephone = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
    LengthLimitingTextInputFormatter(45),
  ];
}
