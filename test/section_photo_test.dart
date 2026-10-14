import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pgde_app/core/theme/app_theme.dart';
import 'package:pgde_app/features/auth/application/auth_controller.dart';
import 'package:pgde_app/features/auth/domain/utilisateur.dart';
import 'package:pgde_app/features/demande/domain/demande.dart';
import 'package:pgde_app/features/demande/ui/etapes/pieces_jointes.dart';

/// Carte d'ouverture de l'étape Identité : qui remplit le dossier, et sa
/// photo d'identité.
Future<void> _afficher(WidgetTester tester, Demande demande) async {
  tester.view
    ..physicalSize = const Size(360, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        utilisateurConnecteProvider.overrideWithValue(
          const Utilisateur(
            id: 1,
            firstname: 'Aminata',
            lastname: 'Ndiaye Diallo',
            username: 'aminata',
            numberid: '1234567890123',
            email:'aminata.ndiaye.diallo@gmail.com',
            enabled: true,
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: SectionPhoto(demande: demande),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sans photo : identité complète et invitation à en ajouter une', (
    tester,
  ) async {
    await _afficher(tester, const Demande());

    expect(tester.takeException(), isNull);
    expect(find.text('Aminata Ndiaye Diallo'), findsOneWidget);
    expect(find.text('1234567890123'), findsOneWidget);
    expect(find.text('aminata.ndiaye.diallo@gmail.com'), findsOneWidget);
    expect(find.text('Ajouter une photo'), findsOneWidget);
    expect(find.text('Changer la photo'), findsNothing);
  });

  testWidgets('avec une photo déposée : on propose de la changer', (
    tester,
  ) async {
    await _afficher(
      tester,
      const Demande(
        photo: FichierJoint(
          chemin: 'uploads/photos/p.jpg',
          url: 'https://exemple.sn/uploads/photos/p.jpg',
        ),
      ),
    );

    expect(find.text('Changer la photo'), findsOneWidget);
    expect(find.text('Ajouter une photo'), findsNothing);
  });
}
