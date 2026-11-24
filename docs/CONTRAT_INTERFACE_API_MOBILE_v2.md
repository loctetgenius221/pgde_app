# Contrat d’interface et API mobile PGDE

> **Version de l’API :** `v1`
> **Version du contrat :** 2 — 20 novembre 2026 (remplace la version du 5 octobre 2026)
> **Public visé :** développeurs de l’application mobile et intégrateurs du chatbot
> **Source de vérité :** routes et contrôleurs Laravel du dépôt. Les réponses d’exemple illustrent le format ; les libellés et données métier peuvent varier.
> **Application :** les changements de cette version s’appliquent à partir de la prochaine mise en production du serveur.

Ce document décrit les routes réellement disponibles et les règles que l’application mobile doit respecter. Les fonctions d’administration du site web ne constituent pas des routes de l’API mobile.

## 0. Ce qui change depuis la version du 5 octobre 2026

| Sujet | Avant | Maintenant | À faire côté application |
|---|---|---|---|
| **Envoi de CV** | `POST /candidat/files/cv` enregistrait un CV | **Fonctionnalité fermée** : réponse `410` avec `success: false` | Retirer l’écran ou le bouton d’envoi de CV. |
| **Lien des CV existants** | `file_url` pointait vers un fichier public | `file_url` pointe vers une route protégée qui exige le jeton Bearer | Télécharger le CV avec l’en-tête `Authorization`, comme pour les diplômes (§ 6.3). |
| **Durée de vie du jeton** | Illimitée | **30 jours** après la connexion | Sur une réponse `401`, effacer le jeton local et renvoyer vers l’écran de connexion (§ 1). |
| **Changement de mot de passe** | Sans effet sur l’application | **Tous les jetons du compte sont révoqués** (changement sur le site, mot de passe oublié, chatbot…) | Même traitement : `401` → reconnexion. |
| **Comptes administrateurs** | Pouvaient se connecter à l’application | Refusés : `403` avec `code: admin_not_allowed` | Afficher le message renvoyé. L’application est réservée aux candidats. |
| **Photo de profil** | Nom et extension du fichier conservés | Nom aléatoire, extension déduite du contenu réel ; un fichier qui n’est pas une image est refusé (`422`) | Aucun changement d’appel. Ne pas déduire quoi que ce soit du nom du fichier renvoyé. |
| **Messages de doublon à l’inscription** | Messages génériques | Messages précis par champ (§ 3.1) | Afficher `errors` sous le champ concerné. |

Les autres routes (référentiels, profil, formations, expériences, emplois ciblés, diplômes, chatbot) sont inchangées.

## 1. Environnements et conventions

### URL de base

Toutes les routes mobiles sont préfixées par `/api/v1`.

| Environnement | URL de base |
|---|---|
| Développement local | `http://127.0.0.1:8000/api/v1` |
| Production | `<URL de production>/api/v1` — communiquée séparément |

Ne pas utiliser l’URL locale dans l’application publiée.

### En-têtes

Pour les requêtes JSON :

```http
Accept: application/json
Content-Type: application/json
```

Pour les routes protégées :

```http
Authorization: Bearer <token>
```

Pour un envoi de fichier, utiliser `multipart/form-data` et laisser le client HTTP définir lui-même le paramètre `boundary`. Ne pas forcer manuellement l’en-tête `Content-Type`.

### Authentification, activation et durée de vie du jeton

- L’API utilise des jetons personnels Laravel Sanctum transmis en Bearer.
- L’inscription ne crée pas de jeton. Le candidat doit activer son adresse e-mail, puis se connecter.
- Les routes `/candidat/*` et `GET /auth/me` exigent un jeton valide **et** une adresse e-mail vérifiée.
- **Un jeton est valable 30 jours** à partir de la connexion. Il n’existe pas d’endpoint de renouvellement : à l’expiration, le candidat se reconnecte.
- **Un jeton est révoqué** lors de la déconnexion (`POST /auth/logout`) et **dès que le mot de passe du compte change**, quel que soit le canal.
- **Règle à appliquer partout :** toute réponse `401` (`code: unauthenticated`) sur une route protégée signifie que le jeton n’est plus valable. L’application efface le jeton local et affiche l’écran de connexion, sans boucle de nouvelles tentatives.
- Le jeton doit être conservé dans le stockage sécurisé de l’appareil (Keychain / Keystore), jamais en clair.
- L’application est réservée aux **candidats** : les comptes administrateurs sont refusés à la connexion.
- Le chatbot mobile accepte un jeton facultatif. Les routes `/chatbot/pgde/*` sont des routes machine-à-machine et ne doivent pas être appelées depuis l’application mobile.

## 2. Format des réponses et erreurs

Les réponses métier ordinaires suivent généralement cette enveloppe :

```json
{
  "success": true,
  "message": "Opération effectuée avec succès.",
  "data": {}
}
```

Les erreurs de validation des contrôleurs mobiles utilisent le statut `422` :

```json
{
  "success": false,
  "message": "Erreur de validation des données.",
  "errors": {
    "email": ["Cette adresse e-mail est déjà utilisée."]
  }
}
```

La validation de `POST /auth/resend-verification` passe par le mécanisme Laravel standard ; son erreur `422` contient `message` et `errors`, sans `success: false`.

Les exceptions HTTP API utilisent généralement `success`, `code` et `message`, sans champ `errors` :

```json
{
  "success": false,
  "code": "unauthenticated",
  "message": "Une authentification est nécessaire pour accéder à cette ressource."
}
```

Codes rencontrés notamment : `unauthenticated` (`401`), `forbidden` (`403`), `not_found` (`404`), `too_many_requests` (`429`) et `server_error` (`500`). Certains contrôleurs renvoient leurs propres erreurs métier (`email_not_verified`, `access_blocked`, `admin_not_allowed`…) ; le client doit donc traiter le statut HTTP et ne pas supposer qu’un seul format s’applique à toutes les routes.

Le statut `410` signifie qu’une fonctionnalité a été retirée (cas de l’envoi de CV).

## 3. Authentification et compte

### 3.1 Créer un compte

`POST /auth/register` — public, corps JSON, succès `201`.

```json
{
  "firstname": "Awa",
  "lastname": "Diop",
  "username": "awa.diop",
  "numberid": "1234567890123",
  "email": "awa.diop@example.com",
  "password": "MotDePasse123!",
  "password_confirmation": "MotDePasse123!"
}
```

Règles principales :

- nom et prénom obligatoires (255 caractères maximum) ;
- nom d’utilisateur de 3 à 50 caractères : lettres, chiffres, points, tirets ou tirets bas, sans `@` ;
- numéro de CNI ou de passeport : lettres et chiffres uniquement, unique ;
- adresse e-mail valide et unique ;
- mot de passe d’au moins 8 caractères, confirmé. **Recommandation :** imposer aussi, dans l’application, au moins une majuscule et un chiffre, comme sur le site web, pour que les candidats aient les mêmes règles partout.

Messages renvoyés en cas de doublon (dans `errors`, sous le champ concerné) :

| Champ | Message |
|---|---|
| `username` | « Ce nom d’utilisateur est déjà utilisé. » |
| `email` | « Cette adresse e-mail est déjà utilisée. » |
| `numberid` | « Ce numéro de CNI ou de passeport est déjà utilisé. » |

La réponse indique que l’activation par e-mail est requise. **Elle ne contient pas de jeton.**

```json
{
  "success": true,
  "message": "Compte créé. Vérifiez votre adresse e-mail pour l’activer avant de vous connecter.",
  "data": {
    "user": {
      "id": 15,
      "firstname": "Awa",
      "lastname": "Diop",
      "fullname": "Awa Diop",
      "username": "awa.diop",
      "email": "awa.diop@example.com",
      "numberid": "1234567890123",
      "enabled": false,
      "recruted": false,
      "date_inscription": "2026-11-20 10:30:00",
      "last_login": null,
      "has_profile": false,
      "userdata_id": null,
      "photo_profil": "<URL de production>/images/images.png"
    },
    "email_verification_required": true
  }
}
```

### 3.2 Renvoyer le lien d’activation

`POST /auth/resend-verification` — public, corps JSON.

```json
{ "email": "awa.diop@example.com" }
```

La réponse reste générique pour ne pas révéler si un compte existe :

```json
{
  "success": true,
  "message": "Si un compte non activé correspond à cette adresse, un nouveau lien lui a été envoyé."
}
```

### 3.3 Se connecter

`POST /auth/login` — public, corps JSON, succès `200`, nombre de tentatives limité.

`login` accepte le **nom d’utilisateur** ou l’**adresse e-mail**. (La connexion par numéro de CNI existe sur le site web, pas dans l’API.) `device_name` est facultatif et identifie le jeton sur le serveur (exemple : `android-app`).

```json
{
  "login": "awa.diop@example.com",
  "password": "MotDePasse123!",
  "device_name": "android-app"
}
```

Succès :

```json
{
  "success": true,
  "message": "Connexion réussie.",
  "data": {
    "user": {
      "id": 15,
      "firstname": "Awa",
      "lastname": "Diop",
      "fullname": "Awa Diop",
      "username": "awa.diop",
      "email": "awa.diop@example.com",
      "numberid": "1234567890123",
      "enabled": true,
      "recruted": false,
      "date_inscription": "2026-11-20 10:30:00",
      "last_login": "2026-11-20 11:00:00",
      "has_profile": true,
      "userdata_id": 42,
      "photo_profil": "<URL de production>/uploads/photos/3f9c0b1e-....jpg"
    },
    "token": "15|<secret>...",
    "token_type": "Bearer"
  }
}
```

Erreurs à traiter :

| Statut | Code | Signification | Affichage conseillé |
|---|---|---|---|
| `422` | — | Champ manquant ou invalide | Message sous le champ. |
| `401` | — | Identifiants incorrects (`errors.login` ou `errors.password`) | **Un seul message générique** « Identifiant ou mot de passe incorrect », sans distinguer les deux cas. |
| `403` | `email_not_verified` | Compte non activé | Écran d’activation, avec « Renvoyer le lien » (§ 3.2). |
| `403` | `access_blocked` | Compte suspendu par l’administration | Message renvoyé (invite à contacter l’administration). |
| `403` | `admin_not_allowed` | Compte administrateur | Message renvoyé : les administrateurs utilisent le site. |
| `429` | `too_many_requests` | Trop de tentatives | Demander de patienter avant de réessayer. |

### 3.4 Compte courant

`GET /auth/me` — Bearer requis, e-mail vérifié, succès `200`.

Retourne `data.user` au format utilisateur décrit plus haut. Cette route ne retourne pas de résumé de progression du dossier. Elle peut servir au démarrage de l’application pour vérifier que le jeton enregistré est toujours valable (`401` → reconnexion).

### 3.5 Mot de passe oublié

`POST /auth/forgot-password` — public, corps JSON.

```json
{ "email": "awa.diop@example.com" }
```

Réponse `200` générique, que l’adresse corresponde ou non à un compte :

```json
{
  "success": true,
  "message": "Si cette adresse correspond à un compte, un lien de réinitialisation lui a été envoyé."
}
```

Le lien reçu par e-mail conduit au parcours web de réinitialisation. L’API mobile ne fournit pas d’endpoint pour choisir directement un nouveau mot de passe. **Après une réinitialisation, les jetons existants sont révoqués** : l’application recevra `401` et devra demander une nouvelle connexion.

### 3.6 Se déconnecter

`POST /auth/logout` — Bearer requis, succès `200`.

```json
{ "success": true, "message": "Déconnexion réussie. Le jeton d’accès a été révoqué." }
```

Le client doit supprimer le jeton local après succès, et aussi en cas de `401` (jeton déjà expiré ou révoqué).

## 4. Données de référence

Ces routes sont publiques. Les réponses sont des listes sous `data`, avec des objets utilisant `id` et `libelle`.

| Méthode | Route | Particularité |
|---|---|---|
| `GET` | `/reference/all` | Bundle : régions avec départements, niveaux de formation, secteurs avec emplois, emplois, handicaps. |
| `GET` | `/reference/regions` | `?with_departements=1` inclut les départements. |
| `GET` | `/reference/regions/{id}/departements` | Renvoie aussi `region_id`. |
| `GET` | `/reference/niveaux-formation` | Niveaux académiques. |
| `GET` | `/reference/secteurs` | `?with_emplois=1` inclut les emplois du secteur. |
| `GET` | `/reference/secteurs/{id}/emplois` | Emplois du secteur et `secteur_id`. |
| `GET` | `/reference/emplois` | `?search=texte` filtre par libellé ; réponse avec `count`. |
| `GET` | `/reference/handicaps` | Types de handicap. |

Exemple d’objet emploi : `{"id": 12, "libelle": "Gestionnaire", "secteur_id": 3}`. Ces listes peuvent être mises en cache côté mobile ; prévoir leur rechargement après une mise à jour applicative ou une longue période hors ligne.

## 5. Dossier candidat

Toutes les routes de cette section exigent un jeton Sanctum valide et un compte activé. Chaque candidat ne modifie que son propre dossier ; aucun identifiant d’un autre candidat n’est transmis pour ces opérations.

### 5.1 Lire le profil complet

`GET /candidat/profile` — succès `200`.

Structure actuelle de `data` :

```json
{
  "userdata_id": 42,
  "candidat_number": 15,
  "completion_percentage": 78,
  "account": {
    "id": 15,
    "firstname": "Awa",
    "lastname": "Diop",
    "fullname": "Awa Diop",
    "email": "awa.diop@example.com",
    "numberid": "1234567890123",
    "username": "awa.diop",
    "enabled": true
  },
  "identity": {
    "telephone1": "771234567",
    "telephone2": null,
    "datenaiss": "1998-05-14",
    "lieunaiss": "Dakar",
    "genre": "Feminin",
    "situationmatrimoniale": "Célibataire",
    "nombreenfant": 0,
    "lieuresidence": "Sénégal",
    "region_naissance": {"id": 1, "libelle": "Dakar"},
    "departement_naissance": {"id": 1, "libelle": "Dakar"},
    "region_residence": {"id": 1, "libelle": "Dakar"},
    "departement_residence": {"id": 1, "libelle": "Dakar"},
    "handicap": null,
    "has_handicap": false,
    "photo_profil_url": "<URL de production>/uploads/photos/3f9c0b1e-....jpg"
  },
  "formations": [],
  "experiences": [],
  "has_experience": false,
  "target_jobs": {
    "cv_summary": null,
    "emploi1": null,
    "anneeexperience1": 0,
    "emploi2": null,
    "anneeexperience2": 0,
    "cv_files": [
      {
        "file_path": "cv/15/7d2a....pdf",
        "file_url": "<URL de production>/api/v1/candidat/files/cv/42/7d2a....pdf",
        "file_name": "7d2a....pdf"
      }
    ]
  }
}
```

- `formations` contient notamment `academic_id`, `academic_label`, `is_sans_diplome`, les détails du diplôme et, si disponible, `diplome_file_url` / `diplome_file_name`.
- `experiences` contient `poste`, `employeur`, `years` et `description`. Les objets emploi utilisent `id` et `libelle`.
- `cv_files` liste les CV **déjà enregistrés** (l’envoi de nouveaux CV est fermé). Leur `file_url` est une route protégée : voir § 6.3.

### 5.2 Modifier identité et résidence

`PUT /candidat/identity` — JSON, succès `200`. Les champs sont facultatifs individuellement :

```json
{
  "telephone1": "771234567",
  "telephone2": null,
  "datenaiss": "1998-05-14",
  "lieunaiss": "Dakar",
  "genre": "Feminin",
  "situationmatrimoniale": "Célibataire",
  "nombreenfant": 0,
  "lieuresidence": "Sénégal",
  "regionnaiss_id": 1,
  "departementnaiss_id": 1,
  "regionresidence_id": 1,
  "departementresidence_id": 1,
  "has_handicap": false,
  "handicap_id": null
}
```

`genre` accepte `Masculin`, `Feminin`, `Homme` ou `Femme` ; les deux dernières valeurs sont normalisées. Les identifiants de région, département et handicap doivent exister. `has_handicap: false` efface `handicap_id`.

Cette route permet aussi un envoi facultatif de `photo_profil` en multipart (JPEG, PNG, JPG ou WEBP, 4 Mo maximum) ; dans ce cas, envoyer les autres champs dans le même multipart. Le serveur vérifie le **contenu réel** du fichier : un fichier qui n’est pas une image est refusé avec `422`, quel que soit son nom. Le succès renvoie uniquement la section `identity` dans `data`.

### 5.3 Remplacer les formations

`PUT /candidat/formations` — JSON, succès `200`.

Cette route remplace la liste envoyée. Chaque entrée avec `academic_id` est enregistrée. La valeur `20` ou `"sansdiplome"` représente « sans diplôme » et efface les détails et le justificatif de cette entrée.

```json
{
  "formations": [
    {
      "academic_id": "5",
      "diplome": "Licence en informatique",
      "anneediplome": "2022",
      "specialite": "Génie logiciel",
      "etablissementdiplome": "UCAD",
      "diplome_file": "diplomes/15/2fc3...uuid.pdf"
    }
  ]
}
```

Pour joindre un justificatif, l’envoyer d’abord à `POST /candidat/files/diplome`, puis placer le `file_path` retourné dans `diplome_file`. Le chemin doit correspondre à un fichier privé appartenant au candidat connecté. Ne pas envoyer `existing_diplome_file` ni une URL. Le succès retourne la liste `formations` actualisée dans `data`.

### 5.4 Remplacer les expériences

`PUT /candidat/experiences` — JSON, succès `200`.

`has_experience` doit être un booléen (`true`/`false`, ou `1`/`0`), et non les chaînes `"oui"` ou `"non"`.

```json
{
  "has_experience": true,
  "experiences": [
    {
      "poste": "Développeuse mobile",
      "employeur": "Entreprise",
      "years": 2,
      "description": "Conception et maintenance d’applications."
    }
  ]
}
```

`years` est numérique, entre 0 et 70. Si `has_experience` est faux ou si la liste est vide, les expériences existantes sont effacées. Le succès retourne la liste `experiences` actualisée dans `data`.

### 5.5 Modifier les emplois ciblés

`PUT /candidat/target-jobs` — JSON, succès `200`.

```json
{
  "cv_summary": "Profil de développeuse mobile à la recherche d’un nouveau poste.",
  "emploi1_id": 12,
  "anneeexperience1": 2,
  "emploi2_id": 15,
  "anneeexperience2": 1
}
```

Les identifiants d’emploi doivent exister ; les années sont des entiers de 0 à 50 ; le résumé est limité à 1000 caractères. Le succès retourne la section `target_jobs` actualisée dans `data`.

## 6. Documents et fichiers

Les limites indiquées sont celles de l’API mobile. Envoyer les champs de fichier en multipart avec le jeton Bearer.

**Règle générale :** le serveur ne conserve jamais le nom d’origine d’un fichier. Il lui attribue un nom aléatoire et déduit le format de son contenu. L’application ne doit donc ni afficher ni réutiliser le nom du fichier renvoyé comme s’il s’agissait du nom choisi par le candidat.

### 6.1 Photo de profil

`POST /candidat/files/photo` — champ multipart `photo`, JPEG/PNG/JPG/WEBP, 4 Mo maximum, succès `200`.

Réponse : `data.photo_path` et `data.photo_url`. Un fichier dont le contenu n’est pas une image autorisée est refusé (`422`), même s’il porte une extension d’image. La photo de profil reste accessible par son URL.

### 6.2 Envoi de CV — fonctionnalité fermée

`POST /candidat/files/cv` — **n’est plus disponible.** Réponse :

```json
{
  "success": false,
  "message": "L’envoi de CV n’est plus disponible."
}
```

Statut `410`. L’application ne doit plus proposer l’envoi de CV.

### 6.3 Consulter un CV déjà enregistré

`GET /candidat/files/cv/{userdata}/{filename}` — Bearer requis et compte activé.

Utiliser le `file_url` fourni dans `target_jobs.cv_files` **avec l’en-tête `Authorization`**. Le serveur renvoie le fichier en téléchargement (pièce jointe). Un lien ouvert dans un navigateur sans le jeton ne fonctionne pas. Le candidat ne peut consulter que les CV de son propre dossier (`403` sinon, `404` si le fichier n’existe plus).

Les applications natives peuvent télécharger la réponse binaire puis l’ouvrir avec le visualiseur du téléphone.

### 6.4 Supprimer un CV

`DELETE /candidat/files/cv` — Bearer requis, JSON :

```json
{ "file_path": "cv/15/7d2a....pdf" }
```

Envoyer exactement le `file_path` reçu dans `cv_files`. Le chemin doit appartenir à la liste des CV du compte connecté. Succès `200` ; champ absent `422` ; fichier qui n’appartient pas au compte ou introuvable `404`.

### 6.5 Téléverser un justificatif de diplôme

`POST /candidat/files/diplome` — champ multipart `diplome_file`, PDF/DOC/DOCX/RTF/TXT/PNG/JPG/JPEG, 8 Mo maximum, succès `201`.

```json
{
  "success": true,
  "message": "Justificatif de diplôme téléversé.",
  "data": {
    "file_path": "diplomes/15/2fc3...uuid.pdf",
    "file_url": "<URL de production>/api/v1/candidat/files/diplomes/42/2fc3...uuid.pdf",
    "file_name": "2fc3...uuid.pdf"
  }
}
```

Le fichier est stocké en privé. Pour le rattacher à une formation, envoyer son `file_path` dans `PUT /candidat/formations`. Il n’existe pas de paramètre `formation_index`.

### 6.6 Télécharger un justificatif de diplôme

`GET /candidat/files/diplomes/{userdata}/{filename}` — Bearer requis et compte activé. Le candidat ne peut télécharger que les justificatifs du profil associé à son compte. Une URL seule ouverte dans un navigateur sans en-tête `Authorization` ne suffit pas.

Utiliser le `diplome_file_url` fourni par le profil avec le même jeton Bearer.

## 7. Chatbot

### 7.1 Conversation de l’application mobile

`POST /chatbot/messages` — JSON, public, limite de débit appliquée. Un jeton Bearer facultatif rattache la conversation au compte connecté.

```json
{
  "message": "Bonjour",
  "session_id": "7e67ff0b-b83f-43f2-96e9-e4faa2481e01"
}
```

`message` est obligatoire (1000 caractères maximum). `session_id` est facultatif au premier appel et doit être un UUID s’il est fourni. Conserver l’identifiant retourné et le renvoyer au message suivant.

```json
{
  "success": true,
  "message": "Réponse du chatbot.",
  "data": {
    "session_id": "7e67ff0b-b83f-43f2-96e9-e4faa2481e01",
    "messages": [
      {
        "text": "Avez-vous déjà un compte ?",
        "buttons": [{"title": "Oui", "payload": "/confirm_has_account"}],
        "image": null,
        "custom": null
      }
    ]
  }
}
```

Afficher une bulle par élément de `messages`. Pour un bouton, afficher son `title` mais renvoyer son `payload` dans le champ `message`. Les réponses peuvent contenir du texte, des boutons, une image ou des données `custom`. L’indisponibilité du service est renvoyée en `503` avec `code: chatbot_unavailable`.

Si un jeton est envoyé et qu’il a expiré, traiter le `401` comme ailleurs (effacer le jeton) ; le chatbot reste utilisable sans jeton.

### 7.2 Services réservés à l’intégration serveur du chatbot

Les routes `/chatbot/pgde/*` sont appelées uniquement par le serveur du chatbot, avec un secret serveur configuré côté backend. **Elles ne doivent jamais être appelées depuis l’application mobile, et aucun secret ne doit y être intégré.** Elles ne font pas partie du contrat de l’application.

## 8. Guide d’intégration mobile et Postman

Variables d’environnement recommandées :

- `baseUrl` : `<URL de production>/api/v1` (ou URL locale en développement)
- `token` : vide avant connexion, puis valeur de `data.token`

Ordre de parcours conseillé :

1. Charger `GET /reference/all` pour préparer les listes de formulaire.
2. Créer un compte avec `POST /auth/register`.
3. Afficher une étape d’activation et proposer `POST /auth/resend-verification` si nécessaire.
4. Après activation, appeler `POST /auth/login` et enregistrer le jeton dans le stockage sécurisé de l’appareil.
5. Au démarrage suivant de l’application, vérifier le jeton avec `GET /auth/me` ; sur `401`, revenir à la connexion.
6. Ajouter `Authorization: Bearer {{token}}` et charger `GET /candidat/profile`.
7. Mettre à jour identité, formations, expériences et emplois ciblés avec les routes `PUT` correspondantes.
8. Pour un diplôme, téléverser d’abord le fichier, puis rattacher le `file_path` retourné dans la mise à jour des formations.
9. Pour ouvrir un diplôme ou un CV déjà enregistré, télécharger son URL avec le jeton Bearer.
10. Lors de la déconnexion, appeler `POST /auth/logout`, puis effacer le jeton local.

Pour toutes les réponses, gérer les statuts HTTP avant de lire `data` :

- `401` → jeton expiré ou révoqué : effacer le jeton et revenir à la connexion ;
- `403 email_not_verified` → écran d’activation ;
- `403 access_blocked` → message de compte suspendu ;
- `403 admin_not_allowed` → message indiquant que l’application est réservée aux candidats ;
- `410` → fonctionnalité retirée (envoi de CV) ;
- `422` → associer `errors` aux champs concernés ;
- `429` → demander de patienter.

Ne pas supposer qu’un fichier privé (CV, diplôme) est accessible sans authentification.

## 9. Endpoints présents dans l’API mais hors contrat candidat

Le contrat ci-dessus couvre les opérations mobiles liées au compte candidat et le chatbot. L’API ne fournit pas d’endpoints REST séparés pour créer, modifier ou supprimer une formation ou une expérience par identifiant : les listes sont remplacées par `PUT /candidat/formations` et `PUT /candidat/experiences`. Les fonctions d’administration (campagnes e-mail, paramètres, gestion et suspension d’agents) sont des fonctions web et ne doivent pas être présentées comme endpoints mobiles.
