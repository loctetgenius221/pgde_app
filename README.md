# PGDE — Demandes d'emploi (mobile)

Application Flutter (Android + iOS) du portail de demandes d'emploi du
Ministère de la Fonction publique : compte candidat, dossier en 4 étapes,
pièces jointes, assistant conversationnel.

## Prérequis

- Flutter 3.47+ (Dart 3.10+), Android Studio (SDK + émulateur)
- Pour iOS : un Mac avec Xcode

## Démarrer

```bash
flutter pub get
dart run build_runner build      # génère les modèles freezed / json
flutter run
```

| Mode | Commande | Backend |
| :--- | :--- | :--- |
| Production (défaut) | `flutter run` | `https://emploi.fonctionpublique.sn/api/v1` |
| Démonstration hors ligne | `flutter run --dart-define=USE_MOCKS=true` | faux backend en mémoire |
| Backend local | `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1` | Laravel sur le PC |

**Backend local** : lancer `php artisan serve --host=0.0.0.0 --port=8000`, puis
choisir l'adresse selon l'appareil : `10.0.2.2` (émulateur Android),
`localhost` (simulateur iOS), IP du PC (téléphone sur le même Wi-Fi).
Le HTTP en clair n'est autorisé qu'en **debug Android**. Sur le simulateur iOS,
ajouter `NSAllowsLocalNetworking` dans `Info.plist` **en local, sans le commiter**.

**Comptes de démonstration** (mode démo uniquement) :

| Identifiant | Mot de passe | Cas |
| :--- | :--- | :--- |
| `msagna` | `password` | compte actif |
| `anouveau` | `password` | compte non activé, code d'activation `123456` |

## Vérifier avant de commiter

```bash
flutter analyze        # doit afficher « No issues found! »
flutter test
```

## Publier sur Android

1. Avoir `android/key.properties` (clé d'upload, **jamais commité**) :
   ```properties
   storeFile=C:/Users/<vous>/cles-android/pgde-upload.jks
   storePassword=...
   keyAlias=upload
   keyPassword=...
   ```
   Sans ce fichier, la release est signée avec la clé de debug : le Play
   Store la refuse.
2. Construire et vérifier la signature :
   ```bash
   flutter build appbundle --release
   keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
   ```
3. Envoyer `app-release.aab` sur la Play Console (Play App Signing).

La clé `.jks` et son mot de passe se sauvegardent **hors du PC** (gestionnaire
de mots de passe + support hors ligne).

## Structure

```
lib/
├── main.dart, app.dart
├── core/          socle commun, ne dépend d'aucune feature
│   ├── config/    URL d'API et mode démo (--dart-define)
│   ├── network/   Dio, jeton Bearer, ApiException
│   ├── storage/   jeton chiffré (Keystore/Keychain), préférences
│   └── router/, theme/, ui/, session/, json/, dictee/
└── features/
    ├── auth/        inscription, connexion, activation, mot de passe
    ├── demande/     dossier candidat : wizard 4 étapes, pièces, résumé
    ├── reference/   référentiels (régions, emplois…), en cache
    ├── assistant/   chatbot Amath
    └── onboarding/, splash/
```

Chaque feature suit `ui → application → data → domain`. Chaque API a une
version HTTP et une version démo (`Http…Api` / `Mock…Api`), choisie par
`USE_MOCKS`.

## Règles du projet

- **Français partout** (code métier, libellés, commentaires), sauf les noms
  imposés par le serveur (`username`, `numberid`…).
- **`flutter analyze` à zéro** : règles strictes dans `analysis_options.yaml`.
- **Aucun secret dans git** : `key.properties`, `*.jks`, `.env` sont ignorés.
- **Le jeton** ne part que vers l'API, et un `401` renvoie à la connexion.
- **Les modèles générés** (`*.freezed.dart`, `*.g.dart`) se régénèrent avec
  `build_runner`, ils ne se modifient pas à la main.

## Icônes et écran de lancement

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

Configuration en fin de `pubspec.yaml`, logo dans `assets/logo_fp.png`.

## Documentation

| Document | Contenu |
| :--- | :--- |
| [docs/CONTRAT_INTERFACE_API_MOBILE_v2.md](docs/CONTRAT_INTERFACE_API_MOBILE_v2.md) | Contrat d'API en vigueur (v1 archivée à côté) |
| [CONTRAT_CHATBOT_MOBILE.md](CONTRAT_CHATBOT_MOBILE.md) | Contrat du chatbot |
| [MOBILE_FLUTTER.md](MOBILE_FLUTTER.md) | Cadrage métier, références `§x.y` du code |
| [AUDIT_2026-11-23.md](AUDIT_2026-11-23.md) | Audit sécurité et suivi des correctifs |
| [docs/DICTEE_VOCALE.md](docs/DICTEE_VOCALE.md) | Dictée vocale |
