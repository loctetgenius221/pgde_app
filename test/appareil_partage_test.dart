import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pgde_app/core/storage/key_value_store.dart';
import 'package:pgde_app/features/auth/application/auth_controller.dart';
import 'package:pgde_app/features/auth/domain/utilisateur.dart';
import 'package:pgde_app/features/demande/application/demande_controller.dart';
import 'package:pgde_app/features/demande/data/brouillon_store.dart';
import 'package:pgde_app/features/demande/data/selecteur_fichiers.dart';
import 'package:pgde_app/features/demande/domain/demande.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Un même téléphone, deux candidats : A remplit son dossier, puis B se
/// connecte. B ne doit rien retrouver de A — ni à l'écran, ni dans ce qu'il
/// enverrait au serveur.

Utilisateur _candidat(int id, String prenom) => Utilisateur(
  id: id,
  firstname: prenom,
  lastname: 'Test',
  username: prenom.toLowerCase(),
  numberid: '$id',
  email: '${prenom.toLowerCase()}@exemple.sn',
  enabled: true,
);

final Utilisateur _a = _candidat(1, 'Awa');
final Utilisateur _b = _candidat(2, 'Bassirou');

/// Compte connecté, piloté par le test.
class _Compte extends Notifier<Utilisateur?> {
  @override
  Utilisateur? build() => null;

  void connecter(Utilisateur? u) => state = u;
}

final _compteProvider = NotifierProvider<_Compte, Utilisateur?>(_Compte.new);

Future<(ProviderContainer, SharedPreferences)> _telephone([
  Map<String, Object> contenu = const <String, Object>{},
]) async {
  SharedPreferences.setMockInitialValues(contenu);
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final ProviderContainer conteneur = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      utilisateurConnecteProvider.overrideWith(
        (ref) => ref.watch(_compteProvider),
      ),
    ],
  );
  addTearDown(conteneur.dispose);
  return (conteneur, prefs);
}

void main() {
  test('B ne retrouve pas le brouillon de A', () async {
    final (ProviderContainer tel, _) = await _telephone();

    tel.read(_compteProvider.notifier).connecter(_a);
    await tel
        .read(brouillonStoreProvider)
        .ecrire(const Demande(lieuNaissance: 'Thiès'));

    tel.read(_compteProvider.notifier).connecter(null);
    tel.read(_compteProvider.notifier).connecter(_b);
    expect(tel.read(brouillonStoreProvider).lire(), isNull);

    // A, lui, retrouve son brouillon : rien n'est perdu pour son auteur.
    tel.read(_compteProvider.notifier).connecter(_a);
    expect(tel.read(brouillonStoreProvider).lire()?.lieuNaissance, 'Thiès');
  });

  test(
    'le dossier en mémoire repart de zéro au changement de compte',
    () async {
      final (ProviderContainer tel, _) = await _telephone();
      tel.read(_compteProvider.notifier).connecter(_a);
      // Garde le contrôleur vivant, comme le ferait l'écran ouvert.
      final abonnement = tel.listen(demandeControllerProvider, (_, _) {});
      addTearDown(abonnement.close);

      await tel.read(demandeControllerProvider.future);
      tel
          .read(demandeControllerProvider.notifier)
          .modifier((d) => d.copyWith(lieuNaissance: 'Thiès'));

      // B se connecte sans même que l'app soit relancée.
      tel.read(_compteProvider.notifier).connecter(_b);
      final Demande vue = await tel.read(demandeControllerProvider.future);
      expect(vue.lieuNaissance, isEmpty);

      // La sauvegarde différée de A ne doit pas atterrir chez B.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(tel.read(brouillonStoreProvider).lire(), isNull);
    },
  );

  test(
    'les pièces choisies par A ne partent pas avec le dossier de B',
    () async {
      final (ProviderContainer tel, _) = await _telephone();
      tel.read(_compteProvider.notifier).connecter(_a);
      final abonnement = tel.listen(piecesEnAttenteProvider, (_, _) {});
      addTearDown(abonnement.close);

      tel
          .read(piecesEnAttenteProvider.notifier)
          .choisirPhoto(File('photo_identite_awa.jpg'));
      expect(tel.read(piecesEnAttenteProvider).estVide, isFalse);

      tel.read(_compteProvider.notifier).connecter(_b);
      expect(tel.read(piecesEnAttenteProvider).estVide, isTrue);
    },
  );

  test('la déconnexion volontaire efface brouillon et pièces de A', () async {
    final (ProviderContainer tel, _) = await _telephone();
    tel.read(_compteProvider.notifier).connecter(_a);
    final abonnement = tel.listen(demandeControllerProvider, (_, _) {});
    addTearDown(abonnement.close);
    await tel.read(demandeControllerProvider.future);

    final Directory dossier = await Directory.systemTemp.createTemp('pgde');
    addTearDown(() => dossier.delete(recursive: true));
    final File photo = await File(
      '${dossier.path}/photo.jpg',
    ).writeAsString('x');

    await tel
        .read(brouillonStoreProvider)
        .ecrire(const Demande(lieuNaissance: 'Thiès'));
    tel.read(piecesEnAttenteProvider.notifier).choisirPhoto(photo);

    await tel
        .read(demandeControllerProvider.notifier)
        .effacerLesDonneesLocales();

    expect(tel.read(brouillonStoreProvider).lire(), isNull);
    expect(tel.read(piecesEnAttenteProvider).estVide, isTrue);
    expect(
      photo.existsSync(),
      isFalse,
      reason: 'la copie sur l’appareil aussi',
    );
  });

  test(
    'l’ancien brouillon commun à l’appareil est effacé sans être lu',
    () async {
      final (ProviderContainer tel, SharedPreferences prefs) = await _telephone(
        <String, Object>{
          BrouillonStore.cleAncienne: '{"lieuNaissance":"Thiès"}',
        },
      );
      tel.read(_compteProvider.notifier).connecter(_b);

      expect(tel.read(brouillonStoreProvider).lire(), isNull);
      await Future<void>.delayed(Duration.zero);
      expect(prefs.containsKey(BrouillonStore.cleAncienne), isFalse);
    },
  );

  test('sans compte connecté, rien n’est lu ni écrit', () async {
    final (ProviderContainer tel, SharedPreferences prefs) = await _telephone();
    await tel
        .read(brouillonStoreProvider)
        .ecrire(const Demande(lieuNaissance: 'Thiès'));
    expect(prefs.getKeys().where((k) => k.startsWith('brouillon')), isEmpty);
  });
}
