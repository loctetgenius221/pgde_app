// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'utilisateur.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Utilisateur {

 int get id; String get firstname; String get lastname; String get username; String get numberid; String get email;/// `enabled` en base : faux tant que l'email n'est pas vérifié (§3.2).
/// La connexion réussit malgré tout (bug BUG-02) : c'est l'app qui
/// aiguille vers l'écran de vérification.
 bool get enabled; bool get recruted;@JsonKey(name: 'is_admin') bool get isAdmin;/// Évite un aller-retour au démarrage : l'app sait immédiatement s'il faut
/// router vers le wizard ou vers le résumé (§7.2).
@JsonKey(name: 'has_demande') bool get hasDemande;@JsonKey(name: 'demande_id') int? get demandeId;@JsonKey(name: 'last_login') DateTime? get lastLogin;
/// Create a copy of Utilisateur
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UtilisateurCopyWith<Utilisateur> get copyWith => _$UtilisateurCopyWithImpl<Utilisateur>(this as Utilisateur, _$identity);

  /// Serializes this Utilisateur to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Utilisateur&&(identical(other.id, id) || other.id == id)&&(identical(other.firstname, firstname) || other.firstname == firstname)&&(identical(other.lastname, lastname) || other.lastname == lastname)&&(identical(other.username, username) || other.username == username)&&(identical(other.numberid, numberid) || other.numberid == numberid)&&(identical(other.email, email) || other.email == email)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.recruted, recruted) || other.recruted == recruted)&&(identical(other.isAdmin, isAdmin) || other.isAdmin == isAdmin)&&(identical(other.hasDemande, hasDemande) || other.hasDemande == hasDemande)&&(identical(other.demandeId, demandeId) || other.demandeId == demandeId)&&(identical(other.lastLogin, lastLogin) || other.lastLogin == lastLogin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,firstname,lastname,username,numberid,email,enabled,recruted,isAdmin,hasDemande,demandeId,lastLogin);

@override
String toString() {
  return 'Utilisateur(id: $id, firstname: $firstname, lastname: $lastname, username: $username, numberid: $numberid, email: $email, enabled: $enabled, recruted: $recruted, isAdmin: $isAdmin, hasDemande: $hasDemande, demandeId: $demandeId, lastLogin: $lastLogin)';
}


}

/// @nodoc
abstract mixin class $UtilisateurCopyWith<$Res>  {
  factory $UtilisateurCopyWith(Utilisateur value, $Res Function(Utilisateur) _then) = _$UtilisateurCopyWithImpl;
@useResult
$Res call({
 int id, String firstname, String lastname, String username, String numberid, String email, bool enabled, bool recruted,@JsonKey(name: 'is_admin') bool isAdmin,@JsonKey(name: 'has_demande') bool hasDemande,@JsonKey(name: 'demande_id') int? demandeId,@JsonKey(name: 'last_login') DateTime? lastLogin
});




}
/// @nodoc
class _$UtilisateurCopyWithImpl<$Res>
    implements $UtilisateurCopyWith<$Res> {
  _$UtilisateurCopyWithImpl(this._self, this._then);

  final Utilisateur _self;
  final $Res Function(Utilisateur) _then;

/// Create a copy of Utilisateur
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? firstname = null,Object? lastname = null,Object? username = null,Object? numberid = null,Object? email = null,Object? enabled = null,Object? recruted = null,Object? isAdmin = null,Object? hasDemande = null,Object? demandeId = freezed,Object? lastLogin = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,firstname: null == firstname ? _self.firstname : firstname // ignore: cast_nullable_to_non_nullable
as String,lastname: null == lastname ? _self.lastname : lastname // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,numberid: null == numberid ? _self.numberid : numberid // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,recruted: null == recruted ? _self.recruted : recruted // ignore: cast_nullable_to_non_nullable
as bool,isAdmin: null == isAdmin ? _self.isAdmin : isAdmin // ignore: cast_nullable_to_non_nullable
as bool,hasDemande: null == hasDemande ? _self.hasDemande : hasDemande // ignore: cast_nullable_to_non_nullable
as bool,demandeId: freezed == demandeId ? _self.demandeId : demandeId // ignore: cast_nullable_to_non_nullable
as int?,lastLogin: freezed == lastLogin ? _self.lastLogin : lastLogin // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Utilisateur].
extension UtilisateurPatterns on Utilisateur {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Utilisateur value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Utilisateur() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Utilisateur value)  $default,){
final _that = this;
switch (_that) {
case _Utilisateur():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Utilisateur value)?  $default,){
final _that = this;
switch (_that) {
case _Utilisateur() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String firstname,  String lastname,  String username,  String numberid,  String email,  bool enabled,  bool recruted, @JsonKey(name: 'is_admin')  bool isAdmin, @JsonKey(name: 'has_demande')  bool hasDemande, @JsonKey(name: 'demande_id')  int? demandeId, @JsonKey(name: 'last_login')  DateTime? lastLogin)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Utilisateur() when $default != null:
return $default(_that.id,_that.firstname,_that.lastname,_that.username,_that.numberid,_that.email,_that.enabled,_that.recruted,_that.isAdmin,_that.hasDemande,_that.demandeId,_that.lastLogin);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String firstname,  String lastname,  String username,  String numberid,  String email,  bool enabled,  bool recruted, @JsonKey(name: 'is_admin')  bool isAdmin, @JsonKey(name: 'has_demande')  bool hasDemande, @JsonKey(name: 'demande_id')  int? demandeId, @JsonKey(name: 'last_login')  DateTime? lastLogin)  $default,) {final _that = this;
switch (_that) {
case _Utilisateur():
return $default(_that.id,_that.firstname,_that.lastname,_that.username,_that.numberid,_that.email,_that.enabled,_that.recruted,_that.isAdmin,_that.hasDemande,_that.demandeId,_that.lastLogin);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String firstname,  String lastname,  String username,  String numberid,  String email,  bool enabled,  bool recruted, @JsonKey(name: 'is_admin')  bool isAdmin, @JsonKey(name: 'has_demande')  bool hasDemande, @JsonKey(name: 'demande_id')  int? demandeId, @JsonKey(name: 'last_login')  DateTime? lastLogin)?  $default,) {final _that = this;
switch (_that) {
case _Utilisateur() when $default != null:
return $default(_that.id,_that.firstname,_that.lastname,_that.username,_that.numberid,_that.email,_that.enabled,_that.recruted,_that.isAdmin,_that.hasDemande,_that.demandeId,_that.lastLogin);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Utilisateur extends Utilisateur {
  const _Utilisateur({required this.id, required this.firstname, required this.lastname, required this.username, required this.numberid, required this.email, this.enabled = false, this.recruted = false, @JsonKey(name: 'is_admin') this.isAdmin = false, @JsonKey(name: 'has_demande') this.hasDemande = false, @JsonKey(name: 'demande_id') this.demandeId, @JsonKey(name: 'last_login') this.lastLogin}): super._();
  factory _Utilisateur.fromJson(Map<String, dynamic> json) => _$UtilisateurFromJson(json);

@override final  int id;
@override final  String firstname;
@override final  String lastname;
@override final  String username;
@override final  String numberid;
@override final  String email;
/// `enabled` en base : faux tant que l'email n'est pas vérifié (§3.2).
/// La connexion réussit malgré tout (bug BUG-02) : c'est l'app qui
/// aiguille vers l'écran de vérification.
@override@JsonKey() final  bool enabled;
@override@JsonKey() final  bool recruted;
@override@JsonKey(name: 'is_admin') final  bool isAdmin;
/// Évite un aller-retour au démarrage : l'app sait immédiatement s'il faut
/// router vers le wizard ou vers le résumé (§7.2).
@override@JsonKey(name: 'has_demande') final  bool hasDemande;
@override@JsonKey(name: 'demande_id') final  int? demandeId;
@override@JsonKey(name: 'last_login') final  DateTime? lastLogin;

/// Create a copy of Utilisateur
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UtilisateurCopyWith<_Utilisateur> get copyWith => __$UtilisateurCopyWithImpl<_Utilisateur>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UtilisateurToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Utilisateur&&(identical(other.id, id) || other.id == id)&&(identical(other.firstname, firstname) || other.firstname == firstname)&&(identical(other.lastname, lastname) || other.lastname == lastname)&&(identical(other.username, username) || other.username == username)&&(identical(other.numberid, numberid) || other.numberid == numberid)&&(identical(other.email, email) || other.email == email)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.recruted, recruted) || other.recruted == recruted)&&(identical(other.isAdmin, isAdmin) || other.isAdmin == isAdmin)&&(identical(other.hasDemande, hasDemande) || other.hasDemande == hasDemande)&&(identical(other.demandeId, demandeId) || other.demandeId == demandeId)&&(identical(other.lastLogin, lastLogin) || other.lastLogin == lastLogin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,firstname,lastname,username,numberid,email,enabled,recruted,isAdmin,hasDemande,demandeId,lastLogin);

@override
String toString() {
  return 'Utilisateur(id: $id, firstname: $firstname, lastname: $lastname, username: $username, numberid: $numberid, email: $email, enabled: $enabled, recruted: $recruted, isAdmin: $isAdmin, hasDemande: $hasDemande, demandeId: $demandeId, lastLogin: $lastLogin)';
}


}

/// @nodoc
abstract mixin class _$UtilisateurCopyWith<$Res> implements $UtilisateurCopyWith<$Res> {
  factory _$UtilisateurCopyWith(_Utilisateur value, $Res Function(_Utilisateur) _then) = __$UtilisateurCopyWithImpl;
@override @useResult
$Res call({
 int id, String firstname, String lastname, String username, String numberid, String email, bool enabled, bool recruted,@JsonKey(name: 'is_admin') bool isAdmin,@JsonKey(name: 'has_demande') bool hasDemande,@JsonKey(name: 'demande_id') int? demandeId,@JsonKey(name: 'last_login') DateTime? lastLogin
});




}
/// @nodoc
class __$UtilisateurCopyWithImpl<$Res>
    implements _$UtilisateurCopyWith<$Res> {
  __$UtilisateurCopyWithImpl(this._self, this._then);

  final _Utilisateur _self;
  final $Res Function(_Utilisateur) _then;

/// Create a copy of Utilisateur
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? firstname = null,Object? lastname = null,Object? username = null,Object? numberid = null,Object? email = null,Object? enabled = null,Object? recruted = null,Object? isAdmin = null,Object? hasDemande = null,Object? demandeId = freezed,Object? lastLogin = freezed,}) {
  return _then(_Utilisateur(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,firstname: null == firstname ? _self.firstname : firstname // ignore: cast_nullable_to_non_nullable
as String,lastname: null == lastname ? _self.lastname : lastname // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,numberid: null == numberid ? _self.numberid : numberid // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,recruted: null == recruted ? _self.recruted : recruted // ignore: cast_nullable_to_non_nullable
as bool,isAdmin: null == isAdmin ? _self.isAdmin : isAdmin // ignore: cast_nullable_to_non_nullable
as bool,hasDemande: null == hasDemande ? _self.hasDemande : hasDemande // ignore: cast_nullable_to_non_nullable
as bool,demandeId: freezed == demandeId ? _self.demandeId : demandeId // ignore: cast_nullable_to_non_nullable
as int?,lastLogin: freezed == lastLogin ? _self.lastLogin : lastLogin // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
