import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Conservation du jeton Sanctum dans le Keystore/Keychain.
///
/// Le jeton Sanctum est opaque et sans expiration : il n'y a pas de
/// « refresh token » (§8.5). Sur 401, on purge et on renvoie à la connexion.
class TokenStore {
  TokenStore(this._storage);

  static const String _key = 'auth_token';

  final FlutterSecureStorage _storage;
  String? _cached;

  Future<String?> read() async => _cached ??= await _storage.read(key: _key);

  Future<void> write(String token) async {
    _cached = token;
    await _storage.write(key: _key, value: token);
  }

  Future<void> clear() async {
    _cached = null;
    await _storage.delete(key: _key);
  }
}

final tokenStoreProvider = Provider<TokenStore>(
  // v11 : chiffrement AES-GCM avec clé protégée par le Keystore par défaut.
  (ref) => TokenStore(const FlutterSecureStorage()),
);
