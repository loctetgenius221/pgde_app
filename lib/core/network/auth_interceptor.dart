import 'package:dio/dio.dart';

import '../session/session_expiry.dart';
import '../storage/token_store.dart';

/// Porte le jeton Bearer sur chaque requête et détecte l'expiration de session.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required TokenStore tokens, required SessionExpiry expiry})
    : _tokens = tokens,
      _expiry = expiry;

  final TokenStore _tokens;
  final SessionExpiry _expiry;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokens.read();
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      await _tokens.clear();
      _expiry.signal();
    }
    handler.next(err);
  }
}
