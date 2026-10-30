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
- **Étape 2 — Scanner**
  - Caméra `mobile_scanner` 7.4.2 (EAN-13, objectif arrière, démarrage différé hors tests) ; détection → arrêt caméra, **haptique battement de cœur**, couverture qui « lévite » (glisse + grandit + halo doré pulsé) 1,2 s puis ouverture de la fiche.
  - Halo « lampe de chevet » (`_LampHaloOverlay`) : cadre doré arrondi qui respire, aucun laser rouge.
  - États gérés : démarrage, scan, identifié, livre introuvable (retry), permission refusée (explication + retry), caméra indisponible.
  - Saisie manuelle d'ISBN (13 chiffres) avec bouton « Chercher » + spinner ; sur écran sans caméra/permission refusée, le bloc saisie est mis en avant.
  - Recherche ISBN : catalogue local 18 livres d'abord (cohérence avec la curation démo), sinon **API publique Google Books** (`lib/core/google_books_client.dart`, timeout 4–5 s, toute erreur → null) ; sinon « livre introuvable ».
  - Détection test vs prod : `lib/core/flags.dart` → `isRunningUnderFlutterTest` = `Platform.environment['FLUTTER_TEST'] == 'true'` (`flutter test` définit une **variable d'env**, pas un `--dart-define` : `bool.fromEnvironment` ne la voit pas — vérifié empiriquement).
  - Tests : `test/scanner_test.dart` (3 tests : dégradation sans caméra, ISBN connu → fiche, ISBN inconnu → avertissement) ; app_test adapté. 5 tests au total, tous verts.

- **Étape 3 — Fiche livre**
  - En-tête : couverture, titre (Lora), auteur, éditeur/année, badge popularity, « X lecteurs d’Ela », description, prix, boutons **Ajouter à la PAL** (toggle, haptique) et **Acheter** (lien affilié fictif via `PaymentService`).
  - 3 onglets en fondu doux (`AnimatedSwitcher` 420 ms, soulignement doré animé) : **Synthèse IA & Presse** (carte « Synthèse Ela » + compteur « ✦ N jetons IA ce mois-ci » + 5 avis presse curés), **Le Web** (15 avis), **La Communauté** (avis illimités, ajout d’avis, bouton Signaler).
  - Pendant la curation simulée (délais fake 0,9–1,6 s) : **texte qui respire + squelettes « encre »**, jamais de spinner.
  - Avis : carte avec auteur/outlet/date, titre serif, texte rogné « Lire la suite » (AnimatedSize), likes ; Signaler → `ReviewService.reportReview` + snack.
  - Ajout d’avis : bottom sheet ; **lazy registration** — profil anonyme → invite « Votre avis mérite un nom » + bouton « Créer mon compte » (navigation branchée à l’étape 6).
  - Ouvrir une fiche = ajout à l’Historique (`LibraryService.addHistory`) pour l’étape 4.
  - Providers Riverpod : `bookByIsbnProvider`, `curationProvider` (family, cache par ISBN), `communityReviewsProvider`, `libraryEntriesProvider`.
  - Tests : `test/book_detail_test.dart` (5 tests, viewport téléphone 390×844@3x — le viewport 800×600 par défaut est trop court pour cette fiche) ; 10 tests au total, tous verts.

- **Étape 4 — Ma Bibliothèque**
  - **Vol de couverture** (`lib/features/library/fly_to_library.dart`) : à l’ajout PAL depuis la fiche, une `OverlayEntry` (navigateur racine, 780 ms, `easeInCubic`) fait glisser une couverture « allégée » (dégradé + initiale + halo doré pulsé, zéro réseau) en arc par-dessus l’UI, du rect de la couverture vers l’icône Bibliothèque ; à l’atterrissage la barre « reçoit » (`FlyToLibraryController.receiving` 520 ms) : l’icône s’élargit + scale 1.12 + fond doré, puis s’efface. `ChangeNotifierProvider` depuis `flutter_riverpod/legacy.dart` (riverpod 3).
  - Positionnement par `Transform.translate` + `Align` : **`Positioned` est interdit dans le sous-arbre d’un `OverlayEntry`** en 3.35 (ParentDataWidget levé) ; suppression via `entry.remove()` ; pas de `lerp` top-level (locale `_lerp`).
  - `library_screen.dart` : lecture via `libraryEntriesProvider` (pas de `StreamBuilder`), Historique (tag **Passif**) et PAL (tag **Active**) triés **chronologiquement** (le plus récent d’abord), compteurs par section, état vide « Votre bibliothèque est vide » + CTA scanner.
  - **Bug produit corrigé** : `FakeLibraryService.watchEntries()` émettait l’état initial au `StreamController.broadcast` **avant** l’abonnement du `StreamProvider` → événement perdu → bibliothèque vide jusqu’à la 1ʳᵉ modification. Désormais chaque abonnement reçoit d’abord un instantané (`Stream.multi`).
  - Tests : `test/library_test.dart` (2 tests : sections/tags/tri chronologique déterministe via prefs pré-chargées avec horodatages explicites ; vol + réception de la barre + entrée PAL persistée). 12 tests au total, tous verts, build APK debug OK.

## En cours
- (rien — étape 4 terminée, en attente d'étape 5)

## Reste
- Étape 5 — Tendance & Recherche : animations des résultats.
- Étape 6 — Comptes : lazy registration (e-mail/Google/Apple stubs), profil, déconnexion.
- Étape 7 — Freemium : gating 1 avis presse + 2 web (flouté au-delà), 3 jetons IA/mois, Premium 2 €/mois, Radar à économies, MatchMaker, paywall.
- Étape 8 — Finitions : onboarding 3 écrans, icône + splash, accessibilité, tests widget des écrans clés, README.
- Étape 9 — Livraison : `flutter build apk --release` (signature debug) → `dist/ela.apk` + commit final.

## Décisions
- **Riverpod 3.3 / go_router 17** installés par Flutter 3.35 : API adaptées (`AsyncValue.when` + `.value` (pas de `.valueOrNull`), `Notifier` au lieu de `StateProvider` (passé en legacy dans riverpod 3), `StatefulShellRoute.indexedStack` + `currentIndex`/`goBranch(int)`, `MaterialApp.router(routerConfig:)`, `BuildContext.mounted` disponible).
- **Fiche livre défilable d’un bloc** (en-tête + onglets + contenu dans un seul `SingleChildScrollView`) : la variante « en-tête + barre d’onglets fixes » déborde dès que la description est longue (vérifié au layout).
- **Couvertures** : URL OpenLibrary `covers.openlibrary.org/b/id/<id>-M.jpg` (ISBN vérifiés via l’API) ; repli visuel élégant (dégradé sépia + initiale) si hors-ligne.
- **Jetifier OFF** (voir Fait) : exigence RAM du conteneur.
- **Flutter 3.35 — overlay** : `Positioned` ne peut pas appliquer sa `StackParentData` dans le sous-arbre d’un `OverlayEntry` (erreur levée au layout) → positionner avec `Transform.translate` (+ `Align`) ; `OverlayEntry.remove()` est la méthode de suppression ; pas de fonction `lerp` globale (écrire la sienne).
- **Google Books** : branché à l’étape 2 — `GoogleBooksClient.fetchByIsbn` (API publique sans clé, timeout 4–5 s, toute erreur → null) ; le catalogue local répond d’abord pour garder curation/avis cohérents.
- **Tests** : `GoogleFonts.config.allowRuntimeFetching = false` + horloge factice avancée à la main (les délais fake sont des `Future.delayed`) ; jamais de réseau ni de caméra en test (garde `isRunningUnderFlutterTest` = variable d’env `FLUTTER_TEST`, **pas** un `--dart-define`).
