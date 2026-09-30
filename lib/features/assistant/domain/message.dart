import 'package:flutter/foundation.dart';

/// Qui parle.
enum Locuteur { candidat, ndimbal }

/// Un tour de parole.
///
/// Classe immuable simple plutôt que `freezed` : ce modèle ne quitte jamais
/// la mémoire — pas de sérialisation, pas de brouillon, pas d'union. La
/// génération de code coûterait ici plus qu'elle ne rapporte.
@immutable
class Message {
  const Message({
    required this.locuteur,
    required this.texte,
    this.enCoursDeFrappe = false,
  });

  final Locuteur locuteur;
  final String texte;

  /// Vrai tant que la réponse s'écrit encore.
  ///
  /// Le texte est alors partiel : c'est ce qui permet d'afficher la réponse
  /// au fil de l'eau plutôt que de laisser le candidat devant un écran vide
  /// pendant que le serveur rédige.
  final bool enCoursDeFrappe;

  bool get vientDeNdimbal => locuteur == Locuteur.ndimbal;

  Message copyWith({String? texte, bool? enCoursDeFrappe}) => Message(
    locuteur: locuteur,
    texte: texte ?? this.texte,
    enCoursDeFrappe: enCoursDeFrappe ?? this.enCoursDeFrappe,
  );

  @override
  bool operator ==(Object other) =>
      other is Message &&
      other.locuteur == locuteur &&
      other.texte == texte &&
      other.enCoursDeFrappe == enCoursDeFrappe;

  @override
  int get hashCode => Object.hash(locuteur, texte, enCoursDeFrappe);
}

/// Ce que fait l'assistant à l'instant.
///
/// Trois états **logiques**, qui pilotent l'écran. Le personnage, lui, n'a
/// que deux poses : il n'a pas à porter une nuance que l'indicateur de frappe
/// exprime déjà mieux que lui.
enum EtatAssistant {
  /// Disponible.
  repos,

  /// La question est partie, la réponse se prépare.
  reflexion,

  /// La réponse s'écrit.
  parle;

  /// Vrai quand une requête est en vol : c'est ce qui verrouille l'envoi.
  bool get occupe => this != EtatAssistant.repos;
}
