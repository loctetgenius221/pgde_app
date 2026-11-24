import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pgde_app/core/storage/token_store.dart';

/// Keystore qui ne répond jamais — le comportement observé sur une tablette
/// Lenovo hors ligne, où l'app restait figée sur l'écran d'ouverture.
class _KeystoreMuet extends FlutterSecureStorage {
  const _KeystoreMuet();

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) => Completer<String?>().future;

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) => Completer<void>().future;
}

/// Donnée chiffrée illisible : restaurée d'une sauvegarde sans sa clé.
class _KeystoreCorrompu extends FlutterSecureStorage {
  const _KeystoreCorrompu();

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => throw PlatformException(code: 'BadPaddingException');

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {}
}

void main() {
  // `testWidgets` fait tourner une horloge simulée : `pump` avance le temps
  // sans attendre réellement les secondes du délai.
  testWidgets('un Keystore muet ne fige pas le démarrage', (tester) async {
    String? lu = 'non résolu';
    bool fini = false;
    unawaited(
      TokenStore(const _KeystoreMuet()).read().then((v) {
        lu = v;
        fini = true;
      }),
    );

    await tester.pump(const Duration(seconds: 14));
    expect(fini, isFalse, reason: 'on laisse au Keystore le temps de répondre');

    await tester.pump(const Duration(seconds: 2));
    expect(fini, isTrue, reason: 'passé le délai, on poursuit sans lui');
    expect(lu, isNull);
  });

  testWidgets('une écriture bloquée garde la session ouverte en mémoire', (
    tester,
  ) async {
    final TokenStore store = TokenStore(const _KeystoreMuet());
    bool ecrit = false;
    unawaited(store.write('jeton').then((_) => ecrit = true));
    await tester.pump(const Duration(seconds: 16));
    expect(ecrit, isTrue);

    expect(await store.read(), 'jeton');
  });

  test('un jeton illisible équivaut à une session absente', () async {
    expect(await TokenStore(const _KeystoreCorrompu()).read(), isNull);
  });
}
