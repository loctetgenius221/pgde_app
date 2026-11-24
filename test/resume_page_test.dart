import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pgde_app/core/theme/app_theme.dart';
import 'package:pgde_app/features/auth/application/auth_controller.dart';
import 'package:pgde_app/features/auth/domain/utilisateur.dart';
import 'package:pgde_app/features/demande/application/demande_controller.dart';
import 'package:pgde_app/features/demande/domain/demande.dart';
import 'package:pgde_app/features/demande/ui/resume_page.dart';
import 'package:pgde_app/features/reference/data/reference_repository.dart';
import 'package:pgde_app/features/reference/domain/referentiel.dart';

const Referentiel _referentiel = Referentiel(
  regions: <Region>[Region(id: 1, libelle: 'Dakar')],
  departements: <Departement>[
    Departement(id: 1, libelle: 'Dakar', regionId: 1),
  ],
  academics: <Academic>[Academic(id: 9, libelle: 'BTS')],
  secteurs: <Secteur>[Secteur(id: 3, libelle: 'Informatique / Télécom')],
  emplois: <Emploi>[
    Emploi(
      id: 293,
      libelle: 'Technicien supérieur en informatique',
      secteurId: 3,
    ),
    Emploi(id: 487, libelle: 'Technicien analyste-programmeur', secteurId: 3),
  ],
);

final Demande _dossier = Demande(
  deposee: true,
  numeroDossier: 362323,
  dateNaissance: DateTime(2001),
  lieuNaissance: 'DAKAR',
  lieuResidence: 'Point E',
  genre: Genre.masculin,
  situationMatrimoniale: SituationMatrimoniale.celibataire,
  telephone1: '771234455',
  regionNaissanceId: 1,
  regionResidenceId: 1,
  departementResidenceId: 1,
  formations: const <Formation>[
    Formation(
      academicId: 9,
      diplome: 'BTS Informatique de gestion',
      anneeDiplome: 2025,
      etablissement: 'ISM',
      specialite: 'Développement',
    ),
  ],
  aDeLExperience: true,
  experiences: const <Experience>[
    Experience(
      poste: 'Développeur mobile',
      employeur: 'Docsen',
      annees: 1,
      description: 'Conception des interfaces.',
    ),
  ],
  emploi1Id: 293,
  emploi2Id: 487,
  anneesExperience1: 1,
  resumeCv: 'Ceci est un test effectué depuis l’application mobile.',
);

class _DossierFixe extends DemandeController {
  @override
  Future<Demande> build() async => _dossier;
}

Future<void> _afficher(WidgetTester tester, Size ecran) async {
  tester.view
    ..physicalSize = ecran
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        demandeControllerProvider.overrideWith(_DossierFixe.new),
        referentielProvider.overrideWith((ref) async => _referentiel),
        utilisateurConnecteProvider.overrideWithValue(
          const Utilisateur(
            id: 362323,
            firstname: 'Test',
            lastname: 'Mobile',
            username: 'test.mobile',
            numberid: '111111111111',
            email: 'test.mobile@exemple.sn',
            enabled: true,
          ),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const ResumePage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // Fait au démarrage de l'app par `main.dart`.
  setUpAll(() => initializeDateFormatting('fr_FR'));

  testWidgets('sur téléphone, le profil passe avant les coordonnées', (
    tester,
  ) async {
    // Écran haut : tous les blocs sont construits, sans défilement.
    await _afficher(tester, const Size(360, 3000));

    final double profil = tester.getTopLeft(find.text('Profil')).dy;
    final double coordonnees = tester.getTopLeft(find.text('Coordonnées')).dy;
    expect(profil, lessThan(coordonnees));
  });

  for (final (String nom, Size ecran) in const <(String, Size)>[
    ('téléphone', Size(360, 800)),
    ('tablette couchée', Size(1280, 800)),
  ]) {
    testWidgets('récapitulatif façon web sur $nom, sans débordement', (
      tester,
    ) async {
      await _afficher(tester, ecran);
      expect(tester.takeException(), isNull);

      // L'en-tête identifie le candidat et met son n° de dossier en avant.
      expect(find.text('Test Mobile'), findsOneWidget);
      expect(find.text('362323'), findsOneWidget);
      expect(find.text('Copier'), findsOneWidget);

      // Les rubriques de la page web, libellés résolus par le référentiel.
      await tester.scrollUntilVisible(
        find.text('Technicien analyste-programmeur'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Informatique / Télécom'), findsNWidgets(2));
      expect(find.text('Célibataire · 0 enfant'), findsOneWidget);
    });
  }

  testWidgets('« Copier » met le n° de dossier dans le presse-papiers', (
    tester,
  ) async {
    final List<MethodCall> appels = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (appel) async {
        appels.add(appel);
        return null;
      },
    );
    await _afficher(tester, const Size(360, 800));

    await tester.tap(find.text('Copier'));
    await tester.pump();

    final MethodCall copie = appels.firstWhere(
      (a) => a.method == 'Clipboard.setData',
    );
    expect((copie.arguments as Map)['text'], '362323');
    expect(find.text('N° de dossier copié.'), findsOneWidget);
  });
}
