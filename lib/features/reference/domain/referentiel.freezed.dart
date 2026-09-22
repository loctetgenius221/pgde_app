// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'referentiel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Region {

 int get id; String get libelle;
/// Create a copy of Region
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegionCopyWith<Region> get copyWith => _$RegionCopyWithImpl<Region>(this as Region, _$identity);

  /// Serializes this Region to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Region&&(identical(other.id, id) || other.id == id)&&(identical(other.libelle, libelle) || other.libelle == libelle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,libelle);

@override
String toString() {
  return 'Region(id: $id, libelle: $libelle)';
}


}

/// @nodoc
abstract mixin class $RegionCopyWith<$Res>  {
  factory $RegionCopyWith(Region value, $Res Function(Region) _then) = _$RegionCopyWithImpl;
@useResult
$Res call({
 int id, String libelle
});




}
/// @nodoc
class _$RegionCopyWithImpl<$Res>
    implements $RegionCopyWith<$Res> {
  _$RegionCopyWithImpl(this._self, this._then);

  final Region _self;
  final $Res Function(Region) _then;

/// Create a copy of Region
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? libelle = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,libelle: null == libelle ? _self.libelle : libelle // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Region].
extension RegionPatterns on Region {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Region value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Region() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Region value)  $default,){
final _that = this;
switch (_that) {
case _Region():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Region value)?  $default,){
final _that = this;
switch (_that) {
case _Region() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String libelle)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Region() when $default != null:
return $default(_that.id,_that.libelle);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String libelle)  $default,) {final _that = this;
switch (_that) {
case _Region():
return $default(_that.id,_that.libelle);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String libelle)?  $default,) {final _that = this;
switch (_that) {
case _Region() when $default != null:
return $default(_that.id,_that.libelle);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Region implements Region {
  const _Region({required this.id, required this.libelle});
  factory _Region.fromJson(Map<String, dynamic> json) => _$RegionFromJson(json);

@override final  int id;
@override final  String libelle;

/// Create a copy of Region
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RegionCopyWith<_Region> get copyWith => __$RegionCopyWithImpl<_Region>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RegionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Region&&(identical(other.id, id) || other.id == id)&&(identical(other.libelle, libelle) || other.libelle == libelle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,libelle);

@override
String toString() {
  return 'Region(id: $id, libelle: $libelle)';
}


}

/// @nodoc
abstract mixin class _$RegionCopyWith<$Res> implements $RegionCopyWith<$Res> {
  factory _$RegionCopyWith(_Region value, $Res Function(_Region) _then) = __$RegionCopyWithImpl;
@override @useResult
$Res call({
 int id, String libelle
});




}
/// @nodoc
class __$RegionCopyWithImpl<$Res>
    implements _$RegionCopyWith<$Res> {
  __$RegionCopyWithImpl(this._self, this._then);

  final _Region _self;
  final $Res Function(_Region) _then;

/// Create a copy of Region
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? libelle = null,}) {
  return _then(_Region(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,libelle: null == libelle ? _self.libelle : libelle // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Departement {

 int get id; String get libelle;@JsonKey(name: 'region_id') int get regionId;
/// Create a copy of Departement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DepartementCopyWith<Departement> get copyWith => _$DepartementCopyWithImpl<Departement>(this as Departement, _$identity);

  /// Serializes this Departement to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Departement&&(identical(other.id, id) || other.id == id)&&(identical(other.libelle, libelle) || other.libelle == libelle)&&(identical(other.regionId, regionId) || other.regionId == regionId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,libelle,regionId);

@override
String toString() {
  return 'Departement(id: $id, libelle: $libelle, regionId: $regionId)';
}


}

/// @nodoc
abstract mixin class $DepartementCopyWith<$Res>  {
  factory $DepartementCopyWith(Departement value, $Res Function(Departement) _then) = _$DepartementCopyWithImpl;
@useResult
$Res call({
 int id, String libelle,@JsonKey(name: 'region_id') int regionId
});




}
/// @nodoc
class _$DepartementCopyWithImpl<$Res>
    implements $DepartementCopyWith<$Res> {
  _$DepartementCopyWithImpl(this._self, this._then);

  final Departement _self;
  final $Res Function(Departement) _then;

/// Create a copy of Departement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? libelle = null,Object? regionId = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,libelle: null == libelle ? _self.libelle : libelle // ignore: cast_nullable_to_non_nullable
as String,regionId: null == regionId ? _self.regionId : regionId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Departement].
extension DepartementPatterns on Departement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Departement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Departement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Departement value)  $default,){
final _that = this;
switch (_that) {
case _Departement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Departement value)?  $default,){
final _that = this;
switch (_that) {
case _Departement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String libelle, @JsonKey(name: 'region_id')  int regionId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Departement() when $default != null:
return $default(_that.id,_that.libelle,_that.regionId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String libelle, @JsonKey(name: 'region_id')  int regionId)  $default,) {final _that = this;
switch (_that) {
case _Departement():
return $default(_that.id,_that.libelle,_that.regionId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String libelle, @JsonKey(name: 'region_id')  int regionId)?  $default,) {final _that = this;
switch (_that) {
case _Departement() when $default != null:
return $default(_that.id,_that.libelle,_that.regionId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Departement implements Departement {
  const _Departement({required this.id, required this.libelle, @JsonKey(name: 'region_id') required this.regionId});
  factory _Departement.fromJson(Map<String, dynamic> json) => _$DepartementFromJson(json);

@override final  int id;
@override final  String libelle;
@override@JsonKey(name: 'region_id') final  int regionId;

/// Create a copy of Departement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DepartementCopyWith<_Departement> get copyWith => __$DepartementCopyWithImpl<_Departement>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DepartementToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Departement&&(identical(other.id, id) || other.id == id)&&(identical(other.libelle, libelle) || other.libelle == libelle)&&(identical(other.regionId, regionId) || other.regionId == regionId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,libelle,regionId);

@override
String toString() {
  return 'Departement(id: $id, libelle: $libelle, regionId: $regionId)';
}


}

/// @nodoc
abstract mixin class _$DepartementCopyWith<$Res> implements $DepartementCopyWith<$Res> {
  factory _$DepartementCopyWith(_Departement value, $Res Function(_Departement) _then) = __$DepartementCopyWithImpl;
@override @useResult
$Res call({
 int id, String libelle,@JsonKey(name: 'region_id') int regionId
});




}
/// @nodoc
class __$DepartementCopyWithImpl<$Res>
    implements _$DepartementCopyWith<$Res> {
  __$DepartementCopyWithImpl(this._self, this._then);

  final _Departement _self;
  final $Res Function(_Departement) _then;

/// Create a copy of Departement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? libelle = null,Object? regionId = null,}) {
  return _then(_Departement(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,libelle: null == libelle ? _self.libelle : libelle // ignore: cast_nullable_to_non_nullable
as String,regionId: null == regionId ? _self.regionId : regionId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Secteur {

 int get id; String get libelle;
/// Create a copy of Secteur
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SecteurCopyWith<Secteur> get copyWith => _$SecteurCopyWithImpl<Secteur>(this as Secteur, _$identity);

  /// Serializes this Secteur to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Secteur&&(identical(other.id, id) || other.id == id)&&(identical(other.libelle, libelle) || other.libelle == libelle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,libelle);

@override
String toString() {
  return 'Secteur(id: $id, libelle: $libelle)';
}


}

/// @nodoc
abstract mixin class $SecteurCopyWith<$Res>  {
  factory $SecteurCopyWith(Secteur value, $Res Function(Secteur) _then) = _$SecteurCopyWithImpl;
@useResult
$Res call({
 int id, String libelle
});




}
/// @nodoc
class _$SecteurCopyWithImpl<$Res>
    implements $SecteurCopyWith<$Res> {
  _$SecteurCopyWithImpl(this._self, this._then);

  final Secteur _self;
  final $Res Function(Secteur) _then;

/// Create a copy of Secteur
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? libelle = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,libelle: null == libelle ? _self.libelle : libelle // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Secteur].
extension SecteurPatterns on Secteur {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Secteur value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Secteur() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Secteur value)  $default,){
final _that = this;
switch (_that) {
case _Secteur():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Secteur value)?  $default,){
final _that = this;
switch (_that) {
case _Secteur() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String libelle)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Secteur() when $default != null:
return $default(_that.id,_that.libelle);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String libelle)  $default,) {final _that = this;
switch (_that) {
case _Secteur():
return $default(_that.id,_that.libelle);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String libelle)?  $default,) {final _that = this;
switch (_that) {
case _Secteur() when $default != null:
return $default(_that.id,_that.libelle);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Secteur implements Secteur {
  const _Secteur({required this.id, required this.libelle});
  factory _Secteur.fromJson(Map<String, dynamic> json) => _$SecteurFromJson(json);

@override final  int id;
@override final  String libelle;

/// Create a copy of Secteur
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SecteurCopyWith<_Secteur> get copyWith => __$SecteurCopyWithImpl<_Secteur>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SecteurToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Secteur&&(identical(other.id, id) || other.id == id)&&(identical(other.libelle, libelle) || other.libelle == libelle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,libelle);

@override
String toString() {
  return 'Secteur(id: $id, libelle: $libelle)';
}


}

/// @nodoc
abstract mixin class _$SecteurCopyWith<$Res> implements $SecteurCopyWith<$Res> {
  factory _$SecteurCopyWith(_Secteur value, $Res Function(_Secteur) _then) = __$SecteurCopyWithImpl;
@override @useResult
$Res call({
 int id, String libelle
});




}
/// @nodoc
class __$SecteurCopyWithImpl<$Res>
    implements _$SecteurCopyWith<$Res> {
  __$SecteurCopyWithImpl(this._self, this._then);

  final _Secteur _self;
  final $Res Function(_Secteur) _then;

/// Create a copy of Secteur
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? libelle = null,}) {
  return _then(_Secteur(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,libelle: null == libelle ? _self.libelle : libelle // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Emploi {

 int get id; String get libelle;@JsonKey(name: 'secteur_id') int get secteurId;
/// Create a copy of Emploi
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmploiCopyWith<Emploi> get copyWith => _$EmploiCopyWithImpl<Emploi>(this as Emploi, _$identity);

  /// Serializes this Emploi to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Emploi&&(identical(other.id, id) || other.id == id)&&(identical(other.libelle, libelle) || other.libelle == libelle)&&(identical(other.secteurId, secteurId) || other.secteurId == secteurId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,libelle,secteurId);

@override
String toString() {
  return 'Emploi(id: $id, libelle: $libelle, secteurId: $secteurId)';
}


}

/// @nodoc
abstract mixin class $EmploiCopyWith<$Res>  {
  factory $EmploiCopyWith(Emploi value, $Res Function(Emploi) _then) = _$EmploiCopyWithImpl;
@useResult
$Res call({
 int id, String libelle,@JsonKey(name: 'secteur_id') int secteurId
});




}
/// @nodoc
class _$EmploiCopyWithImpl<$Res>
    implements $EmploiCopyWith<$Res> {
  _$EmploiCopyWithImpl(this._self, this._then);

  final Emploi _self;
  final $Res Function(Emploi) _then;

/// Create a copy of Emploi
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? libelle = null,Object? secteurId = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,libelle: null == libelle ? _self.libelle : libelle // ignore: cast_nullable_to_non_nullable
as String,secteurId: null == secteurId ? _self.secteurId : secteurId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Emploi].
extension EmploiPatterns on Emploi {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Emploi value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Emploi() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Emploi value)  $default,){
final _that = this;
switch (_that) {
case _Emploi():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Emploi value)?  $default,){
final _that = this;
switch (_that) {
case _Emploi() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String libelle, @JsonKey(name: 'secteur_id')  int secteurId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Emploi() when $default != null:
return $default(_that.id,_that.libelle,_that.secteurId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String libelle, @JsonKey(name: 'secteur_id')  int secteurId)  $default,) {final _that = this;
switch (_that) {
case _Emploi():
return $default(_that.id,_that.libelle,_that.secteurId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String libelle, @JsonKey(name: 'secteur_id')  int secteurId)?  $default,) {final _that = this;
switch (_that) {
case _Emploi() when $default != null:
return $default(_that.id,_that.libelle,_that.secteurId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Emploi implements Emploi {
  const _Emploi({required this.id, required this.libelle, @JsonKey(name: 'secteur_id') required this.secteurId});
  factory _Emploi.fromJson(Map<String, dynamic> json) => _$EmploiFromJson(json);

@override final  int id;
@override final  String libelle;
@override@JsonKey(name: 'secteur_id') final  int secteurId;

/// Create a copy of Emploi
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmploiCopyWith<_Emploi> get copyWith => __$EmploiCopyWithImpl<_Emploi>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EmploiToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Emploi&&(identical(other.id, id) || other.id == id)&&(identical(other.libelle, libelle) || other.libelle == libelle)&&(identical(other.secteurId, secteurId) || other.secteurId == secteurId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,libelle,secteurId);

@override
String toString() {
  return 'Emploi(id: $id, libelle: $libelle, secteurId: $secteurId)';
}


}

/// @nodoc
abstract mixin class _$EmploiCopyWith<$Res> implements $EmploiCopyWith<$Res> {
  factory _$EmploiCopyWith(_Emploi value, $Res Function(_Emploi) _then) = __$EmploiCopyWithImpl;
@override @useResult
$Res call({
 int id, String libelle,@JsonKey(name: 'secteur_id') int secteurId
});




}
/// @nodoc
class __$EmploiCopyWithImpl<$Res>
    implements _$EmploiCopyWith<$Res> {
  __$EmploiCopyWithImpl(this._self, this._then);

  final _Emploi _self;
  final $Res Function(_Emploi) _then;

/// Create a copy of Emploi
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? libelle = null,Object? secteurId = null,}) {
  return _then(_Emploi(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,libelle: null == libelle ? _self.libelle : libelle // ignore: cast_nullable_to_non_nullable
as String,secteurId: null == secteurId ? _self.secteurId : secteurId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Academic {

 int get id; String get libelle;
/// Create a copy of Academic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AcademicCopyWith<Academic> get copyWith => _$AcademicCopyWithImpl<Academic>(this as Academic, _$identity);

  /// Serializes this Academic to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Academic&&(identical(other.id, id) || other.id == id)&&(identical(other.libelle, libelle) || other.libelle == libelle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,libelle);

@override
String toString() {
  return 'Academic(id: $id, libelle: $libelle)';
}


}

/// @nodoc
abstract mixin class $AcademicCopyWith<$Res>  {
  factory $AcademicCopyWith(Academic value, $Res Function(Academic) _then) = _$AcademicCopyWithImpl;
@useResult
$Res call({
 int id, String libelle
});




}
/// @nodoc
class _$AcademicCopyWithImpl<$Res>
    implements $AcademicCopyWith<$Res> {
  _$AcademicCopyWithImpl(this._self, this._then);

  final Academic _self;
  final $Res Function(Academic) _then;

/// Create a copy of Academic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? libelle = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,libelle: null == libelle ? _self.libelle : libelle // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Academic].
extension AcademicPatterns on Academic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Academic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Academic() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Academic value)  $default,){
final _that = this;
switch (_that) {
case _Academic():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Academic value)?  $default,){
final _that = this;
switch (_that) {
case _Academic() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String libelle)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Academic() when $default != null:
return $default(_that.id,_that.libelle);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String libelle)  $default,) {final _that = this;
switch (_that) {
case _Academic():
return $default(_that.id,_that.libelle);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String libelle)?  $default,) {final _that = this;
switch (_that) {
case _Academic() when $default != null:
return $default(_that.id,_that.libelle);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Academic implements Academic {
  const _Academic({required this.id, required this.libelle});
  factory _Academic.fromJson(Map<String, dynamic> json) => _$AcademicFromJson(json);

@override final  int id;
@override final  String libelle;

/// Create a copy of Academic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AcademicCopyWith<_Academic> get copyWith => __$AcademicCopyWithImpl<_Academic>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AcademicToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Academic&&(identical(other.id, id) || other.id == id)&&(identical(other.libelle, libelle) || other.libelle == libelle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,libelle);

@override
String toString() {
  return 'Academic(id: $id, libelle: $libelle)';
}


}

/// @nodoc
abstract mixin class _$AcademicCopyWith<$Res> implements $AcademicCopyWith<$Res> {
  factory _$AcademicCopyWith(_Academic value, $Res Function(_Academic) _then) = __$AcademicCopyWithImpl;
@override @useResult
$Res call({
 int id, String libelle
});




}
/// @nodoc
class __$AcademicCopyWithImpl<$Res>
    implements _$AcademicCopyWith<$Res> {
  __$AcademicCopyWithImpl(this._self, this._then);

  final _Academic _self;
  final $Res Function(_Academic) _then;

/// Create a copy of Academic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? libelle = null,}) {
  return _then(_Academic(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,libelle: null == libelle ? _self.libelle : libelle // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Handicap {

 int get id; String get libelle;
/// Create a copy of Handicap
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HandicapCopyWith<Handicap> get copyWith => _$HandicapCopyWithImpl<Handicap>(this as Handicap, _$identity);

  /// Serializes this Handicap to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Handicap&&(identical(other.id, id) || other.id == id)&&(identical(other.libelle, libelle) || other.libelle == libelle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,libelle);

@override
String toString() {
  return 'Handicap(id: $id, libelle: $libelle)';
}


}

/// @nodoc
abstract mixin class $HandicapCopyWith<$Res>  {
  factory $HandicapCopyWith(Handicap value, $Res Function(Handicap) _then) = _$HandicapCopyWithImpl;
@useResult
$Res call({
 int id, String libelle
});




}
/// @nodoc
class _$HandicapCopyWithImpl<$Res>
    implements $HandicapCopyWith<$Res> {
  _$HandicapCopyWithImpl(this._self, this._then);

  final Handicap _self;
  final $Res Function(Handicap) _then;

/// Create a copy of Handicap
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? libelle = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,libelle: null == libelle ? _self.libelle : libelle // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Handicap].
extension HandicapPatterns on Handicap {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Handicap value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Handicap() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Handicap value)  $default,){
final _that = this;
switch (_that) {
case _Handicap():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Handicap value)?  $default,){
final _that = this;
switch (_that) {
case _Handicap() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String libelle)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Handicap() when $default != null:
return $default(_that.id,_that.libelle);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String libelle)  $default,) {final _that = this;
switch (_that) {
case _Handicap():
return $default(_that.id,_that.libelle);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String libelle)?  $default,) {final _that = this;
switch (_that) {
case _Handicap() when $default != null:
return $default(_that.id,_that.libelle);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Handicap implements Handicap {
  const _Handicap({required this.id, required this.libelle});
  factory _Handicap.fromJson(Map<String, dynamic> json) => _$HandicapFromJson(json);

@override final  int id;
@override final  String libelle;

/// Create a copy of Handicap
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HandicapCopyWith<_Handicap> get copyWith => __$HandicapCopyWithImpl<_Handicap>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HandicapToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Handicap&&(identical(other.id, id) || other.id == id)&&(identical(other.libelle, libelle) || other.libelle == libelle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,libelle);

@override
String toString() {
  return 'Handicap(id: $id, libelle: $libelle)';
}


}

/// @nodoc
abstract mixin class _$HandicapCopyWith<$Res> implements $HandicapCopyWith<$Res> {
  factory _$HandicapCopyWith(_Handicap value, $Res Function(_Handicap) _then) = __$HandicapCopyWithImpl;
@override @useResult
$Res call({
 int id, String libelle
});




}
/// @nodoc
class __$HandicapCopyWithImpl<$Res>
    implements _$HandicapCopyWith<$Res> {
  __$HandicapCopyWithImpl(this._self, this._then);

  final _Handicap _self;
  final $Res Function(_Handicap) _then;

/// Create a copy of Handicap
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? libelle = null,}) {
  return _then(_Handicap(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,libelle: null == libelle ? _self.libelle : libelle // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Pays {

 int get id; String get name;
/// Create a copy of Pays
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaysCopyWith<Pays> get copyWith => _$PaysCopyWithImpl<Pays>(this as Pays, _$identity);

  /// Serializes this Pays to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Pays&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'Pays(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $PaysCopyWith<$Res>  {
  factory $PaysCopyWith(Pays value, $Res Function(Pays) _then) = _$PaysCopyWithImpl;
@useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class _$PaysCopyWithImpl<$Res>
    implements $PaysCopyWith<$Res> {
  _$PaysCopyWithImpl(this._self, this._then);

  final Pays _self;
  final $Res Function(Pays) _then;

/// Create a copy of Pays
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Pays].
extension PaysPatterns on Pays {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Pays value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Pays() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Pays value)  $default,){
final _that = this;
switch (_that) {
case _Pays():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Pays value)?  $default,){
final _that = this;
switch (_that) {
case _Pays() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Pays() when $default != null:
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name)  $default,) {final _that = this;
switch (_that) {
case _Pays():
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name)?  $default,) {final _that = this;
switch (_that) {
case _Pays() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Pays implements Pays {
  const _Pays({required this.id, required this.name});
  factory _Pays.fromJson(Map<String, dynamic> json) => _$PaysFromJson(json);

@override final  int id;
@override final  String name;

/// Create a copy of Pays
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaysCopyWith<_Pays> get copyWith => __$PaysCopyWithImpl<_Pays>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaysToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Pays&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'Pays(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$PaysCopyWith<$Res> implements $PaysCopyWith<$Res> {
  factory _$PaysCopyWith(_Pays value, $Res Function(_Pays) _then) = __$PaysCopyWithImpl;
@override @useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class __$PaysCopyWithImpl<$Res>
    implements _$PaysCopyWith<$Res> {
  __$PaysCopyWithImpl(this._self, this._then);

  final _Pays _self;
  final $Res Function(_Pays) _then;

/// Create a copy of Pays
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_Pays(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Referentiel {

 String get version; List<Region> get regions; List<Departement> get departements; List<Secteur> get secteurs; List<Emploi> get emplois; List<Academic> get academics; List<Handicap> get handicaps; List<Pays> get countries;
/// Create a copy of Referentiel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReferentielCopyWith<Referentiel> get copyWith => _$ReferentielCopyWithImpl<Referentiel>(this as Referentiel, _$identity);

  /// Serializes this Referentiel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Referentiel&&(identical(other.version, version) || other.version == version)&&const DeepCollectionEquality().equals(other.regions, regions)&&const DeepCollectionEquality().equals(other.departements, departements)&&const DeepCollectionEquality().equals(other.secteurs, secteurs)&&const DeepCollectionEquality().equals(other.emplois, emplois)&&const DeepCollectionEquality().equals(other.academics, academics)&&const DeepCollectionEquality().equals(other.handicaps, handicaps)&&const DeepCollectionEquality().equals(other.countries, countries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,const DeepCollectionEquality().hash(regions),const DeepCollectionEquality().hash(departements),const DeepCollectionEquality().hash(secteurs),const DeepCollectionEquality().hash(emplois),const DeepCollectionEquality().hash(academics),const DeepCollectionEquality().hash(handicaps),const DeepCollectionEquality().hash(countries));

@override
String toString() {
  return 'Referentiel(version: $version, regions: $regions, departements: $departements, secteurs: $secteurs, emplois: $emplois, academics: $academics, handicaps: $handicaps, countries: $countries)';
}


}

/// @nodoc
abstract mixin class $ReferentielCopyWith<$Res>  {
  factory $ReferentielCopyWith(Referentiel value, $Res Function(Referentiel) _then) = _$ReferentielCopyWithImpl;
@useResult
$Res call({
 String version, List<Region> regions, List<Departement> departements, List<Secteur> secteurs, List<Emploi> emplois, List<Academic> academics, List<Handicap> handicaps, List<Pays> countries
});




}
/// @nodoc
class _$ReferentielCopyWithImpl<$Res>
    implements $ReferentielCopyWith<$Res> {
  _$ReferentielCopyWithImpl(this._self, this._then);

  final Referentiel _self;
  final $Res Function(Referentiel) _then;

/// Create a copy of Referentiel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? regions = null,Object? departements = null,Object? secteurs = null,Object? emplois = null,Object? academics = null,Object? handicaps = null,Object? countries = null,}) {
  return _then(_self.copyWith(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,regions: null == regions ? _self.regions : regions // ignore: cast_nullable_to_non_nullable
as List<Region>,departements: null == departements ? _self.departements : departements // ignore: cast_nullable_to_non_nullable
as List<Departement>,secteurs: null == secteurs ? _self.secteurs : secteurs // ignore: cast_nullable_to_non_nullable
as List<Secteur>,emplois: null == emplois ? _self.emplois : emplois // ignore: cast_nullable_to_non_nullable
as List<Emploi>,academics: null == academics ? _self.academics : academics // ignore: cast_nullable_to_non_nullable
as List<Academic>,handicaps: null == handicaps ? _self.handicaps : handicaps // ignore: cast_nullable_to_non_nullable
as List<Handicap>,countries: null == countries ? _self.countries : countries // ignore: cast_nullable_to_non_nullable
as List<Pays>,
  ));
}

}


/// Adds pattern-matching-related methods to [Referentiel].
extension ReferentielPatterns on Referentiel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Referentiel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Referentiel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Referentiel value)  $default,){
final _that = this;
switch (_that) {
case _Referentiel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Referentiel value)?  $default,){
final _that = this;
switch (_that) {
case _Referentiel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String version,  List<Region> regions,  List<Departement> departements,  List<Secteur> secteurs,  List<Emploi> emplois,  List<Academic> academics,  List<Handicap> handicaps,  List<Pays> countries)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Referentiel() when $default != null:
return $default(_that.version,_that.regions,_that.departements,_that.secteurs,_that.emplois,_that.academics,_that.handicaps,_that.countries);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String version,  List<Region> regions,  List<Departement> departements,  List<Secteur> secteurs,  List<Emploi> emplois,  List<Academic> academics,  List<Handicap> handicaps,  List<Pays> countries)  $default,) {final _that = this;
switch (_that) {
case _Referentiel():
return $default(_that.version,_that.regions,_that.departements,_that.secteurs,_that.emplois,_that.academics,_that.handicaps,_that.countries);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String version,  List<Region> regions,  List<Departement> departements,  List<Secteur> secteurs,  List<Emploi> emplois,  List<Academic> academics,  List<Handicap> handicaps,  List<Pays> countries)?  $default,) {final _that = this;
switch (_that) {
case _Referentiel() when $default != null:
return $default(_that.version,_that.regions,_that.departements,_that.secteurs,_that.emplois,_that.academics,_that.handicaps,_that.countries);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Referentiel extends Referentiel {
  const _Referentiel({required this.version, final  List<Region> regions = const <Region>[], final  List<Departement> departements = const <Departement>[], final  List<Secteur> secteurs = const <Secteur>[], final  List<Emploi> emplois = const <Emploi>[], final  List<Academic> academics = const <Academic>[], final  List<Handicap> handicaps = const <Handicap>[], final  List<Pays> countries = const <Pays>[]}): _regions = regions,_departements = departements,_secteurs = secteurs,_emplois = emplois,_academics = academics,_handicaps = handicaps,_countries = countries,super._();
  factory _Referentiel.fromJson(Map<String, dynamic> json) => _$ReferentielFromJson(json);

@override final  String version;
 final  List<Region> _regions;
@override@JsonKey() List<Region> get regions {
  if (_regions is EqualUnmodifiableListView) return _regions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_regions);
}

 final  List<Departement> _departements;
@override@JsonKey() List<Departement> get departements {
  if (_departements is EqualUnmodifiableListView) return _departements;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_departements);
}

 final  List<Secteur> _secteurs;
@override@JsonKey() List<Secteur> get secteurs {
  if (_secteurs is EqualUnmodifiableListView) return _secteurs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_secteurs);
}

 final  List<Emploi> _emplois;
@override@JsonKey() List<Emploi> get emplois {
  if (_emplois is EqualUnmodifiableListView) return _emplois;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_emplois);
}

 final  List<Academic> _academics;
@override@JsonKey() List<Academic> get academics {
  if (_academics is EqualUnmodifiableListView) return _academics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_academics);
}

 final  List<Handicap> _handicaps;
@override@JsonKey() List<Handicap> get handicaps {
  if (_handicaps is EqualUnmodifiableListView) return _handicaps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_handicaps);
}

 final  List<Pays> _countries;
@override@JsonKey() List<Pays> get countries {
  if (_countries is EqualUnmodifiableListView) return _countries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_countries);
}


/// Create a copy of Referentiel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReferentielCopyWith<_Referentiel> get copyWith => __$ReferentielCopyWithImpl<_Referentiel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReferentielToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Referentiel&&(identical(other.version, version) || other.version == version)&&const DeepCollectionEquality().equals(other._regions, _regions)&&const DeepCollectionEquality().equals(other._departements, _departements)&&const DeepCollectionEquality().equals(other._secteurs, _secteurs)&&const DeepCollectionEquality().equals(other._emplois, _emplois)&&const DeepCollectionEquality().equals(other._academics, _academics)&&const DeepCollectionEquality().equals(other._handicaps, _handicaps)&&const DeepCollectionEquality().equals(other._countries, _countries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,const DeepCollectionEquality().hash(_regions),const DeepCollectionEquality().hash(_departements),const DeepCollectionEquality().hash(_secteurs),const DeepCollectionEquality().hash(_emplois),const DeepCollectionEquality().hash(_academics),const DeepCollectionEquality().hash(_handicaps),const DeepCollectionEquality().hash(_countries));

@override
String toString() {
  return 'Referentiel(version: $version, regions: $regions, departements: $departements, secteurs: $secteurs, emplois: $emplois, academics: $academics, handicaps: $handicaps, countries: $countries)';
}


}

/// @nodoc
abstract mixin class _$ReferentielCopyWith<$Res> implements $ReferentielCopyWith<$Res> {
  factory _$ReferentielCopyWith(_Referentiel value, $Res Function(_Referentiel) _then) = __$ReferentielCopyWithImpl;
@override @useResult
$Res call({
 String version, List<Region> regions, List<Departement> departements, List<Secteur> secteurs, List<Emploi> emplois, List<Academic> academics, List<Handicap> handicaps, List<Pays> countries
});




}
/// @nodoc
class __$ReferentielCopyWithImpl<$Res>
    implements _$ReferentielCopyWith<$Res> {
  __$ReferentielCopyWithImpl(this._self, this._then);

  final _Referentiel _self;
  final $Res Function(_Referentiel) _then;

/// Create a copy of Referentiel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? regions = null,Object? departements = null,Object? secteurs = null,Object? emplois = null,Object? academics = null,Object? handicaps = null,Object? countries = null,}) {
  return _then(_Referentiel(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,regions: null == regions ? _self._regions : regions // ignore: cast_nullable_to_non_nullable
as List<Region>,departements: null == departements ? _self._departements : departements // ignore: cast_nullable_to_non_nullable
as List<Departement>,secteurs: null == secteurs ? _self._secteurs : secteurs // ignore: cast_nullable_to_non_nullable
as List<Secteur>,emplois: null == emplois ? _self._emplois : emplois // ignore: cast_nullable_to_non_nullable
as List<Emploi>,academics: null == academics ? _self._academics : academics // ignore: cast_nullable_to_non_nullable
as List<Academic>,handicaps: null == handicaps ? _self._handicaps : handicaps // ignore: cast_nullable_to_non_nullable
as List<Handicap>,countries: null == countries ? _self._countries : countries // ignore: cast_nullable_to_non_nullable
as List<Pays>,
  ));
}


}

// dart format on
