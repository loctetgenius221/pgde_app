import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pgde_app/app.dart';
import 'package:pgde_app/core/network/api_exception.dart';
import 'package:pgde_app/core/storage/key_value_store.dart';
import 'package:pgde_app/features/demande/data/demande_api.dart';
import 'package:pgde_app/features/demande/domain/demande.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Faux dossier pilotable, pour éprouver le wizard sans dépendre de l'état
/// global du mock applicatif.
class _FauxDemandeApi implements DemandeApi {
  _FauxDemandeApi({this.dossier});

  Demande? dossier;
  ApiException? erreurAEnvoyer;
  Demande? dernierEnvoi;

  @override
  Future<Demande?> mien() async => dossier;

  @override
  Future<Demande> creer(Demande demande) async => _envoyer(demande, id: 1);

  @override
  Future<Demande> mettreAJour(Demande demande) async =>
      _envoyer(demande, id: demande.id);

  Demande _envoyer(Demande demande, {int? id}) {
    dernierEnvoi = demande;
    final ApiException? erreur = erreurAEnvoyer;
    if (erreur != null) throw erreur;
    return dossier = demande.copyWith(id: id);
  }
}

/// Dossier minimal accepté par le serveur (§4, récapitulatif).
final Demande _dossierValide = Demande(
  id: 42,
  dateNaissance: DateTime(1998, 4, 12),
  lieuNaissance: 'Dakar',
  lieuResidence: 'Pikine',
  genre: Genre.masculin,
  telephone1: '770000000',
  emploi1Id: 12,
  emploi2Id: 45,
);

Future<_FauxDemandeApi> _ouvrirLeWizard(
  WidgetTester tester, {
  Demande? dossier,
}) async {
  // L'application est verrouillée en portrait (§8.1) : le 800 × 600 par
  // défaut de `flutter_test` est une taille qui n'existe pas en production.
  tester.view
    ..physicalSize = const Size(400, 860)
    ..devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues(<String, Object>{
    'onboarding_vu': true,
  });
  FlutterSecureStorage.setMockInitialValues(<String, String>{});
  final prefs = await SharedPreferences.getInstance();
  final api = _FauxDemandeApi(dossier: dossier);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        demandeApiProvider.overrideWithValue(api),
      ],
      child: const PgdeApp(),
    ),
  );
  await tester.pumpAndSettle();

  // Connexion avec le compte de démonstration.
  await tester.enterText(find.byType(TextField).first, 'msagna');
  await tester.enterText(find.byType(TextField).last, 'password');
  await tester.tap(find.text('Se connecter'));
  await tester.pumpAndSettle();

  // Depuis l'accueil, on entre dans le dossier. Le libellé du bouton dépend
  // de l'état du dossier : on vise le bouton, pas son texte.
  await tester.tap(find.byType(FilledButton).first);
  await tester.pumpAndSettle();

  return api;
}

void main() {
  testWidgets('les quatre étapes sont atteignables dans l’ordre', (
    tester,
  ) async {
    await _ouvrirLeWizard(tester);

    expect(find.text('Identité et résidence'), findsOneWidget);
    expect(find.text('Date de naissance'), findsWidgets);

    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(find.text('Formations et documents'), findsOneWidget);

    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(find.text('Expériences professionnelles'), findsOneWidget);
    expect(find.text('Avez-vous déjà travaillé ?'), findsOneWidget);

    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(find.text('Vœux d\'emploi'), findsOneWidget);
    // Dernière étape : le bouton change de rôle.
    expect(find.text('Enregistrer'), findsOneWidget);
    expect(find.text('Continuer'), findsNothing);
  });

  testWidgets('enregistrer un dossier vide renvoie sur l’étape fautive', (
    tester,
  ) async {
    final api = await _ouvrirLeWizard(tester);

    for (int i = 0; i < 3; i++) {
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    // Rien n'est parti au serveur, et on est revenu à l'étape 1.
    expect(api.dernierEnvoi, isNull);
    expect(find.text('Identité et résidence'), findsOneWidget);
    expect(
      find.textContaining('Complétez l’étape'),
      findsOneWidget,
    );
  });

  testWidgets('un 422 renvoie sur l’étape qui porte le champ (§8.7)', (
    tester,
  ) async {
    final api = await _ouvrirLeWizard(tester, dossier: _dossierValide);
    api.erreurAEnvoyer = const ApiException(
      'Certaines informations sont invalides.',
      statusCode: 422,
      fieldErrors: <String, List<String>>{
        'cv_summary': <String>['Le résumé est trop long.'],
      },
    );

    // Le dossier chargé est complet : on peut enregistrer depuis l'étape 1.
    for (int i = 0; i < 3; i++) {
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(api.dernierEnvoi, isNotNull);
    // `cv_summary` appartient à l'étape 4 : on y reste, message affiché.
    expect(find.text('Vœux d\'emploi'), findsOneWidget);
    expect(find.text('Le résumé est trop long.'), findsOneWidget);
  });

  testWidgets('un dossier complet part en entier et ferme le wizard', (
    tester,
  ) async {
    final api = await _ouvrirLeWizard(tester, dossier: _dossierValide);

    for (int i = 0; i < 3; i++) {
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final Demande? envoye = api.dernierEnvoi;
    expect(envoye, isNotNull);
    expect(envoye!.emploi1Id, 12);
    expect(envoye.emploi2Id, 45);
    // Retour à l'accueil après l'enregistrement.
    expect(find.text('Les étapes de votre dossier'), findsOneWidget);
  });
}
