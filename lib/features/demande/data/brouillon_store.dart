import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/key_value_store.dart';
import '../../auth/application/auth_controller.dart';
import '../domain/demande.dart';

/// Brouillon local du dossier — §8.8, « non négociable ».
///
/// Le formulaire compte une trentaine de champs et deux listes dynamiques, sur
/// des réseaux souvent instables. Une saisie perdue fait abandonner le
/// candidat : le dossier est donc écrit sur l'appareil à chaque modification,
/// et n'est effacé qu'après un enregistrement serveur réussi — ou quand son
/// propriétaire se déconnecte.
///
/// **Un brouillon par compte.** Un téléphone se prête : avec une clé unique
/// pour tout l'appareil, le candidat suivant retrouvait le dossier du
/// précédent — et l'envoyait sous son propre compte en appuyant sur
/// « Enregistrer ». Le magasin est donc lié à un utilisateur ; sans
/// utilisateur connecté, il ne lit ni n'écrit rien.
class BrouillonStore {
  BrouillonStore(this._store, this._utilisateurId);

  /// Ancienne clé, commune à tout l'appareil. On ne peut pas savoir à qui
  /// appartient ce qu'elle contient : elle est effacée, jamais relue.
  static const String cleAncienne = 'brouillon_demande';

  final KeyValueStore _store;
  final int? _utilisateurId;

  String? get _cle =>
      _utilisateurId == null ? null : 'brouillon_demande_$_utilisateurId';

  Demande? lire() {
    final String? cle = _cle;
    if (cle == null) return null;
    final json = _store.readJson(cle);
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

  Future<void> ecrire(Demande demande) async {
    final String? cle = _cle;
    if (cle == null) return;
    await _store.writeJson(cle, demande.toJson());
  }

  Future<void> purger() async {
    final String? cle = _cle;
    if (cle == null) return;
    await _store.remove(cle);
  }
}

/// Magasin du brouillon de l'utilisateur **connecté**.
///
/// Recréé à chaque changement de compte : tout ce qui le surveille — à
/// commencer par le dossier en cours d'édition — repart alors de zéro.
final brouillonStoreProvider = Provider<BrouillonStore>((ref) {
  final KeyValueStore store = ref.watch(keyValueStoreProvider);
  unawaited(store.remove(BrouillonStore.cleAncienne));
  return BrouillonStore(
    store,
    ref.watch(utilisateurConnecteProvider.select((u) => u?.id)),
  );
});
