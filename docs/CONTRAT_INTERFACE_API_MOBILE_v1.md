# Contrat d’interface et API mobile PGDE

> **Version de l’API :** `v1`
> **Dernière vérification du contrat :** 5 octobre 2026
> **Public visé :** développeurs de l’application mobile et intégrateurs du chatbot
> **Source de vérité :** routes et contrôleurs Laravel du dépôt. Les réponses d’exemple illustrent le format ; les libellés et données métier peuvent varier.

Ce document décrit les routes réellement disponibles et les règles que l’application mobile doit respecter. Les fonctions d’administration du site web ne constituent pas des routes de l’API mobile.

## 1. Environnements et conventions

### URL de base

Toutes les routes mobiles sont préfixées par `/api/v1`.

| Environnement | URL de base |
|---|---|
| Développement local | `http://127.0.0.1:8000/api/v1` |
| Production | `https://emploi.fonctionpublique.sn/api/v1` |

La disponibilité de l’URL de production dépend de la configuration du serveur déployé. Ne pas utiliser l’URL locale dans l’application publiée.

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

### Authentification et activation

- L’API utilise des jetons personnels Laravel Sanctum transmis en Bearer.
- L’inscription ne crée pas de jeton. Le candidat doit activer son adresse e-mail, puis se connecter.
- Les routes `/candidat/*` et le téléchargement API des diplômes exigent un jeton valide **et** une adresse e-mail vérifiée.
- La déconnexion révoque le jeton courant. Aucun endpoint de renouvellement de jeton n’est actuellement exposé.
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
    "email": ["L’adresse e-mail n’est pas valide."]
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

Codes rencontrés notamment : `unauthenticated` (`401`), `forbidden` (`403`), `not_found` (`404`), `too_many_requests` (`429`) et `server_error` (`500`). Certains contrôleurs renvoient leurs propres erreurs métier ; le client doit donc traiter le statut HTTP et ne pas supposer qu’un seul format s’applique à toutes les routes.

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

Règles principales : nom et prénom obligatoires (255 caractères maximum) ; nom d’utilisateur de 3 à 50 caractères, composé de lettres, chiffres, points, tirets ou tirets bas ; numéro CNI/passeport alphanumérique et unique ; adresse e-mail valide et unique ; mot de passe d’au moins 8 caractères, confirmé.

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
      "date_inscription": "2026-10-05 10:30:00",
      "last_login": null,
      "has_profile": false,
      "userdata_id": null,
      "photo_profil": "https://emploi.fonctionpublique.sn/images/images.png"
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

`POST /auth/login` — public, corps JSON, succès `200`.

`login` accepte le nom d’utilisateur ou l’adresse e-mail. `device_name` est facultatif et identifie le jeton sur le serveur.

```json
{
  "login": "awa.diop@example.com",
  "password": "MotDePasse123!",
  "device_name": "android-app"
}
```

Après vérification des identifiants, le compte doit être activé et ne pas être bloqué par l’administration. Succès :

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
      "date_inscription": "2026-10-05 10:30:00",
      "last_login": "2026-10-05 11:00:00",
      "has_profile": true,
      "userdata_id": 42,
      "photo_profil": "https://emploi.fonctionpublique.sn/uploads/photos/avatar.jpg"
    },
    "token": "15|<secret>...",
    "token_type": "Bearer"
  }
}
```

Erreurs à traiter : `422` pour les champs manquants ou invalides ; `401` pour des identifiants incorrects ; `403` avec `code: email_not_verified` si le compte n’est pas activé ; `403` avec `code: access_blocked` si le compte est suspendu. Le message de compte bloqué invite à contacter l’administration.

### 3.4 Compte courant

`GET /auth/me` — Bearer requis, e-mail vérifié, succès `200`.

Retourne `data.user` au format utilisateur décrit plus haut. Cette route ne retourne pas de résumé de progression du dossier.

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

Le lien reçu par e-mail conduit au parcours web de réinitialisation. L’API mobile ne fournit pas d’endpoint pour choisir directement un nouveau mot de passe.

### 3.6 Se déconnecter

`POST /auth/logout` — Bearer requis, succès `200`.

```json
{ "success": true, "message": "Déconnexion réussie. Le jeton d’accès a été révoqué." }
```

Le client doit supprimer le jeton local après succès. Un jeton révoqué ne doit plus être réutilisé.

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
    "photo_profil_url": "https://emploi.fonctionpublique.sn/uploads/photos/avatar.jpg"
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
    "cv_files": []
  }
}
```

`formations` contient notamment `academic_id`, `academic_label`, `is_sans_diplome`, les détails du diplôme et, si disponible, `diplome_file_url` / `diplome_file_name`. `experiences` contient `poste`, `employeur`, `years` et `description`. Les objets emploi utilisent `id` et `libelle`.

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

`genre` accepte `Masculin`, `Feminin`, `Homme` ou `Femme` ; les deux dernières valeurs sont normalisées. Les identifiants de région, département et handicap doivent exister. `has_handicap: false` efface `handicap_id`. Cette route permet aussi un upload facultatif de `photo_profil` en multipart (JPEG, PNG, JPG ou WEBP, 4 Mo maximum) ; dans ce cas, envoyer les autres champs dans le même multipart. Le succès renvoie uniquement la section `identity` dans `data`.

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

Pour joindre un justificatif, l’envoyer d’abord à `POST /candidat/files/diplome` puis placer le `file_path` retourné dans `diplome_file`. Le chemin doit correspondre à un fichier privé appartenant au candidat connecté. Ne pas envoyer `existing_diplome_file` ni une URL publique. Le succès retourne la liste `formations` actualisée dans `data`.

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

### 6.1 Photo de profil

`POST /candidat/files/photo` — champ multipart `photo`, JPEG/PNG/JPG/WEBP, 4 Mo maximum, succès `200`.

Réponse : `data.photo_path` et `data.photo_url`. La photo est enregistrée sous une URL publique dans le comportement actuel du serveur.

### 6.2 Téléverser un CV

`POST /candidat/files/cv` — champ multipart `cv_file`, PDF/DOC/DOCX/RTF/TXT, 8 Mo maximum, succès `201`.

```json
{
  "success": true,
  "message": "Curriculum Vitae téléversé avec succès.",
  "data": {
    "file_path": "uploads/cv/cv_15_....pdf",
    "file_url": "https://emploi.fonctionpublique.sn/uploads/cv/cv_15_....pdf",
    "file_name": "cv_15_....pdf"
  }
}
```

Le CV est actuellement enregistré avec un chemin public. Le profil fournit `cv_files`, contenant `file_path`, `file_url` et `file_name`.

### 6.3 Supprimer un CV

`DELETE /candidat/files/cv` — Bearer requis, JSON :

```json
{ "file_path": "uploads/cv/cv_15_....pdf" }
```

Le chemin doit appartenir à la liste des CV du compte connecté. Succès `200`; champ absent/invalide `422`; fichier qui n’appartient pas au compte ou introuvable `404`.

### 6.4 Téléverser un justificatif de diplôme

`POST /candidat/files/diplome` — champ multipart `diplome_file`, PDF/DOC/DOCX/RTF/TXT/PNG/JPG/JPEG, 8 Mo maximum, succès `201`.

```json
{
  "success": true,
  "message": "Justificatif de diplôme téléversé.",
  "data": {
    "file_path": "diplomes/15/2fc3...uuid.pdf",
    "file_url": "https://emploi.fonctionpublique.sn/api/v1/candidat/files/diplomes/42/2fc3...uuid.pdf",
    "file_name": "2fc3...uuid.pdf"
  }
}
```

Le fichier est stocké en privé. Pour le rattacher à une formation, envoyer son `file_path` dans `PUT /candidat/formations`. Il n’existe pas de paramètre `formation_index`.

### 6.5 Télécharger un justificatif de diplôme

`GET /candidat/files/diplomes/{userdata}/{filename}` — Bearer requis et compte activé. Le candidat ne peut télécharger que les justificatifs du profil associé à son compte. La route retourne le fichier en téléchargement ; une URL seule ouverte dans un navigateur sans en-tête `Authorization` ne suffit pas.

Utiliser le `diplome_file_url` fourni par le profil avec le même jeton Bearer. Les applications natives peuvent télécharger la réponse binaire directement et l’ouvrir avec le visualiseur approprié.

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

### 7.2 Services réservés à l’intégration serveur du chatbot

Ces routes utilisent un secret serveur configuré côté backend (`CHATBOT_API_TOKEN`). **Ne jamais intégrer ce secret dans l’application mobile.** Elles renvoient une enveloppe avec `success`, `code`, `message`, `data` et `correlation_id`.

| Méthode | Route | Corps |
|---|---|---|
| `POST` | `/chatbot/pgde/accounts/verify` | `{ "cni": "1234567890123" }` |
| `POST` | `/chatbot/pgde/password/reset` | `{ "cni": "1234567890123", "email": "awa.diop@example.com" }` |

La vérification renvoie `FOUND` avec les données du compte, `NOT_FOUND` si la CNI ne correspond pas, ou `INACTIVE_ACCOUNT` si le compte est désactivé/bloqué. La réinitialisation exige que CNI et e-mail correspondent au même compte ; elle déclenche l’e-mail officiel, sans transmettre le lien au chatbot. Elle peut renvoyer `RESET_ACCEPTED`, `NOT_FOUND`, `INACTIVE_ACCOUNT`, `INVALID_INPUT`, `TOO_MANY_REQUESTS` ou `TEMPORARY_ERROR`.

## 8. Guide d’intégration mobile et Postman

Variables d’environnement recommandées :

- `baseUrl` : `https://emploi.fonctionpublique.sn/api/v1` (ou URL locale en développement)
- `token` : vide avant connexion, puis valeur de `data.token`

Ordre de parcours conseillé :

1. Charger `GET /reference/all` pour préparer les listes de formulaire.
2. Créer un compte avec `POST /auth/register`.
3. Afficher une étape d’activation et proposer `POST /auth/resend-verification` si nécessaire.
4. Après activation, appeler `POST /auth/login` et enregistrer le jeton dans le stockage sécurisé de l’appareil.
5. Ajouter `Authorization: Bearer {{token}}` et charger `GET /candidat/profile`.
6. Mettre à jour identité, formations, expériences et emplois ciblés avec les routes `PUT` correspondantes.
7. Pour un diplôme, téléverser d’abord le fichier, puis rattacher le `file_path` retourné dans la mise à jour des formations.
8. Lors de la déconnexion, appeler `POST /auth/logout`, puis effacer le jeton local.

Pour toutes les réponses, gérer les statuts HTTP avant de lire `data`. En particulier, une erreur `403` `email_not_verified` doit orienter vers l’activation ; `access_blocked` doit afficher un message de compte suspendu ; `422` doit associer `errors` aux champs concernés. Ne pas supposer que le lien d’un justificatif privé est accessible sans authentification.

## 9. Endpoints présents dans l’API mais hors contrat candidat

Le contrat ci-dessus couvre les opérations mobiles liées au compte candidat et le chatbot. L’API ne fournit actuellement pas d’endpoints REST séparés pour créer, modifier ou supprimer une formation ou une expérience par identifiant : les listes sont remplacées par `PUT /candidat/formations` et `PUT /candidat/experiences`. Les fonctions d’administration (campagnes e-mail, paramètres, gestion et suspension d’agents) sont des fonctions web et ne doivent pas être présentées comme endpoints mobiles.
