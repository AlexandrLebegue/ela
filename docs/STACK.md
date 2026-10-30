# Choix techniques — Ela

## Plateformes
iPhone **et** Android (décision Chef, 2026-10-30). Développement Android en premier (CI/LXC sans Mac), iOS ensuite avec la même base de code.

## Frontend : Flutter (retenu) plutôt que React Native
| Critère | Flutter | React Native |
|---|---|---|
| Animations « satisfying » (lévitation de couverture, glissement vers l'étagère, halo lampe de chevet, skeletons, fondus) | Moteur de rendu propre (Impeller), 60/120 fps constants, Hero/implicit animations, Rive/Lottie | Possible (Reanimated) mais plus de plomberie native |
| Rendu identique iOS/Android (design cocooning maîtrisé au pixel) | Oui, pixel-perfect | Composants natifs = différences par OS |
| Firebase | FlutterFire officiel (maintenu par Google) | @react-native-firebase (communautaire, très bon) |
| Scanner caméra ISBN | `mobile_scanner` (ML Kit / Vision) | `react-native-vision-camera` |
| Outillage présent sur LXC 103 | Flutter 3.35.1 + JDK 17 + Android SDK 35/36 déjà installés | à installer |
**Décision : Flutter (Dart).** Gestion d'état : Riverpod. Navigation : go_router. Stockage local : Drift (SQLite) ou Hive pour le mode sans compte.

## Backend : Firebase (adapté)
Firebase colle bien au produit :
- **Auth** : anonyme au démarrage (lazy registration) puis *linkWithCredential* (Google / Apple / e-mail) → aucune perte de données à l'inscription.
- **Firestore** : livres (cache partagé des avis curés par ISBN), avis communauté, bibliothèques utilisateurs, compteurs « X lecteurs d'Ela ».
- **Cloud Functions** (Node/TS ou Python) : appel IA + recherche web côté serveur (clés jamais dans l'app), écriture du cache, rafraîchissement hebdo (Cloud Scheduler), modération IA des avis.
- **Remote Config / App Check / Analytics / Crashlytics / FCM**.
- Paiements : RevenueCat (abonnement 2 €/mois + jetons IA) synchronisé avec Firestore via webhook.
Limites à connaître : requêtes Firestore limitées (pas de recherche plein texte → Algolia/Typesense ou Google Books pour la recherche), coût lecture si pas de dénormalisation, verrouillage fournisseur. Rien de bloquant pour Ela.

## Phase 1 (en cours)
Application Android Flutter complète avec **Firebase stubé** : interfaces de services (AuthService, BookRepository, ReviewService, CurationService, PaymentService) + implémentations *Fake* en local avec données de démonstration ; bascule vers les implémentations Firebase plus tard sans toucher l'UI.
