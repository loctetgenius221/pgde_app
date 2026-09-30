// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'demande.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FichierJoint {

 String get chemin; String get url; String get nom; int? get taille;
/// Create a copy of FichierJoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FichierJointCopyWith<FichierJoint> get copyWith => _$FichierJointCopyWithImpl<FichierJoint>(this as FichierJoint, _$identity);

  /// Serializes this FichierJoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FichierJoint&&(identical(other.chemin, chemin) || other.chemin == chemin)&&(identical(other.url, url) || other.url == url)&&(identical(other.nom, nom) || other.nom == nom)&&(identical(other.taille, taille) || other.taille == taille));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,chemin,url,nom,taille);

@override
String toString() {
  return 'FichierJoint(chemin: $chemin, url: $url, nom: $nom, taille: $taille)';
}


}

/// @nodoc
abstract mixin class $FichierJointCopyWith<$Res>  {
  factory $FichierJointCopyWith(FichierJoint value, $Res Function(FichierJoint) _then) = _$FichierJointCopyWithImpl;
@useResult
$Res call({
 String chemin, String url, String nom, int? taille
});




}
/// @nodoc
class _$FichierJointCopyWithImpl<$Res>
    implements $FichierJointCopyWith<$Res> {
  _$FichierJointCopyWithImpl(this._self, this._then);

  final FichierJoint _self;
  final $Res Function(FichierJoint) _then;

/// Create a copy of FichierJoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? chemin = null,Object? url = null,Object? nom = null,Object? taille = freezed,}) {
  return _then(_self.copyWith(
chemin: null == chemin ? _self.chemin : chemin // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,nom: null == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String,taille: freezed == taille ? _self.taille : taille // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [FichierJoint].
extension FichierJointPatterns on FichierJoint {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FichierJoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FichierJoint() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FichierJoint value)  $default,){
final _that = this;
switch (_that) {
case _FichierJoint():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FichierJoint value)?  $default,){
final _that = this;
switch (_that) {
case _FichierJoint() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String chemin,  String url,  String nom,  int? taille)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FichierJoint() when $default != null:
return $default(_that.chemin,_that.url,_that.nom,_that.taille);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String chemin,  String url,  String nom,  int? taille)  $default,) {final _that = this;
switch (_that) {
case _FichierJoint():
return $default(_that.chemin,_that.url,_that.nom,_that.taille);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String chemin,  String url,  String nom,  int? taille)?  $default,) {final _that = this;
switch (_that) {
case _FichierJoint() when $default != null:
return $default(_that.chemin,_that.url,_that.nom,_that.taille);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FichierJoint extends FichierJoint {
  const _FichierJoint({required this.chemin, required this.url, this.nom = '', this.taille}): super._();
  factory _FichierJoint.fromJson(Map<String, dynamic> json) => _$FichierJointFromJson(json);

@override final  String chemin;
@override final  String url;
@override@JsonKey() final  String nom;
@override final  int? taille;

/// Create a copy of FichierJoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FichierJointCopyWith<_FichierJoint> get copyWith => __$FichierJointCopyWithImpl<_FichierJoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FichierJointToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FichierJoint&&(identical(other.chemin, chemin) || other.chemin == chemin)&&(identical(other.url, url) || other.url == url)&&(identical(other.nom, nom) || other.nom == nom)&&(identical(other.taille, taille) || other.taille == taille));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,chemin,url,nom,taille);

@override
String toString() {
  return 'FichierJoint(chemin: $chemin, url: $url, nom: $nom, taille: $taille)';
}


}

/// @nodoc
abstract mixin class _$FichierJointCopyWith<$Res> implements $FichierJointCopyWith<$Res> {
  factory _$FichierJointCopyWith(_FichierJoint value, $Res Function(_FichierJoint) _then) = __$FichierJointCopyWithImpl;
@override @useResult
$Res call({
 String chemin, String url, String nom, int? taille
});




}
/// @nodoc
class __$FichierJointCopyWithImpl<$Res>
    implements _$FichierJointCopyWith<$Res> {
  __$FichierJointCopyWithImpl(this._self, this._then);

  final _FichierJoint _self;
  final $Res Function(_FichierJoint) _then;

/// Create a copy of FichierJoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? chemin = null,Object? url = null,Object? nom = null,Object? taille = freezed,}) {
  return _then(_FichierJoint(
chemin: null == chemin ? _self.chemin : chemin // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,nom: null == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String,taille: freezed == taille ? _self.taille : taille // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$Formation {

 int get academicId; String get diplome; int? get anneeDiplome; String get specialite; String get etablissement;/// Justificatif de **cette** formation.
///
/// Le contrat le porte à deux endroits : `diplome_file_url` dans la
/// lecture du profil (§5.1) et `formation_index` au téléversement
/// (§6.4). Le lien formation ↔ document est donc enfin tenu par le
/// serveur, et non plus reconstitué côté app.
 FichierJoint? get justificatif;
/// Create a copy of Formation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FormationCopyWith<Formation> get copyWith => _$FormationCopyWithImpl<Formation>(this as Formation, _$identity);

  /// Serializes this Formation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Formation&&(identical(other.academicId, academicId) || other.academicId == academicId)&&(identical(other.diplome, diplome) || other.diplome == diplome)&&(identical(other.anneeDiplome, anneeDiplome) || other.anneeDiplome == anneeDiplome)&&(identical(other.specialite, specialite) || other.specialite == specialite)&&(identical(other.etablissement, etablissement) || other.etablissement == etablissement)&&(identical(other.justificatif, justificatif) || other.justificatif == justificatif));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,academicId,diplome,anneeDiplome,specialite,etablissement,justificatif);

@override
String toString() {
  return 'Formation(academicId: $academicId, diplome: $diplome, anneeDiplome: $anneeDiplome, specialite: $specialite, etablissement: $etablissement, justificatif: $justificatif)';
}


}

/// @nodoc
abstract mixin class $FormationCopyWith<$Res>  {
  factory $FormationCopyWith(Formation value, $Res Function(Formation) _then) = _$FormationCopyWithImpl;
@useResult
$Res call({
 int academicId, String diplome, int? anneeDiplome, String specialite, String etablissement, FichierJoint? justificatif
});


$FichierJointCopyWith<$Res>? get justificatif;

}
/// @nodoc
class _$FormationCopyWithImpl<$Res>
    implements $FormationCopyWith<$Res> {
  _$FormationCopyWithImpl(this._self, this._then);

  final Formation _self;
  final $Res Function(Formation) _then;

/// Create a copy of Formation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? academicId = null,Object? diplome = null,Object? anneeDiplome = freezed,Object? specialite = null,Object? etablissement = null,Object? justificatif = freezed,}) {
  return _then(_self.copyWith(
academicId: null == academicId ? _self.academicId : academicId // ignore: cast_nullable_to_non_nullable
as int,diplome: null == diplome ? _self.diplome : diplome // ignore: cast_nullable_to_non_nullable
as String,anneeDiplome: freezed == anneeDiplome ? _self.anneeDiplome : anneeDiplome // ignore: cast_nullable_to_non_nullable
as int?,specialite: null == specialite ? _self.specialite : specialite // ignore: cast_nullable_to_non_nullable
as String,etablissement: null == etablissement ? _self.etablissement : etablissement // ignore: cast_nullable_to_non_nullable
as String,justificatif: freezed == justificatif ? _self.justificatif : justificatif // ignore: cast_nullable_to_non_nullable
as FichierJoint?,
  ));
}
/// Create a copy of Formation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FichierJointCopyWith<$Res>? get justificatif {
    if (_self.justificatif == null) {
    return null;
  }

  return $FichierJointCopyWith<$Res>(_self.justificatif!, (value) {
    return _then(_self.copyWith(justificatif: value));
  });
}
}


/// Adds pattern-matching-related methods to [Formation].
extension FormationPatterns on Formation {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Formation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Formation() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Formation value)  $default,){
final _that = this;
switch (_that) {
case _Formation():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Formation value)?  $default,){
final _that = this;
switch (_that) {
case _Formation() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int academicId,  String diplome,  int? anneeDiplome,  String specialite,  String etablissement,  FichierJoint? justificatif)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Formation() when $default != null:
return $default(_that.academicId,_that.diplome,_that.anneeDiplome,_that.specialite,_that.etablissement,_that.justificatif);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int academicId,  String diplome,  int? anneeDiplome,  String specialite,  String etablissement,  FichierJoint? justificatif)  $default,) {final _that = this;
switch (_that) {
case _Formation():
return $default(_that.academicId,_that.diplome,_that.anneeDiplome,_that.specialite,_that.etablissement,_that.justificatif);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int academicId,  String diplome,  int? anneeDiplome,  String specialite,  String etablissement,  FichierJoint? justificatif)?  $default,) {final _that = this;
switch (_that) {
case _Formation() when $default != null:
return $default(_that.academicId,_that.diplome,_that.anneeDiplome,_that.specialite,_that.etablissement,_that.justificatif);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Formation extends Formation {
  const _Formation({required this.academicId, this.diplome = '', this.anneeDiplome, this.specialite = '', this.etablissement = '', this.justificatif}): super._();
  factory _Formation.fromJson(Map<String, dynamic> json) => _$FormationFromJson(json);

@override final  int academicId;
@override@JsonKey() final  String diplome;
@override final  int? anneeDiplome;
@override@JsonKey() final  String specialite;
@override@JsonKey() final  String etablissement;
/// Justificatif de **cette** formation.
///
/// Le contrat le porte à deux endroits : `diplome_file_url` dans la
/// lecture du profil (§5.1) et `formation_index` au téléversement
/// (§6.4). Le lien formation ↔ document est donc enfin tenu par le
/// serveur, et non plus reconstitué côté app.
@override final  FichierJoint? justificatif;

/// Create a copy of Formation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FormationCopyWith<_Formation> get copyWith => __$FormationCopyWithImpl<_Formation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FormationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Formation&&(identical(other.academicId, academicId) || other.academicId == academicId)&&(identical(other.diplome, diplome) || other.diplome == diplome)&&(identical(other.anneeDiplome, anneeDiplome) || other.anneeDiplome == anneeDiplome)&&(identical(other.specialite, specialite) || other.specialite == specialite)&&(identical(other.etablissement, etablissement) || other.etablissement == etablissement)&&(identical(other.justificatif, justificatif) || other.justificatif == justificatif));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,academicId,diplome,anneeDiplome,specialite,etablissement,justificatif);

@override
String toString() {
  return 'Formation(academicId: $academicId, diplome: $diplome, anneeDiplome: $anneeDiplome, specialite: $specialite, etablissement: $etablissement, justificatif: $justificatif)';
}


}

/// @nodoc
abstract mixin class _$FormationCopyWith<$Res> implements $FormationCopyWith<$Res> {
  factory _$FormationCopyWith(_Formation value, $Res Function(_Formation) _then) = __$FormationCopyWithImpl;
@override @useResult
$Res call({
 int academicId, String diplome, int? anneeDiplome, String specialite, String etablissement, FichierJoint? justificatif
});


@override $FichierJointCopyWith<$Res>? get justificatif;

}
/// @nodoc
class __$FormationCopyWithImpl<$Res>
    implements _$FormationCopyWith<$Res> {
  __$FormationCopyWithImpl(this._self, this._then);

  final _Formation _self;
  final $Res Function(_Formation) _then;

/// Create a copy of Formation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? academicId = null,Object? diplome = null,Object? anneeDiplome = freezed,Object? specialite = null,Object? etablissement = null,Object? justificatif = freezed,}) {
  return _then(_Formation(
academicId: null == academicId ? _self.academicId : academicId // ignore: cast_nullable_to_non_nullable
as int,diplome: null == diplome ? _self.diplome : diplome // ignore: cast_nullable_to_non_nullable
as String,anneeDiplome: freezed == anneeDiplome ? _self.anneeDiplome : anneeDiplome // ignore: cast_nullable_to_non_nullable
as int?,specialite: null == specialite ? _self.specialite : specialite // ignore: cast_nullable_to_non_nullable
as String,etablissement: null == etablissement ? _self.etablissement : etablissement // ignore: cast_nullable_to_non_nullable
as String,justificatif: freezed == justificatif ? _self.justificatif : justificatif // ignore: cast_nullable_to_non_nullable
as FichierJoint?,
  ));
}

/// Create a copy of Formation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FichierJointCopyWith<$Res>? get justificatif {
    if (_self.justificatif == null) {
    return null;
  }

  return $FichierJointCopyWith<$Res>(_self.justificatif!, (value) {
    return _then(_self.copyWith(justificatif: value));
  });
}
}


/// @nodoc
mixin _$Experience {

 String get poste; String get employeur; String get description; int? get annees;
/// Create a copy of Experience
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExperienceCopyWith<Experience> get copyWith => _$ExperienceCopyWithImpl<Experience>(this as Experience, _$identity);

  /// Serializes this Experience to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Experience&&(identical(other.poste, poste) || other.poste == poste)&&(identical(other.employeur, employeur) || other.employeur == employeur)&&(identical(other.description, description) || other.description == description)&&(identical(other.annees, annees) || other.annees == annees));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,poste,employeur,description,annees);

@override
String toString() {
  return 'Experience(poste: $poste, employeur: $employeur, description: $description, annees: $annees)';
}


}

/// @nodoc
abstract mixin class $ExperienceCopyWith<$Res>  {
  factory $ExperienceCopyWith(Experience value, $Res Function(Experience) _then) = _$ExperienceCopyWithImpl;
@useResult
$Res call({
 String poste, String employeur, String description, int? annees
});




}
/// @nodoc
class _$ExperienceCopyWithImpl<$Res>
    implements $ExperienceCopyWith<$Res> {
  _$ExperienceCopyWithImpl(this._self, this._then);

  final Experience _self;
  final $Res Function(Experience) _then;

/// Create a copy of Experience
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? poste = null,Object? employeur = null,Object? description = null,Object? annees = freezed,}) {
  return _then(_self.copyWith(
poste: null == poste ? _self.poste : poste // ignore: cast_nullable_to_non_nullable
as String,employeur: null == employeur ? _self.employeur : employeur // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,annees: freezed == annees ? _self.annees : annees // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [Experience].
extension ExperiencePatterns on Experience {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Experience value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Experience() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Experience value)  $default,){
final _that = this;
switch (_that) {
case _Experience():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Experience value)?  $default,){
final _that = this;
switch (_that) {
case _Experience() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String poste,  String employeur,  String description,  int? annees)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Experience() when $default != null:
return $default(_that.poste,_that.employeur,_that.description,_that.annees);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String poste,  String employeur,  String description,  int? annees)  $default,) {final _that = this;
switch (_that) {
case _Experience():
return $default(_that.poste,_that.employeur,_that.description,_that.annees);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String poste,  String employeur,  String description,  int? annees)?  $default,) {final _that = this;
switch (_that) {
case _Experience() when $default != null:
return $default(_that.poste,_that.employeur,_that.description,_that.annees);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Experience extends Experience {
  const _Experience({this.poste = '', this.employeur = '', this.description = '', this.annees}): super._();
  factory _Experience.fromJson(Map<String, dynamic> json) => _$ExperienceFromJson(json);

@override@JsonKey() final  String poste;
@override@JsonKey() final  String employeur;
@override@JsonKey() final  String description;
@override final  int? annees;

/// Create a copy of Experience
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExperienceCopyWith<_Experience> get copyWith => __$ExperienceCopyWithImpl<_Experience>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExperienceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Experience&&(identical(other.poste, poste) || other.poste == poste)&&(identical(other.employeur, employeur) || other.employeur == employeur)&&(identical(other.description, description) || other.description == description)&&(identical(other.annees, annees) || other.annees == annees));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,poste,employeur,description,annees);

@override
String toString() {
  return 'Experience(poste: $poste, employeur: $employeur, description: $description, annees: $annees)';
}


}

/// @nodoc
abstract mixin class _$ExperienceCopyWith<$Res> implements $ExperienceCopyWith<$Res> {
  factory _$ExperienceCopyWith(_Experience value, $Res Function(_Experience) _then) = __$ExperienceCopyWithImpl;
@override @useResult
$Res call({
 String poste, String employeur, String description, int? annees
});




}
/// @nodoc
class __$ExperienceCopyWithImpl<$Res>
    implements _$ExperienceCopyWith<$Res> {
  __$ExperienceCopyWithImpl(this._self, this._then);

  final _Experience _self;
  final $Res Function(_Experience) _then;

/// Create a copy of Experience
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? poste = null,Object? employeur = null,Object? description = null,Object? annees = freezed,}) {
  return _then(_Experience(
poste: null == poste ? _self.poste : poste // ignore: cast_nullable_to_non_nullable
as String,employeur: null == employeur ? _self.employeur : employeur // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,annees: freezed == annees ? _self.annees : annees // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$Demande {

/// Vrai si le serveur détient déjà une fiche `userdata`.
///
/// Les quatre endpoints d'écriture sont des `PUT` idempotents : il n'y a
/// plus de création à distinguer d'une mise à jour. Ce drapeau ne sert
/// donc qu'à l'affichage — « dossier enregistré » plutôt que « demande
/// en préparation ».
 bool get deposee;// --- Étape 1 : identité et résidence ---
@DateOnlyConverter() DateTime? get dateNaissance; String get lieuNaissance; String get lieuResidence; String get adresse; Genre? get genre; SituationMatrimoniale? get situationMatrimoniale; String get telephone1; String get telephone2; int get nombreEnfants; int? get paysId; int? get regionNaissanceId; int? get departementNaissanceId; int? get regionResidenceId; int? get departementResidenceId;// §4 distingue **deux** champs : `handicap` (« 0 » ou « 1 ») et
// `handicap_id`. Les fondre en un seul rendait « Oui » inexprimable tant
// qu'aucun type n'était choisi — et donc intapable.
 bool get aUnHandicap; int? get handicapId;// --- Étape 2 : formations et justificatifs ---
//
// Chaque formation porte le sien (§5.1, §6.4). Il n'y a plus de tableau
// global de diplômes : c'était l'aveu d'un serveur incapable de dire
// quel document prouvait quelle formation.
 List<Formation> get formations;// Les pièces vivent sur le serveur, déposées par des appels dédiés
// (§6). Elles ne partent donc **pas** dans le corps du formulaire : on
// les garde ici pour l'affichage et la suppression.
 List<FichierJoint> get cv; FichierJoint? get photo;// --- Étape 3 : expériences ---
// `null` tant que le candidat n'a pas répondu. Un booléen par défaut
// faisait passer l'étape pour complétée avant même qu'il l'ait ouverte :
// le dossier affichait une réponse que personne n'avait donnée.
 bool? get aDeLExperience; List<Experience> get experiences;// --- Étape 4 : vœux ---
 int? get emploi1Id; int? get emploi2Id; int get anneesExperience1; int get anneesExperience2; String get resumeCv;
/// Create a copy of Demande
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DemandeCopyWith<Demande> get copyWith => _$DemandeCopyWithImpl<Demande>(this as Demande, _$identity);

  /// Serializes this Demande to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Demande&&(identical(other.deposee, deposee) || other.deposee == deposee)&&(identical(other.dateNaissance, dateNaissance) || other.dateNaissance == dateNaissance)&&(identical(other.lieuNaissance, lieuNaissance) || other.lieuNaissance == lieuNaissance)&&(identical(other.lieuResidence, lieuResidence) || other.lieuResidence == lieuResidence)&&(identical(other.adresse, adresse) || other.adresse == adresse)&&(identical(other.genre, genre) || other.genre == genre)&&(identical(other.situationMatrimoniale, situationMatrimoniale) || other.situationMatrimoniale == situationMatrimoniale)&&(identical(other.telephone1, telephone1) || other.telephone1 == telephone1)&&(identical(other.telephone2, telephone2) || other.telephone2 == telephone2)&&(identical(other.nombreEnfants, nombreEnfants) || other.nombreEnfants == nombreEnfants)&&(identical(other.paysId, paysId) || other.paysId == paysId)&&(identical(other.regionNaissanceId, regionNaissanceId) || other.regionNaissanceId == regionNaissanceId)&&(identical(other.departementNaissanceId, departementNaissanceId) || other.departementNaissanceId == departementNaissanceId)&&(identical(other.regionResidenceId, regionResidenceId) || other.regionResidenceId == regionResidenceId)&&(identical(other.departementResidenceId, departementResidenceId) || other.departementResidenceId == departementResidenceId)&&(identical(other.aUnHandicap, aUnHandicap) || other.aUnHandicap == aUnHandicap)&&(identical(other.handicapId, handicapId) || other.handicapId == handicapId)&&const DeepCollectionEquality().equals(other.formations, formations)&&const DeepCollectionEquality().equals(other.cv, cv)&&(identical(other.photo, photo) || other.photo == photo)&&(identical(other.aDeLExperience, aDeLExperience) || other.aDeLExperience == aDeLExperience)&&const DeepCollectionEquality().equals(other.experiences, experiences)&&(identical(other.emploi1Id, emploi1Id) || other.emploi1Id == emploi1Id)&&(identical(other.emploi2Id, emploi2Id) || other.emploi2Id == emploi2Id)&&(identical(other.anneesExperience1, anneesExperience1) || other.anneesExperience1 == anneesExperience1)&&(identical(other.anneesExperience2, anneesExperience2) || other.anneesExperience2 == anneesExperience2)&&(identical(other.resumeCv, resumeCv) || other.resumeCv == resumeCv));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,deposee,dateNaissance,lieuNaissance,lieuResidence,adresse,genre,situationMatrimoniale,telephone1,telephone2,nombreEnfants,paysId,regionNaissanceId,departementNaissanceId,regionResidenceId,departementResidenceId,aUnHandicap,handicapId,const DeepCollectionEquality().hash(formations),const DeepCollectionEquality().hash(cv),photo,aDeLExperience,const DeepCollectionEquality().hash(experiences),emploi1Id,emploi2Id,anneesExperience1,anneesExperience2,resumeCv]);

@override
String toString() {
  return 'Demande(deposee: $deposee, dateNaissance: $dateNaissance, lieuNaissance: $lieuNaissance, lieuResidence: $lieuResidence, adresse: $adresse, genre: $genre, situationMatrimoniale: $situationMatrimoniale, telephone1: $telephone1, telephone2: $telephone2, nombreEnfants: $nombreEnfants, paysId: $paysId, regionNaissanceId: $regionNaissanceId, departementNaissanceId: $departementNaissanceId, regionResidenceId: $regionResidenceId, departementResidenceId: $departementResidenceId, aUnHandicap: $aUnHandicap, handicapId: $handicapId, formations: $formations, cv: $cv, photo: $photo, aDeLExperience: $aDeLExperience, experiences: $experiences, emploi1Id: $emploi1Id, emploi2Id: $emploi2Id, anneesExperience1: $anneesExperience1, anneesExperience2: $anneesExperience2, resumeCv: $resumeCv)';
}


}

/// @nodoc
abstract mixin class $DemandeCopyWith<$Res>  {
  factory $DemandeCopyWith(Demande value, $Res Function(Demande) _then) = _$DemandeCopyWithImpl;
@useResult
$Res call({
 bool deposee,@DateOnlyConverter() DateTime? dateNaissance, String lieuNaissance, String lieuResidence, String adresse, Genre? genre, SituationMatrimoniale? situationMatrimoniale, String telephone1, String telephone2, int nombreEnfants, int? paysId, int? regionNaissanceId, int? departementNaissanceId, int? regionResidenceId, int? departementResidenceId, bool aUnHandicap, int? handicapId, List<Formation> formations, List<FichierJoint> cv, FichierJoint? photo, bool? aDeLExperience, List<Experience> experiences, int? emploi1Id, int? emploi2Id, int anneesExperience1, int anneesExperience2, String resumeCv
});


$FichierJointCopyWith<$Res>? get photo;

}
/// @nodoc
class _$DemandeCopyWithImpl<$Res>
    implements $DemandeCopyWith<$Res> {
  _$DemandeCopyWithImpl(this._self, this._then);

  final Demande _self;
  final $Res Function(Demande) _then;

/// Create a copy of Demande
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deposee = null,Object? dateNaissance = freezed,Object? lieuNaissance = null,Object? lieuResidence = null,Object? adresse = null,Object? genre = freezed,Object? situationMatrimoniale = freezed,Object? telephone1 = null,Object? telephone2 = null,Object? nombreEnfants = null,Object? paysId = freezed,Object? regionNaissanceId = freezed,Object? departementNaissanceId = freezed,Object? regionResidenceId = freezed,Object? departementResidenceId = freezed,Object? aUnHandicap = null,Object? handicapId = freezed,Object? formations = null,Object? cv = null,Object? photo = freezed,Object? aDeLExperience = freezed,Object? experiences = null,Object? emploi1Id = freezed,Object? emploi2Id = freezed,Object? anneesExperience1 = null,Object? anneesExperience2 = null,Object? resumeCv = null,}) {
  return _then(_self.copyWith(
deposee: null == deposee ? _self.deposee : deposee // ignore: cast_nullable_to_non_nullable
as bool,dateNaissance: freezed == dateNaissance ? _self.dateNaissance : dateNaissance // ignore: cast_nullable_to_non_nullable
as DateTime?,lieuNaissance: null == lieuNaissance ? _self.lieuNaissance : lieuNaissance // ignore: cast_nullable_to_non_nullable
as String,lieuResidence: null == lieuResidence ? _self.lieuResidence : lieuResidence // ignore: cast_nullable_to_non_nullable
as String,adresse: null == adresse ? _self.adresse : adresse // ignore: cast_nullable_to_non_nullable
as String,genre: freezed == genre ? _self.genre : genre // ignore: cast_nullable_to_non_nullable
as Genre?,situationMatrimoniale: freezed == situationMatrimoniale ? _self.situationMatrimoniale : situationMatrimoniale // ignore: cast_nullable_to_non_nullable
as SituationMatrimoniale?,telephone1: null == telephone1 ? _self.telephone1 : telephone1 // ignore: cast_nullable_to_non_nullable
as String,telephone2: null == telephone2 ? _self.telephone2 : telephone2 // ignore: cast_nullable_to_non_nullable
as String,nombreEnfants: null == nombreEnfants ? _self.nombreEnfants : nombreEnfants // ignore: cast_nullable_to_non_nullable
as int,paysId: freezed == paysId ? _self.paysId : paysId // ignore: cast_nullable_to_non_nullable
as int?,regionNaissanceId: freezed == regionNaissanceId ? _self.regionNaissanceId : regionNaissanceId // ignore: cast_nullable_to_non_nullable
as int?,departementNaissanceId: freezed == departementNaissanceId ? _self.departementNaissanceId : departementNaissanceId // ignore: cast_nullable_to_non_nullable
as int?,regionResidenceId: freezed == regionResidenceId ? _self.regionResidenceId : regionResidenceId // ignore: cast_nullable_to_non_nullable
as int?,departementResidenceId: freezed == departementResidenceId ? _self.departementResidenceId : departementResidenceId // ignore: cast_nullable_to_non_nullable
as int?,aUnHandicap: null == aUnHandicap ? _self.aUnHandicap : aUnHandicap // ignore: cast_nullable_to_non_nullable
as bool,handicapId: freezed == handicapId ? _self.handicapId : handicapId // ignore: cast_nullable_to_non_nullable
as int?,formations: null == formations ? _self.formations : formations // ignore: cast_nullable_to_non_nullable
as List<Formation>,cv: null == cv ? _self.cv : cv // ignore: cast_nullable_to_non_nullable
as List<FichierJoint>,photo: freezed == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as FichierJoint?,aDeLExperience: freezed == aDeLExperience ? _self.aDeLExperience : aDeLExperience // ignore: cast_nullable_to_non_nullable
as bool?,experiences: null == experiences ? _self.experiences : experiences // ignore: cast_nullable_to_non_nullable
as List<Experience>,emploi1Id: freezed == emploi1Id ? _self.emploi1Id : emploi1Id // ignore: cast_nullable_to_non_nullable
as int?,emploi2Id: freezed == emploi2Id ? _self.emploi2Id : emploi2Id // ignore: cast_nullable_to_non_nullable
as int?,anneesExperience1: null == anneesExperience1 ? _self.anneesExperience1 : anneesExperience1 // ignore: cast_nullable_to_non_nullable
as int,anneesExperience2: null == anneesExperience2 ? _self.anneesExperience2 : anneesExperience2 // ignore: cast_nullable_to_non_nullable
as int,resumeCv: null == resumeCv ? _self.resumeCv : resumeCv // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of Demande
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FichierJointCopyWith<$Res>? get photo {
    if (_self.photo == null) {
    return null;
  }

  return $FichierJointCopyWith<$Res>(_self.photo!, (value) {
    return _then(_self.copyWith(photo: value));
  });
}
}


/// Adds pattern-matching-related methods to [Demande].
extension DemandePatterns on Demande {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Demande value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Demande() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Demande value)  $default,){
final _that = this;
switch (_that) {
case _Demande():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Demande value)?  $default,){
final _that = this;
switch (_that) {
case _Demande() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool deposee, @DateOnlyConverter()  DateTime? dateNaissance,  String lieuNaissance,  String lieuResidence,  String adresse,  Genre? genre,  SituationMatrimoniale? situationMatrimoniale,  String telephone1,  String telephone2,  int nombreEnfants,  int? paysId,  int? regionNaissanceId,  int? departementNaissanceId,  int? regionResidenceId,  int? departementResidenceId,  bool aUnHandicap,  int? handicapId,  List<Formation> formations,  List<FichierJoint> cv,  FichierJoint? photo,  bool? aDeLExperience,  List<Experience> experiences,  int? emploi1Id,  int? emploi2Id,  int anneesExperience1,  int anneesExperience2,  String resumeCv)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Demande() when $default != null:
return $default(_that.deposee,_that.dateNaissance,_that.lieuNaissance,_that.lieuResidence,_that.adresse,_that.genre,_that.situationMatrimoniale,_that.telephone1,_that.telephone2,_that.nombreEnfants,_that.paysId,_that.regionNaissanceId,_that.departementNaissanceId,_that.regionResidenceId,_that.departementResidenceId,_that.aUnHandicap,_that.handicapId,_that.formations,_that.cv,_that.photo,_that.aDeLExperience,_that.experiences,_that.emploi1Id,_that.emploi2Id,_that.anneesExperience1,_that.anneesExperience2,_that.resumeCv);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool deposee, @DateOnlyConverter()  DateTime? dateNaissance,  String lieuNaissance,  String lieuResidence,  String adresse,  Genre? genre,  SituationMatrimoniale? situationMatrimoniale,  String telephone1,  String telephone2,  int nombreEnfants,  int? paysId,  int? regionNaissanceId,  int? departementNaissanceId,  int? regionResidenceId,  int? departementResidenceId,  bool aUnHandicap,  int? handicapId,  List<Formation> formations,  List<FichierJoint> cv,  FichierJoint? photo,  bool? aDeLExperience,  List<Experience> experiences,  int? emploi1Id,  int? emploi2Id,  int anneesExperience1,  int anneesExperience2,  String resumeCv)  $default,) {final _that = this;
switch (_that) {
case _Demande():
return $default(_that.deposee,_that.dateNaissance,_that.lieuNaissance,_that.lieuResidence,_that.adresse,_that.genre,_that.situationMatrimoniale,_that.telephone1,_that.telephone2,_that.nombreEnfants,_that.paysId,_that.regionNaissanceId,_that.departementNaissanceId,_that.regionResidenceId,_that.departementResidenceId,_that.aUnHandicap,_that.handicapId,_that.formations,_that.cv,_that.photo,_that.aDeLExperience,_that.experiences,_that.emploi1Id,_that.emploi2Id,_that.anneesExperience1,_that.anneesExperience2,_that.resumeCv);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool deposee, @DateOnlyConverter()  DateTime? dateNaissance,  String lieuNaissance,  String lieuResidence,  String adresse,  Genre? genre,  SituationMatrimoniale? situationMatrimoniale,  String telephone1,  String telephone2,  int nombreEnfants,  int? paysId,  int? regionNaissanceId,  int? departementNaissanceId,  int? regionResidenceId,  int? departementResidenceId,  bool aUnHandicap,  int? handicapId,  List<Formation> formations,  List<FichierJoint> cv,  FichierJoint? photo,  bool? aDeLExperience,  List<Experience> experiences,  int? emploi1Id,  int? emploi2Id,  int anneesExperience1,  int anneesExperience2,  String resumeCv)?  $default,) {final _that = this;
switch (_that) {
case _Demande() when $default != null:
return $default(_that.deposee,_that.dateNaissance,_that.lieuNaissance,_that.lieuResidence,_that.adresse,_that.genre,_that.situationMatrimoniale,_that.telephone1,_that.telephone2,_that.nombreEnfants,_that.paysId,_that.regionNaissanceId,_that.departementNaissanceId,_that.regionResidenceId,_that.departementResidenceId,_that.aUnHandicap,_that.handicapId,_that.formations,_that.cv,_that.photo,_that.aDeLExperience,_that.experiences,_that.emploi1Id,_that.emploi2Id,_that.anneesExperience1,_that.anneesExperience2,_that.resumeCv);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Demande extends Demande {
  const _Demande({this.deposee = false, @DateOnlyConverter() this.dateNaissance, this.lieuNaissance = '', this.lieuResidence = '', this.adresse = '', this.genre, this.situationMatrimoniale, this.telephone1 = '', this.telephone2 = '', this.nombreEnfants = 0, this.paysId, this.regionNaissanceId, this.departementNaissanceId, this.regionResidenceId, this.departementResidenceId, this.aUnHandicap = false, this.handicapId, final  List<Formation> formations = const <Formation>[], final  List<FichierJoint> cv = const <FichierJoint>[], this.photo, this.aDeLExperience, final  List<Experience> experiences = const <Experience>[], this.emploi1Id, this.emploi2Id, this.anneesExperience1 = 0, this.anneesExperience2 = 0, this.resumeCv = ''}): _formations = formations,_cv = cv,_experiences = experiences,super._();
  factory _Demande.fromJson(Map<String, dynamic> json) => _$DemandeFromJson(json);

/// Vrai si le serveur détient déjà une fiche `userdata`.
///
/// Les quatre endpoints d'écriture sont des `PUT` idempotents : il n'y a
/// plus de création à distinguer d'une mise à jour. Ce drapeau ne sert
/// donc qu'à l'affichage — « dossier enregistré » plutôt que « demande
/// en préparation ».
@override@JsonKey() final  bool deposee;
// --- Étape 1 : identité et résidence ---
@override@DateOnlyConverter() final  DateTime? dateNaissance;
@override@JsonKey() final  String lieuNaissance;
@override@JsonKey() final  String lieuResidence;
@override@JsonKey() final  String adresse;
@override final  Genre? genre;
@override final  SituationMatrimoniale? situationMatrimoniale;
@override@JsonKey() final  String telephone1;
@override@JsonKey() final  String telephone2;
@override@JsonKey() final  int nombreEnfants;
@override final  int? paysId;
@override final  int? regionNaissanceId;
@override final  int? departementNaissanceId;
@override final  int? regionResidenceId;
@override final  int? departementResidenceId;
// §4 distingue **deux** champs : `handicap` (« 0 » ou « 1 ») et
// `handicap_id`. Les fondre en un seul rendait « Oui » inexprimable tant
// qu'aucun type n'était choisi — et donc intapable.
@override@JsonKey() final  bool aUnHandicap;
@override final  int? handicapId;
// --- Étape 2 : formations et justificatifs ---
//
// Chaque formation porte le sien (§5.1, §6.4). Il n'y a plus de tableau
// global de diplômes : c'était l'aveu d'un serveur incapable de dire
// quel document prouvait quelle formation.
 final  List<Formation> _formations;
// --- Étape 2 : formations et justificatifs ---
//
// Chaque formation porte le sien (§5.1, §6.4). Il n'y a plus de tableau
// global de diplômes : c'était l'aveu d'un serveur incapable de dire
// quel document prouvait quelle formation.
@override@JsonKey() List<Formation> get formations {
  if (_formations is EqualUnmodifiableListView) return _formations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_formations);
}

// Les pièces vivent sur le serveur, déposées par des appels dédiés
// (§6). Elles ne partent donc **pas** dans le corps du formulaire : on
// les garde ici pour l'affichage et la suppression.
 final  List<FichierJoint> _cv;
// Les pièces vivent sur le serveur, déposées par des appels dédiés
// (§6). Elles ne partent donc **pas** dans le corps du formulaire : on
// les garde ici pour l'affichage et la suppression.
@override@JsonKey() List<FichierJoint> get cv {
  if (_cv is EqualUnmodifiableListView) return _cv;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cv);
}

@override final  FichierJoint? photo;
// --- Étape 3 : expériences ---
// `null` tant que le candidat n'a pas répondu. Un booléen par défaut
// faisait passer l'étape pour complétée avant même qu'il l'ait ouverte :
// le dossier affichait une réponse que personne n'avait donnée.
@override final  bool? aDeLExperience;
 final  List<Experience> _experiences;
@override@JsonKey() List<Experience> get experiences {
  if (_experiences is EqualUnmodifiableListView) return _experiences;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_experiences);
}

// --- Étape 4 : vœux ---
@override final  int? emploi1Id;
@override final  int? emploi2Id;
@override@JsonKey() final  int anneesExperience1;
@override@JsonKey() final  int anneesExperience2;
@override@JsonKey() final  String resumeCv;

/// Create a copy of Demande
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DemandeCopyWith<_Demande> get copyWith => __$DemandeCopyWithImpl<_Demande>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DemandeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Demande&&(identical(other.deposee, deposee) || other.deposee == deposee)&&(identical(other.dateNaissance, dateNaissance) || other.dateNaissance == dateNaissance)&&(identical(other.lieuNaissance, lieuNaissance) || other.lieuNaissance == lieuNaissance)&&(identical(other.lieuResidence, lieuResidence) || other.lieuResidence == lieuResidence)&&(identical(other.adresse, adresse) || other.adresse == adresse)&&(identical(other.genre, genre) || other.genre == genre)&&(identical(other.situationMatrimoniale, situationMatrimoniale) || other.situationMatrimoniale == situationMatrimoniale)&&(identical(other.telephone1, telephone1) || other.telephone1 == telephone1)&&(identical(other.telephone2, telephone2) || other.telephone2 == telephone2)&&(identical(other.nombreEnfants, nombreEnfants) || other.nombreEnfants == nombreEnfants)&&(identical(other.paysId, paysId) || other.paysId == paysId)&&(identical(other.regionNaissanceId, regionNaissanceId) || other.regionNaissanceId == regionNaissanceId)&&(identical(other.departementNaissanceId, departementNaissanceId) || other.departementNaissanceId == departementNaissanceId)&&(identical(other.regionResidenceId, regionResidenceId) || other.regionResidenceId == regionResidenceId)&&(identical(other.departementResidenceId, departementResidenceId) || other.departementResidenceId == departementResidenceId)&&(identical(other.aUnHandicap, aUnHandicap) || other.aUnHandicap == aUnHandicap)&&(identical(other.handicapId, handicapId) || other.handicapId == handicapId)&&const DeepCollectionEquality().equals(other._formations, _formations)&&const DeepCollectionEquality().equals(other._cv, _cv)&&(identical(other.photo, photo) || other.photo == photo)&&(identical(other.aDeLExperience, aDeLExperience) || other.aDeLExperience == aDeLExperience)&&const DeepCollectionEquality().equals(other._experiences, _experiences)&&(identical(other.emploi1Id, emploi1Id) || other.emploi1Id == emploi1Id)&&(identical(other.emploi2Id, emploi2Id) || other.emploi2Id == emploi2Id)&&(identical(other.anneesExperience1, anneesExperience1) || other.anneesExperience1 == anneesExperience1)&&(identical(other.anneesExperience2, anneesExperience2) || other.anneesExperience2 == anneesExperience2)&&(identical(other.resumeCv, resumeCv) || other.resumeCv == resumeCv));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,deposee,dateNaissance,lieuNaissance,lieuResidence,adresse,genre,situationMatrimoniale,telephone1,telephone2,nombreEnfants,paysId,regionNaissanceId,departementNaissanceId,regionResidenceId,departementResidenceId,aUnHandicap,handicapId,const DeepCollectionEquality().hash(_formations),const DeepCollectionEquality().hash(_cv),photo,aDeLExperience,const DeepCollectionEquality().hash(_experiences),emploi1Id,emploi2Id,anneesExperience1,anneesExperience2,resumeCv]);

@override
String toString() {
  return 'Demande(deposee: $deposee, dateNaissance: $dateNaissance, lieuNaissance: $lieuNaissance, lieuResidence: $lieuResidence, adresse: $adresse, genre: $genre, situationMatrimoniale: $situationMatrimoniale, telephone1: $telephone1, telephone2: $telephone2, nombreEnfants: $nombreEnfants, paysId: $paysId, regionNaissanceId: $regionNaissanceId, departementNaissanceId: $departementNaissanceId, regionResidenceId: $regionResidenceId, departementResidenceId: $departementResidenceId, aUnHandicap: $aUnHandicap, handicapId: $handicapId, formations: $formations, cv: $cv, photo: $photo, aDeLExperience: $aDeLExperience, experiences: $experiences, emploi1Id: $emploi1Id, emploi2Id: $emploi2Id, anneesExperience1: $anneesExperience1, anneesExperience2: $anneesExperience2, resumeCv: $resumeCv)';
}


}

/// @nodoc
abstract mixin class _$DemandeCopyWith<$Res> implements $DemandeCopyWith<$Res> {
  factory _$DemandeCopyWith(_Demande value, $Res Function(_Demande) _then) = __$DemandeCopyWithImpl;
@override @useResult
$Res call({
 bool deposee,@DateOnlyConverter() DateTime? dateNaissance, String lieuNaissance, String lieuResidence, String adresse, Genre? genre, SituationMatrimoniale? situationMatrimoniale, String telephone1, String telephone2, int nombreEnfants, int? paysId, int? regionNaissanceId, int? departementNaissanceId, int? regionResidenceId, int? departementResidenceId, bool aUnHandicap, int? handicapId, List<Formation> formations, List<FichierJoint> cv, FichierJoint? photo, bool? aDeLExperience, List<Experience> experiences, int? emploi1Id, int? emploi2Id, int anneesExperience1, int anneesExperience2, String resumeCv
});


@override $FichierJointCopyWith<$Res>? get photo;

}
/// @nodoc
class __$DemandeCopyWithImpl<$Res>
    implements _$DemandeCopyWith<$Res> {
  __$DemandeCopyWithImpl(this._self, this._then);

  final _Demande _self;
  final $Res Function(_Demande) _then;

/// Create a copy of Demande
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deposee = null,Object? dateNaissance = freezed,Object? lieuNaissance = null,Object? lieuResidence = null,Object? adresse = null,Object? genre = freezed,Object? situationMatrimoniale = freezed,Object? telephone1 = null,Object? telephone2 = null,Object? nombreEnfants = null,Object? paysId = freezed,Object? regionNaissanceId = freezed,Object? departementNaissanceId = freezed,Object? regionResidenceId = freezed,Object? departementResidenceId = freezed,Object? aUnHandicap = null,Object? handicapId = freezed,Object? formations = null,Object? cv = null,Object? photo = freezed,Object? aDeLExperience = freezed,Object? experiences = null,Object? emploi1Id = freezed,Object? emploi2Id = freezed,Object? anneesExperience1 = null,Object? anneesExperience2 = null,Object? resumeCv = null,}) {
  return _then(_Demande(
deposee: null == deposee ? _self.deposee : deposee // ignore: cast_nullable_to_non_nullable
as bool,dateNaissance: freezed == dateNaissance ? _self.dateNaissance : dateNaissance // ignore: cast_nullable_to_non_nullable
as DateTime?,lieuNaissance: null == lieuNaissance ? _self.lieuNaissance : lieuNaissance // ignore: cast_nullable_to_non_nullable
as String,lieuResidence: null == lieuResidence ? _self.lieuResidence : lieuResidence // ignore: cast_nullable_to_non_nullable
as String,adresse: null == adresse ? _self.adresse : adresse // ignore: cast_nullable_to_non_nullable
as String,genre: freezed == genre ? _self.genre : genre // ignore: cast_nullable_to_non_nullable
as Genre?,situationMatrimoniale: freezed == situationMatrimoniale ? _self.situationMatrimoniale : situationMatrimoniale // ignore: cast_nullable_to_non_nullable
as SituationMatrimoniale?,telephone1: null == telephone1 ? _self.telephone1 : telephone1 // ignore: cast_nullable_to_non_nullable
as String,telephone2: null == telephone2 ? _self.telephone2 : telephone2 // ignore: cast_nullable_to_non_nullable
as String,nombreEnfants: null == nombreEnfants ? _self.nombreEnfants : nombreEnfants // ignore: cast_nullable_to_non_nullable
as int,paysId: freezed == paysId ? _self.paysId : paysId // ignore: cast_nullable_to_non_nullable
as int?,regionNaissanceId: freezed == regionNaissanceId ? _self.regionNaissanceId : regionNaissanceId // ignore: cast_nullable_to_non_nullable
as int?,departementNaissanceId: freezed == departementNaissanceId ? _self.departementNaissanceId : departementNaissanceId // ignore: cast_nullable_to_non_nullable
as int?,regionResidenceId: freezed == regionResidenceId ? _self.regionResidenceId : regionResidenceId // ignore: cast_nullable_to_non_nullable
as int?,departementResidenceId: freezed == departementResidenceId ? _self.departementResidenceId : departementResidenceId // ignore: cast_nullable_to_non_nullable
as int?,aUnHandicap: null == aUnHandicap ? _self.aUnHandicap : aUnHandicap // ignore: cast_nullable_to_non_nullable
as bool,handicapId: freezed == handicapId ? _self.handicapId : handicapId // ignore: cast_nullable_to_non_nullable
as int?,formations: null == formations ? _self._formations : formations // ignore: cast_nullable_to_non_nullable
as List<Formation>,cv: null == cv ? _self._cv : cv // ignore: cast_nullable_to_non_nullable
as List<FichierJoint>,photo: freezed == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as FichierJoint?,aDeLExperience: freezed == aDeLExperience ? _self.aDeLExperience : aDeLExperience // ignore: cast_nullable_to_non_nullable
as bool?,experiences: null == experiences ? _self._experiences : experiences // ignore: cast_nullable_to_non_nullable
as List<Experience>,emploi1Id: freezed == emploi1Id ? _self.emploi1Id : emploi1Id // ignore: cast_nullable_to_non_nullable
as int?,emploi2Id: freezed == emploi2Id ? _self.emploi2Id : emploi2Id // ignore: cast_nullable_to_non_nullable
as int?,anneesExperience1: null == anneesExperience1 ? _self.anneesExperience1 : anneesExperience1 // ignore: cast_nullable_to_non_nullable
as int,anneesExperience2: null == anneesExperience2 ? _self.anneesExperience2 : anneesExperience2 // ignore: cast_nullable_to_non_nullable
as int,resumeCv: null == resumeCv ? _self.resumeCv : resumeCv // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of Demande
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FichierJointCopyWith<$Res>? get photo {
    if (_self.photo == null) {
    return null;
  }

  return $FichierJointCopyWith<$Res>(_self.photo!, (value) {
    return _then(_self.copyWith(photo: value));
  });
}
}

// dart format on
