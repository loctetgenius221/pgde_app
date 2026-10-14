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
/// Aucun identifiant dans les URL : le dossier est déduit du jeton. L'écriture
/// est découpée en quatre `PUT`, un par étape (§5.2 à §5.5).
abstract interface class DemandeApi {
  Future<Demande?> mien();

  Future<void> enregistrerIdentite(Demande demande);

  Future<void> enregistrerFormations(Demande demande);

  Future<void> enregistrerExperiences(Demande demande);

  Future<void> enregistrerVoeux(Demande demande);

  /// §6.1 — champ multipart `photo`.
  Future<FichierJoint> deposerPhoto(File fichier);

  /// §6.4 — champ multipart `diplome_file`. Le `file_path` retourné doit
  /// ensuite partir dans `PUT /candidat/formations`.
  Future<FichierJoint> deposerDiplome(File fichier);

  /// §6.2 — champ multipart `cv_file`.
  Future<FichierJoint> deposerCv(File fichier);

  /// §6.3 — le chemin doit appartenir à `cv_files` du compte.
  Future<void> supprimerCv(String filePath);
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
      if (e.isNotFound) return null;
      rethrow;
    }
  }

  @override
  Future<void> enregistrerIdentite(Demande demande) =>
      _client.put('/candidat/identity', body: DemandeMapper.identite(demande));

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
  Future<void> enregistrerVoeux(Demande demande) =>
      _client.put('/candidat/target-jobs', body: DemandeMapper.voeux(demande));

  @override
  Future<FichierJoint> deposerPhoto(File fichier) async {
    final Json data = await _envoyer(
      '/candidat/files/photo',
      champ: 'photo',
      fichier: fichier,
    );
    return FichierJoint(
      chemin: _texte(data['photo_path'] ?? data['photo_url']),
      url: _texte(data['photo_url'] ?? data['photo_path']),
      nom: _nomDe(fichier),
    );
  }

  @override
  Future<FichierJoint> deposerDiplome(File fichier) async {
    final Json data = await _envoyer(
      '/candidat/files/diplome',
      champ: 'diplome_file',
      fichier: fichier,
    );
    return FichierJoint(
      chemin: _texte(data['file_path']),
      url: _texte(data['file_url']),
      nom: _texte(data['file_name']).isEmpty
          ? _nomDe(fichier)
          : _texte(data['file_name']),
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
      chemin: _texte(data['file_path']),
      url: _texte(data['file_url']),
      nom: _texte(data['file_name']),
      taille: fichier.existsSync() ? fichier.lengthSync() : null,
    );
  }

  @override
  Future<void> supprimerCv(String filePath) => _client.delete(
    '/candidat/files/cv',
    body: <String, dynamic>{'file_path': filePath},
  );

  Future<Json> _envoyer(
    String chemin, {
    required String champ,
    required File fichier,
  }) async {
    final FormData corps = FormData.fromMap(<String, dynamic>{
      champ: await MultipartFile.fromFile(
        fichier.path,
        filename: _nomDe(fichier),
      ),
    });
    final Object? data = await _client.post(chemin, body: corps);
    return data is Map
        ? data.cast<String, dynamic>()
        : const <String, dynamic>{};
  }

  static String _texte(Object? valeur) => valeur?.toString() ?? '';

  static String _nomDe(File fichier) =>
      fichier.path.split(RegExp(r'[\\/]')).last;
}

final demandeApiProvider = Provider<DemandeApi>(
  (ref) => Env.useMocks
      ? MockDemandeApi()
      : HttpDemandeApi(ref.watch(apiClientProvider)),
);
