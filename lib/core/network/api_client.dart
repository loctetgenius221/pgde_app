import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import '../session/session_expiry.dart';
import '../storage/token_store.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';

/// Corps JSON d'une réponse ou d'une requête.
typedef Json = Map<String, dynamic>;

/// Unique porte de sortie HTTP de l'application.
///
/// Responsabilité unique : émettre la requête et traduire tout échec en
/// [ApiException]. Rien d'autre — pas de sérialisation métier, pas de cache.
/// C'est ce qui permet aux dépôts d'ignorer complètement Dio.
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<Object?> get(String path, {Json? query}) =>
      _send(() => _dio.get<dynamic>(path, queryParameters: query));

  Future<Object?> post(String path, {Object? body}) =>
      _send(() => _dio.post<dynamic>(path, data: body));

  Future<Object?> put(String path, {Object? body}) =>
      _send(() => _dio.put<dynamic>(path, data: body));

  Future<Object?> delete(String path, {Object? body}) =>
      _send(() => _dio.delete<dynamic>(path, data: body));

  Future<Object?> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      return _contenu(response.data as Object?);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Déballe l'enveloppe standard `{success, message, data}` (contrat §2).
  ///
  /// **Toutes** les réponses la portent. La laisser traverser obligerait
  /// chaque mappeur à connaître une convention de transport qui ne le regarde
  /// pas — et à répéter `json['data']` une trentaine de fois. Elle s'arrête
  /// donc ici, comme `DioException`.
  static Object? _contenu(Object? corps) {
    if (corps is! Map) return corps;
    final Json json = corps.cast<String, dynamic>();
    // Pas de `data` sur les réponses qui n'ont rien à rendre — une
    // déconnexion, une suppression. On rend l'enveloppe plutôt que `null` :
    // son `message` reste exploitable par l'appelant.
    return json.containsKey('data') ? json['data'] : json;
  }
}

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(minutes: 2), // téléversements
      // Sans cet en-tête, Laravel répond par une redirection HTML 302 au lieu
      // d'un 401 JSON, et par du HTML au lieu d'un 422 (§8.5).
      headers: const {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      tokens: ref.watch(tokenStoreProvider),
      expiry: ref.watch(sessionExpiryProvider),
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (Object? o) => debugPrint(o.toString()),
      ),
    );
  }

  return dio;
});

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(dioProvider)),
);
