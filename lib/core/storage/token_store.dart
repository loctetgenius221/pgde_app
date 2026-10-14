import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Conservation du jeton Sanctum dans le Keystore/Keychain.
///
/// Le jeton Sanctum est opaque et sans expiration : il n'y a pas de
/// « refresh token » (§8.5). Sur 401, on purge et on renvoie à la connexion.
///
/// **Aucun accès au Keystore n'est attendu sans limite.** Sur une tablette
/// Lenovo TB350XU (Android 14), le Keystore tente à chaque génération de clé
/// un provisionnement distant auprès de Google (RKPD) : ~10 s quand il échoue
/// en ligne, plusieurs minutes hors ligne. La première lecture du jeton ne
/// revenait alors jamais, et l'application restait figée sur l'écran
/// d'ouverture. Passé [_delai], on poursuit sans le Keystore — au pire, le
/// candidat devra se reconnecter.
class TokenStore {
  TokenStore(this._storage);

  static const String _key = 'auth_token';

  /// Une lecture saine prend quelques dizaines de millisecondes, mais le
  /// Keystore de certains appareils abandonne son provisionnement distant au
  /// bout de ~10 s seulement (mesuré). Couper plus tôt déconnecterait le
  /// candidat à chaque lancement sur ces appareils ; attendre davantage
  /// laisserait croire à un plantage.
  static const Duration _delai = Duration(seconds: 15);

  final FlutterSecureStorage _storage;
  String? _cached;

  Future<String?> read() async {
    if (_cached != null) return _cached;
    try {
      return _cached = await _storage.read(key: _key).timeout(_delai);
    } on TimeoutException {
      // Pas de mise en cache : la prochaine lecture retentera le Keystore.
      return null;
    } on PlatformException {
      // Donnée illisible — typiquement restaurée d'une sauvegarde alors que
      // la clé du Keystore, elle, ne l'a pas été. Sans jeton lisible, la
      // session est perdue : on repart d'un état propre.
      unawaited(_effacer());
      return null;
    }
  }

  Future<void> write(String token) async {
    // Le jeton est d'abord gardé en mémoire : même si le Keystore ne répond
    // pas, la session ouverte fonctionne jusqu'à la fermeture de l'app.
    _cached = token;
    try {
      await _storage.write(key: _key, value: token).timeout(_delai);
    } on TimeoutException {
      // Non persisté : le candidat se reconnectera au prochain lancement.
    }
  }

  Future<void> clear() async {
    _cached = null;
    await _effacer();
  }

  Future<void> _effacer() async {
    try {
      await _storage.delete(key: _key).timeout(_delai);
    } on TimeoutException {
      // Le jeton orphelin sera refusé (401) et purgé à la prochaine tentative.
    } on PlatformException {
      // Rien de plus à faire : la lecture renverra de toute façon null.
    }
  }
}

final tokenStoreProvider = Provider<TokenStore>(
  // v11 : chiffrement AES-GCM avec clé protégée par le Keystore par défaut.
  (ref) => TokenStore(const FlutterSecureStorage()),
);
