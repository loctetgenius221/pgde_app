# 📱 Contrat d'Interface & Spécification API REST Mobile (v1)

> **Projet** : Plateforme de Gestion des Demandeurs d'Emploi (PGDE)  
> **Version API** : `v1`  
> **Type d'authentification** : `Bearer Token` (Laravel Sanctum)  
> **Formats acceptés** : `application/json` (données) & `multipart/form-data` (fichiers)  

---

## 📑 Sommaire
1. [Principes Généraux & Headers](#1-principes-généraux--headers)
2. [Format Standard des Réponses](#2-format-standard-des-réponses)
3. [Module 1 : Authentification & Sécurité](#3-module-1--authentification--sécurité)
4. [Module 2 : Données de Référence (Caches & Dropdowns)](#4-module-2--données-de-référence)
5. [Module 3 : Parcours Dossier Candidat (4 Étapes)](#5-module-3--parcours-dossier-candidat)
6. [Module 4 : Téléversement des Fichiers & Documents](#6-module-4--téléversement-des-fichiers--documents)
7. [Guide Postman & Scénarios de Test](#7-guide-postman--scénarios-de-test)

---

## 1. Principes Généraux & Headers

### 🌐 Base URL
- **Développement local** : `http://127.0.0.1:8000/api/v1` (ou IP locale du serveur)
- **Production / Staging** : `https://votre-domaine.sn/api/v1`

### 📋 En-têtes HTTP (Headers)
| Header | Valeur | Obligatoire | Remarques |
| :--- | :--- | :---: | :--- |
| `Accept` | `application/json` | **Oui** | Force Laravel à toujours renvoyer du JSON (même en cas d'erreur 500 ou 422). |
| `Content-Type` | `application/json` | **Oui** | Pour toutes les requêtes POST / PUT avec corps JSON. *(Ne pas mettre pour les uploads multipart)* |
| `Authorization` | `Bearer {TOKEN}` | **Oui (routes protégées)** | Jeton obtenu lors du `/auth/login` ou `/auth/register`. |

---

## 2. Format Standard des Réponses

### ✅ Réponse de Succès (Code HTTP `200` ou `201`)
```json
{
  "success": true,
  "message": "Opération effectuée avec succès.",
  "data": {
    ...
  }
}
```

### ❌ Réponse d'Erreur de Validation (Code HTTP `422 Unprocessable Entity`)
```json
{
  "success": false,
  "message": "Erreur de validation des données.",
  "errors": {
    "email": [
      "Cet email est déjà associé à un compte."
    ],
    "password": [
      "Le mot de passe doit comporter au moins 8 caractères."
    ]
  }
}
```

### ⛔ Réponse Non Authentifié (Code HTTP `401 Unauthorized`)
```json
{
  "message": "Unauthenticated."
}
```

---

## 3. Module 1 : Authentification & Sécurité

### 3.1 Inscription Candidat
- **Endpoint** : `POST /auth/register`
- **Authentification** : Aucune (Public)
- **Body JSON** :
```json
{
  "firstname": "Amadou",
  "lastname": "Diallo",
  "username": "amadou_diallo",
  "numberid": "1234567890123",
  "email": "amadou.diallo@example.com",
  "password": "Password123!",
  "password_confirmation": "Password123!"
}
```
- **Réponse Succès (`201 Created`)** :
```json
{
  "success": true,
  "message": "Compte créé avec succès ! Un e-mail de confirmation vous a été envoyé.",
  "data": {
    "user": {
      "id": 15,
      "firstname": "Amadou",
      "lastname": "Diallo",
      "username": "amadou_diallo",
      "numberid": "1234567890123",
      "email": "amadou.diallo@example.com",
      "enabled": false,
      "date_inscription": "2026-09-24 10:30:00"
    },
    "token": "1|qwertzuiopasdfghjklyxcvbnm...",
    "token_type": "Bearer"
  }
}
```

---

### 3.2 Connexion Candidat
- **Endpoint** : `POST /auth/login`
- **Authentification** : Aucune (Public)
- **Body JSON** :
```json
{
  "login": "amadou.diallo@example.com", 
  "password": "Password123!",
  "device_name": "iPhone 15 Pro"
}
```
*(Le champ `login` accepte soit l'adresse **email**, soit le **username**).*

- **Réponse Succès (`200 OK`)** :
```json
{
  "success": true,
  "message": "Connexion réussie.",
  "data": {
    "user": {
      "id": 15,
      "firstname": "Amadou",
      "lastname": "Diallo",
      "username": "amadou_diallo",
      "numberid": "1234567890123",
      "email": "amadou.diallo@example.com",
      "enabled": true,
      "has_profile": true
    },
    "token": "2|1234567890abcdef...",
    "token_type": "Bearer"
  }
}
```

---

### 3.3 Utilisateur Connecté (`/me`)
- **Endpoint** : `GET /auth/me`
- **Authentification** : `Bearer Token`
- **Réponse Succès (`200 OK`)** :
```json
{
  "success": true,
  "message": "Informations de l'utilisateur connecté.",
  "data": {
    "user": {
      "id": 15,
      "firstname": "Amadou",
      "lastname": "Diallo",
      "username": "amadou_diallo",
      "numberid": "1234567890123",
      "email": "amadou.diallo@example.com",
      "enabled": true
    },
    "profile_summary": {
      "has_userdata": true,
      "has_completed_profile": true,
      "completion_rate": 100
    }
  }
}
```

---

### 3.4 Déconnexion
- **Endpoint** : `POST /auth/logout`
- **Authentification** : `Bearer Token`
- **Réponse Succès (`200 OK`)** :
```json
{
  "success": true,
  "message": "Déconnexion réussie. Jeton révoqué."
}
```

---

### 3.5 Mot de passe oublié
- **Endpoint** : `POST /auth/forgot-password`
- **Body JSON** :
```json
{
  "email": "amadou.diallo@example.com"
}
```

---

## 4. Module 2 : Données de Référence

> **💡 Conseil Mobile** : Appelez `GET /reference/all` au démarrage du splash screen / login et stockez la réponse dans le cache local (SQLite / SharedPreferences) pour éliminer les temps d'attente sur les formulaires.

| Méthode | Endpoint | Description | Paramètres |
| :--- | :--- | :--- | :--- |
| `GET` | `/reference/all` | **Toutes les références en 1 appel** (Régions, Départements, Formations, Secteurs, Métiers, Handicaps). | Aucun |
| `GET` | `/reference/regions` | Liste des 14 régions du Sénégal. | Aucun |
| `GET` | `/reference/regions/{id}/departements` | Départements d'une région donnée. | `{id}` dans l'URL |
| `GET` | `/reference/niveaux-formation` | Niveaux académiques (Sans diplôme, BFEM, Bac, Licence, Master...). | Aucun |
| `GET` | `/reference/secteurs` | Liste de tous les secteurs d'activité. | Aucun |
| `GET` | `/reference/secteurs/{id}/emplois` | Métiers associés à un secteur d'activité spécifique. | `{id}` dans l'URL |
| `GET` | `/reference/emplois` | Liste complète de tous les métiers/emplois. | Aucun |
| `GET` | `/reference/handicaps` | Liste des types de handicap. | Aucun |

---

## 5. Module 3 : Parcours Dossier Candidat

### 5.1 Récupération Complète du Profil (`GET /candidat/profile`)
- **Authentification** : `Bearer Token`
- **Réponse Succès (`200 OK`)** :
```json
{
  "success": true,
  "message": "Profil candidat récupéré avec succès.",
  "data": {
    "identity": {
      "firstname": "Amadou",
      "lastname": "Diallo",
      "email": "amadou.diallo@example.com",
      "telephone1": "771234567",
      "telephone2": null,
      "genre": "Masculin",
      "datenaiss": "1998-05-14",
      "lieunaiss": "Dakar",
      "situationmatrimoniale": "Célibataire",
      "nombreenfant": 0,
      "lieuresidence": "Sénégal",
      "addresse": "Médina Rue 6",
      "region_naissance": { "id": 1, "nom": "Dakar" },
      "departement_naissance": { "id": 1, "nom": "Dakar" },
      "region_residence": { "id": 1, "nom": "Dakar" },
      "departement_residence": { "id": 1, "nom": "Dakar" },
      "handicap": null,
      "photo_profil_url": "http://127.0.0.1:8000/uploads/photos/photo_15.jpg"
    },
    "formations": [
      {
        "id": 1,
        "academic_id": 5,
        "academic_label": "Licence",
        "is_sans_diplome": false,
        "diplome": "Licence en Informatique",
        "anneediplome": "2022",
        "specialite": "Génie Logiciel",
        "etablissementdiplome": "Université Cheikh Anta Diop",
        "diplome_file_url": "http://127.0.0.1:8000/uploads/diplomes/1727175260_diplome.pdf",
        "diplome_file_name": "1727175260_diplome.pdf"
      }
    ],
    "experiences": [
      {
        "id": 1,
        "poste": "Développeur Mobile",
        "employeur": "Tech Solutions SN",
        "years": 2,
        "description": "Développement d'applications Flutter et maintenance."
      }
    ],
    "target_jobs": {
      "emploi1": { "id": 12, "intitule": "Développeur Web & Mobile" },
      "emploi2": { "id": 15, "intitule": "Administrateur Systèmes" },
      "anneeexperience1": 2,
      "anneeexperience2": 1,
      "cv_summary": "Développeur passionné par les technologies mobiles.",
      "cv_files": [
        {
          "file_url": "http://127.0.0.1:8000/uploads/cv/1727175260_cv.pdf",
          "file_name": "1727175260_cv.pdf"
        }
      ]
    },
    "progression": {
      "is_completed": true,
      "percentage": 100
    }
  }
}
```

---

### 5.2 Étape 1 : Mise à jour Identité & Résidence
- **Endpoint** : `PUT /candidat/identity`
- **Authentification** : `Bearer Token`
- **Body JSON** :
```json
{
  "telephone1": "771234567",
  "telephone2": "701234567",
  "datenaiss": "1998-05-14",
  "lieunaiss": "Dakar",
  "genre": "Masculin",
  "situationmatrimoniale": "Célibataire",
  "nombreenfant": 0,
  "lieuresidence": "Sénégal",
  "addresse": "Médina Rue 6",
  "regionnaiss_id": 1,
  "departementnaiss_id": 1,
  "regionresidence_id": 1,
  "departementresidence_id": 1,
  "has_handicap": false,
  "handicap_id": null
}
```

---

### 5.3 Étape 2 : Mise à jour des Formations
- **Endpoint** : `PUT /candidat/formations`
- **Authentification** : `Bearer Token`
- **Body JSON (Avec Diplôme(s))** :
```json
{
  "formations": [
    {
      "academic_id": "5",
      "diplome": "Licence en Informatique",
      "anneediplome": "2022",
      "specialite": "Génie Logiciel",
      "etablissementdiplome": "UCAD",
      "existing_diplome_file": "uploads/diplomes/1727175260_licence.pdf"
    }
  ]
}
```
- **Body JSON (Candidat "Sans diplôme")** :
```json
{
  "formations": [
    {
      "academic_id": "sansdiplome",
      "diplome": null,
      "anneediplome": null,
      "specialite": null,
      "etablissementdiplome": null
    }
  ]
}
```
*(Le backend supporte `academic_id: "sansdiplome"` ou `academic_id: 20`).*

---

### 5.4 Étape 3 : Mise à jour des Expériences
- **Endpoint** : `PUT /candidat/experiences`
- **Authentification** : `Bearer Token`
- **Body JSON** :
```json
{
  "hasExperience": "oui",
  "experiences": [
    {
      "poste": "Développeur Mobile",
      "employeur": "Tech Solutions SN",
      "years": 2,
      "description": "Conception d'applications mobiles."
    }
  ]
}
```
*(Si le candidat n'a pas d'expérience : `"hasExperience": "non"`, `"experiences": []`).*

---

### 5.5 Étape 4 : Emplois Ciblés & Résumé
- **Endpoint** : `PUT /candidat/target-jobs`
- **Authentification** : `Bearer Token`
- **Body JSON** :
```json
{
  "emploi1_id": 12,
  "emploi2_id": 15,
  "anneeexperience1": 2,
  "anneeexperience2": 1,
  "cv_summary": "Développeur mobile expérimenté à la recherche de nouveaux défis."
}
```

---

## 6. Module 4 : Téléversement des Fichiers & Documents

> **⚠️ Règle importante pour les fichiers** :
> 1. Définir le header `Content-Type: multipart/form-data` (automatique dans Postman / HTTP clients).
> 2. Envoyer le jeton `Authorization: Bearer {TOKEN}`.

### 6.1 Photo de Profil
- **Endpoint** : `POST /candidat/files/photo`
- **Champ Form-Data** : `photo_profil` (Fichier image : `.jpg`, `.jpeg`, `.png`, `.webp` ; max 4 Mo)
- **Réponse Succès (`200 OK`)** :
```json
{
  "success": true,
  "message": "Photo de profil mise à jour avec succès.",
  "data": {
    "photo_profil_url": "http://127.0.0.1:8000/uploads/photos/1727175260_profil.jpg"
  }
}
```

---

### 6.2 Fichier CV
- **Endpoint** : `POST /candidat/files/cv`
- **Champ Form-Data** : `cv_file` (Fichier document : `.pdf`, `.doc`, `.docx` ; max 8 Mo)
- **Réponse Succès (`200 OK`)** :
```json
{
  "success": true,
  "message": "CV téléversé avec succès.",
  "data": {
    "cv_url": "http://127.0.0.1:8000/uploads/cv/1727175260_cv.pdf",
    "cv_file_name": "1727175260_cv.pdf"
  }
}
```

### 6.3 Suppression du CV
- **Endpoint** : `DELETE /candidat/files/cv`
- **Réponse Succès (`200 OK`)** :
```json
{
  "success": true,
  "message": "CV supprimé avec succès."
}
```

---

### 6.4 Justificatif de Diplôme
- **Endpoint** : `POST /candidat/files/diplome`
- **Champs Form-Data** :
  - `diplome_file` : Fichier (`.pdf`, `.jpg`, `.png`, `.docx` ; max 8 Mo)
  - `formation_index` : `0` *(optionnel, index du diplôme concerné)*
- **Réponse Succès (`200 OK`)** :
```json
{
  "success": true,
  "message": "Justificatif de diplôme téléversé avec succès.",
  "data": {
    "file_path": "uploads/diplomes/1727175260_diplome.pdf",
    "file_url": "http://127.0.0.1:8000/uploads/diplomes/1727175260_diplome.pdf",
    "formation_index": 0
  }
}
```

---

## 7. Guide Postman & Scénarios de Test

### 🔧 Configuration de l'environnement Postman
Créez un environnement dans Postman avec les variables suivantes :
1. `baseUrl` = `http://127.0.0.1:8000/api/v1`
2. `bearerToken` = *(Vide au départ, se remplit après login)*

### 🚀 Scénario de test recommandé pour le dev mobile :
1. **Étape 1** : `GET {{baseUrl}}/reference/all`  
   *(Vérifier la récupération de toutes les données de listes déroulantes).*
2. **Étape 2** : `POST {{baseUrl}}/auth/register`  
   *(Créer un compte de test et récupérer le `token`).*
3. **Étape 3** : Configurer le header Postman : `Authorization: Bearer {{bearerToken}}`.
4. **Étape 4** : `GET {{baseUrl}}/candidat/profile`  
   *(Consulter le profil initial).*
5. **Étape 5** : `PUT {{baseUrl}}/candidat/identity`  
   *(Mettre à jour nom, téléphone, adresse, région/département).*
6. **Étape 6** : `POST {{baseUrl}}/candidat/files/photo`  
   *(Envoyer une photo en Form-Data).*
7. **Étape 7** : `PUT {{baseUrl}}/candidat/formations`  
   *(Ajouter les formations).*
8. **Étape 8** : `PUT {{baseUrl}}/candidat/experiences`  
   *(Ajouter les expériences professionnelles).*
9. **Étape 9** : `PUT {{baseUrl}}/candidat/target-jobs`  
   *(Définir les deux métiers ciblés).*
10. **Étape 10** : `POST {{baseUrl}}/candidat/files/cv`  
    *(Envoyer le fichier CV).*
11. **Étape 11** : `GET {{baseUrl}}/candidat/profile`  
    *(Vérifier que le profil est complet à 100%).*
