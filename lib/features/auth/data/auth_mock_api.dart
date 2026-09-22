import '../../../core/network/api_exception.dart';
import '../domain/utilisateur.dart';
import 'auth_api.dart';

/// Faux backend en mémoire, utilisé tant que `/api/v1` n'existe pas.
///
/// Il reproduit délibérément les **comportements du serveur**, pas seulement
/// ses données : règles d'unicité de `utilisateur` (§3.2), messages d'erreur
/// français déjà traduits côté Laravel, format 422 par champ (§7.1), et le
/// fait qu'un compte naisse désactivé. Les écrans écrits contre ce mock
/// fonctionneront donc face à la vraie API.
class MockAuthApi implements AuthApi {
  static const Duration _latence = Duration(milliseconds: 600);

  static final Map<String, _Compte> _comptes = <String, _Compte>{
    'msagna': const _Compte(
      motDePasse: 'password',
      utilisateur: Utilisateur(
        id: 332099,
        firstname: 'Moussa',
        lastname: 'Sagna',
        username: 'msagna',
        numberid: '1234567890123',
        email: 'msagna@example.com',
        enabled: true,
      ),
    ),
    'anouveau': const _Compte(
      motDePasse: 'password',
      utilisateur: Utilisateur(
        id: 332100,
        firstname: 'Awa',
        lastname: 'Nouveau',
        username: 'anouveau',
        numberid: '9876543210987',
        email: 'awa@example.com',
      ),
    ),
  };

  static String? _connecte;

  @override
  Future<void> register({
    required String firstname,
    required String lastname,
    required String username,
    required String numberid,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(_latence);

    final erreurs = <String, List<String>>{
      if (_comptes.containsKey(username.toLowerCase()))
        'username': const ["Ce nom d'utilisateur est déjà pris."],
      if (_comptes.values.any((c) => c.utilisateur.email == email))
        'email': const ['Cet email est déjà utilisé.'],
      if (_comptes.values.any((c) => c.utilisateur.numberid == numberid))
        'numberid': const ['Ce cni ou passport existe déjà.'],
    };
    if (erreurs.isNotEmpty) {
      throw ApiException(
        'Certaines informations sont invalides.',
        statusCode: 422,
        fieldErrors: erreurs,
      );
    }

    _comptes[username.toLowerCase()] = _Compte(
      motDePasse: password,
      utilisateur: Utilisateur(
        id: DateTime.now().millisecondsSinceEpoch % 1000000,
        firstname: firstname,
        lastname: lastname,
        username: username,
        numberid: numberid,
        email: email,
        // Le serveur force `enabled = 0` : le compte naît inactif (§3.2).
      ),
    );
  }

  @override
  Future<Session> login({
    required String username,
    required String password,
  }) async {
    await Future<void>.delayed(_latence);

    final compte = _comptes[username.toLowerCase()];
    if (compte == null || compte.motDePasse != password) {
      throw const ApiException(
        'Identifiants incorrects.',
        statusCode: 422,
        fieldErrors: {
          'username': ["Nom d'utilisateur ou mot de passe incorrect."],
        },
      );
    }

    // Le serveur laisse passer un compte non vérifié (BUG-02) : l'app reçoit
    // le jeton et `enabled: false`, puis aiguille vers la vérification (§3.3).
    _connecte = compte.utilisateur.username.toLowerCase();
    return (token: 'mock|${compte.utilisateur.id}', utilisateur: compte.utilisateur);
  }

  @override
  Future<Utilisateur> me() async {
    await Future<void>.delayed(_latence);
    final compte = _comptes[_connecte];
    if (compte == null) {
      throw const ApiException('Non authentifié.', statusCode: 401);
    }
    return compte.utilisateur;
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(_latence);
    _connecte = null;
  }

  @override
  Future<void> resendVerificationEmail() async {
    await Future<void>.delayed(_latence);
    // Raccourci de développement assumé : en local `MAIL_MAILER=log`, aucun
    // mail ne part (§3.4). Le renvoi active donc directement le compte, pour
    // que le parcours complet soit parcourable sans serveur de mail.
    final compte = _comptes[_connecte];
    if (compte != null) {
      _comptes[_connecte!] = _Compte(
        motDePasse: compte.motDePasse,
        utilisateur: compte.utilisateur.copyWith(enabled: true),
      );
    }
  }
}

class _Compte {
  const _Compte({required this.motDePasse, required this.utilisateur});

  final String motDePasse;
  final Utilisateur utilisateur;
}
