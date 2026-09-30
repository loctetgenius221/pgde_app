import 'package:freezed_annotation/freezed_annotation.dart';

part 'utilisateur.freezed.dart';
part 'utilisateur.g.dart';

/// Compte candidat — table `utilisateur` (§2.2).
///
/// Deux pièges du backend, absorbés ici :
/// - on se connecte avec [username], **jamais** avec l'email (§3.3) ;
/// - `roles` est du `serialize()` PHP et n'est jamais exposé : l'API renvoie
///   le booléen [isAdmin] (§6.2 D11).
@freezed
abstract class Utilisateur with _$Utilisateur {
  const factory Utilisateur({
    required int id,
    required String firstname,
    required String lastname,
    required String username,
    required String numberid,
    required String email,

    /// `enabled` en base : faux tant que l'email n'est pas vérifié (§3.1).
    /// La connexion réussit malgré tout : c'est l'app qui retient
    /// l'utilisateur sur l'écran de vérification.
    @Default(false) bool enabled,

    /// Vrai si une fiche `userdata` existe déjà — `has_profile` à la
    /// connexion (§3.2), `profile_summary.has_userdata` sur `/auth/me`
    /// (§3.3). Évite un aller-retour au démarrage pour savoir s'il faut
    /// ouvrir le wizard ou le résumé.
    @JsonKey(name: 'has_profile') @Default(false) bool hasProfile,

    /// Posé par l'administration. Absent du contrat v1 : il reste ici parce
    /// que l'accueil sait l'afficher dès que le serveur le renverra.
    @Default(false) bool recruted,
    @JsonKey(name: 'is_admin') @Default(false) bool isAdmin,
    @JsonKey(name: 'date_inscription') DateTime? dateInscription,
  }) = _Utilisateur;

  const Utilisateur._();

  factory Utilisateur.fromJson(Map<String, dynamic> json) =>
      _$UtilisateurFromJson(json);

  String get nomComplet => '$firstname $lastname';
  String get initiales =>
      '${firstname.isEmpty ? '' : firstname[0]}${lastname.isEmpty ? '' : lastname[0]}'
          .toUpperCase();
}
