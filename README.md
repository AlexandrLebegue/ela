# Ela

Compagnon de lecture mobile — **Flutter** (Android + iOS), thème « cocooning »
papier/sépia/or. Phase 1 : **backend 100 % simulé** (fakes déterministes,
zéro compte, zéro réseau pour le cœur) ; phase 2 : Firebase (voir ci-dessous).

## Lancer

```bash
source scripts/env.sh          # PATH Flutter, JDK 17, ANDROID_HOME
flutter pub get
flutter run                    # ou : flutter run -d <serial>
flutter build apk --debug      # → build/app/outputs/flutter-apk/app-debug.apk
```

> Le build est taillé pour des machines modestes : Gradle `-Xmx2g`,
> `--no-daemon`, jetifier désactivé (dépendances 100 % AndroidX).

### Tests

```bash
flutter test                   # 29 tests (app, scanner, fiche, bibliothèque,
                               # tendance/recherche, compte, freemium, onboarding)
flutter analyze                # zéro issue
```

Pas de caméra ni de réseau en test : la détection test est faite par la
variable d'env `FLUTTER_TEST` (`lib/core/flags.dart`).

## Ce que fait l'app (phase 1)

- **Tendance** — listes par catégorie, rangs N°1-3 dorés, apparition en
  cascade, squelettes « encre » pendant la curation simulée.
- **Scanner** — EAN-13 (`mobile_scanner`) avec halo « lampe de chevet »,
  dégradation propre sans caméra/permission, saisie ISBN manuelle ;
  l'ISBN connu ouvre la fiche, l'inconnu est averti.
- **Fiche livre** — couverture, badge de popularité, lecteurs d'Ela,
  synthèse IA + 5 avis presse, 15 avis web, avis communauté (ajout,
  signalement), PAL / Acheter (lien affilié simulé).
- **Ma Bibliothèque** — Historique (Passif) et Pile à Lire (Active) triés
  chronologiquement, persistés localement ; la couverture « vole » vers la
  barre d'onglets à chaque ajout PAL.
- **Comptes (lazy registration)** — anonyme par défaut ; le compte est
  demandé uniquement quand on le faut (publier un avis, acheter, cloud) :
  e-mail avec validation douce, Google/Apple (stubs).
- **Freemium** — gratuit : 1 avis presse + 2 avis web (le reste flouté),
  3 jetons IA/mois pour débloquer une fiche ; Premium 2 €/mois (simulé) :
  tout visible, avis étrangers « traduits par Ela », **Radar à économies**
  (top 6 occasions), **MatchMaker** (scores de compatibilité d'après votre
  étagère), **Bilan de curiosité** + export CSV.
- **Finitions** — splash de marque, onboarding 3 écrans (une seule fois),
  accessibilité (contrastes, labels semantics, tailles de texte), icône
  Ela (adaptive icon + mipmaps générées par `tools/gen_launcher_icon.dart`).

## Structure

```
lib/
  main.dart                  — bootstrap (prefs → ProviderScope → ElaApp)
  app.dart                   — splash → onboarding (1ʳᵉ fois) → routeur
  providers.dart             — DI Riverpod : services, routes, flag BACKEND
  core/
    theme.dart               — couleurs/typo « cocooning » (Lora + Nunito Sans)
    animations.dart          — BreathingText, squelettes, StaggeredReveal…
    haptics.dart             — « battement de cœur »
    flags.dart               — détection flutter test (variable d'env)
    format.dart              — prix, dates, normalisation de requête
    google_books_client.dart — API publique (repli du scanner)
  data/
    models/                  — Book, Review, CurationResult, Entitlement…
    services/                — interfaces (Auth, Curation, Payment, …)
    fake/                    — fakes phase 1 : catalogue 18 livres, avis
                               déterministes, bibliothèque, entitlement…
    firebase/README.md       — ce qui arrive en phase 2 (schéma, fichiers)
  features/
    trending/ scanner/ library/ search/ book_detail/
    account/ premium/ (paywall, radar, matchmaker)
    onboarding/ splash/ home_shell.dart
test/                        — 8 fichiers, 29 tests widget
tools/gen_launcher_icon.dart — génère les mipmaps ic_launcher (pur Dart)
scripts/env.sh               — environnement de build
docs/                        — REQUIREMENTS, STACK, ARCHITECTURE
```

Navigation : `go_router` `StatefulShellRoute.indexedStack` — 4 branches
(Tendance / Scanner / Bibliothèque / Recherche) + routes hors shell
`/livre/:isbn`, `/compte`, `/premium`, `/radar`, `/match`.

## Brancher Firebase (phase 2)

L'UI ne change pas : tout passe par les interfaces de `lib/data/services/`.
Les implémentations réelles s'ajouteront dans `lib/data/firebase/` (contenu
prévu détaillé dans `lib/data/firebase/README.md`) puis on commutera :

```
flutter run --dart-define=BACKEND=firebase
```

- **Auth** : e-mail/mot de passe, Google, Apple → `linkWithCredential`.
- **Books** : Google Books API + cache `books/{isbn}` (curation : synthèse
  IA, 5 presse, 15 web, refresh hebdo par Cloud Function).
- **Avis** : `books/{isbn}/reviews/{id}`, modération par trigger IA.
- **Bibliothèque** : `users/{uid}/library/{isbn}` (history | toRead).
- **Freemium** : RevenueCat → `users/{uid}` (entitlement, jetons IA/mois).
- **Tendances** : Firestore + Remote Config (catégories, pondérations).

## Notes

- Couvertures : OpenLibrary (`covers.openlibrary.org`), avec repli visuel
  élégant hors-ligne (dégradé sépia + initiale).
- Prix d'occasion du Radar : fictifs (catalogue démo).
- Signature release : clés debug pour l'instant (`android/app/build.gradle.kts`).
