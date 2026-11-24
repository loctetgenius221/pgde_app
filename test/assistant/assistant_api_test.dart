import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pgde_app/core/network/api_client.dart';
import 'package:pgde_app/core/network/api_exception.dart';
import 'package:pgde_app/features/assistant/data/assistant_api.dart';
import 'package:pgde_app/features/assistant/domain/message.dart';

/// Serveur HTTP simulé au niveau de l'adaptateur Dio : la requête traverse
/// toute la pile réelle — intercepteurs, sérialisation, traduction d'erreur.
class _Serveur implements HttpClientAdapter {
  _Serveur(this.statut, this.corps, {this.entetes = const {}});

  final int statut;
  final Object corps;
  final Map<String, List<String>> entetes;
  final List<RequestOptions> requetes = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requetes.add(options);
    return ResponseBody.fromString(
      jsonEncode(corps),
      statut,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        ...entetes,
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _ok(List<Map<String, dynamic>> messages) =>
    <String, dynamic>{
      'success': true,
      'message': 'Réponse du chatbot.',
      'data': <String, dynamic>{
        'session_id': '7e67ff0b-b83f-43f2-96e9-e4faa2481e01',
        'messages': messages,
      },
    };

Map<String, dynamic> _bulle({
  Object? text,
  Object? buttons = const <Object>[],
  Object? image,
  Object? custom,
}) => <String, dynamic>{
  'text': text,
  'buttons': buttons,
  'image': image,
  'custom': custom,
};

({HttpAssistantApi api, _Serveur serveur, List<String> journal}) _banc(
  _Serveur serveur,
) {
  final List<String> journal = <String>[];
  final Dio dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
    ..httpClientAdapter = serveur
    ..interceptors.add(JournalReseau(ecrire: (o) => journal.add('$o')));
  return (
    api: HttpAssistantApi(ApiClient(dio)),
    serveur: serveur,
    journal: journal,
  );
}

void main() {
  group('Requête', () {
    test('POST /chatbot/messages, premier appel sans session_id', () async {
      final b = _banc(_Serveur(200, _ok(const [])));
      await b.api.envoyer(message: '/greet');

      final RequestOptions r = b.serveur.requetes.single;
      expect(r.method, 'POST');
      expect(r.path, '/chatbot/messages');
      expect(r.data, <String, dynamic>{'message': '/greet'});
    });

    test('les appels suivants portent la session', () async {
      final b = _banc(_Serveur(200, _ok(const [])));
      await b.api.envoyer(message: 'Awa', sessionId: 'abc');
      expect(b.serveur.requetes.single.data, <String, dynamic>{
        'message': 'Awa',
        'session_id': 'abc',
      });
    });

    test('une session vide n’est pas envoyée', () async {
      final b = _banc(_Serveur(200, _ok(const [])));
      await b.api.envoyer(message: 'x', sessionId: '');
      expect(
        (b.serveur.requetes.single.data as Map).containsKey('session_id'),
        isFalse,
      );
    });

    test(
      'le payload part sans retouche, accolades et accents compris',
      () async {
        final b = _banc(_Serveur(200, _ok(const [])));
        const String payload = '/choose_platform{"platform": "E-Carrière"}';
        await b.api.envoyer(message: payload, sessionId: 's');
        expect((b.serveur.requetes.single.data as Map)['message'], payload);
      },
    );

    test('délai de réception d’au moins 35 s (contrat §2)', () async {
      final b = _banc(_Serveur(200, _ok(const [])));
      await b.api.envoyer(message: 'x');
      final Duration? delai = b.serveur.requetes.single.receiveTimeout;
      expect(delai, isNotNull);
      expect(delai! >= const Duration(seconds: 35), isTrue);
    });

    test(
      'n’appelle jamais les routes réservées au serveur du chatbot',
      () async {
        final b = _banc(_Serveur(200, _ok(const [])));
        await b.api.envoyer(message: 'x');
        final RequestOptions r = b.serveur.requetes.single;
        expect(r.path, isNot(contains('/chatbot/pgde')));
        expect(
          r.headers.keys.map((k) => k.toLowerCase()),
          isNot(contains('x-chatbot-token')),
        );
      },
    );
  });

  group('Réponse', () {
    test(
      'une bulle par message, dans l’ordre, avec la session reçue',
      () async {
        final b = _banc(
          _Serveur(
            200,
            _ok(<Map<String, dynamic>>[
              _bulle(text: 'Premier'),
              _bulle(text: 'Second'),
            ]),
          ),
        );
        final TourChatbot t = await b.api.envoyer(message: 'x');
        expect(t.sessionId, '7e67ff0b-b83f-43f2-96e9-e4faa2481e01');
        expect(t.messages.map((m) => m.texte), <String>['Premier', 'Second']);
        expect(t.messages.every((m) => m.vientDeLAssistant), isTrue);
      },
    );

    test('aucune bulle : liste vide, sans erreur', () async {
      final b = _banc(_Serveur(200, _ok(const [])));
      expect((await b.api.envoyer(message: 'x')).messages, isEmpty);
    });

    test('text null : bulle de boutons seuls', () async {
      final b = _banc(
        _Serveur(
          200,
          _ok(<Map<String, dynamic>>[
            _bulle(
              buttons: <Map<String, String>>[
                <String, String>{
                  'title': 'Oui',
                  'payload': '/confirm_has_account',
                },
              ],
            ),
          ]),
        ),
      );
      final Message m = (await b.api.envoyer(message: 'x')).messages.single;
      expect(m.texte, isEmpty);
      expect(m.boutons, const <BoutonChat>[
        BoutonChat(titre: 'Oui', payload: '/confirm_has_account'),
      ]);
    });

    test('un message entièrement vide est écarté', () async {
      final b = _banc(_Serveur(200, _ok(<Map<String, dynamic>>[_bulle()])));
      expect((await b.api.envoyer(message: 'x')).messages, isEmpty);
    });

    test('boutons incomplets ignorés', () async {
      final b = _banc(
        _Serveur(
          200,
          _ok(<Map<String, dynamic>>[
            _bulle(
              text: 't',
              buttons: <Object>[
                <String, String>{'title': '', 'payload': '/a'},
                <String, String>{'title': 'B'},
                'pas un objet',
                <String, String>{'title': 'C', 'payload': '/c'},
              ],
            ),
          ]),
        ),
      );
      expect(
        (await b.api.envoyer(message: 'x')).messages.single.boutons,
        const <BoutonChat>[BoutonChat(titre: 'C', payload: '/c')],
      );
    });

    test('seule une image https est gardée', () async {
      final b = _banc(
        _Serveur(
          200,
          _ok(<Map<String, dynamic>>[
            _bulle(image: 'https://emploi.fonctionpublique.sn/a.png'),
            _bulle(text: 'a', image: 'http://exemple.sn/b.png'),
            _bulle(text: 'b', image: 'javascript:alert(1)'),
            _bulle(text: 'c', image: 42),
          ]),
        ),
      );
      final List<Message> m = (await b.api.envoyer(message: 'x')).messages;
      expect(m.map((x) => x.imageUrl), <String?>[
        'https://emploi.fonctionpublique.sn/a.png',
        null,
        null,
        null,
      ]);
    });

    test('custom est ignoré sans erreur', () async {
      final b = _banc(
        _Serveur(
          200,
          _ok(<Map<String, dynamic>>[
            _bulle(
              text: 'ok',
              custom: <String, Object>{'type': 'carte', 'x': 1},
            ),
          ]),
        ),
      );
      expect((await b.api.envoyer(message: 'x')).messages.single.texte, 'ok');
    });
  });

  group('Erreurs', () {
    Future<ApiException> echec(_Serveur s) async {
      try {
        await _banc(s).api.envoyer(message: 'x');
      } on ApiException catch (e) {
        return e;
      }
      fail('une ApiException était attendue');
    }

    test('503 chatbot_unavailable', () async {
      final ApiException e = await echec(
        _Serveur(503, <String, dynamic>{
          'success': false,
          'code': 'chatbot_unavailable',
          'message': 'Le chatbot est indisponible.',
        }),
      );
      expect(e.isChatbotUnavailable, isTrue);
    });

    test('429 too_many_requests et son Retry-After', () async {
      final ApiException e = await echec(
        _Serveur(
          429,
          <String, dynamic>{
            'success': false,
            'code': 'too_many_requests',
            'message': 'Trop de requêtes.',
          },
          entetes: <String, List<String>>{
            'retry-after': <String>['12'],
          },
        ),
      );
      expect(e.isTooManyRequests, isTrue);
      expect(e.retryAfter, const Duration(seconds: 12));
    });

    test('429 too_many_cni_attempts garde le message du serveur', () async {
      final ApiException e = await echec(
        _Serveur(429, <String, dynamic>{
          'success': false,
          'code': 'too_many_cni_attempts',
          'message': 'Trop de numéros de CNI. Réessayez dans 10 minutes.',
        }),
      );
      expect(e.isTooManyCniAttempts, isTrue);
      expect(e.message, 'Trop de numéros de CNI. Réessayez dans 10 minutes.');
      expect(e.retryAfter, isNull);
    });

    test('Retry-After illisible ou négatif : ignoré', () async {
      for (final String valeur in <String>[
        'Wed, 21 Oct 2026 07:28:00 GMT',
        '-3',
        '',
      ]) {
        final ApiException e = await echec(
          _Serveur(
            429,
            <String, dynamic>{'code': 'too_many_requests'},
            entetes: <String, List<String>>{
              'retry-after': <String>[valeur],
            },
          ),
        );
        expect(e.retryAfter, isNull, reason: valeur);
      }
    });

    test('422 : erreur de validation', () async {
      final ApiException e = await echec(
        _Serveur(422, <String, dynamic>{
          'success': false,
          'message': 'Données invalides.',
          'errors': <String, List<String>>{
            'message': <String>['Le message est trop long.'],
          },
        }),
      );
      expect(e.isValidation, isTrue);
      expect(e.errorFor('message'), 'Le message est trop long.');
    });
  });

  group('Journal de débogage', () {
    const String cni = '1234567890123';

    test('le contenu d’un échange avec Amath n’est jamais écrit', () async {
      final b = _banc(
        _Serveur(
          200,
          _ok(<Map<String, dynamic>>[_bulle(text: 'CNI $cni reçue, Awa DIOP')]),
        ),
      );
      await b.api.envoyer(message: cni, sessionId: 'session-secrete');

      final String tout = b.journal.join('\n');
      expect(tout, isNot(contains(cni)));
      expect(tout, isNot(contains('Awa DIOP')));
      expect(tout, isNot(contains('session-secrete')));
      expect(tout, contains('/chatbot/messages'));
      expect(tout, contains('contenu masqué'));
    });

    test('ni en cas d’erreur', () async {
      final b = _banc(
        _Serveur(503, <String, dynamic>{
          'code': 'chatbot_unavailable',
          'message': 'Échec pour $cni',
        }),
      );
      await expectLater(
        b.api.envoyer(message: cni),
        throwsA(isA<ApiException>()),
      );
      expect(b.journal.join('\n'), isNot(contains(cni)));
      expect(b.journal.join('\n'), contains('503'));
    });

    test('les autres requêtes restent journalisées en entier', () async {
      final _Serveur serveur = _Serveur(200, <String, dynamic>{
        'data': 'visible',
      });
      final List<String> journal = <String>[];
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = serveur
        ..interceptors.add(JournalReseau(ecrire: (o) => journal.add('$o')));
      await ApiClient(
        dio,
      ).post('/auth/login', body: <String, String>{'login': 'awa'});
      expect(journal.join('\n'), contains('awa'));
      expect(journal.join('\n'), contains('visible'));
    });
  });
}
