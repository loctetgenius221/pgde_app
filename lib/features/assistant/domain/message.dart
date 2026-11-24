import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Qui parle.
enum Locuteur { candidat, assistant }

/// Bouton proposé par le chatbot (contrat §5) : on affiche [titre], on
/// renvoie [payload] tel quel.
@immutable
class BoutonChat {
  const BoutonChat({required this.titre, required this.payload});

  factory BoutonChat.fromJson(Map<String, dynamic> json) => BoutonChat(
    titre: (json['titre'] ?? '').toString(),
    payload: (json['payload'] ?? '').toString(),
  );

  final String titre;
  final String payload;

  /// Nom de l'intention : le texte entre `/` et `{`.
  ///
  /// `/choose_platform{"platform": "PGDE"}` → `choose_platform`.
  String get intention {
    final String sansBarre = payload.startsWith('/')
        ? payload.substring(1)
        : payload;
    final int accolade = sansBarre.indexOf('{');
    return (accolade == -1 ? sansBarre : sansBarre.substring(0, accolade))
        .trim();
  }

  /// Valeur d'un paramètre de l'intention, ou `null` s'il est absent ou
  /// illisible.
  String? parametre(String cle) {
    final int accolade = payload.indexOf('{');
    if (accolade == -1) return null;
    try {
      final Object? json = jsonDecode(payload.substring(accolade));
      return json is Map ? json[cle]?.toString() : null;
    } on FormatException {
      return null;
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'titre': titre,
    'payload': payload,
  };

  @override
  bool operator ==(Object other) =>
      other is BoutonChat && other.titre == titre && other.payload == payload;

  @override
  int get hashCode => Object.hash(titre, payload);
}

/// Une bulle du fil.
@immutable
class Message {
  const Message({
    required this.locuteur,
    required this.texte,
    this.boutons = const <BoutonChat>[],
    this.imageUrl,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    locuteur: json['locuteur'] == Locuteur.candidat.name
        ? Locuteur.candidat
        : Locuteur.assistant,
    texte: (json['texte'] ?? '').toString(),
    imageUrl: json['image'] as String?,
    boutons: <BoutonChat>[
      for (final Object? b in (json['boutons'] as List?) ?? const <Object?>[])
        if (b is Map<String, dynamic>) BoutonChat.fromJson(b),
    ],
  );

  final Locuteur locuteur;

  /// Vide quand le chatbot n'envoie que des boutons ou une image.
  final String texte;
  final List<BoutonChat> boutons;

  /// Toujours une URL `https://`, le reste est écarté à la lecture.
  final String? imageUrl;

  bool get vientDeLAssistant => locuteur == Locuteur.assistant;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'locuteur': locuteur.name,
    'texte': texte,
    if (imageUrl != null) 'image': imageUrl,
    if (boutons.isNotEmpty)
      'boutons': <Map<String, dynamic>>[for (final b in boutons) b.toJson()],
  };

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
