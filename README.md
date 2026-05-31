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
├── main.dart                          # Point d'entrée de l'application
├── app.dart                           # MaterialApp, thème, route initiale
├── constants.dart                     # Constantes globales (AppColors, AppStrings)
├── constants/
│   ├── cinematch_constants.dart       # Constantes du questionnaire CineMatch
│   └── genre_constants.dart          # Liste statique des genres TMDB
├── utils/
│   └── app_router.dart               # Navigation centralisée (fadeRoute, routes)
├── models/                            # Modèles de données avec fromJson / toJson
│   ├── user.dart
│   ├── movie.dart
│   ├── movie_detail.dart
│   ├── movie_credits.dart
│   ├── person.dart
│   ├── genre.dart
│   ├── search_result.dart
│   ├── collection_detail.dart
│   ├── cinematch_question.dart
│   ├── user_movie_action.dart
│   └── trivia_question.dart          # Modèle de question du quiz trivia
├── services/                          # Couche métier — tous en Singleton (factory)
│   ├── storage_service.dart          # Singleton — stockage local JSON (localstorage)
│   ├── auth_service.dart             # Singleton — authentification locale
│   ├── movie_service.dart            # Singleton — appels API TMDB
│   ├── movie_action_service.dart     # Singleton — notes, watchlater, quiz
│   └── share_service.dart            # Singleton — screenshot + partage natif
├── pages/                             # Écrans de l'application
│   ├── splash_page.dart              # Écran de démarrage
│   ├── login_page.dart               # Connexion utilisateur
│   ├── register_page.dart            # Inscription utilisateur
│   ├── home_page.dart                # Hub principal — sections de films par catégorie
│   ├── search_page.dart              # Recherche multi-type + filtres avancés
│   ├── movie_detail_page.dart        # Détail d'un film (crédits, vidéos, images)
│   ├── collection_page.dart          # Timeline d'une saga / collection
│   ├── person_page.dart              # Filmographie d'un acteur ou réalisateur
│   ├── profile_page.dart             # Profil utilisateur et statistiques
│   ├── image_gallery_page.dart       # Galerie plein écran des images d'un film
│   ├── cinematch_page.dart           # Recommandation par questionnaire animé
│   └── trivia_quiz_page.dart         # Quiz trivia basé sur le casting réel TMDB
└── widgets/                           # Composants réutilisables (StatelessWidget)
    ├── movie_card.dart                # Carte film verticale (poster + titre + note)
    ├── movie_row.dart                 # Ligne horizontale scrollable de films
    ├── movie_info_header.dart         # En-tête d'infos film (titre, genres, durée)
    ├── movie_poster_placeholder.dart  # Placeholder quand le poster est absent
    ├── action_buttons.dart            # Boutons noter / watchlater sur un film
    ├── rating_bottom_sheet.dart       # Bottom sheet de notation avec étoiles
    ├── section_title.dart             # Titre de section standardisé
    ├── cast_section.dart              # Liste horizontale du casting
    ├── video_section.dart             # Liste des bandes-annonces (YouTube)
    ├── images_section.dart            # Galerie horizontale des images
    ├── similar_movies_section.dart    # Section films similaires
    ├── collection_header.dart         # En-tête de la page collection / saga
    ├── collection_movie_card.dart     # Carte film dans la timeline de collection
    ├── collection_timeline_dot.dart   # Point de repère dans la timeline
    ├── search_movie_card.dart         # Carte film dans les résultats de recherche
    ├── search_person_card.dart        # Carte personne dans les résultats de recherche
    ├── cinematch_top_bar.dart         # Barre supérieure du questionnaire CineMatch
    ├── cinematch_question_card.dart   # Carte d'une question CineMatch animée
    ├── cinematch_result_card.dart     # Carte du film recommandé par CineMatch
    ├── cinematch_error_card.dart      # Carte d'erreur CineMatch (réseau, aucun film)
    ├── cinematch_progress_bar.dart    # Barre de progression du questionnaire
    ├── cinematch_loading.dart         # Indicateur de chargement CineMatch
    ├── quiz_confirm_dialog.dart       # Dialog de confirmation avant le quiz trivia
    ├── share_card.dart                # Carte de partage de critique (screenshot)
    ├── stats_share_card.dart          # Carte de partage des statistiques profil
    ├── highlight_section.dart         # Section mise en avant (hero ou featured)
    ├── stat_card.dart                 # Carte de statistique individuelle (profil)
    ├── trophy_row.dart                # Ligne de trophée dans le profil
    ├── profile_avatar.dart            # Avatar utilisateur avec initiales
    ├── empty_state.dart               # Écran vide générique (aucun résultat)
    └── error_list.dart                # Liste d'erreurs de validation (formulaires)
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