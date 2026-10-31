# Carnet visuel Ela

La nouvelle page **Tendance avec carrousel** a son [carnet dédié](tendance/README.md),
avec références avant, captures jour/nuit, quatre positions successives,
goldens et validation du build réellement servi sur **:8240**.
Les 120 scènes ci-dessous documentent la refonte « livre » précédente.

- [Avant / après — six parcours](avant-apres.png)
- [Planche jour — 60 scènes](planche-jour.png)
- [Planche nuit — 60 scènes](planche-nuit.png)
- `avant/{jour,nuit}` : 36 scènes de référence (72 PNG).
- `apres/{jour,nuit}` : 60 scènes finales (120 PNG).

Les planches ont deux colonnes et des légendes larges pour le téléphone.
Elles sont longues : faire défiler et zoomer pour lire le détail des pages.
Chaque capture individuelle reste disponible à sa résolution d'origine.

## Reproduire

```bash
source scripts/env.sh
flutter test test/ui_capture_test.dart --concurrency=1 \
  --dart-define=CAPTURE_DIR=docs/screens/apres
flutter test test/ui_capture_test.dart --concurrency=1 --dart-define=COMPACT=true
python3 -m pip install -r tools/screens/requirements.txt
python3 tools/screens/contact_sheet.py
```

Le banc charge les fichiers TTF de `assets/fonts`, les icônes du SDK avec
FontLoader, puis rend à 412 × 915 dp, ratio 2,625 (1082 × 2402 px après
arrondi du moteur). La seconde passe vérifie à 360 × 640 dp et texte ×1,3.
Les deux dimensions MediaQuery et le facteur de texte sont explicitement
assertés. Les services fake utilisent le catalogue réel du dépôt ; la
bibliothèque et les comptes ont des fixtures de test datées, indépendantes
des préférences de l'utilisateur. Les images réseau sont remplacées par le
véritable repli hors ligne de BookCover pour éviter les captures instables.
Les états d'erreur et de chargement utilisent des overrides Riverpod.

Pour la référence, le mode `AUDIT_BEFORE=true` recueille les débordements dans
les fichiers voisins `*-issues.txt` ; il ne doit jamais être activé pour
valider la refonte. Les états spécifiques au nouveau banc (erreurs/reprise,
étagère, compte en connexion) sont ajoutés uniquement aux captures après.
Le scanner physique et les permissions OS ne sont pas simulés comme étant
validés sur appareil : seuls le repli ISBN et l'explication de refus sont rendus.

La version web jouable est dans `build/web`, à servir par ProxBoss. Aucun
serveur n'est démarré par ce travail. Le scanner du navigateur propose
immédiatement la saisie ISBN (exemple : `9782070667918`).

## Vérification du build web dans Chromium

`tools/web_smoke.cjs` ouvre le **build release** dans Chromium à 412 × 915,
ratio 2,625 et événements tactiles. Playwright répond aux requêtes depuis les
fichiers de `build/web` ; il ne lance aucun serveur HTTP et bloque les domaines
externes pour exercer les couvertures de repli. Le contrôle ouvre un ISBN,
revient au scanner, recherche Camus, ouvre sa fiche et vérifie que la requête
reste saisie après retour. Les entrées d'historique prouvent que les bonnes
fiches ont été montées. Les libellés DOM accessibles sont contrôlés séparément.

Les captures réelles du navigateur et son rapport sont dans `web/`.
Pour reproduire, installer Playwright dans un environnement de test, puis :

```bash
ELA_PLAYWRIGHT_PATH=/chemin/vers/node_modules/playwright \
ELA_CHROME_BIN=/chemin/vers/chrome node tools/web_smoke.cjs
```

Le banc n'active pas simultanément le pont DOM de sémantique forcé et les
événements tactiles synthétiques : cette combinaison provoquait une erreur
dans le gestionnaire de pointeurs du moteur Flutter. Les parcours tactiles
normaux et la lecture des libellés sémantiques sont vérifiés séparément.
Un essai avec lecteur d'écran réel reste du ressort de la validation appareil.
