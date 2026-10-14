import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pgde_app/core/network/api_client.dart';
import 'package:pgde_app/core/network/api_exception.dart';
import 'package:pgde_app/features/auth/data/auth_api.dart';
import 'package:pgde_app/features/auth/data/auth_mock_api.dart';
import 'package:pgde_app/features/auth/domain/utilisateur.dart';

class _FakeDioAdapter implements HttpClientAdapter {
  _FakeDioAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) => handler(options);

  @override
  void close({bool force = false}) {}
}

void main() {
  group('ApiException — extraction des codes métier Laravel (§2, §3)', () {
    test('détecte email_not_verified et access_blocked', () {
      final response = Response<dynamic>(
        requestOptions: RequestOptions(path: '/auth/login'),
        statusCode: 403,
        data: <String, dynamic>{
          'success': false,
          'code': 'email_not_verified',
          'message': 'Veuillez activer votre compte.',
        },
      );

      final exception = ApiException.fromDio(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        ),
      );

      expect(exception.statusCode, 403);
      expect(exception.code, 'email_not_verified');
      expect(exception.isEmailNotVerified, isTrue);
      expect(exception.isAccessBlocked, isFalse);
      expect(exception.message, 'Veuillez activer votre compte.');
    });

    test('détecte access_blocked', () {
      final response = Response<dynamic>(
        requestOptions: RequestOptions(path: '/auth/login'),
        statusCode: 403,
        data: <String, dynamic>{
          'success': false,
          'code': 'access_blocked',
          'message': 'Votre compte a été suspendu.',
        },
      );

      final exception = ApiException.fromDio(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        ),
      );

      expect(exception.statusCode, 403);
      expect(exception.code, 'access_blocked');
      expect(exception.isAccessBlocked, isTrue);
    });
  });

  group('HttpAuthApi — conformité au contrat v1', () {
    test(
      'register ne requiert pas de jeton et extrait le compte (§3.1)',
      () async {
        final dio = Dio();
        dio.httpClientAdapter = _FakeDioAdapter((options) async {
          expect(options.path, '/auth/register');
          expect(options.data['password_confirmation'], 'secret123');

          return ResponseBody.fromString(
            '{"success": true, "message": "Compte créé.", "data": {"user": {"id": 42, "firstname": "Awa", "lastname": "Diop", "username": "awa.diop", "numberid": "123456", "email": "awa@example.com", "enabled": false}, "email_verification_required": true}}',
            201,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        });

        final api = HttpAuthApi(ApiClient(dio));
        final utilisateur = await api.register(
          firstname: 'Awa',
          lastname: 'Diop',
          username: 'awa.diop',
          numberid: '123456',
          email: 'awa@example.com',
          password: 'secret123',
        );

        expect(utilisateur.id, 42);
        expect(utilisateur.firstname, 'Awa');
        expect(utilisateur.enabled, isFalse);
      },
    );

    test(
      'login envoie login et device_name puis conserve le jeton (§3.3)',
      () async {
        final dio = Dio();
        dio.httpClientAdapter = _FakeDioAdapter((options) async {
          expect(options.path, '/auth/login');
          expect(options.data['login'], 'awa@example.com');
          expect(options.data['password'], 'secret123');
          expect(
            (options.data['device_name'] as String).startsWith('pgde-app-'),
            isTrue,
          );

          return ResponseBody.fromString(
            '{"success": true, "message": "Connexion réussie.", "data": {"user": {"id": 42, "firstname": "Awa", "lastname": "Diop", "username": "awa.diop", "numberid": "123456", "email": "awa@example.com", "enabled": true}, "token": "42|secret", "token_type": "Bearer"}}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        });

        final session = await HttpAuthApi(
          ApiClient(dio),
        ).login(identifiant: 'awa@example.com', password: 'secret123');
        expect(session.token, '42|secret');
        expect(session.utilisateur.enabled, isTrue);
      },
    );

    test(
      'mot de passe oublié appelle la route publique avec email (§3.5)',
      () async {
        final dio = Dio();
        dio.httpClientAdapter = _FakeDioAdapter((options) async {
          expect(options.path, '/auth/forgot-password');
          expect(options.data['email'], 'awa@example.com');

          return ResponseBody.fromString(
            '{"success": true, "message": "Si cette adresse correspond à un compte, un lien lui a été envoyé."}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        });

        await HttpAuthApi(
          ApiClient(dio),
        ).demanderReinitialisation(email: 'awa@example.com');
      },
    );

    test(
      'resendVerificationEmail appelle POST /auth/resend-verification (§3.2)',
      () async {
        String? bodyEnvoye;
        final dio = Dio();
        dio.httpClientAdapter = _FakeDioAdapter((options) async {
          expect(options.path, '/auth/resend-verification');
          bodyEnvoye = options.data['email'] as String?;

          return ResponseBody.fromString(
            '{"success": true, "message": "Lien envoyé."}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        });

        final api = HttpAuthApi(ApiClient(dio));
        await api.resendVerificationEmail(email: 'awa@example.com');
        expect(bodyEnvoye, 'awa@example.com');
      },
    );
  });

  group('MockAuthApi — comportement aligné sur l’API réelle', () {
    test('inscription produit un compte non activé sans connexion', () async {
      final mock = MockAuthApi();
      final Utilisateur user = await mock.register(
        firstname: 'Fatou',
        lastname: 'Sow',
        username: 'fsow',
        numberid: '9998887776665',
        email: 'fsow@example.com',
        password: 'password',
      );

      expect(user.enabled, isFalse);
      expect(user.username, 'fsow');

      // Tentative de connexion avant activation => 403 email_not_verified
      expect(
        () => mock.login(identifiant: 'fsow', password: 'password'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            'email_not_verified',
          ),
        ),
      );
    });
  });
}
