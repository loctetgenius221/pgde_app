import 'package:flutter/material.dart';

import '../../../../core/network/api_exception.dart';
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      const TitreSection('Premier vœu'),
      const LegendeObligatoire(),
      _Voeu(
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
        onAnnees: (n) =>
            widget.modifier((d) => d.copyWith(anneesExperience1: n)),
      ),

      const TitreSection('Second vœu'),
      _Voeu(
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
        onAnnees: (n) =>
            widget.modifier((d) => d.copyWith(anneesExperience2: n)),
      ),

      const TitreSection(
        'Présentation',
        aide: 'Quelques lignes sur votre parcours.',
      ),
      ChampTexte(
        libelle: 'Résumé',
        valeur: widget.demande.resumeCv,
        lignes: 5,
        // Le serveur refuse au-delà de 1000 caractères (§4, étape 4).
        longueurMax: 1000,
        erreur: widget.erreurs?.errorFor('cv_summary'),
        onChange: (v) => widget.modifier((d) => d.copyWith(resumeCv: v)),
      ),
    ],
  );
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
    final List<Emploi> metiers = secteur == null
        ? const <Emploi>[]
        : referentiel.emploisDe(secteur!.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ChampSelection<Secteur>(
          libelle: 'Secteur',
          icone: Icones.secteur,
          valeur: secteur,
          elements: referentiel.secteurs,
          etiquette: (s) => s.libelle,
          recherche: true,
          onChange: onSecteur,
        ),
        const SizedBox(height: Espace.sm),
        ChampSelection<Emploi>(
          libelle: 'Métier souhaité',
          obligatoire: true,
          icone: Icones.voeu,
          valeur: emploi,
          elements: metiers,
          etiquette: (e) => e.libelle,
          // Près de 500 métiers en base : la recherche n'est pas un confort.
          recherche: true,
          erreur: erreurEmploi,
          messageListeVide: 'Choisissez d’abord un secteur',
          onChange: onEmploi,
        ),
        const SizedBox(height: Espace.sm),
        ChampTexte(
          libelle: 'Années d’expérience dans ce métier',
          icone: Icones.annee,
          valeur: annees == 0 ? '' : '$annees',
          clavier: TextInputType.number,
          formatteurs: Formats.chiffres,
          longueurMax: 2,
          onChange: (v) => onAnnees(int.tryParse(v) ?? 0),
        ),
      ],
    );
  }
}
