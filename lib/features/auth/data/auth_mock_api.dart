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

  /// Emails ayant demandé une réinitialisation.
  static final Set<String> _jetonsEmis = <String>{};

  /// Code accepté par le faux backend, pour la vérification d'email comme
  /// pour la réinitialisation. En local `MAIL_MAILER=log` n'envoie rien
  /// (§3.4) : sans code fixe, aucun de ces parcours ne serait démontrable.
  static const String codeDeDemonstration = '123456';

  @override
  Future<Session> register({
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

    // §3.1 : un jeton est émis **malgré** le compte désactivé. L'app est
    // donc authentifiée dès l'inscription, et c'est le routeur qui la retient
    // sur l'écran de vérification.
    _connecte = username.toLowerCase();
    return (token: 'mock|${cree.id}', utilisateur: cree);
  }

  @override
  Future<Session> login({
    required String identifiant,
    required String password,
  }) async {
    await Future<void>.delayed(_latence);

    // §3.2 : le même champ accepte l'email ou le nom d'utilisateur.
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
        fieldErrors: {'login': ['Identifiant ou mot de passe incorrect.']},
      );
    }

    // Un compte non vérifié se connecte quand même : l'app reçoit le jeton
    // et `enabled: false`, puis aiguille vers la vérification (§3.2).
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
  Future<void> resendVerificationEmail() async {
    await Future<void>.delayed(_latence);
    // Le renvoi n'active plus rien : c'est le code saisi qui active le compte
    // (§3.4, option OTP). En local `MAIL_MAILER=log` n'envoie aucun mail,
    // d'où le [codeDeDemonstration] fixe.
  }

  @override
  Future<Utilisateur> verifierAvecCode(String code) async {
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
    final _Compte compte = _compteConnecte();
    final Utilisateur active = compte.utilisateur.copyWith(enabled: true);
    _comptes[_connecte!] = _Compte(
      motDePasse: compte.motDePasse,
      utilisateur: active,
    );
    return active;
  }

  @override
  Future<void> changerMotDePasse({
    required String actuel,
    required String nouveau,
  }) async {
    await Future<void>.delayed(_latence);
    final _Compte compte = _compteConnecte();
    if (compte.motDePasse != actuel) {
      throw const ApiException(
        'Mot de passe actuel incorrect.',
        statusCode: 422,
        fieldErrors: <String, List<String>>{
          'current_password': <String>['Ce mot de passe ne correspond pas.'],
        },
      );
    }
    _comptes[_connecte!] = _Compte(
      motDePasse: nouveau,
      utilisateur: compte.utilisateur,
    );
  }

  @override
  Future<void> demanderReinitialisation({required String email}) async {
    await Future<void>.delayed(_latence);
    // §3.5 : la réponse est la même que l'email existe ou non. Distinguer
    // les deux cas révélerait qui est inscrit sur la plateforme.
    if (_comptes.values.any((c) => c.utilisateur.email == email)) {
      _jetonsEmis.add(email);
    }
  }

  @override
  Future<bool> estDisponible({
    String? username,
    String? email,
    String? numberid,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (username != null) return !_comptes.containsKey(username.toLowerCase());
    if (email != null) {
      return !_comptes.values.any((c) => c.utilisateur.email == email);
    }
    if (numberid != null) {
      return !_comptes.values.any((c) => c.utilisateur.numberid == numberid);
    }
    return true;
  }

  _Compte _compteConnecte() {
    final _Compte? compte = _comptes[_connecte];
    if (compte == null) {
      throw const ApiException('Non authentifié.', statusCode: 401);
    }
    return compte;
  }
}

class _Compte {
  const _Compte({required this.motDePasse, required this.utilisateur});

  final String motDePasse;
  final Utilisateur utilisateur;
}
