// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'referentiel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Region _$RegionFromJson(Map<String, dynamic> json) => _Region(
  id: (json['id'] as num).toInt(),
  libelle: json['libelle'] as String,
);

Map<String, dynamic> _$RegionToJson(_Region instance) => <String, dynamic>{
  'id': instance.id,
  'libelle': instance.libelle,
};

_Departement _$DepartementFromJson(Map<String, dynamic> json) => _Departement(
  id: (json['id'] as num).toInt(),
  libelle: json['libelle'] as String,
  regionId: (json['region_id'] as num).toInt(),
);

Map<String, dynamic> _$DepartementToJson(_Departement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'libelle': instance.libelle,
      'region_id': instance.regionId,
    };

_Secteur _$SecteurFromJson(Map<String, dynamic> json) => _Secteur(
  id: (json['id'] as num).toInt(),
  libelle: json['libelle'] as String,
);

Map<String, dynamic> _$SecteurToJson(_Secteur instance) => <String, dynamic>{
  'id': instance.id,
  'libelle': instance.libelle,
};

_Emploi _$EmploiFromJson(Map<String, dynamic> json) => _Emploi(
  id: (json['id'] as num).toInt(),
  libelle: json['libelle'] as String,
  secteurId: (json['secteur_id'] as num).toInt(),
);

Map<String, dynamic> _$EmploiToJson(_Emploi instance) => <String, dynamic>{
  'id': instance.id,
  'libelle': instance.libelle,
  'secteur_id': instance.secteurId,
};

_Academic _$AcademicFromJson(Map<String, dynamic> json) => _Academic(
  id: (json['id'] as num).toInt(),
  libelle: json['libelle'] as String,
);

Map<String, dynamic> _$AcademicToJson(_Academic instance) => <String, dynamic>{
  'id': instance.id,
  'libelle': instance.libelle,
};

_Handicap _$HandicapFromJson(Map<String, dynamic> json) => _Handicap(
  id: (json['id'] as num).toInt(),
  libelle: json['libelle'] as String,
);

Map<String, dynamic> _$HandicapToJson(_Handicap instance) => <String, dynamic>{
  'id': instance.id,
  'libelle': instance.libelle,
};

_Pays _$PaysFromJson(Map<String, dynamic> json) =>
    _Pays(id: (json['id'] as num).toInt(), name: json['name'] as String);

Map<String, dynamic> _$PaysToJson(_Pays instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
};

_Referentiel _$ReferentielFromJson(Map<String, dynamic> json) => _Referentiel(
  version: json['version'] as String,
  regions:
      (json['regions'] as List<dynamic>?)
          ?.map((e) => Region.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Region>[],
  departements:
      (json['departements'] as List<dynamic>?)
          ?.map((e) => Departement.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Departement>[],
  secteurs:
      (json['secteurs'] as List<dynamic>?)
          ?.map((e) => Secteur.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Secteur>[],
  emplois:
      (json['emplois'] as List<dynamic>?)
          ?.map((e) => Emploi.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Emploi>[],
  academics:
      (json['academics'] as List<dynamic>?)
          ?.map((e) => Academic.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Academic>[],
  handicaps:
      (json['handicaps'] as List<dynamic>?)
          ?.map((e) => Handicap.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Handicap>[],
  countries:
      (json['countries'] as List<dynamic>?)
          ?.map((e) => Pays.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Pays>[],
);

Map<String, dynamic> _$ReferentielToJson(_Referentiel instance) =>
    <String, dynamic>{
      'version': instance.version,
      'regions': instance.regions.map((e) => e.toJson()).toList(),
      'departements': instance.departements.map((e) => e.toJson()).toList(),
      'secteurs': instance.secteurs.map((e) => e.toJson()).toList(),
      'emplois': instance.emplois.map((e) => e.toJson()).toList(),
      'academics': instance.academics.map((e) => e.toJson()).toList(),
      'handicaps': instance.handicaps.map((e) => e.toJson()).toList(),
      'countries': instance.countries.map((e) => e.toJson()).toList(),
    };
