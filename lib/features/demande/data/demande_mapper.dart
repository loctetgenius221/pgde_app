import '../../../core/config/env.dart';
import '../../../core/json/converters.dart';
import '../../../core/network/api_client.dart';
import '../../reference/domain/referentiel.dart';
import '../domain/demande.dart';

/// Correspondance entre le modèle de l'app et le contrat d'interface v1.
///
/// Lecture : une ressource imbriquée (`GET /candidat/profile`, §5.1).
/// Écriture : quatre corps à plat, un par étape (§5.2 à §5.5).
abstract final class DemandeMapper {
  static const DateOnlyConverter _date = DateOnlyConverter();

  /// Avatar générique renvoyé par le serveur quand le candidat n'a pas de
  /// photo (`photo_profil_url`, §5.1).
  static const String _avatarParDefaut = '/images/images.png';

  static Demande depuisApi(Json data) {
    final Json identite = _objet(data['identity']);
    final Json voeux = _objet(data['target_jobs']);
    final List<Json> experiences = _liste(data['experiences']);

    return Demande(
      deposee: true,
      numeroDossier: _entier(data['candidat_number']),
      dateNaissance: _date.fromJson(_texteOuNull(identite['datenaiss'])),
      lieuNaissance: _texte(identite['lieunaiss']),
      lieuResidence: _texte(identite['lieuresidence']),
      genre: Genre.depuis(identite['genre']),
      situationMatrimoniale: _situation(identite['situationmatrimoniale']),
      telephone1: _texte(identite['telephone1']),
      telephone2: _texte(identite['telephone2']),
      nombreEnfants: _entier(identite['nombreenfant']) ?? 0,
      regionNaissanceId: _identifiant(identite['region_naissance']),
      departementNaissanceId: _identifiant(identite['departement_naissance']),
      regionResidenceId: _identifiant(identite['region_residence']),
      departementResidenceId: _identifiant(identite['departement_residence']),
      aUnHandicap:
          identite['has_handicap'] == true ||
          _identifiant(identite['handicap']) != null,
      handicapId: _identifiant(identite['handicap']),
      photo: _fichierDepuisUrl(identite['photo_profil_url']),
      formations: _liste(data['formations']).map(_formation).toList(),
      aDeLExperience: switch (data['has_experience']) {
        true => true,
        false => false,
        _ => experiences.isEmpty ? null : true,
      },
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
    justificatif: _fichier(<String, dynamic>{
      'file_path': j['diplome_file'] ?? j['diplome_file_path'],
      'file_url': j['diplome_file_url'],
      'file_name': j['diplome_file_name'],
    }),
  );

  static int _academicId(Json j) {
    if (j['is_sans_diplome'] == true) return Academic.sansDiplomeId;
    final Object? brut = j['academic_id'];
    if (brut is String && brut.trim() == Academic.sansDiplomeWire) {
      return Academic.sansDiplomeId;
    }
    return _entier(brut) ?? 0;
  }

  static FichierJoint? _fichier(Json j) {
    final String url = _texte(j['file_url'] ?? j['url']);
    String chemin = _texte(j['file_path'] ?? j['path'] ?? j['diplome_file']);
    if (chemin.isEmpty && url.isNotEmpty) {
      chemin = _cheminDepuisUrl(url) ?? url;
    }
    if (url.isEmpty && chemin.isEmpty) return null;
    return FichierJoint(
      chemin: chemin.isEmpty ? url : chemin,
      url: url.isEmpty ? _adresse(chemin) : url,
      nom: _texte(j['file_name'] ?? j['nom']),
      taille: _entier(j['taille']),
    );
  }

  static FichierJoint? _fichierDepuisUrl(Object? valeur) {
    final String url = _texte(valeur);
    if (url.isEmpty) return null;
    // Sans photo, le serveur renvoie l'avatar générique du site. Le prendre
    // pour une photo faisait proposer « Changer la photo » à un candidat qui
    // n'en a jamais déposé.
    if (url.endsWith(_avatarParDefaut)) return null;
    return FichierJoint(
      chemin: _cheminDepuisUrl(url) ?? url,
      url: _adresse(url),
    );
  }

  /// Extrait `diplomes/{id}/{fichier}` d'une URL privée de justificatif.
  static String? _cheminDepuisUrl(String url) {
    final Match? match = RegExp(r'(diplomes/\d+/[^/?#]+)').firstMatch(url);
    return match?.group(1);
  }

  static String _adresse(String chemin) {
    if (chemin.startsWith('http://') || chemin.startsWith('https://')) {
      return chemin;
    }
    final String relatif = chemin.startsWith('/')
        ? chemin.substring(1)
        : chemin;
    return '${Env.racineFichiers}/$relatif';
  }

  /// `PUT /candidat/identity` — §5.2.
  static Json identite(Demande d) => <String, dynamic>{
    'telephone1': d.telephone1,
    // Facultatif : absent, il part à `null` comme dans le contrat (§5.2),
    // pas en chaîne vide qu'une colonne typée pourrait refuser.
    'telephone2': d.telephone2.trim().isEmpty ? null : d.telephone2.trim(),
    'datenaiss': _date.toJson(d.dateNaissance),
    'lieunaiss': d.lieuNaissance,
    'genre': d.genre?.wire,
    'situationmatrimoniale': d.situationMatrimoniale?.wire,
    'nombreenfant': d.nombreEnfants,
    'lieuresidence': d.lieuResidence,
    'regionnaiss_id': d.regionNaissanceId,
    'departementnaiss_id': d.departementNaissanceId,
    'regionresidence_id': d.regionResidenceId,
    'departementresidence_id': d.departementResidenceId,
    'has_handicap': d.aUnHandicap,
    'handicap_id': d.aUnHandicap ? d.handicapId : null,
  };

  /// `PUT /candidat/formations` — §5.3.
  static Json formations(Demande d) => <String, dynamic>{
    'formations': <Json>[
      for (final Formation f in d.formations)
        <String, dynamic>{
          'academic_id': f.sansDiplome
              ? Academic.sansDiplomeWire
              : '${f.academicId}',
          'diplome': f.sansDiplome ? null : _ouNull(f.diplome),
          'anneediplome': f.sansDiplome ? null : f.anneeDiplome?.toString(),
          'specialite': f.sansDiplome ? null : _ouNull(f.specialite),
          'etablissementdiplome': f.sansDiplome
              ? null
              : _ouNull(f.etablissement),
          'diplome_file': ?_cheminServeur(f.justificatif),
        },
    ],
  };

  /// `PUT /candidat/experiences` — §5.4.
  static Json experiences(Demande d) => <String, dynamic>{
    'has_experience': d.aDeLExperience == true,
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
    'cv_summary': d.resumeCv,
    'emploi1_id': d.emploi1Id,
    'anneeexperience1': d.anneesExperience1,
    'emploi2_id': d.emploi2Id,
    'anneeexperience2': d.anneesExperience2,
  };

  /// Chemin privé à renvoyer au serveur — jamais une URL publique (§5.3).
  static String? _cheminServeur(FichierJoint? piece) {
    final String chemin = piece?.chemin.trim() ?? '';
    if (chemin.isEmpty) return null;
    if (chemin.startsWith('http://') || chemin.startsWith('https://')) {
      return _cheminDepuisUrl(chemin);
    }
    if (chemin.contains('\\') ||
        chemin.startsWith('/data') ||
        chemin.startsWith('/storage')) {
      return null;
    }
    return chemin;
  }

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

  static int? _identifiant(Object? valeur) =>
      valeur is Map ? _entier(_objet(valeur)['id']) : _entier(valeur);

  static SituationMatrimoniale? _situation(Object? brut) {
    if (brut == null) return null;
    final String texte = brut.toString();
    for (final SituationMatrimoniale s in SituationMatrimoniale.values) {
      if (s.wire == texte) return s;
    }
    return null;
  }
}
