# CINEART

Binome:EDDOUSSI Mohamed-BERDAI Aymane.

Application mobile de découverte et de gestion de films, développée avec Flutter dans le cadre du projet de développement mobile (M1 MIAGE, Université Grenoble Alpes).

***

## Fonctionnalités

- Consultation des films tendance, à l'affiche, les mieux notés et à venir
- Recherche de films et de personnalités (acteurs, réalisateurs)
- Découverte par genre avec filtres avancés (note minimale, année, durée)
- Fiche détaillée d'un film : synopsis, crédits, bande-annonce YouTube, films similaires, collection(on arrive à voire les sequels d'un film si ils existent dans un timeline)
- Fiche détaillée d'une personnalité : biographie, filmographie en tant qu'acteur et réalisateur
- Notation personnelle d'un film (0 à 10) avec critique textuelle
- Liste de films à voir plus tard
- Quiz cinématographique par film avec système de trophées (Bronze, Argent, Or, Platine)
- Recommandation personnalisée via CineMatch (questionnaire d'humeur)
- Statistiques annuelles : moyenne des notes, distribution, genre / acteur / réalisateur le plus regardé
- Partage d'une critique ou de ses statistiques annuelles sous forme d'image
- Authentification locale (inscription, connexion, déconnexion) avec mot de passe haché (SHA-256)
- Persistance des données par utilisateur via stockage local


***

## Structure du projet

```
lib/
├── main.dart                        # Point d'entrée de l'application
├── constants/                       # Constantes globales (clés API, URLs, paramètres CineMatch)
│   ├── app_constants.dart
│   └── cinematch_constants.dart
├── models/                          # Modèles de données
│   ├── user.dart
│   ├── movie.dart
│   ├── movie_detail.dart
│   ├── movie_credits.dart
│   ├── person.dart
│   ├── genre.dart
│   ├── search_result.dart
│   ├── collection_detail.dart
│   ├── cinematch_question.dart
│   └── user_movie_action.dart
├── services/                        # Couche métier et accès aux données
│   ├── storage_service.dart         # Singleton — stockage local (localstorage)
│   ├── auth_service.dart            # Singleton — authentification locale
│   ├── movie_service.dart           # Singleton — appels API TMDB
│   ├── movie_action_service.dart    # Singleton — actions utilisateur par film
│   └── share_service.dart           # Singleton — partage d'images
└── pages/                           # Ecrans de l'application
    ├── home_page.dart
    ├── login_page.dart
    ├── register_page.dart
    ├── movie_detail_page.dart
    ├── person_detail_page.dart
    ├── search_page.dart
    ├── discover_page.dart
    ├── profile_page.dart
    ├── stats_page.dart
    ├── watch_later_page.dart
    ├── trophies_page.dart
    └── cinematch_page.dart
```

***

## Architecture

Tous les services suivent le pattern **Singleton** via un constructeur `factory` et un constructeur nommé `_internal()`, conformément aux principes vus en cours. La dépendance à `StorageService` est injectée dans `AuthService` et `MovieActionService` via un constructeur `@visibleForTesting` pour permettre les tests unitaires sans dépendre du plugin natif.

Les modèles sont immutables (`final`), dotés d'un factory constructor `fromJson` pour le parsing HTTP et d'une méthode `toJson` pour la sérialisation vers le stockage local.

Aussi Le programme consome L'API 'TMDB' source:https://developer.themoviedb.org/docs/getting-started
***

## Packages utilisés

| Package | Utilisation |
|---|---|
| `http` | Appels à l'API TMDB |
| `localstorage` | Persistance locale des données utilisateur |
| `crypto` | Hachage SHA-256 des mots de passe |
| `url_launcher` | Ouverture des bandes-annonces YouTube |
| `share_plus` | Partage d'images (critiques, statistiques) |
| `screenshot` | Capture de widgets Flutter en image |
| `path_provider` | Accès au répertoire temporaire pour l'export |

***

## Lancer le projet

```bash
flutter pub get
flutter run
```

Tester sur émulateur Android ou iOS. L'application nécessite une connexion Internet pour accéder à l'API TMDB.

***

## Tests

Commande pour lancer les tests
```bash
flutter test test/services
flutter test test/models
```

Les tests unitaires couvrent `AuthService` (inscription, connexion, déconnexion, persistance) et `MovieActionService` (notation, review, watchLater, quiz, statistiques annuelles). Ils utilisent un `FakeStorageService` en mémoire pour s'exécuter sans dépendance au plugin natif.

***

Projet réalisé en binôme dans le cadre du cours Développement Mobile de Jules Dommartin, 
M1 MIAGE - Université Grenoble Alpes, 2025-2026.