import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_dimens.dart';
import 'assistant_page.dart';
import 'ndimbal.dart';

/// Ndimbal posé dans le coin bas-droit de l'accueil.
///
/// Le personnage entier, pas une icône : c'est une présence, et une présence
/// se reconnaît à ce qu'elle bouge d'elle-même. Un assistant figé passe pour
/// une illustration décorative, et personne n'appuie sur une illustration.
/// La respiration, les anneaux qui tournent et le clignement suffisent à dire
/// qu'il y a quelqu'un.
///
/// Il flotte **au-dessus** du contenu plutôt que de prendre place dans le
/// flux : l'aide doit rester à portée quel que soit l'endroit où le candidat
/// a fait défiler la page.
///
/// Au clic, ce même personnage traverse la navigation par `Hero` et grandit
/// sur l'écran de conversation — on suit du regard ce sur quoi on a appuyé.
class EntreeAssistant extends StatefulWidget {
  const EntreeAssistant({super.key});

  /// Hauteur du personnage.
  ///
  /// Dimensionné pour un téléphone : au-delà, l'assistant cesse d'être un
  /// recours discret posé dans un coin et devient un élément qui dispute
  /// l'écran au dossier — lequel reste la raison d'être de la page.
  static const double hauteur = 92;

  /// Hauteur totale occupée — personnage et étiquette « Ndimbal ».
  ///
  /// Sert aux pages qui l'accueillent à réserver sa place en bas de leur
  /// contenu, pour que rien d'important ne finisse caché dessous.
  static const double emprise = hauteur + 30;

  /// Intervalle entre deux saluts.
  ///
  /// Assez espacé pour qu'on ne le voie pas venir, assez fréquent pour qu'on
  /// finisse par le surprendre. Un personnage qui salue toutes les cinq
  /// secondes devient une sollicitation ; celui qui ne salue jamais reste
  /// une image.
  static const Duration entreDeuxSaluts = Duration(seconds: 14);

  @override
  State<EntreeAssistant> createState() => _EntreeAssistantState();
}

class _EntreeAssistantState extends State<EntreeAssistant> {
  Timer? _horloge;
  Timer? _retour;
  PoseNdimbal _pose = PoseNdimbal.neutre;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pas de salut si l'utilisateur a demandé des animations réduites : un
    // mouvement qui surgit de lui-même est exactement ce qu'il a refusé.
    final bool anime = !MediaQuery.disableAnimationsOf(context);
    _horloge?.cancel();
    if (!anime) return;
    _horloge = Timer.periodic(
      EntreeAssistant.entreDeuxSaluts,
      (_) => _saluer(),
    );
  }

  void _saluer() {
    if (!mounted) return;
    setState(() => _pose = PoseNdimbal.salut);
    // Le geste dure le temps de son animation, puis le visage se repose.
    _retour = Timer(const Duration(milliseconds: 1700), () {
      if (mounted) setState(() => _pose = PoseNdimbal.neutre);
    });
  }

  @override
  void dispose() {
    _horloge?.cancel();
    _retour?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: 'Ndimbal, assistant IA. Poser une question sur votre dossier.',
      child: GestureDetector(
        onTap: () => context.push(Routes.assistant),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Hero(
              tag: heroNdimbal,
              flightShuttleBuilder: (_, _, _, _, _) => const FittedBox(
                fit: BoxFit.contain,
                child: Ndimbal(taille: EntreeAssistant.hauteur),
              ),
              child: Ndimbal(taille: EntreeAssistant.hauteur, pose: _pose),
            ),
            // Le personnage seul ne dit pas qu'on peut lui parler. Une
            // étiquette discrète vaut mieux qu'un robot muet dans un coin,
            // surtout pour un service public dont le public est très large.
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Espace.sm,
                vertical: Espace.xxs,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(Rayon.pilule),
                border: Border.all(color: theme.colorScheme.outlineVariant),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFF0B1220).withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                'Ndimbal',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Le même personnage, réduit à un repère de locuteur dans le fil.
class PastilleNdimbal extends StatelessWidget {
  const PastilleNdimbal({this.taille = 30, this.anime = false, super.key});

  final double taille;

  /// Les vignettes des bulles déjà écrites restent figées : animer une
  /// horloge par message ferait tourner des dizaines de tickers pour des
  /// pastilles que personne ne regarde.
  final bool anime;

  @override
  Widget build(BuildContext context) =>
      Ndimbal(taille: taille, forme: FormeNdimbal.pastille, anime: anime);
}
