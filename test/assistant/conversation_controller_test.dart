import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pgde_app/core/network/api_exception.dart';
import 'package:pgde_app/features/assistant/application/conversation_controller.dart';
import 'package:pgde_app/features/assistant/data/historique_store.dart';
import 'package:pgde_app/features/assistant/domain/message.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'outils_assistant.dart';

const ApiException _indisponible = ApiException(
  'Le chatbot est indisponible.',
  statusCode: 503,
  code: 'chatbot_unavailable',
);
const ApiException _reseau = ApiException('Impossible de joindre le serveur.');

final Message _salutation = amath(
  'Dalal ak Jàmm !\nJe suis **Amath**. Votre nom ?',
);
final Message _menu = amath('Que souhaitez-vous faire ?', const [
  eCarriere,
  pgde,
]);
final Message _compte = amath('Avez-vous un compte ?', const [oui, non]);
final Message _demandeCni = amath(
  'Veuillez renseigner votre numéro de carte nationale d’identité (**CNI**).',
);

class _Banc {
  _Banc(this.c, this.serveur, this.prefs);

  final ProviderContainer c;
  final FauxAmath serveur;
  final SharedPreferences prefs;

  ConversationController get amath => c.read(conversationProvider.notifier);
  Conversation get etat => c.read(conversationProvider);
  List<String> get textes => [for (final m in etat.messages) m.texte];
}

Future<_Banc> _banc([
  Iterable<Object> reponses = const <Object>[],
  Map<String, Object> stockage = const <String, Object>{},
]) async {
  final SharedPreferences prefs = await preferences(stockage);
  final FauxAmath serveur = FauxAmath(reponses);
  final ProviderContainer c = ProviderContainer(
    overrides: surcharges(prefs, serveur),
  );
  addTearDown(c.dispose);
  // Garde le fournisseur en vie entre deux lectures, comme l'écran.
  c.listen(conversationProvider, (_, _) {});
  return _Banc(c, serveur, prefs);
}

/// Conduit la conversation jusqu'au menu principal.
Future<_Banc> _auMenu([Iterable<Object> suite = const <Object>[]]) async {
  final _Banc b = await _banc(<Object>[
    tour(<Message>[_salutation]),
    tour(<Message>[_menu]),
    ...suite,
  ]);
  await b.amath.ouvrir();
  await b.amath.envoyer('Awa');
  return b;
}

void main() {
  group('Ouverture (§3.1)', () {
    test(
      'envoie /greet sans session et n’affiche aucune bulle du candidat',
      () async {
        final _Banc b = await _banc(<Object>[
          tour(<Message>[_salutation]),
        ]);
        await b.amath.ouvrir();

        expect(b.serveur.appels.single, (message: '/greet', sessionId: null));
        expect(b.etat.messages, <Message>[_salutation]);
        expect(b.etat.messages.any((m) => !m.vientDeLAssistant), isFalse);
        expect(b.etat.sessionId, 'session-1');
        expect(b.etat.etat, EtatAssistant.repos);
      },
    );

    test('ne resalue pas une conversation déjà commencée', () async {
      final _Banc b = await _auMenu();
      await b.amath.ouvrir();
      expect(b.serveur.messages, <String>['/greet', 'Awa']);
    });

    test('deux ouvertures rapprochées ne saluent qu’une fois', () async {
      final Completer<TourChatbot> lente = Completer<TourChatbot>();
      final _Banc b = await _banc(<Object>[lente]);
      final Future<void> premiere = b.amath.ouvrir();
      await b.amath.ouvrir();
      lente.complete(tour(<Message>[_salutation]));
      await premiere;
      expect(b.serveur.messages, <String>['/greet']);
    });
  });

  group('Saisie libre (§3.2)', () {
    test('bulle du candidat, puis envoi avec la session reçue', () async {
      final _Banc b = await _auMenu();
      expect(b.serveur.appels.last, (message: 'Awa', sessionId: 'session-1'));
      expect(b.textes, <String>[_salutation.texte, 'Awa', _menu.texte]);
      expect(b.etat.messages[1].locuteur, Locuteur.candidat);
    });

    test('le texte est rogné, et une saisie vide ne part pas', () async {
      final _Banc b = await _banc(<Object>[
        tour(<Message>[_salutation]),
        tour(<Message>[_menu]),
      ]);
      await b.amath.ouvrir();
      await b.amath.envoyer('   ');
      await b.amath.envoyer('');
      expect(b.serveur.messages, <String>['/greet']);
      await b.amath.envoyer('  Awa \n');
      expect(b.serveur.messages.last, 'Awa');
      expect(b.etat.messages[1].texte, 'Awa');
    });

    test(
      '1 000 caractères passent, 1 001 non — sans appel au serveur',
      () async {
        final _Banc b = await _banc(<Object>[
          tour(<Message>[_salutation]),
          tour(<Message>[_demandeCni]),
        ]);
        await b.amath.ouvrir();

        await b.amath.envoyer('a' * 1001);
        expect(b.serveur.messages, <String>['/greet']);
        expect(b.etat.messages, hasLength(1), reason: 'aucune bulle ajoutée');
        expect(b.etat.erreur?.aRenvoyer, isNull, reason: 'rien à renvoyer');

        await b.amath.envoyer('a' * 1000);
        expect(b.serveur.messages.last, hasLength(1000));
        expect(b.etat.erreur, isNull);
      },
    );

    test('plusieurs bulles dans une réponse, dans l’ordre', () async {
      final _Banc b = await _banc(<Object>[
        tour(<Message>[amath('Un'), amath('Deux'), amath('Trois')]),
      ]);
      await b.amath.ouvrir();
      expect(b.textes, <String>['Un', 'Deux', 'Trois']);
    });

    test('une réponse sans bulle n’ajoute rien et rend la main', () async {
      final _Banc b = await _banc(<Object>[
        tour(<Message>[_salutation]),
        tour(const <Message>[]),
      ]);
      await b.amath.ouvrir();
      await b.amath.envoyer('Awa');
      expect(b.textes, <String>[_salutation.texte, 'Awa']);
      expect(b.etat.saisieBloquee, isFalse);
    });

    test(
      'une session vide en réponse ne remplace pas la session connue',
      () async {
        final _Banc b = await _banc(<Object>[
          tour(<Message>[_salutation]),
          tour(<Message>[_menu], session: ''),
        ]);
        await b.amath.ouvrir();
        await b.amath.envoyer('Awa');
        expect(b.etat.sessionId, 'session-1');
      },
    );

    test('pendant un envoi : saisie fermée, second envoi ignoré', () async {
      final Completer<TourChatbot> lente = Completer<TourChatbot>();
      final _Banc b = await _banc(<Object>[
        tour(<Message>[_salutation]),
        lente,
      ]);
      await b.amath.ouvrir();

      final Future<void> envoi = b.amath.envoyer('Awa');
      expect(b.etat.etat, EtatAssistant.reflexion);
      expect(b.etat.saisieBloquee, isTrue);
      await b.amath.envoyer('Deuxième');
      expect(b.serveur.messages, <String>['/greet', 'Awa']);

      lente.complete(tour(<Message>[_menu]));
      await envoi;
      expect(b.etat.etat, EtatAssistant.repos);
    });
  });

  group('Boutons (§5)', () {
    test('le titre s’affiche, le payload part tel quel', () async {
      final _Banc b = await _auMenu(<Object>[
        tour(<Message>[_compte]),
      ]);
      await b.amath.choisir(eCarriere);

      expect(b.serveur.appels.last, (
        message: '/choose_platform{"platform": "E-Carrière"}',
        sessionId: 'session-1',
      ));
      expect(
        b.etat.messages[3],
        const Message(locuteur: Locuteur.candidat, texte: 'E-Carrière'),
      );
      expect(b.textes, isNot(contains(eCarriere.payload)));
    });

    test(
      'un menu ferme la saisie libre ; un message sans bouton la rouvre',
      () async {
        final _Banc b = await _auMenu(<Object>[
          tour(<Message>[_compte]),
          tour(<Message>[_demandeCni]),
        ]);
        expect(b.etat.saisieBloquee, isTrue);

        await b.amath.envoyer('texte pendant un menu');
        expect(b.serveur.messages, hasLength(2), reason: 'saisie ignorée');

        await b.amath.choisir(eCarriere);
        expect(b.etat.saisieBloquee, isTrue);
        await b.amath.choisir(oui);
        expect(b.etat.saisieBloquee, isFalse);
      },
    );

    test('seuls les boutons du dernier message répondent', () async {
      final _Banc b = await _auMenu(<Object>[
        tour(<Message>[_compte]),
      ]);
      final int indexMenu = b.etat.messages.indexOf(_menu);
      expect(b.etat.boutonsActifs(indexMenu), isTrue);

      await b.amath.choisir(eCarriere);
      expect(b.etat.boutonsActifs(indexMenu), isFalse);
      expect(b.etat.boutonsActifs(b.etat.messages.length - 1), isTrue);

      // Un vieux menu ne relance pas une étape passée.
      await b.amath.choisir(pgde);
      expect(b.serveur.messages, hasLength(3));
      expect(b.etat.messages.last, _compte);
    });

    test('un bouton étranger au dernier message est ignoré', () async {
      final _Banc b = await _auMenu();
      await b.amath.choisir(
        const BoutonChat(titre: 'Pirate', payload: '/ask_support'),
      );
      expect(b.serveur.messages, hasLength(2));
    });

    test('aucun bouton ne répond pendant un envoi', () async {
      final Completer<TourChatbot> lente = Completer<TourChatbot>();
      final _Banc b = await _auMenu(<Object>[lente]);
      final Future<void> premier = b.amath.choisir(eCarriere);
      expect(b.etat.boutonsActifs(b.etat.messages.length - 1), isFalse);
      await b.amath.choisir(pgde);
      lente.complete(tour(<Message>[_compte]));
      await premier;
      expect(b.serveur.messages, hasLength(3));
    });

    test('choisir sur une conversation vide ne lève pas d’erreur', () async {
      final _Banc b = await _banc();
      await b.amath.choisir(oui);
      expect(b.serveur.appels, isEmpty);
    });
  });

  group('Clavier (§6)', () {
    test('clavier numérique quand Amath demande une CNI', () async {
      final _Banc b = await _auMenu(<Object>[
        tour(<Message>[_compte]),
        tour(<Message>[_demandeCni]),
        tour(<Message>[amath('Votre **matricule solde**, en MAJUSCULES.')]),
      ]);
      expect(b.etat.attendUneCni, isFalse);
      await b.amath.choisir(eCarriere);
      await b.amath.choisir(oui);
      expect(b.etat.attendUneCni, isTrue);
      await b.amath.envoyer('1234567890123');
      expect(
        b.etat.attendUneCni,
        isFalse,
        reason: 'le matricule contient une lettre',
      );
    });

    test('« CNI » doit être un mot : « CNIL » ne compte pas', () async {
      final _Banc b = await _banc(<Object>[
        tour(<Message>[amath('Voir la CNIL.')]),
      ]);
      await b.amath.ouvrir();
      expect(b.etat.attendUneCni, isFalse);
    });
  });

  group('Erreurs (§7)', () {
    test('503 : bulle « indisponible », la bulle du candidat reste', () async {
      final _Banc b = await _banc(<Object>[
        tour(<Message>[_salutation]),
        _indisponible,
      ]);
      await b.amath.ouvrir();
      await b.amath.envoyer('Awa');

      expect(
        b.etat.erreur,
        const ErreurChat(ConversationController.indisponible, aRenvoyer: 'Awa'),
      );
      expect(b.textes.last, 'Awa');
      expect(b.etat.etat, EtatAssistant.repos);
    });

    test('Réessayer renvoie le même message, sans doubler la bulle', () async {
      final _Banc b = await _banc(<Object>[
        tour(<Message>[_salutation]),
        _indisponible,
        tour(<Message>[_menu]),
      ]);
      await b.amath.ouvrir();
      await b.amath.envoyer('Awa');
      await b.amath.reessayer();

      expect(b.serveur.messages, <String>['/greet', 'Awa', 'Awa']);
      expect(b.textes.where((t) => t == 'Awa'), hasLength(1));
      expect(b.etat.erreur, isNull);
      expect(b.etat.messages.last, _menu);
    });

    test(
      'Réessayer après un bouton renvoie le payload, pas le titre',
      () async {
        final _Banc b = await _auMenu(<Object>[
          _indisponible,
          tour(<Message>[_compte]),
        ]);
        await b.amath.choisir(eCarriere);
        expect(b.etat.erreur?.aRenvoyer, eCarriere.payload);
        await b.amath.reessayer();
        expect(b.serveur.messages.last, eCarriere.payload);
        expect(b.etat.messages.last, _compte);
      },
    );

    test(
      'réseau coupé ou erreur inattendue : même traitement que 503',
      () async {
        for (final Object panne in <Object>[
          _reseau,
          StateError('boum'),
          const FormatException(),
        ]) {
          final _Banc b = await _banc(<Object>[panne]);
          await b.amath.ouvrir();
          expect(
            b.etat.erreur?.texte,
            ConversationController.indisponible,
            reason: '$panne',
          );
          expect(b.etat.erreur?.aRenvoyer, '/greet');
        }
      },
    );

    test(
      'l’échec de la salutation se rattrape sans bulle du candidat',
      () async {
        final _Banc b = await _banc(<Object>[
          _reseau,
          tour(<Message>[_salutation]),
        ]);
        await b.amath.ouvrir();
        expect(b.etat.vierge, isTrue);
        await b.amath.reessayer();
        expect(b.etat.messages, <Message>[_salutation]);
        expect(b.serveur.messages, <String>['/greet', '/greet']);
      },
    );

    test(
      '429 too_many_cni_attempts : message du serveur, rien à renvoyer',
      () async {
        const ApiException cni = ApiException(
          'Trop de numéros de CNI envoyés. Réessayez dans 10 minutes.',
          statusCode: 429,
          code: 'too_many_cni_attempts',
          retryAfter: Duration(minutes: 10),
        );
        final _Banc b = await _banc(<Object>[
          tour(<Message>[_demandeCni]),
          cni,
        ]);
        await b.amath.ouvrir();
        await b.amath.envoyer('1234567890123');

        expect(b.etat.erreur, ErreurChat(cni.message));
        await b.amath.reessayer();
        expect(b.serveur.messages, hasLength(2));
      },
    );

    test('422 : erreur de l’application, jamais renvoyée', () async {
      const ApiException invalide = ApiException('Invalide', statusCode: 422);
      final _Banc b = await _banc(<Object>[
        tour(<Message>[_salutation]),
        invalide,
      ]);
      await b.amath.ouvrir();
      await b.amath.envoyer('Awa');

      expect(b.etat.erreur?.aRenvoyer, isNull);
      await b.amath.reessayer();
      expect(b.serveur.messages, hasLength(2));
    });

    testWidgets('429 too_many_requests : Réessayer attend le Retry-After', (
      tester,
    ) async {
      const ApiException trop = ApiException(
        'Trop de requêtes.',
        statusCode: 429,
        code: 'too_many_requests',
        retryAfter: Duration(seconds: 3),
      );
      final _Banc b = await _banc(<Object>[
        tour(<Message>[_salutation]),
        trop,
        tour(<Message>[_menu]),
      ]);
      await b.amath.ouvrir();
      await b.amath.envoyer('Awa');

      expect(
        b.etat.erreur,
        const ErreurChat(
          ConversationController.tropDeMessages,
          aRenvoyer: 'Awa',
          enAttente: true,
        ),
      );
      await b.amath.reessayer();
      expect(b.serveur.messages, hasLength(2), reason: 'trop tôt');

      await tester.pump(const Duration(milliseconds: 2900));
      expect(b.etat.erreur?.enAttente, isTrue);
      await tester.pump(const Duration(milliseconds: 200));
      expect(b.etat.erreur?.enAttente, isFalse);

      await b.amath.reessayer();
      expect(b.serveur.messages, <String>['/greet', 'Awa', 'Awa']);
      expect(b.etat.erreur, isNull);
    });

    testWidgets('429 sans Retry-After : attente de 5 s par défaut', (
      tester,
    ) async {
      const ApiException trop = ApiException('x', statusCode: 429);
      final _Banc b = await _banc(<Object>[trop]);
      await b.amath.ouvrir();
      await tester.pump(const Duration(milliseconds: 4900));
      expect(b.etat.erreur?.enAttente, isTrue);
      await tester.pump(const Duration(milliseconds: 200));
      expect(b.etat.erreur?.enAttente, isFalse);
    });

    test('un nouvel envoi réussi efface l’erreur', () async {
      final _Banc b = await _banc(<Object>[
        tour(<Message>[_demandeCni]),
        _indisponible,
        tour(<Message>[amath('Matricule ?')]),
      ]);
      await b.amath.ouvrir();
      await b.amath.envoyer('1234567890123');
      expect(b.etat.erreur, isNotNull);
      await b.amath.envoyer('1234567890124');
      expect(b.etat.erreur, isNull);
    });
  });

  group('Nouvelle conversation ↻ (§3.4)', () {
    test(
      'efface fil, session et historique, puis resalue sans session',
      () async {
        final _Banc b = await _auMenu(<Object>[
          tour(<Message>[_salutation], session: 'session-2'),
        ]);
        await b.amath.nouvelleConversation();

        expect(b.serveur.appels.last, (message: '/greet', sessionId: null));
        expect(b.etat.messages, <Message>[_salutation]);
        expect(b.etat.sessionId, 'session-2');
        final Map<String, dynamic> stocke =
            jsonDecode(b.prefs.getString('chatbot_conversation_1')!)
                as Map<String, dynamic>;
        expect(stocke['messages'], hasLength(1));
      },
    );

    test(
      'possible pendant un envoi : la réponse tardive est ignorée',
      () async {
        final Completer<TourChatbot> lente = Completer<TourChatbot>();
        final _Banc b = await _auMenu(<Object>[
          lente,
          tour(<Message>[_salutation], session: 'neuve'),
        ]);
        final Future<void> ancien = b.amath.choisir(eCarriere);

        await b.amath.nouvelleConversation();
        lente.complete(tour(<Message>[_compte], session: 'ancienne'));
        await ancien;

        expect(b.etat.messages, <Message>[_salutation]);
        expect(b.etat.sessionId, 'neuve');
      },
    );

    test('efface aussi une erreur en cours', () async {
      final _Banc b = await _banc(<Object>[
        _indisponible,
        tour(<Message>[_salutation]),
      ]);
      await b.amath.ouvrir();
      expect(b.etat.erreur, isNotNull);
      await b.amath.nouvelleConversation();
      expect(b.etat.erreur, isNull);
    });
  });

  group('Historique local (§8)', () {
    test(
      'la conversation est retrouvée à la réouverture de l’application',
      () async {
        final _Banc b = await _auMenu();
        final Map<String, Object> disque = <String, Object>{
          for (final String k in b.prefs.getKeys()) k: b.prefs.get(k)!,
        };

        // Nouveau lancement : même disque, nouveaux fournisseurs.
        final _Banc relance = await _banc(<Object>[
          tour(<Message>[_compte]),
        ], disque);
        expect(relance.etat.messages, b.etat.messages);
        expect(relance.etat.sessionId, 'session-1');

        await relance.amath.ouvrir();
        expect(
          relance.serveur.appels,
          isEmpty,
          reason: 'pas de nouvelle salutation',
        );
        await relance.amath.choisir(eCarriere);
        expect(relance.serveur.appels.single.sessionId, 'session-1');
      },
    );

    test('les boutons sont conservés avec leur payload', () async {
      final _Banc b = await _auMenu();
      final Map<String, dynamic> json =
          jsonDecode(b.prefs.getString('chatbot_conversation_1')!)
              as Map<String, dynamic>;
      final Message dernier = Message.fromJson(
        (json['messages'] as List).last as Map<String, dynamic>,
      );
      expect(dernier.boutons, const <BoutonChat>[eCarriere, pgde]);
    });

    test('l’erreur affichée n’est pas conservée', () async {
      final _Banc b = await _banc(<Object>[
        tour(<Message>[_salutation]),
        _indisponible,
      ]);
      await b.amath.ouvrir();
      await b.amath.envoyer('Awa');
      final _Banc relance = await _banc(const <Object>[], <String, Object>{
        'chatbot_conversation_1': b.prefs.getString('chatbot_conversation_1')!,
      });
      expect(relance.etat.erreur, isNull);
      expect(relance.etat.messages.last.texte, 'Awa');
    });

    test(
      'au-delà de 60 min d’inactivité, la conversation repart de zéro',
      () async {
        final String perime = jsonEncode(<String, dynamic>{
          'maj': DateTime.now()
              .subtract(const Duration(minutes: 61))
              .toIso8601String(),
          'session_id': 'vieille',
          'messages': <Map<String, dynamic>>[_menu.toJson()],
        });
        final _Banc b = await _banc(
          <Object>[
            tour(<Message>[_salutation], session: 'neuve'),
          ],
          <String, Object>{'chatbot_conversation_1': perime},
        );
        expect(b.etat.vierge, isTrue);
        await b.amath.ouvrir();
        expect(b.serveur.appels.single, (message: '/greet', sessionId: null));
      },
    );

    test('un historique illisible est ignoré sans planter', () async {
      for (final String corrompu in <String>[
        '{"maj": "pas une date", "messages": []}',
        '{"messages": []}',
        '{"maj": "2026-10-29T10:00:00", "messages": "texte"}',
        'pas du json',
      ]) {
        final _Banc b = await _banc(const <Object>[], <String, Object>{
          'chatbot_conversation_1': corrompu,
        });
        expect(b.etat.vierge, isTrue, reason: corrompu);
      }
    });
  });

  group('Appareil partagé', () {
    test(
      'B ne retrouve pas la conversation de A, qui la retrouve ensuite',
      () async {
        final _Banc b = await _auMenu();
        expect(b.etat.vierge, isFalse);

        b.c.read(compteProvider.notifier).connecter(bassirou);
        expect(b.etat.vierge, isTrue);
        expect(
          b.etat.sessionId,
          isNull,
          reason: 'B ne poursuit pas la session de A',
        );

        b.c.read(compteProvider.notifier).connecter(awa);
        expect(b.etat.messages.last, _menu);
      },
    );

    test('une réponse destinée à A n’arrive pas chez B', () async {
      final Completer<TourChatbot> lente = Completer<TourChatbot>();
      final _Banc b = await _banc(<Object>[
        tour(<Message>[_demandeCni]),
        lente,
      ]);
      await b.amath.ouvrir();
      final Future<void> envoi = b.amath.envoyer('1234567890123');

      b.c.read(compteProvider.notifier).connecter(bassirou);
      lente.complete(tour(<Message>[amath('Bienvenue Awa DIOP')]));
      await envoi;

      expect(b.etat.vierge, isTrue);
      expect(b.prefs.getString('chatbot_conversation_2'), isNull);
    });

    test('sans compte connecté, rien n’est écrit sur l’appareil', () async {
      final _Banc b = await _banc(<Object>[
        tour(<Message>[_salutation]),
      ]);
      b.c.read(compteProvider.notifier).connecter(null);
      await b.amath.ouvrir();
      expect(b.etat.messages, <Message>[_salutation]);
      expect(b.prefs.getKeys().where((k) => k.startsWith('chatbot')), isEmpty);
    });

    test('purger efface l’historique du compte (déconnexion)', () async {
      final _Banc b = await _auMenu();
      await b.c.read(historiqueStoreProvider).purger();
      expect(b.prefs.getString('chatbot_conversation_1'), isNull);
    });
  });
}
