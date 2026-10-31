# Validation v2 — notation, Marché, scanner — 31/10/2026

## Réalisation dans l’ordre du brief

1. **Notation — `3ff8996`** : note personnelle par utilisateur et ISBN,
   de 0,5 à 5 par demi-étoiles, persistée localement ; édition et suppression.
   La fiche affiche la moyenne typographique, le nombre de votes et les cinq
   tranches de l’histogramme juste sous l’identité du livre. L’éditeur tactile
   accepte le glissement et fournit les actions sémantiques augmenter/diminuer.
   Un avis communauté exige une note, avec titre et texte optionnels ; les avis
   personnels sont persistés et remplacés lors d’une modification. Les notes
   de sources présentes sont converties sur 5 ; une source sans note n’affiche
   pas d’étoiles. Les cartes de Tendance, rayons et résultats de recherche
   affichent les notes ; la bibliothèque montre la note personnelle, permet
   de trier par note et propose de noter après « Lu ». Rayon « Les mieux notés ».
   Les agrégats reposent sur 210 à 589 votes simulés par livre.
2. **Marché — `44bd4f8`** : cinquième entrée de navigation, accueil,
   recherche, comparateur neuf/occasion de Fnac, Amazon, Place des Libraires,
   Rakuten, Momox, Recyclivre, Vinted et Leboncoin. Prix du livre, port, total,
   état, tri par prix total ou état, meilleure offre et lien affilié simulé.
   Le bloc « Où l’acheter » de la fiche ouvre le bon ISBN. Annonces lecteurs
   avec prix, état, ville, photo par URL HTTPS optionnelle ; vente depuis les
   deux vues de bibliothèque, filtre de ville, fiche et contact simulé.
   Les annonces publiées sont persistées sur l’appareil. Le Radar Premium
   est intégré au Marché, et l’ancienne route `/radar` y redirige.
3. **Scanner — `be031c4`** : aperçu occupant toute la surface disponible,
   voile sombre neutre, coins crème fins et balayage discret, une touche
   bordeaux, aide courte, ISBN en feuille basse, haptique et confirmation
   animée. Le scan ne retient que les EAN-13 ISBN 978/979 à clé valide.
   Arrêt caméra quand l’app est inactive, pendant la saisie et la navigation.
   Le navigateur et les permissions refusées disposent du repli manuel.

Les interfaces `RatingService`, `ReviewService` et `MarketService` isolent les
fakes ; les schémas prévus sont documentés dans
[data/firebase/README.md](../lib/data/firebase/README.md). Aucun branchement
Firebase ni achat réel n’est revendiqué. Les couvertures réelles existantes
et leur repli n’ont pas été modifiés.

## Vérifications

- `flutter analyze --no-pub` : **aucune issue**.
- `flutter test --no-pub --concurrency=1` : **196 tests verts**, avec comparaison
  des **6 goldens** (4 Tendance, 2 éditeur de notation).
- `flutter test test/ui_capture_test.dart test/v2_capture_test.dart --no-pub
  --concurrency=1 --dart-define=COMPACT=true` : **139 contrôles verts**,
  en **360 × 640 dp, texte ×1,3**. Aucun débordement ni exception Flutter.
- Les tests couvrent moyenne, demi-étoiles, arrondi, conversion de source,
  unicité par utilisateur/livre, modification et suppression persistées,
  note obligatoire, avis sans texte, édition visuelle, tri incluant le port,
  vente et persistance, contact, filtre de ville, lien affilié, retour à la
  fiche, Radar intégré, clé ISBN, saisie manuelle et reprise après erreur.
- Les tests existants restent présents : leurs interactions défilent jusqu’aux
  éléments lorsque la nouvelle notation en tête allonge la fiche.
- Les commandes lourdes sont exécutées en série. Aucun `flutter_tester`
  ne reste après les tests. Gradle conserve `org.gradle.daemon=false`.

## Captures

**40 PNG Flutter** dans [screens/v2/](screens/v2/README.md) : fiche et notation,
éditeur, Tendance, Marché, comparateur, annonce, Radar, scanner avant/après et
feuille ISBN, dans les deux thèmes et au format compact. Les PNG utilisent
les vraies polices et icônes locales. Les références du scanner avant refonte
sont conservées et ne sont plus régénérées par le banc courant.

Le viseur est capturé avec un état de prévisualisation sans matériel ; les
captures montrent la vraie interface sur fond neutre. La caméra réelle,
les permissions OS, le ressenti haptique, les lecteurs d’écran natifs et les
performances sur téléphone restent à vérifier sur appareil physique.

## Web

- `flutter build web --release --no-pub --no-web-resources-cdn` : **réussi**.
  CanvasKit et polices inclus dans `build/web`.
- Le serveur existant sur **:8240** répond **HTTP 200** ; son `main.dart.js`
  est identique au fichier livré (comparaison binaire).
- Aucun nouveau serveur HTTP n’est lancé.
- Chromium **156.0.8078.4** : parcours du nouveau build validés, **aucune
  erreur JavaScript**, en jour/nuit, 412 × 915 et 360 × 640.
  [Rapport](screens/v2/web/validation.json) et
  [arbre accessible](screens/v2/web/accessibilite.txt).
- Le contrôle ciblé de notation vérifie aussi les demi-étoiles au clavier,
  l’écriture effective de **4,5**, son remplacement par **3,5**, puis la
  suppression dans les préférences du navigateur.
  [Rapport notation](screens/v2/web/notation-validation.json).
- **13 captures Chromium** complètent les captures Flutter. Les couvertures
  distantes sont bloquées uniquement dans les contextes de test, pour exercer
  le repli hors ligne existant. Le build de production conserve leurs URL.

## Android et livraison

- `flutter build apk --release --no-pub` : **réussi**, Gradle en 124,3 s.
- APK livré : [`dist/ela.apk`](../dist/ela.apk), **72 896 849 octets**.
- `apksigner verify --print-certs` : signature valide, certificat identique
  à celui de l’APK livré avant cette demande.
- Certificat SHA-256 : `805647876be2375c1aedf9004993b58b9cfa6a5a3400e07c8c03846aaf414d6a`.
- APK SHA-256 : `bfb0660c096613f93f4244bd9808d44dc8615e402985c9af703d8fb7d2d04190`.
- `cd dist && sha256sum -c ela.apk.sha256` : **OK**.
- Manifeste : `com.alexandrelebegue.ela`, version `1.0.0` / code `1`,
  Android minimum 24, cible 36. Permissions Internet, caméra et état réseau.
- Le hash de `build/web/main.dart.js` reste inchangé après le build Android.
  Le web reste servi sur **:8240**.

Les trois parties fonctionnelles sont dans des commits distincts, suivis du
commit de livraison (APK, contrôle web et documentation). Aucune release
GitHub supplémentaire n’est créée par cette demande.
