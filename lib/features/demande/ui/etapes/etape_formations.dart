import 'package:flutter/material.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/ui/champs.dart';
import '../../../../core/ui/icone.dart';
import '../../../../core/ui/liste_dynamique.dart';
import '../../../reference/domain/referentiel.dart';
import '../../domain/demande.dart';
import 'etape_wizard.dart';

/// Étape 2 — formations (§4).
///
/// Aucun champ n'est obligatoire côté serveur, mais **la colonne
/// `autresdiplomes` est un `varchar(255)`** alors qu'une seule formation en
/// occupe déjà 183 (bloqueur B3). Tant qu'elle n'est pas migrée, une deuxième
/// formation fera échouer l'enregistrement avec une erreur SQL 1406 : on
/// prévient ici plutôt que de laisser le candidat perdre sa saisie.
class EtapeFormations extends StatelessWidget {
  const EtapeFormations({
    required this.demande,
    required this.referentiel,
    required this.erreurs,
    required this.modifier,
    super.key,
  });

  final Demande demande;
  final Referentiel referentiel;
  final ApiException? erreurs;
  final Modification modifier;

  @override
  Widget build(BuildContext context) {
    final List<Academic> niveaux = referentiel.academicsOrdonnes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const TitreSection(
          'Vos formations',
          aide: 'Commencez par la plus élevée. Vous pouvez en ajouter '
              'autant que nécessaire.',
        ),

        ListeDynamique<Formation>(
          elements: demande.formations,
          libelleAjout: 'Ajouter une formation',
          messageVide: 'Aucune formation enregistrée pour le moment.',
          nouveau: () => const Formation(academicId: 0),
          titre: (i) => 'Formation ${i + 1}',
          onChange: (liste) => modifier((d) => d.copyWith(formations: liste)),
          contenu: (formation, remplacer) => _ChampsFormation(
            formation: formation,
            niveaux: niveaux,
            erreurs: erreurs,
            onChange: remplacer,
          ),
        ),

        if (demande.formations.length > 1) ...<Widget>[
          const SizedBox(height: Espace.md),
          _AvertissementFormationsMultiples(),
        ],
      ],
    );
  }
}

class _ChampsFormation extends StatelessWidget {
  const _ChampsFormation({
    required this.formation,
    required this.niveaux,
    required this.erreurs,
    required this.onChange,
  });

  final Formation formation;
  final List<Academic> niveaux;
  final ApiException? erreurs;
  final ValueChanged<Formation> onChange;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      ChampSelection<Academic>(
        libelle: 'Niveau d’études',
        icone: Icones.niveauEtudes,
        valeur: _niveau,
        elements: niveaux,
        // §5.2 : l'ordre est imposé par l'app, jamais par l'id.
        etiquette: (a) =>
            a.id == Academic.sansDiplomeId ? 'Sans diplôme' : a.libelle,
        onChange: (v) => onChange(formation.copyWith(academicId: v?.id ?? 0)),
      ),

      // §8.9 : « sans diplôme » masque intitulé, année, spécialité et
      // établissement — les demander n'aurait aucun sens.
      if (!formation.sansDiplome && formation.academicId != 0) ...<Widget>[
        const SizedBox(height: Espace.sm),
        ChampTexte(
          libelle: 'Intitulé du diplôme',
          icone: Icones.diplome,
          valeur: formation.diplome,
          onChange: (v) => onChange(formation.copyWith(diplome: v)),
        ),
        const SizedBox(height: Espace.sm),
        ChampTexte(
          libelle: 'Spécialité',
          icone: Icones.diplome,
          valeur: formation.specialite,
          onChange: (v) => onChange(formation.copyWith(specialite: v)),
        ),
        const SizedBox(height: Espace.sm),
        ChampTexte(
          libelle: 'Établissement',
          icone: Icones.etablissement,
          valeur: formation.etablissement,
          onChange: (v) => onChange(formation.copyWith(etablissement: v)),
        ),
        const SizedBox(height: Espace.sm),
        ChampTexte(
          libelle: 'Année d’obtention',
          icone: Icones.annee,
          valeur: formation.anneeDiplome?.toString() ?? '',
          clavier: TextInputType.number,
          formatteurs: Formats.chiffres,
          longueurMax: 4,
          onChange: (v) =>
              onChange(formation.copyWith(anneeDiplome: int.tryParse(v))),
        ),
      ],
    ],
  );

  Academic? get _niveau {
    for (final Academic a in niveaux) {
      if (a.id == formation.academicId) return a;
    }
    return null;
  }
}

/// Avertissement lié au bloqueur B3, à retirer dès la migration de la colonne.
class _AvertissementFormationsMultiples extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Espace.sm + 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(Rayon.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icone(
            Icones.alerte,
            taille: 20,
            couleur: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: Espace.xs),
          Expanded(
            child: Text(
              'Le serveur ne sait pas encore enregistrer plusieurs formations. '
              'Votre saisie reste conservée sur l’appareil, mais '
              'l’enregistrement peut échouer tant que la correction n’est pas '
              'déployée.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
