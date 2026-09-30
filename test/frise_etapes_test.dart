import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pgde_app/core/theme/app_theme.dart';
import 'package:pgde_app/core/ui/frise_etapes.dart';
import 'package:pgde_app/features/demande/domain/demande.dart';
import 'package:pgde_app/features/demande/domain/wizard.dart';

Future<void> _poser(WidgetTester tester, List<ElementFrise> elements) async {
  tester.view
    ..physicalSize = const Size(400, 900)
    ..devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: SingleChildScrollView(child: FriseEtapes(elements: elements)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<ElementFrise> _quatreEtapes({required int franchies}) => <ElementFrise>[
  for (int i = 1; i <= 4; i++)
    ElementFrise(
      numero: i,
      titre: 'Étape $i',
      etat: i <= franchies
          ? EtatEtape.franchie
          : (i == franchies + 1 ? EtatEtape.enCours : EtatEtape.aVenir),
      statut: i <= franchies
          ? 'Complétée'
          : (i == franchies + 1 ? 'À remplir' : null),
    ),
];

void main() {
  group('Étape courante du dossier (§7.6)', () {
    test('c’est la première étape non complétée', () {
      // Identité et vœux remplis, formations et expériences non : la reprise
      // se fait aux formations, pas aux vœux déjà faits.
      final Demande partiel = Demande(
        dateNaissance: DateTime(1998, 4, 12),
        lieuNaissance: 'Dakar',
        lieuResidence: 'Pikine',
        genre: Genre.masculin,
        telephone1: '770000000',
        aDeLExperience: true, // étape 3 incomplète : aucune expérience saisie
        emploi1Id: 12,
        emploi2Id: 45,
      );
      expect(partiel.etapeCourante, EtapeWizard.formations);
    });

    test('null quand tout est complété', () {
      final Demande complet = Demande(
        dateNaissance: DateTime(1998, 4, 12),
        lieuNaissance: 'Dakar',
        lieuResidence: 'Pikine',
        genre: Genre.masculin,
        telephone1: '770000000',
        formations: const <Formation>[Formation(academicId: 7)],
        aDeLExperience: false,
        emploi1Id: 12,
        emploi2Id: 45,
      );
      expect(complet.etapeCourante, isNull);
    });
  });

  group('Frise', () {
    testWidgets('affiche un surtitre numéroté par étape', (tester) async {
      await _poser(tester, _quatreEtapes(franchies: 1));

      for (int i = 1; i <= 4; i++) {
        expect(find.text('ÉTAPE $i'), findsOneWidget);
      }
    });

    testWidgets('une seule étape porte « À remplir »', (tester) async {
      await _poser(tester, _quatreEtapes(franchies: 2));

      expect(find.text('Complétée'), findsNWidgets(2));
      // L'étape en cours est unique : c'est ce qui distingue une frise d'une
      // liste de cases à cocher.
      expect(find.text('À remplir'), findsOneWidget);
    });

    testWidgets('la dernière ligne ne porte pas de rail', (tester) async {
      await _poser(tester, _quatreEtapes(franchies: 4));

      // Trois segments pour quatre étapes : le rail relie, il ne dépasse pas.
      expect(
        find.byWidgetPredicate(
          (w) => w is Positioned && w.top == 34 && w.bottom == 0,
        ),
        findsNWidgets(3),
      );
    });

    testWidgets('chaque ligne est actionnable séparément', (tester) async {
      int? tapee;
      await _poser(tester, <ElementFrise>[
        for (int i = 1; i <= 3; i++)
          ElementFrise(
            numero: i,
            titre: 'Étape $i',
            etat: EtatEtape.aVenir,
            onTap: () => tapee = i,
          ),
      ]);

      await tester.tap(find.text('Étape 2'));
      expect(tapee, 2);
    });
  });
}
