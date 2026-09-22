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

    /// `enabled` en base : faux tant que l'email n'est pas vérifié (§3.2).
    /// La connexion réussit malgré tout (bug BUG-02) : c'est l'app qui
    /// aiguille vers l'écran de vérification.
    @Default(false) bool enabled,
    @Default(false) bool recruted,
    @JsonKey(name: 'is_admin') @Default(false) bool isAdmin,

    /// Évite un aller-retour au démarrage : l'app sait immédiatement s'il faut
    /// router vers le wizard ou vers le résumé (§7.2).
    @JsonKey(name: 'has_demande') @Default(false) bool hasDemande,
    @JsonKey(name: 'demande_id') int? demandeId,
    @JsonKey(name: 'last_login') DateTime? lastLogin,
  }) = _Utilisateur;

  const Utilisateur._();

  factory Utilisateur.fromJson(Map<String, dynamic> json) =>
      _$UtilisateurFromJson(json);

  String get nomComplet => '$firstname $lastname';
  String get initiales =>
      '${firstname.isEmpty ? '' : firstname[0]}${lastname.isEmpty ? '' : lastname[0]}'
          .toUpperCase();
}
