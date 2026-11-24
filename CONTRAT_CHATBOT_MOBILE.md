# Contrat d'interface — Chatbot Amath (application mobile)

> Public visé : développeur de l'application mobile (Flutter).
> Document autonome : il couvre tout ce qu'il faut pour intégrer le chatbot.
> Référence de comportement : le widget du site emploi (même API, même rendu).

## 1. Principe : l'application affiche, le chatbot décide

L'application **ne code aucun menu en dur**. Chaque réponse du chatbot contient le texte
à afficher et les boutons à proposer ; l'application se contente de les afficher et de
renvoyer le choix de l'utilisateur. Un menu modifié côté chatbot apparaît donc dans
l'application sans nouvelle version.

Une seule route : `POST /api/v1/chatbot/messages` (détail au § 2).

```
Utilisateur ──(texte ou clic)──▶ App ──POST {message, session_id}──▶ API ──▶ Chatbot
App ◀── {session_id, messages:[{text, buttons, image, custom}]} ◀──────────────┘
```

## 2. Contrat de l'API

### Requête

```http
POST /api/v1/chatbot/messages
Accept: application/json
Content-Type: application/json
Authorization: Bearer <jeton Sanctum>      (facultatif : utilisateur connecté)

{
  "message": "Bonjour",
  "session_id": "7e67ff0b-b83f-43f2-96e9-e4faa2481e01"
}
```

| Champ | Obligatoire | Règle |
|---|---|---|
| `message` | oui | texte saisi ou `payload` d'un bouton, 1 000 caractères maximum |
| `session_id` | non | UUID ; absent au premier appel, puis celui renvoyé par l'API |

Aucune autre route n'est nécessaire. Les routes `/chatbot/pgde/*` et le secret
`CHATBOT_API_TOKEN` sont réservés au serveur du chatbot : **interdits dans l'application**.

### Réponse — 200

```json
{
  "success": true,
  "message": "Réponse du chatbot.",
  "data": {
    "session_id": "7e67ff0b-b83f-43f2-96e9-e4faa2481e01",
    "messages": [
      {
        "text": "Bienvenue sur **E-Carrière** !\nAvez-vous déjà un compte ?",
        "buttons": [
          {"title": "Oui", "payload": "/confirm_has_account"},
          {"title": "Non", "payload": "/deny_has_account"}
        ],
        "image": null,
        "custom": null
      }
    ]
  }
}
```

`data.messages` peut contenir plusieurs éléments, ou aucun. Chaque élément a toujours
les quatre champs : `text` (texte ou `null`), `buttons` (liste, éventuellement vide),
`image` (URL ou `null`), `custom` (objet ou `null`).

### Erreurs

Toutes les erreurs ont la forme `{"success": false, "code": "...", "message": "..."}`
(`422` : `errors` à la place de `code`).

| HTTP | `code` | Cause |
|---|---|---|
| `422` | — | `message` absent ou trop long, `session_id` non UUID (détail dans `errors`) |
| `429` | `too_many_requests` | plus de 30 messages/min par conversation, ou 300/min par IP ; en-tête `Retry-After` |
| `429` | `too_many_cni_attempts` | plus de 10 numéros de CNI envoyés en 10 min depuis la même IP ; en-tête `Retry-After` |
| `503` | `chatbot_unavailable` | chatbot injoignable ou en erreur |

Le chatbot limite en outre la vérification à 5 CNI par conversation : au-delà, il répond
normalement (`200`) avec un message et un bouton Support.

### Délais

Une réponse peut prendre jusqu'à 30 s (consultation E-Carrière). Délai du client HTTP :
**35 s minimum**.

## 3. Boucle de conversation

1. **Ouverture** : envoyer `{"message": "/greet"}` sans `session_id`. Enregistrer le
   `session_id` reçu (stockage local de l'app).
2. **Chaque envoi** : `{"message": "<texte ou payload>", "session_id": "<celui enregistré>"}`.
3. **Chaque réponse** : ajouter **une bulle par élément** de `data.messages`, dans l'ordre.
   Une réponse peut contenir plusieurs bulles, ou aucune.
4. **Nouvelle conversation** (bouton ↻ en haut) : effacer l'historique local et le
   `session_id`, puis renvoyer `/greet`.

Utilisateur connecté : ajouter `Authorization: Bearer <jeton Sanctum>`. La conversation
est alors celle du compte (le `session_id` envoyé est ignoré).

## 4. Afficher un message du chatbot

Chaque élément de `messages` :

| Champ | Affichage |
|---|---|
| `text` | Bulle du chatbot. Peut être `null` (message avec seulement des boutons ou une image). |
| `buttons` | Liste de boutons sous la bulle (voir § 5). Liste vide = pas de bouton. |
| `image` | URL `https://…` : afficher l'image dans une bulle. Ignorer toute autre valeur. |
| `custom` | Réservé, pas utilisé aujourd'hui : ignorer sans erreur. |

### Mise en forme du texte

Le texte utilise un Markdown **réduit**. Interpréter uniquement :

| Syntaxe | Rendu |
|---|---|
| `**texte**` | gras |
| `*texte*` | italique |
| `[libellé](https://…)` | lien cliquable, ouvert dans le **navigateur externe** |
| `\n` | retour à la ligne |
| `• ` ou `- ` en début de ligne | à laisser tel quel (déjà lisible) |

Ne jamais interpréter de HTML : afficher le texte brut sinon. N'ouvrir que les liens
`http(s)`. Exemples réels de liens : connexion E-Carrière, connexion et mot de passe
oublié PGDE.

Le message de l'utilisateur s'affiche en texte brut, sans mise en forme.

## 5. Les boutons (menus)

Chaque bouton a un `title` (libellé) et un `payload` (valeur technique, ex.
`/go_back_greet_with_name` ou `/choose_platform{"platform": "PGDE"}`).

Au clic :

1. afficher une bulle **utilisateur** avec le `title` (jamais le payload) ;
2. envoyer le **`payload`** tel quel dans `message`, sans le modifier ni le traduire ;
3. désactiver tous les boutons affichés plus haut : **seuls les boutons du dernier
   message restent cliquables** (un vieux menu ne doit pas relancer une étape passée).

**Saisie bloquée** : tant que le dernier message du chatbot porte des boutons, désactiver
le champ de saisie et afficher en indication « Utilisez les boutons ci-dessus… ». Le
réactiver dès qu'arrive un message sans bouton (le chatbot attend alors un texte : nom,
CNI, matricule…). Le bouton ↻ (nouvelle conversation) reste toujours actif.

Pendant un envoi : afficher « Amath écrit… », bloquer saisie et boutons, délai HTTP ≥ 35 s.

### Icônes (facultatif, comme sur le site)

Choisir l'icône d'après le **payload**, jamais d'après le libellé (les libellés changent).
Nom de l'intention = texte entre `/` et `{` :

| Intention | Icône |
|---|---|
| `go_back_greet_with_name` | maison (menu principal) |
| `go_back_ecarriere`, `go_back_pgde`, `retour_menu_utilisateur` | flèche retour |
| `ask_support` | téléphone |
| `start_account_verification` | réessayer |
| `confirm_has_account`, `confirm_has_access`, `confirm_password_reset`, `confirm_reset_ecarriere` | coche |
| `deny_has_account`, `deny_has_access`, `deny_password_reset`, `cancel_reset_ecarriere` | croix |
| `ask_account_creation`, `ask_attestation_account` | ajout de compte |
| `ask_login` | connexion |
| `ask_password_reset`, `reset_password_ecarriere` | clé |
| `voir_actes`, `ask_attestation_request` | document |
| `voir_projets` | graphique |
| `ask_attestation_info` | info |
| `ask_attestation_status` | horloge |
| `choose_platform` + `"E-Carrière"` / `"PGDE"` / `"Attestation"` | mallette / personne / document |

Intention inconnue : bouton sans icône (pas d'erreur).

## 6. Parcours (à titre indicatif)

L'application n'a pas à connaître ces parcours ; ils servent à tester.

```
/greet ─▶ « Votre nom ? »                         (saisie libre)
        ─▶ Menu principal : E-Carrière | PGDE | Attestation de non appartenance

E-Carrière ─▶ Compte ? Oui | Non
   Oui ─▶ CNI (saisie, 13 chiffres) ─▶ Matricule (saisie, ex. 123456A)
       ─▶ Voir mes actes | Voir mes projets | Réinitialiser mot de passe
          | Autre vérification | Retour E-Carrière | Menu principal | Support
   Non ─▶ explications de création de compte

PGDE ─▶ Compte ? Oui | Non
   Oui ─▶ CNI (saisie) ─▶ compte vérifié ─▶ Se connecter | Mot de passe oublié …
   Non ─▶ création de compte (lien vers le site)

Attestation ─▶ À quoi ça sert ? | Créer mon compte | Comment postuler ? | Suivre une demande
```

Partout : « Menu principal » ramène au choix de plateforme, « Support » donne les contacts.

### Saisies libres : clavier adapté

Le chatbot n'indique pas le type de saisie attendu. Recommandation simple : clavier
texte par défaut ; si le dernier texte du chatbot mentionne « CNI », proposer un clavier
numérique (sans l'imposer). Ne pas valider le format côté app : le chatbot le fait et
explique l'erreur.

### Exemple complet : consulter ses actes E-Carrière

Textes réels du chatbot (relevés le 22/10/2026), données d'agent **fictives**.
Pour chaque étape : ce que l'app envoie, ce qu'elle reçoit (`data.messages`), ce qu'elle
affiche. Le `session_id` reçu à l'étape 1 est renvoyé à toutes les étapes suivantes.

**Étape 1 — ouverture du chat** (l'utilisateur n'a rien tapé)

```json
→ {"message": "/greet"}
← {"session_id": "7e67ff0b-b83f-43f2-96e9-e4faa2481e01", "messages": [
    {"text": "Dalal ak Jàmm !\nJe suis **Amath**, votre assistant virtuel du **Ministère de la Fonction publique, du Travail et de la Réforme du Service public**.\nJe suis ravi de vous accueillir ! Pour mieux vous accompagner dans vos démarches, pourriez-vous me communiquer votre nom, s'il vous plaît ?",
     "buttons": [], "image": null, "custom": null}
  ]}
```

Afficher : une bulle Amath (« Amath » et le ministère en gras). Pas de bouton →
**saisie active**. Aucune bulle utilisateur (`/greet` n'est pas affiché).

**Étape 2 — l'utilisateur tape son nom**

```json
→ {"message": "Awa", "session_id": "7e67ff0b-…"}
← {"messages": [
    {"text": "Bienvenue, Awa !\nJe suis là pour vous orienter vers les services disponibles et vous accompagner dans vos démarches administratives.\n**Que souhaitez-vous faire aujourd'hui ?**",
     "buttons": [
       {"title": "E-Carrière", "payload": "/choose_platform{\"platform\": \"E-Carrière\"}"},
       {"title": "Demande d'emploi (PGDE)", "payload": "/choose_platform{\"platform\": \"PGDE\"}"},
       {"title": "Attestation de non appartenance", "payload": "/choose_platform{\"platform\": \"Attestation\"}"}
     ], "image": null, "custom": null}
  ]}
```

Afficher : bulle utilisateur « Awa », puis la bulle Amath et 3 boutons →
**saisie bloquée** (« Utilisez les boutons ci-dessus… »).

**Étape 3 — clic sur « E-Carrière »**

```json
→ {"message": "/choose_platform{\"platform\": \"E-Carrière\"}", "session_id": "7e67ff0b-…"}
← {"messages": [
    {"text": "Bienvenue sur **E-Carrière** !\nSuivez l'évolution de votre carrière en quelques clics.\nPour commencer, avez-vous déjà un compte E-Carrière ?",
     "buttons": [
       {"title": "Oui", "payload": "/confirm_has_account"},
       {"title": "Non", "payload": "/deny_has_account"}
     ], "image": null, "custom": null}
  ]}
```

Afficher : bulle utilisateur **« E-Carrière »** (le titre, pas le payload). Les 3 boutons
de l'étape 2 deviennent inactifs. Nouveaux boutons Oui / Non, saisie toujours bloquée.

**Étape 4 — clic sur « Oui »**

```json
→ {"message": "/confirm_has_account", "session_id": "7e67ff0b-…"}
← {"messages": [
    {"text": "**Parfait, poursuivons la vérification !**\nPour continuer, veuillez renseigner votre numéro de carte nationale d'identité (**CNI**) afin de permettre la vérification de votre compte E-Carrière.\n**À retenir** : votre numéro de CNI doit comporter exactement 13 chiffres.",
     "buttons": [], "image": null, "custom": null}
  ]}
```

Afficher : bulle « Oui », bulle Amath. Pas de bouton → **saisie réactivée** (clavier
numérique proposé, le texte mentionne « CNI »).

**Étape 5 — l'utilisateur tape sa CNI**

```json
→ {"message": "1234567890123", "session_id": "7e67ff0b-…"}
← {"messages": [
    {"text": "Parfait ! Maintenant, j'ai besoin de votre **matricule solde**.\nVotre matricule doit être en MAJUSCULES et sans slash(/)",
     "buttons": [], "image": null, "custom": null}
  ]}
```

**Étape 6 — l'utilisateur tape son matricule** (réponse 4 à 15 s : afficher « Amath écrit… »)

```json
→ {"message": "123456A", "session_id": "7e67ff0b-…"}
← {"messages": [
    {"text": "Enchanté **Awa DIOP**,\n\n- **Matricule :** 123456A\nQue souhaitez-vous faire ?",
     "buttons": [
       {"title": "Voir mes actes", "payload": "/voir_actes"},
       {"title": "Voir mes projets", "payload": "/voir_projets"},
       {"title": "Réinitialiser mot de passe", "payload": "/reset_password_ecarriere"},
       {"title": "Autre vérification", "payload": "/start_account_verification"},
       {"title": "Retour E-Carrière", "payload": "/go_back_ecarriere"},
       {"title": "Menu principal", "payload": "/go_back_greet_with_name"},
       {"title": "Support", "payload": "/ask_support"}
     ], "image": null, "custom": null}
  ]}
```

Si la CNI et le matricule ne correspondent pas, la réponse est un message
« **Nous n'avons pas pu retrouver votre compte.** » avec les boutons Réessayer /
Retour E-Carrière / Support : même traitement, rien de spécial côté app.

**Étape 7 — clic sur « Voir mes actes »**

```json
→ {"message": "/voir_actes", "session_id": "7e67ff0b-…"}
← {"messages": [
    {"text": "**Vos derniers actes, Awa DIOP**\n\n**1. Acte n°12455B10**\nType : Avancement de grade\nÉtat : Initial\nDate : 15/04/2026\nActe pas encore disponible : il n'est pas encore signé",
     "buttons": [
       {"title": "Retour au menu", "payload": "/retour_menu_utilisateur"},
       {"title": "Menu principal", "payload": "/go_back_greet_with_name"}
     ], "image": null, "custom": null}
  ]}
```

« Retour au menu » réaffiche le menu de l'étape 6 ; « Menu principal » celui de
l'étape 2. Le bouton ↻ de l'app recommence à l'étape 1 avec un nouveau `session_id`.

## 7. Erreurs à afficher

| Réponse | Affichage |
|---|---|
| `503 chatbot_unavailable` ou réseau coupé | Bulle « Amath est momentanément indisponible » + bouton « Réessayer » qui renvoie le **même** message |
| `429 too_many_cni_attempts` | Bulle avec le `message` reçu, tel quel |
| `429 too_many_requests` | « Trop de messages, patientez quelques secondes » (attendre `Retry-After`) |
| `422` | Erreur de l'app (message vide ou trop long) : ne pas renvoyer |

Le message utilisateur déjà affiché reste à l'écran dans tous les cas.

## 8. Historique

Conserver localement l'historique affiché (bulles + boutons) et le `session_id` pour
retrouver la conversation à la réouverture de l'app. Le chatbot garde de son côté le
contexte **60 minutes** d'inactivité ; au-delà il repart de zéro : si sa réponse ne
correspond plus à l'historique, proposer « Nouvelle conversation ».

Ne jamais journaliser ni envoyer ailleurs le contenu des messages (CNI, matricule, nom).

## 9. Exemple Flutter (simplifié)

```dart
class ChatbotMessage {
  final String? text;
  final List<ChatbotButton> buttons;
  final String? image;
  ChatbotMessage.fromJson(Map<String, dynamic> json)
      : text = json['text'] as String?,
        image = json['image'] as String?,
        buttons = ((json['buttons'] as List?) ?? [])
            .map((b) => ChatbotButton(b['title'] as String, b['payload'] as String))
            .toList();
}

class ChatbotButton {
  final String title;
  final String payload;
  ChatbotButton(this.title, this.payload);
}

Future<List<ChatbotMessage>> sendToAmath(String message) async {
  final response = await http.post(
    Uri.parse('$apiBaseUrl/chatbot/messages'),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    },
    body: jsonEncode({'message': message, if (sessionId != null) 'session_id': sessionId}),
  ).timeout(const Duration(seconds: 35));

  final body = jsonDecode(response.body) as Map<String, dynamic>;
  if (response.statusCode != 200) {
    throw ChatbotException(response.statusCode, body['code'] as String?, body['message'] as String?);
  }
  sessionId = body['data']['session_id'] as String;
  return (body['data']['messages'] as List).map((m) => ChatbotMessage.fromJson(m)).toList();
}

// Clic sur un bouton : bulle avec le titre, envoi du payload.
void onButtonPressed(ChatbotButton button) {
  addUserBubble(button.title);
  sendAndDisplay(button.payload);
}

// Saisie bloquée tant que le dernier message du chatbot a des boutons.
bool get inputEnabled => !isSending && !(lastBotMessage?.buttons.isNotEmpty ?? false);
```

## 10. Environnements

| Environnement | URL de base | Accès |
|---|---|---|
| Test | `http://10.128.12.71:8080/api/v1` | réseau interne uniquement |
| Production | `https://emploi.fonctionpublique.sn/api/v1` | actif après la mise en production du chatbot |

Interdit dans l'application : les routes `/chatbot/pgde/*` et le secret `CHATBOT_API_TOKEN`
(réservés au serveur du chatbot).
