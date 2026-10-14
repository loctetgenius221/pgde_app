import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/ui/icone.dart';

/// Une information du candidat sur toute la largeur : pictogramme dans une
/// tuile grise, libellé discret à gauche, valeur à droite.
///
/// Partagée par la carte d'identité du formulaire et l'en-tête de « Mon
/// dossier », pour qu'un candidat retrouve la même présentation aux deux
/// endroits.
class LigneCompte extends StatelessWidget {
  const LigneCompte({
    required this.icone,
    required this.libelle,
    required this.valeur,
    this.lignesMax = 1,
    super.key,
  });

  final DonneesIcone icone;
  final String libelle;
  final String valeur;

  /// Une ligne pour un identifiant ; deux pour un intitulé d'emploi, qui ne
  /// doit pas être tronqué au premier mot.
  final int lignesMax;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool clair = theme.brightness == Brightness.light;
    return Padding(
      padding: const EdgeInsets.only(top: Espace.xs - 2),
      child: Row(
        children: <Widget>[
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: clair ? AppColors.pisteClaire : AppColors.pisteSombre,
              borderRadius: BorderRadius.circular(Rayon.sm - 2),
            ),
            child: Icone(
              icone,
              taille: 14,
              couleur: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: Espace.sm),
          Text(libelle, style: theme.textTheme.bodySmall),
          const SizedBox(width: Espace.sm),
          Expanded(
            child: Text(
              valeur,
              maxLines: lignesMax,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
