# Firebase — Phase 2

Ce dossier est **vide en phase 1** : tout le backend est stubé par
`lib/data/fake/`. Quand le projet Firebase sera provisionné, les
implémentations réelles s'ajouteront ici **sans toucher à l'UI** :

```
lib/data/firebase/
  firebase_services.dart        — initialisation (FirebaseApp, Auth, Firestore)
  firebase_auth_service.dart    — AuthService : anneau → linkWithCredential (e-mail, Google, Apple)
  firebase_book_repository.dart — BookLookupService : Google Books API + cache Firestore books/{isbn}
  firebase_curation_service.dart— CurationService : callable curateBook(isbn), cache + refresh hebdo
  firebase_review_service.dart  — ReviewService : collection books/{isbn}/reviews/{id}
  firebase_library_service.dart — LibraryService : users/{uid}/library/{isbn}
  firebase_payment_service.dart — PaymentService : RevenueCat → users/{uid} (entitlement, aiTokens)
  firebase_trend_service.dart   — TrendService : Firestore + Remote Config (catégories, poids)
  firebase_moderation_service.dart — ModerationService : trigger onCreate (IA)
```

Rappel du schéma Firestore prévu (voir `docs/ARCHITECTURE.md`) :
- `books/{isbn}` : métadonnées, `curated: {summary, press[5], web[15]}`, `curatedAt`, `readersCount`, `popularityBadge`
- `books/{isbn}/reviews/{id}` : avis communauté (modérés)
- `users/{uid}` : profil, entitlement, aiTokens ; `users/{uid}/library/{isbn}` (history|tbr, addedAt)
- Cloud Functions : `curateBook` (callable), `weeklyRefresh` (scheduler), `moderateReview` (trigger)

Le commutateur de sélection est centralisé dans `lib/providers.dart`
(flag `--dart-define=BACKEND=fake|firebase`).
