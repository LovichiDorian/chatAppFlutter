# ChatApp Flutter – Documentation détaillée (FR)

Application de messagerie Flutter avec Firebase (Auth, Firestore, Storage) et une UI moderne. Fonctionne sur le web (Chrome) et mobile (Android/iOS) après configuration.

## Fonctionnalités principales

- Authentification
  - Email/Mot de passe
  - Connexion avec Google (web via popup)
- Messagerie
  - Envoi de texte
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
<<<<<<< HEAD
- Notifications push: supprimées (FCM retiré à la demande)
=======
>>>>>>> 2d6050ad0656d84513efd0f1e01ca1aef59a419c
- Thème
  - UI moderne Material 3
  - Thème clair et sombre (suivant le système)

## Pile technologique

- Flutter 3.x (Material 3)
- Firebase
  - `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`
- État: `provider`
- UI/Utilitaires: `emoji_picker_flutter`, `grouped_list`, `intl`

## Architecture du code

- `lib/models/` – Modèles (ex: `message.dart`, `chat_user.dart`)
- `lib/viewmodel/` – Logique/appels Firebase (ex: `auth_view_model.dart`, `chat_view_model.dart`)
- `lib/pages/` – Écrans (login, signup, home, chat, profil)
- `lib/widgets/` – Widgets réutilisables (bulle de message, item liste)
- `lib/constants.dart` – Couleurs/texte/chemins Firestore
- `lib/firebase_options.dart` – Options Firebase générées par FlutterFire CLI
- `web/manifest.json` – Manifest PWA

## Prérequis

- Flutter installé (3.x recommandé)
- Un projet Firebase configuré
  - Auth (Email/Password + Google si voulu)
  - Firestore et Storage activés

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

Astuce web: après avoir modifié `manifest.json`, fermez l’onglet de l’app et relancez la commande (ou utilisez une fenêtre de navigation privée) pour éviter le cache. (Le service worker FCM a été supprimé.)

## Utilisation

1. Authentification

   - Se connecter avec email/mot de passe
   - Bouton “Continuer avec Google” (web)

2. Discussions

   - Envoyer un message texte
   - Joindre une image via le trombone (pas fonctionnel pour le moment)
   - Appui long sur un message
     - “Supprimer pour moi” (local)
     - “Supprimer pour tous” (global)
   - Les messages sont regroupés par date (Aujourd’hui, Hier, etc.) et l’heure HH:mm s’affiche sous chaque bulle
   - Lazy loading: faites défiler vers le haut pour charger les anciens messages
   - Clavier émoji: bouton “smiley” à côté du composeur

3. Profil

   - Depuis la page de conversation, tapez le titre (avatar/nom) pour afficher le profil de l’autre utilisateur
   - Depuis la page d’accueil, ouvrez votre profil pour modifier nom et bio

## Licence

Dorian Lovichi
