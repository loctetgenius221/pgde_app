// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'demande.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FichierJoint _$FichierJointFromJson(Map<String, dynamic> json) =>
    _FichierJoint(
      chemin: json['chemin'] as String,
      url: json['url'] as String,
      nom: json['nom'] as String? ?? '',
      taille: (json['taille'] as num?)?.toInt(),
    );

Map<String, dynamic> _$FichierJointToJson(_FichierJoint instance) =>
    <String, dynamic>{
      'chemin': instance.chemin,
      'url': instance.url,
      'nom': instance.nom,
      'taille': instance.taille,
    };

_Formation _$FormationFromJson(Map<String, dynamic> json) => _Formation(
  academicId: (json['academicId'] as num).toInt(),
  diplome: json['diplome'] as String? ?? '',
  anneeDiplome: (json['anneeDiplome'] as num?)?.toInt(),
  specialite: json['specialite'] as String? ?? '',
  etablissement: json['etablissement'] as String? ?? '',
);

Map<String, dynamic> _$FormationToJson(_Formation instance) =>
    <String, dynamic>{
      'academicId': instance.academicId,
      'diplome': instance.diplome,
      'anneeDiplome': instance.anneeDiplome,
      'specialite': instance.specialite,
      'etablissement': instance.etablissement,
    };

_Experience _$ExperienceFromJson(Map<String, dynamic> json) => _Experience(
  poste: json['poste'] as String? ?? '',
  employeur: json['employeur'] as String? ?? '',
  description: json['description'] as String? ?? '',
  annees: (json['annees'] as num?)?.toInt(),
);

Map<String, dynamic> _$ExperienceToJson(_Experience instance) =>
    <String, dynamic>{
      'poste': instance.poste,
      'employeur': instance.employeur,
      'description': instance.description,
      'annees': instance.annees,
    };

_Demande _$DemandeFromJson(Map<String, dynamic> json) => _Demande(
  id: (json['id'] as num?)?.toInt(),
  dateNaissance: const DateOnlyConverter().fromJson(
    json['dateNaissance'] as String?,
  ),
  lieuNaissance: json['lieuNaissance'] as String? ?? '',
  lieuResidence: json['lieuResidence'] as String? ?? '',
  adresse: json['adresse'] as String? ?? '',
  genre: $enumDecodeNullable(_$GenreEnumMap, json['genre']),
  situationMatrimoniale: $enumDecodeNullable(
    _$SituationMatrimonialeEnumMap,
    json['situationMatrimoniale'],
  ),
  telephone1: json['telephone1'] as String? ?? '',
  telephone2: json['telephone2'] as String? ?? '',
  nombreEnfants: (json['nombreEnfants'] as num?)?.toInt() ?? 0,
  paysId: (json['paysId'] as num?)?.toInt(),
  regionNaissanceId: (json['regionNaissanceId'] as num?)?.toInt(),
  departementNaissanceId: (json['departementNaissanceId'] as num?)?.toInt(),
  regionResidenceId: (json['regionResidenceId'] as num?)?.toInt(),
  departementResidenceId: (json['departementResidenceId'] as num?)?.toInt(),
  handicapId: (json['handicapId'] as num?)?.toInt(),
  formations:
      (json['formations'] as List<dynamic>?)
          ?.map((e) => Formation.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Formation>[],
  diplomes:
      (json['diplomes'] as List<dynamic>?)
          ?.map((e) => FichierJoint.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <FichierJoint>[],
  cv:
      (json['cv'] as List<dynamic>?)
          ?.map((e) => FichierJoint.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <FichierJoint>[],
  photo: json['photo'] == null
      ? null
      : FichierJoint.fromJson(json['photo'] as Map<String, dynamic>),
  aDeLExperience: json['aDeLExperience'] as bool? ?? false,
  experiences:
      (json['experiences'] as List<dynamic>?)
          ?.map((e) => Experience.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Experience>[],
  emploi1Id: (json['emploi1Id'] as num?)?.toInt(),
  emploi2Id: (json['emploi2Id'] as num?)?.toInt(),
  anneesExperience1: (json['anneesExperience1'] as num?)?.toInt() ?? 0,
  anneesExperience2: (json['anneesExperience2'] as num?)?.toInt() ?? 0,
  resumeCv: json['resumeCv'] as String? ?? '',
);

Map<String, dynamic> _$DemandeToJson(_Demande instance) => <String, dynamic>{
  'id': instance.id,
  'dateNaissance': const DateOnlyConverter().toJson(instance.dateNaissance),
  'lieuNaissance': instance.lieuNaissance,
  'lieuResidence': instance.lieuResidence,
  'adresse': instance.adresse,
  'genre': _$GenreEnumMap[instance.genre],
  'situationMatrimoniale':
      _$SituationMatrimonialeEnumMap[instance.situationMatrimoniale],
  'telephone1': instance.telephone1,
  'telephone2': instance.telephone2,
  'nombreEnfants': instance.nombreEnfants,
  'paysId': instance.paysId,
  'regionNaissanceId': instance.regionNaissanceId,
  'departementNaissanceId': instance.departementNaissanceId,
  'regionResidenceId': instance.regionResidenceId,
  'departementResidenceId': instance.departementResidenceId,
  'handicapId': instance.handicapId,
  'formations': instance.formations.map((e) => e.toJson()).toList(),
  'diplomes': instance.diplomes.map((e) => e.toJson()).toList(),
  'cv': instance.cv.map((e) => e.toJson()).toList(),
  'photo': instance.photo?.toJson(),
  'aDeLExperience': instance.aDeLExperience,
  'experiences': instance.experiences.map((e) => e.toJson()).toList(),
  'emploi1Id': instance.emploi1Id,
  'emploi2Id': instance.emploi2Id,
  'anneesExperience1': instance.anneesExperience1,
  'anneesExperience2': instance.anneesExperience2,
  'resumeCv': instance.resumeCv,
};

const _$GenreEnumMap = {Genre.masculin: 'masculin', Genre.feminin: 'feminin'};

const _$SituationMatrimonialeEnumMap = {
  SituationMatrimoniale.celibataire: 'celibataire',
  SituationMatrimoniale.marie: 'marie',
  SituationMatrimoniale.divorce: 'divorce',
  SituationMatrimoniale.veuf: 'veuf',
};
