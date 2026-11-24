import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';

/// Mention d'autorité : le nom de la plateforme et celui du ministère.
///
/// Deux niveaux de discrétion, parce que ce n'est pas la même information :
/// le nom de la plateforme situe l'application, celui du ministère la signe.
/// Ni l'un ni l'autre ne doit concurrencer le contenu de l'écran.
///
/// Partagée par l'écran d'ouverture et l'accueil, pour que la signature soit
/// rigoureusement la même aux deux endroits.
class PiedInstitutionnel extends StatelessWidget {
  const PiedInstitutionnel({
    this.avecLogo = false,
    this.avecPlateforme = true,
    super.key,
  });

  static const String plateforme =
      'Plateforme de Gestion des Demandes d’emploi';

  static const String ministere =
      'Ministère de la Fonction publique, du \n travail '
      'et de la réforme du service public';

  /// Ajoute le logo au-dessus du texte.
  final bool avecLogo;

  /// Affiche le nom de la plateforme au-dessus de celui du ministère.
  ///
  /// Inutile là où l'écran dit déjà où l'on se trouve : le répéter en pied
  /// de page ajoute une ligne sans rien apprendre. Seule la signature du
  /// ministère a besoin d'y rester.
  final bool avecPlateforme;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (avecLogo) ...<Widget>[
          Image.asset('assets/logo_fp.png', width: 40, height: 40),
          const SizedBox(height: Espace.xs),
        ],
        if (avecPlateforme) ...<Widget>[
          Text(
            plateforme,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              letterSpacing: 0.4,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Espace.xxs),
        ],
        Text(
          ministere,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            height: 1.35,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
