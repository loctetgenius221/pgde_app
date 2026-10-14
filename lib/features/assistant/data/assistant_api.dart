import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../domain/message.dart';
import 'assistant_mock_api.dart';

/// Conversation mobile — `POST /chatbot/messages` (§7.1).
///
/// Un jeton Bearer facultatif est déjà posé par [AuthInterceptor] s'il existe.
abstract interface class AssistantApi {
  Future<TourChatbot> envoyer({required String message, String? sessionId});
}

class HttpAssistantApi implements AssistantApi {
  HttpAssistantApi(this._client);

  final ApiClient _client;

  @override
  Future<TourChatbot> envoyer({
    required String message,
    String? sessionId,
  }) async {
    final Json data =
        await _client.post(
              '/chatbot/messages',
              body: <String, dynamic>{
                'message': message,
                if (sessionId != null && sessionId.isNotEmpty)
                  'session_id': sessionId,
              },
            )
            as Json;

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
            locuteur: Locuteur.ndimbal,
            texte: (item['text'] ?? '').toString(),
            imageUrl: item['image']?.toString(),
            boutons: _boutons(item['buttons']),
          ),
    ];
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
}

final assistantApiProvider = Provider<AssistantApi>(
  (ref) => Env.useMocks
      ? MockAssistantApi()
      : HttpAssistantApi(ref.watch(apiClientProvider)),
);
