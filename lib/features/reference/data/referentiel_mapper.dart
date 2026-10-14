import '../../../core/network/api_client.dart';
import '../domain/referentiel.dart';

/// Lecture de `GET /reference/all` (contrat §4).
///
/// Les objets portent `id` et `libelle`. Les départements peuvent arriver
/// imbriqués dans chaque région, les emplois dans chaque secteur : on
/// aplatit pour le modèle local, qui travaille par listes plates.
abstract final class ReferentielMapper {
  static Referentiel depuisApi(Json json) {
    final List<Json> regions = _liste(json, 'regions');
    final List<Json> secteurs = _liste(json, 'secteurs');
    final List<Json> emploisNids = <Json>[
      for (final Json secteur in secteurs) ..._liste(secteur, 'emplois'),
    ];
    final List<Json> emplois = <Json>[
      ..._liste(json, 'emplois'),
      ...emploisNids.where((e) => !_dejaPresent(_liste(json, 'emplois'), e)),
    ];

    return Referentiel(
      version: json['version']?.toString() ?? '',
      regions: regions.map(_region).toList(),
      departements: _uniques(<Departement>[
        ..._liste(json, 'departements').map(_departement),
        for (final Json region in regions)
          ..._liste(
            region,
            'departements',
          ).map((d) => _departement(d, regionId: _entier(region['id']))),
      ]),
      secteurs: secteurs.map(_secteur).toList(),
      emplois: _uniques(emplois.map(_emploi)),
      academics: _niveaux(json).map(_academic).toList(),
      handicaps: _liste(json, 'handicaps').map(_handicap).toList(),
    );
  }

  static List<Json> _niveaux(Json json) {
    for (final String cle in const <String>[
      'niveaux_formation',
      'niveaux-formation',
      'academics',
    ]) {
      final List<Json> liste = _liste(json, cle);
      if (liste.isNotEmpty) return liste;
    }
    return const <Json>[];
  }

  static Region _region(Json j) =>
      Region(id: _entier(j['id']) ?? 0, libelle: _libelle(j));

  static Departement _departement(Json j, {int? regionId}) => Departement(
    id: _entier(j['id']) ?? 0,
    libelle: _libelle(j),
    regionId: _entier(j['region_id']) ?? regionId ?? 0,
  );

  static Secteur _secteur(Json j) =>
      Secteur(id: _entier(j['id']) ?? 0, libelle: _libelle(j));

  static Emploi _emploi(Json j) => Emploi(
    id: _entier(j['id']) ?? 0,
    libelle: _libelle(j),
    secteurId: _entier(j['secteur_id']) ?? 0,
  );

  static Academic _academic(Json j) =>
      Academic(id: _entier(j['id']) ?? 0, libelle: _libelle(j));

  static Handicap _handicap(Json j) =>
      Handicap(id: _entier(j['id']) ?? 0, libelle: _libelle(j));

  static String _libelle(Json j) =>
      (j['libelle'] ?? j['name'] ?? '').toString();

  static List<T> _uniques<T>(Iterable<T> items) {
    final List<T> uniques = <T>[];
    final Set<int> vus = <int>{};
    for (final T item in items) {
      final int id = switch (item) {
        final Departement d => d.id,
        final Emploi e => e.id,
        _ => uniques.length,
      };
      if (vus.add(id)) uniques.add(item);
    }
    return uniques;
  }

  static bool _dejaPresent(List<Json> liste, Json candidat) {
    final int? id = _entier(candidat['id']);
    if (id == null) return false;
    return liste.any((e) => _entier(e['id']) == id);
  }

  static List<Json> _liste(Json json, String cle) {
    final Object? valeur = json[cle];
    if (valeur is! List) return const <Json>[];
    return valeur
        .whereType<Map<dynamic, dynamic>>()
        .map((m) => m.cast<String, dynamic>())
        .toList();
  }

  static int? _entier(Object? valeur) => switch (valeur) {
    final int n => n,
    final num n => n.toInt(),
    final String s => int.tryParse(s.trim()),
    _ => null,
  };
}
