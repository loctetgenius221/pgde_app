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
  recruted: json['recruted'] as bool? ?? false,
  isAdmin: json['is_admin'] as bool? ?? false,
  hasDemande: json['has_demande'] as bool? ?? false,
  demandeId: (json['demande_id'] as num?)?.toInt(),
  lastLogin: json['last_login'] == null
      ? null
      : DateTime.parse(json['last_login'] as String),
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
      'recruted': instance.recruted,
      'is_admin': instance.isAdmin,
      'has_demande': instance.hasDemande,
      'demande_id': instance.demandeId,
      'last_login': instance.lastLogin?.toIso8601String(),
    };
