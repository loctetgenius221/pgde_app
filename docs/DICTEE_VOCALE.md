# Dictée vocale — guide d'implémentation

Ce guide explique comment la dictée vocale est construite dans l'app PGDE,
comment l'activer sur un champ, la tester et la dépanner.

Elle permet au candidat de **dicter** le texte des champs longs au lieu de le
taper. Elle utilise la reconnaissance vocale déjà présente sur le téléphone,
via le paquet [`speech_to_text`](https://pub.dev/documentation/speech_to_text/latest/).

---

## 1. En bref

| | |
|---|---|
| **Paquet** | `speech_to_text` 7.4.x : `SpeechRecognizer` sur Android, framework Speech sur iOS |
| **Champs équipés** | « Missions principales » (étape 3), « Votre profil en quelques mots » (étape 4), saisie de Ndimbal |
| **Activer sur un champ** | `ChampTexte(..., dictee: true)` |
| **Code** | `lib/core/dictee/` (moteur) et `lib/core/ui/bouton_dictee.dart` (bouton) |
| **Tests** | `test/dictee/` : 53 tests, dont 3 vérifiés par mutation |
| **Permissions** | Android : `RECORD_AUDIO` plus `<queries>` `RecognitionService` ; iOS : 2 clés `Info.plist` |

Aucun modèle n'est embarqué dans l'app : sa taille ne change pas.

---

## 2. Ce que voit le candidat

1. Un **micro vert** apparaît au bout du champ.
2. **Premier appui**, la toute première fois : Android ou iOS demande l'accès
   au micro. La demande ne vient jamais au lancement de l'app.
3. **Pendant l'écoute**, le bouton devient une pastille verte avec un carré
   « stop ». Le texte s'écrit **au fil de la parole**, à la suite de ce qui
   était déjà saisi.
4. **Fin de la dictée**, au choix :
   - un second appui sur le bouton ;
   - 4 secondes de silence ;
   - 60 secondes d'écoute au maximum.
5. Le texte reste **modifiable au clavier**, et il est sauvegardé dans le
   brouillon comme une saisie normale.
6. En cas de problème, un message clair s'affiche en bas de l'écran (voir
   section 7).

### Règles d'insertion du texte (`fusionnerDictee`)

| Situation | Champ avant | Dicté | Champ après |
|---|---|---|---|
| Champ vide | `` | `je suis comptable` | `Je suis comptable` |
| Suite d'une phrase | `Je suis` | `comptable` | `Je suis comptable` |
| Après un point, `!` ou `?` | `Fin.` | `suite` | `Fin. Suite` |
| Après un retour à la ligne | `Ligne 1⏎` | `ligne 2` | `Ligne 1⏎Ligne 2` |
| Le champ finit déjà par un blanc | `Je suis ` | `là` | `Je suis là` (pas d'espace doublée) |
| Limite du champ | `abc` (max 10) | `defghijklm` | `abc defghi` (10 caractères) |

---

## 3. Architecture

Le découpage suit trois principes :
- **KISS** : trois fichiers, aucun état global.
- **SOLID** : un seul rôle par classe, et les écrans dépendent d'une
  interface, pas du paquet (inversion de dépendance).
- **Moins de code** : le bouton se branche sur n'importe quel champ par deux
  fonctions.

```
            écrans (étapes 3-4, Ndimbal)
                       │  ChampTexte(dictee: true)
                       ▼
lib/core/ui/bouton_dictee.dart ─── BoutonDictee
   • état repos / écoute
   • fusion du texte (fusionnerDictee)
   • messages d'erreur
                       │  ref.read(moteurDicteeProvider)
                       ▼
lib/core/dictee/dictee.dart ─── contrat, sans dépendance externe
   • MoteurDictee (interface)
   • ErreurDictee (enum + message)
   • fusionnerDictee (fonction pure)
                       ▲  implémente
lib/core/dictee/moteur_speech_to_text.dart
   • MoteurSpeechToText : seule classe qui connaît speech_to_text
   • moteurDicteeProvider (Riverpod)
```

| Fichier | Rôle | Dépend de |
|---|---|---|
| `dictee.dart` | Le contrat : ce qu'est un moteur de dictée, ses erreurs, la règle d'insertion | rien (Flutter `foundation` seulement) |
| `moteur_speech_to_text.dart` | Adapter le paquet au contrat | `speech_to_text`, Riverpod |
| `bouton_dictee.dart` | L'interface : micro, écoute, messages | le contrat, le provider |
| `champs.dart` (`ChampTexte`) | Paramètre `dictee` qui pose le bouton | `bouton_dictee.dart` |

**Pourquoi une interface ?** Pour changer de moteur sans toucher aux écrans :
ML Kit quand son API sera stable, `SpeechAnalyzer` d'iOS 26, ou une solution
embarquée. Il suffit d'écrire une nouvelle classe qui implémente
`MoteurDictee` et de la déclarer dans le provider.

### Cycle de vie d'une session (`MoteurSpeechToText`)

```
preparer() ──► initialize() une seule fois par vie de l'app
   │             ├─ ok    → choix de la langue française → null
   │             └─ échec → permissionRefusee | indisponible (préparation retentée au prochain appui)
   ▼
ecouter() ──► listen(mode dictée, partiels, pause 4 s, max 60 s, locale fr)
   │   ├─ résultats partiels ─► surTexte(texte, definitif: false)
   │   ├─ résultat final     ─► surTexte(texte, definitif: true)
   │   ├─ erreur plateforme  ─► surErreur(traduite) puis surFin
   │   └─ statut « done »    ─► (rien entendu ? surErreur(rienEntendu)) puis surFin
   ▼
arreter() ──► stop() : le dernier texte arrive comme définitif, puis « done »
```

Garanties testées :
- **`surFin` n'est appelé qu'une fois par session**, même si l'erreur et le
  statut `done` arrivent tous les deux.
- **Une session silencieuse affiche toujours un message.** Constaté sur
  tablette Android 14 : le plugin envoie « done » **avant** l'erreur « pas de
  parole ». Sans ce traitement, la dictée se terminait sans rien expliquer.
- **Rien n'est transmis après la fin de la session.**

### Choix de la langue

L'adaptateur prend, dans l'ordre :
1. `fr_SN` ;
2. sinon `fr_FR` ;
3. sinon n'importe quelle variante française (`fr_CA`…) ;
4. sinon la langue du système.

L'identifiant est renvoyé tel que la plateforme l'a donné (`fr-FR` ou `fr_FR`).

---

## 4. Installation, de zéro

### 4.1 Dépendances (`pubspec.yaml`)

```yaml
dependencies:
  speech_to_text: ^7.4.0

dev_dependencies:
  speech_to_text_platform_interface: ^2.4.0   # tests : fausse plateforme
  plugin_platform_interface: ^2.1.8           # tests : MockPlatformInterfaceMixin
```

> **Pourquoi la version 7.4 ?** La 7.5 exige Flutter 3.44 et Dart 3.12, alors
> que le projet est en Flutter 3.38 et Dart 3.10. La 7.4 est aussi celle où
> Android commence à respecter `pauseFor`. Après une montée de version de
> Flutter, `flutter pub upgrade` passera de lui-même à la 7.5.

### 4.2 Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>

<queries>
    <!-- Sans cette entrée (Android 11 et plus), speech_to_text croit le
         service de reconnaissance absent. -->
    <intent>
        <action android:name="android.speech.RecognitionService"/>
    </intent>
</queries>
```

La documentation du paquet cite aussi les permissions `BLUETOOTH*`. Elles ne
servent qu'aux micros Bluetooth, et je ne les ai pas ajoutées pour ne pas
demander plus que nécessaire.

### 4.3 iOS (`ios/Runner/Info.plist`)

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Le micro sert uniquement à dicter le texte de votre demande.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>La reconnaissance vocale transforme votre dictée en texte dans votre demande.</string>
```

Sans ces deux clés, iOS ferme l'app au premier appui sur le micro.

---

## 5. Utilisation dans le code

### Activer la dictée sur un champ du formulaire

```dart
ChampTexte(
  libelle: 'Missions principales',
  valeur: experience.description,
  lignes: 4,
  longueurMax: 500,   // facultatif : la dictée ne dépassera jamais la limite
  dictee: true,       // ← c'est tout
  onChange: (v) => onChange(experience.copyWith(description: v)),
)
```

À réserver aux **champs longs**. Sur un nom, un numéro ou une date, le
clavier reste plus fiable.

### Sur un `TextField` hors `ChampTexte` (exemple : Ndimbal)

```dart
TextField(
  controller: controleur,
  decoration: InputDecoration(
    suffixIcon: BoutonDictee(
      texteActuel: () => controleur.text,
      onTexte: (texte) => controleur.value = TextEditingValue(
        text: texte,
        selection: TextSelection.collapsed(offset: texte.length),
      ),
      longueurMax: 1000,
    ),
  ),
)
```

Le bouton ne connaît pas le champ. Il lit son contenu par `texteActuel`, et
le remplace par `onTexte`.

### Régler le comportement

Les réglages sont des constantes de `MoteurSpeechToText` :

| Constante | Valeur | Effet |
|---|---|---|
| `pauseMax` | 4 s | Silence au-delà duquel la phrase est jugée terminée. Android impose en plus sa propre pause, d'une à trois secondes, impossible à allonger. |
| `dureeMax` | 60 s | Durée maximale d'une session, alignée sur la limite de la reconnaissance par serveur d'iOS. |

Les options passées à `listen` :

| Option | Valeur | Effet |
|---|---|---|
| `listenMode` | `ListenMode.dictation` | Optimise pour des phrases (iOS uniquement) |
| `partialResults` | `true` | Le texte apparaît au fil de la parole |
| `cancelOnError` | `true` | Une erreur définitive ferme proprement la session |
| `autoPunctuation` | `true` | Ponctuation automatique (iOS uniquement) |
| `onDevice` | non fixé (`false`) | Voir la section 8 |

---

## 6. Tests

```bash
flutter test test/dictee
```

| Fichier | Tests | Ce qui est éprouvé |
|---|---|---|
| `fusionner_dictee_test.dart` | 15 | Règles d'insertion : espaces, majuscules (accents compris), retour à la ligne, troncature, dictée vide ; messages d'erreur non techniques et tous différents |
| `moteur_speech_to_text_test.dart` | 24 | L'adaptateur **avec le vrai plugin** branché sur une fausse plateforme qui envoie les mêmes JSON que le code natif : préparation, langue, options d'écoute, partiels et final, fin unique, ordre réel des événements Android, traduction de 14 codes d'erreur, échec de `listen` |
| `bouton_dictee_test.dart` | 14 | Le bouton dans un vrai `ChampTexte` : présence, texte au fil de la parole sans empilement, curseur, deux dictées enchaînées, saisie au clavier conservée, limite du champ, arrêt, micro coupé en quittant l'écran, refus du micro, dictée indisponible, erreur en cours, double appui ignoré |

**Le principe des doubles de test**
- **`_PlateformeSimulee`** (moteur) étend `SpeechToTextPlatform` avec
  `MockPlatformInterfaceMixin`. Elle envoie les mêmes JSON que le code natif,
  produits par les `toJson()` du paquet. Toute la chaîne est donc testée :
  plugin → adaptateur → contrat.
- **`_MoteurPilote`** (bouton) implémente `MoteurDictee`. Le test décide de
  chaque événement (`entendre`, `echouer`, `finir`), au moment voulu.
- **`SpeechToText.withMethodChannel()`** donne une instance neuve par test.
  `SpeechToText()` est un singleton : sans cela, l'état passerait d'un test à
  l'autre.

**Tests de mutation.** J'ai introduit volontairement trois défauts pour
vérifier que les tests les détectent :
- retirer l'arrêt du micro dans `dispose` ;
- supprimer la protection « une seule fin » ;
- faire s'empiler les résultats partiels.

Chacun a fait échouer au moins un test.

### Recette sur un vrai téléphone

À refaire à chaque changement de moteur ou de version du plugin :

- [ ] Le premier appui sur le micro demande l'accès au micro, et pas avant.
- [ ] Après l'accord, le bouton devient vert « stop » et l'indicateur de micro
  du système s'allume.
- [ ] La parole s'écrit au fil de l'eau, en français, à la suite du texte
  existant.
- [ ] Un second appui arrête la dictée et garde le texte.
- [ ] En silence, « Rien n'a été entendu… » s'affiche après environ 4 s.
- [ ] Mode avion avec le pack de langue hors ligne absent : message
  « réseau ».
- [ ] Micro refusé, puis nouvel appui : message « Autorisez l'accès au micro… ».
- [ ] Quitter l'écran pendant la dictée éteint l'indicateur de micro.
- [ ] La limite de 1000 caractères est respectée.

---

## 7. Erreurs et messages

| Codes plateforme (extraits) | `ErreurDictee` | Message affiché |
|---|---|---|
| `error_permission`, `error_insufficient_permissions` | `permissionRefusee` | Autorisez l'accès au micro dans les réglages pour dicter. |
| `error_no_match`, `error_speech_timeout`, session silencieuse | `rienEntendu` | Rien n'a été entendu. Rapprochez-vous du micro et réessayez. |
| `error_network*`, `error_server*` | `reseau` | Dictée impossible sans connexion. Vérifiez votre réseau. |
| `error_language_*`, initialisation échouée avec micro accordé | `indisponible` | La dictée vocale n'est pas disponible sur cet appareil. |
| tout le reste (`error_busy`, `error_audio_error`…) | `autre` | La dictée s'est interrompue. Réessayez. |

La traduction se fait dans `MoteurSpeechToText.traduireErreur`, par
recherche de mots-clés. Pour ajouter un cas : ajouter une ligne à la table
`attendus` du test, puis la règle correspondante.

---

## 8. Confidentialité

- **Le micro n'est ouvert que pendant une dictée**, à la demande du candidat.
  Il est refermé quand on quitte l'écran ; c'est testé.
- **`onDevice` n'est pas forcé.** Le système reconnaît sur l'appareil si le
  pack de langue est installé, sinon il passe par ses serveurs (Google ou
  Apple). Constaté sur la tablette de test : le pack hors ligne français
  n'était pas installé (`SodaSpeechRecognizer: Failed to get language pack`),
  et la reconnaissance est passée par le serveur.
- **Pour forcer le traitement sur l'appareil**, passer `onDevice: true` dans
  `SpeechListenOptions`. La dictée échouera alors sur les téléphones sans pack
  hors ligne, avec le message « indisponible ». Il faut faire valider ce choix
  par le référent juridique.
- **À mentionner dans la politique de confidentialité** de l'app.

---

## 9. Dépannage

| Symptôme | Cause probable | Solution |
|---|---|---|
| Le micro n'apparaît pas | `dictee: true` oublié | Ajouter le paramètre au `ChampTexte` |
| Toujours « indisponible » sur Android | Entrée `<queries>` `RecognitionService` absente, ou pas de service de reconnaissance (appareil sans Google) | Vérifier le manifeste ; installer « Speech Services by Google » |
| Ça marche en debug, pas en release | Permission `INTERNET` absente du manifeste **principal** | La déclarer dans `src/main/AndroidManifest.xml` |
| L'écoute s'arrête très vite | Pause imposée par Android, de 1 à 3 s, non réglable | Dicter phrase par phrase : chaque phrase s'ajoute à la suite |
| Crash au premier appui sur iOS | Clés `Info.plist` manquantes | Section 4.3 |
| Texte en anglais | Pas de locale française sur l'appareil | Installer le français dans « Voix » ou la dictée du système |

**Lire les logs Android** :

```powershell
adb logcat -c
# … faire une dictée …
adb logcat -d | Select-String 'Recogni|SpeechRecognizer|speech'
```

Une session saine donne, dans l'ordre :
1. `onMicrophoneOpened`
2. `onStartOfSpeech`
3. `onStopListening`
4. `Received the final result`

Une session silencieuse se termine par `NO_SPEECH_DETECTED`.

---

## 10. Évolutions possibles

- **Passer à `speech_to_text` 7.5** dès que le projet est en Flutter 3.44 ou
  plus. Aucun changement de code attendu : la 7.5 n'annonce aucun changement
  incompatible.
- **Changer de moteur** (ML Kit GenAI une fois stable, `SpeechAnalyzer` sur
  iOS 26) : écrire une nouvelle classe qui implémente `MoteurDictee` et la
  déclarer dans `moteurDicteeProvider`. Les écrans et les tests du bouton ne
  changent pas.
- **Commandes de ponctuation à la voix** (« virgule », « point ») : à ajouter
  dans `fusionnerDictee`, avec ses tests.
