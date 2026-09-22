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
}

final demandeApiProvider = Provider<DemandeApi>(
  (ref) => Env.useMocks
      ? MockDemandeApi()
      : HttpDemandeApi(ref.watch(apiClientProvider)),
);
