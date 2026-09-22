import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/key_value_store.dart';
import '../domain/referentiel.dart';
import 'reference_api.dart';

/// Accès au référentiel, cache d'abord (§5.6).
///
/// Le wizard doit rester utilisable hors ligne : c'est un formulaire long,
/// rempli sur des réseaux instables. Le référentiel est donc servi depuis le
/// cache dès qu'il existe, et rafraîchi en arrière-plan pour le lancement
/// suivant — jamais au prix d'un écran de chargement.
class ReferenceRepository {
  ReferenceRepository({required ReferenceApi api, required KeyValueStore store})
    : _api = api,
      _store = store;

  static const String _cle = 'referentiel';

  final ReferenceApi _api;
  final KeyValueStore _store;

  Future<Referentiel> charger() async {
    final cache = _lireCache();
    if (cache != null) {
      unawaited(_rafraichirSilencieusement());
      return cache;
    }
    return telecharger();
  }

  /// Force une lecture serveur et remplace le cache.
  Future<Referentiel> telecharger() async {
    final referentiel = await _api.bootstrap();
    await _store.writeJson(_cle, referentiel.toJson());
    return referentiel;
  }

  Referentiel? _lireCache() {
    final json = _store.readJson(_cle);
    if (json == null) return null;
    try {
      return Referentiel.fromJson(json);
    } on Object catch (e) {
      // Le schéma a changé depuis la mise en cache : on repart du serveur.
      debugPrint('Cache référentiel illisible, ignoré : $e');
      return null;
    }
  }

  Future<void> _rafraichirSilencieusement() async {
    try {
      await telecharger();
    } on ApiException {
      // Hors ligne : le cache reste la source. Rien à signaler à l'utilisateur.
    }
  }
}

final referenceRepositoryProvider = Provider<ReferenceRepository>(
  (ref) => ReferenceRepository(
    api: ref.watch(referenceApiProvider),
    store: ref.watch(keyValueStoreProvider),
  ),
);

/// Référentiel chargé une fois pour toute la durée de vie de l'app.
final referentielProvider = FutureProvider<Referentiel>(
  (ref) => ref.watch(referenceRepositoryProvider).charger(),
);
