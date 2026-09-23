import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/demande.dart';
import 'demande_mapper.dart';
import 'demande_mock_api.dart';

/// Le dossier du candidat — §7.5.
///
/// Aucun identifiant dans les URL : le dossier est déduit de l'utilisateur
/// authentifié. Cela **supprime par construction** la classe de failles IDOR
/// corrigée à la main dans le contrôleur web (SEC-02).
abstract interface class DemandeApi {
  /// Le dossier de l'utilisateur, ou `null` s'il n'en a pas encore.
  Future<Demande?> mien();

  /// Création — une seule fois par compte (`utilisateur_id` UNIQUE, §2.1).
  Future<Demande> creer(Demande demande);

  Future<Demande> mettreAJour(Demande demande);

  // --- Pièces jointes (§7.5) ---
  //
  // Elles vivent sur la même ressource `/demande` et dans le même dossier
  // serveur : les séparer dans une seconde interface obligerait les deux
  // implémentations à se partager un état. La cohésion l'emporte ici sur le
  // découpage.

  /// Remplace la photo de profil. Le serveur n'en garde qu'une (§2.3).
  Future<Demande> deposerPhoto(File fichier);

  /// Ajoute des diplômes ou des CV au dossier.
  Future<Demande> deposerDocuments({
    required TypeFichier type,
    required List<File> fichiers,
  });

  /// Retire une pièce. [chemin] est le `path` renvoyé par l'API, jamais l'URL.
  Future<Demande> supprimerFichier({
    required TypeFichier type,
    required String chemin,
  });
}

class HttpDemandeApi implements DemandeApi {
  HttpDemandeApi(this._client);

  final ApiClient _client;

  @override
  Future<Demande?> mien() async {
    try {
      return DemandeMapper.depuisApi(await _client.get('/demande') as Json);
    } on ApiException catch (e) {
      // 404 n'est pas une erreur : c'est un candidat qui n'a rien déposé.
      if (e.isNotFound) return null;
      rethrow;
    }
  }

  @override
  Future<Demande> creer(Demande demande) async => DemandeMapper.depuisApi(
    await _client.post('/demande', body: DemandeMapper.versCorps(demande))
        as Json,
  );

  @override
  Future<Demande> mettreAJour(Demande demande) async => DemandeMapper.depuisApi(
    await _client.put('/demande', body: DemandeMapper.versCorps(demande))
        as Json,
  );

  @override
  Future<Demande> deposerPhoto(File fichier) async {
    final FormData corps = FormData();
    corps.files.add(
      MapEntry(
        'photo_profil',
        await MultipartFile.fromFile(fichier.path, filename: _nomDe(fichier)),
      ),
    );
    return DemandeMapper.depuisApi(
      await _client.post('/demande/photo', body: corps) as Json,
    );
  }

  @override
  Future<Demande> deposerDocuments({
    required TypeFichier type,
    required List<File> fichiers,
  }) async {
    // §8.6 : Laravel attend la **même clé répétée**, suffixée de crochets —
    // `diplome_file[]`, et non un tableau JSON.
    final String cle = '${type.wire}_file[]';
    final FormData corps = FormData();
    for (final File fichier in fichiers) {
      corps.files.add(
        MapEntry(
          cle,
          await MultipartFile.fromFile(fichier.path, filename: _nomDe(fichier)),
        ),
      );
    }
    return DemandeMapper.depuisApi(
      await _client.post('/demande/files', body: corps) as Json,
    );
  }

  @override
  Future<Demande> supprimerFichier({
    required TypeFichier type,
    required String chemin,
  }) async => DemandeMapper.depuisApi(
    await _client.delete(
          '/demande/files',
          body: <String, dynamic>{'type': type.wire, 'path': chemin},
        )
        as Json,
  );

  /// Nom de fichier, quel que soit le séparateur de la plateforme.
  static String _nomDe(File fichier) =>
      fichier.path.split(RegExp(r'[\/]')).last;
}

final demandeApiProvider = Provider<DemandeApi>(
  (ref) => Env.useMocks
      ? MockDemandeApi()
      : HttpDemandeApi(ref.watch(apiClientProvider)),
);
