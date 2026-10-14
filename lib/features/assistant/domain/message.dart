import 'package:flutter/foundation.dart';

/// Qui parle.
enum Locuteur { candidat, ndimbal }

/// Bouton proposé par le chatbot (§7.1) : on affiche [titre], on renvoie [payload].
@immutable
class BoutonChat {
  const BoutonChat({required this.titre, required this.payload});

  final String titre;
  final String payload;

  @override
  bool operator ==(Object other) =>
      other is BoutonChat && other.titre == titre && other.payload == payload;

  @override
  int get hashCode => Object.hash(titre, payload);
}

/// Un tour de parole.
@immutable
class Message {
  const Message({
    required this.locuteur,
    required this.texte,
    this.boutons = const <BoutonChat>[],
    this.imageUrl,
  });

  final Locuteur locuteur;
  final String texte;
  final List<BoutonChat> boutons;
  final String? imageUrl;

  bool get vientDeNdimbal => locuteur == Locuteur.ndimbal;

  Message copyWith({
    String? texte,
    List<BoutonChat>? boutons,
    String? imageUrl,
  }) => Message(
    locuteur: locuteur,
    texte: texte ?? this.texte,
    boutons: boutons ?? this.boutons,
    imageUrl: imageUrl ?? this.imageUrl,
  );

  @override
  bool operator ==(Object other) =>
      other is Message &&
      other.locuteur == locuteur &&
      other.texte == texte &&
      other.imageUrl == imageUrl &&
      listEquals(other.boutons, boutons);

  @override
  int get hashCode =>
      Object.hash(locuteur, texte, imageUrl, Object.hashAll(boutons));
}

/// Réponse d'un appel `POST /chatbot/messages`.
@immutable
class TourChatbot {
  const TourChatbot({required this.sessionId, required this.messages});

  final String sessionId;
  final List<Message> messages;
}

enum EtatAssistant {
  repos,
  reflexion;

  bool get occupe => this != EtatAssistant.repos;
}
