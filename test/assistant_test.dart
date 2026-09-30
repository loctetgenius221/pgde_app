import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pgde_app/features/assistant/application/conversation_controller.dart';
import 'package:pgde_app/features/assistant/data/assistant_api.dart';
import 'package:pgde_app/features/assistant/data/assistant_mock_api.dart';
import 'package:pgde_app/features/assistant/domain/message.dart';

/// Assistant pilotable : il rend les fragments qu'on lui donne, sans latence.
class _FauxAssistant implements AssistantApi {
  _FauxAssistant(this.fragments, {this.echoue = false});

  final List<String> fragments;
  final bool echoue;

  int appels = 0;
  List<Message> dernierHistorique = const <Message>[];

  @override
  Stream<String> repondre({
    required String question,
    required List<Message> historique,
  }) async* {
    appels++;
    dernierHistorique = historique;
    if (echoue) throw StateError('serveur injoignable');
    for (final String f in fragments) {
      yield f;
    }
  }
}

ProviderContainer _avec(_FauxAssistant faux) {
  final ProviderContainer conteneur = ProviderContainer(
    overrides: [assistantApiProvider.overrideWithValue(faux)],
  );
  addTearDown(conteneur.dispose);
  return conteneur;
}

void main() {
  group('Conversation', () {
    test('les fragments s’accumulent dans une seule bulle', () async {
      final faux = _FauxAssistant(<String>['Bonjour ', 'à ', 'vous']);
      final ProviderContainer c = _avec(faux);

      await c.read(conversationProvider.notifier).envoyer('salut');
      await pumpEventQueue();

      final Conversation etat = c.read(conversationProvider);
      // Une question, une réponse — pas une bulle par fragment.
      expect(etat.messages, hasLength(2));
      expect(etat.messages.first.locuteur, Locuteur.candidat);
      expect(etat.messages.last.texte, 'Bonjour à vous');
    });

    test('la bulle se referme et l’assistant revient au repos', () async {
      final faux = _FauxAssistant(<String>['Oui.']);
      final ProviderContainer c = _avec(faux);

      await c.read(conversationProvider.notifier).envoyer('question');
      await pumpEventQueue();

      final Conversation etat = c.read(conversationProvider);
      // Le curseur de frappe doit disparaître : sinon l'écran laisse croire
      // que la réponse continue de s'écrire.
      expect(etat.messages.last.enCoursDeFrappe, isFalse);
      expect(etat.etat, EtatAssistant.repos);
    });

    test('une question vide ne part pas', () async {
      final faux = _FauxAssistant(<String>['x']);
      final ProviderContainer c = _avec(faux);

      await c.read(conversationProvider.notifier).envoyer('   ');
      await pumpEventQueue();

      expect(faux.appels, 0);
      expect(c.read(conversationProvider).vierge, isTrue);
    });

    test('l’historique accompagne la question', () async {
      final faux = _FauxAssistant(<String>['ok']);
      final ProviderContainer c = _avec(faux);

      await c.read(conversationProvider.notifier).envoyer('première');
      await pumpEventQueue();
      await c.read(conversationProvider.notifier).envoyer('seconde');
      await pumpEventQueue();

      // Le second appel voit les trois tours précédents, sa propre question
      // comprise : sans quoi l'assistant repartirait de zéro à chaque phrase.
      expect(faux.dernierHistorique, hasLength(3));
      expect(faux.dernierHistorique.last.texte, 'seconde');
    });

    test('une panne laisse le fil lisible et le signale', () async {
      final faux = _FauxAssistant(<String>[], echoue: true);
      final ProviderContainer c = _avec(faux);

      await c.read(conversationProvider.notifier).envoyer('bonjour');
      await pumpEventQueue();

      final Conversation etat = c.read(conversationProvider);
      // La question reste affichée : l'échec ne doit pas effacer ce que le
      // candidat vient d'écrire.
      expect(etat.messages, hasLength(1));
      expect(etat.messages.single.texte, 'bonjour');
      expect(etat.erreur, isNotNull);
      expect(etat.etat, EtatAssistant.repos);
    });

    test('réinitialiser vide le fil', () async {
      final faux = _FauxAssistant(<String>['ok']);
      final ProviderContainer c = _avec(faux);

      await c.read(conversationProvider.notifier).envoyer('bonjour');
      await pumpEventQueue();
      c.read(conversationProvider.notifier).reinitialiser();

      expect(c.read(conversationProvider).vierge, isTrue);
    });
  });

  group('Faux assistant', () {
    test('la réponse arrive en plusieurs morceaux, jamais d’un bloc', () async {
      // C'est ce que l'écran doit savoir encaisser : un mock qui répondrait
      // d'un seul coup masquerait le cas réel.
      final List<String> morceaux = await MockAssistantApi()
          .repondre(question: 'bonjour', historique: const <Message>[])
          .toList();

      expect(morceaux.length, greaterThan(3));
      expect(morceaux.join().trim(), startsWith('Bonjour'));
    });

    test('les accents ne changent pas la réponse', () async {
      Future<String> demander(String q) async => (await MockAssistantApi()
              .repondre(question: q, historique: const <Message>[])
              .toList())
          .join()
          .trim();

      // « delai » sans accent doit tomber sur la même réponse que « délai ».
      expect(await demander('quel délai ?'), await demander('quel delai ?'));
    });

    test('hors sujet, il dit ce qu’il sait faire plutôt que d’inventer', () async {
      final String reponse = (await MockAssistantApi()
              .repondre(
                question: 'quelle est la capitale du Brésil',
                historique: const <Message>[],
              )
              .toList())
          .join();

      expect(reponse, contains('pièces'));
      expect(reponse, isNot(contains('Brasilia')));
    });

    test('les mots-clés du dossier tombent sur la bonne réponse', () async {
      Future<String> demander(String q) async => (await MockAssistantApi()
              .repondre(question: q, historique: const <Message>[])
              .toList())
          .join();

      expect(await demander('quelles pièces fournir ?'), contains('4 Mo'));
      expect(await demander('mes voeux'), contains('deux métiers'));
      expect(await demander('je suis en situation de handicap'), contains('étape 1'));
    });
  });
}
