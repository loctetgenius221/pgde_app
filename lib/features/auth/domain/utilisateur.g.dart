// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'utilisateur.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Utilisateur _$UtilisateurFromJson(Map<String, dynamic> json) => _Utilisateur(
  id: (json['id'] as num).toInt(),
  firstname: json['firstname'] as String,
  lastname: json['lastname'] as String,
  username: json['username'] as String,
  numberid: json['numberid'] as String,
  email: json['email'] as String,
  enabled: json['enabled'] as bool? ?? false,
  hasProfile: json['has_profile'] as bool? ?? false,
  recruted: json['recruted'] as bool? ?? false,
  isAdmin: json['is_admin'] as bool? ?? false,
  dateInscription: json['date_inscription'] == null
      ? null
      : DateTime.parse(json['date_inscription'] as String),
);

Map<String, dynamic> _$UtilisateurToJson(_Utilisateur instance) =>
    <String, dynamic>{
      'id': instance.id,
      'firstname': instance.firstname,
      'lastname': instance.lastname,
      'username': instance.username,
      'numberid': instance.numberid,
      'email': instance.email,
      'enabled': instance.enabled,
      'has_profile': instance.hasProfile,
      'recruted': instance.recruted,
      'is_admin': instance.isAdmin,
      'date_inscription': instance.dateInscription?.toIso8601String(),
    };
