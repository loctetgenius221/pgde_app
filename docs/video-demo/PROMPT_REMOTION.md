# Prompt — Vidéo de présentation et de démonstration de l'app PGDE (Remotion)

> À coller dans Claude Code, ouvert à la racine d'un projet Remotion.
> Les ressources citées se trouvent dans le dépôt de l'app Flutter :
> `pgde_app/assets/` et `pgde_app/docs/video-demo/`.

---

## Ta mission

Réalise avec Remotion une **vidéo de présentation et de démonstration** de
l'application mobile **PGDE**, l'app de demande d'emploi de la fonction
publique sénégalaise. Le résultat doit avoir la qualité d'une vidéo
institutionnelle : sobre, lisible, fidèle à l'app réelle et à sa charte.

Livre **deux compositions** à partir des mêmes scènes :

| Composition | Format | Durée | Usage |
|---|---|---|---|
| `PgdeDemo` | 1920 × 1080, 16:9, 30 i/s | 75 à 90 s | site du ministère, YouTube, présentations |
| `PgdeDemoVertical` | 1080 × 1920, 9:16, 30 i/s | 45 à 60 s | réseaux sociaux (version courte) |

Avant d'écrire du code, **propose-moi le découpage scène par scène** (durées,
texte à l'écran, capture utilisée, animation). Attends ma validation, puis
réalise.

Si les skills Remotion officielles pour Claude Code sont disponibles
(`remotion-dev/skills`), installe-les et appuie-toi dessus.

---

## 1. L'application

- **Nom** : PGDE, Plateforme de Gestion des Demandes d'Emploi dans la fonction
  publique.
- **Éditeur** : Ministère de la Fonction publique, du Travail et de la Réforme
  du service public (Sénégal).
- **Public** : tout citoyen qui veut postuler à un emploi de la fonction
  publique. C'est un public très large, et pas forcément à l'aise avec le
  numérique.
- **Promesse** : *une seule demande, un seul dossier, rempli à votre rythme
  depuis votre téléphone, le même que sur le site web.*

### Fonctionnalités à montrer (dans cet ordre)

1. **Ouverture** : le logo se pose, puis le sigle « PGDE » arrive par la droite
   et s'aligne avec lui. C'est la signature de l'app, à reproduire dans la
   vidéo.
2. **Présentation en 3 pages**, avec les textes exacts :
   - « Une demande, un dossier » : *Vous ne remplissez qu'une seule demande.
     Elle reste modifiable à tout moment.*
   - « Préparez vos pièces » : *Pièce d'identité, photo et diplômes.*
   - « Quatre étapes, à votre rythme » : *Identité, formations, expériences,
     vœux. Votre saisie est conservée, même hors connexion.*
3. **Inscription et connexion** : création du compte, activation par e-mail,
   connexion avec l'e-mail ou le nom d'utilisateur.
4. **Accueil** : état du dossier (« Demande en préparation », puis « Dossier
   enregistré »), barre de progression, frise verticale des 4 étapes avec
   pastilles « À remplir » et « Complétée ».
5. **Formulaire en 4 étapes**, avec la frise d'étapes en haut :
   - **Identité** : choix segmentés (Homme/Femme, situation matrimoniale),
     choix « Au Sénégal / À l'étranger », compteur du nombre d'enfants.
   - **Formation** : cartes « Diplôme 1 », justificatif à joindre (zone en
     pointillés), « Ajouter un autre diplôme ».
   - **Expérience** : « Oui, j'ai de l'expérience / Non, pas encore ».
   - **Emploi** : deux vœux (« 1er choix », « 2e choix ») par secteur et
     emploi, présentation du profil.
   - Message à faire passer : **le brouillon est enregistré automatiquement**
     (« brouillon enregistré » s'affiche sous le formulaire).
6. **Récapitulatif « Mon dossier »** : n° de dossier mis en avant, avec un
   bouton « Copier », et toutes les rubriques. Il s'ouvre après
   l'enregistrement.
7. **Ndimbal, l'assistant IA** : un petit robot animé en bas à droite de
   l'accueil. Son nom veut dire « aide » en wolof. Questions suggérées :
   « Quelles pièces dois-je fournir ? », « Comment remplir mes formations ? »,
   « Où en est mon dossier ? », « Je n'ai pas de diplôme, que faire ? ». Il
   répond aux questions, mais ne traite aucun dossier lui-même.
8. **Confiance** : à la déconnexion, les données sont effacées de l'appareil.
   Un téléphone peut donc se prêter sans risque.

La vidéo montre **uniquement l'app sur smartphone**. Pas de tablette, pas de
format paysage : c'est le support de la grande majorité des candidats.

### Ce qu'il ne faut PAS affirmer

- Ne cite aucune boutique (Play Store, App Store) ni aucune date de sortie.
  Mets un emplacement `[DISPONIBILITÉ À CONFIRMER]` dans l'appel à l'action
  final.
- N'invente ni chiffres (nombre de candidats, postes ouverts…) ni
  fonctionnalités absentes de cette liste (pas de suivi en temps réel, pas de
  notification push).
- Ne dis pas que l'IA décide ou instruit les dossiers.

---

## 2. Charte graphique (à respecter strictement)

| Rôle | Couleur | Usage |
|---|---|---|
| Vert du logo | `#009454` | couleur principale : actions, titres forts, accents |
| Vert pâle | `#D9F2E5` | fonds de pastilles et d'icônes |
| Jaune du logo | `#FFCC34` | **un seul accent**, rare : l'élément mis en avant |
| Rouge du logo | `#F43438` | **à ne pas utiliser** en décoration (réservé aux erreurs dans l'app) |
| Anthracite | `#272825` | texte principal |
| Gris texte | `#6B716E` | texte secondaire |
| Fond | `#FFFFFF` | fond principal ; `#F1F3F4` pour les zones grises |

- **Police** : Poppins, et uniquement Poppins (Regular 400, Medium 500,
  SemiBold 600, Bold 700). Les fichiers TTF sont dans `pgde_app/assets/fonts/`.
- **Formes** : rayons de 12 px pour les boutons et les champs, 16 px pour les
  cartes. Les pastilles sont en forme de pilule.
- **Logo** : `pgde_app/assets/logo_fp.svg`, ou `logo_fp.png`. Ne le déforme
  pas, ne le recolore pas, laisse-lui de l'air.
- **Ton** : institutionnel et chaleureux. On vouvoie le candidat. Phrases
  courtes et concrètes, pas de jargon technique.

---

## 3. Ressources fournies

Copie-les dans `public/` (Remotion les sert via `staticFile()`) :

```
pgde_app/assets/logo_fp.svg                → public/brand/logo_fp.svg
pgde_app/assets/icone-demande-d-emploi.png → public/brand/icone.png
pgde_app/assets/fonts/Poppins-*.ttf        → public/fonts/
pgde_app/docs/video-demo/captures/*.png    → public/captures/
pgde_app/docs/video-demo/enregistrements/*.mp4 → public/enregistrements/
```

Captures fournies : **smartphone en portrait, 1080 × 2340 px** (ratio 9:19,5,
environ 393 dp de large, comme un Android courant). Elles sont dans l'ordre du
parcours :

| Fichier | Contenu |
|---|---|
| `01-splash.png` | ouverture : logo + « PGDE » assemblés, barre de chargement |
| `02-onboarding-1.png` | « Une demande, un dossier » |
| `02b-onboarding-2.png` | « Préparez vos pièces » |
| `02c-onboarding-3.png` | « Quatre étapes, à votre rythme » |
| `03-connexion.png` | « Votre espace candidat », connexion |
| `03b-inscription.png` | « Créer un compte » |
| `04-accueil.png` | accueil : « Dossier enregistré », 4 étapes complétées, Ndimbal en bas à droite |
| `05-etape1-identite.png` | étape 1 : carte d'identité du candidat, choix Homme/Femme, date de naissance |
| `05b-etape1-etat-civil.png` | étape 1 : situation matrimoniale en grille, compteur d'enfants |
| `05c-etape1-residence.png` | étape 1 : « Au Sénégal / À l'étranger », pastille « facultatif » |
| `06-etape2-formation.png` | étape 2 : carte « Diplôme 1 » |
| `06b-etape2-justificatif.png` | étape 2 : zone pointillée « Joindre le diplôme », « Ajouter un autre diplôme » |
| `07-etape3-experience.png` | étape 3 : « Oui, j'ai de l'expérience / Non, pas encore », carte « Expérience 1 » |
| `08-etape4-voeux.png` | étape 4 : « 1er choix », secteur et emploi |
| `08b-etape4-profil.png` | étape 4 : « Votre profil en quelques mots », bouton « Enregistrer » |
| `09-mon-dossier.png` | « Mon dossier » : en-tête, **N° de dossier** et bouton « Copier » |
| `09b-mon-dossier-rubriques.png` | informations personnelles, emplois visés |
| `09c-mon-dossier-parcours.png` | formations et expériences |
| `10-ndimbal-accueil.png` | Ndimbal : « Comment puis-je vous aider ? », questions suggérées |
| `10b-ndimbal-reflexion.png` | question envoyée, Ndimbal « Réfléchit… » |

Captures et vidéos à venir : `10c-ndimbal-reponse` (une réponse de Ndimbal ;
le service était indisponible lors de la capture), puis des vidéos d'écran
dans `enregistrements/` (parcours du formulaire, conversation avec Ndimbal).

**Nettoyage des captures, à faire dans la vidéo :**
- **Barre d'état et barre de navigation** : rogne la barre d'état (les 66 px
  du haut : heure, icônes) et la barre de gestes (les 50 px du bas). Dessine à
  la place une barre d'état neutre et propre dans le cadre du téléphone, avec
  l'heure fixée à 9:41.
- **Bouton flottant parasite** : un petit cercle blanc avec un crayon apparaît
  sur le bord droit de chaque capture (environ x 1030–1080, y 545–625). C'est
  un bouton du système de la tablette, pas un élément de l'app. Masque-le avec
  un aplat de la couleur du fond, sans toucher au reste de l'écran.

- **Les captures actuelles viennent d'un compte de test** et montrent des
  données réelles (nom, e-mail). Avant le rendu final, je les remplacerai par
  celles d'un compte de démonstration. Construis la vidéo pour que ce
  remplacement se limite à changer les fichiers.
- **Si une ressource manque**, mets un panneau provisoire clairement marqué
  (« CAPTURE À VENIR : 05-etape2-formation ») plutôt que de reconstituer
  l'écran à la main.
- **Préfère les vidéos d'écran aux images fixes** quand elles existent : elles
  montrent la vraie fluidité de l'app.

---

## 4. Bonnes pratiques de réalisation (à appliquer)

### Narration
- **Accroche dans les 3 premières secondes** : la promesse, pas le logo seul.
  Exemple : « Postuler à la fonction publique, depuis votre téléphone. »
- **Structure** : problème → solution → démonstration des moments clés →
  confiance → appel à l'action. Une idée par scène.
- **Montre au lieu de dire** : chaque affirmation à l'écran est illustrée par
  l'écran réel de l'app qui la prouve.
- **Rythme** : 3 à 6 s par plan ; un temps fort toutes les 5 à 8 s (zoom,
  apparition, changement d'écran). Pas de plan statique de plus de 6 s.

### Lisibilité
- **Pensée pour être regardée sans le son** (lecture automatique muette) :
  tout message essentiel est écrit à l'écran.
- **Titres courts** : 7 mots au plus, 2 lignes au plus. Taille minimale de
  48 px en 1080p et de 56 px en vertical. Contraste conforme WCAG AA.
- **Zones de sécurité** : 5 % de marge sur les bords en 16:9. En 9:16, rien
  d'important dans les 15 % du haut ni dans les 20 % du bas, que couvrent les
  interfaces des réseaux sociaux.
- **Sous-titres** : si une voix off est ajoutée, sous-titres incrustés,
  synchronisés, en Poppins SemiBold, sur fond semi-opaque.

### Mise en scène des écrans
- Présente l'app **dans un cadre de smartphone dessiné en CSS/SVG** (ratio
  9:19,5, bords arrondis, ombre douce), jamais dans la reproduction d'un
  appareil de marque.
- **En 16:9**, le téléphone occupe environ 80 % de la hauteur, sur un côté de
  l'image. L'autre côté porte le titre de la scène. Pour comparer deux écrans
  (avant/après, deux étapes), place deux téléphones côte à côte.
- **En 9:16**, le téléphone occupe la largeur, légèrement réduit, et le titre
  se place au-dessus, dans la zone de sécurité.
- **Guide le regard** :
  - zoom lent (effet Ken Burns, 1,0 → 1,08) ;
  - zoom ciblé sur la zone à commenter, avec un halo vert `#009454` à 25 %
    d'opacité ;
  - point de toucher animé (cercle qui s'étend) sur les boutons
    « actionnés ».
- **Transitions** : courtes (8 à 15 images), cohérentes, en fondu ou
  glissement. Pas d'effets gratuits (rotation 3D, flou excessif, paillettes).
- **Animations** : courbes `spring()` amorties (`damping` élevé, sans rebond
  exagéré). Les entrées se font de bas en haut, avec un léger décalage entre
  les éléments.
- **Reprends les motifs de l'app** :
  - la frise des 4 étapes (tuiles carrées arrondies vertes reliées par un
    trait, plein pour les étapes passées, pointillé pour les suivantes) pour
    rythmer la partie « formulaire » ;
  - l'assemblage logo + « PGDE » de l'ouverture pour l'intro et l'outro.

### Son
- Musique libre de droits, institutionnelle et légère, à environ −18 LUFS.
  Baisse automatique de la musique sous la voix off (ducking).
- Une voix off est optionnelle. Prépare-en le texte, en français, à environ
  140 mots par minute, mais la vidéo doit fonctionner sans.

### Accessibilité et inclusion
- Pas de clignotement rapide (plus de 3 flashs par seconde).
- Prévois une version sous-titrée et un texte alternatif résumant la vidéo
  pour la page web.

---

## 5. Bonnes pratiques Remotion (techniques)

- **Animations pilotées par l'image courante** :
  - tout se calcule à partir de `useCurrentFrame()` et `useVideoConfig()` ;
  - **aucune** animation CSS, `transition` ou `setTimeout`, qui ne sont pas
    déterministes au rendu ;
  - `interpolate()` toujours avec `extrapolateLeft` et `extrapolateRight` à
    `'clamp'`, et `spring()` pour les mouvements.
- **Découpage** : une scène = un composant, assemblé dans des `<Sequence>`
  avec `premountFor`. Transitions avec `@remotion/transitions`
  (`<TransitionSeries>`).
- **Données** :
  - le découpage (textes, durées, captures) vit dans **un fichier de
    configuration typé** (`src/storyboard.ts`) ;
  - les compositions sont paramétrées avec un **schéma `zod`** (titre, appel à
    l'action, couleurs) ;
  - la durée totale est calculée depuis le storyboard (`calculateMetadata`),
    jamais codée en dur.
- **Médias** :
  - `<Img>` et `staticFile()` pour les images ;
  - `<OffthreadVideo>` pour les vidéos d'écran ;
  - `<Audio>` avec un volume animé pour le fondu et le ducking.
- **Police** : chargée avec `@remotion/fonts` (`loadFont`) depuis
  `public/fonts/`, avant tout rendu.
- **Deux formats sans duplication** : les scènes s'adaptent au ratio
  (`width > height`) grâce à des constantes de mise en page, et non à deux
  copies du code.
- **Qualité** :
  - TypeScript strict, ESLint propre, composants courts et nommés ;
  - pas de valeurs magiques : couleurs, rayons et durées dans `src/theme.ts` ;
  - vérifie chaque scène dans le Studio (`npx remotion studio`) avant le
    rendu.
- **Rendu** :
  ```
  npx remotion render PgdeDemo out/pgde-demo-16x9.mp4 --codec=h264 --crf=18
  npx remotion render PgdeDemoVertical out/pgde-demo-9x16.mp4 --codec=h264 --crf=18
  npx remotion still PgdeDemo out/miniature.png --frame=<image de l'accroche>
  ```
  Ajoute ces commandes en scripts `npm`.

---

## 6. Livrables attendus

1. Le découpage scène par scène, **à valider avant de coder**.
2. Le code Remotion : `src/theme.ts`, `src/storyboard.ts`, un dossier
   `src/scenes/`, des composants réutilisables (`CadreAppareil`,
   `ZoomCible`, `PointDeToucher`, `FriseEtapes`, `TitreAnime`) et les deux
   compositions.
3. Le texte de la voix off (optionnelle) et le fichier de sous-titres `.srt`.
4. Une miniature 1280 × 720 pour YouTube.
5. Un `README.md` : comment remplacer les captures, changer les textes et
   relancer le rendu.

## 7. Checklist de validation

- [ ] Le message principal se comprend sans le son, dès les 3 premières
  secondes.
- [ ] Seules les couleurs de la charte apparaissent, et le jaune n'est qu'un
  accent.
- [ ] Toutes les polices sont en Poppins.
- [ ] Chaque écran montré est un écran réel de l'app, ou un panneau
  « CAPTURE À VENIR ».
- [ ] Aucune donnée personnelle réelle n'est visible dans le rendu final.
- [ ] Aucune affirmation non vérifiée (boutique, date, chiffres).
- [ ] Les textes respectent les zones de sécurité dans les deux formats.
- [ ] Le rendu est sans saut d'image ni élément qui clignote.
- [ ] Les durées sont tenues (16:9 de 75 à 90 s, 9:16 de 45 à 60 s).
