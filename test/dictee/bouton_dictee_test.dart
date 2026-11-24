import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pgde_app/core/dictee/dictee.dart';
import 'package:pgde_app/core/dictee/moteur_speech_to_text.dart';
import 'package:pgde_app/core/theme/app_theme.dart';
import 'package:pgde_app/core/ui/champs.dart';

/// Moteur piloté par le test : il dit ce qu'on lui fait dire, quand on le
/// lui demande.
class _MoteurPilote implements MoteurDictee {
  ErreurDictee? echecPreparation;
  Completer<void>? preparationEnCours;

  int preparations = 0;
  int ecoutes = 0;
  int arrets = 0;

  SurTexteDicte? _surTexte;
  VoidCallback? _surFin;
  ValueChanged<ErreurDictee>? _surErreur;

  bool get ecoute => _surFin != null;

  @override
  Future<ErreurDictee?> preparer() async {
    preparations++;
    await preparationEnCours?.future;
    return echecPreparation;
  }

  @override
  Future<void> ecouter({
    required SurTexteDicte surTexte,
    required VoidCallback surFin,
    required ValueChanged<ErreurDictee> surErreur,
  }) async {
    ecoutes++;
    _surTexte = surTexte;
    _surFin = surFin;
    _surErreur = surErreur;
  }

  @override
  Future<void> arreter() async => arrets++;

  void entendre(String texte, {bool definitif = false}) =>
      _surTexte?.call(texte, definitif: definitif);

  void echouer(ErreurDictee erreur) => _surErreur?.call(erreur);

  void finir() {
    final VoidCallback? fin = _surFin;
    _surTexte = null;
    _surFin = null;
    _surErreur = null;
    fin?.call();
  }
}

class _Banc {
  _Banc(this.moteur);

  final _MoteurPilote moteur;
  final List<String> valeurs = <String>[];

  String get derniere => valeurs.last;
}

Future<_Banc> _poser(
  WidgetTester tester, {
  String valeur = '',
  int? longueurMax,
  bool dictee = true,
  _MoteurPilote? moteur,
}) async {
  final _Banc banc = _Banc(moteur ?? _MoteurPilote());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [moteurDicteeProvider.overrideWithValue(banc.moteur)],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ChampTexte(
              libelle: 'Missions principales',
              valeur: valeur,
              lignes: 4,
              longueurMax: longueurMax,
              dictee: dictee,
              onChange: banc.valeurs.add,
            ),
          ),
        ),
      ),
    ),
  );
  return banc;
}

final Finder _micro = find.byTooltip('Dicter le texte');
final Finder _stop = find.byTooltip('Arrêter la dictée');

String _texteDuChamp(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

void main() {
  group('Présence du bouton', () {
    testWidgets('un champ avec dictée porte le micro', (tester) async {
      await _poser(tester);
      expect(_micro, findsOneWidget);
      expect(_stop, findsNothing);
    });

    testWidgets('sans dictée, aucun micro', (tester) async {
      await _poser(tester, dictee: false);
      expect(_micro, findsNothing);
    });
  });

  group('Dictée réussie', () {
    testWidgets('le texte apparaît au fil de la parole, à la suite', (
      tester,
    ) async {
      final _Banc banc = await _poser(tester, valeur: 'Gestion de la paie.');

      await tester.tap(_micro);
      await tester.pump();
      expect(banc.moteur.preparations, 1);
      expect(banc.moteur.ecoutes, 1);
      expect(_stop, findsOneWidget, reason: 'le bouton passe en « arrêter »');

      banc.moteur.entendre('suivi des');
      await tester.pump();
      expect(_texteDuChamp(tester), 'Gestion de la paie. Suivi des');

      // Chaque partiel remplace le précédent, il ne s'empile pas.
      banc.moteur.entendre('suivi des congés');
      await tester.pump();
      expect(_texteDuChamp(tester), 'Gestion de la paie. Suivi des congés');

      banc.moteur
        ..entendre('suivi des congés', definitif: true)
        ..finir();
      await tester.pump();

      expect(_texteDuChamp(tester), 'Gestion de la paie. Suivi des congés');
      // Le dossier reçoit la valeur : elle sera sauvegardée en brouillon.
      expect(banc.derniere, 'Gestion de la paie. Suivi des congés');
      expect(_micro, findsOneWidget, reason: 'retour au repos');
    });

    testWidgets('le curseur se place à la fin du texte dicté', (tester) async {
      final _Banc banc = await _poser(tester);
      await tester.tap(_micro);
      await tester.pump();
      banc.moteur.entendre('comptable');
      await tester.pump();

      final TextEditingController c = tester
          .widget<TextField>(find.byType(TextField))
          .controller!;
      expect(c.selection, const TextSelection.collapsed(offset: 9));
    });

    testWidgets('deux dictées successives s’enchaînent', (tester) async {
      final _Banc banc = await _poser(tester);

      await tester.tap(_micro);
      await tester.pump();
      banc.moteur
        ..entendre('première phrase.', definitif: true)
        ..finir();
      await tester.pump();

      await tester.tap(_micro);
      await tester.pump();
      banc.moteur
        ..entendre('deuxième phrase', definitif: true)
        ..finir();
      await tester.pump();

      expect(_texteDuChamp(tester), 'Première phrase. Deuxième phrase');
    });

    testWidgets('le texte modifié au clavier entre deux dictées est gardé', (
      tester,
    ) async {
      final _Banc banc = await _poser(tester);
      await tester.enterText(find.byType(TextField), 'Saisi au clavier');
      await tester.pump();

      await tester.tap(_micro);
      await tester.pump();
      banc.moteur.entendre('puis dicté', definitif: true);
      await tester.pump();

      expect(_texteDuChamp(tester), 'Saisi au clavier puis dicté');
    });

    testWidgets('la limite du champ n’est jamais dépassée', (tester) async {
      final _Banc banc = await _poser(tester, valeur: 'abc', longueurMax: 10);

      await tester.tap(_micro);
      await tester.pump();
      banc.moteur.entendre('defghijklmnop', definitif: true);
      await tester.pump();

      expect(_texteDuChamp(tester), 'abc defghi');
      expect(_texteDuChamp(tester).length, 10);
    });
  });

  group('Arrêt', () {
    testWidgets('un second appui arrête l’écoute', (tester) async {
      final _Banc banc = await _poser(tester);
      await tester.tap(_micro);
      await tester.pump();

      await tester.tap(_stop);
      await tester.pump();
      expect(banc.moteur.arrets, 1);

      // Le bouton reste « arrêter » jusqu'à la vraie fin de session, qui
      // livre le dernier texte.
      expect(_stop, findsOneWidget);
      banc.moteur.finir();
      await tester.pump();
      expect(_micro, findsOneWidget);
    });

    testWidgets('quitter l’écran en pleine dictée coupe le micro', (
      tester,
    ) async {
      final _Banc banc = await _poser(tester);
      await tester.tap(_micro);
      await tester.pump();

      await tester.pumpWidget(const SizedBox());
      expect(banc.moteur.arrets, 1);
    });

    testWidgets('quitter l’écran au repos ne sollicite pas le moteur', (
      tester,
    ) async {
      final _Banc banc = await _poser(tester);
      await tester.pumpWidget(const SizedBox());
      expect(banc.moteur.arrets, 0);
    });
  });

  group('Échecs', () {
    testWidgets('micro refusé : message clair, et le micro reste fermé', (
      tester,
    ) async {
      final _MoteurPilote moteur = _MoteurPilote()
        ..echecPreparation = ErreurDictee.permissionRefusee;
      await _poser(tester, moteur: moteur);

      await tester.tap(_micro);
      await tester.pump();

      expect(find.text(ErreurDictee.permissionRefusee.message), findsOneWidget);
      expect(moteur.ecoutes, 0);
      expect(_micro, findsOneWidget);
    });

    testWidgets('dictée indisponible : message dédié', (tester) async {
      final _MoteurPilote moteur = _MoteurPilote()
        ..echecPreparation = ErreurDictee.indisponible;
      await _poser(tester, moteur: moteur);

      await tester.tap(_micro);
      await tester.pump();

      expect(find.text(ErreurDictee.indisponible.message), findsOneWidget);
    });

    testWidgets('erreur en cours de dictée : message, puis retour au repos', (
      tester,
    ) async {
      final _Banc banc = await _poser(tester, valeur: 'Début');
      await tester.tap(_micro);
      await tester.pump();

      banc.moteur
        ..echouer(ErreurDictee.rienEntendu)
        ..finir();
      await tester.pump();

      expect(find.text(ErreurDictee.rienEntendu.message), findsOneWidget);
      expect(_micro, findsOneWidget);
      // Le texte déjà saisi n'est pas touché.
      expect(_texteDuChamp(tester), 'Début');
    });

    testWidgets('pendant la préparation, un double appui est ignoré', (
      tester,
    ) async {
      final _MoteurPilote moteur = _MoteurPilote()
        ..preparationEnCours = Completer<void>();
      await _poser(tester, moteur: moteur);

      await tester.tap(_micro);
      await tester.pump();
      await tester.tap(_micro);
      await tester.pump();
      expect(moteur.preparations, 1);

      moteur.preparationEnCours!.complete();
      await tester.pump();
      expect(moteur.ecoutes, 1);
    });
  });
}
