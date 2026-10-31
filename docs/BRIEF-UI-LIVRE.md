# BRIEF — Refonte complète de l'interface d'Ela (style « livre »)

Demande de Chef (31/10/2026) : « Ela est très moche et l'interface bugue. Reprendre toute
l'interface et lui faire un vrai style, un peu bouquin. Graphisme propre, finition nickel.
Je veux un retour visuel pour jauger les fonctionnalités. »

Tu travailles seul dans `/home/dev/projects/ela` (Flutter, Riverpod, go_router).
Lis d'abord `README.md`, `PROGRESS.md`, `docs/ARCHITECTURE.md`, `docs/REQUIREMENTS.md`.
Les fonctionnalités existantes (scanner, fiche livre 3 onglets, tendance, recherche,
bibliothèque PAL/historique, comptes en lazy registration, freemium/paywall, radar, matchmaker,
onboarding, splash) doivent TOUTES être conservées et fonctionner. Seuls l'interface et les bugs changent.

## Contraintes machine (IMPORTANT)
- LXC de 8 Go de RAM, partagé avec d'autres projets. Une seule commande lourde à la fois
  (jamais `flutter build` et `flutter test` en parallèle). Pas de daemon Gradle (déjà réglé
  dans `~/.gradle/gradle.properties`, ne pas modifier).
- Après chaque série de tests, vérifie qu'aucun `flutter_tester` ne reste en vie
  (`pkill -f flutter_tester` si besoin).

## Étape 0 — Captures « avant » + audit des bugs
1. Mets en place un banc de captures d'écran fiable : test widget « golden » (ou
   `integration_test` si plus pratique) qui rend CHAQUE écran et état important en taille
   téléphone (412×915 dp, ratio 2.625), en mode jour ET nuit, avec les VRAIES polices.
   Pour ça, les polices doivent être embarquées en assets (OFL, fichiers .ttf dans
   `assets/fonts/`, déclarées dans pubspec) au lieu de `google_fonts` en réseau, et chargées
   dans le test (FontLoader). Les icônes Material aussi (MaterialIcons depuis le SDK).
   Résultat : aucune capture avec la police de test (rectangles « Ahem »).
2. Capture l'état ACTUEL de tous les écrans dans `docs/screens/avant/` (PNG).
3. Fais un audit honnête : débordements (RenderFlex overflow), textes coupés, écrans vides,
   navigation cassée, retour arrière, états de chargement bloqués, contrastes, incohérences
   de style, problèmes d'animations, erreurs dans les logs. Lance aussi `flutter analyze`.
   Écris la liste dans `docs/AUDIT-UI.md` (gravité, écran, cause, correctif prévu).
4. Commit + push, puis : `~/.local/bin/proxboss-wake "ela: étape 0 faite (captures avant + audit)"`.

## Étape 1 — Direction artistique « livre » et design system
Ambiance : un beau livre relié qu'on ouvre le soir, cocooning, élégant, SOBRE (pas kitsch,
pas de faux parchemin brûlé). Inspiration : édition de poche Folio/Pléiade, carnet de lecture,
marque-page en ruban, ex-libris.
- Typographie : serif littéraire pour titres (ex. EB Garamond, Cormorant Garamond ou Playfair)
  et serif de lecture pour le corps (ex. Literata, Source Serif) ; petites capitales et
  chiffres elzéviriens quand c'est pertinent ; une sans-serif discrète seulement pour les
  très petits libellés si nécessaire. Hiérarchie claire, interlignage généreux.
- Matière : papier crème avec grain très subtil (bruit léger, procédural ou petite texture),
  encre brun-noir, accents bordeaux / vert reliure / or patiné en touches. Mode nuit =
  lecture à la lampe : fond cuir/bleu nuit profond, texte ivoire, or doux.
- Ornements typographiques discrets : filets, fleurons (❦ ⁂), lettrines sur les synthèses,
  en-têtes de section façon chapitres (« Chapitre I · Tendances »), folios / numéros de page.
- Composants : cartes « page » (marges, léger ombré de reliure), couvertures avec ombre
  et effet de dos, onglets en marque-pages / rubans, boutons sobres type étiquette d'éditeur,
  barre de navigation basse élégante avec le Scanner central bien mis en valeur,
  bibliothèque façon étagère (dos de livres) en plus de la vue liste si ça reste lisible.
- Transitions : douces, effet de page tournée ou fondu papier entre écrans, sans lourdeur
  (60 fps sur téléphone moyen de gamme).
- Centralise tout dans un vrai design system : `lib/core/design/` (tokens couleurs,
  typographie, espacements, rayons, ombres) + composants réutilisables. Plus aucune
  couleur/taille en dur dans les écrans.
Écris la DA en une page dans `docs/DESIGN.md`. Commit + push.

## Étape 2 — Refonte écran par écran + correction des bugs
Refais TOUS les écrans avec le design system (splash, onboarding, tendance, recherche,
scanner, fiche livre et ses 3 onglets, bibliothèque, compte, premium/paywall, radar,
matchmaker, dialogues, feuilles basses, snackbars, états vides/erreur/chargement).
Corrige tous les points de `docs/AUDIT-UI.md`. Finition : alignements, marges cohérentes,
aucun débordement même avec grande taille de police système (textScaler 1.3) et petit
écran (360×640), aucun texte coupé, accessibilité (contraste AA, semantics).
Commits réguliers (un par écran ou groupe d'écrans) et push.
Au milieu de l'étape (≈ moitié des écrans faits) : régénère les captures et
`~/.local/bin/proxboss-wake "ela: étape 2 à mi-parcours, captures à jour"`.

## Étape 3 — Retour visuel pour Chef
1. Captures « après » de tous les écrans/états, jour et nuit : `docs/screens/apres/`.
2. Une planche-contact lisible sur téléphone : `docs/screens/planche-jour.png` et
   `docs/screens/planche-nuit.png` (grille avec le nom de chaque écran sous la capture),
   plus `docs/screens/avant-apres.png` (4-6 écrans clés côte à côte).
3. Version web jouable : active la plateforme web (`flutter create --platforms web .`),
   assure-toi que l'app tourne dans un navigateur mobile (le scanner peut basculer sur la
   saisie ISBN manuelle si pas de caméra), puis `flutter build web --release` dans
   `build/web`. Ne lance PAS de serveur : ProxBoss s'en charge.
4. `flutter analyze` sans erreur, tous les tests verts (anciens + nouveaux).
5. Mets à jour `PROGRESS.md` et `README.md`. Commit + push.
6. `~/.local/bin/proxboss-wake "ela: étape 3 faite, captures + build web prêts"`.

## Étape 4 — APK
`flutter build apk --release` (même signature que la v0.1.0), copie dans `dist/ela.apk`,
commit + push. Ne crée PAS la release GitHub : ProxBoss la publiera après validation de Chef.
Puis `~/.local/bin/proxboss-wake "ela: refonte terminée, APK prêt"` et arrête-toi.

## Règles
- Ne change pas les fonctionnalités ni les données de démo sans raison ; si tu dois trancher
  un choix de design important, prends la décision la plus élégante et note-la dans DESIGN.md.
- Aucun secret dans le dépôt.
- Si tu es bloqué plus de 20 min sur un point, note-le dans PROGRESS.md, réveille ProxBoss
  avec `proxboss-wake "ela: bloqué sur ..."` et continue sur le reste.
