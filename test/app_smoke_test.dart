import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pgde_app/app.dart';
import 'package:pgde_app/core/storage/key_value_store.dart';
import 'package:pgde_app/core/ui/responsive.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Parcours d'ouverture de bout en bout : amorçage, splash animé, onboarding,
/// connexion. Fait aussi office de test de compilation de l'arbre complet.
Future<void> _lancer(
  WidgetTester tester, {
  Map<String, Object> prefs = const <String, Object>{},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  FlutterSecureStorage.setMockInitialValues(<String, String>{});
  final instance = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(instance)],
      child: const PgdeApp(),
    ),
  );
}

void main() {
  testWidgets('au premier lancement, le splash mène à l’onboarding', (
    tester,
  ) async {
    await _lancer(tester);

    // Le splash s'affiche d'abord : le logo est à l'écran, pas l'onboarding.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Passer'), findsNothing);

    // Le routeur ne quitte le splash qu'une fois l'animation terminée.
    await tester.pumpAndSettle();
    expect(find.text('Une demande, un dossier'), findsOneWidget);
    expect(find.text('Continuer'), findsOneWidget);
  });

  testWidgets('l’onboarding se parcourt et libère l’accès à la connexion', (
    tester,
  ) async {
    await _lancer(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(find.text('Préparez vos pièces'), findsOneWidget);

    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(find.text('Quatre étapes, à votre rythme'), findsOneWidget);

    // Dernière page : le bouton change de libellé.
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();

    expect(find.text('Votre espace candidat'), findsOneWidget);
    expect(find.text('Email ou nom d’utilisateur'), findsOneWidget);
    // §3.3 : l'API accepte l'email ou le nom d'utilisateur.
    expect(find.text('Adresse email'), findsNothing);
  });

  testWidgets('onboarding déjà vu : le splash mène droit à la connexion', (
    tester,
  ) async {
    await _lancer(tester, prefs: <String, Object>{'onboarding_vu': true});
    await tester.pumpAndSettle();

    expect(find.text('Votre espace candidat'), findsOneWidget);
    expect(find.text('Une demande, un dossier'), findsNothing);
  });

  testWidgets('sur tablette, le formulaire reste dans une largeur lisible', (
    tester,
  ) async {
    // Format de la tablette de test : 1200 × 2000.
    tester.view
      ..physicalSize = const Size(1200, 2000)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _lancer(tester, prefs: <String, Object>{'onboarding_vu': true});
    await tester.pumpAndSettle();

    // Sans plafond, le champ s'étirerait sur toute la largeur de l'écran.
    final Size champ = tester.getSize(find.byType(TextFormField).first);
    expect(champ.width, lessThanOrEqualTo(LargeurMax.formulaire));
    expect(champ.width, greaterThan(300));
  });

  testWidgets('sur un téléphone, le sigle vient s’aligner avec le logo', (
    tester,
  ) async {
    // Petit téléphone courant : 360 × 800 en pixels logiques.
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _lancer(tester);

    // Le logo se pose seul : le sigle n'est pas encore entré.
    await tester.pump(const Duration(milliseconds: 250));
    final Rect logoSeul = tester.getRect(find.byType(Image));
    expect(
      logoSeul.center.dx,
      closeTo(180, 12),
      reason: 'le logo commence centré, avant l’arrivée du sigle',
    );

    // Une fois l'assemblage joué, les deux partagent la même ligne.
    await tester.pump(const Duration(milliseconds: 1550));
    final Rect logo = tester.getRect(find.byType(Image));
    final Rect sigle = tester.getRect(find.text('PGDE'));

    expect(
      sigle.left,
      greaterThan(logo.right - 1),
      reason: 'le sigle est à droite du logo',
    );
    // Même ligne : les deux rectangles se chevauchent verticalement.
    expect(logo.top, lessThan(sigle.bottom));
    expect(sigle.top, lessThan(logo.bottom));
    // Et le logo a bien cédé sa place centrale.
    expect(logo.center.dx, lessThan(logoSeul.center.dx - 10));

    // Le pied de page tient dans l'écran, sans rognage latéral.
    final Rect ministere = tester.getRect(
      find.textContaining('Ministère de la Fonction publique'),
    );
    expect(ministere.bottom, lessThanOrEqualTo(800));
    expect(ministere.left, greaterThanOrEqualTo(0));
    expect(ministere.right, lessThanOrEqualTo(360));
  });
}
