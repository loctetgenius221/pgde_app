import 'package:flutter_test/flutter_test.dart';
import 'package:pgde_app/features/demande/domain/demande.dart';
import 'package:pgde_app/features/demande/domain/wizard.dart';

void main() {
  group('Demande — complétude des étapes (§4)', () {
    const complete = Demande(
      lieuNaissance: 'Dakar',
      lieuResidence: 'Pikine',
      genre: Genre.masculin,
      telephone1: '+221770000000',
      emploi1Id: 12,
      emploi2Id: 45,
    );

    test("l'étape 1 exige les six champs obligatoires du serveur", () {
      final avecDate = complete.copyWith(dateNaissance: DateTime(1998, 4, 12));
      expect(avecDate.estComplete(EtapeWizard.identite), isTrue);

      // La date manque : le serveur refuserait la création.
      expect(complete.estComplete(EtapeWizard.identite), isFalse);
      // Un champ rempli d'espaces ne vaut pas un champ rempli.
      expect(
        avecDate.copyWith(telephone1: '   ').estComplete(EtapeWizard.identite),
        isFalse,
      );
    });

    test('deux vœux identiques ne valident pas l’étape 4 (§6.2 D9)', () {
      expect(complete.estComplete(EtapeWizard.voeux), isTrue);
      expect(
        complete.copyWith(emploi2Id: 12).estComplete(EtapeWizard.voeux),
        isFalse,
      );
      expect(
        complete.copyWith(emploi2Id: null).estComplete(EtapeWizard.voeux),
        isFalse,
      );
    });

    test('sans expérience déclarée, l’étape 3 est complète', () {
      expect(complete.estComplete(EtapeWizard.experiences), isTrue);
      expect(
        complete
            .copyWith(aDeLExperience: true)
            .estComplete(EtapeWizard.experiences),
        isFalse,
      );
    });
  });

  group('Demande — expériences réellement enregistrées (§4, étape 3)', () {
    test('une expérience sans poste, employeur ni description est écartée', () {
      const demande = Demande(
        aDeLExperience: true,
        experiences: <Experience>[
          Experience(poste: 'Stagiaire', employeur: 'ARTP', annees: 2),
          Experience(annees: 3), // que des années : le serveur la jette
        ],
      );
      expect(demande.experiencesRetenues, hasLength(1));
      expect(demande.experiencesRetenues.single.poste, 'Stagiaire');
    });

    test('répondre « non » vide la liste, comme le fait le serveur', () {
      const demande = Demande(
        experiences: <Experience>[Experience(poste: 'Stagiaire')],
      );
      expect(demande.experiencesRetenues, isEmpty);
    });
  });

  group('Demande — cas particuliers du référentiel', () {
    test('la région 15 bascule sur le choix du pays (§5.1)', () {
      expect(const Demande(regionResidenceId: 1).resideHorsSenegal, isFalse);
      expect(const Demande(regionResidenceId: 15).resideHorsSenegal, isTrue);
    });

    test('« sans diplôme » vaut 14, pas 20 (§6.1 B4)', () {
      expect(const Formation(academicId: 14).sansDiplome, isTrue);
      expect(const Formation(academicId: 20).sansDiplome, isFalse);
      expect(const Formation(academicId: 7).sansDiplome, isFalse);
    });
  });

  group('EtapeWizard.pourChamp — routage des erreurs 422 (§8.7)', () {
    test('associe un champ simple à son étape', () {
      expect(EtapeWizard.pourChamp('datenaiss'), EtapeWizard.identite);
      expect(EtapeWizard.pourChamp('cv_summary'), EtapeWizard.voeux);
    });

    test('normalise les clés indexées renvoyées par Laravel', () {
      expect(
        EtapeWizard.pourChamp('formations.0.academic_id'),
        EtapeWizard.formations,
      );
      expect(
        EtapeWizard.pourChamp('experiences.12.years'),
        EtapeWizard.experiences,
      );
    });

    test('rend null sur un champ inconnu plutôt que de deviner', () {
      expect(EtapeWizard.pourChamp('motivation'), isNull);
    });
  });
}
