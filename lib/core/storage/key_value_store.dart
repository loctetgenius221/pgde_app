import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistance locale des données non sensibles : référentiel mis en cache et
/// brouillon du wizard, stockés en blobs JSON.
///
/// Voir ADR-002 : le référentiel (~700 lignes quasi statiques) est chargé
/// intégralement en mémoire de toute façon. Une base embarquée n'apporterait
/// ici que des adaptateurs générés et une initialisation asynchrone.
class KeyValueStore {
  KeyValueStore(this._prefs);

  final SharedPreferences _prefs;

  Map<String, dynamic>? readJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } on FormatException {
      return null; // cache corrompu : on repart d'une lecture serveur
    }
  }

  Future<void> writeJson(String key, Map<String, dynamic> value) =>
      _prefs.setString(key, jsonEncode(value));

  bool readBool(String key, {bool defaut = false}) =>
      _prefs.getBool(key) ?? defaut;

  Future<void> writeBool(String key, {required bool value}) =>
      _prefs.setBool(key, value);

  Future<void> remove(String key) => _prefs.remove(key);
}

/// Surchargé dans `main()`, une fois `SharedPreferences` initialisé.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider doit être surchargé dans main()'),
);

final keyValueStoreProvider = Provider<KeyValueStore>(
  (ref) => KeyValueStore(ref.watch(sharedPreferencesProvider)),
);
