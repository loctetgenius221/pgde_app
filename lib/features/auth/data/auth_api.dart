import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../domain/utilisateur.dart';
import 'auth_mock_api.dart';

/// Jeton Sanctum + profil, tels que renvoyés par `POST /auth/login` (§7.2).
typedef Session = ({String token, Utilisateur utilisateur});

/// Contrat d'authentification, §7.2.
///
/// L'interface existe parce que le backend **n'expose aucune API aujourd'hui**
/// (bloqueurs B1/B2) : [MockAuthApi] permet de développer et de démontrer
/// l'app maintenant, [HttpAuthApi] prend le relais sans toucher au reste.
abstract interface class AuthApi {
  /// Le compte est créé désactivé (`enabled = 0`) : aucun jeton n'est émis,
  /// l'app enchaîne sur l'écran de vérification (§3.2).
  Future<void> register({
    required String firstname,
    required String lastname,
    required String username,
    required String numberid,
    required String email,
    required String password,
  });

  /// On se connecte avec le **nom d'utilisateur**, jamais avec l'email (§3.3).
  Future<Session> login({required String username, required String password});

  Future<Utilisateur> me();

  Future<void> logout();

  Future<void> resendVerificationEmail();
}

class HttpAuthApi implements AuthApi {
  HttpAuthApi(this._client);

  final ApiClient _client;

  /// Nomme le jeton Sanctum côté serveur, pour que l'utilisateur puisse
  /// révoquer un appareil perdu.
  static String get _deviceName => 'pgde-app-${Platform.operatingSystem}';

  @override
  Future<void> register({
    required String firstname,
    required String lastname,
    required String username,
    required String numberid,
    required String email,
    required String password,
  }) async {
    await _client.post(
      '/auth/register',
      body: <String, dynamic>{
        'firstname': firstname,
        'lastname': lastname,
        'username': username,
        'numberid': numberid,
        'email': email,
        // `email` et `password` portent la règle `confirmed` : la double
        // saisie est obligatoire dans la requête (§3.2).
        'email_confirmation': email,
        'password': password,
        'password_confirmation': password,
        'device_name': _deviceName,
      },
    );
  }

  @override
  Future<Session> login({
    required String username,
    required String password,
  }) async {
    final json = await _client.post(
      '/auth/login',
      body: <String, dynamic>{
        'username': username,
        'password': password,
        'device_name': _deviceName,
      },
    ) as Json;

    return (
      token: json['token']! as String,
      utilisateur: Utilisateur.fromJson(json['user']! as Json),
    );
  }

  @override
  Future<Utilisateur> me() async {
    final json = await _client.get('/auth/me') as Json;
    return Utilisateur.fromJson(json['user']! as Json);
  }

  @override
  Future<void> logout() => _client.post('/auth/logout');

  @override
  Future<void> resendVerificationEmail() => _client.post('/auth/email/resend');
}

/// Point de bascule unique entre le faux backend et le vrai (§ADR-001).
final authApiProvider = Provider<AuthApi>(
  (ref) => Env.useMocks
      ? MockAuthApi()
      : HttpAuthApi(ref.watch(apiClientProvider)),
);
