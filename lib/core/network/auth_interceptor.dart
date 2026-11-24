import 'package:dio/dio.dart';

import '../config/env.dart';
import '../session/session_expiry.dart';
import '../storage/token_store.dart';

/// Porte le jeton Bearer sur chaque requête et détecte l'expiration de session.
///
/// Contrat v2 §1 : un jeton vit 30 jours et il est révoqué dès que le mot de
/// passe change, quel que soit le canal. Tout `401` sur une requête qui
/// **portait** un jeton signifie donc « session terminée » : on purge le
/// jeton et on prévient l'application, sans nouvelle tentative.
///
/// Un `401` sans jeton n'a pas ce sens : sur `POST /auth/login`, il signale
/// des identifiants incorrects. Le traiter comme une expiration relancerait
/// la restauration de session au milieu d'une saisie.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required TokenStore tokens,
    required SessionExpiry expiry,
    String apiBaseUrl = Env.apiBaseUrl,
  }) : _tokens = tokens,
       _expiry = expiry,
       _api = Uri.parse(apiBaseUrl);

  final TokenStore _tokens;
  final SessionExpiry _expiry;
  final Uri _api;

  /// Audit SEC-001 — le jeton ne part que vers le serveur de l'API.
  ///
  /// Dio accepte les URL absolues : les pièces jointes sont téléchargées à
  /// l'adresse que renvoie le serveur. Si l'une d'elles désignait un autre
  /// hôte, le jeton — valable 30 jours — lui serait remis. On exige donc le
  /// même schéma, le même hôte et le même port que `API_BASE_URL`.
  bool _versLApi(Uri cible) =>
      cible.scheme == _api.scheme &&
      cible.host == _api.host &&
      cible.port == _api.port;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_versLApi(options.uri)) {
      final token = await _tokens.read();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    } else {
      // Un en-tête posé ailleurs ne doit pas non plus franchir la frontière.
      options.headers.remove('Authorization');
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final bool portaitUnJeton = err.requestOptions.headers.containsKey(
      'Authorization',
    );
    if (err.response?.statusCode == 401 && portaitUnJeton) {
      await _tokens.clear();
      _expiry.signal();
    }
    handler.next(err);
  }
}
