import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';

import 'key_value_store.dart';

/// Chiffrement des données personnelles gardées sur l'appareil — audit
/// SEC-002.
///
/// Le brouillon du dossier (handicap, naissance, téléphones) et l'historique
/// du chatbot (CNI, matricule) vivent dans SharedPreferences, c'est-à-dire
/// dans un fichier XML (Android) ou un plist (iOS) lisible par quiconque
/// accède au stockage de l'app : sauvegarde iCloud, appareil rooté, outil de
/// diagnostic. Ils y sont désormais écrits chiffrés en **AES-256-GCM**, avec
/// une clé propre à l'appareil rangée dans le Keystore/Keychain, comme le
/// jeton de session.
///
/// GCM authentifie en plus de chiffrer : une donnée altérée est rejetée au
/// lieu d'être relue de travers. Le nom de l'entrée (qui porte l'identifiant
/// du compte) est lié au chiffré comme donnée associée : le brouillon d'un
/// compte recopié sous la clé d'un autre ne se déchiffre pas.
///
/// **Sans clé, rien n'est écrit.** Si le Keystore ne répond pas (cf.
/// `TokenStore` : certains appareils le bloquent plusieurs minutes), le
/// dossier reste en mémoire le temps de la session, mais n'est jamais
/// écrit en clair.
class CoffreLocal {
  CoffreLocal(FlutterSecureStorage keystore) : _keystore = keystore;

  /// Coffre déjà ouvert, sans Keystore : pour les tests.
  @visibleForTesting
  CoffreLocal.enMemoire() : _keystore = null, _cle = _aleatoire(_tailleCle);

  static const String _nomCle = 'cle_donnees_locales';
  static const String _prefixe = 'v1:';
  static const int _tailleCle = 32; // AES-256
  static const int _tailleNonce = 12; // recommandé pour GCM
  static const int _tailleTag = 16; // 128 bits

  /// Même délai que pour le jeton (voir `TokenStore`).
  static const Duration _delai = Duration(seconds: 15);

  final FlutterSecureStorage? _keystore;
  Uint8List? _cle;
  Future<void>? _ouverture;

  bool get ouvert => _cle != null;

  /// Charge la clé, ou la crée au premier lancement. Ne lève jamais : en cas
  /// d'échec, le coffre reste fermé et une prochaine ouverture réessaiera.
  Future<void> ouvrir() => _ouverture ??= _charger();

  Future<void> _charger() async {
    final FlutterSecureStorage? keystore = _keystore;
    if (keystore == null || _cle != null) return;
    try {
      Uint8List? cle;
      try {
        final String? existante = await keystore
            .read(key: _nomCle)
            .timeout(_delai);
        if (existante != null) cle = base64Decode(existante);
      } on TimeoutException {
        return; // Keystore muet : surtout ne pas remplacer une clé existante
      } on Exception {
        cle =
            null; // clé illisible : les données qu'elle protégeait sont perdues
      }
      if (cle == null || cle.length != _tailleCle) {
        cle = _aleatoire(_tailleCle);
        await keystore
            .write(key: _nomCle, value: base64Encode(cle))
            .timeout(_delai);
      }
      _cle = cle;
    } on Exception {
      // Clé non enregistrée : l'utiliser rendrait illisible au prochain
      // lancement tout ce qu'elle aurait chiffré. Le coffre reste fermé.
    } finally {
      if (_cle == null) _ouverture = null;
    }
  }

  /// `null` si le coffre est fermé.
  String? chiffrer(String clair, {required String contexte}) {
    final Uint8List? cle = _cle;
    if (cle == null) return null;
    final Uint8List nonce = _aleatoire(_tailleNonce);
    final Uint8List chiffre = _gcm(
      chiffrement: true,
      cle: cle,
      nonce: nonce,
      contexte: contexte,
    ).process(utf8.encode(clair));
    return _prefixe +
        base64Encode(
          Uint8List(nonce.length + chiffre.length)
            ..setAll(0, nonce)
            ..setAll(nonce.length, chiffre),
        );
  }

  /// `null` si le coffre est fermé, ou si [valeur] a été altérée, chiffrée
  /// avec une autre clé ou sous un autre [contexte].
  String? dechiffrer(String valeur, {required String contexte}) {
    final Uint8List? cle = _cle;
    if (cle == null || !estChiffre(valeur)) return null;
    try {
      final Uint8List octets = base64Decode(valeur.substring(_prefixe.length));
      if (octets.length < _tailleNonce + _tailleTag) return null;
      return utf8.decode(
        _gcm(
          chiffrement: false,
          cle: cle,
          nonce: Uint8List.sublistView(octets, 0, _tailleNonce),
          contexte: contexte,
        ).process(Uint8List.sublistView(octets, _tailleNonce)),
      );
    } on Object {
      // Tag GCM invalide (InvalidCipherTextException), base64 ou UTF-8 cassé.
      return null;
    }
  }

  static bool estChiffre(String valeur) => valeur.startsWith(_prefixe);

  static GCMBlockCipher _gcm({
    required bool chiffrement,
    required Uint8List cle,
    required Uint8List nonce,
    required String contexte,
  }) => GCMBlockCipher(AESEngine())
    ..init(
      chiffrement,
      AEADParameters(
        KeyParameter(cle),
        _tailleTag * 8,
        nonce,
        utf8.encode(contexte),
      ),
    );

  static Uint8List _aleatoire(int taille) {
    final Random hasard = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(taille, (_) => hasard.nextInt(256)),
    );
  }
}

/// Blobs JSON chiffrés par [CoffreLocal], avec la même interface que
/// [KeyValueStore] pour les magasins qui l'utilisent.
class StockageChiffre {
  StockageChiffre(this._store, this._coffre);

  final KeyValueStore _store;
  final CoffreLocal _coffre;

  Map<String, dynamic>? readJson(String cle) {
    if (!_coffre.ouvert) return null;
    final String? brut = _store.readString(cle);
    if (brut == null) return null;

    if (!CoffreLocal.estChiffre(brut)) {
      // Écrit en clair par une version antérieure : repris, puis réécrit
      // chiffré pour que le clair disparaisse du disque.
      final Map<String, dynamic>? json = _store.readJson(cle);
      unawaited(json == null ? _store.remove(cle) : writeJson(cle, json));
      return json;
    }

    final String? clair = _coffre.dechiffrer(brut, contexte: cle);
    if (clair == null) {
      // Clé perdue (réinstallation, Keystore réinitialisé) ou donnée
      // altérée : l'entrée ne sera plus jamais lisible.
      unawaited(_store.remove(cle));
      return null;
    }
    try {
      return jsonDecode(clair) as Map<String, dynamic>;
    } on Object {
      return null;
    }
  }

  /// Sans clé, n'écrit rien : jamais de repli en clair.
  Future<void> writeJson(String cle, Map<String, dynamic> valeur) async {
    final String? chiffre = _coffre.chiffrer(jsonEncode(valeur), contexte: cle);
    if (chiffre == null) return;
    await _store.writeString(cle, chiffre);
  }

  /// Fonctionne même coffre fermé : une déconnexion doit toujours purger.
  Future<void> remove(String cle) => _store.remove(cle);
}

/// Ouvert par `AuthController` avant que la session soit déterminée : aucun
/// compte n'est donc connecté tant que la clé n'est pas chargée (ou
/// définitivement indisponible).
final coffreLocalProvider = Provider<CoffreLocal>(
  (ref) => CoffreLocal(const FlutterSecureStorage()),
);
