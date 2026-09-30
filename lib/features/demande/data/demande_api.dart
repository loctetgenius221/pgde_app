import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/demande.dart';
import 'demande_mapper.dart';
import 'demande_mock_api.dart';

/// Le dossier du candidat — modules 3 et 4 du contrat d'interface.
///
/// Aucun identifiant dans les URL : le dossier est déduit de l'utilisateur
/// authentifié. Cela **supprime par construction** la classe de failles IDOR
/// corrigée à la main dans le contrôleur web.
///
/// L'écriture est découpée en quatre `PUT`, un par étape (§5.2 à §5.5).
/// C'est un changement de fond par rapport au `PUT` global précédent :
/// enregistrer une étape ne peut plus effacer les autres, et un 422 désigne
/// sans ambiguïté l'étape fautive — c'est celle qu'on venait d'envoyer.
abstract interface class DemandeApi {
  /// §5.1 — le profil complet, ou `null` si le candidat n'a encore rien
  /// rempli.
  Future<Demande?> mien();

  Future<void> enregistrerIdentite(Demande demande);

  Future<void> enregistrerFormations(Demande demande);

  Future<void> enregistrerExperiences(Demande demande);

  Future<void> enregistrerVoeux(Demande demande);

  // --- Pièces jointes (§6) ---
  //
  // Trois routes dédiées, une par nature de pièce. Elles renvoient la pièce
  // déposée, pas le dossier entier : on n'en adopte donc que ce qui change.

  /// §6.1 — remplace la photo de profil. Le serveur n'en garde qu'une.
  Future<FichierJoint> deposerPhoto(File fichier);

  /// §6.4 — justificatif d'une formation. [formationIndex] est le rang de la
  /// formation dans la liste envoyée à `PUT /candidat/formations`.
  Future<FichierJoint> deposerDiplome({
    required File fichier,
    required int formationIndex,
  });

  /// §6.2 — le CV. Retiré de la saisie aujourd'hui, la route reste couverte
  /// pour que le rétablir ne coûte qu'un écran.
  Future<FichierJoint> deposerCv(File fichier);

  /// §6.3 — le contrat n'expose **aucune suppression de justificatif de
  /// diplôme** : seul le CV peut être retiré.
  Future<void> supprimerCv();
}

class HttpDemandeApi implements DemandeApi {
  HttpDemandeApi(this._client);

  final ApiClient _client;

  @override
  Future<Demande?> mien() async {
    try {
      final Object? data = await _client.get('/candidat/profile');
      if (data is! Map) return null;
      return DemandeMapper.depuisApi(data.cast<String, dynamic>());
    } on ApiException catch (e) {
      // 404 n'est pas une erreur : c'est un candidat qui n'a rien rempli.
      if (e.isNotFound) return null;
      rethrow;
    }
  }

  @override
  Future<void> enregistrerIdentite(Demande demande) => _client.put(
    '/candidat/identity',
    body: DemandeMapper.identite(demande),
  );

  @override
  Future<void> enregistrerFormations(Demande demande) => _client.put(
    '/candidat/formations',
    body: DemandeMapper.formations(demande),
  );

  @override
  Future<void> enregistrerExperiences(Demande demande) => _client.put(
    '/candidat/experiences',
    body: DemandeMapper.experiences(demande),
  );

  @override
  Future<void> enregistrerVoeux(Demande demande) => _client.put(
    '/candidat/target-jobs',
    body: DemandeMapper.voeux(demande),
  );

  @override
  Future<FichierJoint> deposerPhoto(File fichier) async {
    final Json data = await _envoyer(
      '/candidat/files/photo',
      champ: 'photo_profil',
      fichier: fichier,
    );
    return FichierJoint(
      chemin: _texte(data['photo_profil_url']),
      url: _texte(data['photo_profil_url']),
      nom: _nomDe(fichier),
    );
  }

  @override
  Future<FichierJoint> deposerDiplome({
    required File fichier,
    required int formationIndex,
  }) async {
    final Json data = await _envoyer(
      '/candidat/files/diplome',
      champ: 'diplome_file',
      fichier: fichier,
      // §6.4 — c'est **ce champ** qui rattache le document à sa formation.
      champsSupplementaires: <String, dynamic>{
        'formation_index': formationIndex,
      },
    );
    return FichierJoint(
      chemin: _texte(data['file_path']),
      url: _texte(data['file_url']),
      nom: _nomDe(fichier),
      taille: fichier.existsSync() ? fichier.lengthSync() : null,
    );
  }

  @override
  Future<FichierJoint> deposerCv(File fichier) async {
    final Json data = await _envoyer(
      '/candidat/files/cv',
      champ: 'cv_file',
      fichier: fichier,
    );
    return FichierJoint(
      chemin: _texte(data['cv_url']),
      url: _texte(data['cv_url']),
      nom: _texte(data['cv_file_name']),
      taille: fichier.existsSync() ? fichier.lengthSync() : null,
    );
  }

  @override
  Future<void> supprimerCv() => _client.delete('/candidat/files/cv');

  Future<Json> _envoyer(
    String chemin, {
    required String champ,
    required File fichier,
    Json? champsSupplementaires,
  }) async {
    final FormData corps = FormData();
    if (champsSupplementaires != null) {
      for (final MapEntry<String, dynamic> e in champsSupplementaires.entries) {
        corps.fields.add(MapEntry(e.key, e.value.toString()));
      }
    }
    corps.files.add(
      MapEntry(
        champ,
        await MultipartFile.fromFile(fichier.path, filename: _nomDe(fichier)),
      ),
    );

    final Object? data = await _client.post(chemin, body: corps);
    return data is Map ? data.cast<String, dynamic>() : const <String, dynamic>{};
  }

  static String _texte(Object? valeur) => valeur?.toString() ?? '';

  /// Nom de fichier, quel que soit le séparateur de la plateforme.
  static String _nomDe(File fichier) =>
      fichier.path.split(RegExp(r'[\\/]')).last;
}

final demandeApiProvider = Provider<DemandeApi>(
  (ref) => Env.useMocks
      ? MockDemandeApi()
      : HttpDemandeApi(ref.watch(apiClientProvider)),
);
