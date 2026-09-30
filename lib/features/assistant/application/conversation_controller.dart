import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/assistant_api.dart';
import '../domain/message.dart';

/// État complet de l'écran de conversation.
@immutable
class Conversation {
  const Conversation({
    this.messages = const <Message>[],
    this.etat = EtatAssistant.repos,
    this.erreur,
  });

  final List<Message> messages;
  final EtatAssistant etat;

  /// Panne de la réponse en cours. Affichée sous le fil, pas à la place :
  /// ce qui a déjà été dit reste lisible.
  final String? erreur;

  bool get vierge => messages.isEmpty;

  Conversation copyWith({
    List<Message>? messages,
    EtatAssistant? etat,
    String? erreur,
    bool effacerErreur = false,
  }) => Conversation(
    messages: messages ?? this.messages,
    etat: etat ?? this.etat,
    erreur: effacerErreur ? null : (erreur ?? this.erreur),
  );
}

/// Conduit l'échange avec l'assistant.
///
/// L'état d'animation de l'avatar est dérivé d'ici, et de nulle part
/// ailleurs : c'est ce qui garantit qu'il ne « réfléchit » jamais alors que
/// la réponse est déjà écrite.
class ConversationController extends Notifier<Conversation> {
  StreamSubscription<String>? _flux;

  @override
  Conversation build() {
    ref.onDispose(() => _flux?.cancel());
    return const Conversation();
  }

  Future<void> envoyer(String texte) async {
    final String question = texte.trim();
    // On refuse aussi pendant qu'une réponse s'écrit : deux flux concurrents
    // entrelaceraient leurs mots dans la même bulle.
    if (question.isEmpty || state.etat.occupe) return;

    final List<Message> historique = <Message>[
      ...state.messages,
      Message(locuteur: Locuteur.candidat, texte: question),
    ];
    state = Conversation(
      messages: historique,
      etat: EtatAssistant.reflexion,
    );

    final StringBuffer accumule = StringBuffer();
    // La bulle de réponse est créée **vide** au premier fragment seulement :
    // avant cela, c'est l'indicateur de frappe qui occupe la place.
    bool bulleOuverte = false;

    await _flux?.cancel();
    _flux =
        ref
            .read(assistantApiProvider)
            .repondre(question: question, historique: historique)
            .listen(
              (fragment) {
                accumule.write(fragment);
                final Message reponse = Message(
                  locuteur: Locuteur.ndimbal,
                  texte: accumule.toString().trimRight(),
                  enCoursDeFrappe: true,
                );
                state = state.copyWith(
                  etat: EtatAssistant.parle,
                  messages: <Message>[
                    ...bulleOuverte
                        ? state.messages.sublist(0, state.messages.length - 1)
                        : state.messages,
                    reponse,
                  ],
                );
                bulleOuverte = true;
              },
              onError: (Object _) {
                state = state.copyWith(
                  etat: EtatAssistant.repos,
                  erreur: 'La réponse n’a pas pu être obtenue. Réessayez.',
                );
              },
              onDone: _clore,
              cancelOnError: true,
            );
  }

  /// Referme la dernière bulle : le curseur de frappe disparaît, l'avatar
  /// revient au repos.
  void _clore() {
    final List<Message> messages = state.messages;
    if (messages.isEmpty) {
      state = state.copyWith(etat: EtatAssistant.repos);
      return;
    }
    state = state.copyWith(
      etat: EtatAssistant.repos,
      messages: <Message>[
        ...messages.sublist(0, messages.length - 1),
        messages.last.copyWith(enCoursDeFrappe: false),
      ],
    );
  }

  /// Vide l'échange — « Nouvelle conversation ».
  void reinitialiser() {
    _flux?.cancel();
    state = const Conversation();
  }
}

final conversationProvider =
    NotifierProvider<ConversationController, Conversation>(
      ConversationController.new,
    );
