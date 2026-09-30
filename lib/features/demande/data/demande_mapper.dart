import '../../../core/config/env.dart';
import '../../../core/json/converters.dart';
import '../../../core/network/api_client.dart';
import '../../reference/domain/referentiel.dart';
import '../domain/demande.dart';

/// Correspondance entre le modèle de l'app et le contrat d'interface v1.
///
/// La lecture est **une** ressource imbriquée (`GET /candidat/profile`, §5.1)
/// tandis que l'écriture est **quatre** corps à plat, un par étape (§5.2 à
/// §5.5). Une sérialisation générée ne peut donc pas servir les deux : la
/// correspondance est écrite à la main, ici, et nulle part ailleurs.
///
/// C'est aussi le seul endroit qui connaît les tournures du contrat —
/// `hasExperience: "oui"`, `academic_id: "sansdiplome"`, les entités
/// résolues en `{id, nom}`.
abstract final class DemandeMapper {
  static const DateOnlyConverter _date = DateOnlyConverter();

  // -------------------------------------------------------------------------
  // Lecture — §5.1
  // -------------------------------------------------------------------------

  static Demande depuisApi(Json data) {
    final Json identite = _objet(data['identity']);
    final Json voeux = _objet(data['target_jobs']);
    final List<Json> experiences = _liste(data['experiences']);

    return Demande(
      // La réponse n'existe que si une fiche existe : la recevoir suffit à
      // savoir que le dossier est déposé.
      deposee: true,

      dateNaissance: _date.fromJson(_texteOuNull(identite['datenaiss'])),
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
      regionNaissanceId: _identifiant(identite['region_naissance']),
      departementNaissanceId: _identifiant(identite['departement_naissance']),
      regionResidenceId: _identifiant(identite['region_residence']),
      departementResidenceId: _identifiant(identite['departement_residence']),
      // §5.1 ne renvoie que le type résolu, ou `null` : sa présence **est**
      // la réponse « oui ».
      aUnHandicap: _identifiant(identite['handicap']) != null,
      handicapId: _identifiant(identite['handicap']),
      photo: _fichierDepuisUrl(identite['photo_profil_url']),

      formations: _liste(data['formations']).map(_formation).toList(),

      // Le contrat ne renvoie **pas** `hasExperience` en lecture (§5.1) :
      // seule la liste revient. Une liste pleine vaut « oui » ; une liste
      // vide reste ambiguë — « non » et « pas encore répondu » s'y
      // confondent. On choisit de ne rien inventer : l'étape se rouvre.
      aDeLExperience: experiences.isEmpty ? null : true,
      experiences: experiences
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
      anneesExperience1: _entier(voeux['anneeexperience1']) ?? 0,
      anneesExperience2: _entier(voeux['anneeexperience2']) ?? 0,
      resumeCv: _texte(voeux['cv_summary']),
      cv: _liste(voeux['cv_files']).map(_fichier).nonNulls.toList(),
    );
  }

  static Formation _formation(Json j) => Formation(
    academicId: _academicId(j),
    diplome: _texte(j['diplome']),
    anneeDiplome: _entier(j['anneediplome']),
    specialite: _texte(j['specialite']),
    etablissement: _texte(j['etablissementdiplome']),
    // §5.1 — le justificatif voyage **avec** sa formation.
    justificatif: _fichierDepuisUrl(
      j['diplome_file_url'],
      nom: _texte(j['diplome_file_name']),
    ),
  );

  /// §5.3 — `academic_id` peut valoir la chaîne `"sansdiplome"`, l'id 20 ou
  /// l'id 14 selon la version du serveur. Les trois disent la même chose.
  static int _academicId(Json j) {
    if (j['is_sans_diplome'] == true) return Academic.sansDiplomeId;
    final Object? brut = j['academic_id'];
    if (brut is String && brut.trim() == Academic.sansDiplomeWire) {
      return Academic.sansDiplomeId;
    }
    return _entier(brut) ?? 0;
  }

  /// Pièce décrite par un objet `{file_url, file_name}` (§5.1, `cv_files`).
  static FichierJoint? _fichier(Json j) {
    final String url = _texte(j['file_url'] ?? j['url']);
    final String chemin = _texte(j['file_path'] ?? j['path']);
    if (url.isEmpty && chemin.isEmpty) return null;
    return FichierJoint(
      chemin: chemin.isEmpty ? url : chemin,
      url: url.isEmpty ? _adresse(chemin) : url,
      nom: _texte(j['file_name'] ?? j['nom']),
      taille: _entier(j['taille']),
    );
  }

  /// Pièce décrite par une simple URL — `photo_profil_url`,
  /// `diplome_file_url` (§5.1).
  static FichierJoint? _fichierDepuisUrl(Object? valeur, {String nom = ''}) {
    final String url = _texte(valeur);
    if (url.isEmpty) return null;
    return FichierJoint(chemin: url, url: _adresse(url), nom: nom);
  }

  /// Rend une adresse absolue. Le contrat renvoie des URLs complètes, mais
  /// afficher une image vide parce qu'une réponse a livré un chemin relatif
  /// serait un mauvais échange.
  static String _adresse(String chemin) {
    if (chemin.startsWith('http://') || chemin.startsWith('https://')) {
      return chemin;
    }
    final String relatif = chemin.startsWith('/')
        ? chemin.substring(1)
        : chemin;
    return '${Env.racineFichiers}/$relatif';
  }

  // -------------------------------------------------------------------------
  // Écriture — §5.2 à §5.5
  //
  // Quatre corps, quatre endpoints. Chacun n'emporte que sa propre étape :
  // enregistrer les vœux ne peut plus effacer les formations, ce qui était
  // le risque principal de l'ancien `PUT` global.
  // -------------------------------------------------------------------------

  /// `PUT /candidat/identity` — §5.2.
  static Json identite(Demande d) => <String, dynamic>{
    'telephone1': d.telephone1,
    'telephone2': d.telephone2,
    'datenaiss': _date.toJson(d.dateNaissance),
    'lieunaiss': d.lieuNaissance,
    'genre': d.genre?.wire,
    'situationmatrimoniale': d.situationMatrimoniale?.wire,
    'nombreenfant': d.nombreEnfants,
    'lieuresidence': d.lieuResidence,
    'addresse': d.adresse,
    'regionnaiss_id': d.regionNaissanceId,
    'departementnaiss_id': d.departementNaissanceId,
    'regionresidence_id': d.regionResidenceId,
    'departementresidence_id': d.departementResidenceId,
    // Un vrai booléen, là où le formulaire web envoyait la chaîne « 0 ».
    'has_handicap': d.aUnHandicap,
    'handicap_id': d.aUnHandicap ? d.handicapId : null,
  };

  /// `PUT /candidat/formations` — §5.3.
  static Json formations(Demande d) => <String, dynamic>{
    'formations': <Json>[
      for (final Formation f in d.formations)
        <String, dynamic>{
          // La chaîne plutôt que 14 ou 20 : c'est la seule forme que toutes
          // les versions du serveur interprètent de la même façon.
          'academic_id': f.sansDiplome
              ? Academic.sansDiplomeWire
              : f.academicId,
          'diplome': f.sansDiplome ? null : _ouNull(f.diplome),
          'anneediplome': f.sansDiplome ? null : f.anneeDiplome,
          'specialite': f.sansDiplome ? null : _ouNull(f.specialite),
          'etablissementdiplome': f.sansDiplome
              ? null
              : _ouNull(f.etablissement),
          // §5.3 — sans ce rappel, le justificatif déjà déposé serait perdu
          // à la prochaine modification de la formation.
          'existing_diplome_file': ?f.justificatif?.chemin,
        },
    ],
  };

  /// `PUT /candidat/experiences` — §5.4.
  static Json experiences(Demande d) => <String, dynamic>{
    // Sans ce « oui » exact, le serveur efface les expériences.
    'hasExperience': d.aDeLExperience == true ? 'oui' : 'non',
    'experiences': <Json>[
      for (final Experience e in d.experiencesRetenues)
        <String, dynamic>{
          'poste': e.poste,
          'employeur': e.employeur,
          'years': e.annees,
          'description': e.description,
        },
    ],
  };

  /// `PUT /candidat/target-jobs` — §5.5.
  static Json voeux(Demande d) => <String, dynamic>{
    'emploi1_id': d.emploi1Id,
    'emploi2_id': d.emploi2Id,
    'anneeexperience1': d.anneesExperience1,
    'anneeexperience2': d.anneesExperience2,
    'cv_summary': d.resumeCv,
  };

  // -------------------------------------------------------------------------
  // Lecture défensive
  //
  // Le serveur est en cours d'écriture : son contrat peut encore bouger, et
  // certaines colonnes sont des chaînes là où on attend des entiers
  // (`anneediplome: "2022"`). On lit donc sans jamais supposer le type.
  // -------------------------------------------------------------------------

  static String? _ouNull(String valeur) =>
      valeur.trim().isEmpty ? null : valeur;

  static Json _objet(Object? valeur) => valeur is Map
      ? valeur.cast<String, dynamic>()
      : const <String, dynamic>{};

  static List<Json> _liste(Object? valeur) => valeur is List
      ? valeur.whereType<Map<dynamic, dynamic>>().map(_objet).toList()
      : const <Json>[];

  static String _texte(Object? valeur) => valeur?.toString() ?? '';

  static String? _texteOuNull(Object? valeur) {
    final String texte = _texte(valeur);
    return texte.isEmpty ? null : texte;
  }

  static int? _entier(Object? valeur) => switch (valeur) {
    final int n => n,
    final num n => n.toInt(),
    final String s => int.tryParse(s.trim()),
    _ => null,
  };

  /// Extrait l'`id` d'une entité résolue (`{"id": 1, "nom": …}`), ou l'entier
  /// brut si le serveur renvoie déjà un identifiant.
  static int? _identifiant(Object? valeur) =>
      valeur is Map ? _entier(_objet(valeur)['id']) : _entier(valeur);

  /// Retrouve une valeur d'énumération depuis sa chaîne réseau.
  static T? _valeurDe<T extends Enum>(List<T> valeurs, Object? brut) {
    if (brut == null) return null;
    final String texte = brut.toString();
    for (final T valeur in valeurs) {
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
