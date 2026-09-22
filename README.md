# Demandes d'emploi — application mobile

Application Flutter du portail de demandes d'emploi du Ministère de la Fonction publique.
Le cadrage métier et le contrat d'API font l'objet d'un document séparé : [MOBILE_FLUTTER.md](MOBILE_FLUTTER.md).
Les références `§x.y` de ce README et des commentaires du code y renvoient.

---

## Démarrer

```bash
flutter pub get
dart run build_runner build        # modèles freezed / json_serializable
flutter run
```

Par défaut l'app tourne sur un **faux backend en mémoire** : le vrai n'expose
aucune API consommable aujourd'hui (§6.1, bloqueurs B1 et B2).

Comptes de démonstration :

| Nom d'utilisateur | Mot de passe | État |
| :--- | :--- | :--- |
| `msagna` | `password` | compte actif |
| `anouveau` | `password` | compte non vérifié — mène à l'écran d'activation |

Sur l'écran d'activation, « Renvoyer l'email » active directement le compte :
raccourci assumé, `MAIL_MAILER=log` en local n'envoie aucun mail (§3.4).

### Brancher sur le backend réel

```bash
flutter run \
  --dart-define=USE_MOCKS=false \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

| Contexte | `API_BASE_URL` |
| :--- | :--- |
| Émulateur Android | `http://10.0.2.2:8000/api/v1` |
| Simulateur iOS | `http://localhost:8000/api/v1` |
| Appareil physique (même Wi-Fi) | `http://<IP LAN>:8000/api/v1` |

Côté serveur : `php artisan serve --host=0.0.0.0 --port=8000`.
Le HTTP en clair est autorisé **en debug uniquement** — `android/app/src/debug/AndroidManifest.xml`
et `NSAllowsLocalNetworking` dans `ios/Runner/Info.plist`.

### Vérifications

```bash
flutter analyze      # doit rester à zéro
flutter test
dart run build_runner watch   # pendant le dev
```

---

## Architecture

Découpage **par fonctionnalité**, trois couches par fonctionnalité, dépendances
toujours orientées vers l'intérieur : `ui → application → data → domain`.

```
lib/
├── main.dart                 amorçage (prefs, locale fr, portrait)
├── app.dart                  MaterialApp.router
├── core/                     socle transverse, ne connaît aucune feature
│   ├── config/env.dart       --dart-define : URL d'API, mocks
│   ├── network/              Dio, intercepteur Bearer, ApiException
│   ├── session/              signal d'expiration de session (401)
│   ├── storage/              jeton chiffré + magasin clé/valeur JSON
│   ├── router/               go_router + redirections selon la session
│   ├── theme/                thème unique Material 3
│   ├── json/                 convertisseurs partagés (date YYYY-MM-DD)
│   └── ui/                   AsyncView, FormSubmission, BandeauErreur
└── features/
    ├── auth/                 inscription, connexion, vérification d'email
    ├── reference/            nomenclatures, cache d'abord
    └── demande/              le dossier candidat (wizard 4 étapes)
```

### Ce qu'on ne fait pas, et pourquoi

Trois couches « canoniques » de la Clean Architecture ont été écartées. Ce sont
des décisions, pas des oublis.

**Pas de couche `usecase`.** Le dépôt *est* la frontière métier. Une classe par
appel de dépôt, ce serait une quarantaine de fichiers qui délèguent sans rien
décider.

**Pas de `Either` / `Result`.** Les échecs remontent en `ApiException` et sont
portés par `AsyncValue`, qui est déjà un type somme et déjà intégré au
framework. Un second mécanisme de résultat ferait doublon.

**Pas de `AuthRepository`.** Il n'aurait fait que déléguer à `AuthApi`.
`AuthController` combine directement deux collaborateurs — l'API et le magasin
de jetons — et reste testable par surcharge de providers.

`ReferenceRepository`, lui, **existe** : il porte une vraie logique de cache.
C'est le critère retenu partout — une couche se justifie par un comportement,
jamais par la symétrie du schéma.

---

## Décisions d'architecture

### ADR-001 — Les API sont des interfaces, avec une implémentation factice

*Contexte.* Le backend n'a ni `routes/api.php` chargé, ni Sanctum (§6.1). Rien
n'est appelable, et rien ne dit quand ça le sera.

*Décision.* Chaque contrat serveur est une `abstract interface class`, avec deux
implémentations : `Http…Api` et `Mock…Api`. Un provider choisit selon
`Env.useMocks`.

*Conséquences.* Le mobile avance sans attendre le backend et reste démontrable
en permanence. Les mocks reproduisent les **comportements** du serveur — règles
d'unicité, messages d'erreur français, format 422 par champ, compte créé
désactivé — pas seulement ses données : un écran écrit contre le mock
fonctionnera face à la vraie API. Le basculement est une variable de build,
sans modification de code.

### ADR-002 — Pas de base embarquée : `shared_preferences` en blobs JSON

*Contexte.* Le cadrage suggérait Hive ou Drift pour le référentiel (~700 lignes)
et le brouillon du wizard.

*Décision.* Un magasin clé/valeur qui stocke du JSON sérialisé.

*Conséquences.* Le référentiel est de toute façon chargé intégralement en
mémoire : les cascades sont des `where` sur des listes. Une base embarquée
n'apporterait ici que des adaptateurs générés et une initialisation
asynchrone. À revoir le jour où il faudra requêter ou paginer localement —
ce sera alors Drift, et le point de changement est confiné à `KeyValueStore`.

### ADR-003 — `Demande` est un agrégat unique et immuable

*Contexte.* `userdata.utilisateur_id` porte une contrainte UNIQUE (§2.1) : un
candidat a **un** dossier. Et surtout, un `PUT` partiel **efface** côté serveur
les formations et expériences absentes de la requête (§6.2 D1).

*Décision.* Un seul modèle `Demande` immuable détient l'intégralité du dossier
et est renvoyé entier à chaque enregistrement. Pas d'état de formulaire
éparpillé par écran.

*Conséquences.* C'est la protection de l'app contre la destruction silencieuse
de données. Elle tient même si le correctif D1 n'arrive jamais côté backend.
Corollaire : l'app ne propose jamais « nouvelle demande » — le parcours est
*créer si absent, sinon éditer*.

### ADR-004 — `ApiException` s'arrête à `ApiClient`

*Contexte.* Le cadrage proposait `validateStatus: code < 500`, ce qui oblige
chaque appel à tester le code de statut lui-même.

*Décision.* `ApiClient` laisse Dio lever, attrape `DioException` en un point
unique et la traduit en `ApiException` porteuse d'un message français, du code
de statut et des erreurs par champ.

*Conséquences.* Dépôts, contrôleurs et écrans ignorent totalement Dio. La
traduction des erreurs vit à un seul endroit. Remplacer Dio ne toucherait qu'un
fichier.

### ADR-005 — `core` ne connaît aucune feature

*Contexte.* Sur un 401, la couche réseau doit provoquer une déconnexion — ce
qui est une affaire d'authentification.

*Décision.* La couche réseau publie un signal (`SessionExpiry`), le module
d'authentification s'y abonne.

*Conséquences.* La dépendance pointe de `features/auth` vers `core`, jamais
l'inverse. Le socle reste réutilisable et testable seul.

---

---

## Design

### Palette — issue du logo, pas des maquettes

Les captures de `inspirations/` ont servi de référence pour le **langage de
mise en page** : beaucoup de blanc, formes très arrondies, boutons pilule,
grands titres serrés, cartes cernées plutôt qu'ombrées. Leur indigo, lui, n'a
pas été repris : les couleurs sont relevées au pixel dans `assets/logo_fp.png`.

| Rôle | Couleur | Usage |
| :--- | :--- | :--- |
| Action | **#009454** vert | Boutons, liens, états actifs, focus |
| Accent | **#FFCC34** jaune | Badges, étape en cours — **jamais une action** |
| Alerte | **#F43438** rouge | Erreurs **uniquement** |
| Texte | **#272825** anthracite | Titres et corps de texte |

Le rouge ne sert à rien d'autre qu'aux erreurs. Sur un formulaire de trente
champs, un rouge décoratif détruirait la seule couleur d'alerte disponible.

Typographie : **Poppins** (4 graisses, 628 Ko), embarquée dans l'APK. Pas de
`google_fonts` : l'app doit fonctionner hors ligne dès le premier lancement.

### Responsive

`lib/core/ui/responsive.dart` porte trois seuils de largeur — téléphone
(< 600), tablette (600–900), large (≥ 900) — et `ConteneurPage`, qui centre le
contenu et plafonne sa largeur (520 px pour un formulaire, 760 px pour une
liste). Sans ce plafond, un champ de saisie s'étire sur 1200 px de tablette et
la page paraît vide. Un test le verrouille :
« sur tablette, le formulaire reste dans une largeur lisible ».

### Illustrations

Dessinées en Flutter (`lib/core/ui/illustrations.dart`), pas importées. Elles
reprennent l'ADN du logo — un arc ouvert, des silhouettes en croissant
surmontées d'une tête ronde — obtenues par soustraction de deux disques plutôt
qu'à coups de courbes. Conséquences : 0 Ko d'assets, net à toute résolution,
et impossible de dériver du logo par accident.

### Séquence d'ouverture

```
splash natif  →  splash animé  →  onboarding (1er lancement)  →  connexion
(pas de flash    logo + titre     3 écrans                       ou dossier
 blanc)          + liseré         « Passer » toujours offert
                 tricolore
```

Le routeur ne quitte le splash qu'à **deux** conditions réunies : session
restaurée *et* animation terminée. Sans la seconde, une session restaurée en
40 ms ferait clignoter l'écran suivant.

Les trois écrans d'onboarding ne sont pas décoratifs. Chacun désamorce une
cause d'abandon identifiée dans le cadrage :

1. **« Une demande, un dossier »** — `utilisateur_id` est UNIQUE (§2.1). Sans
   cette explication, le candidat cherche un bouton « nouvelle demande » qui
   n'existera jamais.
2. **« Préparez vos pièces »** — formats et poids sont **refusés par le
   serveur** (§4, étape 2). C'est le premier mur rencontré ; l'annoncer avant
   évite un 422 incompréhensible au milieu du formulaire.
3. **« Quatre étapes, à votre rythme »** — trente champs sur un réseau
   instable (§8.8). Annoncer la sauvegarde locale avant de commencer.

### Identité de l'application

```bash
dart run flutter_launcher_icons        # icônes Android + iOS
dart run flutter_native_splash:create  # écran natif de lancement
```

Les deux sont configurés en fin de `pubspec.yaml`. Le logo fourni était un PNG
encapsulé dans un wrapper SVG : il a été extrait en `assets/logo_fp.png`, puis
recadré avec marges pour l'icône adaptative Android (zone sûre de 66 %).

## Conventions

- **Français partout** : noms de domaine (`Demande`, `EtapeWizard`,
  `Referentiel`), libellés, commentaires. Seul le vocabulaire imposé par le
  serveur reste tel quel (`username`, `numberid`, `emploi1_id`).
- **`flutter analyze` à zéro.** Les règles sont volontairement strictes
  (`strict-casts`, `avoid_dynamic_calls`, `prefer_final_locals`…) :
  voir `analysis_options.yaml`.
- **Les ids magiques n'existent pas en dur.** `Academic.sansDiplomeId` (14, pas
  20 — §6.1 B4), `Region.horsSenegalId` (15).
- **Les valeurs contraintes sont des énumérations.** `Genre`,
  `SituationMatrimoniale` : la base accepte n'importe quelle chaîne, mais une
  valeur hors liste rend le candidat invisible aux filtres de l'administration.
  L'énumération porte la valeur exacte attendue (`Feminin`, sans accent).
- **Les tests portent sur les pièges, pas sur la couverture.** Ce qui est testé
  aujourd'hui : complétude des étapes, expériences effectivement conservées,
  ordre imposé des niveaux d'études, routage des erreurs 422, aller-retour JSON
  du cache, démarrage de l'app.

---

## Suite des travaux

Livré : socle, authentification, référentiel en cache, design, onboarding, et
**le wizard en quatre étapes** — saisie complète, brouillon local, cascades,
enregistrement et routage des erreurs serveur.

Reste à faire, par ordre de dépendance :

1. **Pièces jointes** — diplômes, CV et photo de profil. `multipart` en
   notation à crochets (§8.6), compression avant envoi (plafond serveur :
   2 Mo par fichier), et suppression via `deleted_files`.
2. **Résumé du dossier** en lecture seule, équivalent de `userdata.summary`.
3. **Changement de mot de passe** et mot de passe oublié (§7.2).
4. **Branchement sur l'API réelle** : `--dart-define=USE_MOCKS=false`, une fois
   les bloqueurs §6.1 levés côté backend.

### Le wizard

```
lib/features/demande/
├── domain/      Demande (agrégat immuable), Formation, Experience, EtapeWizard
├── data/        DemandeApi (+ mock), DemandeMapper, BrouillonStore
├── application/ DemandeController
└── ui/          WizardPage + etapes/{identite,formations,experiences,voeux}
```

Quatre partis pris structurent l'ensemble :

**Un seul point de mutation.** `DemandeController.modifier((d) => d.copyWith(…))`
est la seule écriture possible. Trente champs auraient donné trente méthodes ;
une transformation sur un agrégat immuable en donne une — et rien ne peut
contourner la sauvegarde du brouillon qu'elle déclenche.

**Les écrans d'étape ne détiennent aucun état.** Ils reçoivent le dossier, le
référentiel, les erreurs serveur et la fonction de modification. Ce sont des
fonctions pures de l'état : testables, et impossibles à désynchroniser.

**Quatre composants de saisie couvrent les trente champs.** `ChampTexte`,
`ChampSelection`, `ChampDate` et `ChoixSegmente` dans `core/ui/champs.dart`,
plus `ListeDynamique` pour les formations et expériences — qui ont exactement
le même comportement. Les écrans ne décrivent plus que *quoi* saisir.

**La navigation entre étapes est libre.** Le dossier est un brouillon tant
qu'il n'est pas envoyé ; bloquer l'avance sur un champ manquant ne ferait que
coincer un candidat qui veut y revenir. Le contrôle a lieu à l'enregistrement,
et renvoie sur l'étape fautive — c'est à cela que sert `EtapeWizard.pourChamp`
(§8.7), aussi bien pour les champs obligatoires que pour un 422 du serveur.

### À trancher

- **`applicationId`.** Toujours `com.example.pgde_app`. Une publication sur les
  stores exige un identifiant définitif — il fige aussi l'arborescence Kotlin,
  donc autant le choisir tôt.
- **Plateformes.** Le projet ne cible qu'Android et iOS ; les dossiers `web/`,
  `windows/`, `linux/` et `macos/` ont été retirés. Pour en réactiver un :
  `flutter create --platforms=web .`

### À relayer au backend

Les bloqueurs du §6.1 restent entiers. Les trois qui empêchent toute mise en
production, quelle que soit la qualité du mobile :

- **B1 + B2** — charger `routes/api.php`, installer Sanctum. Sans quoi aucune
  API n'existe.
- **B3** — `autresdiplomes` est un `varchar(255)`, une seule formation en
  occupe déjà 183. **Les formations multiples sont impossibles aujourd'hui**,
  sur mobile comme sur le web.
- **D6** — les pièces d'identité et diplômes sont écrits dans `public/uploads/`,
  accessibles sans authentification. À traiter comme un risque de
  confidentialité, pas comme une dette technique.
