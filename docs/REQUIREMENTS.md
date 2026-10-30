# REQUIREMENTS.md — Application mobile "Ela"

> Source : conversation Gemini partagée (https://share.gemini.google/J5zx5oCPszmf), extraite intégralement dans `conversation.txt` (111 tours, ~384 Ko).
> Règle appliquée pour les points en contradiction : la décision la plus récente dans le fil l'emporte.

---

## 1. Résumé de la demande d'application

### Objectif
Développer une application mobile nommée **Ela**, positionnée comme un "compagnon de lecture intelligent et social". Elle permet de scanner ou rechercher un livre, puis utilise l'IA pour agréger, trier, traduire et résumer les avis du web et des utilisateurs de l'app. L'ambition est de se différencier de Babelio, Gleeph, SensCritique et Goodreads grâce à une curation IA et une expérience "cocooning".

### Public cible
- Cible privilégiée évoquée : les **gros lecteurs de fiction** (romance, thriller, fantasy, communauté BookTok), obsédés par les "tropes", la chasse aux livres d'occasion et la "Pile à Lire" (PAL).
- **Point ouvert** : la discussion laisse en suspens le choix entre ce public de niche fiction/BookTok et un public plus large et traditionnel (prix littéraires, essais, biographies) (ligne ~761 de conversation.txt — aucune réponse claire apportée).

### Plateformes
- Application **mobile**.
- Stack envisagée : **React Native ou Flutter** (donc visée multiplateforme iOS + Android), mais le choix précis n'a pas été tranché.
- **Point ouvert** : la question "iPhone uniquement ou iPhone et Android en même temps" est posée (lignes ~185 et ~197) sans réponse claire dans le fil.

### Nom et identité
- Nom retenu : **Ela** (court, doux, personnel, bienveillant, cohérent avec l'ambiance cocon).
- Ambiance visuelle : **cocooning, apaisante, chaleureuse** (décidé définitivement à la fin du fil, ligne ~1005).

---

## 2. Fonctionnalités demandées (structurées par thème)

### 2.1 Expérience utilisateur et inscription
- **Lazy Registration** (décisif) : aucun compte obligatoire à l'ouverture. Scan, recherche et ajout à l'historique fonctionnent en local sans compte.
- Création de compte demandée a posteriori (sauvegarde cloud de la bibliothèque, dépôt d'avis, paiement).
- Navigation principale (bottom bar) : **Tendance**, **Scanner** (bouton central, action principale), **Ma Bibliothèque** (Historique passif chronologique + Pile à Lire actif), **Recherche** (barre manuelle).

### 2.2 Scan et reconnaissance de livres
- Scanner de code-barres (ISBN) comme expérience centrale.
- Reconnaissance via API publiques et légales de métadonnées de livres (ex. Google Books API).
- Pas de scraping des bases de données concurrentes (Gleeph, Babelio, Amazon) — illégal.
- Pas de copiage du code ni du design des concurrents (risque de concurrence déloyale / parasitisme).
- Nom et logo totalement différents pour éviter toute confusion.

### 2.3 Page de détail d'un livre (3 onglets)
Décision la plus récente (Super Prompt Définitif, lignes ~1069-1075) :
1. **Synthèse IA & Presse** : résumé/synthèse IA global + exactement **5 avis presse** pertinents extraits via IA.
2. **Le Web** : exactement **15 avis** pertinents extraits de blogs/sites via IA.
3. **La Communauté** : avis **illimités** laissés par les utilisateurs de l'app.

> **Contradicton / évolution** : dans une version antérieure, l'IA rédigeait un "Résumé IA" (paragraphe généré) et il existait un onglet "Recherche" dans l'architecture 3 onglets (Tendance / Scan / Recherche). La version finale précise que l'IA n'est pas un rédacteur robotique mais un **super-curateur** (elle sélectionne et extrait les meilleurs avis existants ; les lecteurs préfèrent de "vraies voix humaines"). Décision retenue : super-curation + synthèse, pas de résumé rédigé par IA.

### 2.4 Fonctionnalités IA et données
- Agrégation, tri et **traduction** des avis du web et des utilisateurs.
- Super-curation : l'IA sélectionne les avis les plus pertinents (règles strictes à définir : longueur, likes à la source, etc.).
- Mise en cache : quand le premier utilisateur scanne un livre, l'IA fait le travail (~15 s) et les résultats sont sauvegardés en base. Le deuxième utilisateur qui scanne le même livre affiche les avis instantanément (coût 0 €). Rafraîchissement des avis une fois par semaine en arrière-plan.
- Indicateur de popularité communautaire : "X lecteurs de [Ela] ont lu ce livre".
- Données de ventes publiques (best-sellers uniquement, ex. Wikipédia/communiqués éditeurs).
- **MatchMaker** (Premium) : score de compatibilité basé sur les goûts de l'utilisateur.
- **Radar à Économies** (Premium) : trouver le livre d'occasion moins cher (affiliation sur plateformes d'occasion possible).
- Historique passif et Pile à Lire (PAL) active.
- Export de l'historique (CSV / Notion) — Premium.
- "Bilan de curiosité" (Premium) : statistiques de lecture (répartition par genre, auteurs les plus recherchés).

### 2.5 Modèle économique (freemium stratégique)
Décision la plus récente (lignes ~1077-1082) :

**Version Gratuite**
- Scan et recherche illimités.
- Historique et Pile à Lire illimités.
- Accès complet à l'onglet "Communauté".
- Onglets IA (Presse/Web) "teasés" : 1 avis presse et 2 avis web visibles, le reste flouté.
- 3 "Jetons IA" offerts par mois pour débloquer un livre complet.

**Version Premium (abonnement)**
- Déblocage des 20 avis IA (5 presse + 15 web).
- Traduction automatique des avis étrangers.
- Radar à Économies.
- MatchMaker.
- Pas de publicité (interface "pure et zen").
- Statistiques avancées et export.

> **Contradictions de prix (garder la plus récente)** : un tarif de 3,99 €/mois est évoqué tôt dans le fil ; un tarif de **2 €/mois** est avancé plus tard (ligne ~1099, projection de rentabilité). Décision retenue : **2 €/mois** (version la plus récente).

**Autres revenus**
- Bouton "Acheter ce livre" avec affiliation (Amazon, Fnac, librairies indépendantes, plateformes d'occasion) : commission 5-10 %, utilisateur ne paie pas plus cher.
- Cartes cadeaux "Premium Ela" (ex. 6 mois pour 12 €).
- Primes livres audio (Audible, Kobo) pour chaque nouvel inscrit.
- Ciblage des auteurs indépendants (auto-édition) et préventes B2B auprès des auteurs (trésorerie de lancement).

### 2.6 Design et animations ("Satisfying Design")
Décision la plus récente (lignes ~1083-1092 et ~1009-1047) :
- Thème : doux, cocooning, couleurs chaudes (mode papier/sépia ou dark mode bleu nuit/sépia / "coquille d'œuf"). Aucune lumière agressive.
- Scanner : pas de laser rouge (trop "caisse de supermarché"). Halo lumineux doux façon "lampe de chevet" (ambre/doré). À la reconnaissance, la couverture lévite avec un **doux retour haptique** (vibration sourde, type battement de cœur).
- Ajout à la PAL : animation fluide, la couverture réduit et glisse en courbe vers l'icône "Étagère" en bas de l'écran (icône qui s'élargit pour "accueillir" le livre).
- Thermomètre de popularité : icône animée (effet d'éclosion douce) à la place du nombre exact : 🔥 Phénomène, 📈 Tendance, 💎 Pépite cachée, 🏺 Classique intemporel. Décision : badges visuels plutôt que chiffre brut (ligne ~987).
- Transitions : fondu enchaîné très doux entre onglets, couleur de fond stable.
- Texte apparaissant en fondu avec effet "respiration" pendant le traitement IA.
- Pas de roue de chargement classique ; utiliser des skeleton screens / animation d'encre ou livre dont les pages se tournent au ralenti.

> **Contradicton d'animation (garder la plus récente)** : une première version proposait un filtre "laser" ou aura lumineuse (ligne ~211) ; la version finale écarte le laser rouge au profit du halo "lampe de chevet". Décision retenue : lampe de chevet.

### 2.7 Modération et communauté
- Système de signalement ("Signaler cet avis").
- Utilisation de l'IA pour bloquer automatiquement les mots injurieux / spams / publicités déguisées.

### 2.8 Marketing et acquisition (évoqués dans le fil)
- TikTok Ads : CPC moyen 0,15 € - 0,50 € ; campagne de test 10 jours, 400 € - 500 €.
- Créateurs UGC nano/micro (1 000 - 50 000 abonnés) : 80 € - 250 €/vidéo ; pack de lancement 3 à 5 vidéos, 300 € - 800 €.
- Angles suggérés : "anti-Goodreads", "Spice & Tropes", "pile de livres à la Fnac".
- "Build in Public" (vidéos gratuites), préventes B2B auteurs, ciblage BookTokers.

---

## 3. Contraintes techniques

- **Légale / propriété intellectuelle** : idées libres de parcours (concurrence autorisée), mais interdiction de copier le code/design des concurrents, d'aspirer leurs bases de données (scraping), et obligation du droit de courte citation pour la presse (lien vers l'article original).
- **API** : utiliser uniquement des API publiques et légales pour les métadonnées livres (ex. Google Books API).
- **Coût IA par scan** (estimation) : lecture 10 000-15 000 tokens (input), écriture 1 000-2 000 tokens (output).
  - Modèle économique (ex. Claude 3 Haiku / GPT-4o-mini) : ~0,004 € IA + ~0,003 € recherche web par scan.
  - Modèle premium (ex. Claude 3.5 Sonnet / GPT-4o) : ~0,06 € IA + ~0,003 € recherche web par scan.
- **Infrastructure** : serveur + IA pour jusqu'à 5 000 utilisateurs, environ 108 €/mois.
- **Cache** obligatoire pour maîtriser les coûts (pas de nouvel appel IA pour un livre déjà scanné).
- Modèle de tarification "metered paywall" / jetons IA pour limiter le coût par utilisateur gratuit.
- Choix de stack non finalisé : React Native ou Flutter ; backend, base de données, API de scraping d'avis à définir (tâches à accomplir pour la première interaction).

---

## 4. Points ouverts et contradictions (décision la plus récente retenue)

| Point | Antécédent | Décision la plus récente / État |
|-------|-----------|---------------------------------|
| Rôle de l'IA sur les avis | Rédige un "Résumé IA" (paragraphe généré) | **Super-curateur** : sélectionne/extrait les meilleurs avis existants, pas de résumé robotique (lignes ~281, ~1069) |
| Animation de scan | Filtre "laser" / aura lumineuse | **Halo "lampe de chevet"**, pas de laser rouge (lignes ~1013, ~1087) |
| Indicateur de popularité | Chiffre brut ("Noté par X millions") | **Badges visuels** 🔥📈💎🏺 (lignes ~983, ~987) |
| Traduction avis étrangers | Bouton "Traduire" à la demande (économie API) | **Traduction automatique** incluse dans le Premium (Super Prompt Définitif, ligne ~1081) — antécédent noté |
| Prix Premium | 3,99 €/mois | **2 €/mois** (projection la plus récente, ligne ~1099) |
| Nombre d'onglets page livre | 3 (Tendance/Scan/Recherche) | 3 onglets sur page livre (Synthèse IA & Presse / Le Web / La Communauté) + bottom bar Tendance/Scanner/Bibliothèque/Recherche (lignes ~1069-1101) — complémentaires, pas contradiction |
| Public cible | Gros lecteurs fiction/BookTok | **Ouvert** : alternative public large traditionnel (prix littéraires, essais, biographies) non tranchée (ligne ~761) |
| Plateforme | React Native ou Flutter | **Ouvert** : iPhone seul vs iPhone + Android non tranché (lignes ~185, ~197) |
| Stack technique | À proposer | **Non choisie** (frontend, backend, DB, API livres, IA/scraping à définir) |

---

## 5. Tâches à accomplir pour commencer (extraites du Super Prompt Définitif)

1. Proposer la stack technique idéale et détaillée (frontend, backend, base de données, API métadonnées livres via ISBN, architecture IA/scraping des avis).
2. Rédiger l'architecture globale des composants du projet.
3. Écrire le code complet du premier écran (Scanner) avec animation fluide, design cocooning et gestion élégante de la caméra (scanner "luxe", pas basique).

---
*Document généré à partir de l'extraction de la conversation Gemini partagée. Voir `conversation.txt` pour le texte brut intégral.*
