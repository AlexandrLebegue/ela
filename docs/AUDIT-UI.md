# Audit UI — référence du 31 octobre 2026

Référence : 72 PNG dans `docs/screens/avant/{jour,nuit}` (36 scènes),
412 × 915 dp à 2,625, polices Lora/Nunito Sans embarquées et chargées par
FontLoader, MaterialIcons du SDK. Les couvertures réseau utilisent le repli
réel hors ligne pour rendre les captures reproductibles. Le mode audit
collecte les erreurs Flutter ; il ne les considère pas comme corrigées.
`flutter analyze` initial : aucune issue. Les captures révèlent des défauts
que l'analyse statique ne peut pas détecter.

| ID | Gravité | Écran | Cause / constat | Correctif prévu |
|---|---|---|---|---|
| A01 | Haute | Navigation principale | RenderFlex horizontal : +37 px, constaté dans 20 scènes jour/nuit, libellés et espacements naturels sans flex | Répartition avec Expanded, retours à la ligne, cible tactile ≥48 |
| A02 | Haute | Fiches depuis listes/scanner | `context.go` remplace la pile ; retour vers la recherche/bibliothèque perdu | `push` des fiches, retour explicite en entrée directe |
| A03 | Haute | Web | `Platform.environment` et HttpClient de dart:io | Détection conditionnelle, client HTTP multiplateforme et scanner web manuel |
| A04 | Moyenne | Tendance / bibliothèque | En-têtes fixes, listes dans Expanded, manque de place avec texte agrandi ; titres limités à une ligne | En-tête défilant, titres sans limite, métadonnées verticales |
| A05 | Haute | Nuit : avis verrouillés, radar, matchs, premium | Texte `sepiaDeep` sombre sur fond sombre, couleur de jour forcée | Couleurs sémantiques du ColorScheme, contrastes AA testés |
| A06 | Moyenne | Recherche | Future créé dans build, erreurs assimilées à zéro résultat, autofocus ouvre le clavier sans demande | FutureProvider par requête, erreur et retry, focus explicite |
| A07 | Moyenne | Radar / MatchMaker / Premium | Entitlement null → SizedBox vide, aucune information ni retry | États livre de chargement/erreur et action de reprise |
| A08 | Moyenne | Compte / fiche / synthèse | Compteurs et titres en Row rigide, actions longues, feuilles non défilantes au clavier | Wrap, boutons adaptatifs, feuilles scrollables avec SafeArea |
| A09 | Moyenne | Scanner | Fond noir même sans caméra, blocs fixes ; caméra continue dans branche inactive ; erreurs lookup laissent busy | Surface papier hors caméra, cycle de vie, try/finally et saisie validée |
| A10 | Moyenne | Profil / achat / avis | Provider profil non réactif ; partage annonce une copie sans copier ; erreurs async sans reprise | Profil basé sur stream, presse-papier effectif, erreurs et réactivation boutons |
| A11 | Moyenne | Onboarding / animations | Carte centrée non défilante, animation continue sans réduction système ; texte respirant parfois trop pâle | Contenu défilant, réduction des animations, opacité lisible |
| A12 | Moyenne | Tous | Polices réseau, arrondis et couleurs incohérents, absence de hiérarchie éditoriale | Polices OFL locales, tokens et composants sous lib/core/design |
| A13 | Faible | Bibliothèque / radar / matchs | Couvertures réseau et couvertures factices divergentes, données inconnues réduites à l'ISBN | BookCover commun, résolution du livre par ISBN et repli explicite |
| A14 | Moyenne | Avis | Signalement tactile minuscule ; titre/texte de formulaire sans label ; modération non appliquée à l'envoi | IconButton sémantique, labels, service de modération existant |

## Limites de la référence

Les capteurs physiques et permissions caméra ne peuvent pas être exercés par
un widget test Linux ; le repli manuel est capturé. Les services Firebase,
authentification sociale et paiement restent simulés, conformément au dépôt.
Le contrôle de fluidité ici est structurel et visuel, pas une mesure de FPS
sur un téléphone physique. Les erreurs de layout de la référence sont gardées
en fichiers `*-issues.txt` à côté des PNG concernés.

## Mesure petit écran avant refonte

Matrice 360 × 640 dp, texte ×1,3 :

- `lib/features/home_shell.dart:54:16` : 20 signalements de débordement.
- `lib/features/trending/trending_screen.dart:211:21` : 18 signalements de débordement.

## Corrections et preuves après refonte

Tous les points A01–A14 sont traités. Les défauts de disposition sont vérifiés
par la matrice de 60 scènes, en jour/nuit, téléphone 412 × 915 puis
360 × 640 avec texte ×1,3. Les erreurs Flutter ne sont interceptées que dans
le mode d'audit « avant » ; elles font échouer toutes les validations finales.

- **A01/A04/A08** : navigation en flex, en-têtes défilants, titres complets,
  compteurs en Wrap, feuilles défilantes ; contrôles de taille et de facteur
  de texte dans le banc. La vue étagère est également exercée.
- **A02** : push des fiches et bouton Retour avec repli en entrée directe ;
  test conservation de la requête et des résultats après retour de la fiche.
- **A03/A06** : imports conditionnels pour les flags, client HTTP web/mobile,
  FutureProvider stable par requête, recherche ISBN externe en repli, erreur
  distincte de l'absence de résultat et bouton Réessayer.
- **A05/A12** : palettes et dimensions centralisées, vraies polices locales,
  polices OFL de symboles pour les fleurons et badges ; test du contraste
  ≥4,5:1 pour les huit paires de texte sémantiques dans les deux thèmes.
- **A07/A09** : états de chargement/erreur visibles et reprise ; scanner avec
  saisie normalisée, erreur non bloquante, arrêt caméra sur changement de
  route/cycle de vie et livre identifié chargé avant sa présentation.
- **A10/A14** : profil réactif, copie réelle au presse-papier, cibles tactiles
  de signalement, champs nommés, modération appliquée, conservation du texte
  si l'envoi échoue ; test connexion puis publication et compteur persistant.
- **A11** : onboarding et formulaires défilants, animations réduites quand
  le système le demande ; test de feuille au clavier à 360 × 640 et texte ×1,3.
- **A13** : composant BookCover partagé, résolution des livres de bibliothèque
  par provider, vues liste/étagère conservant l'ordre et les sections.

Deux défauts supplémentaires ont été corrigés pendant les vérifications :

| ID | Gravité | Constat | Correction |
|---|---|---|---|
| A15 | Haute | Permission INTERNET présente uniquement en debug/profile ; couvertures et Google Books impossibles dans l'APK release | Permission dans le manifeste principal ; miniatures HTTP passées en HTTPS |
| A16 | Moyenne | Basculer depuis le thème système sombre sélectionnait encore sombre ; choix non mémorisé | Calcul d'après la luminosité réelle puis persistance du choix |

Le fixture de capture utilisait `toread` au lieu de `toRead` : correction et
recapture des dix PNG concernés depuis le commit de référence 64faa13, dans
un checkout séparé, pour conserver une comparaison loyale. Le banc vérifie
explicitement les dimensions MediaQuery, pas seulement les contraintes du rendu.
Les tests fonctionnels historiques défilent maintenant jusqu'aux actions et
sections hors écran, sans supprimer leurs assertions métier. L'attente du test
scanner couvre la chaîne lookup → fiche → historique, dont les délais simulés
peuvent s'additionner ; aucun timer ni flutter_tester ne reste après la série.

La caméra physique, les permissions de l'OS, le rendu sur appareil et les FPS
restent à confirmer sur téléphone ; aucun résultat matériel n'est revendiqué.
