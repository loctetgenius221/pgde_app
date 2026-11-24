import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pgde_app/core/dictee/dictee.dart';
import 'package:pgde_app/core/dictee/moteur_speech_to_text.dart';
import 'package:pgde_app/core/network/api_exception.dart';
import 'package:pgde_app/core/theme/app_theme.dart';
import 'package:pgde_app/features/assistant/domain/message.dart';
import 'package:pgde_app/features/assistant/ui/assistant_page.dart';
import 'package:pgde_app/features/assistant/ui/texte_chatbot.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'outils_assistant.dart';

class _MicroMuet implements MoteurDictee {
  @override
  Future<ErreurDictee?> preparer() async => ErreurDictee.indisponible;

  @override
  Future<void> ecouter({
    required SurTexteDicte surTexte,
    required VoidCallback surFin,
    required ValueChanged<ErreurDictee> surErreur,
  }) async {}

  @override
  Future<void> arreter() async {}
}

final Message _salutation = amath('Je suis **Amath**. Votre nom ?');
final Message _menu = amath('Que souhaitez-vous faire ?', const [
  eCarriere,
  pgde,
]);
final Message _compte = amath('Avez-vous un compte ?', const [oui, non]);

Future<FauxAmath> _ouvrir(WidgetTester tester, List<Object> reponses) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final SharedPreferences prefs = await preferences();
  final FauxAmath serveur = FauxAmath(reponses);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...surcharges(prefs, serveur),
        moteurDicteeProvider.overrideWithValue(_MicroMuet()),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const AssistantPage()),
    ),
  );
  // Salutation envoyée après la première frame, et salut du personnage
  // terminé : plus aucun minuteur en attente.
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  return serveur;
}

TextField _champ(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField));

IconButton _icone(WidgetTester tester, String infobulle) =>
    tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip(infobulle),
        matching: find.byType(IconButton),
      ),
    );

OutlinedButton _bouton(WidgetTester tester, String titre) =>
    tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text(titre),
        matching: find.bySubtype<OutlinedButton>(),
      ),
    );

void main() {
  testWidgets('à l’ouverture : salutation affichée, /greet jamais montré', (
    tester,
  ) async {
    final FauxAmath serveur = await _ouvrir(tester, <Object>[
      tour(<Message>[_salutation]),
    ]);

    expect(serveur.messages, <String>['/greet']);
    expect(find.textContaining('/greet', findRichText: true), findsNothing);
    expect(
      find.textContaining('Votre nom ?', findRichText: true),
      findsOneWidget,
    );
    // Le Markdown est rendu : les étoiles ont disparu.
    expect(find.textContaining('**', findRichText: true), findsNothing);
    expect(_champ(tester).enabled, isTrue);
    expect(_champ(tester).decoration?.hintText, 'Écrivez votre message…');
  });

  testWidgets('le nom tapé part et s’affiche en bulle', (tester) async {
    final FauxAmath serveur = await _ouvrir(tester, <Object>[
      tour(<Message>[_salutation]),
      tour(<Message>[_menu]),
    ]);
    await tester.enterText(find.byType(TextField), 'Awa');
    await tester.pump();
    await tester.tap(find.byTooltip('Envoyer'));
    await tester.pump();

    expect(serveur.appels.last, (message: 'Awa', sessionId: 'session-1'));
    expect(find.text('Awa'), findsOneWidget);
    expect(_champ(tester).controller?.text, isEmpty);
  });

  testWidgets('le texte du candidat n’est jamais interprété', (tester) async {
    await _ouvrir(tester, <Object>[
      tour(<Message>[_salutation]),
      tour(<Message>[amath('Bien reçu.')]),
    ]);
    await tester.enterText(find.byType(TextField), '**Awa** [x](https://x.sn)');
    await tester.pump();
    await tester.tap(find.byTooltip('Envoyer'));
    await tester.pump();
    expect(find.text('**Awa** [x](https://x.sn)'), findsOneWidget);
  });

  testWidgets('menu : saisie fermée avec « Utilisez les boutons ci-dessus… »', (
    tester,
  ) async {
    await _ouvrir(tester, <Object>[
      tour(<Message>[_menu]),
    ]);

    expect(_champ(tester).enabled, isFalse);
    expect(
      _champ(tester).decoration?.hintText,
      'Utilisez les boutons ci-dessus…',
    );
    expect(_bouton(tester, 'E-Carrière').onPressed, isNotNull);
    expect(_icone(tester, 'Envoyer').onPressed, isNull);
    expect(find.byTooltip('Dicter le texte'), findsNothing);
  });

  testWidgets(
    'clic : bulle avec le titre, payload envoyé, ancien menu inactif',
    (tester) async {
      final FauxAmath serveur = await _ouvrir(tester, <Object>[
        tour(<Message>[_menu]),
        tour(<Message>[_compte]),
      ]);
      await tester.tap(find.text('E-Carrière'));
      await tester.pump();

      expect(serveur.messages.last, eCarriere.payload);
      // Le titre, une fois dans le menu et une fois en bulle du candidat.
      expect(find.text('E-Carrière'), findsNWidgets(2));
      expect(
        find.textContaining('choose_platform', findRichText: true),
        findsNothing,
      );
      expect(_bouton(tester, 'Demande d’emploi (PGDE)').onPressed, isNull);
      expect(_bouton(tester, 'Oui').onPressed, isNotNull);
    },
  );

  testWidgets('pendant un envoi : « Amath écrit… », tout est bloqué sauf ↻', (
    tester,
  ) async {
    final Completer<TourChatbot> lente = Completer<TourChatbot>();
    await _ouvrir(tester, <Object>[
      tour(<Message>[_menu]),
      lente,
    ]);
    await tester.tap(find.text('E-Carrière'));
    await tester.pump();

    expect(find.text('Amath écrit…'), findsWidgets);
    expect(find.bySemanticsLabel('Amath écrit…'), findsWidgets);
    expect(_champ(tester).enabled, isFalse);
    expect(_bouton(tester, 'Demande d’emploi (PGDE)').onPressed, isNull);
    expect(_icone(tester, 'Nouvelle conversation').onPressed, isNotNull);

    lente.complete(tour(<Message>[_compte]));
    await tester.pump();
    expect(find.text('Assistant virtuel'), findsOneWidget);
  });

  testWidgets('↻ efface le fil et resalue sans session', (tester) async {
    final FauxAmath serveur = await _ouvrir(tester, <Object>[
      tour(<Message>[_menu]),
      tour(<Message>[_compte]),
      tour(<Message>[_salutation], session: 'neuve'),
    ]);
    await tester.tap(find.text('E-Carrière'));
    await tester.pump();
    await tester.tap(_reinitialiser);
    await tester.pump();
    await tester.pump();

    expect(serveur.appels.last, (message: '/greet', sessionId: null));
    expect(find.text('E-Carrière'), findsNothing);
    expect(
      find.textContaining('Votre nom ?', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('503 : « indisponible » et Réessayer renvoie le même message', (
    tester,
  ) async {
    final FauxAmath serveur = await _ouvrir(tester, <Object>[
      tour(<Message>[_salutation]),
      const ApiException('x', statusCode: 503, code: 'chatbot_unavailable'),
      tour(<Message>[_menu]),
    ]);
    await tester.enterText(find.byType(TextField), 'Awa');
    await tester.pump();
    await tester.tap(find.byTooltip('Envoyer'));
    await tester.pump();

    expect(find.text('Amath est momentanément indisponible.'), findsOneWidget);
    expect(find.text('Awa'), findsOneWidget, reason: 'la bulle reste');

    await tester.tap(find.text('Réessayer'));
    await tester.pump();
    expect(serveur.messages, <String>['/greet', 'Awa', 'Awa']);
    expect(find.text('Amath est momentanément indisponible.'), findsNothing);
    expect(find.text('Awa'), findsOneWidget, reason: 'pas de bulle en double');
    expect(find.text('E-Carrière'), findsOneWidget);
  });

  testWidgets('429 : Réessayer grisé jusqu’au Retry-After', (tester) async {
    await _ouvrir(tester, <Object>[
      const ApiException(
        'x',
        statusCode: 429,
        code: 'too_many_requests',
        retryAfter: Duration(seconds: 4),
      ),
    ]);
    expect(
      find.text('Trop de messages, patientez quelques secondes.'),
      findsOneWidget,
    );
    expect(_bouton(tester, 'Réessayer').onPressed, isNull);
    await tester.pump(const Duration(seconds: 4));
    expect(_bouton(tester, 'Réessayer').onPressed, isNotNull);
  });

  testWidgets('422 : pas de Réessayer', (tester) async {
    await _ouvrir(tester, <Object>[const ApiException('x', statusCode: 422)]);
    expect(find.textContaining('n’a pas pu être envoyé'), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
  });

  testWidgets('CNI demandée : clavier numérique proposé', (tester) async {
    await _ouvrir(tester, <Object>[
      tour(<Message>[amath('Votre numéro de **CNI** (13 chiffres).')]),
    ]);
    expect(_champ(tester).keyboardType, TextInputType.number);
  });

  testWidgets('sinon clavier texte', (tester) async {
    await _ouvrir(tester, <Object>[
      tour(<Message>[_salutation]),
    ]);
    expect(_champ(tester).keyboardType, TextInputType.text);
  });

  testWidgets('les boutons portent l’icône de leur intention', (tester) async {
    await _ouvrir(tester, <Object>[
      tour(<Message>[
        amath('Menu', const <BoutonChat>[
          BoutonChat(
            titre: 'Menu principal',
            payload: '/go_back_greet_with_name',
          ),
          BoutonChat(titre: 'Inconnu', payload: '/intention_future'),
        ]),
      ]),
    ]);
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('Menu principal'),
          matching: find.bySubtype<OutlinedButton>(),
        ),
        matching: find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == 'Icone',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('Inconnu'),
          matching: find.bySubtype<OutlinedButton>(),
        ),
        matching: find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == 'Icone',
        ),
      ),
      findsNothing,
    );
  });

  testWidgets('un lien du texte s’ouvre au toucher', (tester) async {
    final List<Uri> ouverts = <Uri>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TexteChatbot(
            'Mot de passe oublié ? [Cliquez ici](https://emploi.fonctionpublique.sn/password) ou pas.',
            ouvrir: (url) async => ouverts.add(url),
          ),
        ),
      ),
    );
    await tester.tapOnText(find.textRange.ofSubstring('Cliquez ici'));
    expect(ouverts, <Uri>[
      Uri.parse('https://emploi.fonctionpublique.sn/password'),
    ]);

    await tester.tapOnText(find.textRange.ofSubstring('ou pas'));
    expect(
      ouverts,
      hasLength(1),
      reason: 'le reste du texte n’est pas un lien',
    );
  });

  testWidgets('les reconnaisseurs de lien sont libérés', (tester) async {
    Widget texte(String t) => MaterialApp(
      home: Scaffold(body: TexteChatbot(t, ouvrir: (_) async {})),
    );
    await tester.pumpWidget(texte('[a](https://a.sn) [b](https://b.sn)'));
    await tester.pumpWidget(texte('[c](https://c.sn)'));
    await tester.pumpWidget(const SizedBox());
    // Un reconnaisseur non libéré ferait échouer le test (fuite détectée
    // par le framework en fin de test).
    expect(tester.takeException(), isNull);
  });
}

final Finder _reinitialiser = find.byTooltip('Nouvelle conversation');
