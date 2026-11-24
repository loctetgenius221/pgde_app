import 'package:flutter/material.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/ui/frise_etapes.dart';
import '../../../core/ui/icone.dart';
import '../../../core/ui/responsive.dart';
import '../domain/wizard.dart';

/// Pictogramme d'une étape — le même que sur le web, dans les deux frises.
DonneesIcone iconeEtape(EtapeWizard etape) => switch (etape) {
  EtapeWizard.identite => Icones.etapeIdentite,
  EtapeWizard.formations => Icones.etapeFormations,
  EtapeWizard.experiences => Icones.etapeExperiences,
  EtapeWizard.voeux => Icones.etapeVoeux,
};

/// Frise horizontale des étapes du wizard, dessinée comme sur le web.
///
/// Les étapes déjà passées sont pleines et reliées d'un trait vert ; l'étape
/// en cours porte un halo ; les suivantes restent en vert pâle, reliées en
/// pointillé. Le candidat qui passe du site à l'application retrouve
/// exactement le même repère.
///
/// La navigation entre étapes étant libre (voir `WizardPage`), chaque tuile
/// est aussi un raccourci.
class FriseWizard extends StatelessWidget {
  const FriseWizard({required this.etape, required this.onEtape, super.key});

  final EtapeWizard etape;
  final ValueChanged<EtapeWizard> onEtape;

  EtatEtape _etat(EtapeWizard e) => e.index < etape.index
      ? EtatEtape.franchie
      : (e == etape ? EtatEtape.enCours : EtatEtape.aVenir);

  @override
  Widget build(BuildContext context) {
    const List<EtapeWizard> etapes = EtapeWizard.values;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Espace.xs,
        Espace.xxs,
        Espace.xs,
        Espace.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final EtapeWizard e in etapes)
            Expanded(
              child: _Colonne(
                etape: e,
                etat: _etat(e),
                // Le trait est plein jusqu'à l'étape en cours : il
                // matérialise le chemin déjà parcouru.
                traitGaucheFranchi: e.index <= etape.index,
                traitDroitFranchi: e.index < etape.index,
                premiere: e.index == 0,
                derniere: e.index == etapes.length - 1,
                onTap: () => onEtape(e),
              ),
            ),
        ],
      ),
    );
  }
}

class _Colonne extends StatelessWidget {
  const _Colonne({
    required this.etape,
    required this.etat,
    required this.traitGaucheFranchi,
    required this.traitDroitFranchi,
    required this.premiere,
    required this.derniere,
    required this.onTap,
  });

  final EtapeWizard etape;
  final EtatEtape etat;
  final bool traitGaucheFranchi;
  final bool traitDroitFranchi;
  final bool premiere;
  final bool derniere;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool active = etat == EtatEtape.enCours;
    final bool passee = etat == EtatEtape.franchie;
    // Tuiles compactes sur téléphone : la frise est un repère, pas le sujet
    // de l'écran. Elle laissait à peine 60 % de la hauteur au formulaire.
    final double cote = context.format.estTablette ? 40 : 32;

    // Le jour n'est laissé que **côté tuile** (place du halo) : les deux
    // demi-traits de deux colonnes voisines se rejoignent ainsi en un trait
    // continu, au lieu d'un « –  – » coupé en son milieu.
    Widget trait(bool franchi, {required bool aGauche}) => Padding(
      padding: EdgeInsets.only(
        left: aGauche ? 0 : Espace.xs,
        right: aGauche ? Espace.xs : 0,
      ),
      child: TraitEtape(franchi: franchi),
    );

    return Semantics(
      button: true,
      selected: active,
      label: 'Étape ${etape.numero} : ${etape.titre}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Rayon.champ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Espace.xxs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                height: cote,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: premiere
                          ? const SizedBox.shrink()
                          : trait(traitGaucheFranchi, aGauche: true),
                    ),
                    TuileEtape(
                      etat: etat,
                      icone: iconeEtape(etape),
                      cote: cote,
                    ),
                    Expanded(
                      child: derniere
                          ? const SizedBox.shrink()
                          : trait(traitDroitFranchi, aGauche: false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Espace.xxs),
              AnimatedDefaultTextStyle(
                duration: Duree.rapide,
                style: theme.textTheme.bodySmall!.copyWith(
                  fontSize: 11,
                  height: 1.2,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active || passee
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
                child: Text(
                  etape.libelleCourt,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
