import '../../../core/json/converters.dart';
import '../../../core/network/api_client.dart';
import '../domain/demande.dart';

/// Correspondance entre le modèle de l'app et les deux formes de l'API.
///
/// La lecture (§7.6, imbriquée et résolue) et l'écriture (§7.7, à plat) **ne
/// se ressemblent pas**. Une sérialisation générée ne peut donc pas servir les
/// deux : la correspondance est écrite à la main, ici, et nulle part ailleurs.
/// C'est aussi le seul endroit qui connaît les bizarreries du contrat —
/// `handicap: "0"`, `hasExperience: "oui"`, les années castées en chaîne.
abstract final class DemandeMapper {
  static const DateOnlyConverter _date = DateOnlyConverter();

  // -------------------------------------------------------------------------
  // Lecture — §7.6
  // -------------------------------------------------------------------------

  static Demande depuisApi(Json json) {
    final Json identite = _objet(json['identite']);
    final Json naissance = _objet(identite['naissance']);
    final Json residence = _objet(identite['residence']);
    final Json voeux = _objet(json['voeux']);

    return Demande(
      id: _entier(json['id']),

      dateNaissance: _date.fromJson(identite['datenaiss'] as String?),
      lieuNaissance: _texte(identite['lieunaiss']),
      lieuResidence: _texte(identite['lieuresidence']),
      adresse: _texte(identite['addresse']),
      genre: _valeurDe(Genre.values, identite['genre']),
      situationMatrimoniale: _valeurDe(
        SituationMatrimoniale.values,
        identite['situationmatrimoniale'],
      ),
      telephone1: _texte(identite['telephone1']),
      telephone2: _texte(identite['telephone2']),
      nombreEnfants: _entier(identite['nombreenfant']) ?? 0,
      paysId: _identifiant(identite['pays']),
      regionNaissanceId: _identifiant(naissance['region']),
      departementNaissanceId: _identifiant(naissance['departement']),
      regionResidenceId: _identifiant(residence['region']),
      departementResidenceId: _identifiant(residence['departement']),
      handicapId: _identifiant(identite['handicap']),

      formations: _liste(json['formations'])
          .map(
            (f) => Formation(
              academicId: _entier(f['academic_id']) ?? 0,
              diplome: _texte(f['diplome']),
              anneeDiplome: _entier(f['anneediplome']),
              specialite: _texte(f['specialite']),
              etablissement: _texte(f['etablissementdiplome']),
            ),
          )
          .toList(),

      aDeLExperience: json['has_experience'] == true,
      experiences: _liste(json['experiences'])
          .map(
            (e) => Experience(
              poste: _texte(e['poste']),
              employeur: _texte(e['employeur']),
              description: _texte(e['description']),
              annees: _entier(e['years']),
            ),
          )
          .toList(),

      emploi1Id: _identifiant(voeux['emploi1']),
      emploi2Id: _identifiant(voeux['emploi2']),
      anneesExperience1: _entier(_objet(voeux['emploi1'])['annees']) ?? 0,
      anneesExperience2: _entier(_objet(voeux['emploi2'])['annees']) ?? 0,
      resumeCv: _texte(json['cv_summary']),
    );
  }

  // -------------------------------------------------------------------------
  // Écriture — §7.7
  // -------------------------------------------------------------------------

  /// Corps d'un `POST` ou d'un `PUT`.
  ///
  /// **L'agrégat part toujours en entier**, formations et expériences
  /// comprises. Un envoi partiel effacerait côté serveur ce qui n'est pas
  /// transmis (§6.2 D1) : c'est la protection principale de l'app contre une
  /// perte de données silencieuse.
  static Json versCorps(Demande d) => <String, dynamic>{
    'datenaiss': _date.toJson(d.dateNaissance),
    'lieunaiss': d.lieuNaissance,
    'lieuresidence': d.lieuResidence,
    'addresse': d.adresse,
    'genre': d.genre?.wire,
    'situationmatrimoniale': d.situationMatrimoniale?.wire,
    'telephone1': d.telephone1,
    'telephone2': d.telephone2,
    'nombreenfant': d.nombreEnfants,
    'country_id': d.paysId,
    'regionnaiss_id': d.regionNaissanceId,
    'departementnaiss_id': d.departementNaissanceId,
    'regionresidence_id': d.regionResidenceId,
    'departementresidence_id': d.departementResidenceId,

    // §4 : le formulaire web envoie un bouton radio. « Non » vaut la chaîne
    // « 0 », qui force `handicap_id` à null côté serveur.
    'handicap': d.handicapId == null ? '0' : '1',
    'handicap_id': d.handicapId,

    'formations': <Json>[
      for (final Formation f in d.formations)
        <String, dynamic>{
          'academic_id': f.academicId,
          'diplome': f.sansDiplome ? '' : f.diplome,
          'anneediplome': f.sansDiplome ? null : f.anneeDiplome,
          'specialite': f.sansDiplome ? '' : f.specialite,
          'etablissementdiplome': f.sansDiplome ? '' : f.etablissement,
        },
    ],

    // §4, étape 3 : sans ce « oui » exact, le serveur efface les expériences.
    'hasExperience': d.aDeLExperience ? 'oui' : 'non',
    'experiences': <Json>[
      for (final Experience e in d.experiencesRetenues)
        <String, dynamic>{
          'description': e.description,
          'years': e.annees,
          'poste': e.poste,
          'employeur': e.employeur,
        },
    ],

    'emploi1_id': d.emploi1Id,
    'emploi2_id': d.emploi2Id,
    'anneeexperience1': d.anneesExperience1,
    'anneeexperience2': d.anneesExperience2,
    'cv_summary': d.resumeCv,
  };

  // -------------------------------------------------------------------------
  // Lecture défensive
  //
  // Le backend n'existe pas encore : son contrat peut bouger, et certaines
  // colonnes sont des chaînes là où on attend des entiers (§2.4). On lit donc
  // sans jamais supposer le type.
  // -------------------------------------------------------------------------

  static Json _objet(Object? valeur) =>
      valeur is Map ? valeur.cast<String, dynamic>() : const <String, dynamic>{};

  static List<Json> _liste(Object? valeur) => valeur is List
      ? valeur.whereType<Map<dynamic, dynamic>>().map(_objet).toList()
      : const <Json>[];

  static String _texte(Object? valeur) => valeur?.toString() ?? '';

  static int? _entier(Object? valeur) => switch (valeur) {
    final int n => n,
    final num n => n.toInt(),
    final String s => int.tryParse(s.trim()),
    _ => null,
  };

  /// Extrait l'`id` d'une entité résolue par l'API (`{"id": 1, "libelle": …}`),
  /// ou l'entier brut si l'API renvoie déjà un identifiant.
  static int? _identifiant(Object? valeur) =>
      valeur is Map ? _entier(_objet(valeur)['id']) : _entier(valeur);

  /// Retrouve une valeur d'énumération depuis sa chaîne réseau.
  static T? _valeurDe<T extends Enum>(List<T> valeurs, Object? brut) {
    if (brut == null) return null;
    final String texte = brut.toString();
    for (final T valeur in valeurs) {
      // `wire` est déclaré sur chaque énumération du domaine.
      final String attendu = switch (valeur) {
        final Genre g => g.wire,
        final SituationMatrimoniale s => s.wire,
        _ => valeur.name,
      };
      if (attendu == texte) return valeur;
    }
    return null;
  }
}
