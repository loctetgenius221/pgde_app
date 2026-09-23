import 'package:flutter/material.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/ui/champs.dart';
import '../../../../core/ui/icone.dart';
import '../../../reference/domain/referentiel.dart';
import '../../domain/demande.dart';
import '../../domain/telephone.dart';
import 'etape_wizard.dart';
import 'pieces_jointes.dart';

/// Étape 1 — identité et résidence (§4).
///
/// Champs obligatoires côté serveur : date de naissance, lieu de naissance,
/// lieu de résidence, genre et premier téléphone. Tout le reste est facultatif,
/// même si le formulaire web en marque davantage.
class EtapeIdentite extends StatelessWidget {
  const EtapeIdentite({
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      // La photo est une pièce d'identité : sa place est avec l'état civil,
      // en ouverture, pas au milieu des diplômes.
      SectionPhoto(demande: demande),

      const TitreSection('État civil'),

      ChampDate(
        // Pas d'icône de tête : `ChampDate` pose déjà un calendrier en fin de
        // champ, qui est l'affordance du sélecteur. Deux fois la même icône
        // sur une ligne ne dit rien de plus.
        libelle: 'Date de naissance',
        valeur: demande.dateNaissance,
        erreur: erreurs?.errorFor('datenaiss'),
        onChange: (v) => modifier((d) => d.copyWith(dateNaissance: v)),
      ),
      const SizedBox(height: Espace.sm),

      ChoixSegmente<Genre>(
        libelle: 'Genre',
        valeur: demande.genre,
        options: Genre.values,
        // `wire` porte la valeur exacte attendue en base (§4) : afficher autre
        // chose ici ne changerait rien à ce qui est envoyé.
        etiquette: (g) => g == Genre.masculin ? 'Masculin' : 'Féminin',
        erreur: erreurs?.errorFor('genre'),
        onChange: (v) => modifier((d) => d.copyWith(genre: v)),
      ),
      const SizedBox(height: Espace.sm),

      ChampTexte(
        libelle: 'Lieu de naissance',
        icone: Icones.lieu,
        valeur: demande.lieuNaissance,
        erreur: erreurs?.errorFor('lieunaiss'),
        majusculesAutomatiques: true,
        onChange: (v) => modifier((d) => d.copyWith(lieuNaissance: v)),
      ),
      const SizedBox(height: Espace.sm),

      ChampSelection<Region>(
        libelle: 'Région de naissance',
        icone: Icones.region,
        valeur: _region(demande.regionNaissanceId),
        elements: referentiel.regions,
        etiquette: (r) => r.libelle,
        erreur: erreurs?.errorFor('regionnaiss_id'),
        // Changer de région invalide le département : le laisser afficherait
        // un département qui n'appartient plus à la région choisie (§8.9).
        onChange: (v) => modifier(
          (d) => d.copyWith(
            regionNaissanceId: v?.id,
            departementNaissanceId: null,
          ),
        ),
      ),
      const SizedBox(height: Espace.sm),

      ChampSelection<Departement>(
        libelle: 'Département de naissance',
        icone: Icones.lieu,
        valeur: _departement(demande.departementNaissanceId),
        elements: _departementsDe(demande.regionNaissanceId),
        etiquette: (d) => d.libelle,
        erreur: erreurs?.errorFor('departementnaiss_id'),
        messageListeVide: 'Choisissez d’abord une région',
        onChange: (v) =>
            modifier((d) => d.copyWith(departementNaissanceId: v?.id)),
      ),

      const TitreSection('Résidence'),

      ChampTexte(
        libelle: 'Lieu de résidence',
        icone: Icones.lieu,
        valeur: demande.lieuResidence,
        erreur: erreurs?.errorFor('lieuresidence'),
        majusculesAutomatiques: true,
        onChange: (v) => modifier((d) => d.copyWith(lieuResidence: v)),
      ),
      const SizedBox(height: Espace.sm),

      ChampSelection<Region>(
        libelle: 'Région de résidence',
        icone: Icones.region,
        valeur: _region(demande.regionResidenceId),
        elements: referentiel.regions,
        etiquette: (r) => r.libelle,
        erreur: erreurs?.errorFor('regionresidence_id'),
        onChange: (v) => modifier(
          (d) => d.copyWith(
            regionResidenceId: v?.id,
            departementResidenceId: null,
            // Quitter « Hors Sénégal » rend le pays sans objet.
            paysId: v?.id == Region.horsSenegalId ? d.paysId : null,
          ),
        ),
      ),
      const SizedBox(height: Espace.sm),

      // §5.1 : la région 15 n'a aucun département rattaché. On demande le pays
      // à la place, jamais les deux.
      if (demande.resideHorsSenegal)
        ChampSelection<Pays>(
          libelle: 'Pays de résidence',
          icone: Icones.region,
          valeur: _pays(demande.paysId),
          elements: referentiel.countries,
          etiquette: (p) => p.name,
          recherche: true,
          erreur: erreurs?.errorFor('country_id'),
          onChange: (v) => modifier((d) => d.copyWith(paysId: v?.id)),
        )
      else
        ChampSelection<Departement>(
          libelle: 'Département de résidence',
          icone: Icones.lieu,
          valeur: _departement(demande.departementResidenceId),
          elements: _departementsDe(demande.regionResidenceId),
          etiquette: (d) => d.libelle,
          erreur: erreurs?.errorFor('departementresidence_id'),
          messageListeVide: 'Choisissez d’abord une région',
          onChange: (v) =>
              modifier((d) => d.copyWith(departementResidenceId: v?.id)),
        ),
      const SizedBox(height: Espace.sm),

      ChampTexte(
        libelle: 'Adresse',
        icone: Icones.adresse,
        valeur: demande.adresse,
        erreur: erreurs?.errorFor('addresse'),
        onChange: (v) => modifier((d) => d.copyWith(adresse: v)),
      ),

      const TitreSection('Contact'),

      ChampTexte(
        libelle: 'Téléphone principal',
        icone: Icones.telephone,
        valeur: demande.telephone1,
        clavier: TextInputType.phone,
        formatteurs: Formats.telephone,
        // Le serveur accepte n'importe quoi dans un varchar(45) : c'est
        // ici que se joue la joignabilité du candidat (§8.9).
        erreur:
            erreurs?.errorFor('telephone1') ??
            Telephone.refus(demande.telephone1),
        onChange: (v) => modifier((d) => d.copyWith(telephone1: v)),
      ),
      const SizedBox(height: Espace.sm),

      ChampTexte(
        libelle: 'Téléphone secondaire',
        icone: Icones.telephone,
        valeur: demande.telephone2,
        clavier: TextInputType.phone,
        formatteurs: Formats.telephone,
        // Le serveur accepte n'importe quoi dans un varchar(45) : c'est
        // ici que se joue la joignabilité du candidat (§8.9).
        erreur:
            erreurs?.errorFor('telephone2') ??
            Telephone.refus(demande.telephone2),
        onChange: (v) => modifier((d) => d.copyWith(telephone2: v)),
      ),

      const TitreSection('Situation personnelle'),

      ChampSelection<SituationMatrimoniale>(
        libelle: 'Situation matrimoniale',
        icone: Icones.famille,
        valeur: demande.situationMatrimoniale,
        elements: SituationMatrimoniale.values,
        etiquette: (s) => s.wire,
        erreur: erreurs?.errorFor('situationmatrimoniale'),
        onChange: (v) => modifier((d) => d.copyWith(situationMatrimoniale: v)),
      ),
      const SizedBox(height: Espace.sm),

      ChampTexte(
        libelle: 'Nombre d’enfants',
        icone: Icones.enfants,
        valeur: demande.nombreEnfants == 0 ? '' : '${demande.nombreEnfants}',
        clavier: TextInputType.number,
        formatteurs: Formats.chiffres,
        erreur: erreurs?.errorFor('nombreenfant'),
        onChange: (v) =>
            modifier((d) => d.copyWith(nombreEnfants: int.tryParse(v) ?? 0)),
      ),
      const SizedBox(height: Espace.md),

      ChoixSegmente<bool>(
        libelle: 'Êtes-vous en situation de handicap ?',
        valeur: demande.handicapId != null,
        options: const <bool>[false, true],
        etiquette: (oui) => oui ? 'Oui' : 'Non',
        // « Non » efface le type : le serveur reçoit alors `handicap: "0"`,
        // qui force `handicap_id` à null (§4).
        onChange: (oui) =>
            modifier((d) => d.copyWith(handicapId: oui ? d.handicapId : null)),
      ),
      if (demande.handicapId != null || _handicapDeclare) ...<Widget>[
        const SizedBox(height: Espace.sm),
        ChampSelection<Handicap>(
          libelle: 'Type de handicap',
          icone: Icones.handicap,
          valeur: _handicap(demande.handicapId),
          elements: referentiel.handicaps,
          etiquette: (h) => h.libelle,
          erreur: erreurs?.errorFor('handicap_id'),
          onChange: (v) => modifier((d) => d.copyWith(handicapId: v?.id)),
        ),
      ],
    ],
  );

  bool get _handicapDeclare => demande.handicapId != null;

  Region? _region(int? id) => _parId(referentiel.regions, id, (r) => r.id);
  Departement? _departement(int? id) =>
      _parId(referentiel.departements, id, (d) => d.id);
  Handicap? _handicap(int? id) =>
      _parId(referentiel.handicaps, id, (h) => h.id);
  Pays? _pays(int? id) => _parId(referentiel.countries, id, (p) => p.id);

  List<Departement> _departementsDe(int? regionId) => regionId == null
      ? const <Departement>[]
      : referentiel.departementsDe(regionId);

  static T? _parId<T>(List<T> elements, int? id, int Function(T) cle) {
    if (id == null) return null;
    for (final T element in elements) {
      if (cle(element) == id) return element;
    }
    return null;
  }
}
