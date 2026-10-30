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

- **Étape 5 — Tendance & Recherche (animations)**
  - `StaggeredReveal` (`lib/core/animations.dart`) : chaque ligne apparaît (fondu + glisse 14 px, 420 ms `easeOutCubic`) avec un décalage de 70 ms par rang (plafonné au rang 7) ; `Timer` annulable au dispose (pas de timer orphelin si la ligne est démontée avant son tour).
  - Tendance : `AnimatedSwitcher` sur la liste (skeleton → liste, et au changement de catégorie : les deux listes fondent l'une dans l'autre) ; rangs **N°1-3 dorés gras**, rangs suivants en gris tabulaire.
  - Recherche : `AnimatedSwitcher` hint ↔ résultats (clé par requête → chaque nouvelle recherche refait la cascade) ; squelettes pendant le debounce 350 ms + la recherche (250–900 ms).
  - Tests : `test/trending_search_test.dart` (3 tests : squelettes → cascade + rangs + changement de catégorie ; recherche par auteur + clear ; aucun résultat). 15 tests au total, tous verts, build debug OK.

- **Étape 6 — Comptes (lazy registration)**
  - Écran `/compte` (`lib/features/account/account_screen.dart`) : anonyme → « Bienvenue chez Ela » + explication (compte demandé seulement pour : publier un avis, cloud, payer) + formulaire e-mail/mot de passe avec validation douce (erreurs en texte, pas de rouge agressif) + boutons Google et Apple (stubs) ; connecté → avatar initiale doré, nom, e-mail, badge « Membre d’Ela », carte « bibliothèque locale / cloud simulé », **Se déconnecter** (purge le profil, ne touche pas la bibliothèque locale).
  - Déclencheurs : « Créer mon compte » dans la feuille d'avis (ferme la feuille puis `push('/compte')`) ; **Acheter** sur la fiche quand on est anonyme ; icône profil dans l'en-tête Bibliothèque.
  - `profileStreamProvider` (StreamProvider) : profil réactif ; même fix « instantané initial » que la bibliothèque (`Stream.multi`, l'add du contrôleur au constructeur était perdu).
  - go_router 17.2.3 : pas de `GoRouter.of(optional:)` → `GoRouter.maybeOf(context)` ; navigation dégénérée (snack) si aucun routeur (tests isolés sans router).
  - Tests : `test/account_test.dart` (5 tests : invite anonyme + 3 méthodes ; e-mail validation→profil→persistance→déconnexion ; Google stub ; profil persisté ; Bibliothèque→votre espace via le vrai routeur). 20 tests au total, tous verts, build debug OK.
  - **Apprentissage tests** : `pumpAndSettle` seul ne déclenche PAS les `Future.delayed` du fake qui n'engendrent pas de frame → pattern `settleAll` (8×`pump(300 ms)` + settle), déjà utilisé dans app_test, généralisé aux tests routés.

- **Étape 7 — Freemium**
  - **Gating fiche livre** (`book_detail_screen.dart`) : gratuit → 1 avis presse visible + 4 floutés (carte fantôme translucide, verrou + « Avis Premium ») et 2 avis web visibles + 13 floutés ; synthèse IA rognée (~220 caractères à la ponctuation) pour le gratuit. Déblocage : **1 jeton IA** (3/mois, persistés, compteur « ✦ N jetons ce mois-ci ») via `unlockedBooksProvider` (Notifier de `Set<isbn>`) ; 0 jeton → carte « Premium inclut 3 jetons/mois ». Premium → tout visible sans dépenser.
  - **Traduction simulée Premium** : 2 des 15 avis web sont en langue étrangère (en/es, indices déterministes `stableHash`) ; avec Premium (ou fiche débloquée) ils reçoivent le chip « Traduit par Ela (anglais/espagnol) ».
  - **Paywall `/premium`** (`lib/features/premium/premium_screen.dart`) : 2 €/mois sans engagement, 7 avantages, abonnement/annulation simulés (délais fake, `Entitlement.premium` persisté, « Membre depuis … ») ; `PremiumUnlockCard` réutilisable (compact → « Découvrir Premium », sinon « Voir Premium — 2 €/mois »).
  - **Radar à économies `/radar`** (`radar_screen.dart`) : top 6 par remise (`usedPriceEur/priceEur`, prix d'occasion fictifs) ; gratuit → teaser + 1ʳᵉ affaire + 4 floutées + carte Premium ; Premium → les 6 avec badge « −N % ».
  - **MatchMaker `/match`** (`matchmaker_screen.dart`) : 2 suggestions par livre de l'étagère (même genre d'abord, `stableHash` déterministe) avec score 62–97 % (barre dorée) ; gratuit → 2 visibles + verrous « score masqué » + carte ; Premium → tout ; état vide si étagère vide.
  - **Bilan de curiosité** (écran de compte, Premium) : cartes stats (Lus / En PAL / Jetons IA du mois / Avis publiés — compteur prefs `ela.stats.reviews` incrémenté à chaque avis) + **export CSV** (dialogue : `champ;valeur`, copie presse-papier + snack). Gratuit → carte teaser « Premium » vers le paywall.
  - `FakePaymentService.watchEntitlement()` : fix « instantané initial » (même pattern que bibliothèque/profil) ; `entitlementStreamProvider` (stream) + suppression du fallback `FutureProvider` dans les vues (le `Future.delayed` du fake survivait aux `pumpAndSettle` des tests → timers orphelins).
  - Entrées Radar/MatchMaker ajoutées sur l'écran Tendance (icône cadenas si gratuit).
  - Tests : `test/freemium_test.dart` (6 tests : jeton→fiche complète + compteur 2 ; Premium 5 presse/15 web + 2 traduits ; paywall souscription→annulation ; Radar teaser vs 6 badges ; MatchMaker vide/verrous/premium ; Bilan CSV) ; `book_detail_test` adapté au gating (1+4 floutés, 2+13 floutés). **26 tests au total, tous verts (2 runs), build debug OK.**
  - **Apprentissages 3.35/tests** : pas de widget `Masked` (fondu = `Opacity` fantôme) ; `hashValues` retiré de `dart:ui` → `stableHash` maison (`fake_delay.dart`) ; `AsyncValue.value ?? futureProvider` piège de typage (`Object` si l'autre membre est `Future`) → stream seul ; `ListView` paresseux : les éléments hors viewport (viewport 390×844) ne sont **pas dans l'arbre** → tests freemium en viewport 390×2000 + `ensureVisible`/`pumpAndSettle` avant les taps ; bouton en cours d'action qui change de libellé (« Débloquer — 1 jeton » → « Déblocage… ») : attendre la disparition du libellé **intermédiaire**, pas du final.

- **Étape 8 — Finitions**
  - **Splash de marque** (`lib/features/splash/splash_screen.dart`) : papier (ou nuit), disque doré + `Icons.menu_book` (`Icons.stories` n'existe pas en 3.35) dans un halo qui respire (controller 1400 ms, disposé proprement) ; durée pilotée par `ElaApp` (1,1 s) — **omis sous `flutter test`** (`isRunningUnderFlutterTest`) pour ne jamais laisser de ticker/timer en attente.
  - **Onboarding 3 écrans** (`lib/features/onboarding/onboarding_screen.dart`) : Bienvenue / « 20 avis, 1 verdict » / bibliothèque+Premium ; dots animés, Retour/Suivant/« Commencer à lire », « Passer » ; `onboardedProvider` (Notifier bool, prefs `ela.onboarded`) ; `app.dart` : splash → (onboarding 1ʳᵉ fois) → `MaterialApp.router` (3 branches de `MaterialApp`, switch par rebuild du provider).
  - **Icône Ela** : `tools/gen_launcher_icon.dart` — **PNG RGBA encodés à la main en pur Dart** (zlib « stored » sans compression, CRC32/Adler-32, supersampling 2×2) : carré papier aux coins arrondis + disque doré + livre ouvert, 5 densités ; **adaptive icon** API 26+ (`mipmap-anydpi-v26` : fond `elaPaper` + vector `ic_ela_monogram.xml` 108 dp, disque+livre dans la safe zone).
  - **Splash natif Android** : `drawable/launch_background.xml` = papier + monogramme (layer-list `android:gravity=center` — `<bitmap>` d'un vector échoue sur les anciennes API) ; variante `drawable-night` bleu nuit ; couleurs `elaPaper/elaNight/elaGold` dans `values/ela_colors.xml`.
  - **Accessibilité** : `onSecondary` = encre sur or (5:1 au lieu de 2,6:1 pour le blanc) dans `theme.dart` + bouton onboarding aligné ; tooltips/Semantics sur les icon-only buttons (barre 4 entrées, scanner, profil, partage, déconnexion, effacer recherche) ; tailles de texte via le `textTheme` système (TextScaler).
  - **Tests** : `test/onboarding_test.dart` (3 tests : parcours 3 écrans + retour → shell, Passer + persistance du flag, 2ᵉ lancement direct) ; les 3 tests pumpant `ElaApp` seedent `ela.onboarded` (**`setMockInitialValues` remplace toute la map** — les seeds locaux doivent le re-porter). **29 tests au total, tous verts (2 runs), build debug OK.**
  - **README.md** : lancement (env.sh, run, build, tests), structure lib/, ce que fait l'app, branchement Firebase phase 2 (interfaces + flag `BACKEND`), notes (couvertures OpenLibrary, signature debug).
  - **Apprentissages** : `flutter test` + timers — toute fin de test avec un `Future.delayed`/`Timer` du fake non expiré échoue (`!timersPending`) ; le `settleAll` (8×300 ms) doit suivre **chaque** transition vers un écran qui déclenche des fakes ; fonction locale forward-reference interdite en Dart (déclarer `settleAll` avant `pumpApp`) ; un `sed` global sur `pumpAndSettle` peut casser le corps même de `settleAll` (recursion) ; `#!/usr/bin/env` ne peut être que ligne 1 sinon le parseur s'égare.

## En cours
- (rien — étape 8 terminée, en attente d'étape 9)

## Reste
- Étape 9 — Livraison : `flutter build apk --release` (signature debug) → `dist/ela.apk` + commit final.

## Décisions
- **Riverpod 3.3 / go_router 17** installés par Flutter 3.35 : API adaptées (`AsyncValue.when` + `.value` (pas de `.valueOrNull`), `Notifier` au lieu de `StateProvider` (passé en legacy dans riverpod 3), `StatefulShellRoute.indexedStack` + `currentIndex`/`goBranch(int)`, `MaterialApp.router(routerConfig:)`, `BuildContext.mounted` disponible).
- **Fiche livre défilable d’un bloc** (en-tête + onglets + contenu dans un seul `SingleChildScrollView`) : la variante « en-tête + barre d’onglets fixes » déborde dès que la description est longue (vérifié au layout).
- **Couvertures** : URL OpenLibrary `covers.openlibrary.org/b/id/<id>-M.jpg` (ISBN vérifiés via l’API) ; repli visuel élégant (dégradé sépia + initiale) si hors-ligne.
- **Jetifier OFF** (voir Fait) : exigence RAM du conteneur.
- **Flutter 3.35 — overlay** : `Positioned` ne peut pas appliquer sa `StackParentData` dans le sous-arbre d’un `OverlayEntry` (erreur levée au layout) → positionner avec `Transform.translate` (+ `Align`) ; `OverlayEntry.remove()` est la méthode de suppression ; pas de fonction `lerp` globale (écrire la sienne).
- **Google Books** : branché à l’étape 2 — `GoogleBooksClient.fetchByIsbn` (API publique sans clé, timeout 4–5 s, toute erreur → null) ; le catalogue local répond d’abord pour garder curation/avis cohérents.
- **Tests** : `GoogleFonts.config.allowRuntimeFetching = false` + horloge factice avancée à la main (les délais fake sont des `Future.delayed`) ; jamais de réseau ni de caméra en test (garde `isRunningUnderFlutterTest` = variable d’env `FLUTTER_TEST`, **pas** un `--dart-define`).
