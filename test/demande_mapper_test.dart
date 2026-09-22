import 'package:flutter_test/flutter_test.dart';
import 'package:pgde_app/features/demande/data/demande_mapper.dart';
import 'package:pgde_app/features/demande/domain/demande.dart';

void main() {
  final Demande complete = Demande(
    id: 1369020,
    dateNaissance: DateTime(1998, 4, 12),
    lieuNaissance: 'Dakar',
    lieuResidence: 'Pikine',
    adresse: 'Rue 12 x 15',
    genre: Genre.masculin,
    situationMatrimoniale: SituationMatrimoniale.celibataire,
    telephone1: '+221770000000',
    nombreEnfants: 2,
    regionNaissanceId: 1,
    departementNaissanceId: 1,
    regionResidenceId: 1,
    departementResidenceId: 2,
    handicapId: 3,
    formations: const <Formation>[
      Formation(
        academicId: 7,
        diplome: 'Baccalauréat S2',
        anneeDiplome: 2019,
        specialite: 'FINANCE',
        etablissement: 'ESTM',
      ),
    ],
    aDeLExperience: true,
    experiences: const <Experience>[
      Experience(poste: 'Stagiaire', employeur: 'ARTP', annees: 2),
    ],
    emploi1Id: 12,
    emploi2Id: 45,
    anneesExperience1: 2,
    resumeCv: 'Quelques lignes.',
  );

  group('Écriture — §7.7', () {
    test('la date part au format attendu par Laravel', () {
      expect(DemandeMapper.versCorps(complete)['datenaiss'], '1998-04-12');
    });

    test('les énumérations partent avec leur valeur exacte en base', () {
      final corps = DemandeMapper.versCorps(complete);
      // « Feminin » sans accent, sinon les filtres de l'administration
      // ne voient plus le candidat (§4).
      expect(corps['genre'], 'Masculin');
      expect(
        DemandeMapper.versCorps(
          complete.copyWith(genre: Genre.feminin),
        )['genre'],
        'Feminin',
      );
      expect(corps['situationmatrimoniale'], 'Célibataire');
    });

    test('« non » au handicap envoie handicap = "0" (§4)', () {
      expect(DemandeMapper.versCorps(complete)['handicap'], '1');
      expect(DemandeMapper.versCorps(complete)['handicap_id'], 3);

      final sansHandicap = DemandeMapper.versCorps(
        complete.copyWith(handicapId: null),
      );
      expect(sansHandicap['handicap'], '0');
      expect(sansHandicap['handicap_id'], isNull);
    });

    test('hasExperience vaut exactement "oui" ou "non" (§4, étape 3)', () {
      expect(DemandeMapper.versCorps(complete)['hasExperience'], 'oui');

      final sans = DemandeMapper.versCorps(
        complete.copyWith(aDeLExperience: false),
      );
      expect(sans['hasExperience'], 'non');
      // Le serveur remettrait tout à null de toute façon : on n'envoie rien.
      expect(sans['experiences'], isEmpty);
    });

    test('une expérience non significative n’est pas envoyée', () {
      final corps = DemandeMapper.versCorps(
        complete.copyWith(
          experiences: const <Experience>[
            Experience(poste: 'Stagiaire'),
            Experience(annees: 4), // ni poste, ni employeur, ni description
          ],
        ),
      );
      expect(corps['experiences'], hasLength(1));
    });

    test('« sans diplôme » n’envoie ni intitulé, ni année (§8.9)', () {
      final corps = DemandeMapper.versCorps(
        complete.copyWith(
          formations: const <Formation>[
            Formation(
              academicId: 14,
              diplome: 'résidu de saisie',
              anneeDiplome: 2010,
              specialite: 'résidu',
              etablissement: 'résidu',
            ),
          ],
        ),
      );
      final formation = (corps['formations']! as List<dynamic>).single
          as Map<String, dynamic>;
      expect(formation['academic_id'], 14);
      expect(formation['diplome'], '');
      expect(formation['anneediplome'], isNull);
      expect(formation['specialite'], '');
      expect(formation['etablissementdiplome'], '');
    });

    test('le dossier part toujours entier, contre le bloqueur D1', () {
      final corps = DemandeMapper.versCorps(complete);
      // Les deux listes que le serveur efface si elles manquent.
      expect(corps.containsKey('formations'), isTrue);
      expect(corps.containsKey('experiences'), isTrue);
      expect(corps.containsKey('hasExperience'), isTrue);
    });
  });

  group('Lecture — §7.6', () {
    test('résout les entités imbriquées en identifiants', () {
      final demande = DemandeMapper.depuisApi(<String, dynamic>{
        'id': 7,
        'identite': <String, dynamic>{
          'datenaiss': '1998-04-12',
          'genre': 'Feminin',
          'situationmatrimoniale': 'Marié(e)',
          'nombreenfant': 3,
          'telephone1': '770000000',
          'naissance': <String, dynamic>{
            'region': <String, dynamic>{'id': 1, 'libelle': 'Dakar'},
            'departement': <String, dynamic>{'id': 2, 'libelle': 'Pikine'},
          },
          'residence': <String, dynamic>{
            'region': <String, dynamic>{'id': 13, 'libelle': 'Thiès'},
          },
          'handicap': <String, dynamic>{'id': 4, 'libelle': 'Mélange'},
        },
        'has_experience': true,
        'experiences': <dynamic>[
          <String, dynamic>{'poste': 'Agent', 'years': '3'},
        ],
        'voeux': <String, dynamic>{
          'emploi1': <String, dynamic>{'id': 12, 'annees': 2},
        },
      });

      expect(demande.id, 7);
      expect(demande.genre, Genre.feminin);
      expect(demande.situationMatrimoniale, SituationMatrimoniale.marie);
      expect(demande.regionNaissanceId, 1);
      expect(demande.departementNaissanceId, 2);
      expect(demande.regionResidenceId, 13);
      expect(demande.departementResidenceId, isNull);
      expect(demande.handicapId, 4);
      expect(demande.emploi1Id, 12);
      expect(demande.anneesExperience1, 2);
      // §2.4 : les années arrivent castées en chaîne.
      expect(demande.experiences.single.annees, 3);
    });

    test('survit à une réponse incomplète sans lever', () {
      final demande = DemandeMapper.depuisApi(const <String, dynamic>{});
      expect(demande.id, isNull);
      expect(demande.formations, isEmpty);
      expect(demande.aDeLExperience, isFalse);
      expect(demande.nombreEnfants, 0);
    });
  });

  test('un dossier survit à l’aller-retour complet vers l’API', () {
    // C'est le test qui compte : ce qui ne survit pas ici sera perdu en
    // production, silencieusement.
    final corps = DemandeMapper.versCorps(complete);
    final relu = DemandeMapper.depuisApi(<String, dynamic>{
      'id': complete.id,
      'identite': <String, dynamic>{
        'datenaiss': corps['datenaiss'],
        'lieunaiss': corps['lieunaiss'],
        'lieuresidence': corps['lieuresidence'],
        'addresse': corps['addresse'],
        'genre': corps['genre'],
        'situationmatrimoniale': corps['situationmatrimoniale'],
        'telephone1': corps['telephone1'],
        'telephone2': corps['telephone2'],
        'nombreenfant': corps['nombreenfant'],
        'naissance': <String, dynamic>{
          'region': corps['regionnaiss_id'],
          'departement': corps['departementnaiss_id'],
        },
        'residence': <String, dynamic>{
          'region': corps['regionresidence_id'],
          'departement': corps['departementresidence_id'],
        },
        'handicap': corps['handicap_id'],
      },
      'formations': corps['formations'],
      'has_experience': corps['hasExperience'] == 'oui',
      'experiences': corps['experiences'],
      'voeux': <String, dynamic>{
        'emploi1': <String, dynamic>{
          'id': corps['emploi1_id'],
          'annees': corps['anneeexperience1'],
        },
        'emploi2': <String, dynamic>{
          'id': corps['emploi2_id'],
          'annees': corps['anneeexperience2'],
        },
      },
      'cv_summary': corps['cv_summary'],
    });

    expect(relu, complete);
  });
}
