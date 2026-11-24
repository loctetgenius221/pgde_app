import 'package:freezed_annotation/freezed_annotation.dart';

part 'referentiel.freezed.dart';
part 'referentiel.g.dart';

@freezed
abstract class Region with _$Region {
  const factory Region({required int id, required String libelle}) = _Region;

  factory Region.fromJson(Map<String, dynamic> json) => _$RegionFromJson(json);

  /// §5.1 — la région 15 n'a aucun département : elle ouvre le choix du pays.
  static const int horsSenegalId = 15;
}

@freezed
abstract class Departement with _$Departement {
  const factory Departement({
    required int id,
    required String libelle,
    @JsonKey(name: 'region_id') required int regionId,
  }) = _Departement;

  factory Departement.fromJson(Map<String, dynamic> json) =>
      _$DepartementFromJson(json);
}

@freezed
abstract class Secteur with _$Secteur {
  const factory Secteur({required int id, required String libelle}) = _Secteur;

  factory Secteur.fromJson(Map<String, dynamic> json) =>
      _$SecteurFromJson(json);
}

@freezed
abstract class Emploi with _$Emploi {
  const factory Emploi({
    required int id,
    required String libelle,
    @JsonKey(name: 'secteur_id') required int secteurId,
  }) = _Emploi;

  factory Emploi.fromJson(Map<String, dynamic> json) => _$EmploiFromJson(json);
}

@freezed
abstract class Academic with _$Academic {
  const factory Academic({required int id, required String libelle}) =
      _Academic;

  factory Academic.fromJson(Map<String, dynamic> json) =>
      _$AcademicFromJson(json);

  /// « Sans diplôme ».
  ///
  /// Le contrat §5.3 accepte `academic_id: "sansdiplome"` **ou** `20`, là où
  /// l'analyse de la base donnait **14** (l'id 20 y était une clé étrangère
  /// morte). Les deux sont donc reconnus en lecture, et l'écriture passe par
  /// la chaîne `"sansdiplome"` : c'est la seule forme que les deux versions
  /// du serveur interprètent identiquement.
  static const int sansDiplomeId = 14;

  /// L'autre identifiant admis par le contrat pour « sans diplôme ».
  static const int sansDiplomeIdContrat = 20;

  /// Valeur envoyée au serveur pour « sans diplôme » (§5.3).
  static const String sansDiplomeWire = 'sansdiplome';

  static bool estSansDiplome(int id) =>
      id == sansDiplomeId || id == sansDiplomeIdContrat;

  /// §5.2 — la table n'est ni ordonnée ni contiguë. L'ordre d'affichage est
  /// imposé ici, jamais déduit de l'id.
  static const List<int> ordreAffichage = <int>[
    18, // Doctorat
    1, // Supérieur à BAC+5
    2, // Master 2
    3, // Master 1
    4, // Licence
    9, // BTS
    8, // DTS
    5, // BAC+2
    6, // BAC+1
    7, // BAC
    17, // BT
    16, // CAP
    10, // BFEM
    15, // CFEE
    14, // sansdiplome
  ];
}

@freezed
abstract class Handicap with _$Handicap {
  const factory Handicap({required int id, required String libelle}) =
      _Handicap;

  factory Handicap.fromJson(Map<String, dynamic> json) =>
      _$HandicapFromJson(json);
}

@freezed
abstract class Pays with _$Pays {
  const factory Pays({required int id, required String name}) = _Pays;

  factory Pays.fromJson(Map<String, dynamic> json) => _$PaysFromJson(json);
}

/// Nomenclatures complètes, récupérées en un appel (§7.3 `/ref/bootstrap`).
///
/// ~700 lignes quasi statiques : l'app les charge une fois, les garde en
/// mémoire et les persiste en cache pour fonctionner hors ligne (§5.6).
@freezed
abstract class Referentiel with _$Referentiel {
  const factory Referentiel({
    /// Absente du contrat v1 : vide tant que le serveur n'en publie pas.
    /// Elle sert au cache local, qui doit savoir se périmer.
    @Default('') String version,
    @Default(<Region>[]) List<Region> regions,
    @Default(<Departement>[]) List<Departement> departements,
    @Default(<Secteur>[]) List<Secteur> secteurs,
    @Default(<Emploi>[]) List<Emploi> emplois,
    @Default(<Academic>[]) List<Academic> academics,
    @Default(<Handicap>[]) List<Handicap> handicaps,
    @Default(<Pays>[]) List<Pays> countries,
  }) = _Referentiel;

  const Referentiel._();

  factory Referentiel.fromJson(Map<String, dynamic> json) =>
      _$ReferentielFromJson(json);

  /// Cascade région -> département (§8.9).
  List<Departement> departementsDe(int regionId) =>
      departements.where((d) => d.regionId == regionId).toList();

  /// Cascade secteur -> emploi. 491 emplois : le sélecteur doit être
  /// recherchable, pas un simple `DropdownButton` (§8.9).
  List<Emploi> emploisDe(int secteurId) =>
      emplois.where((e) => e.secteurId == secteurId).toList();

  /// Remonte le secteur d'un emploi, nécessaire pour réafficher un vœu
  /// existant : `userdata` ne stocke pas `secteur_id` (§4, étape 4).
  Secteur? secteurDeLEmploi(int emploiId) {
    final emploi = emploiParId(emploiId);
    if (emploi == null) return null;
    for (final secteur in secteurs) {
      if (secteur.id == emploi.secteurId) return secteur;
    }
    return null;
  }

  Emploi? emploiParId(int id) {
    for (final emploi in emplois) {
      if (emploi.id == id) return emploi;
    }
    return null;
  }

  /// Niveaux d'études dans l'ordre d'affichage imposé (§5.2).
  List<Academic> get academicsOrdonnes {
    final parId = {for (final a in academics) a.id: a};
    return <Academic>[
      for (final id in Academic.ordreAffichage)
        if (parId[id] case final Academic a) a,
      // Tout niveau ajouté en base sans être classé ici reste visible.
      ...academics.where((a) => !Academic.ordreAffichage.contains(a.id)),
    ];
  }
}
