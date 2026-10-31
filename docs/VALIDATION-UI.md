# Validation Tendance — carrousel héros — 31/10/2026

## Interface et tests

- `flutter analyze --no-pub` : **aucune issue**.
- `flutter test --no-pub --concurrency=1` : **169 tests verts** ; les
  158 contrôles existants sont conservés, avec 11 contrôles supplémentaires
  pour le carrousel et sa palette. Quatre comparaisons de pixels golden
  vérifient les positions 1 et 3, en jour et en nuit.
- `flutter test test/ui_capture_test.dart --no-pub --concurrency=1
  --dart-define=COMPACT=true` : **121 contrôles verts**, en **360 × 640 dp,
  texte ×1,3**, avec les vraies polices. Aucun débordement ni exception Flutter.
- Les tests spécifiques font également défiler les cinq positions dans les
  deux thèmes au format compact, y compris la jonction de fin de boucle.
- Gestes avec snap, pause tant qu'un doigt est posé, reprise après inactivité,
  pause explicite, réduction des animations, application en arrière-plan,
  changement d'onglet et navigation vers une fiche : vérifiés.
- Ajout rapide PAL : ISBN correct, état désactivé après ajout, persistance
  locale et absence de doublon vérifiés. Le retour d'une fiche conserve la
  position du carrousel. La transition Hero est vérifiée pendant son vol.
- Indicateurs : libellés du livre et de la position, état sélectionné, action
  sémantique et hauteur tactile de 48 dp. Les rayons ont leurs libellés et
  leurs actions propres ; le top 10 se défile jusqu'au dixième livre.
- Papier, typographie et bordeaux conservés. Grandes couvertures centrales,
  voisines atténuées en perspective, fond animé, métadonnées en fondu/glissé,
  apparition en cascade et légère parallaxe. Les peintures de couvertures
  sont isolées par des RepaintBoundary ; les transformations du geste se
  limitent au ruban du héros. L'extraction de palette est calculée une fois
  par couverture réseau chargée, sur une miniature de 24 × 24 pixels.

## Captures

**27 PNG** sont livrés dans [screens/tendance/](screens/tendance/README.md) :
références avant jour/nuit prises sur `62ca9a6`, nouveaux écrans jour/nuit,
quatre positions successives dans chaque thème, rayons, vues compactes,
trois planches et huit captures Chromium.

- [Avant / après jour et nuit](screens/tendance/avant-apres.png)
- [Carrousel jour](screens/tendance/sequence-jour.png)
- [Carrousel nuit](screens/tendance/sequence-nuit.png)

Les quatre goldens sont dans `test/goldens/`. Les références et les captures
Flutter exercent le véritable repli illustré hors ligne ; les couvertures
réseau restent prioritaires dans l'application. Le banc et les commandes
pour reproduire les captures sont décrits dans le carnet dédié.
Les anciennes planches dans `screens/apres/` restent la référence historique
de la précédente refonte « livre ».

## Web

- `flutter build web --release --no-pub --no-web-resources-cdn` : **réussi**.
  Build livré dans `build/web`, CanvasKit et polices inclus.
- Le **serveur ProxBoss existant sur :8240** sert bien le nouveau build :
  réponse HTTP 200 et contrôle du build réel par Chromium **156.0.8078.4**.
  Aucun nouveau serveur n'a été démarré.
- `tools/tendance_web_smoke.cjs` : quatre positions par gestes tactiles,
  ajout PAL du Petit Prince, ouverture de L’Alchimiste depuis la quatrième
  carte, retour au carrousel, thème nuit, format compact et sémantique :
  **validés, aucune erreur JavaScript**.
  [Rapport](screens/tendance/web/validation.json) et
  [arbre accessible](screens/tendance/web/accessibilite.txt).
- `tools/web_smoke.cjs` : parcours existants scanner ISBN → fiche,
  recherche Camus → L’Étranger → retour avec requête conservée et libellés
  de navigation : **validés, aucune erreur JavaScript**.
  [Rapport de régression](screens/web/validation.json).
- Les ressources locales sont chargées sans CDN. Les domaines de couvertures
  ont été bloqués dans les contrôles navigateur pour exercer le repli illustré.

Les validations finales et les builds ont été exécutés en série.
Aucun `flutter_tester` ne reste après les tests. Les comptes, prix et données
restent simulés. Les 60 fps sont un objectif de composition ; ils ne sont pas
mesurés sur appareil physique par les tests Linux/Chromium. La caméra, les
permissions OS et les lecteurs d'écran natifs restent à vérifier sur téléphone.

## Android et livraison

- `flutter build apk --release --no-pub` : **réussi en 116 secondes**.
  Gradle reste configuré avec `org.gradle.daemon=false` et un tas de 2 Go.
- APK livré : [`dist/ela.apk`](../dist/ela.apk), **71 962 525 octets**.
- `apksigner verify --print-certs` : signature valide, certificat identique
  à celui de l'APK précédent et de la release `v0.1.0`.
- Certificat SHA-256 :
  `805647876be2375c1aedf9004993b58b9cfa6a5a3400e07c8c03846aaf414d6a`.
- APK SHA-256 :
  `17576798ac1963e9c1e8abc00d61e541f43befae6ef206e570baa09fe2e00a74`.
- Vérification reproductible : `cd dist && sha256sum -c ela.apk.sha256`.
- Manifeste : `com.alexandrelebegue.ela`, version `1.0.0` / code `1`,
  Android minimum 24, cible 36, permissions Internet, caméra et état réseau.
- `build/web/main.dart.js` reste inchangé après le build Android
  (SHA-256 vérifié) ; le build web reste servi sur **:8240**.

Les livraisons sont séparées entre code et tests, captures et web, puis APK
et rapport final, sur la branche `main`. Aucune release GitHub supplémentaire
n'est créée par cette demande.
