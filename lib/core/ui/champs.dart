import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

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
    super.key,
  });

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
    final bool multiligne = widget.lignes > 1;
    return TextField(
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
        labelText: widget.libelle,
        helperText: widget.aide,
        errorText: widget.erreur,
        prefixIcon: widget.icone == null ? null : PrefixeChamp(widget.icone!),
        // Un champ multiligne ne peut pas être une pilule : le rayon du thème
        // avalerait les lignes du milieu.
        border: multiligne ? _bordureMultiligne(context) : null,
        enabledBorder: multiligne ? _bordureMultiligne(context) : null,
        alignLabelWithHint: multiligne,
      ),
    );
  }

  OutlineInputBorder _bordureMultiligne(BuildContext context) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(Rayon.lg),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
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

  final String? messageListeVide;

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

    return InkWell(
      onTap: _actif ? () => _ouvrir(context) : null,
      borderRadius: BorderRadius.circular(Rayon.pilule),
      child: InputDecorator(
        isEmpty: false,
        decoration: InputDecoration(
          labelText: libelle,
          helperText: _actif ? aide : (messageListeVide ?? aide),
          errorText: erreur,
          enabled: _actif,
          prefixIcon: icone == null ? null : PrefixeChamp(icone!),
          suffixIcon: const SuffixeChamp(HugeIcons.strokeRoundedArrowDown01),
        ),
        child: Text(
          vide ? 'Sélectionner' : etiquette(valeur as T),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: vide || !_actif
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onSurface,
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

/// Choix parmi deux ou trois options courtes, affichées d'un bloc.
class ChoixSegmente<T> extends StatelessWidget {
  const ChoixSegmente({
    required this.libelle,
    required this.valeur,
    required this.options,
    required this.etiquette,
    required this.onChange,
    this.erreur,
    super.key,
  });

  final String libelle;
  final T? valeur;
  final List<T> options;
  final String Function(T) etiquette;
  final ValueChanged<T> onChange;
  final String? erreur;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(libelle, style: theme.textTheme.labelMedium),
        const SizedBox(height: Espace.xs),
        SegmentedButton<T>(
          segments: <ButtonSegment<T>>[
            for (final T option in options)
              ButtonSegment<T>(value: option, label: Text(etiquette(option))),
          ],
          selected: valeur == null ? <T>{} : <T>{valeur as T},
          emptySelectionAllowed: true,
          showSelectedIcon: false,
          onSelectionChanged: (choix) => onChange(choix.first),
          style: SegmentedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
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
    super.key,
  });

  final String libelle;
  final DateTime? valeur;
  final ValueChanged<DateTime> onChange;
  final DonneesIcone? icone;
  final String? erreur;
  final DateTime? premiereDate;
  final DateTime? derniereDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final DateTime aujourdhui = DateTime.now();

    return InkWell(
      borderRadius: BorderRadius.circular(Rayon.pilule),
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
          labelText: libelle,
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
