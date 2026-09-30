import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../domain/referentiel.dart';
import 'reference_mock_api.dart';
import 'referentiel_mapper.dart';

/// Nomenclatures — contrat §4.
///
/// `GET /reference/all` plutôt que les sept routes granulaires : le
/// référentiel est volumineux mais quasi statique, il se charge d'un bloc et
/// se met en cache. Le contrat recommande lui-même cet appel unique au
/// démarrage.
abstract interface class ReferenceApi {
  Future<Referentiel> bootstrap();
}

class HttpReferenceApi implements ReferenceApi {
  HttpReferenceApi(this._client);

  final ApiClient _client;

  @override
  Future<Referentiel> bootstrap() async =>
      ReferentielMapper.depuisApi(await _client.get('/reference/all') as Json);
}

final referenceApiProvider = Provider<ReferenceApi>(
  (ref) => Env.useMocks
      ? MockReferenceApi()
      : HttpReferenceApi(ref.watch(apiClientProvider)),
);
