import 'package:flutter/material.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/ui/champs.dart';
import '../../../../core/ui/icone.dart';
import '../../../reference/domain/referentiel.dart';
import '../../domain/demande.dart';
import 'etape_wizard.dart';

/// Étape 4 — vœux d'emploi (§4).
///
/// Les deux vœux sont **obligatoires** à la création. Le choix se fait en
/// cascade secteur → emploi, mais `secteur_id` n'est pas stocké dans
/// `userdata` : il ne sert qu'au filtrage. Pour un vœu déjà enregistré, on le
/// remonte donc depuis l'emploi.
class EtapeVoeux extends StatefulWidget {
  const EtapeVoeux({
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
  State<EtapeVoeux> createState() => _EtapeVoeuxState();
}

class _EtapeVoeuxState extends State<EtapeVoeux> {
  /// Secteur choisi à l'écran. Purement local : il ne part jamais au serveur.
  Secteur? _secteurChoisi1;
  Secteur? _secteurChoisi2;

  Secteur? _secteur(int rang) {
    final Secteur? choisi = rang == 1 ? _secteurChoisi1 : _secteurChoisi2;
    if (choisi != null) return choisi;
    final int? emploiId = rang == 1
        ? widget.demande.emploi1Id
        : widget.demande.emploi2Id;
    return emploiId == null
        ? null
        : widget.referentiel.secteurDeLEmploi(emploiId);
  }

  Emploi? _emploi(int? id) {
    if (id == null) return null;
    return widget.referentiel.emploiParId(id);
  }

  /// §6.2 D9 : rien n'empêche côté serveur que les deux vœux soient identiques.
  bool get _voeuxIdentiques =>
      widget.demande.emploi1Id != null &&
      widget.demande.emploi1Id == widget.demande.emploi2Id;

  @override
  Widget build(BuildContext context) {
    final Widget voeu1 = _Voeu(
      rang: 1,
      referentiel: widget.referentiel,
      secteur: _secteur(1),
      emploi: _emploi(widget.demande.emploi1Id),
      annees: widget.demande.anneesExperience1,
      erreurEmploi: widget.erreurs?.errorFor('emploi1_id'),
      onSecteur: (s) => setState(() {
        _secteurChoisi1 = s;
        // Changer de secteur invalide le métier : il n'y appartient plus.
        widget.modifier((d) => d.copyWith(emploi1Id: null));
      }),
      onEmploi: (e) => widget.modifier((d) => d.copyWith(emploi1Id: e?.id)),
      onAnnees: (n) => widget.modifier((d) => d.copyWith(anneesExperience1: n)),
    );
    final Widget voeu2 = _Voeu(
      rang: 2,
      referentiel: widget.referentiel,
      secteur: _secteur(2),
      emploi: _emploi(widget.demande.emploi2Id),
      annees: widget.demande.anneesExperience2,
      erreurEmploi:
          widget.erreurs?.errorFor('emploi2_id') ??
          (_voeuxIdentiques
              ? 'Choisissez un métier différent du premier vœu.'
              : null),
      onSecteur: (s) => setState(() {
        _secteurChoisi2 = s;
        widget.modifier((d) => d.copyWith(emploi2Id: null));
      }),
      onEmploi: (e) => widget.modifier((d) => d.copyWith(emploi2Id: e?.id)),
      onAnnees: (n) => widget.modifier((d) => d.copyWith(anneesExperience2: n)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const IntroEtape(
          'Choisissez deux emplois, chacun dans un secteur. Le premier est '
          'votre choix prioritaire.',
        ),

        // Côte à côte quand la largeur le permet, comme sur le web ; l'un
        // sous l'autre sur un téléphone.
        LayoutBuilder(
          builder: (context, contraintes) => contraintes.maxWidth >= 600
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: voeu1),
                    const SizedBox(width: Espace.md),
                    Expanded(child: voeu2),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    voeu1,
                    const SizedBox(height: Espace.md),
                    voeu2,
                  ],
                ),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(vertical: Espace.lg),
          child: Divider(),
        ),

        const _EnTetePresentation(),
        const SizedBox(height: Espace.sm),
        ChampTexte(
          libelle: 'Résumé',
          masquerLibelle: true,
          indication:
              'Présentez-vous : vos compétences, vos points forts et ce que '
              'vous souhaitez apporter à l’administration.',
          aide: 'Ce texte apparaîtra en tête de votre CV.',
          valeur: widget.demande.resumeCv,
          lignes: 5,
          // Le serveur refuse au-delà de 1000 caractères (§4, étape 4).
          longueurMax: 1000,
          // Le plus long champ du dossier : dicter fait gagner du temps.
          dictee: true,
          erreur: widget.erreurs?.errorFor('cv_summary'),
          onChange: (v) => widget.modifier((d) => d.copyWith(resumeCv: v)),
        ),
      ],
    );
  }
}

/// Intitulé du bloc de présentation : pictogramme, titre, « facultatif ».
class _EnTetePresentation extends StatelessWidget {
  const _EnTetePresentation();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool clair = theme.brightness == Brightness.light;
    return Row(
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: clair ? AppColors.pisteClaire : AppColors.pisteSombre,
            borderRadius: BorderRadius.circular(Rayon.sm),
          ),
          child: Center(
            child: Icone(
              Icones.presentation,
              taille: 18,
              couleur: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: Espace.sm),
        Flexible(
          child: Text(
            'Votre profil en quelques mots',
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(width: Espace.xs),
        const PastilleFacultatif(),
      ],
    );
  }
}

class _Voeu extends StatelessWidget {
  const _Voeu({
    required this.rang,
    required this.referentiel,
    required this.secteur,
    required this.emploi,
    required this.annees,
    required this.erreurEmploi,
    required this.onSecteur,
    required this.onEmploi,
    required this.onAnnees,
  });

  final int rang;
  final Referentiel referentiel;
  final Secteur? secteur;
  final Emploi? emploi;
  final int annees;
  final String? erreurEmploi;
  final ValueChanged<Secteur?> onSecteur;
  final ValueChanged<Emploi?> onEmploi;
  final ValueChanged<int> onAnnees;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool clair = theme.brightness == Brightness.light;
    final bool prioritaire = rang == 1;
    final List<Emploi> metiers = secteur == null
        ? const <Emploi>[]
        : referentiel.emploisDe(secteur!.id);

    return Container(
      padding: const EdgeInsets.all(Espace.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(Rayon.md),
        // Le vœu prioritaire se distingue par un liseré vert, comme sur le
        // web ; le second reste neutre.
        border: Border.all(
          color: prioritaire
              ? scheme.primary.withValues(alpha: 0.35)
              : scheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: prioritaire
                      ? scheme.primary
                      : (clair ? AppColors.pisteClaire : AppColors.pisteSombre),
                  borderRadius: BorderRadius.circular(Rayon.champ),
                ),
                child: Text(
                  '$rang',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: prioritaire ? scheme.onPrimary : scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: Espace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      prioritaire ? '1er choix' : '2e choix',
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      prioritaire
                          ? 'Votre emploi prioritaire'
                          : 'Une autre possibilité',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Espace.md),
          ChampSelection<Secteur>(
            libelle: 'Secteur',
            // Non stocké (voir [EtapeVoeux]), mais sans lui pas de métier :
            // il est donc bien exigé, comme sur le web.
            obligatoire: true,
            indication: 'Choisir un secteur',
            valeur: secteur,
            elements: referentiel.secteurs,
            etiquette: (s) => s.libelle,
            recherche: true,
            onChange: onSecteur,
          ),
          const SizedBox(height: Espace.md),
          ChampSelection<Emploi>(
            libelle: 'Emploi',
            obligatoire: true,
            indication: 'Choisir un emploi',
            valeur: emploi,
            elements: metiers,
            etiquette: (e) => e.libelle,
            // Près de 500 métiers en base : la recherche n'est pas un confort.
            recherche: true,
            erreur: erreurEmploi,
            messageListeVide: 'Choisir d’abord le secteur',
            onChange: onEmploi,
          ),
          const SizedBox(height: Espace.md),
          ChampCompteur(
            libelle: 'Années d’expérience dans ce métier',
            facultatif: true,
            valeur: annees,
            // Le serveur accepte de 0 à 50 (§4, étape 4).
            maximum: 50,
            onChange: onAnnees,
          ),
        ],
      ),
    );
  }
}
