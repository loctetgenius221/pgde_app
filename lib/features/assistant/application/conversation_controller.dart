import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/application/auth_controller.dart';
import '../data/assistant_api.dart';
import '../domain/message.dart';

@immutable
class Conversation {
  const Conversation({
    this.messages = const <Message>[],
    this.etat = EtatAssistant.repos,
    this.sessionId,
    this.erreur,
  });

  final List<Message> messages;
  final EtatAssistant etat;
  final String? sessionId;
  final String? erreur;

  bool get vierge => messages.isEmpty;

  Conversation copyWith({
    List<Message>? messages,
    EtatAssistant? etat,
    String? sessionId,
    String? erreur,
    bool effacerErreur = false,
  }) => Conversation(
    messages: messages ?? this.messages,
    etat: etat ?? this.etat,
    sessionId: sessionId ?? this.sessionId,
    erreur: effacerErreur ? null : (erreur ?? this.erreur),
  );
}

class ConversationController extends Notifier<Conversation> {
  @override
  Conversation build() {
    // Un changement de compte efface la conversation **et** son identifiant
    // de session serveur : le candidat suivant ne doit ni lire les échanges
    // du précédent, ni les poursuivre.
    ref.watch(utilisateurConnecteProvider.select((u) => u?.id));
    return const Conversation();
  }

  /// [texte] est affiché. [payload] part au serveur s'il est fourni (boutons).
  Future<void> envoyer(String texte, {String? payload}) async {
    final String affiche = texte.trim();
    final String aEnvoyer = (payload ?? texte).trim();
    if (affiche.isEmpty || aEnvoyer.isEmpty || state.etat.occupe) return;

    state = Conversation(
      messages: <Message>[
        ...state.messages,
        Message(locuteur: Locuteur.candidat, texte: affiche),
      ],
      etat: EtatAssistant.reflexion,
      sessionId: state.sessionId,
    );

    try {
      final TourChatbot tour = await ref
          .read(assistantApiProvider)
          .envoyer(message: aEnvoyer, sessionId: state.sessionId);
      state = state.copyWith(
        etat: EtatAssistant.repos,
        sessionId: tour.sessionId.isEmpty ? state.sessionId : tour.sessionId,
        messages: <Message>[...state.messages, ...tour.messages],
        effacerErreur: true,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        etat: EtatAssistant.repos,
        erreur: e.isChatbotUnavailable
            ? 'L’assistant est temporairement indisponible. Réessayez plus tard.'
            : e.message,
      );
    } on Object {
      state = state.copyWith(
        etat: EtatAssistant.repos,
        erreur: 'La réponse n’a pas pu être obtenue. Réessayez.',
      );
    }
  }

  void reinitialiser() {
    state = const Conversation();
  }
}

final conversationProvider =
    NotifierProvider<ConversationController, Conversation>(
      ConversationController.new,
    );
