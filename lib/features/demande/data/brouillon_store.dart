import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/key_value_store.dart';
import '../domain/demande.dart';

/// Brouillon local du dossier — §8.8, « non négociable ».
///
/// Le formulaire compte une trentaine de champs et deux listes dynamiques, sur
/// des réseaux souvent instables. Une saisie perdue fait abandonner le
/// candidat : le dossier est donc écrit sur l'appareil à chaque modification,
/// et n'est effacé qu'après un enregistrement serveur réussi.
class BrouillonStore {
  BrouillonStore(this._store);

  static const String _cle = 'brouillon_demande';

  final KeyValueStore _store;

  Demande? lire() {
    final json = _store.readJson(_cle);
    if (json == null) return null;
    try {
      return Demande.fromJson(json);
    } on Object catch (e) {
      // Le modèle a changé depuis l'écriture : mieux vaut repartir du serveur
      // que de planter au démarrage sur un brouillon d'une version antérieure.
      debugPrint('Brouillon illisible, ignoré : $e');
      return null;
    }
  }

  Future<void> ecrire(Demande demande) => _store.writeJson(_cle, demande.toJson());

  Future<void> purger() => _store.remove(_cle);
}

final brouillonStoreProvider = Provider<BrouillonStore>(
  (ref) => BrouillonStore(ref.watch(keyValueStoreProvider)),
);
