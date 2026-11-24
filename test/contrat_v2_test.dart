import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pgde_app/core/network/api_client.dart';
import 'package:pgde_app/core/network/api_exception.dart';
import 'package:pgde_app/core/network/auth_interceptor.dart';
import 'package:pgde_app/core/session/session_expiry.dart';
import 'package:pgde_app/core/storage/token_store.dart';
import 'package:pgde_app/features/auth/data/auth_api.dart';

/// Changements du contrat d'interface v2 (20 novembre 2026).
class _Adaptateur implements HttpClientAdapter {
  _Adaptateur(this.reponse);

  final ResponseBody Function(RequestOptions) reponse;
  final List<RequestOptions> requetes = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requetes.add(options);
    return reponse(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(String corps, int statut) => ResponseBody.fromString(
  corps,
  statut,
  headers: <String, List<String>>{
    Headers.contentTypeHeader: <String>[Headers.jsonContentType],
  },
);

class _FauxStockage extends Fake implements FlutterSecureStorage {
  _FauxStockage(this.valeur);

  String? valeur;

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => valeur;

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => valeur = null;
}

void main() {
  group('Codes du contrat v2', () {
    ApiException erreur(int statut, Map<String, dynamic> corps) =>
        ApiException.fromDio(
          DioException(
            requestOptions: RequestOptions(path: '/x'),
            type: DioExceptionType.badResponse,
            response: Response<dynamic>(
              requestOptions: RequestOptions(path: '/x'),
              statusCode: statut,
              data: corps,
            ),
          ),
        );

    test('admin_not_allowed est reconnu', () {
      final ApiException e = erreur(403, <String, dynamic>{
        'success': false,
        'code': 'admin_not_allowed',
        'message': 'Les administrateurs utilisent le site.',
      });
      expect(e.isAdminNotAllowed, isTrue);
      expect(e.message, 'Les administrateurs utilisent le site.');
    });

    test('410 signale une fonctionnalité retirée', () {
      final ApiException e = erreur(410, <String, dynamic>{
        'success': false,
        'message': 'L’envoi de CV n’est plus disponible.',
      });
      expect(e.isGone, isTrue);
    });
  });

  test(
    'identifiants refusés : un seul message, sans erreur de champ',
    () async {
      final Dio dio = Dio();
      dio.httpClientAdapter = _Adaptateur(
        (_) => _json(
          '{"success": false, "message": "x", '
          '"errors": {"password": ["Mot de passe incorrect."]}}',
          401,
        ),
      );

      await expectLater(
        HttpAuthApi(ApiClient(dio)).login(identifiant: 'awa', password: 'x'),
        throwsA(
          isA<ApiException>()
              .having(
                (e) => e.message,
                'message',
                HttpAuthApi.identifiantsIncorrects,
              )
              .having((e) => e.fieldErrors, 'fieldErrors', isEmpty),
        ),
      );
    },
  );

  group('AuthInterceptor', () {
    Future<(int, String?)> appeler({required String? jeton}) async {
      final _FauxStockage stockage = _FauxStockage(jeton);
      final SessionExpiry expiry = SessionExpiry();
      int signaux = 0;
      expiry.addListener(() => signaux++);

      const String api = 'https://api.test/api/v1';
      final Dio dio = Dio(BaseOptions(baseUrl: api))
        ..httpClientAdapter = _Adaptateur(
          (_) => _json('{"code": "unauthenticated"}', 401),
        )
        ..interceptors.add(
          AuthInterceptor(
            tokens: TokenStore(stockage),
            expiry: expiry,
            apiBaseUrl: api,
          ),
        );
      await expectLater(
        ApiClient(dio).get('/auth/me'),
        throwsA(isA<ApiException>()),
      );
      return (signaux, stockage.valeur);
    }

    test('401 avec jeton : purge et fin de session', () async {
      final (int signaux, String? reste) = await appeler(jeton: '15|abc');
      expect(signaux, 1);
      expect(reste, isNull);
    });

    test('401 sans jeton (mauvais identifiants) : pas d’expiration', () async {
      final (int signaux, _) = await appeler(jeton: null);
      expect(signaux, 0);
    });
  });
}
