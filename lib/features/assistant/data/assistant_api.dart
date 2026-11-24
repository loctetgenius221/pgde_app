import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/message.dart';
import 'assistant_mock_api.dart';

/// Conversation avec Amath — `POST /chatbot/messages`, seule route autorisée
/// (contrat chatbot §2). Les routes `/chatbot/pgde/*` et le secret du
/// serveur du chatbot n'ont rien à faire dans l'application.
///
/// Un jeton Bearer facultatif est déjà posé par `AuthInterceptor` s'il existe.
abstract interface class AssistantApi {
  Future<TourChatbot> envoyer({required String message, String? sessionId});
}

class HttpAssistantApi implements AssistantApi {
  HttpAssistantApi(this._client);

  final ApiClient _client;

  /// Une consultation E-Carrière peut prendre 30 s : le contrat exige au
  /// moins 35 s côté client.
  static const Duration delai = Duration(seconds: 40);

  @override
  Future<TourChatbot> envoyer({
    required String message,
    String? sessionId,
  }) async {
    try {
      return await _envoyer(message, sessionId);
    } on ApiException catch (e) {
      // Contrat v2 §7.1 : un jeton expiré vaut 401. `AuthInterceptor` l'a
      // déjà effacé ; le chatbot restant public, on renvoie le message une
      // seule fois, cette fois sans jeton.
      if (!e.isUnauthorized) rethrow;
      return _envoyer(message, sessionId);
    }
  }

  Future<TourChatbot> _envoyer(String message, String? sessionId) async {
    final Object? brut = await _client.post(
      '/chatbot/messages',
      body: <String, dynamic>{
        'message': message,
        if (sessionId != null && sessionId.isNotEmpty) 'session_id': sessionId,
      },
      delai: delai,
      // CNI, matricule, nom : le contenu ne doit jamais être journalisé.
      contenuConfidentiel: true,
    );
    final Map<Object?, Object?> data = brut is Map ? brut : const {};

    return TourChatbot(
      sessionId: data['session_id']?.toString() ?? sessionId ?? '',
      messages: _messages(data['messages']),
    );
  }

  static List<Message> _messages(Object? brut) {
    if (brut is! List) return const <Message>[];
    return <Message>[
          for (final Object? item in brut)
            if (item is Map)
              Message(
                locuteur: Locuteur.assistant,
                texte: item['text']?.toString() ?? '',
                imageUrl: _imageHttps(item['image']),
                boutons: _boutons(item['buttons']),
                // `custom` est réservé : ignoré sans erreur.
              ),
        ]
        .where(
          (m) =>
              m.texte.isNotEmpty || m.boutons.isNotEmpty || m.imageUrl != null,
        )
        .toList();
  }

  static List<BoutonChat> _boutons(Object? brut) {
    if (brut is! List) return const <BoutonChat>[];
    return <BoutonChat>[
      for (final Object? item in brut)
        if (item is Map)
          BoutonChat(
            titre: (item['title'] ?? '').toString(),
            payload: (item['payload'] ?? '').toString(),
          ),
    ].where((b) => b.titre.isNotEmpty && b.payload.isNotEmpty).toList();
  }

  /// Seule une URL `https://` s'affiche ; toute autre valeur est ignorée.
  static String? _imageHttps(Object? brut) {
    final Uri? url = brut is String ? Uri.tryParse(brut) : null;
    return url != null && url.scheme == 'https' && url.hasAuthority
        ? brut as String
        : null;
  }
}

final assistantApiProvider = Provider<AssistantApi>(
  (ref) => Env.useMocks
      ? MockAssistantApi()
      : HttpAssistantApi(ref.watch(apiClientProvider)),
);
