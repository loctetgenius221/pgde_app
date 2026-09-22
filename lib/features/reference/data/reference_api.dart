import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../domain/referentiel.dart';
import 'reference_mock_api.dart';

/// Nomenclatures, §7.3.
///
/// Un seul appel plutôt que sept : le référentiel est volumineux mais quasi
/// statique, il se charge d'un bloc et se met en cache (§5.6).
abstract interface class ReferenceApi {
  Future<Referentiel> bootstrap();
}

class HttpReferenceApi implements ReferenceApi {
  HttpReferenceApi(this._client);

  final ApiClient _client;

  @override
  Future<Referentiel> bootstrap() async =>
      Referentiel.fromJson(await _client.get('/ref/bootstrap') as Json);
}

final referenceApiProvider = Provider<ReferenceApi>(
  (ref) => Env.useMocks
      ? MockReferenceApi()
      : HttpReferenceApi(ref.watch(apiClientProvider)),
);
