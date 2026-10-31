# Ela

Compagnon de lecture mobile — **Flutter** (Android + iOS + web), interface littéraire
papier crème, reliure bordeaux et lecture de nuit. Phase 1 : **backend 100 % simulé** (fakes déterministes,
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
flutter test --concurrency=1   # 196 tests, dont le carrousel et 6 goldens
flutter analyze                # zéro issue
```

Pas de caméra ni de réseau en test : la détection test est faite par la
variable d'env `FLUTTER_TEST` (`lib/core/flags.dart`).

## Ce que fait l'app (phase 1)

- **Tendance** — héros coverflow tactile, ambiance issue de la couverture,
  défilement auto avec pause et réduction des animations, transition Hero vers
  la fiche, ajout rapide PAL et rayons horizontaux (top 10, classiques, courts).
  Filtres par catégorie, jour/nuit et repli illustré hors ligne.
- **Scanner** — EAN-13 ISBN (`mobile_scanner`) avec viseur neutre plein écran,
  dégradation propre sans caméra/permission, saisie ISBN en feuille basse ;
  l'ISBN connu ouvre la fiche, l'inconnu est averti.
- **Notation** — demi-étoiles de 0,5 à 5, moyenne communauté, histogramme,
  note personnelle persistée et avis avec texte optionnel ; tri en bibliothèque
  et rayon « Les mieux notés » sur Tendance.
- **Marché** — comparateur neuf/occasion de huit enseignes, total avec port,
  tri par prix ou état, annonces entre lecteurs filtrées par ville, vente
  depuis la bibliothèque et Radar Premium intégré (données simulées).
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


## Refonte « livre » et livrables visuels

**Nouvelle Tendance** : [avant / après](docs/screens/tendance/avant-apres.png) ·
[séquence du carrousel](docs/screens/tendance/sequence-jour.png) ·
[captures et reproduction](docs/screens/tendance/README.md).
Le build `build/web` est servi par le serveur ProxBoss existant sur **:8240**.

[Avant / après](docs/screens/avant-apres.png) ·
[Planche jour](docs/screens/planche-jour.png) ·
[Planche nuit](docs/screens/planche-nuit.png) ·
[Audit et corrections](docs/AUDIT-UI.md) · [Direction artistique](docs/DESIGN.md)

72 captures avant et 120 après, avec vraies polices et icônes, à 412 × 915 dp
(ratio 2,625). La matrice complète passe aussi à 360 × 640 et texte ×1,3.
Le [banc de captures](docs/screens/README.md) documente les commandes, fixtures
et limites. Les paiements, comptes sociaux, prix et données de démo restent
simulés. Les fonctions existantes sont conservées ; la bibliothèque dispose
également d'une vue étagère. Le thème jour/nuit est mémorisé.

```bash
source scripts/env.sh
flutter build web --release --no-web-resources-cdn   # build/web
flutter build apk --release                        # build/app/outputs/flutter-apk/app-release.apk
```

`build/web` est prêt à être servi par ProxBoss, à la racine d'un hôte web.
Aucun serveur n'est lancé par la procédure de livraison. Sur navigateur,
le scanner propose la saisie ISBN ; exemple : `9782070667918`.
Les ressources CanvasKit et les polices sont incluses dans le build ; les
couvertures distantes et Google Books restent des améliorations réseau.
L'APK livré est `dist/ela.apk`, avec la même signature que `v0.1.0`.
La publication GitHub reste à ProxBoss après validation visuelle.

Une seule commande Flutter lourde à la fois sur la machine partagée ;
Gradle sans daemon. Après les tests : `pgrep -x flutter_tester` doit être vide.
La caméra et la fluidité sur appareil physique restent à vérifier sur téléphone.

## Structure

```
lib/
  main.dart                  — bootstrap (prefs → ProviderScope → ElaApp)
  app.dart                   — splash → onboarding (1ʳᵉ fois) → routeur
  providers.dart             — DI Riverpod : services, routes, flag BACKEND
  core/
    design/                  — tokens, papier, ex-libris, cartes et rubans
    theme.dart               — Cormorant Garamond / Literata / Nunito Sans locales
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
    trending/ scanner/ library/ search/ book_detail/ ratings/ market/
    account/ premium/ (paywall, radar, matchmaker)
    onboarding/ splash/ home_shell.dart
test/                        — tests métier, captures et régressions UI
tools/gen_launcher_icon.dart — génère les mipmaps ic_launcher (pur Dart)
scripts/env.sh               — environnement de build
docs/                        — REQUIREMENTS, STACK, ARCHITECTURE
```

Navigation : `go_router` `StatefulShellRoute.indexedStack` — 5 branches
(Tendance / Scanner / Bibliothèque / Recherche / Marché) + routes hors shell
`/livre/:isbn`, `/annonce/:id`, `/compte`, `/premium`, `/match`.
`/marche?isbn=…` ouvre le comparateur ; `/radar` redirige vers
`/marche?vue=radar`. Les [captures v2](docs/screens/v2/README.md) documentent
la notation, le Marché et le scanner, en jour/nuit et au format compact.

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

- Polices : OFL embarquées sous `assets/fonts/`, aucun chargement Google Fonts.
- Couvertures : OpenLibrary (`covers.openlibrary.org`), avec repli visuel
  élégant hors-ligne (dégradé sépia + initiale).
- Prix d'occasion du Radar : fictifs (catalogue démo).
- Signature release : clés debug pour l'instant (`android/app/build.gradle.kts`).
