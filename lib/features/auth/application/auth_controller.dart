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

  /// L'inscription authentifie déjà (§3.1) : le serveur émet un jeton avec le
  /// compte, encore désactivé. On ouvre donc la session tout de suite — le
  /// routeur se charge de retenir l'utilisateur sur l'écran de vérification.
  Future<void> inscription({
    required String firstname,
    required String lastname,
    required String username,
    required String numberid,
    required String email,
    required String password,
  }) async {
    final session = await ref
        .read(authApiProvider)
        .register(
          firstname: firstname,
          lastname: lastname,
          username: username,
          numberid: numberid,
          email: email,
          password: password,
        );
    await _ouvrir(session);
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

  Future<void> renvoyerEmailDeVerification() =>
      ref.read(authApiProvider).resendVerificationEmail();

  /// Active le compte avec le code reçu par email (§3.4, option OTP).
  Future<void> verifierAvecCode(String code) async {
    state = AsyncData(await ref.read(authApiProvider).verifierAvecCode(code));
  }

  /// Les trois opérations de mot de passe ne changent **pas** l'état de
  /// session : elles réussissent ou lèvent, et c'est le formulaire appelant
  /// qui l'affiche.
  Future<void> changerMotDePasse({
    required String actuel,
    required String nouveau,
  }) => ref
      .read(authApiProvider)
      .changerMotDePasse(actuel: actuel, nouveau: nouveau);

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
    AsyncNotifierProvider<AuthController, Utilisateur?>(AuthController.new);

/// Raccourcis de lecture pour le routeur, sans exposer `AsyncValue` partout.
final utilisateurConnecteProvider = Provider<Utilisateur?>(
  (ref) => ref.watch(authControllerProvider).value,
);
