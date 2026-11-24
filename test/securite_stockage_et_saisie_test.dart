import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pgde_app/core/network/api_exception.dart';
import 'package:pgde_app/core/storage/coffre_local.dart';
import 'package:pgde_app/core/storage/key_value_store.dart';
import 'package:pgde_app/core/ui/form_submission.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Non-régression des correctifs du 24 novembre 2026 : chiffrement des
/// données locales (SEC-002) et blocage des formulaires sur `429`.

/// Keystore qui accepte la lecture mais refuse d'écrire.
class _KeystoreEnLectureSeule extends FlutterSecureStorage {
  const _KeystoreEnLectureSeule();

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => null;

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => throw PlatformException(code: 'keystore');
}

Future<(KeyValueStore, SharedPreferences)> _prefs([
  Map<String, Object> contenu = const <String, Object>{},
]) async {
  SharedPreferences.setMockInitialValues(contenu);
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return (KeyValueStore(prefs), prefs);
}

const String _cle = 'brouillon_demande_7';
const Map<String, dynamic> _dossier = <String, dynamic>{
  'lieuNaissance': 'Thiès',
  'handicap': 'moteur',
};

void main() {
  group('SEC-002 — CoffreLocal', () {
    test('chiffre puis déchiffre, sans laisser le clair', () {
      final CoffreLocal coffre = CoffreLocal.enMemoire();
      final String chiffre = coffre.chiffrer('handicap moteur', contexte: 'a')!;

      expect(chiffre, startsWith('v1:'));
      expect(chiffre, isNot(contains('handicap')));
      expect(coffre.dechiffrer(chiffre, contexte: 'a'), 'handicap moteur');
    });

    test('deux chiffrements du même texte diffèrent (nonce aléatoire)', () {
      final CoffreLocal coffre = CoffreLocal.enMemoire();
      expect(
        coffre.chiffrer('x', contexte: 'a'),
        isNot(coffre.chiffrer('x', contexte: 'a')),
      );
    });

    test('un chiffré recopié sous la clé d’un autre compte est rejeté', () {
      final CoffreLocal coffre = CoffreLocal.enMemoire();
      final String chiffre = coffre.chiffrer('dossier de A', contexte: 'b_1')!;
      expect(coffre.dechiffrer(chiffre, contexte: 'b_2'), isNull);
    });

    test('un chiffré altéré est rejeté', () {
      final CoffreLocal coffre = CoffreLocal.enMemoire();
      final String chiffre = coffre.chiffrer('dossier', contexte: 'a')!;
      final String altere =
          chiffre.substring(0, chiffre.length - 3) +
          (chiffre[chiffre.length - 3] == 'A' ? 'B' : 'A') +
          chiffre.substring(chiffre.length - 2);
      expect(coffre.dechiffrer(altere, contexte: 'a'), isNull);
    });

    test('une autre clé ne déchiffre pas', () {
      final String chiffre = CoffreLocal.enMemoire().chiffrer(
        'dossier',
        contexte: 'a',
      )!;
      expect(
        CoffreLocal.enMemoire().dechiffrer(chiffre, contexte: 'a'),
        isNull,
      );
    });

    test(
      'la clé est conservée dans le Keystore d’un lancement à l’autre',
      () async {
        FlutterSecureStorage.setMockInitialValues(<String, String>{});
        final CoffreLocal premier = CoffreLocal(const FlutterSecureStorage());
        await premier.ouvrir();
        final String chiffre = premier.chiffrer('dossier', contexte: 'a')!;

        final CoffreLocal relance = CoffreLocal(const FlutterSecureStorage());
        await relance.ouvrir();
        expect(relance.dechiffrer(chiffre, contexte: 'a'), 'dossier');
      },
    );

    test('clé impossible à enregistrer : le coffre reste fermé', () async {
      final CoffreLocal coffre = CoffreLocal(const _KeystoreEnLectureSeule());
      await coffre.ouvrir();
      expect(coffre.ouvert, isFalse);
      expect(coffre.chiffrer('x', contexte: 'a'), isNull);
    });
  });

  group('SEC-002 — StockageChiffre', () {
    test('rien de lisible dans SharedPreferences', () async {
      final (KeyValueStore store, SharedPreferences prefs) = await _prefs();
      await StockageChiffre(
        store,
        CoffreLocal.enMemoire(),
      ).writeJson(_cle, _dossier);

      final String brut = prefs.getString(_cle)!;
      expect(brut, startsWith('v1:'));
      expect(brut, isNot(contains('Thiès')));
      expect(brut, isNot(contains('handicap')));
    });

    test('relit ce qu’il a écrit', () async {
      final (KeyValueStore store, _) = await _prefs();
      final StockageChiffre stockage = StockageChiffre(
        store,
        CoffreLocal.enMemoire(),
      );
      await stockage.writeJson(_cle, _dossier);
      expect(stockage.readJson(_cle), _dossier);
    });

    test('un brouillon en clair d’une version antérieure est repris et '
        'rechiffré', () async {
      final (KeyValueStore store, SharedPreferences prefs) = await _prefs(
        <String, Object>{_cle: '{"lieuNaissance":"Thiès","handicap":"moteur"}'},
      );
      final StockageChiffre stockage = StockageChiffre(
        store,
        CoffreLocal.enMemoire(),
      );

      expect(stockage.readJson(_cle), _dossier);
      await pumpEventQueue();
      expect(prefs.getString(_cle), startsWith('v1:'));
      expect(prefs.getString(_cle), isNot(contains('Thiès')));
    });

    test('coffre fermé : rien n’est écrit, surtout pas en clair', () async {
      final (KeyValueStore store, SharedPreferences prefs) = await _prefs();
      final CoffreLocal ferme = CoffreLocal(const _KeystoreEnLectureSeule());
      await ferme.ouvrir();

      await StockageChiffre(store, ferme).writeJson(_cle, _dossier);
      expect(prefs.containsKey(_cle), isFalse);
    });

    test(
      'clé perdue (réinstallation) : l’entrée illisible est purgée',
      () async {
        final (KeyValueStore store, SharedPreferences prefs) = await _prefs();
        await StockageChiffre(
          store,
          CoffreLocal.enMemoire(),
        ).writeJson(_cle, _dossier);

        final StockageChiffre autreCle = StockageChiffre(
          store,
          CoffreLocal.enMemoire(),
        );
        expect(autreCle.readJson(_cle), isNull);
        await pumpEventQueue();
        expect(prefs.containsKey(_cle), isFalse);
      },
    );
  });

  group('Force brute — blocage des formulaires sur 429', () {
    Future<void> monter(WidgetTester tester, Future<void> Function() action) =>
        tester.pumpWidget(MaterialApp(home: _Formulaire(action)));

    testWidgets('le bouton se bloque pendant Retry-After, avec un compte à '
        'rebours', (WidgetTester tester) async {
      int appels = 0;
      await monter(tester, () async {
        appels++;
        throw const ApiException(
          'Trop de tentatives.',
          statusCode: 429,
          retryAfter: Duration(seconds: 3),
        );
      });

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(find.text('Réessayez dans 3 s'), findsOneWidget);

      // Toucher pendant le blocage ne déclenche aucun appel.
      await tester.tap(find.byType(FilledButton));
      await tester.pump(const Duration(seconds: 1));
      expect(appels, 1);
      expect(find.text('Réessayez dans 2 s'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Se connecter'), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(appels, 2);
      await tester.pump(const Duration(minutes: 2)); // vide les minuteurs
    });

    testWidgets('sans Retry-After, attente par défaut de 60 s', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        () async => throw const ApiException('x', statusCode: 429),
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(find.text('Réessayez dans 1 min 00'), findsOneWidget);
      await tester.pump(const Duration(seconds: 61));
      expect(find.text('Se connecter'), findsOneWidget);
    });

    testWidgets('un Retry-After aberrant est plafonné à 15 min', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        () async => throw const ApiException(
          'x',
          statusCode: 429,
          retryAfter: Duration(days: 2),
        ),
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(find.text('Réessayez dans 15 min 00'), findsOneWidget);
      await tester.pump(const Duration(minutes: 16));
    });

    testWidgets('une autre erreur ne bloque pas', (WidgetTester tester) async {
      await monter(
        tester,
        () async => throw const ApiException('Identifiants', statusCode: 401),
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(find.text('Se connecter'), findsOneWidget);
    });
  });
}

class _Formulaire extends StatefulWidget {
  const _Formulaire(this.action);

  final Future<void> Function() action;

  @override
  State<_Formulaire> createState() => _FormulaireState();
}

class _FormulaireState extends State<_Formulaire> with FormSubmission {
  @override
  Widget build(BuildContext context) => Scaffold(
    body: FilledButton(
      onPressed: envoiPossible ? () => soumettre(widget.action) : null,
      child: contenuBouton('Se connecter'),
    ),
  );
}
