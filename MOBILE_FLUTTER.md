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

Écrans particuliers, traités à part car leur logique n'est pas évidente à la lecture du code : la **photo de profil** (§4.6), l'écran **« Mon CV »** et son bouton *Modifier* (§4.7), le **changement de mot de passe** (§3.6) et la **réinitialisation** (§3.7).

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
| `diplome_file` | text | **2** — JSON `["uploads/diplome/…", …]` (un champ par bloc formation) |
| `cv_file` | text | **4** ⚠️ — JSON `["uploads/cv/…", …]` (pas à l'étape 2) |
| `photo_profil` | varchar(255) | **1** ⚠️ — chemin simple, dès la 1ʳᵉ étape (§4.6) |
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

### 3.6 Changement de mot de passe (utilisateur connecté)

Le backend expose **deux implémentations concurrentes** du même besoin. Il faut savoir laquelle est la référence.

| # | Route | Contrôleur | Nom de route | Redirection après succès |
| :-- | :--- | :--- | :--- | :--- |
| 1 | `GET /change-password` | `PasswordController::edit` | `password.edit` | *(affiche le formulaire)* |
| 2 | `POST /change-password` | `PasswordController::update` | `password.update` ⚠️ | `route('password.edit')` |
| 3 | `POST /auth/change-password` | `AuthController::changePassword` | `change.password` | `route('userdata.summary', $userdata->id)` |

> **C'est la n°3 qui est réellement utilisée** : `change-password.blade.php` poste vers `route('change.password')`. La n°2 est du code mort — mais son **nom de route casse la réinitialisation de mot de passe** (voir §3.7, bloqueur **B9**).

**Contrat identique pour les deux** (`PasswordController::update` et `AuthController::changePassword`) :

```php
'current_password' => 'required|string',
'new_password'     => 'required|string|min:8|confirmed',
```

Champs à envoyer — **noms exacts** :

| Champ | Obligatoire | Règle |
| :--- | :--- | :--- |
| `current_password` | oui | doit correspondre au mot de passe actuel |
| `new_password` | oui | min. 8 caractères |
| `new_password_confirmation` | oui | imposé par la règle `confirmed` sur `new_password` |

Erreur en cas de mauvais mot de passe actuel — clé `current_password`, message serveur déjà en français :

```json
{ "message": "…", "errors": { "current_password": ["Le mot de passe actuel est incorrect."] } }
```

Trois points à connaître côté mobile :

1. **⚠️ Les comptes legacy Symfony ne peuvent pas changer leur mot de passe.** `changePassword()` n'utilise que `Hash::check($current, $user->password)`. Un compte dont `salt` est non-null (jamais reconnecté depuis la migration) verra **toujours** « Le mot de passe actuel est incorrect. » ⇒ **l'endpoint API doit réutiliser la double vérification bcrypt / Symfony3 du login** (§3.3), exactement comme `AuthController::login`.

2. **Aucune invalidation de session ni de token.** Le mot de passe est réécrit, rien d'autre. Pour l'API, décider : révoquer les **autres** tokens Sanctum (`$user->tokens()->where('id','!=',$current)->delete()`) et conserver celui de l'appareil courant. C'est le comportement attendu par les utilisateurs et ça limite le risque en cas de compte compromis.

3. **Aucune contrainte de robustesse** au-delà de `min:8` : pas de vérification de complexité, pas de refus des mots de passe compromis. Si le mobile veut un indicateur de robustesse, c'est une décision purement côté app (ou faire ajouter `Password::defaults()` côté serveur).

> Bug secondaire : si l'utilisateur n'a pas encore de dossier, `AuthController::changePassword` redirige vers `route('userdata.summary', 'default')` ⇒ `/userdata/summary/default` ⇒ `findOrFail` échoue ⇒ **404**. Sans conséquence pour le mobile (qui ne suit pas les redirections), mais à corriger.

### 3.7 Mot de passe oublié — réinitialisation

Parcours web actuel, en trois temps :

| Étape | Route | Détail |
| :--- | :--- | :--- |
| 1. Demande du lien | `POST /forgot-password` (`password.email`) | `email` : `required`\|`email`\|`exists:utilisateur,email` → `Password::sendResetLink()` |
| 2. Ouverture du lien | `GET /reset-password/{token}` (`password.reset`) | affiche le formulaire |
| 3. Nouveau mot de passe | `POST /reset-password` (`password.update`) | `token`, `email`, `password`, `password_confirmation` (`min:8`\|`confirmed`) |

Paramètres du broker (`config/auth.php`) : **expiration 15 minutes**, **throttle 60 secondes** entre deux demandes. Deux brokers existent (`users` et `utilisateur`), tous deux adossés au provider `users` → strictement équivalents.

> ⛔ **Bloqueur B9 — la réinitialisation est cassée aujourd'hui.** Le nom `password.update` est déclaré **deux fois** dans [routes/web.php](routes/web.php) : d'abord sur `POST /reset-password` (groupe `guest`), puis sur `POST /change-password` (groupe `auth`). Le second écrase le premier dans le registre des noms. Or `reset-password.blade.php` (ligne 23) utilise `action="{{ route('password.update') }}"` ⇒ le formulaire poste vers **`/change-password`**, route protégée par `auth` ⇒ l'invité est redirigé vers `/login` et **le mot de passe n'est jamais réinitialisé**. À corriger avant d'exposer ce parcours au mobile.

Il existe par ailleurs une variante « chatbot » plus adaptée au mobile, qui exige **email + `numberid`** (CNI/passeport) avant d'envoyer le lien — mais elle est inatteignable (bloqueur **B1**) :

```php
// app/Http/Controllers/Api/ResetPasswordController.php  →  POST /api/chatbot/reset-password
'email'    => 'required|email',
'numberid' => 'required'
```

**Recommandation mobile** : reprendre cette logique à deux facteurs (email **+** `numberid`) et remplacer le lien web par un **code OTP à 6 chiffres**, comme pour la vérification d'email (§3.4). Un lien signé de réinitialisation est difficile à réintégrer proprement dans une app.

---

## 4. Le formulaire de demande — contrat de données exact

Source d'autorité : `UserdataController::store()` et `::update()`. Le wizard web comporte 4 étapes ; l'app doit les reprendre pour permettre l'édition ultérieure champ par champ.

### 4.1 Étape 1 — Identité, résidence **et photo de profil**

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

### 4.2 Étape 2 — Formations (liste dynamique) + diplômes

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

**Les trois champs de fichiers sont validés ensemble dans `store()`/`update()`, mais ils sont saisis à des étapes différentes du wizard.** Emplacement réel dans les vues Blade :

| Champ | Étape réelle | Règle | Destination disque |
| :--- | :--- | :--- | :--- |
| `photo_profil` | **1** | nullable\|image\|mimes:jpeg,png,jpg,gif\|max:2048 | `public/uploads/photos/` |
| `diplome_file[]` | **2** (un champ `multiple` par bloc formation) | nullable\|array + `.*` file\|mimes:**pdf,doc,docx,rtf,txt**\|**max:2048** (2 Mo) | `public/uploads/diplome/` |
| `cv_file[]` | **4** (à côté des vœux et de `cv_summary`) | nullable\|array + `.*` file\|mimes:pdf,doc,docx,rtf,txt\|max:2048 | `public/uploads/cv/` |

Preuves : `photo_profil` est à la ligne 133 de [create.blade.php](resources/views/userdata/create.blade.php), dans `<div id="step-1">` (113→414) ; `diplome_file[]` aux lignes 477 et 560, dans `step-2` ; `cv_file[]` à la ligne 790, dans `step-4` (774→956). Même découpage dans [edit.blade.php](resources/views/userdata/edit.blade.php) (`photo_profil` l. 339 / step-1, `diplome_file[]` l. 736 / step-2, `cv_file[]` l. 1101 / step-4).

> ⚠️ Ne pas placer l'upload du CV à l'étape 2 dans l'app : côté web c'est **l'étape 4**. Le regrouper ailleurs romprait la correspondance avec le parcours web et l'écran d'édition.
>
> Les diplômes sont attachés **par bloc de formation** côté UI, mais le serveur les **aplatit en une seule liste** : `foreach ($request->file('diplome_file') as $file)` → un unique tableau JSON dans `diplome_file`. **Le lien entre un diplôme et la formation correspondante est perdu.** Ne pas promettre cette association dans l'app.
>
> Pas de PNG/JPG accepté pour un diplôme : **une photo de diplôme prise au téléphone sera refusée.** L'app doit soit convertir en PDF, soit demander l'ajout de `jpg,png` à la whitelist (§6.2).
>
> Nommage serveur : `time() . '_' . nom_original`. Non assaini, collisions possibles. L'URL de retour doit être encodée.
>
> Côté web, l'input `cv_file` n'a **pas** l'attribut `multiple` (un seul CV), alors que la validation accepte un tableau. Le backend gère donc plusieurs CV : l'app peut en proposer plusieurs sans changement serveur.

Suppression de fichiers en édition : champs texte `deleted_files` et `deleted_cv_files`, **chemins séparés par `;`**.

### 4.3 Étape 3 — Expériences professionnelles

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

### 4.4 Étape 4 — Vœux d'emploi **et CV**

| Champ | Règle `store()` | Règle `update()` |
| :--- | :--- | :--- |
| `emploi1_id` | **required**\|exists:emploi,id | nullable\|exists:emploi,id |
| `emploi2_id` | **required**\|exists:emploi,id | nullable\|exists:emploi,id |
| `anneeexperience1` | nullable\|integer | idem |
| `anneeexperience2` | nullable\|integer | idem |
| `cv_summary` | nullable\|string\|**max:1000** | idem |
| `cv_file[]` | nullable\|array — **le CV se dépose ici**, pas à l'étape 2 (§4.2) | idem |

> Les deux vœux sont **obligatoires** à la création. Rien n'empêche `emploi1_id == emploi2_id` : à contrôler côté app (UX) et idéalement côté serveur (`different:emploi1_id`).
>
> Le choix se fait en cascade : **secteur → emploi**. `secteur_id` n'est pas stocké dans `userdata`, il ne sert qu'au filtrage de la liste. L'app doit donc, pour réafficher un vœu existant, remonter `emploi.secteur_id` pour présélectionner le secteur.

### 4.5 Récapitulatif des champs obligatoires à la création

```
datenaiss, lieunaiss, lieuresidence, genre, telephone1, emploi1_id, emploi2_id
```

Tout le reste est optionnel côté serveur — même si le formulaire web marque davantage de champs `required` en HTML. L'app peut donc enregistrer un brouillon serveur dès l'étape 4 franchie.

### 4.6 La photo de profil — cycle de vie complet

**Réponse directe à la question : la photo appartient à la demande, pas au compte.** Elle est stockée dans `userdata.photo_profil`, pas dans `utilisateur`. Il n'existe **aucun écran « profil »** séparé dans ce backend : le « profil » du candidat *est* son dossier de demande. Conséquence pour Flutter : tant qu'un candidat n'a pas créé sa demande, il **ne peut pas avoir de photo**.

Elle est donc à la fois un champ du formulaire (étape 1) **et** une ressource modifiable isolément depuis l'écran résumé. Trois points d'entrée coexistent :

| | Contexte | Endpoint | Transport | Remarques |
| :-- | :--- | :--- | :--- | :--- |
| **A** | Wizard de création, **étape 1** | `POST /userdata` (`userdata.store`) | multipart, **avec tout le formulaire** | champ `photo_profil`, optionnel |
| **B** | Formulaire d'édition, **étape 1** | `PUT /userdata/{id}` (`userdata.update`) | multipart, avec tout le formulaire | aperçu local via `previewImage(event)` |
| **C** | **Écran résumé**, bouton autonome | `updatePhotoProfil` | multipart **AJAX, photo seule** | ⛔ route cassée, voir plus bas |

**Comportement serveur en édition (B)** — correctif BUG-05, important à ne pas casser :

```php
if ($request->hasFile('photo_profil')) {
    // supprime l'ancien fichier du disque, puis enregistre le nouveau
    @unlink(public_path($userdata->photo_profil));
    $validated['photo_profil'] = 'uploads/photos/' . $filename;
} else {
    unset($validated['photo_profil']);   // ⇒ l'ancienne photo est CONSERVÉE
}
```

⇒ Ne **jamais** envoyer `photo_profil` vide ou `null` lors d'une mise à jour : l'omettre suffit à la conserver. (C'est la seule exception à la règle « toujours renvoyer tout le dossier » du §4.3.)

#### Le flux C en détail — c'est celui que Flutter doit reproduire

Extrait de [summary.blade.php](resources/views/userdata/summary.blade.php) (l. 332-400) :

1. Affichage : `<img id="user-photo" src="{{ asset($userdata->photo_profil ?: 'images/images.png') }}">`
   → placeholder par défaut **`public/images/images.png`** (présent, 2 Ko).
2. Clic sur « **Modifier la photo** » → déclenche l'input file caché.
3. `change` sur l'input → **soumission automatique** (pas de second clic de confirmation).
4. `POST` AJAX multipart vers `route('updatePhotoProfil', ['id' => $userdata->id])`, bouton passé en « Chargement… » et désactivé.
5. Succès → `img.src = response.photo_profil + '?t=' + Date.now()` (**cache-buster obligatoire**, l'URL peut être identique) + SweetAlert de confirmation.
6. Erreur → SweetAlert avec `xhr.responseJSON.message`.

**Contrat de l'endpoint dédié** (`UserdataController::updatePhotoProfil`) :

```php
'photo_profil' => 'required|image|max:2048',   // ⚠️ required, et AUCUNE liste mimes
```

| Cas | Réponse |
| :--- | :--- |
| Succès | `200` `{"success": true, "photo_profil": "http://…/uploads/photos/1775151117_x.jpeg"}` — **URL absolue** via `asset()` |
| Pas propriétaire (ni admin) | `403` `{"success": false, "message": "Non autorisé."}` |
| Aucun fichier reçu | `400` `{"success": false}` |
| Validation | `422` standard Laravel |

> Noter la divergence de validation : l'endpoint dédié accepte **toute image** (`image` seul), alors que le formulaire complet restreint à `jpeg,png,jpg,gif`. Un WebP passera par le flux C mais sera refusé par le flux A/B. À harmoniser côté API.

#### ⛔ Ce flux est cassé aujourd'hui (bloqueur B5, mécanisme précis)

Les deux routes déclarées n'ont **pas** de paramètre `{id}` :

```php
Route::post('/update-photo',        [UserdataController::class, 'updatePhotoProfil'])->name('updatePhotoProfil');
Route::post('/updatephoto-profil', [UserdataController::class, 'updatePhotoProfil'])->name('update.photo');
```

alors que la signature est `updatePhotoProfil(Request $request, $id)`. Donc :

- `route('updatePhotoProfil', ['id' => 1369020])` génère **`/update-photo?id=1369020`** — l'`id` part en **query string**, pas en paramètre de route ;
- à l'appel, Laravel n'a aucun paramètre de route à injecter dans `$id` ⇒ **`ArgumentCountError: Too few arguments`** ⇒ **500**.

Le bouton « Modifier la photo » de l'écran résumé est donc **non fonctionnel en l'état**, sur le web comme pour toute app qui appellerait cette URL. Correctif : `Route::post('/update-photo/{id}', …)`, ou — préférable pour l'API — déduire le dossier de l'utilisateur authentifié et supprimer le paramètre (§7.5).

#### Ce que Flutter doit gérer

| Sujet | Règle |
| :--- | :--- |
| Source | `photo_profil` du dossier ; si `null` → **avatar local** (initiales ou asset embarqué), ne pas dépendre de `images/images.png` côté serveur |
| Deux préfixes historiques | `uploads/photos/…` **et** `storage/uploads/…` (une ligne legacy en base). Si l'API ne renvoie pas d'URL absolue, préfixer en tenant compte des deux |
| Encodage | `Uri.encodeFull()` — les noms contiennent espaces et accents (`1775151117_WhatsApp Image 2026-03-10 at 07.54.53.jpeg`) |
| Cache | `CachedNetworkImage` + **invalider le cache après upload** (`evict()` ou suffixe `?t=timestamp`), sinon l'ancienne photo reste affichée |
| Capture | `image_picker` : appareil photo **et** galerie. Le web utilise `capture="environment"` (caméra arrière) — pour un portrait, préférer la caméra **avant** par défaut |
| Poids | **2 Mo max.** Une photo de smartphone fait 3-8 Mo ⇒ compression **obligatoire** avec `flutter_image_compress` avant l'envoi, sinon `422` systématique |
| Recadrage | Le backend ne recadre ni redimensionne rien. Prévoir un recadrage carré côté app (`image_cropper`) : l'affichage web est en `object-fit: cover` 150-200 px |
| Formats | Se limiter à **jpg / png** : c'est l'intersection des deux validations serveur |
| UX | Reproduire l'upload immédiat à la sélection (pas de bouton « valider »), avec indicateur de progression `onSendProgress` de Dio |
| Ordre des opérations | Tant que la demande n'existe pas, il n'y a pas d'`id` de dossier : **la photo doit partir avec le `POST /demande` initial** (flux A), pas avant |

### 4.7 L'écran « Mon CV » — le résumé du dossier

C'est l'écran d'atterrissage après connexion et après chaque enregistrement. Source : `UserdataController::summary()` + [summary.blade.php](resources/views/userdata/summary.blade.php).

```php
GET /userdata/summary/{id}        → name: userdata.summary   (middleware: auth)
```

Trois comportements du contrôleur à retenir :

1. **Contrôle d'accès** : propriétaire **ou** admin, sinon `abort(403)` (correctif SEC-02).
2. **La date est reformatée côté serveur** : `$userdata->datenaiss = Carbon::parse(...)->format('d/m/Y')`. L'affichage est donc déjà en **`jj/mm/aaaa`** — l'API devra, elle, renvoyer de l'ISO (`YYYY-MM-DD`) et laisser le formatage à l'app.
3. `{id}` est l'**id du dossier** (`userdata.id`), pas celui de l'utilisateur.

#### Structure exacte à reproduire

```
┌──────────────────────────────────────────────────────────┐
│ EN-TÊTE INSTITUTIONNEL                                   │
│  drapeau + « République du Sénégal »                     │
│             « Un Peuple - Un But - Une Foi »             │
│  « PLATEFORME DE GESTION DES DEMANDES D'EMPLOI »         │
├──────────────────────────────────────────────────────────┤
│ [ N° INSCRIPTION : 332099 ]      [ Bonjour Prénom Nom ▾ ]│
│                                    ├ Modifier le mot…    │
│                                    └ Déconnexion         │
├──────────────────────────────────────────────────────────┤
│   ╭────────╮                                             │
│   │ PHOTO  │   « Modifier la photo »   (§4.6)            │
│   ╰────────╯                                             │
│                                                          │
│   [ 👤 Mettre à jour mes infos ]  ← LE BOUTON MODIFIER   │
├──────────────────────────────────────────────────────────┤
│ Informations personnelles      (4 lignes seulement)      │
│   Date de naissance : …                                  │
│   Email : …                                              │
│   Téléphone : …                                          │
│   Lieu de résidence : …                                  │
├──────────────────────────────────────────────────────────┤
│ Formation                      (1 carte par formation)   │
├──────────────────────────────────────────────────────────┤
│ Expérience professionnelle     (1 carte par expérience)  │
├──────────────────────────────────────────────────────────┤
│ Emploi                         (résumé CV + 2 vœux)      │
└──────────────────────────────────────────────────────────┘
```

**En-tête** — `N° INSCRIPTION` = `$userdata->utilisateur->id`, soit l'**id du compte utilisateur**, pas celui du dossier. C'est le numéro que le candidat communique à l'administration : à afficher en évidence dans l'app, et à rendre copiable.

**Section « Informations personnelles »** — quatre lignes, et c'est tout :

| Libellé | Donnée |
| :--- | :--- |
| Date de naissance : | `datenaiss` (déjà en `jj/mm/aaaa`) |
| Email: | `utilisateur.email` ← vient du **compte**, pas du dossier |
| Téléphone: | `telephone1` |
| Lieu de résidence : | `lieuresidence` |

**Section « Formation »** — une carte par entrée de `autresdiplomes` (décodé dans la vue) :

- **titre** = libellé du niveau, résolu via `Academic::pluck('libelle','id')`. Si `academic_id` vaut `'sansdiplome'` **ou** `'20'` → affiche littéralement « **Sans diplôme** » *(la vue gère donc la valeur 20 fautive du bloqueur B4 — l'app ne doit pas reproduire ce contournement, elle doit envoyer 14)* ;
- + `« à {etablissementdiplome} »` en plus petit, si présent ;
- ligne grise : `anneediplome` ;
- ligne : `Intitulé du diplôme : {diplome}` ;
- ligne : `Spécialité : {specialite}` ;
- **repli** si `autresdiplomes` est vide mais `academic_id`/`diplome` présents → une carte construite depuis les colonnes plates ;
- **état vide** : « Aucune formation renseignée ».

**Section « Expérience professionnelle »** — une carte par entrée de `experiences` :

- **titre** = `poste` (repli `posteoccupe`, puis « Poste non renseigné ») + `« à {employeur} »` ;
- `{years} année` / `{years} années` **d'expérience** (pluriel si `> 1`) ;
- `description` en texte courant ;
- **repli** sur `posteoccupe`/`employeur`/`nombreanneeexpe` ;
- **état vide** : « Pas d'expérience ».

**Section « Emploi »** — une seule carte :

- `Résumé du CV :` → `cv_summary` ;
- `Premier secteur choisi:` → `emploi1.secteur.libelle` · `Emploi concerné:` → `emploi1.libelle` ;
- `Deuxième secteur choisi:` → `emploi2.secteur.libelle` · `Emploi concerné:` → `emploi2.libelle`.

> ⛔ **Bloqueur B10** : ces quatre accès sont écrits **sans protection null** (`{{ $userdata->emploi1->secteur->libelle }}`). Comme `update()` déclare `emploi1_id`/`emploi2_id` en `nullable`, un dossier sans vœu rend l'écran résumé **définitivement inaccessible** (`Attempt to read property "secteur" on null` ⇒ **500**), y compris pour son propriétaire. L'API doit renvoyer `null` proprement et l'app afficher « Non renseigné ».

#### ⚠️ Ce que le résumé n'affiche PAS

Bien que présents en base, ces champs sont **absents** de l'écran : `genre`, `situationmatrimoniale`, `nombreenfant`, `lieunaiss`, `addresse`, `country_id`, les quatre couples région/département, `handicap_id`, `anneeexperience1`, `anneeexperience2`, et — surtout — **les fichiers CV et diplômes** (ils ne sont visibles et gérables que dans le formulaire d'édition).

**Décision de conception pour l'app** : le résumé web est volontairement minimal, mais sur mobile c'est le seul écran de consultation. **Recommandation : l'enrichir** — ajouter un bloc « État civil » (genre, situation, enfants, lieu de naissance, résidence complète, handicap) et un bloc « Mes documents » listant CV, diplômes et photo avec téléchargement. `GET /demande` (§7.6) renvoie déjà tout le nécessaire.

#### Le bouton « Modifier »

```html
<a href="{{ route('userdata.edit', ['id' => $userdata->id]) }}" class="btn btn-success">
  <i class="fas fa-user-edit"></i> Mettre à jour mes infos
</a>
```

Un **unique** bouton, qui ouvre le wizard d'édition complet (4 étapes, `edit.blade.php`, 2289 lignes) à l'étape 1. Il n'y a **aucune édition par section**.

Pour l'app, c'est le point où il faut faire mieux que le web : mettre un bouton **« Modifier » sur chaque section**, qui ouvre le wizard **directement à l'étape correspondante** (§8.7 donne le mapping champ → étape). Le formulaire est long ; faire retraverser les quatre étapes pour corriger un numéro de téléphone est le principal point de friction du parcours actuel.

Trois précautions :

- l'édition doit **repartir du dossier serveur** (`GET /demande`), pas d'un cache d'affichage ;
- à la sauvegarde, **renvoyer la totalité** formations + expériences + `hasExperience` (§4.3), sinon des données sont effacées ;
- **omettre** `photo_profil` s'il n'y a pas de nouvelle photo (§4.6).

#### La variante imprimable : `resume.blade.php`

```php
GET /userdata/{id}/resume        → name: resume   (middleware: auth)
```

Même mise en page (mêmes quatre sections), mais en version **CV imprimable** : en-tête et pied de page marqués `d-print-none`, ni bouton d'édition ni photo modifiable.

> ⚠️ Piège : ici `{id}` est l'**id de l'utilisateur**, pas celui du dossier — `Utilisateur::with('userdata')->findOrFail($id)`. Les deux routes `userdata.summary` et `resume` attendent donc **deux identifiants différents** malgré des URLs voisines.

Si l'app doit proposer un export PDF, deux options : générer le PDF côté Flutter (paquet `pdf`, maîtrise totale de la mise en page) ou faire produire un `GET /demande/cv.pdf` côté serveur depuis cette vue. La seconde garantit que le CV mobile est **identique** au document que voit l'administration — c'est l'option recommandée.

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
| **B5** | **Le bouton « Modifier la photo » du résumé est cassé** | Les routes `/update-photo` et `/updatephoto-profil` n'ont pas de `{id}`, mais `updatePhotoProfil(Request $request, $id)` l'exige. `route('updatePhotoProfil', ['id'=>…])` produit `/update-photo?id=…` (query string) ⇒ **`ArgumentCountError`** ⇒ 500. Détail : §4.6 | `Route::post('/update-photo/{id}', …)`, ou déduire le dossier de l'utilisateur authentifié et retirer le paramètre |
| **B6** | `/check-email` interroge la mauvaise table | `User::where('email', …)` → table `users`, alors que les candidats sont dans `utilisateur` | Utiliser `Utilisateur::where('email_canonical', strtolower(trim($email)))` |
| **B7** | `POST /api/chatbot/reset-password` inatteignable | conséquence de B1 | résolu par B1 |
| **B8** | `APP_URL=localhost` | `.env` | URL absolue avec schéma — sinon liens signés et `asset()` cassés |
| **B9** | **La réinitialisation de mot de passe est cassée** | Le nom `password.update` est déclaré 2× : `POST /reset-password` (groupe `guest`) puis `POST /change-password` (groupe `auth`). Le second gagne ⇒ `reset-password.blade.php` l. 23 poste vers `/change-password`, protégée par `auth` ⇒ redirection vers `/login`, mot de passe jamais réinitialisé. Détail : §3.7 | Renommer la route de changement en `password.change` (ou supprimer `PasswordController::update`, code mort — la vue utilise `change.password`) |
| **B10** | **L'écran résumé plante si un vœu est vide** | `{{ $userdata->emploi1->secteur->libelle }}` sans protection null, alors que `update()` déclare `emploi1_id`/`emploi2_id` en `nullable` ⇒ `Attempt to read property on null` ⇒ **500**, dossier inaccessible à son propriétaire. Détail : §4.7 | Opérateur `?->` + valeur de repli dans la vue ; côté API, renvoyer `null` et laisser l'app afficher « Non renseigné » |
| **B11** | Changement de mot de passe impossible pour les comptes legacy | `AuthController::changePassword` n'utilise que `Hash::check()` ; un compte avec `salt` non-null échouera toujours sur `current_password`. Détail : §3.6 | Réutiliser la double vérification bcrypt / Symfony3 du login |

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
| **D12** | Le résumé n'affiche que 4 champs personnels et **aucun fichier** (§4.7) | Sur mobile c'est le seul écran de consultation | Enrichir : bloc « État civil » + bloc « Mes documents » (CV, diplômes, photo) avec téléchargement |
| **D13** | Édition uniquement globale (un seul bouton « Mettre à jour mes infos ») | Retraverser 4 étapes pour corriger un téléphone = principal point de friction | Exposer `PATCH /demande/step/{1..4}` et ouvrir le wizard à l'étape voulue |
| **D14** | Validation photo divergente : `image` seul sur l'endpoint dédié, `mimes:jpeg,png,jpg,gif` dans le formulaire | Un WebP passe par un chemin et échoue sur l'autre | Harmoniser sur une seule liste de mimes |
| **D15** | Pas de révocation de token au changement de mot de passe | Un appareil volé reste connecté après le changement | Révoquer les autres tokens Sanctum, conserver celui de l'appareil courant (§3.6) |
| **D16** | Deux routes attendent des ids différents : `userdata.summary` ← id du **dossier**, `resume` ← id de l'**utilisateur** | Source de bugs d'intégration | Sur l'API, aucun id dans l'URL (§7.5) |
| **D17** | Déconnexion web non fonctionnelle : le `<form id="logout-form">` du résumé poste vers `route('login')` au lieu de `route('logout')` | Sans effet pour le mobile (logout local + `POST /auth/logout`), mais à signaler | Corriger l'action du formulaire |

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

**`POST /auth/password/change`** — conserver **exactement** les noms de champs du web, pour que les messages d'erreur serveur restent réutilisables et que la logique soit partagée avec `AuthController::changePassword` :

```json
{ "current_password": "…", "new_password": "…", "new_password_confirmation": "…" }
```

Réponse `200` : `{"message": "Votre mot de passe a été mis à jour avec succès."}`, et — si **D15** est retenu — `{"token": "<nouveau token>"}` après révocation des autres tokens, que l'app doit alors substituer dans le stockage sécurisé.
Réponse `422` : erreur sous la clé `current_password` (« Le mot de passe actuel est incorrect. ») ou `new_password`.

> Cet endpoint doit lui aussi appliquer la double vérification bcrypt / Symfony3 sur `current_password`, sinon les comptes legacy ne pourront jamais changer de mot de passe (bloqueur **B11**, §3.6).

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
| POST | `/demande/photo` | `multipart` — champ `photo_profil` (remplace §4.6 **C**, cassé) |
| DELETE | `/demande/photo` | Retirer la photo — *à créer, aucun équivalent web* |
| POST | `/demande/files` | `multipart` — `diplome_file[]` et/ou `cv_file[]` |
| DELETE | `/demande/files` | `{"type":"cv"\|"diplome","path":"uploads/cv/…"}` |
| GET | `/demande/cv.pdf` | *(recommandé)* CV imprimable, rendu depuis `resume.blade.php` (§4.7) |

> Aucun `{id}` dans l'URL : le dossier est déduit de l'utilisateur authentifié. Cela **supprime par construction la classe de failles IDOR** corrigée manuellement dans le contrôleur web (SEC-02), et évite la confusion entre id de dossier et id d'utilisateur (**D16**).

**`POST /demande/photo`** — conserver la forme de réponse déjà consommée par le web, en y ajoutant le chemin relatif :

```json
{
  "success": true,
  "photo_profil": "http://…/uploads/photos/1775151117_x.jpeg",
  "path": "uploads/photos/1775151117_x.jpeg"
}
```

L'ancien fichier est supprimé du disque par le serveur. Côté app : invalider le cache image après réception (§4.6).

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
  image_cropper: ^8.0.2             # recadrage carré de la photo — §4.6
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
│   │   └── ui/     (login, register, verify_email, forgot_password,
│   │                change_password)                     # §3.6 / §8.12
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
│           ├── cv_page.dart        # écran « Mon CV » — §4.7 / §8.11
│           ├── files_page.dart     # CV + diplômes (§4.2, §4.4)
│           └── profile_photo.dart  # avatar + upload isolé — §4.6 / §8.10
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
  'photo_profil': 1,                    // étape 1, cf. §4.6

  'formations': 2, 'diplome_file': 2,   // les diplômes sont à l'étape 2

  'hasExperience': 3, 'experiences': 3,

  'emploi1_id': 4, 'emploi2_id': 4,
  'anneeexperience1': 4, 'anneeexperience2': 4, 'cv_summary': 4,
  'cv_file': 4,                         // le CV est à l'étape 4, PAS à l'étape 2
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
| CV / diplômes | Jamais affichés dans le résumé web (§4.7) — les exposer dans un écran « Mes documents » (**D12**) |

### 8.10 Photo de profil — implémentation

Contrat métier complet en §4.6. Côté Flutter, la chaîne à respecter est **sélection → recadrage → compression → contrôle de taille → upload → invalidation du cache**.

```dart
Future<void> changerPhoto(ImageSource source) async {
  final picked = await ImagePicker().pickImage(
    source: source,
    preferredCameraDevice: CameraDevice.front,  // portrait
  );
  if (picked == null) return;

  // 1) Recadrage carré — le serveur ne redimensionne rien
  final cropped = await ImageCropper().cropImage(
    sourcePath: picked.path,
    aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
  );
  if (cropped == null) return;

  // 2) Compression : limite serveur = 2048 Ko (max:2048)
  final bytes = await FlutterImageCompress.compressWithFile(
    cropped.path, minWidth: 800, minHeight: 800, quality: 85, format: CompressFormat.jpeg,
  );
  if (bytes == null) return;

  // 3) Garde-fou explicite plutôt qu'un 422 opaque
  if (bytes.length > 2 * 1024 * 1024) {
    throw const AppException('Image trop lourde après compression, réessayez.');
  }

  // 4) Upload isolé — la demande doit déjà exister
  final form = FormData.fromMap({
    'photo_profil': MultipartFile.fromBytes(bytes, filename: 'photo.jpg'),
  });
  final res = await dio.post('/demande/photo', data: form,
      onSendProgress: (sent, total) => _progress.value = sent / total);

  // 5) Invalider le cache, sinon l'ancienne image reste affichée
  final url = res.data['photo_profil'] as String;
  await CachedNetworkImage.evictFromCache(url);
  _photoUrl.value = url;
}
```

Points de vigilance :

- **Tant que la demande n'existe pas, il n'y a pas de dossier à photographier.** Au premier enregistrement, la photo part dans le `POST /demande` (§4.6 flux A) ; l'upload isolé n'est disponible qu'ensuite.
- **Ne jamais envoyer `photo_profil: null`** dans un `PUT /demande` : l'omettre conserve l'existante, l'envoyer vide risque de l'effacer.
- L'avatar par défaut doit être un **asset local** (initiales du candidat), pas `images/images.png` côté serveur.
- Afficher l'état d'upload sur le bouton lui-même (« Chargement… », désactivé), comme le web.

### 8.11 Écran « Mon CV » — implémentation

Structure et contenu exact en §4.7. Recommandations d'implémentation :

| Sujet | Règle |
| :--- | :--- |
| Source | **toujours** `GET /demande`, jamais un cache d'affichage — c'est l'écran de vérité du candidat |
| N° d'inscription | `utilisateur.id`, affiché en évidence et **copiable** (`Clipboard.setData`) — c'est la référence administrative |
| État « pas de dossier » | `GET /demande` → `404` ⇒ écran d'accueil « Créer ma demande », pas une erreur |
| Vœux vides | Afficher « Non renseigné » ; ne jamais supposer `emploi1 != null` (**B10**) |
| Formations / expériences | Une carte par entrée ; respecter les états vides du web (« Aucune formation renseignée », « Pas d'expérience ») |
| Pluriel | `{years} année` / `{years} années` — la règle du web (`> 1`) |
| Dates | L'API renvoie `YYYY-MM-DD` ; afficher en `dd/MM/yyyy` (le web le fait côté serveur) |
| Boutons « Modifier » | Un **par section**, ouvrant le wizard à l'étape correspondante (**D13**, mapping §8.7) — c'est le principal gain d'UX sur le web |
| Documents | Section « Mes documents » (**D12**) : photo, CV, diplômes, avec téléchargement via `open_filex` |
| Export | `GET /demande/cv.pdf` si le backend le fournit, pour garantir un CV identique à celui de l'administration ; sinon génération locale avec le paquet `pdf` |
| Rafraîchissement | `RefreshIndicator` — le dossier peut être modifié par un admin (champ `recruted`, notamment) |

### 8.12 Écran de changement de mot de passe

Contrat en §3.6.

```dart
await dio.post('/auth/password/change', data: {
  'current_password': current,
  'new_password': next,
  'new_password_confirmation': confirm,   // nom imposé par la règle `confirmed`
});
```

| Sujet | Règle |
| :--- | :--- |
| Champs | Les trois, avec **les noms exacts ci-dessus** |
| Validation locale | `new_password.length >= 8` et `new_password == confirmation`, avant l'appel |
| Erreur « mot de passe actuel » | Arrive sous la clé `errors.current_password` — l'afficher **sous ce champ**, pas en bannière globale |
| Après succès | Si l'API renvoie un nouveau token (**D15**), le **remplacer** dans le stockage sécurisé, sinon la session mobile tombera en `401` |
| Comptes legacy | Si le backend n'a pas corrigé **B11**, un compte migré recevra « Le mot de passe actuel est incorrect. » alors que son mot de passe est bon — prévoir un message d'aide renvoyant vers « mot de passe oublié » |
| Emplacement | Le web le place dans le menu « Bonjour {prénom} » du résumé ; sur mobile, un écran « Mon compte » (mot de passe, email, n° d'inscription, déconnexion) est plus lisible |

---

## 9. Ordre des travaux recommandé

### Backend (prérequis)

1. **B1** charger `routes/api.php` · **B2** installer Sanctum + `HasApiTokens` · **B8** corriger `APP_URL`.
2. **B3** `ALTER TABLE userdata MODIFY autresdiplomes JSON NULL;` — *sans quoi les formations multiples sont impossibles.*
3. **B4** corriger `20` → `14` pour « sans diplôme » · **B9** lever la collision de nom `password.update` · **B10** protéger les vœux nuls dans le résumé · **B5** réparer la route de photo.
4. Endpoints d'auth (§7.2) en **réutilisant la double vérification bcrypt/Symfony3** — login **et** changement de mot de passe (**B11**).
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
5. Upload de fichiers (diplômes à l'étape 2, CV à l'étape 4) + photo de profil (§8.10).
6. Écran « Mon CV » (§8.11) avec boutons « Modifier » par section, puis écran « Mon compte » + changement de mot de passe (§8.12).
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
| Inscription / connexion / **changement de mdp réellement utilisé** | [app/Http/Controllers/AuthController.php](app/Http/Controllers/AuthController.php) |
| Changement de mdp — variante morte (cause de **B9**) | [app/Http/Controllers/PasswordController.php](app/Http/Controllers/PasswordController.php) |
| Formulaire de changement de mdp (noms de champs) | [resources/views/auth/change-password.blade.php](resources/views/auth/change-password.blade.php) |
| Réinitialisation « chatbot » (email + numberid) | [app/Http/Controllers/Api/ResetPasswordController.php](app/Http/Controllers/Api/ResetPasswordController.php) |
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
| **Écran « Mon CV » + photo à reproduire (§4.6, §4.7)** | [resources/views/userdata/summary.blade.php](resources/views/userdata/summary.blade.php) |
| Wizard d'édition (4 étapes) ouvert par « Mettre à jour mes infos » | [resources/views/userdata/edit.blade.php](resources/views/userdata/edit.blade.php) |
| CV imprimable — `{id}` = id **utilisateur** (§4.7) | [resources/views/userdata/resume.blade.php](resources/views/userdata/resume.blade.php) |
| Historique des correctifs de sécurité | [AUDIT_CORRECTIONS.md](AUDIT_CORRECTIONS.md) |
