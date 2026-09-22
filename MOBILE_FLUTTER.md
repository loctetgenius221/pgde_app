# 📱 Application mobile Flutter — Demandes d'emploi

**Document de référence pour l'équipe mobile**
Projet backend : `emplois-main` (Laravel 11 / PHP 8.2 / MySQL `emploi`)
Date d'analyse : 22 septembre 2026

---

## 0. À lire en premier — le verdict

> **Il n'existe aujourd'hui aucune API consommable par une application mobile.**

Le backend est une application **100 % web, rendue en Blade, authentifiée par session + cookie + CSRF**. Concrètement :

| Constat | Détail | Impact mobile |
| :--- | :--- | :--- |
| `routes/api.php` **n'est pas chargé** | `bootstrap/app.php` → `withRouting(web:, commands:, health:)` — la clé `api:` est absente | La seule route API du projet (`POST /api/chatbot/reset-password`) renvoie **404** |
| **Sanctum n'est pas installé** | `vendor/laravel/` contient breeze, framework, pail, pint, prompts, sail, tinker, ui — **pas sanctum** | Aucun mécanisme de token → impossible d'authentifier un client mobile |
| Toutes les routes métier sont en `web` | `middleware('auth')` = guard `session` | Nécessiterait de gérer cookie de session + token CSRF depuis Flutter = à éviter |
| Toutes les réponses sont des `redirect()` / `view()` | `UserdataController::store()` retourne `redirect()->route('userdata.summary', …)` | Aucun JSON exploitable |

**Conséquence : le chantier mobile commence par la création d'une couche API sur le backend.** Ce document décrit (a) tout ce que le mobile doit connaître du domaine métier existant, (b) le contrat d'API à faire produire côté backend, (c) le setup Flutter.

Les sections **§6 (bloqueurs)** et **§7 (contrat d'API)** sont celles à transmettre à l'équipe backend.

---

## 1. Architecture et environnement

### 1.1 Stack backend

```
Laravel        11.31
PHP            8.2+
Base           MySQL — base "emploi" (DB_HOST=127.0.0.1, DB_PORT=3306)
Session        driver database (table sessions)
Cache / Queue  database
Mail           MAIL_MAILER=log  ← en local, AUCUN mail n'est réellement envoyé
Front          Blade + Tailwind (vite) + jQuery/DataTables
Serveur dev    Laragon → http://emplois-main.test ou http://127.0.0.1:8000
```

### 1.2 Point d'attention immédiat pour le dev mobile

`APP_URL=localhost` dans `.env` (sans schéma). Les URLs générées par `asset()` et par les liens signés de vérification d'email sont donc **cassées**. À corriger avant tout test mobile :

```env
APP_URL=http://192.168.x.x:8000     # IP LAN de la machine de dev, joignable par le téléphone
```

> Un émulateur Android n'atteint **pas** `127.0.0.1`. Utiliser `10.0.2.2` (émulateur Android), `localhost` (simulateur iOS) ou l'IP LAN (appareil physique). Voir §8.4.

### 1.3 Le double modèle utilisateur — piège majeur

Le projet contient **deux** modèles d'utilisateur. Un seul compte :

| Modèle | Table | Statut | Utilisé par |
| :--- | :--- | :--- | :--- |
| `App\Models\Utilisateur` | `utilisateur` | ✅ **LE VRAI** — c'est le provider du guard (`config/auth.php` → `AUTH_MODEL`) | Inscription, connexion, dossier candidat, admin |
| `App\Models\User` | `users` | ⚠️ Vestige du squelette Laravel | Uniquement la route `/check-email` (donc cassée, voir §6) |

De même, `App\Models\Info` / table `infos` est un **formulaire de candidature de première génération**, remplacé par `userdata`. Seule la route `GET /info/create` subsiste. **Le mobile ignore complètement `users` et `infos`.**

---

## 2. Modèle de données métier

### 2.1 Schéma relationnel

```
utilisateur (compte)
   └─1:1─ userdata (LA DEMANDE D'EMPLOI)   ← utilisateur_id est UNIQUE
            ├── country_id              → countries
            ├── regionnaiss_id          → region
            ├── regionresidence_id      → region
            ├── departementnaiss_id     → departement (→ region)
            ├── departementresidence_id → departement (→ region)
            ├── emploi1_id              → emploi (→ secteur)   [vœu n°1]
            ├── emploi2_id              → emploi (→ secteur)   [vœu n°2]
            ├── handicap_id             → handicap
            ├── academic_id             → academic  [niveau de la 1ʳᵉ formation]
            ├── autresdiplomes  (JSON texte : toutes les formations)
            ├── experiences     (JSON texte : toutes les expériences)
            ├── diplome_file    (JSON texte : tableau de chemins)
            ├── cv_file         (JSON texte : tableau de chemins)
            └── photo_profil    (chemin simple)
```

> ⚠️ **`userdata.utilisateur_id` porte une contrainte UNIQUE.** Un candidat possède **une seule** demande, créée une fois puis modifiée. Le mobile ne doit donc jamais proposer « nouvelle demande » : le parcours est **créer si absente, sinon éditer**. Un second `POST` déclenche une erreur SQL 1062.

### 2.2 Table `utilisateur` (structure réelle en base)

| Colonne | Type | Notes pour le mobile |
| :--- | :--- | :--- |
| `id` | int PK | |
| `numberid` | varchar(255) **UNIQUE** | **N° CNI ou passeport** — saisi à l'inscription |
| `firstname` | varchar(255) NOT NULL | Prénom |
| `lastname` | varchar(255) NOT NULL | Nom |
| `username` | varchar(180) NOT NULL | **Identifiant de connexion** |
| `username_canonical` | varchar(180) UNIQUE | Généré par mutateur (`strtolower(trim())`) |
| `email` | varchar(180) | |
| `email_canonical` | varchar(180) UNIQUE | Généré par mutateur |
| `password` | varchar(255) | bcrypt **ou** hash Symfony3 legacy (voir §3.3) |
| `salt` | varchar(255) NULL | Non-null ⇒ compte legacy jamais reconnecté |
| `enabled` | tinyint(1) | **0 = email non vérifié / compte inactif**, 1 = actif |
| `recruted` | tinyint(1) def 0 | Marqué recruté par un admin |
| `roles` | longtext | **PHP `serialize()`** — `a:0:{}` = candidat, `a:1:{i:0;s:5:"admin";}` = admin |
| `date_inscription` | datetime | |
| `last_login` | datetime NULL | Mis à jour **uniquement** lors du login admin |
| `confirmation_token`, `password_requested_at` | | Vestiges Symfony, non utilisés |

`$timestamps = false` sur ce modèle : pas de `created_at`/`updated_at`.

**`roles` n'est pas du JSON.** C'est une chaîne PHP sérialisée. L'API ne doit jamais l'exposer brute : elle renvoie un booléen ou un tableau (`"roles": ["admin"]`).

### 2.3 Table `userdata` — la demande

Structure réelle (attention : elle **diverge de la migration**, voir §6.1) :

| Colonne | Type en base | Rempli à l'étape |
| :--- | :--- | :--- |
| `id` | int PK | |
| `utilisateur_id` | int **UNIQUE** NOT NULL | auto (utilisateur connecté) |
| `datenaiss` | date | 1 |
| `lieunaiss` | varchar(255) | 1 |
| `lieuresidence` | varchar(255) | 1 |
| `addresse` | varchar(255) | 1 |
| `genre` | varchar(10) | 1 |
| `situationmatrimoniale` | varchar(255) | 1 |
| `telephone1` / `telephone2` | varchar(45) | 1 |
| `nombreenfant` | int def 0 | 1 |
| `country_id`, `regionnaiss_id`, `regionresidence_id`, `departementnaiss_id`, `departementresidence_id`, `handicap_id` | int NULL | 1 |
| `academic_id` | int NULL | 2 (1ʳᵉ formation) |
| `diplome` | longtext | 2 (1ʳᵉ formation) |
| `anneediplome` | int | 2 (1ʳᵉ formation) |
| `specialite` | varchar(255) | 2 (1ʳᵉ formation) |
| `etablissementdiplome` | longtext | 2 (1ʳᵉ formation) |
| **`autresdiplomes`** | **varchar(255)** ⛔ | 2 — JSON de **toutes** les formations |
| `diplome_file` | text | 2 — JSON `["uploads/diplome/…", …]` |
| `cv_file` | text | 2 — JSON `["uploads/cv/…", …]` |
| `photo_profil` | varchar(255) | 2 — chemin simple |
| `experiences` | longtext | 3 — JSON de toutes les expériences |
| `posteoccupe` | longtext | 3 — dérivé : poste de la 1ʳᵉ expérience |
| `employeur` | longtext | 3 — dérivé : employeur de la 1ʳᵉ expérience |
| `nombreanneeexpe` | longtext | 3 — dérivé : **somme** des `years` |
| `emploi1_id` / `emploi2_id` | int NULL | 4 |
| `anneeexperience1` / `anneeexperience2` | int def 0 | 4 |
| `cv_summary` | text | 4 — texte libre ≤ 1000 car. |
| `motivation` | longtext | *jamais rempli par le formulaire actuel* |
| `created_at` / `updated_at` | timestamp auto | |

### 2.4 Format des colonnes JSON

Ce sont des **chaînes de texte** contenant du JSON (pas des colonnes `json` MySQL, pas de cast Eloquent). Le mobile doit `jsonDecode` après réception si l'API les relaie brutes — **mais l'API à construire doit les décoder côté serveur** et renvoyer de vrais tableaux JSON (voir §7.6).

**`autresdiplomes`** — exemple réel en base :
```json
[{"academic_id":"7","diplome":"dd","anneediplome":"2019","specialite":"FINANCE","etablissementdiplome":"ESTM"}]
```
Tous les champs sont castés en **string** par le contrôleur, y compris `academic_id` et `anneediplome`.

**`experiences`** — exemple réel :
```json
[{"description":"DDD","years":"2","poste":"Stagiaire","employeur":"ARTP"}]
```

**`diplome_file` / `cv_file`** — chemins relatifs, échappés :
```json
["uploads\/cv\/1775151073_Acte de reclassement.pdf"]
```

> Les noms de fichiers contiennent **espaces et accents** non assainis. Côté Flutter, toujours passer par `Uri.encodeFull()` avant d'afficher / télécharger.

---

## 3. Parcours métier à reproduire dans l'app

### 3.1 Vue d'ensemble

```
┌─────────────┐   POST /register            ┌──────────────────┐
│ Inscription │ ──────────────────────────▶ │ enabled = 0      │
└─────────────┘   + mail de vérification    │ compte inactif   │
                                            └────────┬─────────┘
                        clic lien signé (web)        │
                                            ┌────────▼─────────┐
                                            │ enabled = 1      │
                                            └────────┬─────────┘
┌─────────────┐   POST /login                        │
│  Connexion  │ ◀────────────────────────────────────┘
└──────┬──────┘
       │  userdata existe ?
       ├── NON ──▶ Wizard 4 étapes ──▶ POST userdata ──┐
       └── OUI ──▶ Résumé du dossier ◀─────────────────┘
                        │
                        ├── Éditer (PUT)
                        ├── Gérer fichiers (ajout / suppression)
                        ├── Changer la photo
                        └── Changer le mot de passe
```

### 3.2 Inscription — règles exactes (`AuthController::register`)

```php
'firstname' => 'required|string|max:255',
'lastname'  => 'required|string|max:255',
'username'  => 'required|string|max:180|unique:utilisateur',
'numberid'  => 'required|string|max:255|unique:utilisateur',
'email'     => 'required|string|email|max:255|unique:utilisateur|confirmed',
'password'  => 'required|string|min:8|confirmed',
```

Points à implémenter côté mobile :

- `email` est **`confirmed`** ⇒ le champ `email_confirmation` est **obligatoire** dans la requête (double saisie de l'email). Idem `password_confirmation`.
- Le rôle est **forcé** à `a:0:{}` côté serveur (correctif SEC-01). Ne jamais envoyer de champ de rôle.
- `enabled` est forcé à `0` ⇒ **écran « vérifiez votre email » obligatoire** après inscription.
- Messages d'erreur métier déjà traduits en français côté serveur (`Cet email est déjà utilisé.`, `Ce cni ou passport existe déjà.`, …) → l'app peut les afficher telles quelles.

### 3.3 Connexion — 3 subtilités critiques

```php
'username' => 'required|string',   // ⚠️ PAS l'email
'password' => 'required|string',
```

1. **On se connecte avec `username`, jamais avec l'email.** L'écran de login doit donc libeller « Nom d'utilisateur », et l'app doit stocker le `username` pour le remplissage automatique.

2. **Double vérification de mot de passe.** Le contrôleur essaie bcrypt, puis, si `salt` est non-null, le hash Symfony 3 legacy (`App\Services\PasswordService` : sha512, 5000 itérations sur `password{salt}`, base64). En cas de succès legacy, le mot de passe est **réécrit en bcrypt** et `salt` passé à `null`. ⇒ **L'endpoint de login de l'API doit impérativement conserver cette double logique**, sinon les 4 comptes existants (et tous les comptes migrés de l'ancienne plateforme) ne pourront plus se connecter.

3. **La connexion réussit même si `enabled = 0`** (bug BUG-02, non corrigé). Il faut décider du comportement mobile :
   - recommandé : l'API renvoie le token **et** `"enabled": false` → l'app route vers l'écran de vérification et bloque le wizard ;
   - sinon : l'API refuse avec `403`.

### 3.4 Vérification d'email — pas d'équivalent mobile aujourd'hui

`GET /email/verify/{id}/{hash}` est protégée par le middleware `signed` **et** par `hash_equals(sha1($user->email_canonical), $hash)`. C'est une URL web signée. Deux options :

- **Deep link** : l'app enregistre un App Link / Universal Link sur `/email/verify/*`, ouvre le lien, laisse le backend faire le travail et redirige vers l'app.
- **Code OTP** (plus simple et plus fiable) : nouvel endpoint API qui envoie un code à 6 chiffres et un endpoint de validation. **Recommandé.**

Prévoir dans les deux cas un **renvoi du mail/code** (`POST /email/verification-notification` existe déjà en web).

> `MAIL_MAILER=log` en local : les mails partent dans `storage/logs/laravel.log`. Pour tester le parcours mobile, configurer Mailpit/Mailtrap.

### 3.5 Bug à connaître : `hasVerifiedEmail()`

```php
// app/Models/Utilisateur.php
protected $casts = ['enabled' => 'boolean', …];

public function hasVerifiedEmail() {
    return $this->enabled === 1;   // ⛔ enabled est un bool → === 1 est TOUJOURS false
}
```

`hasVerifiedEmail()` renvoie donc **toujours `false`**. Le middleware `enabled` (`CheckAccountEnabled`) utilise `!$user->enabled`, qui fonctionne. L'API doit s'appuyer sur **`(bool) $user->enabled`**, pas sur `hasVerifiedEmail()`.

---

## 4. Le formulaire de demande — contrat de données exact

Source d'autorité : `UserdataController::store()` et `::update()`. Le wizard web comporte 4 étapes ; l'app doit les reprendre pour permettre l'édition ultérieure champ par champ.

### Étape 1 — Identité & résidence

| Champ | Règle `store()` | Règle `update()` | Valeurs |
| :--- | :--- | :--- | :--- |
| `datenaiss` | **required**\|date | nullable\|date | `YYYY-MM-DD` |
| `lieunaiss` | **required**\|string | nullable | texte |
| `lieuresidence` | **required**\|string | nullable | texte |
| `genre` | **required**\|string | nullable | `Masculin` \| `Feminin` |
| `telephone1` | **required**\|string | nullable | texte libre (varchar 45) |
| `telephone2` | nullable\|string | nullable | |
| `situationmatrimoniale` | nullable\|string | nullable | `Célibataire` \| `Marié(e)` \| `Divorcé(e)` \| `Veuf/Veuve` |
| `nombreenfant` | nullable\|integer | nullable\|integer | |
| `country_id` | nullable\|exists:countries,id | *absent de update()* ⚠️ | |
| `addresse` | nullable\|string | *absent de update()* ⚠️ | |
| `regionnaiss_id` | nullable\|exists:region,id | idem | |
| `departementnaiss_id` | nullable\|exists:departement,id | idem | |
| `regionresidence_id` | nullable\|exists:region,id | idem | |
| `departementresidence_id` | nullable\|exists:departement,id | idem | |
| `handicap_id` | nullable\|exists:handicap,id | idem | |
| `handicap` | *(non validé)* | *(non validé)* | `'0'` ⇒ force `handicap_id = null` |

> ⚠️ `country_id` et `addresse` sont acceptés à la création mais **absents de la validation de `update()`** : ils ne sont pas modifiables. À corriger côté backend (§6.2).
>
> Les valeurs de `genre` et `situationmatrimoniale` sont des **chaînes libres non contraintes en base** — les envoyer exactement comme listé ci-dessus, sinon les écrans admin de filtrage (masculin/féminin) ne verront pas le candidat.
>
> Logique `handicap` : radio « Avez-vous un handicap ? ». Si non → envoyer `handicap: "0"`. Si oui → envoyer `handicap_id`.

### Étape 2 — Formations (liste dynamique) + fichiers

Tableau `formations[]`, indexé :

| Champ | Règle | Notes |
| :--- | :--- | :--- |
| `formations` | nullable\|array | |
| `formations.*.academic_id` | **required** | ID de `academic`, ou la chaîne littérale `"sansdiplome"` |
| `formations.*.diplome` | nullable\|string | intitulé du diplôme |
| `formations.*.anneediplome` | nullable\|**integer** | année d'obtention |
| `formations.*.specialite` | nullable\|string | |
| `formations.*.etablissementdiplome` | nullable\|string | |

Traitement serveur :
- les entrées dont `academic_id` est vide sont **filtrées**, les autres réindexées ;
- `"sansdiplome"` est converti en **`20`** — ⛔ **l'id 20 n'existe pas** dans `academic` (le vrai est **14**). Voir §6.1 ;
- la **1ʳᵉ** formation est recopiée dans les colonnes plates (`academic_id`, `diplome`, `anneediplome`, `specialite`, `etablissementdiplome`) ;
- l'ensemble est sérialisé en JSON dans `autresdiplomes`.

Fichiers :

| Champ | Règle | Destination |
| :--- | :--- | :--- |
| `diplome_file` | nullable\|array | |
| `diplome_file.*` | file\|mimes:**pdf,doc,docx,rtf,txt**\|**max:2048** (2 Mo) | `public/uploads/diplome/` |
| `cv_file` | nullable\|array | |
| `cv_file.*` | file\|mimes:pdf,doc,docx,rtf,txt\|max:2048 | `public/uploads/cv/` |
| `photo_profil` | nullable\|image\|mimes:jpeg,png,jpg,gif\|max:2048 | `public/uploads/photos/` |

> Pas de PNG/JPG accepté pour un diplôme : **une photo de diplôme prise au téléphone sera refusée.** L'app doit soit convertir en PDF, soit demander l'ajout de `jpg,png` à la whitelist (§6.2).
>
> Nommage serveur : `time() . '_' . nom_original`. Non assaini, collisions possibles. L'URL de retour doit être encodée.

Suppression de fichiers en édition : champs texte `deleted_files` et `deleted_cv_files`, **chemins séparés par `;`**.

### Étape 3 — Expériences professionnelles

| Champ | Règle | Notes |
| :--- | :--- | :--- |
| `hasExperience` | nullable\|**in:oui,non** | ⚠️ doit valoir exactement `oui` pour que les expériences soient enregistrées |
| `experiences` | nullable\|array | |
| `experiences.*.description` | nullable\|string | |
| `experiences.*.years` | nullable\|integer | nb d'années sur ce poste |
| `experiences.*.poste` | nullable\|string | |
| `experiences.*.employeur` | nullable\|string | |

Traitement : une expérience est conservée si **au moins un** de `description`, `poste`, `employeur` est rempli. Si `hasExperience !== 'oui'` **ou** liste vide ⇒ `experiences`, `posteoccupe`, `employeur`, `nombreanneeexpe` sont **tous remis à `null`**.

> ⚠️ **Conséquence destructive** : un `PUT` partiel sans `hasExperience=oui` **efface les expériences déjà enregistrées**. Idem pour `autresdiplomes` si `formations` est absent. **L'app doit toujours renvoyer la totalité du dossier** (formations + expériences + `hasExperience`) à chaque mise à jour, ou faire corriger le backend (§6.2).

### Étape 4 — Vœux d'emploi

| Champ | Règle `store()` | Règle `update()` |
| :--- | :--- | :--- |
| `emploi1_id` | **required**\|exists:emploi,id | nullable\|exists:emploi,id |
| `emploi2_id` | **required**\|exists:emploi,id | nullable\|exists:emploi,id |
| `anneeexperience1` | nullable\|integer | idem |
| `anneeexperience2` | nullable\|integer | idem |
| `cv_summary` | nullable\|string\|**max:1000** | idem |

> Les deux vœux sont **obligatoires** à la création. Rien n'empêche `emploi1_id == emploi2_id` : à contrôler côté app (UX) et idéalement côté serveur (`different:emploi1_id`).
>
> Le choix se fait en cascade : **secteur → emploi**. `secteur_id` n'est pas stocké dans `userdata`, il ne sert qu'au filtrage de la liste. L'app doit donc, pour réafficher un vœu existant, remonter `emploi.secteur_id` pour présélectionner le secteur.

### Récapitulatif des champs obligatoires à la création

```
datenaiss, lieunaiss, lieuresidence, genre, telephone1, emploi1_id, emploi2_id
```

Tout le reste est optionnel côté serveur — même si le formulaire web marque davantage de champs `required` en HTML. L'app peut donc enregistrer un brouillon serveur dès l'étape 4 franchie.

---

## 5. Données de référence (listes déroulantes)

Volumes et identifiants **réels** en base, à la date d'analyse :

| Table | Lignes | Colonnes | Remarques |
| :--- | :--- | :--- | :--- |
| `region` | **15** | `id`, `libelle` | 14 régions du Sénégal + **`15 = Hors Sénégal`** |
| `departement` | **46** | `id`, `region_id`, `libelle` | cascade depuis `region` |
| `secteur` | **16** | `id`, `libelle` | ids **1→15 et 19** (non contigus) |
| `emploi` | **491** | `id`, `secteur_id`, `libelle` | cascade depuis `secteur` |
| `academic` | **18** | `id`, `libelle` | ids **1→10 et 14→18** (non contigus) |
| `handicap` | **4** | `id`, `libelle` | |
| `countries` | ~195 | `id`, `name` | seeder `CountrySeeder`, libellés FR |

### 5.1 `region` (valeurs exactes)

`1` Dakar · `2` Diourbel · `3` Fatick · `4` Kaffrine · `5` Kaolack · `6` Kédougou · `7` Kolda · `8` Louga · `9` Matam · `10` Saint-Louis · `11` Sédhiou · `12` Tambacounda · `13` Thiès · `14` Ziguinchor · **`15` Hors Sénégal**

> Si l'utilisateur choisit `regionresidence_id = 15` (*Hors Sénégal*), l'app doit afficher le sélecteur `country_id`. Il n'y a **pas** de département rattaché à la région 15.

### 5.2 `academic` (niveaux d'études — valeurs exactes)

| id | libellé |
| :-- | :-- |
| 1 | Supérieur à BAC+5 |
| 2 | Master 2 |
| 3 | Master 1 |
| 4 | Licence |
| 5 | BAC+2 |
| 6 | BAC+1 |
| 7 | BAC |
| 8 | DTS |
| 9 | BTS |
| 10 | BFEM |
| **14** | **sansdiplome** |
| 15 | CFEE |
| 16 | CAP |
| 17 | BT |
| 18 | Doctorat |

> Ni ordonné par niveau, ni contigu. **Ne jamais trier par `id`** : l'app doit appliquer son propre ordre d'affichage (Doctorat → Supérieur BAC+5 → Master 2 → … → Sans diplôme). Et **`sansdiplome` = 14**, pas 20 (voir §6.1).

### 5.3 `handicap`

`1` Handicap physique · `2` Handicap visuel · `3` Handicap mental · `4` Un mélange de plusieurs types d'handicaps

### 5.4 `secteur` (valeurs exactes)

`1` Affaires générales · `2` Agriculture / Elevage / Pêche · `3` BTP / Transport / Mécanique · `4` Documentation · `5` Education / Enseignement · `6` Finances · `7` Gestion / Comptabilité · `8` Industrie / Mines / Energies / Electricité / Hydraulique · `9` Informatique / Télécom / Téléservices · `10` Menuiserie / Peinture / Plomberie / Maçonnerie · `11` Planification · `12` Santé · `13` Science sociale / Affaire juridique · `14` Tourisme / Culture / Hotelerie · `15` Urbanisation / Envirronement / Eaux / Forêt · `19` Communication

> Les libellés en base contiennent des fautes (`Envirronement`, `Hotelerie`) et des accents. À ne pas « corriger » côté mobile : afficher tel quel ou demander un nettoyage en base.
>
> ⚠️ Le seeder `SecteursTableSeeder` insère dans une table **`secteurs`** avec une colonne **`nom`** — ni la table ni la colonne n'existent (le vrai est `secteur`.`libelle`). Ce seeder est mort, ne pas s'y fier.

### 5.5 Endpoints de référence existants (web, publics, sans auth)

Utilisables **immédiatement** pour prototyper, mais à consolider :

```
GET /departements-par-region/{regionId}    → JSON des départements
GET /get-departements/{region_id}          → idem (doublon)
GET /getDepartements/{regionId}            → idem (doublon)
GET /departements/{region_id}              → idem (doublon)
GET /emplois-par-secteur/{secteur_id}      → JSON des emplois
GET /check-email?email=...                 → ⛔ CASSÉ, interroge la table `users`
```

**Aucun endpoint n'existe pour `region`, `secteur`, `academic`, `handicap`, `countries`.** Ils doivent être créés (§7.3).

### 5.6 Stratégie de cache mobile recommandée

491 emplois + 195 pays + 46 départements = référentiel volumineux mais **quasi statique**.

- Un unique appel `GET /api/v1/ref/bootstrap` au premier lancement → tout le référentiel en une réponse.
- Persister dans une base locale (Hive ou sqflite / Drift).
- Revalider via `ETag` / `If-None-Match` ou un champ `version` → `304` la plupart du temps.
- **Le wizard doit fonctionner hors ligne** une fois le référentiel en cache : c'est un formulaire long, sur des réseaux souvent instables.

---

## 6. Ce qui bloque le mobile aujourd'hui

### 6.1 Bloqueurs durs (corrections backend indispensables)

| # | Problème | Preuve | Correctif |
| :-- | :--- | :--- | :--- |
| **B1** | `routes/api.php` n'est pas chargé | `bootstrap/app.php` : `withRouting(web:, commands:, health:)` | Ajouter `api: __DIR__.'/../routes/api.php'` |
| **B2** | Aucun système de token | Sanctum absent de `vendor/laravel/` | `composer require laravel/sanctum` + `HasApiTokens` sur `Utilisateur` |
| **B3** | **`autresdiplomes` est `varchar(255)`** alors que la migration déclare `json` | En base : `varchar(255)`. Une **seule** formation occupe déjà **183 caractères**. `sql_mode` inclut `STRICT_TRANS_TABLES` ⇒ **erreur SQL 1406 « Data too long »** dès la 2ᵈᵉ formation | `ALTER TABLE userdata MODIFY autresdiplomes JSON NULL;` (ou `LONGTEXT`) — **sinon les formations multiples sont impossibles**, sur mobile comme sur le web |
| **B4** | `academic_id = 20` pour « sans diplôme » | `SELECT * FROM academic WHERE id IN (19,20)` ⇒ **0 ligne**. Le vrai id est **14** | Remplacer `20` par `14` dans `UserdataController::store()` et `::update()` (3 occurrences), et corriger les données existantes |
| **B5** | Routes de photo de profil sans paramètre | `Route::post('/update-photo', …)` et `/updatephoto-profil` vs `updatePhotoProfil(Request $request, $id)` ⇒ **`ArgumentCountError`** | `Route::post('/update-photo/{id}', …)` ou déduire l'id du user connecté |
| **B6** | `/check-email` interroge la mauvaise table | `User::where('email', …)` → table `users`, alors que les candidats sont dans `utilisateur` | Utiliser `Utilisateur::where('email_canonical', strtolower(trim($email)))` |
| **B7** | `POST /api/chatbot/reset-password` inatteignable | conséquence de B1 | résolu par B1 |
| **B8** | `APP_URL=localhost` | `.env` | URL absolue avec schéma — sinon liens signés et `asset()` cassés |

### 6.2 Bloqueurs de conception (à arbitrer avec le backend)

| # | Problème | Enjeu mobile | Recommandation |
| :-- | :--- | :--- | :--- |
| **D1** | `update()` **écrase avec `null`** les expériences et formations absentes de la requête | Toute sauvegarde partielle détruit des données | Ne modifier `experiences` / `autresdiplomes` que si la clé est **présente** dans la requête ; ou exposer des sous-ressources dédiées |
| **D2** | `country_id` et `addresse` absents de la validation de `update()` | Champs non modifiables après création | Les ajouter |
| **D3** | Pas de notion d'état de la demande (`brouillon` / `soumise` / `traitée`) | Impossible d'afficher un statut, ni un suivi | Ajouter `statut` + `submitted_at` sur `userdata` (la table `infos`, obsolète, possédait déjà un `is_submitted`) |
| **D4** | `mimes` des diplômes/CV : pas d'images | Une photo de diplôme prise au téléphone est **refusée** | Ajouter `jpg,jpeg,png` (+ conversion PDF côté app) |
| **D5** | `max:2048` (2 Mo) par fichier | Une photo de smartphone dépasse 2 Mo | Compresser côté Flutter (`flutter_image_compress`) **avant** l'envoi |
| **D6** | Fichiers écrits dans `public/uploads/` via `$file->move()` | Documents d'identité **publiquement accessibles sans authentification** (URL devinable) | Migrer vers `storage/app/private` + route de téléchargement authentifiée. À signaler comme risque RGPD/confidentialité |
| **D7** | Noms de fichiers non assainis + `time()` comme préfixe | Collisions, URLs à encoder | `Str::uuid()` + extension |
| **D8** | Pas de pagination ni de tri sur les listes de référence | 491 emplois en une réponse | Acceptable si mis en cache (§5.6) ; sinon paginer |
| **D9** | `emploi1_id` peut égaler `emploi2_id` | Vœu en doublon | `different:emploi1_id` |
| **D10** | Login possible avec `enabled = 0` (BUG-02) | Un utilisateur non vérifié atteindrait le wizard | Décider : token + flag, ou `403` (§3.3) |
| **D11** | `roles` en `serialize()` (SEC-05, non corrigé) | Ne jamais exposer brut | L'API renvoie `is_admin: bool` |

---

## 7. Contrat d'API à faire produire (spécification)

Base : `/api/v1`. Auth : **Laravel Sanctum**, token Bearer.
Toutes les réponses en `application/json`. En-têtes requis côté client : `Accept: application/json`.

### 7.1 Format d'erreur (standard Laravel)

Validation — **422** :
```json
{
  "message": "Le champ datenaiss est obligatoire.",
  "errors": {
    "datenaiss": ["Le champ datenaiss est obligatoire."],
    "emploi1_id": ["Le vœu n°1 est obligatoire."]
  }
}
```
Autres codes : `401` token absent/invalide · `403` compte non activé ou accès refusé · `404` ressource absente · `409` dossier déjà existant · `413` fichier trop lourd · `422` validation · `429` throttle · `500`.

> L'app doit mapper `errors` vers les champs du wizard **et savoir sur quelle étape naviguer** pour chaque champ en erreur. Voir §8.7.

### 7.2 Authentification

| Méthode | Endpoint | Corps | Réponse |
| :--- | :--- | :--- | :--- |
| POST | `/auth/register` | `firstname, lastname, username, numberid, email, email_confirmation, password, password_confirmation, device_name` | `201` + `{user, message}` (pas de token : compte inactif) |
| POST | `/auth/login` | `username, password, device_name` | `200` + `{token, user}` |
| POST | `/auth/logout` | — | `204` (révoque le token courant) |
| GET | `/auth/me` | — | `200` + `{user}` |
| POST | `/auth/email/resend` | — | `202` |
| POST | `/auth/email/verify` | `code` *(si option OTP)* | `200` + `{user}` |
| POST | `/auth/password/forgot` | `email, numberid` | `202` |
| POST | `/auth/password/reset` | `token, email, password, password_confirmation` | `200` |
| POST | `/auth/password/change` | `current_password, new_password, new_password_confirmation` | `200` |

**`POST /auth/login` — réponse** :
```json
{
  "token": "12|4f8Qk…",
  "user": {
    "id": 332099,
    "firstname": "Moussa",
    "lastname": "Sagna",
    "username": "msagna",
    "numberid": "1234567890123",
    "email": "msagna@example.com",
    "enabled": true,
    "recruted": false,
    "is_admin": false,
    "has_demande": true,
    "demande_id": 1369020,
    "last_login": "2026-09-22T10:15:00Z"
  }
}
```

> `has_demande` / `demande_id` évitent un second aller-retour au démarrage : l'app sait immédiatement s'il faut router vers le wizard ou vers le résumé.
>
> **Exigence non négociable** : cet endpoint doit réutiliser la double vérification bcrypt / Symfony3 de `AuthController::login` (§3.3), y compris la réécriture en bcrypt et la remise à `null` de `salt`.

### 7.3 Données de référence

| Méthode | Endpoint | Réponse |
| :--- | :--- | :--- |
| GET | `/ref/bootstrap` | tout le référentiel + `version` / `ETag` |
| GET | `/ref/regions` | `[{id, libelle}]` |
| GET | `/ref/regions/{id}/departements` | `[{id, libelle, region_id}]` |
| GET | `/ref/secteurs` | `[{id, libelle}]` |
| GET | `/ref/secteurs/{id}/emplois` | `[{id, libelle, secteur_id}]` |
| GET | `/ref/academics` | `[{id, libelle, ordre}]` ← ajouter un champ d'ordre d'affichage |
| GET | `/ref/handicaps` | `[{id, libelle}]` |
| GET | `/ref/countries` | `[{id, name}]` |

Publics (pas de token) — ce sont des nomenclatures.

**`GET /ref/bootstrap`** :
```json
{
  "version": "2026-09-22T10:00:00Z",
  "regions":     [{"id":1,"libelle":"Dakar"}, "…15 items"],
  "departements":[{"id":1,"libelle":"Dakar","region_id":1}, "…46 items"],
  "secteurs":    [{"id":1,"libelle":"Affaires générales"}, "…16 items"],
  "emplois":     [{"id":1,"libelle":"…","secteur_id":1}, "…491 items"],
  "academics":   [{"id":18,"libelle":"Doctorat","ordre":1}, "…18 items"],
  "handicaps":   [{"id":1,"libelle":"Handicap physique"}, "…4 items"],
  "countries":   [{"id":1,"name":"Afghanistan"}, "…~195 items"]
}
```

### 7.4 Disponibilité (avant inscription)

| Méthode | Endpoint | Réponse |
| :--- | :--- | :--- |
| GET | `/availability?username=…` | `{"available": true}` |
| GET | `/availability?email=…` | `{"available": false}` |
| GET | `/availability?numberid=…` | `{"available": true}` |

Interroger la table **`utilisateur`** sur les colonnes canoniques. Permet une validation en temps réel dans le formulaire d'inscription au lieu d'un `422` à la soumission. **À throttler.**

### 7.5 La demande (`userdata`)

| Méthode | Endpoint | Rôle |
| :--- | :--- | :--- |
| GET | `/demande` | Mon dossier — `200` ou `404` s'il n'existe pas |
| POST | `/demande` | Créer (une seule fois) — `201`, ou `409` si déjà créé |
| PUT | `/demande` | Mettre à jour |
| PATCH | `/demande/step/{1..4}` | *(optionnel)* sauvegarde par étape |
| POST | `/demande/submit` | *(si D3 retenu)* passer de brouillon à soumise |
| POST | `/demande/photo` | `multipart` — champ `photo_profil` |
| POST | `/demande/files` | `multipart` — `diplome_file[]` et/ou `cv_file[]` |
| DELETE | `/demande/files` | `{"type":"cv"\|"diplome","path":"uploads/cv/…"}` |

> Aucun `{id}` dans l'URL : le dossier est déduit de l'utilisateur authentifié. Cela **supprime par construction la classe de failles IDOR** corrigée manuellement dans le contrôleur web (SEC-02).

### 7.6 `GET /demande` — réponse de référence

L'API **décode** les colonnes JSON, **résout** les libellés et **absolutise** les URLs de fichiers. C'est le point le plus important pour le mobile : ne jamais renvoyer les colonnes brutes.

```json
{
  "id": 1369020,
  "utilisateur_id": 332099,
  "statut": "brouillon",
  "completion": { "pourcentage": 75, "etapes_completes": [1,2,3], "etape_courante": 4 },

  "identite": {
    "datenaiss": "1998-04-12",
    "genre": "Masculin",
    "situationmatrimoniale": "Célibataire",
    "nombreenfant": 0,
    "telephone1": "+221770000000",
    "telephone2": null,
    "lieunaiss": "Dakar",
    "lieuresidence": "Pikine",
    "addresse": "Rue 12 x 15",
    "naissance":  { "region": {"id":1,"libelle":"Dakar"}, "departement": {"id":1,"libelle":"Dakar"} },
    "residence":  { "region": {"id":1,"libelle":"Dakar"}, "departement": {"id":2,"libelle":"Pikine"} },
    "pays": null,
    "handicap": null
  },

  "formations": [
    { "academic_id": 7, "academic_libelle": "BAC", "diplome": "Baccalauréat S2",
      "anneediplome": 2019, "specialite": "FINANCE", "etablissementdiplome": "ESTM" }
  ],

  "has_experience": true,
  "experiences": [
    { "description": "Stage à l'ARTP", "years": 2, "poste": "Stagiaire", "employeur": "ARTP" }
  ],
  "nombreanneeexpe": 2,

  "voeux": {
    "emploi1": { "id": 12, "libelle": "Développeur web", "secteur": {"id":9,"libelle":"Informatique / Télécom / Téléservices"}, "annees": 2 },
    "emploi2": { "id": 45, "libelle": "Analyste financier", "secteur": {"id":6,"libelle":"Finances"}, "annees": 0 }
  },
  "cv_summary": "…",

  "fichiers": {
    "photo_profil": { "path": "uploads/photos/177_x.jpg", "url": "http://…/uploads/photos/177_x.jpg" },
    "diplomes": [ { "path": "uploads/diplome/177_d.pdf", "url": "http://…/uploads/diplome/177_d.pdf", "nom": "d.pdf", "taille": 184320 } ],
    "cv":       [ { "path": "uploads/cv/177_cv.pdf",     "url": "http://…/uploads/cv/177_cv.pdf",     "nom": "cv.pdf", "taille": 92160 } ]
  },

  "created_at": "2026-09-01T09:12:00Z",
  "updated_at": "2026-09-20T14:03:00Z"
}
```

Le champ `path` est conservé en plus de `url` : c'est **lui** qu'il faut renvoyer à `DELETE /demande/files` et dans `deleted_files`.

### 7.7 `POST /demande` — corps attendu

Deux formes à supporter :

**(a) JSON pur** (sans fichier) — recommandé pour le wizard, les fichiers passant par `/demande/files` :
```json
{
  "datenaiss": "1998-04-12",
  "lieunaiss": "Dakar",
  "lieuresidence": "Pikine",
  "genre": "Masculin",
  "situationmatrimoniale": "Célibataire",
  "nombreenfant": 0,
  "telephone1": "+221770000000",
  "telephone2": null,
  "addresse": "Rue 12 x 15",
  "country_id": null,
  "regionnaiss_id": 1,
  "departementnaiss_id": 1,
  "regionresidence_id": 1,
  "departementresidence_id": 2,
  "handicap": "0",
  "handicap_id": null,

  "formations": [
    { "academic_id": 7, "diplome": "Baccalauréat S2", "anneediplome": 2019,
      "specialite": "FINANCE", "etablissementdiplome": "ESTM" }
  ],

  "hasExperience": "oui",
  "experiences": [
    { "description": "Stage à l'ARTP", "years": 2, "poste": "Stagiaire", "employeur": "ARTP" }
  ],

  "emploi1_id": 12,
  "emploi2_id": 45,
  "anneeexperience1": 2,
  "anneeexperience2": 0,
  "cv_summary": "…"
}
```

**(b) `multipart/form-data`** — si les fichiers accompagnent le formulaire. Laravel attend alors la **notation à crochets**, ce qui a des conséquences directes sur la construction du `FormData` Dio (§8.6) :

```
datenaiss=1998-04-12
formations[0][academic_id]=7
formations[0][diplome]=Baccalauréat S2
formations[1][academic_id]=4
experiences[0][poste]=Stagiaire
experiences[0][years]=2
hasExperience=oui
diplome_file[]=<binaire>
diplome_file[]=<binaire>
cv_file[]=<binaire>
photo_profil=<binaire>
```

---

## 8. Setup de l'application Flutter

### 8.1 Cible

```
Flutter        3.24+ / Dart 3.5+
Plateformes    Android 7.0+ (API 24), iOS 13+
Langue         français (unique) — locale fr_FR
Orientation    portrait
```

### 8.2 Dépendances

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # Réseau
  dio: ^5.7.0
  pretty_dio_logger: ^1.4.0
  connectivity_plus: ^6.0.5

  # État & navigation
  flutter_riverpod: ^2.5.1
  go_router: ^14.2.7

  # Modèles
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0

  # Stockage
  flutter_secure_storage: ^9.2.2   # token uniquement
  hive: ^2.2.3                      # référentiel + brouillon du wizard
  hive_flutter: ^1.1.0

  # Fichiers & médias
  image_picker: ^1.1.2
  file_picker: ^8.1.2
  flutter_image_compress: ^2.3.0    # cf. D5 — limite 2 Mo
  cached_network_image: ^3.4.1
  open_filex: ^4.5.0                # ouvrir un CV/diplôme téléchargé
  permission_handler: ^11.3.1

  # Divers
  intl: ^0.19.0
  url_launcher: ^6.3.0

dev_dependencies:
  build_runner: ^2.4.13
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  flutter_lints: ^4.0.0
```

### 8.3 Arborescence

```
lib/
├── main.dart
├── app.dart                        # MaterialApp.router + thème + locale fr
├── core/
│   ├── config/env.dart             # baseUrl par flavor
│   ├── network/
│   │   ├── api_client.dart         # Dio + intercepteurs
│   │   ├── auth_interceptor.dart   # Bearer + 401
│   │   └── api_exception.dart      # mapping 422 → erreurs par champ
│   ├── storage/
│   │   ├── token_store.dart        # flutter_secure_storage
│   │   └── local_db.dart           # Hive (référentiel, brouillon)
│   ├── router/app_router.dart
│   └── theme/
├── features/
│   ├── auth/
│   │   ├── data/   (auth_api.dart, auth_repository.dart)
│   │   ├── domain/ (utilisateur.dart)
│   │   └── ui/     (login, register, verify_email, forgot_password)
│   ├── reference/
│   │   ├── data/   (ref_api.dart, ref_repository.dart)  # cache-first
│   │   └── domain/ (region, departement, secteur, emploi, academic, handicap, country)
│   └── demande/
│       ├── data/   (demande_api.dart, demande_repository.dart, draft_store.dart)
│       ├── domain/ (demande.dart, formation.dart, experience.dart, voeu.dart)
│       └── ui/
│           ├── wizard/             # 4 étapes + barre de progression
│           │   ├── step1_identite.dart
│           │   ├── step2_formations.dart
│           │   ├── step3_experiences.dart
│           │   └── step4_voeux.dart
│           ├── summary_page.dart   # équivalent de userdata.summary
│           ├── files_page.dart
│           └── profile_photo.dart
└── shared/widgets/                 # champs, sélecteur cascade, uploader
```

### 8.4 Configuration réseau par plateforme

| Contexte d'exécution | `baseUrl` |
| :--- | :--- |
| Émulateur Android | `http://10.0.2.2:8000/api/v1` |
| Simulateur iOS | `http://localhost:8000/api/v1` |
| Appareil physique (même Wi-Fi) | `http://192.168.x.x:8000/api/v1` |
| Recette / prod | `https://…/api/v1` |

Lancer le serveur en écoute sur toutes les interfaces : `php artisan serve --host=0.0.0.0 --port=8000`.

En HTTP clair sur un appareil physique, prévoir :
- **Android** : `android:usesCleartextTraffic="true"` dans le `<application>` du manifest (debug uniquement) ;
- **iOS** : `NSAppTransportSecurity` / `NSAllowsLocalNetworking` dans `Info.plist` (debug uniquement).

Permissions à déclarer : caméra + photothèque (`image_picker`), lecture de documents (`file_picker`). Sur iOS, renseigner `NSCameraUsageDescription` et `NSPhotoLibraryUsageDescription`.

### 8.5 Client HTTP

```dart
class ApiClient {
  ApiClient(this._tokenStore)
      : dio = Dio(BaseOptions(
          baseUrl: Env.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(minutes: 2), // uploads
          headers: {'Accept': 'application/json'},
          // on gère nous-mêmes les codes d'erreur
          validateStatus: (code) => code != null && code < 500,
        )) {
    dio.interceptors.add(AuthInterceptor(_tokenStore));
  }

  final Dio dio;
  final TokenStore _tokenStore;
}
```

> `Accept: application/json` est **obligatoire** : sans cet en-tête, Laravel répond par une **redirection HTML** (302 vers `/login`) au lieu d'un `401` JSON, et les erreurs de validation renvoient du HTML au lieu du `422`.
>
> Le token Sanctum est **opaque et sans expiration** (pas de JWT) : il n'y a **pas** de refresh token. Sur `401`, purger le stockage sécurisé et renvoyer vers l'écran de connexion.

### 8.6 Upload multipart — notation à crochets

Le piège principal côté Dio : Laravel attend `formations[0][academic_id]`, pas un JSON imbriqué.

```dart
FormData buildDemandeForm(Demande d, List<File> diplomes, List<File> cvs) {
  final map = <String, dynamic>{
    'datenaiss': d.datenaiss,                 // 'YYYY-MM-DD'
    'lieunaiss': d.lieunaiss,
    'lieuresidence': d.lieuresidence,
    'genre': d.genre,                         // 'Masculin' | 'Feminin'
    'telephone1': d.telephone1,
    'emploi1_id': d.emploi1Id,
    'emploi2_id': d.emploi2Id,
    'hasExperience': d.hasExperience ? 'oui' : 'non',
  };

  // Aplatir les listes en notation à crochets
  for (var i = 0; i < d.formations.length; i++) {
    final f = d.formations[i];
    map['formations[$i][academic_id]'] = f.academicId.toString();
    map['formations[$i][diplome]'] = f.diplome ?? '';
    map['formations[$i][anneediplome]'] = f.anneediplome?.toString() ?? '';
    map['formations[$i][specialite]'] = f.specialite ?? '';
    map['formations[$i][etablissementdiplome]'] = f.etablissement ?? '';
  }

  for (var i = 0; i < d.experiences.length; i++) {
    final e = d.experiences[i];
    map['experiences[$i][description]'] = e.description ?? '';
    map['experiences[$i][years]'] = e.years?.toString() ?? '';
    map['experiences[$i][poste]'] = e.poste ?? '';
    map['experiences[$i][employeur]'] = e.employeur ?? '';
  }

  final form = FormData.fromMap(map);

  // Fichiers multiples : MÊME clé 'diplome_file[]' répétée
  for (final f in diplomes) {
    form.files.add(MapEntry(
      'diplome_file[]',
      MultipartFile.fromFileSync(f.path, filename: p.basename(f.path)),
    ));
  }
  for (final f in cvs) {
    form.files.add(MapEntry(
      'cv_file[]',
      MultipartFile.fromFileSync(f.path, filename: p.basename(f.path)),
    ));
  }
  return form;
}
```

À vérifier **avant** l'envoi :
- taille ≤ **2 Mo** par fichier (`max:2048`) → sinon `422`. Compresser les images, refuser côté app avec un message clair ;
- extension dans `pdf, doc, docx, rtf, txt` pour diplômes et CV ; `jpeg, png, jpg, gif` pour la photo ;
- `upload_max_filesize` / `post_max_size` de PHP (défaut Laragon : 2M / 8M). Un envoi groupé de plusieurs fichiers peut dépasser `post_max_size` et produire une **réponse vide** — cas à gérer explicitement.

### 8.7 Wizard : mapping champ → étape

Indispensable pour router les erreurs `422` vers le bon écran :

```dart
const fieldStep = <String, int>{
  'datenaiss': 1, 'lieunaiss': 1, 'lieuresidence': 1, 'genre': 1,
  'situationmatrimoniale': 1, 'nombreenfant': 1, 'telephone1': 1, 'telephone2': 1,
  'addresse': 1, 'country_id': 1, 'regionnaiss_id': 1, 'departementnaiss_id': 1,
  'regionresidence_id': 1, 'departementresidence_id': 1, 'handicap_id': 1,

  'formations': 2, 'diplome_file': 2, 'cv_file': 2, 'photo_profil': 2,

  'hasExperience': 3, 'experiences': 3,

  'emploi1_id': 4, 'emploi2_id': 4,
  'anneeexperience1': 4, 'anneeexperience2': 4, 'cv_summary': 4,
};
```

Les clés indexées reçues (`formations.0.academic_id`, `experiences.1.years`) doivent être normalisées : remplacer `\.\d+\..*` par la racine avant lookup.

### 8.8 Brouillon local — non négociable

Le formulaire compte ~30 champs plus deux listes dynamiques. Sur un réseau instable, une saisie perdue fait abandonner le candidat.

- Persister le brouillon dans **Hive** à chaque changement d'étape (et en `debounce` sur les champs longs).
- Au lancement : si un brouillon existe et qu'aucune demande serveur n'est présente, proposer « Reprendre votre demande ».
- Après un `POST`/`PUT` réussi, purger le brouillon.
- Ne **jamais** mettre de fichier binaire dans Hive : stocker les chemins et vérifier leur existence à la reprise.

### 8.9 Règles d'affichage à respecter

| Sujet | Règle |
| :--- | :--- |
| Dates | Saisie via `showDatePicker`, envoi en `YYYY-MM-DD`, affichage en `dd/MM/yyyy` (`intl`, locale `fr`) |
| Niveaux d'études | Ordre d'affichage **imposé par l'app**, pas par l'`id` (§5.2) |
| Cascade région → département | Vider le département dès que la région change ; masquer si `region_id == 15` |
| Cascade secteur → emploi | 491 emplois : prévoir une **recherche textuelle** dans le sélecteur, pas un simple `DropdownButton` |
| Région 15 (Hors Sénégal) | Afficher `country_id`, masquer le département |
| Handicap | Radio oui/non ; « non » ⇒ envoyer `handicap: "0"` |
| « Sans diplôme » | Masquer diplôme / année / spécialité / établissement ; envoyer `academic_id: 14` (§6.1 B4) |
| Téléphone | `varchar(45)`, aucun format imposé en base : valider côté app (format sénégalais + international) |
| URLs de fichiers | Toujours `Uri.encodeFull()` (espaces et accents dans les noms) |
| Photo de profil | Gérer les deux préfixes historiques : `uploads/photos/…` **et** `storage/uploads/…` (une ligne legacy utilise le second) |

---

## 9. Ordre des travaux recommandé

### Backend (prérequis)

1. **B1** charger `routes/api.php` · **B2** installer Sanctum + `HasApiTokens` · **B8** corriger `APP_URL`.
2. **B3** `ALTER TABLE userdata MODIFY autresdiplomes JSON NULL;` — *sans quoi les formations multiples sont impossibles.*
3. **B4** corriger `20` → `14` pour « sans diplôme ».
4. Endpoints d'auth (§7.2) en **réutilisant la double vérification bcrypt/Symfony3**.
5. Endpoints de référence (§7.3) + `/ref/bootstrap`.
6. Endpoints de la demande (§7.5) avec `FormRequest` partagés entre web et API, et `DemandeResource` (§7.6).
7. **D1** rendre `update()` non destructif · **D2** ajouter `country_id`/`addresse`.
8. **D3** statut de la demande · **D6** sortir les fichiers de `public/`.
9. Arbitrer **D4/D5** (formats et poids des fichiers) et **D10** (login si `enabled = 0`).

### Mobile (parallélisable)

1. Squelette + thème + `go_router` + client Dio (mockable).
2. Écrans d'auth sur mocks, en attendant les endpoints réels.
3. Module référentiel + cache Hive (les 4 routes `departements`/`emplois` existantes permettent de démarrer dès maintenant).
4. Wizard 4 étapes + brouillon local (le contrat de §4 est **stable** : c'est la validation réelle du contrôleur).
5. Upload de fichiers + photo de profil.
6. Résumé du dossier, édition, changement de mot de passe.
7. Branchement sur l'API réelle, gestion des `422`, hors ligne, états vides et d'erreur.

---

## 10. Annexe — commandes de vérification

Référentiel utilisable dès aujourd'hui (routes web publiques) :

```bash
curl http://127.0.0.1:8000/departements-par-region/1
curl http://127.0.0.1:8000/emplois-par-secteur/9
```

Inspection directe du référentiel (Laragon, MySQL 8.4) :

```bash
mysql -u root -p -h 127.0.0.1 emploi -e "SELECT id,libelle FROM academic ORDER BY id;"
mysql -u root -p -h 127.0.0.1 emploi -e "SELECT id,libelle FROM region ORDER BY id;"
mysql -u root -p -h 127.0.0.1 emploi -e "SELECT COUNT(*) FROM emploi;"
```

Reproduire le bloqueur **B3** (truncature de `autresdiplomes`) :

```sql
SELECT id, LENGTH(autresdiplomes) FROM userdata WHERE autresdiplomes IS NOT NULL;
-- 183 caractères pour UNE formation, colonne varchar(255) → la 2ᵈᵉ échoue
SHOW COLUMNS FROM userdata LIKE 'autresdiplomes';   -- varchar(255)
```

Confirmer le bloqueur **B4** :

```sql
SELECT * FROM academic WHERE id IN (19, 20);   -- 0 ligne : l'id 20 n'existe pas
SELECT * FROM academic WHERE libelle = 'sansdiplome';  -- id = 14
```

---

## 11. Fichiers de référence du backend

| Sujet | Fichier |
| :--- | :--- |
| Inscription / connexion / changement de mdp | [app/Http/Controllers/AuthController.php](app/Http/Controllers/AuthController.php) |
| **Le formulaire de demande (contrat d'autorité)** | [app/Http/Controllers/UserdataController.php](app/Http/Controllers/UserdataController.php) |
| Vérification d'email | [app/Http/Controllers/VerificationController.php](app/Http/Controllers/VerificationController.php) |
| Modèle utilisateur réel | [app/Models/Utilisateur.php](app/Models/Utilisateur.php) |
| Modèle de la demande | [app/Models/Userdata.php](app/Models/Userdata.php) |
| Toutes les routes actuelles | [routes/web.php](routes/web.php) |
| Routes API (non chargées — B1) | [routes/api.php](routes/api.php) |
| Chargement des routes / alias de middleware | [bootstrap/app.php](bootstrap/app.php) |
| Guard et provider d'auth | [config/auth.php](config/auth.php) |
| Hash Symfony 3 legacy | [app/Services/PasswordService.php](app/Services/PasswordService.php) |
| Middleware « compte activé » | [app/Http/Middleware/CheckAccountEnabled.php](app/Http/Middleware/CheckAccountEnabled.php) |
| Wizard web à reproduire (4 étapes) | [resources/views/userdata/create.blade.php](resources/views/userdata/create.blade.php) |
| Écran de résumé à reproduire | [resources/views/userdata/summary.blade.php](resources/views/userdata/summary.blade.php) |
| Historique des correctifs de sécurité | [AUDIT_CORRECTIONS.md](AUDIT_CORRECTIONS.md) |
