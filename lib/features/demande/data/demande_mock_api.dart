import 'dart:io';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/demande.dart';
import 'demande_api.dart';
import 'demande_mapper.dart';

/// Faux backend du dossier, tant que `/api/v1` n'est pas déployé.
///
/// Il ne stocke **pas** un `Demande` tel quel : il le fait passer par les
/// quatre corps d'écriture du contrat, réassemble la réponse de
/// `GET /candidat/profile`, puis la relit avec le vrai mappeur. Ce qui ne
/// survit pas à l'aller-retour ne survivra pas non plus en production — et
/// se voit tout de suite à l'écran, plutôt qu'au premier appel réel.
class MockDemandeApi implements DemandeApi {
  static const Duration _latence = Duration(milliseconds: 500);

  Demande? _dossier;

  @override
  Future<Demande?> mien() async {
    await Future<void>.delayed(_latence);
    return _dossier;
  }

  @override
  Future<void> enregistrerIdentite(Demande demande) =>
      _enregistrer(demande, EtapeEcriture.identite);

  @override
  Future<void> enregistrerFormations(Demande demande) =>
      _enregistrer(demande, EtapeEcriture.formations);

  @override
  Future<void> enregistrerExperiences(Demande demande) =>
      _enregistrer(demande, EtapeEcriture.experiences);

  @override
  Future<void> enregistrerVoeux(Demande demande) =>
      _enregistrer(demande, EtapeEcriture.voeux);

  /// Applique **la seule tranche** que porte l'endpoint appelé.
  ///
  /// C'est tout l'intérêt du découpage du contrat : enregistrer les vœux ne
  /// doit rien changer aux formations. Le mock le vérifie en ne recopiant
  /// que les champs de l'étape.
  Future<void> _enregistrer(Demande envoye, EtapeEcriture etape) async {
    await Future<void>.delayed(_latence);
    final Demande actuel = _dossier ?? const Demande();

    _dossier = switch (etape) {
      EtapeEcriture.identite => actuel.copyWith(
        deposee: true,
        dateNaissance: envoye.dateNaissance,
        lieuNaissance: envoye.lieuNaissance,
        lieuResidence: envoye.lieuResidence,
        adresse: envoye.adresse,
        genre: envoye.genre,
        situationMatrimoniale: envoye.situationMatrimoniale,
        telephone1: envoye.telephone1,
        telephone2: envoye.telephone2,
        nombreEnfants: envoye.nombreEnfants,
        regionNaissanceId: envoye.regionNaissanceId,
        departementNaissanceId: envoye.departementNaissanceId,
        regionResidenceId: envoye.regionResidenceId,
        departementResidenceId: envoye.departementResidenceId,
        aUnHandicap: envoye.aUnHandicap,
        handicapId: envoye.handicapId,
      ),
      EtapeEcriture.formations => actuel.copyWith(
        deposee: true,
        // `existing_diplome_file` conserve le justificatif déjà déposé : on
        // repart des formations envoyées, justificatifs compris.
        formations: envoye.formations,
      ),
      EtapeEcriture.experiences => actuel.copyWith(
        deposee: true,
        aDeLExperience: envoye.aDeLExperience,
        experiences: envoye.experiencesRetenues,
      ),
      EtapeEcriture.voeux => actuel.copyWith(
        deposee: true,
        emploi1Id: envoye.emploi1Id,
        emploi2Id: envoye.emploi2Id,
        anneesExperience1: envoye.anneesExperience1,
        anneesExperience2: envoye.anneesExperience2,
        resumeCv: envoye.resumeCv,
      ),
    };

    // Aller-retour complet : ce que le serveur ne sait pas rendre est perdu
    // ici aussi, immédiatement et visiblement.
    _dossier = DemandeMapper.depuisApi(_profil(_dossier!));
  }

  @override
  Future<FichierJoint> deposerPhoto(File fichier) async {
    await Future<void>.delayed(_latence);
    final FichierJoint piece = _enregistrerFichier(fichier, 'uploads/photos');
    _dossier = (_dossier ?? const Demande()).copyWith(photo: piece);
    return piece;
  }

  @override
  Future<FichierJoint> deposerDiplome({
    required File fichier,
    required int formationIndex,
  }) async {
    await Future<void>.delayed(_latence);
    final Demande actuel = _exigeUnDossier();
    if (formationIndex >= actuel.formations.length) {
      throw const ApiException(
        'Enregistrez d’abord cette formation avant d’y joindre un document.',
        statusCode: 422,
      );
    }
    final FichierJoint piece = _enregistrerFichier(fichier, 'uploads/diplomes');
    _dossier = actuel.avecJustificatif(formationIndex, piece);
    return piece;
  }

  @override
  Future<FichierJoint> deposerCv(File fichier) async {
    await Future<void>.delayed(_latence);
    final Demande actuel = _exigeUnDossier();
    final FichierJoint piece = _enregistrerFichier(fichier, 'uploads/cv');
    _dossier = actuel.copyWith(cv: <FichierJoint>[piece]);
    return piece;
  }

  @override
  Future<void> supprimerCv() async {
    await Future<void>.delayed(_latence);
    _dossier = _exigeUnDossier().copyWith(cv: const <FichierJoint>[]);
  }

  Demande _exigeUnDossier() {
    final Demande? actuel = _dossier;
    if (actuel == null) {
      throw const ApiException(
        'Enregistrez d’abord votre demande avant d’y joindre des pièces.',
        statusCode: 404,
      );
    }
    return actuel;
  }

  /// Reproduit le nommage serveur : `time() . '_' . nom_original`, non
  /// assaini — espaces et accents compris. C'est précisément ce qui oblige
  /// l'app à encoder les URLs avant de les ouvrir.
  FichierJoint _enregistrerFichier(File fichier, String dossier) {
    final String nom = fichier.path.split(RegExp(r'[\\/]')).last;
    final String chemin =
        '$dossier/${DateTime.now().millisecondsSinceEpoch ~/ 1000}_$nom';
    return FichierJoint(
      chemin: chemin,
      url: 'http://mock.local/$chemin',
      nom: nom,
      taille: fichier.existsSync() ? fichier.lengthSync() : null,
    );
  }

  /// Réassemble la réponse de `GET /candidat/profile` (§5.1) à partir des
  /// quatre corps d'écriture, comme le ferait le serveur.
  Json _profil(Demande d) {
    final Json identite = DemandeMapper.identite(d);
    final Json voeux = DemandeMapper.voeux(d);

    return <String, dynamic>{
      'identity': <String, dynamic>{
        'telephone1': identite['telephone1'],
        'telephone2': identite['telephone2'],
        'datenaiss': identite['datenaiss'],
        'lieunaiss': identite['lieunaiss'],
        'genre': identite['genre'],
        'situationmatrimoniale': identite['situationmatrimoniale'],
        'nombreenfant': identite['nombreenfant'],
        'lieuresidence': identite['lieuresidence'],
        'addresse': identite['addresse'],
        'region_naissance': _entite(identite['regionnaiss_id']),
        'departement_naissance': _entite(identite['departementnaiss_id']),
        'region_residence': _entite(identite['regionresidence_id']),
        'departement_residence': _entite(identite['departementresidence_id']),
        // §5.1 ne rend que le type résolu : répondre « oui » sans préciser
        // le type ne survit donc pas à l'aller-retour. C'est une perte réelle
        // du contrat, et elle doit se voir.
        'handicap': _entite(identite['handicap_id']),
        'photo_profil_url': d.photo?.url,
      },
      'formations': <Json>[
        for (final Formation f in d.formations)
          <String, dynamic>{
            'academic_id': f.academicId,
            'is_sans_diplome': f.sansDiplome,
            'diplome': f.sansDiplome ? null : f.diplome,
            'anneediplome': f.sansDiplome ? null : f.anneeDiplome,
            'specialite': f.sansDiplome ? null : f.specialite,
            'etablissementdiplome': f.sansDiplome ? null : f.etablissement,
            'diplome_file_url': f.justificatif?.url,
            'diplome_file_name': f.justificatif?.nom,
          },
      ],
      'experiences': <Json>[
        for (final Experience e in d.experiencesRetenues)
          <String, dynamic>{
            'poste': e.poste,
            'employeur': e.employeur,
            'years': e.annees,
            'description': e.description,
          },
      ],
      'target_jobs': <String, dynamic>{
        'emploi1': _entite(voeux['emploi1_id']),
        'emploi2': _entite(voeux['emploi2_id']),
        'anneeexperience1': voeux['anneeexperience1'],
        'anneeexperience2': voeux['anneeexperience2'],
        'cv_summary': voeux['cv_summary'],
        'cv_files': <Json>[
          for (final FichierJoint piece in d.cv)
            <String, dynamic>{
              'file_url': piece.url,
              'file_path': piece.chemin,
              'file_name': piece.nom,
              'taille': piece.taille,
            },
        ],
      },
      'progression': <String, dynamic>{
        'is_completed': d.etapeCourante == null,
        'percentage': (d.progression * 100).round(),
      },
    };
  }

  /// Entité résolue `{id, nom}` telle que la rend le serveur, ou `null`.
  static Json? _entite(Object? id) =>
      id == null ? null : <String, dynamic>{'id': id, 'nom': ''};
}

/// Les quatre tranches d'écriture du contrat (§5.2 à §5.5).
enum EtapeEcriture { identite, formations, experiences, voeux }
