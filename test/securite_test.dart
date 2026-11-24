import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pgde_app/core/network/api_client.dart';
import 'package:pgde_app/core/network/auth_interceptor.dart';
import 'package:pgde_app/core/session/session_expiry.dart';
import 'package:pgde_app/core/storage/token_store.dart';
import 'package:pgde_app/features/demande/data/demande_api.dart';

/// Non-régression des correctifs de l'audit du 23 novembre 2026
/// (`AUDIT_2026-11-23.md`).
class _Capture implements HttpClientAdapter {
  final List<RequestOptions> vues = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    vues.add(options);
    return ResponseBody.fromString('{}', 200);
  }

  @override
  void close({bool force = false}) {}
}

class _Stockage extends Fake implements FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => '15|jeton-secret';
}

void main() {
  group('SEC-001 — le jeton ne quitte pas le serveur de l’API', () {
    const String api = 'https://emploi.fonctionpublique.sn/api/v1';

    Future<RequestOptions> requete(
      String url, {
      Map<String, dynamic>? entetes,
    }) async {
      final _Capture capture = _Capture();
      final Dio dio = Dio(BaseOptions(baseUrl: api))
        ..httpClientAdapter = capture
        ..interceptors.add(
          AuthInterceptor(
            tokens: TokenStore(_Stockage()),
            expiry: SessionExpiry(),
            apiBaseUrl: api,
          ),
        );
      await dio.get<dynamic>(url, options: Options(headers: entetes));
      return capture.vues.single;
    }

    test('chemin relatif : jeton présent', () async {
      final RequestOptions o = await requete('/candidat/profile');
      expect(o.headers['Authorization'], 'Bearer 15|jeton-secret');
    });

    test('URL absolue de l’API (pièce jointe) : jeton présent', () async {
      final RequestOptions o = await requete(
        'https://emploi.fonctionpublique.sn/api/v1/candidat/files/cv/42/a.pdf',
      );
      expect(o.headers['Authorization'], 'Bearer 15|jeton-secret');
    });

    test('hôte tiers : aucun jeton', () async {
      final RequestOptions o = await requete('https://attaquant.example/vol');
      expect(o.headers.containsKey('Authorization'), isFalse);
    });

    test('sous-domaine voisin ou faux préfixe : aucun jeton', () async {
      for (final String url in <String>[
        'https://cdn.emploi.fonctionpublique.sn/x',
        'https://emploi.fonctionpublique.sn.attaquant.example/x',
      ]) {
        final RequestOptions o = await requete(url);
        expect(o.headers.containsKey('Authorization'), isFalse, reason: url);
      }
    });

    test('même hôte en HTTP clair : aucun jeton', () async {
      final RequestOptions o = await requete(
        'http://emploi.fonctionpublique.sn/api/v1/candidat/profile',
      );
      expect(o.headers.containsKey('Authorization'), isFalse);
    });

    test('un en-tête posé à la main est retiré vers un tiers', () async {
      final RequestOptions o = await requete(
        'https://attaquant.example/vol',
        entetes: <String, dynamic>{'Authorization': 'Bearer fuite'},
      );
      expect(o.headers.containsKey('Authorization'), isFalse);
    });
  });

  test('SEC-008 — le journal de debug n’écrit pas les en-têtes', () async {
    final List<String> lignes = <String>[];
    final Dio dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = _Capture()
      ..interceptors.add(JournalReseau(ecrire: (o) => lignes.add('$o')));
    await dio.get<dynamic>(
      '/x',
      options: Options(headers: <String, dynamic>{'Authorization': 'Bearer z'}),
    );
    expect(lignes.join('\n'), isNot(contains('Bearer z')));
  });

  test('SEC-005 — les copies locales de pièces sont purgées', () async {
    final File copie = File(
      '${CopiesLocales.dossier.path}${Platform.pathSeparator}cv.pdf',
    );
    await copie.create(recursive: true);
    expect(copie.existsSync(), isTrue);

    await CopiesLocales.purger();

    expect(CopiesLocales.dossier.existsSync(), isFalse);
    // Sans dossier, la purge ne lève rien.
    await CopiesLocales.purger();
  });

  group('Configuration des plateformes', () {
    test('SEC-002 — aucune sauvegarde Android des données', () {
      final String manifeste = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      expect(manifeste, contains('android:allowBackup="false"'));
      expect(
        manifeste,
        contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
      );

      final String regles = File(
        'android/app/src/main/res/xml/data_extraction_rules.xml',
      ).readAsStringSync();
      for (final String section in <String>[
        'cloud-backup',
        'device-transfer',
      ]) {
        expect(regles, contains('<$section>'));
      }
      expect(RegExp('domain="sharedpref"').allMatches(regles), hasLength(2));
    });

    test('SEC-004 — aucune exception ATS dans l’Info.plist publié', () {
      final String plist = File('ios/Runner/Info.plist').readAsStringSync();
      expect(plist, isNot(contains('NSAllowsLocalNetworking')));
      expect(plist, isNot(contains('NSAllowsArbitraryLoads')));
    });

    test('SEC-003 — la release ne signe en debug que faute de clé', () {
      final String gradle = File(
        'android/app/build.gradle.kts',
      ).readAsStringSync();
      expect(gradle, contains('rootProject.file("key.properties")'));
      expect(gradle, contains('signingConfigs.getByName("release")'));
      final String ignores = File('.gitignore').readAsStringSync();
      expect(ignores, contains('key.properties'));
      expect(ignores, contains('*.jks'));
    });
  });
}
