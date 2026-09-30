import 'package:flutter/material.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/ui/champs.dart';
import '../../../../core/ui/icone.dart';
import '../../../../core/ui/liste_dynamique.dart';
import '../../domain/demande.dart';
import 'etape_wizard.dart';

/// Étape 3 — expériences professionnelles (§4).
///
/// Deux règles du serveur sont reproduites ici, parce qu'elles décident de ce
/// qui sera réellement enregistré :
/// - répondre « non » **efface** toutes les expériences ;
/// - une expérience sans poste, ni employeur, ni description est écartée.
class EtapeExperiences extends StatelessWidget {
  const EtapeExperiences({
    required this.demande,
    required this.erreurs,
    required this.modifier,
    super.key,
  });

  final Demande demande;
  final ApiException? erreurs;
  final Modification modifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final int retenues = demande.experiencesRetenues.length;
    final int saisies = demande.experiences.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const TitreSection('Votre parcours'),

        ChoixSegmente<bool>(
          libelle: 'Avez-vous déjà travaillé ?',
          valeur: demande.aDeLExperience,
          options: const <bool>[false, true],
          etiquette: (oui) => oui ? 'Oui' : 'Non',
          erreur: erreurs?.errorFor('hasExperience'),
          onChange: (oui) => modifier((d) => d.copyWith(aDeLExperience: oui)),
        ),

        if (demande.aDeLExperience == false)
          Padding(
            padding: const EdgeInsets.only(top: Espace.md),
            child: Text(
              'De nombreux postes sont ouverts aux débutants.',
              style: theme.textTheme.bodyMedium,
            ),
          )
        else if (demande.aDeLExperience == true) ...<Widget>[
          const TitreSection('Vos expériences'),
          ListeDynamique<Experience>(
            elements: demande.experiences,
            libelleAjout: 'Ajouter une expérience',
            messageVide: 'Aucune expérience.',
            nouveau: Experience.new,
            titre: (i) => 'Expérience ${i + 1}',
            onChange: (liste) =>
                modifier((d) => d.copyWith(experiences: liste)),
            contenu: (_, experience, remplacer) =>
                _ChampsExperience(experience: experience, onChange: remplacer),
          ),

          // Le serveur écarte silencieusement les lignes vides : autant le dire
          // avant l'enregistrement plutôt que de laisser le candidat croire
          // qu'elles ont été prises en compte.
          if (retenues < saisies)
            Padding(
              padding: const EdgeInsets.only(top: Espace.md),
              child: Text(
                saisies - retenues == 1
                    ? 'Une expérience sera ignorée : renseignez au moins le '
                          'poste ou l’employeur.'
                    : '${saisies - retenues} expériences seront ignorées : '
                          'renseignez au moins le poste ou l’employeur.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _ChampsExperience extends StatelessWidget {
  const _ChampsExperience({required this.experience, required this.onChange});

  final Experience experience;
  final ValueChanged<Experience> onChange;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      ChampTexte(
        libelle: 'Poste occupé',
        icone: Icones.poste,
        valeur: experience.poste,
        onChange: (v) => onChange(experience.copyWith(poste: v)),
      ),
      const SizedBox(height: Espace.sm),
      ChampTexte(
        libelle: 'Employeur',
        icone: Icones.employeur,
        valeur: experience.employeur,
        onChange: (v) => onChange(experience.copyWith(employeur: v)),
      ),
      const SizedBox(height: Espace.sm),
      ChampTexte(
        libelle: 'Nombre d’années',
        icone: Icones.annee,
        valeur: experience.annees?.toString() ?? '',
        clavier: TextInputType.number,
        formatteurs: Formats.chiffres,
        longueurMax: 2,
        onChange: (v) => onChange(experience.copyWith(annees: int.tryParse(v))),
      ),
      const SizedBox(height: Espace.sm),
      ChampTexte(
        libelle: 'Description des missions',
        valeur: experience.description,
        lignes: 3,
        onChange: (v) => onChange(experience.copyWith(description: v)),
      ),
    ],
  );
}
