# PROGRESS — Ela

Avancement par étapes du plan `PROMPT.md`. À chaque étape : `flutter analyze`
sans erreur, `flutter test` vert, `flutter build apk --debug` OK, puis commit.

## Fait
- **Étape 1 — Socle**
  - `flutter create --org com.alexandrelebegue --project-name ela --platforms android,ios`
  - `scripts/env.sh` (PATH Flutter, JAVA_HOME=jdk17, ANDROID_HOME) ; source avant chaque commande flutter.
  - Packages : flutter_riverpod 3.3, go_router 17, mobile_scanner, cached_network_image, google_fonts, shared_preferences.
  - Gradle : `org.gradle.jvmargs=-Xmx2g`, `org.gradle.daemon=false`, **jetifier désactivé** (dépendances 100 % AndroidX ; le jetifier explosait la RAM du conteneur).
  - Thème « cocooning » (`lib/core/theme.dart`) : jour = papier/sépia coquille d’œuf, nuit = bleu nuit/sépia, accents or/ambre ; titres en serif Lora, corps en Nunito Sans (Google Fonts).
  - Haptique « battement de cœur » (`lib/core/haptics.dart`) ; animations douces : texte qui respire, squelettes « encre », cross-fade (`lib/core/animations.dart`).
  - Navigation : go_router `StatefulShellRoute.indexedStack` — 4 entrées (Tendance / Scanner en bouton central doré mis en avant / Bibliothèque / Recherche) ; route `/livre/:isbn` hors shell.
  - Modèles : `Book` (badge popularité 🔥📈💎🏺, lecteurs d’Ela), `Review` (press/web/community), `CurationResult`, `LibraryEntry` (history/toRead), `UserProfile` (anonyme par défaut), `Entitlement` (free/premium + jetons IA).
  - Interfaces de services : Auth, BookLookup, Curation, Review, Library, Payment, Trend, Moderation.
  - Fakes (délais 300–1500 ms) : catalogue FR de 18 livres (classiques + contemporains + thrillers + fantasy) avec couvertures réelles OpenLibrary (vérifiées 200 OK) ; avis presse/web/communauté générés de façon déterministe ; bibliothèque persistée en SharedPreferences ; entitlement/jetons persistés ; modération par liste de mots.
  - `lib/data/firebase/README.md` : ce qui ira dans ce dossier en phase 2.
  - `providers.dart` : sélection `--dart-define=BACKEND=fake|firebase` (défaut fake ; firebase = UnimplementedError pointant le README).
  - Écrans socle : Tendance (catégories + listes + squelettes), Scanner (halo lampe de chevet + saisie ISBN manuelle), Bibliothèque (Historique + PAL, persistance locale, état vide), Recherche (debounce, résultats), fiche livre (en-tête, badge, lecteurs, PAL/Acheter).
  - Tests : `test/app_test.dart` (barre 4 entrées + navigation).
  - Android : permission CAMERA + uses-feature non obligatoire, label « Ela ».

## En cours
- **Étape 2 — Scanner** : caméra `mobile_scanner` EAN-13/ISBN, halo doré, haptique battement de cœur à la détection, lévitation de la couverture avant ouverture de la fiche ; garde la saisie manuelle ; gestion propre du refus de la permission caméra.

## Reste
- Étape 3 — Fiche livre : 3 onglets en fondu (Synthèse IA & Presse : synthèse + 5 avis ; Le Web : 15 avis ; La Communauté : illimité + ajout d’avis + Signaler), curation simulée avec texte qui respire.
- Étape 4 — Ma Bibliothèque : animation d’ajout PAL (couverture glisse vers l’icône de la barre qui s’élargit).
- Étape 5 — Tendance & Recherche : animations des résultats.
- Étape 6 — Comptes : lazy registration (e-mail/Google/Apple stubs), profil, déconnexion.
- Étape 7 — Freemium : gating 1 avis presse + 2 web (flouté au-delà), 3 jetons IA/mois, Premium 2 €/mois, Radar à économies, MatchMaker, paywall.
- Étape 8 — Finitions : onboarding 3 écrans, icône + splash, accessibilité, tests widget des écrans clés, README.
- Étape 9 — Livraison : `flutter build apk --release` (signature debug) → `dist/ela.apk` + commit final.

## Décisions
- **Riverpod 3.3 / go_router 17** installés par Flutter 3.35 : API adaptées (`AsyncValue.when`, `Notifier` au lieu de `StateProvider` (passé en legacy dans riverpod 3), `StatefulShellRoute.indexedStack` + `currentIndex`/`goBranch(int)`, `MaterialApp.router(routerConfig:)`).
- **Couvertures** : URL OpenLibrary `covers.openlibrary.org/b/id/<id>-M.jpg` (ISBN vérifiés via l’API) ; repli visuel élégant (dégradé sépia + initiale) si hors-ligne.
- **Jetifier OFF** (voir Fait) : exigence RAM du conteneur.
- **Google Books** : l’appel réel de l’API (recherche ISBN) sera branché à l’étape 2 avec repli sur le catalogue fake.
- **Tests** : `GoogleFonts.config.allowRuntimeFetching = false` + horloge factice avancée à la main (les délais fake sont des `Future.delayed`).
