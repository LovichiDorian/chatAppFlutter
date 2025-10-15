# ChatApp Flutter – Documentation détaillée (FR)

Application de messagerie Flutter avec Firebase (Auth, Firestore, Storage, Messaging) et une UI moderne. Fonctionne sur le web (Chrome) et mobile (Android/iOS) après configuration.

## Fonctionnalités principales

- Authentification
  - Email/Mot de passe
  - Connexion avec Google (web via popup)
- Messagerie
  - Envoi de texte et d’images (Firebase Storage)
  - Suppression de message
    - Pour moi (local): masque le message pour l’utilisateur courant
    - Pour tous (global): remplace par “Message supprimé” et supprime le média
  - Groupement par date (Aujourd’hui, Hier, date en français)
  - Heure d’envoi affichée sous chaque message
  - Lazy loading: chargement progressif des messages anciens
  - Émojis: clavier intégré avec bouton de bascule
- Profils
  - Affichage du profil d’autrui depuis la page de conversation
  - Édition du profil utilisateur (nom, bio)
- Notifications push (FCM)
  - Permissions + token enregistré dans Firestore
  - Service worker pour notifications en arrière-plan sur le web
- Thème
  - UI moderne Material 3
  - Thème clair et sombre (suivant le système)

## Pile technologique

- Flutter 3.x (Material 3)
- Firebase
  - `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_messaging`
- État: `provider`
- UI/Utilitaires: `emoji_picker_flutter`, `grouped_list`, `intl`

## Architecture du code

- `lib/models/` – Modèles (ex: `message.dart`, `chat_user.dart`)
- `lib/viewmodel/` – Logique/appels Firebase (ex: `auth_view_model.dart`, `chat_view_model.dart`)
- `lib/pages/` – Écrans (login, signup, home, chat, profil)
- `lib/widgets/` – Widgets réutilisables (bulle de message, item liste)
- `lib/constants.dart` – Couleurs/texte/chemins Firestore et config Notifications
- `lib/firebase_options.dart` – Options Firebase générées par FlutterFire CLI
- `web/firebase-messaging-sw.js` – Service worker FCM (Web)
- `web/manifest.json` – Manifest PWA (inclut gcm_sender_id)

## Prérequis

- Flutter installé (3.x recommandé)
- Un projet Firebase configuré
  - Auth (Email/Password + Google si voulu)
  - Firestore et Storage activés
  - Cloud Messaging activé (pour notifications)

## Installation

1. Installer les dépendances

```powershell
flutter pub get
```

2. Configurer Firebase (toutes plateformes nécessaires)

- Utilisez FlutterFire CLI pour générer `lib/firebase_options.dart`:

```powershell
flutterfire configure
```

- Android: placez `android/app/google-services.json` (si cible Android)
- iOS: placez `ios/Runner/GoogleService-Info.plist` (si cible iOS)
- Web:
  - Le service worker FCM est déjà présent: `web/firebase-messaging-sw.js`
  - Le manifest inclut `"gcm_sender_id": "103953800507"` (requis par FCM web)

3. VAPID key pour notifications Web

- Ouvrez `lib/constants.dart` et définissez votre clé publique VAPID:

```dart
class Notifications {
	static const String? webVapidKey = "VOTRE_CLE_VAPID_PUBLIQUE";
}
```

Vous trouverez la clé dans Firebase Console > Project Settings > Cloud Messaging > Web Push certificates.

4. Règles Firestore/Storage (exemples de base pour dev)

Firestore (exemple permissif pour utilisateurs connectés):

```js
service cloud.firestore {
	match /databases/{database}/documents {
		match /chats/{chatId}/messages/{msgId} {
			allow read, write: if request.auth != null;
		}
		match /users/{uid} {
			allow read: if request.auth != null;
			allow write: if request.auth != null && request.auth.uid == uid;
		}
	}
}
```

Storage (exemple permissif pour utilisateurs connectés):

```js
rules_version = '2';
service firebase.storage {
	match /b/{bucket}/o {
		match /{allPaths=**} {
			allow read, write: if request.auth != null;
		}
	}
}
```

Adaptez ces règles à vos besoins avant de passer en production.

## Lancer l’application

Web (Chrome):

```powershell
flutter run -d chrome
```

Android ou iOS: branchez un appareil ou démarrez un émulateur et utilisez `flutter run`.

Astuce web: si vous modifiez `manifest.json` ou le service worker, fermez l’onglet de l’app et relancez la commande (ou utilisez une fenêtre de navigation privée) pour éviter le cache.

## Utilisation

1. Authentification

   - Se connecter avec email/mot de passe
   - Bouton “Continuer avec Google” (web)

2. Discussions

   - Envoyer un message texte
   - Joindre une image via le trombone (upload vers Storage)
   - Appui long sur un message
     - “Supprimer pour moi” (local)
     - “Supprimer pour tous” (global)
   - Les messages sont regroupés par date (Aujourd’hui, Hier, etc.) et l’heure HH:mm s’affiche sous chaque bulle
   - Lazy loading: faites défiler vers le haut pour charger les anciens messages
   - Clavier émoji: bouton “smiley” à côté du composeur

3. Profil

   - Depuis la page de conversation, tapez le titre (avatar/nom) pour afficher le profil de l’autre utilisateur
   - Depuis la page d’accueil, ouvrez votre profil pour modifier nom et bio

4. Notifications (web)
   - Au premier lancement, acceptez la permission
   - Le token FCM de l’utilisateur est stocké dans `users/{uid}.fcmTokens`
   - Envoyez un test depuis Firebase Console vers ce token pour vérifier la réception

## Dépannage (Troubleshooting)

- Image non envoyée / non visible

  - Vérifiez les règles Storage/Firestore
  - Regardez la console: une erreur explicite est affichée en SnackBar
  - Assurez-vous que l’utilisateur est connecté

- Notifications web non reçues

  - Vérifiez que `Notifications.webVapidKey` est bien renseignée
  - Vérifiez `web/manifest.json` (gcm_sender_id) et la présence du service worker
  - Essayez en navigation privée pour éviter l’ancien service worker

- Erreurs “DWDS / Timer not supported on web”
  - Ce sont des logs de l’outillage de debug. L’app peut fonctionner malgré ces messages.

## Feuille de route (Roadmap)

- Appels audio/vidéo (Agora SDK ou WebRTC)
- Notifications locales en foreground sur mobile (flutter_local_notifications)
- Avatar utilisateur dans la liste des messages (avec `avatarUrl`)
- Tests unitaires et d’intégration

## Avertissements

- Ne commitez pas de secrets (clés privées) dans le dépôt
- Les règles de sécurité Firebase proposées ici sont des exemples pour le développement

## Licence

Projet académique/démo. Ajoutez votre licence si nécessaire.
