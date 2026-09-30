import '../../../core/network/api_client.dart';
import '../domain/referentiel.dart';

/// Lecture de `GET /reference/all` (contrat §4).
///
/// **Le contrat énumère les routes de référence mais ne donne aucun exemple
/// de réponse.** Les noms de clés et de champs sont donc inconnus au moment
/// d'écrire ce code. Plutôt que de parier sur une orthographe et de casser au
/// premier appel réel, on accepte les variantes plausibles : `libelle`,
/// `nom`, `intitule` ou `label` pour un libellé ; `emplois` ou `metiers` pour
/// la liste des métiers.
///
/// Cette tolérance est **provisoire** : dès que le serveur répond, une trace
/// de la réponse réelle permettra de figer les clés et de supprimer les
/// variantes mortes. C'est le prix d'un client écrit avant son serveur, et il
/// est moins cher qu'un écran vide sans explication.
abstract final class ReferentielMapper {
  static Referentiel depuisApi(Json json) {
    // `/reference/all` peut aussi bien renvoyer les listes à la racine que
    // sous une clé de regroupement.
    final Json racine = _premierObjet(json, <String>[
      'references',
      'reference',
    ]) ?? json;

    return Referentiel(
      version: _texte(racine['version']),
      regions: _liste(racine, <String>['regions']).map(_region).toList(),
      departements: _liste(racine, <String>[
        'departements',
        'departments',
      ]).map(_departement).toList(),
      secteurs: _liste(racine, <String>[
        'secteurs',
        'sectors',
      ]).map(_secteur).toList(),
      emplois: _liste(racine, <String>[
        'emplois',
        'metiers',
        'jobs',
      ]).map(_emploi).toList(),
      academics: _liste(racine, <String>[
        'niveaux_formation',
        'niveaux-formation',
        'academics',
        'formations',
        'niveaux',
      ]).map(_academic).toList(),
      handicaps: _liste(racine, <String>[
        'handicaps',
      ]).map(_handicap).toList(),
      // Le contrat n'expose aucune route « pays » : la liste reste vide, et
      // l'écran d'identité masque le champ plutôt que d'ouvrir un sélecteur
      // sans contenu.
      countries: _liste(racine, <String>[
        'countries',
        'pays',
      ]).map(_pays).toList(),
    );
  }

  static Region _region(Json j) =>
      Region(id: _entier(j['id']) ?? 0, libelle: _libelle(j));

  static Departement _departement(Json j) => Departement(
    id: _entier(j['id']) ?? 0,
    libelle: _libelle(j),
    regionId: _entier(j['region_id'] ?? j['regionId']) ?? 0,
  );

  static Secteur _secteur(Json j) =>
      Secteur(id: _entier(j['id']) ?? 0, libelle: _libelle(j));

  static Emploi _emploi(Json j) => Emploi(
    id: _entier(j['id']) ?? 0,
    libelle: _libelle(j),
    secteurId: _entier(j['secteur_id'] ?? j['sector_id'] ?? j['secteurId']) ?? 0,
  );

  static Academic _academic(Json j) =>
      Academic(id: _entier(j['id']) ?? 0, libelle: _libelle(j));

  static Handicap _handicap(Json j) =>
      Handicap(id: _entier(j['id']) ?? 0, libelle: _libelle(j));

  static Pays _pays(Json j) => Pays(id: _entier(j['id']) ?? 0, name: _libelle(j));

  /// Libellé d'une entité, quelle que soit la colonne qui le porte.
  static String _libelle(Json j) {
    for (final String cle in const <String>[
      'libelle',
      'nom',
      'intitule',
      'label',
      'name',
      'academic_label',
      'title',
    ]) {
      final Object? valeur = j[cle];
      if (valeur is String && valeur.trim().isNotEmpty) return valeur;
    }
    return '';
  }

  static Json? _premierObjet(Json json, List<String> cles) {
    for (final String cle in cles) {
      final Object? valeur = json[cle];
      if (valeur is Map) return valeur.cast<String, dynamic>();
    }
    return null;
  }

  static List<Json> _liste(Json json, List<String> cles) {
    for (final String cle in cles) {
      final Object? valeur = json[cle];
      if (valeur is List) {
        return valeur
            .whereType<Map<dynamic, dynamic>>()
            .map((m) => m.cast<String, dynamic>())
            .toList();
      }
    }
    return const <Json>[];
  }

  static String _texte(Object? valeur) => valeur?.toString() ?? '';

  static int? _entier(Object? valeur) => switch (valeur) {
    final int n => n,
    final num n => n.toInt(),
    final String s => int.tryParse(s.trim()),
    _ => null,
  };
}
