import 'package:flutter/material.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/ui/champs.dart';
import '../../../../core/ui/icone.dart';
import '../../../../core/ui/liste_dynamique.dart';
import '../../../../core/ui/responsive.dart';
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
        const IntroEtape(
          'Stages, emplois, bénévolat : tout compte. Pas d’expérience ? '
          'Répondez simplement « Non ».',
        ),

        ChoixSegmente<bool>(
          libelle: 'Avez-vous déjà une expérience professionnelle ?',
          valeur: demande.aDeLExperience,
          options: const <bool>[true, false],
          etiquette: (oui) =>
              oui ? 'Oui, j’ai de l’expérience' : 'Non, pas encore',
          icone: (oui) => oui ? Icones.etapeExperiences : Icones.debutant,
          erreur: erreurs?.errorFor('has_experience'),
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
          const SizedBox(height: Espace.md),
          ListeDynamique<Experience>(
            elements: demande.experiences,
            icone: Icones.etapeExperiences,
            libelleAjout: demande.experiences.isEmpty
                ? 'Ajouter une expérience'
                : 'Ajouter une autre expérience',
            messageVide: 'Aucune expérience pour l’instant.',
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
  Widget build(BuildContext context) => GrilleChamps(
    children: <Widget>[
      ChampTexte(
        libelle: 'Poste occupé',
        indication: 'ex : Comptable',
        valeur: experience.poste,
        onChange: (v) => onChange(experience.copyWith(poste: v)),
      ),
      ChampTexte(
        libelle: 'Entreprise ou employeur',
        indication: 'ex : Ministère des Finances',
        valeur: experience.employeur,
        onChange: (v) => onChange(experience.copyWith(employeur: v)),
      ),
      ChampCompteur(
        libelle: 'Durée (en années)',
        valeur: experience.annees ?? 0,
        // Même plafond que les années d'expérience des vœux (§4).
        maximum: 50,
        onChange: (v) => onChange(experience.copyWith(annees: v)),
      ),
      // Un texte de plusieurs lignes a besoin de toute la largeur.
      PleineLargeur(
        child: ChampTexte(
          libelle: 'Missions principales',
          facultatif: true,
          indication: 'Décrivez en quelques lignes ce que vous faisiez.',
          valeur: experience.description,
          lignes: 4,
          dictee: true,
          onChange: (v) => onChange(experience.copyWith(description: v)),
        ),
      ),
    ],
  );
}
