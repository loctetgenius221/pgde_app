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
/// Cinq opérations sont spécifiées : inscription, connexion, profil,
/// déconnexion, mot de passe oublié. Les quatre suivantes — renvoi de
/// l'email de vérification, saisie du code, changement de mot de passe,
/// disponibilité d'un identifiant — **n'ont pas d'endpoint dans la v1** :
/// elles restent dans l'interface parce que les écrans existent et
/// fonctionnent sur le faux backend, et [HttpAuthApi] les refuse d'un message
/// explicite plutôt que d'appeler une route imaginaire.
abstract interface class AuthApi {
  /// §3.1 — le compte est créé `enabled: false`, **mais un jeton est émis**.
  /// L'app est donc authentifiée dès l'inscription ; c'est le routeur qui
  /// retient l'utilisateur sur l'écran de vérification tant que le compte
  /// n'est pas activé.
  Future<Session> register({
    required String firstname,
    required String lastname,
    required String username,
    required String numberid,
    required String email,
    required String password,
  });

  /// §3.2 — [identifiant] vaut **l'email ou le nom d'utilisateur** : le
  /// serveur accepte les deux sur le même champ.
  Future<Session> login({
    required String identifiant,
    required String password,
  });

  Future<Utilisateur> me();

  Future<void> logout();

  /// §3.5 — l'email seul. La v1 ne demande pas le numéro de pièce.
  Future<void> demanderReinitialisation({required String email});

  // --- Hors contrat v1 -----------------------------------------------------

  Future<void> resendVerificationEmail();

  Future<Utilisateur> verifierAvecCode(String code);

  Future<void> changerMotDePasse({
    required String actuel,
    required String nouveau,
  });

  Future<bool> estDisponible({
    String? username,
    String? email,
    String? numberid,
  });
}

class HttpAuthApi implements AuthApi {
  HttpAuthApi(this._client);

  final ApiClient _client;

  /// Nomme le jeton Sanctum côté serveur, pour que l'utilisateur puisse
  /// révoquer un appareil perdu.
  static String get _deviceName => 'pgde-app-${Platform.operatingSystem}';

  /// Refus d'une opération que la v1 n'expose pas.
  ///
  /// Un message net vaut mieux qu'un 404 traduit en « Ressource
  /// introuvable » : celui-ci dit *pourquoi*, et à qui le demander.
  static Never _horsContrat(String operation) => throw ApiException(
    '$operation n’est pas encore disponible sur le serveur.',
    statusCode: 501,
  );

  @override
  Future<Session> register({
    required String firstname,
    required String lastname,
    required String username,
    required String numberid,
    required String email,
    required String password,
  }) async => _session(
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
        as Json,
  );

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
    final Utilisateur utilisateur = Utilisateur.fromJson(
      data['user']! as Json,
    );

    // §3.3 — `profile_summary` vit à côté de `user`. Seul `has_userdata`
    // sert au routage ; le taux de complétion, lui, est recalculé sur le
    // dossier en mémoire, qui est à jour même avant l'enregistrement.
    final Object? resume = data['profile_summary'];
    if (resume is! Map) return utilisateur;
    return utilisateur.copyWith(
      hasProfile: resume['has_userdata'] == true,
    );
  }

  @override
  Future<void> logout() => _client.post('/auth/logout');

  @override
  Future<void> demanderReinitialisation({required String email}) =>
      _client.post(
        '/auth/forgot-password',
        body: <String, dynamic>{'email': email},
      );

  @override
  Future<void> resendVerificationEmail() async =>
      _horsContrat('Le renvoi de l’email de vérification');

  @override
  Future<Utilisateur> verifierAvecCode(String code) async =>
      _horsContrat('La vérification par code');

  @override
  Future<void> changerMotDePasse({
    required String actuel,
    required String nouveau,
  }) async => _horsContrat('Le changement de mot de passe');

  @override
  Future<bool> estDisponible({
    String? username,
    String? email,
    String? numberid,
  }) async {
    // Silencieux plutôt que bloquant : ce contrôle n'est qu'un confort qui
    // évite un 422 après un formulaire de huit champs. Sans endpoint, on
    // laisse simplement le serveur trancher à l'inscription.
    return true;
  }
}

/// Point de bascule unique entre le faux backend et le vrai (§ADR-001).
final authApiProvider = Provider<AuthApi>(
  (ref) =>
      Env.useMocks ? MockAuthApi() : HttpAuthApi(ref.watch(apiClientProvider)),
);
