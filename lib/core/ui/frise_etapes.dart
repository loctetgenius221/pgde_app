import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import 'icone.dart';

/// Côté d'une tuile d'étape — et donc largeur de la colonne du rail. Les deux
/// doivent rester égaux, sinon les tuiles cessent d'être centrées sur le
/// trait qui les relie.
const double coteTuileEtape = 44;

/// État d'une étape dans une frise.
enum EtatEtape {
  /// Franchie : tuile verte pleine, trait plein jusqu'à la suivante.
  franchie,

  /// En cours : tuile verte pleine **avec halo**. Une seule étape à la fois.
  enCours,

  /// À venir : tuile vert pâle, trait pointillé.
  aVenir,
}

/// Tuile carrée arrondie d'une étape, dessinée comme sur la plateforme web.
///
/// Partagée par la frise verticale de l'accueil et la frise horizontale du
/// wizard : un candidat doit reconnaître la même étape aux deux endroits.
class TuileEtape extends StatelessWidget {
  const TuileEtape({
    required this.etat,
    this.icone,
    this.numero,
    this.cote = coteTuileEtape,
    super.key,
  });

  final EtatEtape etat;

  /// Pictogramme de l'étape. À défaut, la tuile affiche [numero].
  final DonneesIcone? icone;
  final int? numero;

  /// Côté de la tuile. Pictogramme, rayon et halo suivent ses proportions,
  /// pour qu'une tuile compacte garde l'allure de la grande.
  final double cote;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool clair = theme.brightness == Brightness.light;
    final bool pleine = etat != EtatEtape.aVenir;
    final Color encre = pleine ? scheme.onPrimary : scheme.primary;

    return AnimatedContainer(
      duration: Duree.moyenne,
      curve: Curves.easeOutCubic,
      width: cote,
      height: cote,
      decoration: BoxDecoration(
        color: pleine
            ? scheme.primary
            : (clair
                  ? AppColors.vertPale.withValues(alpha: 0.6)
                  : scheme.primaryContainer),
        borderRadius: BorderRadius.circular(cote * 0.27),
        boxShadow: etat == EtatEtape.enCours
            ? <BoxShadow>[
                // Le halo du web : un anneau vert diffus autour de l'étape en
                // cours, seule à le porter.
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.22),
                  spreadRadius: cote / 11,
                ),
              ]
            : const <BoxShadow>[],
      ),
      child: Center(
        child: icone != null
            ? Icone(icone!, taille: cote * 0.45, couleur: encre)
            : Text(
                '${numero ?? ''}',
                style: theme.textTheme.titleMedium?.copyWith(color: encre),
              ),
      ),
    );
  }
}

/// Trait entre deux tuiles : plein et vert sur le chemin parcouru,
/// pointillé et gris au-delà.
class TraitEtape extends StatelessWidget {
  const TraitEtape({
    required this.franchi,
    this.axe = Axis.horizontal,
    super.key,
  });

  final bool franchi;
  final Axis axe;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<Color?>(
      duration: Duree.moyenne,
      tween: ColorTween(end: franchi ? scheme.primary : scheme.outlineVariant),
      builder: (context, couleur, _) => CustomPaint(
        size: axe == Axis.horizontal
            ? const Size(double.infinity, 2)
            : const Size(2, double.infinity),
        painter: _PeintreTrait(
          couleur: couleur ?? scheme.outlineVariant,
          plein: franchi,
          axe: axe,
        ),
      ),
    );
  }
}

class _PeintreTrait extends CustomPainter {
  const _PeintreTrait({
    required this.couleur,
    required this.plein,
    required this.axe,
  });

  final Color couleur;
  final bool plein;
  final Axis axe;

  static const double _tiret = 4;
  static const double _espace = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint pinceau = Paint()
      ..color = couleur
      ..strokeWidth = plein ? 2 : 1.5
      ..strokeCap = StrokeCap.round;
    final bool horizontal = axe == Axis.horizontal;
    final double longueur = horizontal ? size.width : size.height;
    Offset point(double t) =>
        horizontal ? Offset(t, size.height / 2) : Offset(size.width / 2, t);

    if (plein) {
      canvas.drawLine(point(0), point(longueur), pinceau);
      return;
    }
    for (double t = 0; t < longueur; t += _tiret + _espace) {
      canvas.drawLine(
        point(t),
        point((t + _tiret).clamp(0, longueur)),
        pinceau,
      );
    }
  }

  @override
  bool shouldRepaint(_PeintreTrait ancien) =>
      ancien.couleur != couleur || ancien.plein != plein || ancien.axe != axe;
}

@immutable
class ElementFrise {
  const ElementFrise({
    required this.numero,
    required this.titre,
    required this.etat,
    this.icone,
    this.statut,
    this.description,
    this.onTap,
  });

  final int numero;
  final String titre;
  final EtatEtape etat;

  /// Pictogramme de la tuile ; à défaut, le numéro.
  final DonneesIcone? icone;

  /// Pastille d'état — « Complétée », « En cours ». Absente pour une étape
  /// à venir : lui coller « À faire » n'apprendrait rien.
  final String? statut;

  final String? description;
  final VoidCallback? onTap;
}

/// Frise verticale des étapes d'un parcours.
///
/// Mêmes tuiles et mêmes traits que la frise horizontale du formulaire web :
/// seule l'orientation change, parce qu'un téléphone a de la hauteur et pas
/// de largeur — et que la frise de l'accueil porte un statut par étape.
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
        // Le rail part sous la tuile et descend jusqu'au bas de la ligne, où
        // l'attend la tuile suivante.
        //
        // `Positioned` avec `top` **et** `bottom` lui donne la hauteur réelle
        // de la ligne. Passer par `IntrinsicHeight` obligerait chaque
        // descendant à savoir dire sa hauteur — ce qu'un trait de hauteur
        // libre ne sait pas faire.
        if (!derniere)
          Positioned(
            top: coteTuileEtape,
            bottom: 0,
            left: 0,
            width: coteTuileEtape,
            child: Padding(
              // Laisse un jour entre le trait et les tuiles, et la place du
              // halo de l'étape en cours.
              padding: const EdgeInsets.symmetric(vertical: Espace.xs),
              // Le rail ne se colore que sous une étape franchie : il
              // matérialise le chemin déjà parcouru.
              child: TraitEtape(
                franchi: element.etat == EtatEtape.franchie,
                axe: Axis.vertical,
              ),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TuileEtape(
              etat: element.etat,
              icone: element.icone,
              numero: element.numero,
            ),
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
        borderRadius: BorderRadius.circular(Rayon.champ),
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
                _PastilleStatut(statut: statut, etat: element.etat),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PastilleStatut extends StatelessWidget {
  const _PastilleStatut({required this.statut, required this.etat});

  final String statut;
  final EtatEtape etat;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool franchie = etat == EtatEtape.franchie;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Espace.xs + 2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        // « À remplir » garde le jaune : c'est l'unique accent de la
        // palette, réservé à ce qui attend le candidat.
        color: franchie ? AppColors.vertPale : scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(Rayon.pilule),
      ),
      child: Text(
        statut,
        style: theme.textTheme.bodySmall?.copyWith(
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
