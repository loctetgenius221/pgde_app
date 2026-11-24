import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:pgde_app/core/storage/coffre_local.dart';
import 'package:pgde_app/core/storage/key_value_store.dart';
import 'package:pgde_app/features/assistant/data/assistant_api.dart';
import 'package:pgde_app/features/assistant/domain/message.dart';
import 'package:pgde_app/features/auth/application/auth_controller.dart';
import 'package:pgde_app/features/auth/domain/utilisateur.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Outils partagés par les tests d'Amath.

Utilisateur candidat(int id, String prenom) => Utilisateur(
  id: id,
  firstname: prenom,
  lastname: 'Test',
  username: prenom.toLowerCase(),
  numberid: '$id',
  email: '${prenom.toLowerCase()}@exemple.sn',
  enabled: true,
);

final Utilisateur awa = candidat(1, 'Awa');
final Utilisateur bassirou = candidat(2, 'Bassirou');

/// Compte connecté, piloté par le test.
class Compte extends Notifier<Utilisateur?> {
  @override
  Utilisateur? build() => awa;

  void connecter(Utilisateur? u) => state = u;
}

final compteProvider = NotifierProvider<Compte, Utilisateur?>(Compte.new);

Message amath(String texte, [List<BoutonChat> boutons = const []]) =>
    Message(locuteur: Locuteur.assistant, texte: texte, boutons: boutons);

TourChatbot tour(List<Message> messages, {String session = 'session-1'}) =>
    TourChatbot(sessionId: session, messages: messages);

const BoutonChat eCarriere = BoutonChat(
  titre: 'E-Carrière',
  payload: '/choose_platform{"platform": "E-Carrière"}',
);
const BoutonChat pgde = BoutonChat(
  titre: 'Demande d’emploi (PGDE)',
  payload: '/choose_platform{"platform": "PGDE"}',
);
const BoutonChat oui = BoutonChat(
  titre: 'Oui',
  payload: '/confirm_has_account',
);
const BoutonChat non = BoutonChat(titre: 'Non', payload: '/deny_has_account');

/// Un appel reçu par le faux serveur.
typedef Appel = ({String message, String? sessionId});

/// Amath scripté : chaque appel consomme la réponse suivante de la file.
///
/// Une réponse est un [TourChatbot], une exception à lever, ou un
/// [Completer] que le test résout quand il le veut (réponse lente).
class FauxAmath implements AssistantApi {
  FauxAmath([Iterable<Object> reponses = const <Object>[]])
    : _file = <Object>[...reponses];

  final List<Object> _file;
  final List<Appel> appels = <Appel>[];

  void puis(Object reponse) => _file.add(reponse);

  List<String> get messages => [for (final a in appels) a.message];

  @override
  Future<TourChatbot> envoyer({
    required String message,
    String? sessionId,
  }) async {
    appels.add((message: message, sessionId: sessionId));
    if (_file.isEmpty) throw StateError('Réponse non prévue pour « $message »');
    return switch (_file.removeAt(0)) {
      final TourChatbot t => t,
      final Completer<TourChatbot> c => c.future,
      final Object erreur => throw erreur,
    };
  }
}

/// Préférences vierges (ou pré-remplies) pour un test.
Future<SharedPreferences> preferences([
  Map<String, Object> contenu = const <String, Object>{},
]) async {
  SharedPreferences.setMockInitialValues(contenu);
  return SharedPreferences.getInstance();
}

/// Clé de chiffrement de l'appareil simulé. Partagée entre les « lancements »
/// d'un même test, comme le Keystore survit à la fermeture de l'app.
final CoffreLocal coffreDuTelephone = CoffreLocal.enMemoire();

/// Contenu déchiffré d'une entrée du stockage local.
Map<String, dynamic>? lireStocke(SharedPreferences prefs, String cle) =>
    StockageChiffre(KeyValueStore(prefs), coffreDuTelephone).readJson(cle);

/// Les surcharges communes : stockage, compte connecté, faux serveur.
List<Override> surcharges(SharedPreferences prefs, FauxAmath serveur) => [
  sharedPreferencesProvider.overrideWithValue(prefs),
  coffreLocalProvider.overrideWithValue(coffreDuTelephone),
  utilisateurConnecteProvider.overrideWith((ref) => ref.watch(compteProvider)),
  assistantApiProvider.overrideWithValue(serveur),
];
