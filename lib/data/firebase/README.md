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

## Notation (v2)

`RatingService` sépare les notes des avis : `books/{isbn}/ratings/{uid}`
contient `value` (0,5…5 par pas de 0,5). Une écriture remplace la note de
cet utilisateur ; une suppression retire aussi son avis. Les agrégats
(moyenne, total, histogramme des tranches supérieures 1…5) doivent être
mis à jour atomiquement côté serveur. Les avis ajoutent `userId` et `rating` ;
le texte et le titre sont optionnels. Les notes presse/web sont normalisées
sur 5 seulement si la source fournit une note. Les anciennes données sans
note restent lisibles. Le fake conserve les notes et avis personnels dans
SharedPreferences et génère des votes de démonstration déterministes.

## Marché (v2)

`MarketService.offers(isbn)` fournit les offres (enseigne, prix, port, état).
Les prix sont explicitement simulés ; le tri compare le total, puis l’état
si ce choix est activé. `PaymentService.affiliatePurchaseLink` reste le point
d’entrée des liens affiliés, avec l’enseigne dans les paramètres.
`market/listings/{id}` pourra stocker les champs de `ReaderListing` ;
`watchListings`, `publish` et `contact` isolent le backend. L’UI filtre les
annonces par ville choisie, sans géolocalisation. La photo optionnelle est
une URL HTTPS, à remplacer par un upload Storage lors du branchement réel.
Le fake persiste les annonces sur l’appareil ; le contact est simulé et
n’envoie aucun message. Le Radar Premium est une vue du Marché ; `/radar`
redirige vers `/marche?vue=radar` pour conserver les anciens accès.
