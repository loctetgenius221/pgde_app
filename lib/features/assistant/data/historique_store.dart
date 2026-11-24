import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/key_value_store.dart';
import '../../auth/application/auth_controller.dart';
import '../domain/message.dart';

/// Conversation retrouvée sur l'appareil.
@immutable
class Historique {
  const Historique({required this.sessionId, required this.messages});

  final String? sessionId;
  final List<Message> messages;
}

/// Historique local de la conversation avec Amath (contrat chatbot §8).
///
/// **Un historique par compte**, comme le brouillon du dossier : il contient
/// une CNI, un matricule, un nom. Sans utilisateur connecté, rien n'est lu
/// ni écrit.
///
/// Le chatbot oublie le contexte après [dureeDeVie] d'inactivité. Un
/// historique plus ancien ne se poursuivrait pas : ses menus enverraient des
/// choix à un interlocuteur qui ne s'en souvient plus. Il est donc écarté, et
/// la conversation repart de la salutation.
class HistoriqueStore {
  HistoriqueStore(
    this._store,
    this._utilisateurId, {
    DateTime Function()? maintenant,
  }) : _maintenant = maintenant ?? DateTime.now;

  static const Duration dureeDeVie = Duration(minutes: 60);

  final KeyValueStore _store;
  final int? _utilisateurId;
  final DateTime Function() _maintenant;

  String? get _cle =>
      _utilisateurId == null ? null : 'chatbot_conversation_$_utilisateurId';

  Historique? lire() {
    final String? cle = _cle;
    if (cle == null) return null;
    final Map<String, dynamic>? json = _store.readJson(cle);
    if (json == null) return null;
    try {
      final DateTime maj = DateTime.parse(json['maj'] as String);
      if (_maintenant().difference(maj) > dureeDeVie) return null;
      return Historique(
        sessionId: json['session_id'] as String?,
        messages: <Message>[
          for (final Object? m in json['messages'] as List)
            Message.fromJson(m! as Map<String, dynamic>),
        ],
      );
    } on Object {
      // Format d'une version antérieure : on repart d'une conversation neuve.
      return null;
    }
  }

  Future<void> ecrire(Historique historique) async {
    final String? cle = _cle;
    if (cle == null) return;
    await _store.writeJson(cle, <String, dynamic>{
      'maj': _maintenant().toIso8601String(),
      'session_id': historique.sessionId,
      'messages': <Map<String, dynamic>>[
        for (final Message m in historique.messages) m.toJson(),
      ],
    });
  }

  Future<void> purger() async {
    final String? cle = _cle;
    if (cle == null) return;
    await _store.remove(cle);
  }
}

/// Historique de l'utilisateur **connecté**, recréé à chaque changement de
/// compte.
final historiqueStoreProvider = Provider<HistoriqueStore>(
  (ref) => HistoriqueStore(
    ref.watch(keyValueStoreProvider),
    ref.watch(utilisateurConnecteProvider.select((u) => u?.id)),
  ),
);
