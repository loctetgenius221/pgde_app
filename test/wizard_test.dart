import 'dart:io';

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

  /// Les quatre étapes enregistrées, dans l'ordre où elles sont parties.
  final List<String> etapesEnvoyees = <String>[];

  /// Dernier dossier soumis, toutes étapes confondues.
  Demande? dernierEnvoi;

  /// Rangs de formation pour lesquels un justificatif a été déposé (§6.4).
  final List<int> diplomesDeposes = <int>[];

  @override
  Future<Demande?> mien() async => dossier;

  @override
  Future<void> enregistrerIdentite(Demande d) => _envoyer(d, 'identity');

  @override
  Future<void> enregistrerFormations(Demande d) => _envoyer(d, 'formations');

  @override
  Future<void> enregistrerExperiences(Demande d) => _envoyer(d, 'experiences');

  @override
  Future<void> enregistrerVoeux(Demande d) => _envoyer(d, 'target-jobs');

  Future<void> _envoyer(Demande demande, String etape) async {
    dernierEnvoi = demande;
    final ApiException? erreur = erreurAEnvoyer;
    if (erreur != null) throw erreur;
    etapesEnvoyees.add(etape);
    dossier = demande.copyWith(deposee: true);
  }

  // Les pièces ne sont pas l'objet de ces tests : on note ce qui est
  // demandé, sans toucher au dossier.
  final List<File> photosDeposees = <File>[];

  @override
  Future<FichierJoint> deposerPhoto(File fichier) async {
    photosDeposees.add(fichier);
    return const FichierJoint(chemin: 'p.jpg', url: 'http://x/p.jpg');
  }

  @override
  Future<FichierJoint> deposerDiplome({
    required File fichier,
    required int formationIndex,
  }) async {
    diplomesDeposes.add(formationIndex);
    return const FichierJoint(chemin: 'd.pdf', url: 'http://x/d.pdf');
  }

  @override
  Future<FichierJoint> deposerCv(File fichier) async =>
      const FichierJoint(chemin: 'cv.pdf', url: 'http://x/cv.pdf');

  @override
  Future<void> supprimerCv() async {}
}

/// Dossier minimal accepté par le serveur (§4, récapitulatif).
final Demande _dossierValide = Demande(
  deposee: true,
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

  // L'accueil porte l'avatar de l'assistant, dont l'animation de repos
  // tourne sans fin : `pumpAndSettle` attendrait indéfiniment une scène qui
  // ne se stabilise jamais. On demande donc le mouvement réduit — ce qui
  // éprouve au passage le chemin que suit un utilisateur ayant désactivé les
  // animations sur son appareil.
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

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

  // Depuis l'accueil, on entre dans le formulaire. Un dossier déjà déposé
  // ouvre d'abord le résumé : c'est « Modifier » qui mène au wizard.
  await tester.tap(
    dossier == null
        ? find.byType(FilledButton).first
        : find.text('Modifier mon dossier'),
  );
  await tester.pumpAndSettle();

  return api;
}

void main() {
  testWidgets('les quatre étapes sont atteignables dans l’ordre', (
    tester,
  ) async {
    await _ouvrirLeWizard(tester);

    expect(find.text('Identité et résidence'), findsOneWidget);
    // Le libellé d'un champ obligatoire est un `Text.rich` (astérisque) :
    // `find.text` ne le verrait pas.
    expect(find.textContaining('Date de naissance'), findsWidgets);

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

  testWidgets('répondre « oui » au handicap ouvre le choix du type', (
    tester,
  ) async {
    await _ouvrirLeWizard(tester);

    // La question est en bas de l'étape 1.
    await tester.scrollUntilVisible(
      find.text('Êtes-vous en situation de handicap ?'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Type de handicap'), findsNothing);

    await tester.tap(find.text('Oui'));
    await tester.pumpAndSettle();

    // Le geste doit avoir un effet **avant** qu'un type soit choisi : c'est
    // exactement ce qui ne marchait pas.
    expect(find.text('Type de handicap'), findsOneWidget);
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
    expect(find.textContaining('Complétez l’étape'), findsOneWidget);
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
