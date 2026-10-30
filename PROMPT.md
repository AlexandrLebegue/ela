# MISSION : développer l'application mobile « Ela » (Flutter, Android d'abord) avec Firebase STUBÉ

Tu es dans /home/dev/projects/ela. Lis d'abord, dans cet ordre : docs/REQUIREMENTS.md (cahier des charges complet, issu de la conversation produit), docs/STACK.md (choix techniques), docs/ARCHITECTURE.md (structure imposée). docs/conversation.txt est la source brute : ne le lis que pour lever un doute précis (grep), il est très long.

## Environnement (déjà installé, ne réinstalle rien)
- Flutter : `~/flutter/bin/flutter` (3.35.1, Dart 3.9). Ajoute-le au PATH : `export PATH=$HOME/flutter/bin:$PATH`.
- JDK 17 obligatoire pour Gradle : `export JAVA_HOME=$HOME/jdk17` (le java système est 21, NE PAS l'utiliser).
- Android SDK : `export ANDROID_HOME=$HOME/android-sdk` (platforms 35/36, build-tools 34-36). Licences acceptées.
- Mets ces 3 exports dans `scripts/env.sh` et source-le avant chaque commande flutter.
- RAM du conteneur limitée (8 Go partagés) : builds Gradle avec `org.gradle.jvmargs=-Xmx2g` et `--no-daemon`, jamais deux builds en parallèle, pas d'émulateur.

## Règles de travail
1. Crée le projet : `flutter create --org com.alexandrelebegue --project-name ela --platforms android,ios .` (garde docs/ et les fichiers existants).
2. Travaille par étapes ; à la fin de CHAQUE étape : `flutter analyze` sans erreur, `flutter test` vert, `flutter build apk --debug` OK, puis `git commit` (message clair). Tiens PROGRESS.md à jour (fait / en cours / reste / décisions).
3. Firebase est STUBÉ : n'ajoute AUCUN package firebase_* maintenant. Toute dépendance backend passe par une interface dans lib/data/services/ avec une implémentation Fake dans lib/data/fake/ (délais simulés 300-1500 ms, données de démonstration réalistes en FRANÇAIS : 15-20 livres variés avec couvertures via URL Google Books/OpenLibrary, avis presse/web/communauté crédibles). Le dossier lib/data/firebase/ contient seulement un README expliquant ce qui ira là. Sélection via Riverpod + `--dart-define=BACKEND=fake` (défaut fake).
4. Exception autorisée : la recherche ISBN peut appeler l'API publique Google Books (sans clé) avec repli sur les données fake si hors-ligne.
5. Packages conseillés : flutter_riverpod, go_router, mobile_scanner (scan ISBN), cached_network_image, shimmer ou skeletonizer, google_fonts (ou polices embarquées), shared_preferences/hive pour la persistance locale. Pas de package abandonné.
6. Interface entièrement en français. Ne t'arrête pas à un prototype : avance jusqu'à l'app complète. Si une étape bloque, note-la dans PROGRESS.md et passe à la suivante. Écris vite, n'analyse pas trop longtemps.

## Étapes
1. **Socle** : projet Flutter, env.sh, thème « cocooning » (mode papier/sépia coquille d'œuf + mode nuit bleu nuit/sépia, couleurs chaudes, typo serif douce pour les titres), go_router, Riverpod, bottom bar 4 entrées : Tendance / Scanner (bouton central mis en avant) / Ma Bibliothèque / Recherche. Modèles de données + interfaces de services + Fakes.
2. **Scanner** (écran phare, soigné) : caméra mobile_scanner EAN-13/ISBN, halo doré façon « lampe de chevet » (pas de laser rouge), à la détection : retour haptique doux (battement de cœur) + couverture qui « lévite » puis ouverture de la fiche. Saisie manuelle d'ISBN en secours + gestion propre de la permission caméra refusée.
3. **Fiche livre** : en-tête (couverture, titre, auteur, badge popularité 🔥 Phénomène / 📈 Tendance / 💎 Pépite cachée / 🏺 Classique intemporel, « X lecteurs d'Ela ont lu ce livre ») + 3 onglets en fondu doux : Synthèse IA & Presse (synthèse + 5 avis presse), Le Web (15 avis), La Communauté (illimité, ajout d'avis, bouton Signaler). Pendant la « curation IA » simulée : skeletons / texte qui « respire », pas de spinner. Boutons Ajouter à la PAL et Acheter (lien affilié fictif).
4. **Ma Bibliothèque** : Historique (passif, chronologique, chaque livre scanné/consulté) + Pile à Lire (active). Animation d'ajout : la couverture rétrécit et glisse en courbe vers l'icône Bibliothèque de la bottom bar qui s'élargit pour l'accueillir. Persistance locale (fonctionne sans compte).
5. **Tendance & Recherche** : listes tendances (fake) par catégories ; recherche titre/auteur/ISBN avec résultats animés.
6. **Comptes (lazy registration)** : aucun compte au démarrage (utilisateur anonyme). Écran de création/connexion (e-mail, Google, Apple — stubs) déclenché seulement pour : publier un avis, sauvegarder dans le cloud, payer. Profil simple + déconnexion.
7. **Freemium** : gratuit = 1 avis presse + 2 avis web visibles, le reste flouté avec invitation ; 3 jetons IA/mois pour débloquer un livre complet (compteur visible). Premium 2 €/mois (PaymentService fake) : 20 avis, traduction auto des avis étrangers (simulée), Radar à économies (prix d'occasion fictifs), MatchMaker (score de compatibilité), sans pub, statistiques « Bilan de curiosité » + export CSV. Écran paywall élégant.
8. **Finitions** : onboarding court (3 écrans), icône + splash aux couleurs d'Ela, accessibilité (tailles de texte, contrastes), tests widget des écrans clés, README (lancement, structure, comment brancher Firebase en phase 2).
9. **Livraison** : `flutter build apk --release` (signature debug acceptée), copie dans `dist/ela.apk`, commit final.

Commence maintenant par l'étape 1.
