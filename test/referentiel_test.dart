import 'package:flutter_test/flutter_test.dart';
import 'package:pgde_app/features/reference/data/reference_mock_api.dart';
import 'package:pgde_app/features/reference/domain/referentiel.dart';

void main() {
  late Referentiel referentiel;

  setUp(() async {
    referentiel = await MockReferenceApi().bootstrap();
  });

  test('les 15 régions et les 16 secteurs réels sont présents (§5.1, §5.4)', () {
    expect(referentiel.regions, hasLength(15));
    expect(referentiel.secteurs, hasLength(16));
    // Les ids de secteur ne sont pas contigus : 1→15 puis 19.
    expect(referentiel.secteurs.map((s) => s.id), contains(19));
    expect(referentiel.secteurs.map((s) => s.id), isNot(contains(16)));
  });

  test('les niveaux d’études suivent l’ordre imposé, pas l’id (§5.2)', () {
    final libelles = referentiel.academicsOrdonnes.map((a) => a.libelle).toList();

    expect(libelles.first, 'Doctorat'); // id 18, pourtant le dernier en base
    expect(libelles.last, 'sansdiplome'); // id 14, au milieu des ids
    expect(libelles, hasLength(referentiel.academics.length));
  });

  test('un niveau ajouté en base sans être classé reste visible', () {
    final augmente = referentiel.copyWith(
      academics: <Academic>[
        ...referentiel.academics,
        const Academic(id: 99, libelle: 'Nouveau niveau'),
      ],
    );
    expect(
      augmente.academicsOrdonnes.map((a) => a.id),
      contains(99),
    );
  });

  test('la région « Hors Sénégal » n’a aucun département (§5.1)', () {
    expect(referentiel.departementsDe(Region.horsSenegalId), isEmpty);
    expect(referentiel.departementsDe(1), isNotEmpty);
  });

  test('un vœu permet de retrouver son secteur (§4, étape 4)', () {
    // `userdata` ne stocke pas `secteur_id` : il faut le remonter depuis
    // l'emploi pour pré-sélectionner le secteur en édition.
    final secteur = referentiel.secteurDeLEmploi(12); // Développeur web
    expect(secteur?.id, 9);
    expect(secteur?.libelle, 'Informatique / Télécom / Téléservices');
    expect(referentiel.secteurDeLEmploi(999999), isNull);
  });

  test('le référentiel survit à un aller-retour JSON (cache local)', () {
    final recharge = Referentiel.fromJson(referentiel.toJson());
    expect(recharge, referentiel);
  });
}
