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
  Future<void> demanderReinitialisation({
    required String email,
    required String numberid,
  }) async {
    await Future<void>.delayed(_latence);
    // §7.2 : les deux doivent correspondre au **même** compte. Répondre
    // différemment selon que l'email existe ou non révélerait qui est inscrit.
    final bool trouve = _comptes.values.any(
      (c) => c.utilisateur.email == email && c.utilisateur.numberid == numberid,
    );
    if (trouve) _jetonsEmis.add(email);
  }

  @override
  Future<void> reinitialiser({
    required String jeton,
    required String email,
    required String motDePasse,
  }) async {
    await Future<void>.delayed(_latence);
    if (jeton.trim() != codeDeDemonstration || !_jetonsEmis.contains(email)) {
      throw const ApiException(
        'Lien de réinitialisation invalide ou expiré.',
        statusCode: 422,
        fieldErrors: <String, List<String>>{
          'token': <String>['Ce code est invalide ou a expiré.'],
        },
      );
    }
    final MapEntry<String, _Compte> entree = _comptes.entries.firstWhere(
      (e) => e.value.utilisateur.email == email,
    );
    _comptes[entree.key] = _Compte(
      motDePasse: motDePasse,
      utilisateur: entree.value.utilisateur,
    );
    _jetonsEmis.remove(email);
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
