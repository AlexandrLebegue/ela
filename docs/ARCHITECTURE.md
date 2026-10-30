# Architecture cible — Ela

```
lib/
  main.dart / app.dart          thème cocooning, go_router, ProviderScope
  core/                         thème (couleurs papier/sépia + nuit), typographie, haptique, animations communes
  data/
    models/                     Book, Review(source: press|web|community), Library entry, UserProfile, Entitlement
    services/ (interfaces)      AuthService, BookLookupService (ISBN), CurationService (avis IA), ReviewService,
                                LibraryService, PaymentService, TrendService, ModerationService
    fake/                       implémentations locales (délais simulés, données de démo FR) — PHASE 1
    firebase/                   implémentations réelles — PHASE 2 (vide pour l'instant)
  features/
    trending/  scanner/  library/ (historique + PAL)  search/  book_detail/ (3 onglets)  account/  paywall/
```
- Injection via Riverpod : un seul fichier `providers.dart` choisit Fake vs Firebase (flag `--dart-define=BACKEND=fake|firebase`).
- Lazy registration : AuthService.fake démarre en utilisateur anonyme ; l'inscription « lie » le compte.
- Flux scan : caméra → ISBN → BookLookupService (Google Books réel autorisé, sinon fake) → CurationService (cache) → fiche livre.
- Gating freemium : Entitlement {free, premium}, jetons IA (3/mois), floutage des avis au-delà de 1 presse / 2 web.

## Firestore (prévision phase 2)
- `books/{isbn}` : métadonnées, `curated: {press[5], web[15], summary}`, `curatedAt`, `readersCount`, `popularityBadge`
- `books/{isbn}/reviews/{id}` : avis communauté (modérés)
- `users/{uid}` : profil, entitlement, aiTokens, `library/{isbn}` (history|tbr, addedAt)
- Function `curateBook(isbn)` (callable), `weeklyRefresh` (scheduler), `moderateReview` (trigger onCreate)
