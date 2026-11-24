import 'package:dio/dio.dart';

/// Erreurs de validation Laravel : `{"champ": ["message", ...]}` (§7.1).
typedef FieldErrors = Map<String, List<String>>;

/// Échec normalisé de l'API.
///
/// Invariant : `DioException` ne franchit jamais [ApiClient]. Au-dessus de la
/// couche réseau, tout échec — transport ou métier — est un [ApiException].
/// Les dépôts, contrôleurs et écrans ignorent donc totalement Dio.
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.code,
    this.fieldErrors = const {},
    this.retryAfter,
  });

  final String message;
  final int? statusCode;
  final String? code;
  final FieldErrors fieldErrors;

  /// Délai imposé par l'en-tête `Retry-After` d'un `429`, s'il est donné.
  final Duration? retryAfter;

  /// Aucune réponse du serveur : réseau coupé, délai dépassé.
  bool get isTransport => statusCode == null;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isValidation => statusCode == 422;

  /// Fonctionnalité retirée du serveur (contrat v2 §2 — envoi de CV).
  bool get isGone => statusCode == 410;

  bool get isEmailNotVerified => code == 'email_not_verified';
  bool get isAccessBlocked => code == 'access_blocked';

  /// Compte administrateur : l'application est réservée aux candidats (§3.3).
  bool get isAdminNotAllowed => code == 'admin_not_allowed';
  bool get isChatbotUnavailable =>
      statusCode == 503 || code == 'chatbot_unavailable';
  bool get isTooManyRequests => code == 'too_many_requests';
  bool get isTooManyCniAttempts => code == 'too_many_cni_attempts';

  /// Premier message d'erreur pour un champ, à afficher sous le champ concerné.
  String? errorFor(String field) {
    final messages = fieldErrors[field];
    return (messages == null || messages.isEmpty) ? null : messages.first;
  }

  @override
  String toString() => 'ApiException($statusCode, code: $code): $message';

  /// Traduit un échec Dio en message affichable, en français.
  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiException('Le serveur met trop de temps à répondre.');
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return const ApiException(
          'Impossible de joindre le serveur. Vérifiez votre connexion.',
        );
      case DioExceptionType.badCertificate:
        return const ApiException('Le certificat du serveur est invalide.');
      case DioExceptionType.cancel:
        return const ApiException('Requête annulée.');
      case DioExceptionType.badResponse:
        return ApiException._fromResponse(e.response!);
    }
  }

  factory ApiException._fromResponse(Response<dynamic> response) {
    final status = response.statusCode;
    final body = response.data;
    final Duration? retryAfter = _parseRetryAfter(
      response.headers.value('retry-after'),
    );

    // Un envoi groupé de fichiers qui dépasse `post_max_size` renvoie un corps
    // vide, sans message exploitable (§8.6).
    if (body is! Map) {
      return ApiException(
        _defaultMessage(status),
        statusCode: status,
        retryAfter: retryAfter,
      );
    }

    final json = body.cast<String, dynamic>();
    return ApiException(
      json['message'] as String? ?? _defaultMessage(status),
      statusCode: status,
      code: json['code'] as String?,
      fieldErrors: _parseFieldErrors(json['errors']),
      retryAfter: retryAfter,
    );
  }

  /// `Retry-After` en secondes. La forme date HTTP n'est pas utilisée par
  /// l'API : elle est ignorée plutôt que mal interprétée.
  static Duration? _parseRetryAfter(String? valeur) {
    final int? secondes = int.tryParse(valeur?.trim() ?? '');
    return secondes == null || secondes < 0
        ? null
        : Duration(seconds: secondes);
  }

  static FieldErrors _parseFieldErrors(Object? errors) {
    if (errors is! Map) return const {};
    return {
      for (final entry in errors.entries)
        entry.key.toString(): switch (entry.value) {
          final List<dynamic> list => list.map((m) => m.toString()).toList(),
          final Object value => [value.toString()],
          null => const <String>[],
        },
    };
  }

  static String _defaultMessage(int? status) => switch (status) {
    401 => 'Votre session a expiré. Veuillez vous reconnecter.',
    403 => "Vous n'avez pas accès à cette ressource.",
    404 => 'Ressource introuvable.',
    409 => 'Vous avez déjà une demande enregistrée.',
    410 => 'Cette fonctionnalité n’est plus disponible.',
    // Le plafond dépend du type de pièce (4 Mo pour la photo, 8 Mo pour les
    // documents) : le message reste général, `ReglesFichiers` donne le
    // chiffre exact avant l'envoi.
    413 => 'Fichier trop volumineux.',
    422 => 'Certaines informations sont invalides.',
    429 => 'Trop de tentatives. Réessayez dans quelques instants.',
    503 => 'Le service est temporairement indisponible. Réessayez plus tard.',
    _ => 'Une erreur est survenue. Merci de réessayer.',
  };
}
