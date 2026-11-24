import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/session/session_expiry.dart';
import '../../../core/storage/token_store.dart';
import '../data/auth_api.dart';
import '../domain/utilisateur.dart';

/// État de session de l'application.
///
/// - `AsyncLoading` : restauration en cours au démarrage ;
/// - `AsyncData(null)` : déconnecté ;
/// - `AsyncData(utilisateur)` : connecté ;
/// - `AsyncError` : la session n'a **pas pu** être déterminée (serveur
///   injoignable). Distinct de « déconnecté » : on n'éjecte pas un
///   utilisateur parce que son réseau a coupé.
///
/// Les échecs d'une action de l'utilisateur (mauvais mot de passe) ne passent
/// pas par cet état : ils sont levés à l'appelant, qui les affiche dans son
/// formulaire. L'état global ne décrit que la session, jamais un incident de
/// saisie.
class AuthController extends AsyncNotifier<Utilisateur?> {
  @override
  Future<Utilisateur?> build() async {
    // La couche réseau signale les 401 sans connaître ce module (§core/session).
    final expiry = ref.watch(sessionExpiryProvider);
    void surExpiration() => ref.invalidateSelf();
    expiry.addListener(surExpiration);
    ref.onDispose(() => expiry.removeListener(surExpiration));

    final token = await ref.watch(tokenStoreProvider).read();
    if (token == null) return null;

    try {
      return await ref.watch(authApiProvider).me();
    } on ApiException catch (e) {
      if (e.isUnauthorized) return null; // jeton périmé : session terminée
      rethrow; // panne réseau : l'écran de démarrage propose de réessayer
    }
  }

  /// [identifiant] vaut l'email **ou** le nom d'utilisateur : le serveur
  /// accepte les deux sur le même champ (contrat §3.2).
  Future<void> connexion({
    required String identifiant,
    required String password,
  }) async {
    final session = await ref
        .read(authApiProvider)
        .login(identifiant: identifiant, password: password);
    await _ouvrir(session);
  }

  /// L'inscription crée le compte sans émettre de jeton (§3.1) : le candidat
  /// doit activer son compte via l'e-mail reçu avant de se connecter.
  Future<Utilisateur> inscription({
    required String firstname,
    required String lastname,
    required String username,
    required String numberid,
    required String email,
    required String password,
  }) async {
    return ref
        .read(authApiProvider)
        .register(
          firstname: firstname,
          lastname: lastname,
          username: username,
          numberid: numberid,
          email: email,
          password: password,
        );
  }

  Future<void> _ouvrir(Session session) async {
    await ref.read(tokenStoreProvider).write(session.token);
    state = AsyncData(session.utilisateur);
  }

  Future<void> deconnexion() async {
    try {
      await ref.read(authApiProvider).logout();
    } on ApiException {
      // Le jeton est peut-être déjà révoqué côté serveur : la déconnexion
      // locale doit aboutir quoi qu'il arrive.
    }
    await ref.read(tokenStoreProvider).clear();
    state = const AsyncData(null);
  }

  /// §3.2 — Renvoie le lien d'activation du compte par e-mail.
  Future<void> renvoyerEmailDeVerification({String? email}) {
    final String? adresse = email ?? state.value?.email;
    if (adresse == null || adresse.trim().isEmpty) {
      throw const ApiException('Une adresse email est requise.');
    }
    return ref
        .read(authApiProvider)
        .resendVerificationEmail(email: adresse.trim());
  }

  /// Active le compte avec le code reçu par email (§3.4, option OTP factice).
  Future<void> verifierAvecCode(String code, {String? email}) async {
    state = AsyncData(
      await ref.read(authApiProvider).verifierAvecCode(code, email: email),
    );
  }

  /// §3.5 — l'email seul : le serveur envoie le lien de réinitialisation.
  /// La suite se passe hors de l'app, la v1 n'exposant pas de route pour
  /// consommer le jeton reçu.
  Future<void> demanderReinitialisation({required String email}) =>
      ref.read(authApiProvider).demanderReinitialisation(email: email);

  /// Recharge le profil, par exemple après validation de l'email.
  Future<void> rafraichir() async {
    state = AsyncData(await ref.read(authApiProvider).me());
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, Utilisateur?>(
      AuthController.new,
      // The splash screen exposes a manual retry for session restoration.
      retry: (_, _) => null,
    );

/// Raccourcis de lecture pour le routeur, sans exposer `AsyncValue` partout.
final utilisateurConnecteProvider = Provider<Utilisateur?>(
  (ref) => ref.watch(authControllerProvider).value,
);
