# Validation de la refonte — 31/10/2026

- `flutter analyze --no-pub` : aucune issue.
- `flutter test --concurrency=1` : **158 tests verts** (29 tests métier
  historiques, 120 scènes jour/nuit, contrôle de configuration, 8 régressions).
- Matrice compacte : **121 contrôles verts**, 360 × 640 dp, texte ×1,3,
  vraies polices. Aucun débordement ni exception Flutter.
- Captures finales : **120 PNG**, 412 × 915 dp à 2,625 ; trois planches.
- `flutter build web --release --no-web-resources-cdn` : réussi, `build/web`.
  Ressources CanvasKit et polices embarquées. Aucun serveur HTTP démarré.
- Chromium 156.0.8078.4, viewport téléphone avec gestes tactiles : build release
  ouvert, ISBN 9782070667918 → fiche, retour scanner, recherche Camus →
  L’Étranger, retour avec requête conservée. Contrôle séparé des libellés
  sémantiques ; aucune erreur JavaScript dans cette vérification.
  [Rapport navigateur](screens/web/validation.json) et [captures](screens/README.md).
- Les commandes lourdes sont séquentielles. Aucun flutter_tester ne reste
  après les séries. Configuration Gradle sans daemon conservée.

Les simulations métier restent celles de la phase 1. La caméra physique,
les permissions de l'OS, les lecteurs d'écran natifs et les FPS sur téléphone
ne sont pas mesurés par ces tests Linux/Chromium.

## Android

- `flutter build apk --release` : réussi en 145,1 secondes.
- Livraison : `dist/ela.apk` (71,700,213 octets).
- Signature vérifiée par `apksigner`, certificat identique à l'APK téléchargé
  depuis la release GitHub `v0.1.0`.
- Certificat SHA-256 : `805647876be2375c1aedf9004993b58b9cfa6a5a3400e07c8c03846aaf414d6a`.
- APK SHA-256 : `3b372cae4818d4dffdf1cd6b73785bccaf8b6cadb8080d70ded12848321596e3`.
- Contrôle reproductible : `cd dist && sha256sum -c ela.apk.sha256`.
- Manifeste du build :

```text
package: name='com.alexandrelebegue.ela' versionCode='1' versionName='1.0.0' platformBuildVersionName='16' platformBuildVersionCode='36' compileSdkVersion='36' compileSdkVersionCodename='16'
sdkVersion:'24'
targetSdkVersion:'36'
uses-permission: name='android.permission.INTERNET'
uses-permission: name='android.permission.CAMERA'
uses-permission: name='com.alexandrelebegue.ela.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION'
uses-permission: name='android.permission.ACCESS_NETWORK_STATE'
application-label:'Ela'
```

Le build web est conservé après le build Android. Les six étapes de commit
(0, 1, 2 découverte, 2 fiches/comptes, 3 visuels/web, 4 APK) sont livrées sur
la branche `main`. La publication de release GitHub est laissée à ProxBoss.
