import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import 'icone.dart';

/// Diamètre d'une pastille — et donc largeur de la colonne du rail. Les deux
/// doivent rester égaux, sinon les pastilles cessent d'être centrées sur le
/// trait qui les relie.
const double _diametrePastille = 34;

/// Épaisseur du trait reliant les pastilles.
const double _largeurRail = 2.5;

/// État d'une étape dans la frise.
enum EtatEtape {
  /// Franchie : pastille pleine et coche.
  franchie,

  /// En cours : anneau vert sur halo jaune. Une seule étape à la fois.
  enCours,

  /// À venir : contour discret, numéro en gris.
  aVenir,
}

@immutable
class ElementFrise {
  const ElementFrise({
    required this.numero,
    required this.titre,
    required this.etat,
    this.statut,
    this.description,
    this.onTap,
  });

  final int numero;
  final String titre;
  final EtatEtape etat;

  /// Pastille d'état — « Complétée », « En cours ». Absente pour une étape
  /// à venir : lui coller « À faire » n'apprendrait rien.
  final String? statut;

  final String? description;
  final VoidCallback? onTap;
}

/// Frise verticale des étapes d'un parcours.
///
/// Le rail relie les pastilles entre elles et se colore jusqu'à l'endroit
/// atteint : la progression se lit d'un coup d'œil, sans compter les coches.
/// C'est ce qu'une liste de cartes ne sait pas faire — elle juxtapose là où
/// une frise raconte un chemin.
///
/// Les hauteurs de ligne sont libres : le rail s'étire sur la hauteur réelle
/// de sa ligne, pas sur une constante qui casserait dès qu'un titre passe sur
/// deux lignes ou que l'utilisateur agrandit la police système.
class FriseEtapes extends StatefulWidget {
  const FriseEtapes({required this.elements, super.key});

  final List<ElementFrise> elements;

  @override
  State<FriseEtapes> createState() => _FriseEtapesState();
}

class _FriseEtapesState extends State<FriseEtapes>
    with SingleTickerProviderStateMixin {
  static const Duration _duree = Duration(milliseconds: 900);

  late final AnimationController _controleur = AnimationController(
    vsync: this,
    duration: _duree,
  );

  @override
  void initState() {
    super.initState();
    _controleur.forward();
  }

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  /// Avancement de la ligne [index], décalé pour que la frise se dessine de
  /// haut en bas plutôt que d'apparaître d'un bloc.
  Animation<double> _echelonne(int index, int total) {
    final double pas = 1 / (total + 1);
    return CurvedAnimation(
      parent: _controleur,
      curve: Interval(
        (index * pas).clamp(0.0, 1.0),
        ((index + 2) * pas).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Respecte le réglage système « réduire les animations » : une frise qui
    // se dessine est un agrément, pas une information.
    final bool anime = !MediaQuery.disableAnimationsOf(context);
    if (!anime) _controleur.value = 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < widget.elements.length; i++)
          _Ligne(
            element: widget.elements[i],
            derniere: i == widget.elements.length - 1,
            avancement: _echelonne(i, widget.elements.length),
          ),
      ],
    );
  }
}

class _Ligne extends StatelessWidget {
  const _Ligne({
    required this.element,
    required this.derniere,
    required this.avancement,
  });

  final ElementFrise element;
  final bool derniere;
  final Animation<double> avancement;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: avancement,
    builder: (context, enfant) => Opacity(
      opacity: avancement.value.clamp(0, 1),
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - avancement.value)),
        child: enfant,
      ),
    ),
    child: Stack(
      children: <Widget>[
        // Le rail part sous la pastille et descend jusqu'au bas de la ligne,
        // où l'attend la pastille suivante.
        //
        // `Positioned` avec `top` **et** `bottom` lui donne la hauteur réelle
        // de la ligne. Passer par `IntrinsicHeight` obligerait chaque
        // descendant à savoir dire sa hauteur — ce qu'un trait large de
        // 2,5 px et de hauteur libre ne sait pas faire.
        if (!derniere)
          Positioned(
            top: _diametrePastille,
            bottom: 0,
            left: (_diametrePastille - _largeurRail) / 2,
            width: _largeurRail,
            child: _Rail(
              // Le rail ne se colore que sous une étape franchie : il
              // matérialise le chemin déjà parcouru.
              franchi: element.etat == EtatEtape.franchie,
              avancement: avancement,
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _Pastille(etat: element.etat, numero: element.numero),
            const SizedBox(width: Espace.sm),
            Expanded(
              child: _Contenu(element: element, derniere: derniere),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Pastille extends StatelessWidget {
  const _Pastille({required this.etat, required this.numero});

  final EtatEtape etat;
  final int numero;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return SizedBox.square(
      dimension: _diametrePastille,
      child: switch (etat) {
        EtatEtape.franchie => DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icone(Icones.valide, taille: 17, couleur: scheme.onPrimary),
          ),
        ),

        // Le halo jaune n'apparaît qu'ici : c'est l'unique accent de la
        // palette, réservé à l'étape en cours.
        EtatEtape.enCours => DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.jaune.withValues(alpha: 0.30),
          ),
          child: Center(
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: scheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.primary, width: 2.5),
              ),
              child: Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),

        EtatEtape.aVenir => DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            shape: BoxShape.circle,
            border: Border.all(color: scheme.outlineVariant, width: 1.5),
          ),
          child: Center(
            child: Text(
              '$numero',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      },
    );
  }
}

/// Segment du rail, entre deux pastilles.
class _Rail extends StatelessWidget {
  const _Rail({required this.franchi, required this.avancement});

  final bool franchi;
  final Animation<double> avancement;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final BorderRadius arrondi = BorderRadius.circular(_largeurRail);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.outlineVariant,
              borderRadius: arrondi,
            ),
          ),
          if (franchi)
            // Le trait vert descend au rythme de l'apparition de la ligne.
            //
            // Son propre `AnimatedBuilder` est indispensable : le reste de la
            // ligne est passé en `child` au builder parent, donc construit une
            // seule fois. Lire `avancement.value` là-haut donnerait une valeur
            // figée, et le rail ne descendrait jamais.
            AnimatedBuilder(
              animation: avancement,
              builder: (context, _) => FractionallySizedBox(
                alignment: Alignment.topCenter,
                heightFactor: avancement.value.clamp(0, 1),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: arrondi,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Contenu extends StatelessWidget {
  const _Contenu({required this.element, required this.derniere});

  final ElementFrise element;
  final bool derniere;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool active = element.etat != EtatEtape.aVenir;

    return Padding(
      padding: EdgeInsets.only(bottom: derniere ? 0 : Espace.lg),
      child: InkWell(
        onTap: element.onTap,
        borderRadius: BorderRadius.circular(Rayon.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Espace.xs,
            vertical: Espace.xxs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'ÉTAPE ${element.numero}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                  color: element.etat == EtatEtape.enCours
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.75,
                        ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                element.titre,
                style: theme.textTheme.titleMedium?.copyWith(
                  // Une étape à venir ne réclame pas l'attention.
                  color: active
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              if (element.description case final String texte) ...<Widget>[
                const SizedBox(height: 2),
                Text(texte, style: theme.textTheme.bodySmall),
              ],
              if (element.statut case final String statut) ...<Widget>[
                const SizedBox(height: Espace.xs),
                _Pastilleteinte(statut: statut, etat: element.etat),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Pastilleteinte extends StatelessWidget {
  const _Pastilleteinte({required this.statut, required this.etat});

  final String statut;
  final EtatEtape etat;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool franchie = etat == EtatEtape.franchie;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Espace.xs + 2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: franchie ? AppColors.vertPale : scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(Rayon.pilule),
      ),
      child: Text(
        statut,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: franchie
              ? scheme.onPrimaryContainer
              : scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
