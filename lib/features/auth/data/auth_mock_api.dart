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

  /// Code accepté par le faux backend, pour la vérification d'email comme
  /// pour la réinitialisation. En local `MAIL_MAILER=log` n'envoie rien
  /// (§3.4) : sans code fixe, aucun de ces parcours ne serait démontrable.
  static const String codeDeDemonstration = '123456';

  @override
  Future<Utilisateur> register({
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

    final Utilisateur cree = Utilisateur(
      id: DateTime.now().millisecondsSinceEpoch % 1000000,
      firstname: firstname,
      lastname: lastname,
      username: username,
      numberid: numberid,
      email: email,
      // Le serveur force `enabled: false` : le compte naît inactif (§3.1).
    );
    _comptes[username.toLowerCase()] = _Compte(
      motDePasse: password,
      utilisateur: cree,
    );

    return cree;
  }

  @override
  Future<Session> login({
    required String identifiant,
    required String password,
  }) async {
    await Future<void>.delayed(_latence);

    // §3.3 : le même champ accepte l'email ou le nom d'utilisateur.
    final String cle = identifiant.toLowerCase();
    final _Compte? compte =
        _comptes[cle] ??
        _comptes.values
            .where((c) => c.utilisateur.email.toLowerCase() == cle)
            .firstOrNull;
    if (compte == null || compte.motDePasse != password) {
      throw const ApiException(
        'Identifiants incorrects.',
        statusCode: 422,
        fieldErrors: {
          'login': ['Identifiant ou mot de passe incorrect.'],
        },
      );
    }

    if (!compte.utilisateur.enabled) {
      throw const ApiException(
        'Veuillez activer votre compte avant de vous connecter.',
        statusCode: 403,
        code: 'email_not_verified',
      );
    }

    _connecte = compte.utilisateur.username.toLowerCase();
    return (
      token: 'mock|${compte.utilisateur.id}',
      utilisateur: compte.utilisateur,
    );
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
  Future<void> resendVerificationEmail({required String email}) async {
    await Future<void>.delayed(_latence);
  }

  @override
  Future<Utilisateur> verifierAvecCode(String code, {String? email}) async {
    await Future<void>.delayed(_latence);
    if (code.trim() != codeDeDemonstration) {
      throw const ApiException(
        'Code incorrect.',
        statusCode: 422,
        fieldErrors: <String, List<String>>{
          'code': <String>['Ce code est invalide ou a expiré.'],
        },
      );
    }
    _Compte? compte = _connecte != null ? _comptes[_connecte] : null;
    if (compte == null && email != null && email.trim().isNotEmpty) {
      compte = _comptes.values
          .where(
            (c) =>
                c.utilisateur.email.toLowerCase() == email.trim().toLowerCase(),
          )
          .firstOrNull;
    }
    compte ??= _comptes.values.where((c) => !c.utilisateur.enabled).firstOrNull;
    if (compte == null) {
      throw const ApiException('Aucun compte à activer.', statusCode: 404);
    }
    final Utilisateur active = compte.utilisateur.copyWith(enabled: true);
    final String cle = active.username.toLowerCase();
    _comptes[cle] = _Compte(motDePasse: compte.motDePasse, utilisateur: active);
    _connecte = cle;
    return active;
  }

  @override
  Future<void> demanderReinitialisation({required String email}) async {
    await Future<void>.delayed(_latence);
  }
}

class _Compte {
  const _Compte({required this.motDePasse, required this.utilisateur});

  final String motDePasse;
  final Utilisateur utilisateur;
}
