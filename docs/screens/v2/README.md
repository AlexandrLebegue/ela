# Notation, Marché, scanner — captures v2

Les PNG sont rendus par Flutter avec les polices et icônes locales, en jour
et en nuit. Les couvertures réseau restent intactes dans l’application ;
le banc sans réseau exerce leur repli illustré existant.

| Écran | Jour | Nuit |
| --- | --- | --- |
| Fiche et notation en tête | [Jour](fiche-notation-jour.png) | [Nuit](fiche-notation-nuit.png) |
| Éditeur, note de 4,5 | [Jour](widget-notation-jour.png) | [Nuit](widget-notation-nuit.png) |
| Tendance et étoiles | [Jour](tendance-etoiles-jour.png) | [Nuit](tendance-etoiles-nuit.png) |
| Marché, accueil | [Jour](marche-accueil-jour.png) | [Nuit](marche-accueil-nuit.png) |
| Comparateur | [Jour](marche-comparateur-jour.png) | [Nuit](marche-comparateur-nuit.png) |
| Annonce lecteur | [Jour](marche-annonce-jour.png) | [Nuit](marche-annonce-nuit.png) |
| Radar intégré | [Jour](marche-radar-jour.png) | [Nuit](marche-radar-nuit.png) |
| Scanner avant | [Jour](scanner-avant-jour.png) | [Nuit](scanner-avant-nuit.png) |
| Scanner après, viseur | [Jour](scanner-apres-jour.png) | [Nuit](scanner-apres-nuit.png) |
| Saisie ISBN, feuille basse | [Jour](scanner-manuel-jour.png) | [Nuit](scanner-manuel-nuit.png) |

Les versions `compact-*` montrent les mêmes écrans à **360 × 640 dp,
texte ×1,3**. Les autres sont prises à **412 × 915 dp**, en PNG à ratio 2.
Les références `scanner-avant-*` ont été prises avant sa refonte : elles
montrent le repli sans caméra de cette version. Le nouveau viseur utilise
`ScannerAvailability.preview` : c’est la vraie interface, sur fond neutre,
sans prétendre capturer un flux matériel. Les permissions OS, la caméra,
les vibrations et la fluidité sur téléphone restent à vérifier sur appareil.

## Reproduire

À lancer en série :

```bash
source scripts/env.sh
flutter test test/v2_capture_test.dart --no-pub --concurrency=1 \
  --dart-define=V2_CAPTURE_DIR=docs/screens/v2
flutter test test/v2_capture_test.dart --no-pub --concurrency=1 \
  --dart-define=COMPACT=true --dart-define=V2_CAPTURE_DIR=docs/screens/v2
```

Le banc contrôle aussi l’enregistrement et la suppression de la note.
Deux goldens de l’éditeur sont dans `test/goldens/`, en plus des quatre
goldens de Tendance. Les captures de référence du scanner sont archivées,
le banc courant ne les écrase plus.

## Build web réel

`tools/v2_web_smoke.cjs` contrôle le build release servi sur **:8240**,
avec Chromium et le pont sémantique Flutter. Aucun serveur supplémentaire
n’est lancé. Il exerce notation, Marché, filtres du comparateur, lien affilié,
contact simulé, Radar, ISBN, recherche, nuit et format compact. Le parcours
notation enregistre 4,5 par les actions clavier, modifie à 3,5 et supprime
la note ; `notation-validation.json` consigne ces vérifications.

```bash
ELA_PLAYWRIGHT_PATH=/tmp/ela-browser/node_modules/playwright \
ELA_CHROME_BIN=$HOME/.cache/ms-playwright/chromium-1248/chrome-linux64/chrome \
node tools/v2_web_smoke.cjs
```

Les captures Chromium, le rapport JSON et l’arbre accessible sont dans `web/`.
Le blocage des couvertures distantes se limite au contexte de test.
Les fakes, prix, liens affiliés et contacts sont des démonstrations.
La photo d’une annonce se fournit par URL HTTPS optionnelle ; l’upload de
fichier sera à brancher avec le backend.
