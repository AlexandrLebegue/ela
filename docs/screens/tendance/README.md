# Tendance — carrousel héros

[Avant / après jour et nuit](avant-apres.png) ·
[Séquence jour](sequence-jour.png) · [Séquence nuit](sequence-nuit.png)

- `avant/{jour,nuit}/05-tendance.png` : références capturées sur le commit
  `62ca9a6`, avant toute modification de l'interface.
- `apres/{jour,nuit}/05-tendance.png` : premier écran avec animations normales.
- `apres/{jour,nuit}/01-hero.png` à `04-hero.png` : quatre positions successives,
  obtenues par glissement. Les animations système sont désactivées pour ces
  scènes et les goldens ; le bouton de pause est donc masqué.
- `apres/{jour,nuit}/05-rayons.png` : les rayons sous le héros.
- `compact-{jour,nuit}.png` : rayons en 360 × 640 dp, texte ×1,3.
- `web/` : captures du build release réellement servi sur le port **8240**, gestes
  tactiles Chromium, thème nuit, fiche ouverte depuis la quatrième couverture,
  écran compact et contrôle séparé des libellés accessibles.

Les captures Flutter utilisent les vraies polices, le catalogue fake existant
et le véritable repli illustré hors ligne. Résolution normale : 412 × 915 dp,
export à 2,625 pixels par dp. Les quatre goldens sont dans `test/goldens/`,
à un pixel par dp ; les tests comparent leurs pixels à chaque exécution.
Les planches sont des assemblages des captures, sans retouche de l'interface.

## Reproduire

```bash
source scripts/env.sh
flutter test test/tendance_carousel_test.dart --concurrency=1 \
  --dart-define=TENDANCE_CAPTURE_DIR=docs/screens/tendance
flutter test test/ui_capture_test.dart --concurrency=1 \
  --plain-name '05-tendance' \
  --dart-define=CAPTURE_DIR=docs/screens/tendance/apres
flutter test test/ui_capture_test.dart --concurrency=1 \
  --dart-define=COMPACT=true
python3 tools/screens/tendance_sheet.py
```

Les références « avant » sont figées. Pour accepter une modification visuelle
voulue, lancer le premier test avec `--update-goldens`, puis relire les images.
Pillow est la seule dépendance Python, listée dans `tools/screens/requirements.txt`.

Le contrôle Chromium utilise le serveur existant de ProxBoss ; il n'en démarre
aucun. Les couvertures distantes sont bloquées pour vérifier le repli hors ligne.
Les ressources de l'application sont chargées par HTTP depuis le vrai build :

```bash
ELA_PLAYWRIGHT_PATH=/chemin/vers/node_modules/playwright \
ELA_CHROME_BIN=/chemin/vers/chrome node tools/tendance_web_smoke.cjs
```

`ELA_WEB_URL` peut remplacer `http://127.0.0.1:8240/`.
[Rapport navigateur](web/validation.json) · [Sémantique](web/accessibilite.txt).

Le carrousel marque une pause tant qu'un doigt est posé ou qu'un contrôle a
le focus. Il reprend après 12 secondes d'inactivité ; le rythme normal est de
7 à 12 secondes entre cartes, avec une transition de 850 ms. Il s'arrête également
quand l'application passe en arrière-plan, dans un autre onglet, sur une fiche
ou lorsque le héros n'est plus visible. La réduction des animations et la
navigation accessible désactivent l'auto-défilement. Les indicateurs et les
cartes restent utilisables à la main et au clavier.
