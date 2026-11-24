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

  /// Clé de `RequestOptions.extra` : le corps de la requête et de sa réponse
  /// ne doit jamais apparaître dans les journaux.
  static const String confidentiel = 'confidentiel';

  Future<Object?> get(String path, {Json? query}) =>
      _send(() => _dio.get<dynamic>(path, queryParameters: query));

  /// [delai] remplace le délai de réception par défaut, pour une route plus
  /// lente que les autres. [contenuConfidentiel] tient le contenu à l'écart
  /// des journaux (données personnelles).
  Future<Object?> post(
    String path, {
    Object? body,
    Duration? delai,
    bool contenuConfidentiel = false,
  }) => _send(
    () => _dio.post<dynamic>(
      path,
      data: body,
      options: Options(
        receiveTimeout: delai,
        extra: <String, dynamic>{confidentiel: contenuConfidentiel},
      ),
    ),
  );

  Future<Object?> put(String path, {Object? body}) =>
      _send(() => _dio.put<dynamic>(path, data: body));

  Future<Object?> delete(String path, {Object? body}) =>
      _send(() => _dio.delete<dynamic>(path, data: body));

  /// Télécharge [url] dans [destination], **avec** le jeton Bearer.
  ///
  /// Les CV et justificatifs sont servis par des routes protégées (contrat
  /// v2 §6.3, §6.6) : un navigateur ouvert sur l'URL nue reçoit un 401.
  /// [url] peut être absolue — Dio ignore alors `baseUrl`.
  Future<void> telecharger(String url, String destination) => _send(
    () => _dio.download(
      url,
      destination,
      options: Options(receiveTimeout: const Duration(minutes: 2)),
    ),
  ).then((_) {});

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

  if (kDebugMode) dio.interceptors.add(JournalReseau());

  return dio;
});

/// Journal HTTP de débogage, qui tait le contenu des requêtes confidentielles.
///
/// Les échanges avec le chatbot portent une CNI, un matricule, un nom : le
/// contrat interdit de les journaliser. Pour ces requêtes, seuls la méthode,
/// le chemin et le statut sont écrits.
class JournalReseau extends LogInterceptor {
  JournalReseau({void Function(Object?)? ecrire})
    : super(
        // Audit SEC-008 — les en-têtes portent le jeton Bearer : ils ne
        // doivent pas finir dans logcat, même en debug.
        requestHeader: false,
        requestBody: true,
        responseBody: true,
        logPrint: ecrire ?? (Object? o) => debugPrint(o.toString()),
      );

  static bool _masque(RequestOptions o) =>
      o.extra[ApiClient.confidentiel] == true;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_masque(options)) return super.onRequest(options, handler);
    logPrint('→ ${options.method} ${options.path} (contenu masqué)');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (!_masque(response.requestOptions)) {
      return super.onResponse(response, handler);
    }
    logPrint('← ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!_masque(err.requestOptions)) return super.onError(err, handler);
    logPrint(
      '✕ ${err.response?.statusCode ?? err.type.name} '
      '${err.requestOptions.path}',
    );
    handler.next(err);
  }
}

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(dioProvider)),
);
