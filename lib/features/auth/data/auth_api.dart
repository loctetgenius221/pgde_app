import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/utilisateur.dart';
import 'auth_mock_api.dart';

/// Jeton Sanctum + profil, tels que renvoyés par `/auth/login` et
/// `/auth/register` (contrat §3.1, §3.2).
typedef Session = ({String token, Utilisateur utilisateur});

/// Contrat d'authentification — module 1 du contrat d'interface.
///
/// Les opérations disponibles sur le serveur sont exposées par ce contrat.
/// La vérification par code reste réservée au faux backend de démonstration.
abstract interface class AuthApi {
  /// §3.1 — le compte est créé `enabled: false`. **Aucun jeton n'est émis.**
  /// Le candidat doit activer son compte par email puis se connecter.
  Future<Utilisateur> register({
    required String firstname,
    required String lastname,
    required String username,
    required String numberid,
    required String email,
    required String password,
  });

  /// §3.3 — [identifiant] vaut **l'email ou le nom d'utilisateur** : le
  /// serveur accepte les deux sur le même champ.
  Future<Session> login({
    required String identifiant,
    required String password,
  });

  Future<Utilisateur> me();

  Future<void> logout();

  /// §3.5 — l'email seul. La v1 ne demande pas le numéro de pièce.
  Future<void> demanderReinitialisation({required String email});

  /// §3.2 — renvoie le lien d'activation par e-mail.
  Future<void> resendVerificationEmail({required String email});

  // --- Hors contrat v1 -----------------------------------------------------

  Future<Utilisateur> verifierAvecCode(String code, {String? email});
}

class HttpAuthApi implements AuthApi {
  HttpAuthApi(this._client);

  final ApiClient _client;

  /// Nomme le jeton Sanctum côté serveur, pour que l'utilisateur puisse
  /// révoquer un appareil perdu.
  static String get _deviceName => 'pgde-app-${Platform.operatingSystem}';

  /// Refus d'une opération que la v1 n'expose pas.
  static Never _horsContrat(String operation) => throw ApiException(
    '$operation n’est pas disponible sur le serveur.',
    statusCode: 501,
  );

  @override
  Future<Utilisateur> register({
    required String firstname,
    required String lastname,
    required String username,
    required String numberid,
    required String email,
    required String password,
  }) async {
    final Json data =
        await _client.post(
              '/auth/register',
              body: <String, dynamic>{
                'firstname': firstname,
                'lastname': lastname,
                'username': username,
                'numberid': numberid,
                'email': email,
                'password': password,
                'password_confirmation': password,
              },
            )
            as Json;

    return Utilisateur.fromJson(data['user']! as Json);
  }

  @override
  Future<Session> login({
    required String identifiant,
    required String password,
  }) async => _session(
    await _client.post(
          '/auth/login',
          body: <String, dynamic>{
            'login': identifiant,
            'password': password,
            'device_name': _deviceName,
          },
        )
        as Json,
  );

  static Session _session(Json data) => (
    token: data['token']! as String,
    utilisateur: Utilisateur.fromJson(data['user']! as Json),
  );

  @override
  Future<Utilisateur> me() async {
    final Json data = await _client.get('/auth/me') as Json;
    final Object? userJson = data.containsKey('user') ? data['user'] : data;
    return Utilisateur.fromJson(userJson! as Json);
  }

  @override
  Future<void> logout() => _client.post('/auth/logout');

  @override
  Future<void> demanderReinitialisation({required String email}) => _client
      .post('/auth/forgot-password', body: <String, dynamic>{'email': email});

  @override
  Future<void> resendVerificationEmail({required String email}) => _client.post(
    '/auth/resend-verification',
    body: <String, dynamic>{'email': email},
  );

  @override
  Future<Utilisateur> verifierAvecCode(String code, {String? email}) async =>
      _horsContrat('La vérification par code direct');
}

/// Point de bascule unique entre le faux backend et le vrai (§ADR-001).
final authApiProvider = Provider<AuthApi>(
  (ref) =>
      Env.useMocks ? MockAuthApi() : HttpAuthApi(ref.watch(apiClientProvider)),
);
