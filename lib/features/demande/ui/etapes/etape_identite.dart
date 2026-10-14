import 'package:flutter/material.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/ui/champs.dart';
import '../../../../core/ui/icone.dart';
import '../../../../core/ui/responsive.dart';
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
      const SizedBox(height: Espace.sm),
      SectionPhoto(demande: demande),

      // Sections, ordre et regroupement en lignes repris du formulaire web :
      // le candidat qui a commencé sur le site retrouve chaque champ à sa
      // place. Sur téléphone, chaque grille se replie en une colonne.
      const TitreSection('Naissance et état civil'),
      const LegendeObligatoire(),

      GrilleChamps(
        children: <Widget>[
          ChoixSegmente<Genre>(
            libelle: 'Genre',
            obligatoire: true,
            valeur: demande.genre,
            options: Genre.values,
            // `wire` porte la valeur exacte attendue en base (§4) : le libellé
            // affiché, repris du web, ne change rien à ce qui est envoyé.
            etiquette: (g) => g == Genre.masculin ? 'Homme' : 'Femme',
            erreur: erreurs?.errorFor('genre'),
            onChange: (v) => modifier((d) => d.copyWith(genre: v)),
          ),
          ChampDate(
            libelle: 'Date de naissance',
            obligatoire: true,
            valeur: demande.dateNaissance,
            erreur: erreurs?.errorFor('datenaiss'),
            onChange: (v) => modifier((d) => d.copyWith(dateNaissance: v)),
          ),
        ],
      ),
      const SizedBox(height: Espace.md),

      GrilleChamps(
        colonnesMax: 3,
        children: <Widget>[
          ChampTexte(
            libelle: 'Lieu de naissance',
            obligatoire: true,
            valeur: demande.lieuNaissance,
            erreur: erreurs?.errorFor('lieunaiss'),
            majusculesAutomatiques: true,
            onChange: (v) => modifier((d) => d.copyWith(lieuNaissance: v)),
          ),
          ChampSelection<Region>(
            libelle: 'Région de naissance',
            valeur: _region(demande.regionNaissanceId),
            elements: referentiel.regions,
            etiquette: (r) => r.libelle,
            erreur: erreurs?.errorFor('regionnaiss_id'),
            // Changer de région invalide le département : le laisser
            // afficherait un département qui n'appartient plus à la région
            // choisie (§8.9).
            onChange: (v) => modifier(
              (d) => d.copyWith(
                regionNaissanceId: v?.id,
                departementNaissanceId: null,
              ),
            ),
          ),
          ChampSelection<Departement>(
            libelle: 'Département de naissance',
            valeur: _departement(demande.departementNaissanceId),
            elements: _departementsDe(demande.regionNaissanceId),
            etiquette: (d) => d.libelle,
            erreur: erreurs?.errorFor('departementnaiss_id'),
            messageListeVide: 'Choisissez d’abord une région',
            onChange: (v) =>
                modifier((d) => d.copyWith(departementNaissanceId: v?.id)),
          ),
        ],
      ),
      const SizedBox(height: Espace.md),

      GrilleChamps(
        children: <Widget>[
          ChoixSegmente<SituationMatrimoniale>(
            libelle: 'Situation matrimoniale',
            valeur: demande.situationMatrimoniale,
            options: SituationMatrimoniale.values,
            // Quatre options ne tiennent pas sur une ligne de téléphone.
            colonnes: 2,
            etiquette: (s) => s.wire,
            erreur: erreurs?.errorFor('situationmatrimoniale'),
            onChange: (v) =>
                modifier((d) => d.copyWith(situationMatrimoniale: v)),
          ),
          ChampCompteur(
            libelle: 'Nombre d’enfants',
            valeur: demande.nombreEnfants,
            erreur: erreurs?.errorFor('nombreenfant'),
            onChange: (v) => modifier((d) => d.copyWith(nombreEnfants: v)),
          ),
        ],
      ),

      const TitreSection('Contact et résidence'),

      GrilleChamps(
        children: <Widget>[
          ChampTexte(
            libelle: 'Téléphone principal',
            obligatoire: true,
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
          ChampTexte(
            libelle: 'Téléphone secondaire',
            facultatif: true,
            valeur: demande.telephone2,
            clavier: TextInputType.phone,
            formatteurs: Formats.telephone,
            erreur:
                erreurs?.errorFor('telephone2') ??
                Telephone.refus(demande.telephone2),
            onChange: (v) => modifier((d) => d.copyWith(telephone2: v)),
          ),
        ],
      ),
      const SizedBox(height: Espace.md),

      // Même bascule que sur le web. Elle n'a pas de champ à elle : « À
      // l'étranger » **est** la région 15 (§5.1), et le serveur ne connaît
      // que `regionresidence_id`. La dériver de la région évite deux sources
      // de vérité qui pourraient se contredire.
      ChoixSegmente<bool>(
        libelle: 'Où résidez-vous ?',
        obligatoire: true,
        valeur: demande.resideHorsSenegal,
        options: const <bool>[false, true],
        etiquette: (etranger) => etranger ? 'À l’étranger' : 'Au Sénégal',
        icone: (etranger) => etranger ? Icones.region : Icones.lieu,
        onChange: (etranger) {
          if (etranger == demande.resideHorsSenegal) return;
          modifier(
            (d) => d.copyWith(
              regionResidenceId: etranger ? Region.horsSenegalId : null,
              departementResidenceId: null,
              paysId: null,
            ),
          );
        },
      ),
      const SizedBox(height: Espace.md),

      GrilleChamps(
        colonnesMax: 3,
        children: <Widget>[
          if (demande.resideHorsSenegal) ...<Widget>[
            // §5.2 n'a pas de `country_id`, et le contrat n'expose aucune
            // route « pays » : sans référentiel, le sélecteur serait vide. On
            // le masque plutôt que d'ouvrir une liste sur du néant — il
            // réapparaîtra seul le jour où le serveur publiera la liste.
            if (referentiel.countries.isNotEmpty)
              ChampSelection<Pays>(
                libelle: 'Pays de résidence',
                valeur: _pays(demande.paysId),
                elements: referentiel.countries,
                etiquette: (p) => p.name,
                recherche: true,
                erreur: erreurs?.errorFor('country_id'),
                onChange: (v) => modifier((d) => d.copyWith(paysId: v?.id)),
              ),
          ] else ...<Widget>[
            ChampSelection<Region>(
              libelle: 'Région de résidence',
              valeur: _region(demande.regionResidenceId),
              // « Hors Sénégal » est porté par la bascule ci-dessus : le
              // proposer aussi ici offrirait deux chemins vers le même état.
              elements: referentiel.regions
                  .where((r) => r.id != Region.horsSenegalId)
                  .toList(),
              etiquette: (r) => r.libelle,
              erreur: erreurs?.errorFor('regionresidence_id'),
              // Changer de région invalide le département (§8.9).
              onChange: (v) => modifier(
                (d) => d.copyWith(
                  regionResidenceId: v?.id,
                  departementResidenceId: null,
                ),
              ),
            ),
            ChampSelection<Departement>(
              libelle: 'Département de résidence',
              valeur: _departement(demande.departementResidenceId),
              elements: _departementsDe(demande.regionResidenceId),
              etiquette: (d) => d.libelle,
              erreur: erreurs?.errorFor('departementresidence_id'),
              messageListeVide: 'Choisissez d’abord une région',
              onChange: (v) =>
                  modifier((d) => d.copyWith(departementResidenceId: v?.id)),
            ),
          ],
          ChampTexte(
            libelle: 'Lieu de résidence',
            obligatoire: true,
            valeur: demande.lieuResidence,
            // À l'étranger, faute de liste des pays, c'est ce champ qui dit
            // où.
            aide: demande.resideHorsSenegal
                ? 'Ville et pays de résidence'
                : null,
            erreur: erreurs?.errorFor('lieuresidence'),
            majusculesAutomatiques: true,
            onChange: (v) => modifier((d) => d.copyWith(lieuResidence: v)),
          ),
        ],
      ),

      const Padding(
        padding: EdgeInsets.symmetric(vertical: Espace.lg),
        child: Divider(),
      ),

      GrilleChamps(
        children: <Widget>[
          ChoixSegmente<bool>(
            libelle: 'Êtes-vous en situation de handicap ?',
            valeur: demande.aUnHandicap,
            options: const <bool>[false, true],
            etiquette: (oui) => oui ? 'Oui' : 'Non',
            // « Non » efface le type : le serveur reçoit alors
            // `handicap: "0"`, qui force `handicap_id` à null (§4).
            onChange: (oui) => modifier(
              (d) => d.copyWith(
                aUnHandicap: oui,
                handicapId: oui ? d.handicapId : null,
              ),
            ),
          ),
          if (demande.aUnHandicap)
            ChampSelection<Handicap>(
              libelle: 'Type de handicap',
              valeur: _handicap(demande.handicapId),
              elements: referentiel.handicaps,
              etiquette: (h) => h.libelle,
              erreur: erreurs?.errorFor('handicap_id'),
              onChange: (v) => modifier((d) => d.copyWith(handicapId: v?.id)),
            ),
        ],
      ),
    ],
  );

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
