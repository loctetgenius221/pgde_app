import 'package:flutter_test/flutter_test.dart';
import 'package:pgde_app/core/network/api_client.dart';
import 'package:pgde_app/features/demande/data/demande_mapper.dart';
import 'package:pgde_app/features/demande/domain/demande.dart';
import 'package:pgde_app/features/reference/domain/referentiel.dart';

/// Un dossier rempli, tel que le wizard le produit.
final Demande _dossier = Demande(
  dateNaissance: DateTime(1998, 5, 14),
  lieuNaissance: 'Dakar',
  lieuResidence: 'Sénégal',
  adresse: 'Médina Rue 6',
  genre: Genre.masculin,
  situationMatrimoniale: SituationMatrimoniale.celibataire,
  telephone1: '771234567',
  telephone2: '701234567',
  nombreEnfants: 2,
  regionNaissanceId: 1,
  departementNaissanceId: 3,
  regionResidenceId: 1,
  departementResidenceId: 3,
  aUnHandicap: true,
  handicapId: 4,
  formations: const <Formation>[
    Formation(
      academicId: 4,
      diplome: 'Licence en Informatique',
      anneeDiplome: 2022,
      specialite: 'Génie Logiciel',
      etablissement: 'UCAD',
    ),
  ],
  aDeLExperience: true,
  experiences: const <Experience>[
    Experience(
      poste: 'Développeur Mobile',
      employeur: 'Tech Solutions SN',
      description: 'Flutter',
      annees: 2,
    ),
  ],
  emploi1Id: 12,
  emploi2Id: 15,
  anneesExperience1: 2,
  anneesExperience2: 1,
  resumeCv: 'Développeur mobile.',
);

void main() {
  group('Écriture — quatre corps, un par étape (§5.2 à §5.5)', () {
    test('l’identité part à plat, avec un vrai booléen de handicap', () {
      final Json corps = DemandeMapper.identite(_dossier);

      expect(corps['datenaiss'], '1998-05-14');
      expect(corps['genre'], 'Masculin');
      expect(corps['regionnaiss_id'], 1);
      expect(corps['departementresidence_id'], 3);
      // §5.2 : un booléen, là où le formulaire web envoyait la chaîne « 0 ».
      expect(corps['has_handicap'], isTrue);
      expect(corps['handicap_id'], 4);
      // Aucun `country_id` : le contrat v1 n'en a pas.
      expect(corps.containsKey('country_id'), isFalse);
    });

    test('répondre « non » au handicap efface le type', () {
      final Json corps = DemandeMapper.identite(
        _dossier.copyWith(aUnHandicap: false),
      );
      expect(corps['has_handicap'], isFalse);
      expect(corps['handicap_id'], isNull);
    });

    test('chaque corps n’emporte que sa propre étape', () {
      // C'est l'apport du découpage : enregistrer les vœux ne peut plus
      // effacer les formations, ce qui était le risque du PUT global.
      expect(DemandeMapper.identite(_dossier).containsKey('formations'), false);
      expect(DemandeMapper.voeux(_dossier).containsKey('experiences'), false);
      expect(
        DemandeMapper.formations(_dossier).containsKey('emploi1_id'),
        isFalse,
      );
    });

    test('« sans diplôme » part en toutes lettres et vide les champs', () {
      final Json corps = DemandeMapper.formations(
        _dossier.copyWith(
          formations: const <Formation>[
            Formation(academicId: Academic.sansDiplomeId, diplome: 'Résidu'),
          ],
        ),
      );
      final Json formation = (corps['formations']! as List).single as Json;

      // §5.3 accepte « sansdiplome », 20 ou 14 : la chaîne est la seule
      // forme que toutes les versions du serveur lisent pareil.
      expect(formation['academic_id'], Academic.sansDiplomeWire);
      expect(formation['diplome'], isNull);
      expect(formation['anneediplome'], isNull);
      expect(formation['etablissementdiplome'], isNull);
    });

    test('un justificatif déjà déposé est rappelé au serveur', () {
      final Json corps = DemandeMapper.formations(
        _dossier.copyWith(
          formations: <Formation>[
            _dossier.formations.first.copyWith(
              justificatif: const FichierJoint(
                chemin: 'uploads/diplomes/1_licence.pdf',
                url: 'http://x/1_licence.pdf',
              ),
            ),
          ],
        ),
      );
      final Json formation = (corps['formations']! as List).single as Json;

      // §5.3 — sans ce rappel, le fichier serait perdu à la prochaine
      // modification de la formation.
      expect(formation['existing_diplome_file'], 'uploads/diplomes/1_licence.pdf');
    });

    test('une formation sans justificatif n’envoie pas la clé', () {
      final Json corps = DemandeMapper.formations(_dossier);
      final Json formation = (corps['formations']! as List).single as Json;
      expect(formation.containsKey('existing_diplome_file'), isFalse);
    });

    test('hasExperience vaut « oui » ou « non », jamais un booléen', () {
      expect(DemandeMapper.experiences(_dossier)['hasExperience'], 'oui');
      expect(
        DemandeMapper.experiences(
          _dossier.copyWith(aDeLExperience: false),
        )['hasExperience'],
        'non',
      );
      // Sans réponse, on n'invente pas un « oui ».
      expect(
        DemandeMapper.experiences(
          _dossier.copyWith(aDeLExperience: null),
        )['hasExperience'],
        'non',
      );
    });

    test('répondre « non » vide la liste, comme le fait le serveur', () {
      final Json corps = DemandeMapper.experiences(
        _dossier.copyWith(aDeLExperience: false),
      );
      expect(corps['experiences'], isEmpty);
    });
  });

  group('Lecture — GET /candidat/profile (§5.1)', () {
    /// La réponse telle que le contrat la documente, `data` déjà déballé.
    final Json reponse = <String, dynamic>{
      'identity': <String, dynamic>{
        'telephone1': '771234567',
        'telephone2': null,
        'genre': 'Masculin',
        'datenaiss': '1998-05-14',
        'lieunaiss': 'Dakar',
        'situationmatrimoniale': 'Célibataire',
        'nombreenfant': 0,
        'lieuresidence': 'Sénégal',
        'addresse': 'Médina Rue 6',
        'region_naissance': <String, dynamic>{'id': 1, 'nom': 'Dakar'},
        'departement_naissance': <String, dynamic>{'id': 1, 'nom': 'Dakar'},
        'region_residence': <String, dynamic>{'id': 1, 'nom': 'Dakar'},
        'departement_residence': <String, dynamic>{'id': 1, 'nom': 'Dakar'},
        'handicap': null,
        'photo_profil_url': 'http://127.0.0.1:8000/uploads/photos/p.jpg',
      },
      'formations': <dynamic>[
        <String, dynamic>{
          'id': 1,
          'academic_id': 5,
          'academic_label': 'Licence',
          'is_sans_diplome': false,
          'diplome': 'Licence en Informatique',
          // Le serveur renvoie l'année en **chaîne**.
          'anneediplome': '2022',
          'specialite': 'Génie Logiciel',
          'etablissementdiplome': 'UCAD',
          'diplome_file_url': 'http://127.0.0.1:8000/uploads/diplomes/1_d.pdf',
          'diplome_file_name': '1727175260_diplome.pdf',
        },
      ],
      'experiences': <dynamic>[
        <String, dynamic>{
          'id': 1,
          'poste': 'Développeur Mobile',
          'employeur': 'Tech Solutions SN',
          'years': 2,
          'description': 'Flutter',
        },
      ],
      'target_jobs': <String, dynamic>{
        'emploi1': <String, dynamic>{'id': 12, 'intitule': 'Développeur'},
        'emploi2': <String, dynamic>{'id': 15, 'intitule': 'Administrateur'},
        'anneeexperience1': 2,
        'anneeexperience2': 1,
        'cv_summary': 'Développeur passionné.',
        'cv_files': <dynamic>[
          <String, dynamic>{
            'file_url': 'http://127.0.0.1:8000/uploads/cv/1_cv.pdf',
            'file_name': '1727175260_cv.pdf',
          },
        ],
      },
      'progression': <String, dynamic>{'is_completed': true, 'percentage': 100},
    };

    test('les entités résolues sont réduites à leur identifiant', () {
      final Demande d = DemandeMapper.depuisApi(reponse);

      expect(d.regionNaissanceId, 1);
      expect(d.departementResidenceId, 1);
      expect(d.emploi1Id, 12);
      expect(d.emploi2Id, 15);
      expect(d.genre, Genre.masculin);
      expect(d.situationMatrimoniale, SituationMatrimoniale.celibataire);
      expect(d.dateNaissance, DateTime(1998, 5, 14));
    });

    test('recevoir un profil suffit à savoir le dossier déposé', () {
      // Les quatre écritures sont des PUT idempotents : il n'y a plus de
      // création à distinguer d'une mise à jour, et donc plus d'identifiant
      // à guetter.
      expect(DemandeMapper.depuisApi(reponse).existeSurLeServeur, isTrue);
      expect(const Demande().existeSurLeServeur, isFalse);
    });

    test('le handicap absent vaut « non »', () {
      final Demande d = DemandeMapper.depuisApi(reponse);
      expect(d.aUnHandicap, isFalse);
      expect(d.handicapId, isNull);

      final Json avec = Json.from(reponse);
      avec['identity'] = <String, dynamic>{
        ...reponse['identity']! as Json,
        'handicap': <String, dynamic>{'id': 4, 'nom': 'Moteur'},
      };
      final Demande porteur = DemandeMapper.depuisApi(avec);
      expect(porteur.aUnHandicap, isTrue);
      expect(porteur.handicapId, 4);
    });

    test('chaque formation revient avec son justificatif', () {
      final Formation f = DemandeMapper.depuisApi(reponse).formations.single;

      expect(f.diplome, 'Licence en Informatique');
      // L'année est castée : le serveur l'envoie en chaîne.
      expect(f.anneeDiplome, 2022);
      expect(f.justificatif, isNotNull);
      expect(f.justificatif!.nom, '1727175260_diplome.pdf');
      expect(f.justificatif!.url, contains('uploads/diplomes'));
    });

    test('« sans diplôme » est reconnu sous ses trois formes', () {
      for (final Object forme in <Object>[
        'sansdiplome',
        Academic.sansDiplomeIdContrat,
        Academic.sansDiplomeId,
      ]) {
        final Json avec = Json.from(reponse);
        avec['formations'] = <dynamic>[
          <String, dynamic>{'academic_id': forme},
        ];
        expect(
          DemandeMapper.depuisApi(avec).formations.single.sansDiplome,
          isTrue,
          reason: '$forme',
        );
      }
    });

    test('le CV déposé reste lisible', () {
      final Demande d = DemandeMapper.depuisApi(reponse);
      expect(d.cv, hasLength(1));
      expect(d.cv.single.nom, '1727175260_cv.pdf');
    });

    test('une liste d’expériences pleine vaut « oui »', () {
      // §5.1 ne renvoie **pas** `hasExperience` : seule la liste revient.
      expect(DemandeMapper.depuisApi(reponse).aDeLExperience, isTrue);

      final Json sans = Json.from(reponse);
      sans['experiences'] = const <dynamic>[];
      // Une liste vide reste ambiguë : « non » et « pas encore répondu » s'y
      // confondent. On ne tranche pas à la place du candidat.
      expect(DemandeMapper.depuisApi(sans).aDeLExperience, isNull);
    });

    test('une réponse vide ne fait pas tomber la lecture', () {
      final Demande d = DemandeMapper.depuisApi(const <String, dynamic>{});
      expect(d.formations, isEmpty);
      expect(d.telephone1, '');
      expect(d.photo, isNull);
    });
  });
}
