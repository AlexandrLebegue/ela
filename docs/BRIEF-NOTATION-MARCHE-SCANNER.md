# Brief : notation, Marché (marketplace), scanner sobre (demande Chef 31/10 02h35)

Retours de Chef après la refonte Tendance : « il manque le marketplace, le scanner QR est trop bizarre coloré comme ça, et il manque surtout tout le système de notation ». Les couvertures réelles s affichent bien chez lui (ne pas toucher à ça).
Ordre de priorité : 1 notation (le plus important), 2 Marché, 3 scanner. Garder la DA « livre » (lib/core/design), jour + nuit, 360x640 sans overflow, accessibilité.

## 1. Système de notation (PRIORITÉ)
- Modèle : note 0,5 à 5 étoiles (demi-étoiles) par utilisateur et par livre ; ajouter `rating` aux avis communauté (Review) ; notes presse/web converties sur 5 quand la source en donne une (sinon pas de note). Services fake + interfaces prêtes pour Firebase (même architecture que review_service / library).
- Moyenne communauté + nombre de notes + histogramme 5→1 sur la fiche de lecture, en tête, bien visible (grand chiffre typographique « 4,3 » + étoiles).
- Noter un livre : widget étoiles tactile (glisser pour demi-étoiles, retour haptique), depuis la fiche et depuis la Bibliothèque (« Lu » -> proposer de noter). Rédiger un avis communauté = note obligatoire + texte optionnel. Modifier/supprimer sa note.
- Affichage partout : étoiles + moyenne sur les cartes du carrousel Tendance, les rangées, la recherche, la bibliothèque (sa note perso). Tri par note dans la Bibliothèque et rangée « Les mieux notés » sur Tendance.
- Données démo réalistes (notes variées par livre, quelques centaines de votes simulés).
- Tests unitaires (moyenne, demi-étoiles, arrondi, modification) + goldens.

## 2. Marché (marketplace)
- Nouvel onglet de navigation « Marché » (barre du bas : garder 5 entrées max, réorganiser proprement).
- Pour un livre : comparateur d offres neuf (Fnac, Amazon, librairies indépendantes / Place des Libraires) et occasion (Rakuten, Momox, Recyclivre, Vinted, Leboncoin) : prix, état (comme neuf / très bon / bon / correct), frais de port, lien affilié (affiliatePurchaseLink existant). Tri prix total / état, meilleure offre mise en avant. Intégrer le Radar à économies existant (Premium) dans ce Marché plutôt qu un écran isolé.
- Annonces entre lecteurs : vendre un livre de sa Bibliothèque (prix, état, photo optionnelle, ville), liste des annonces proches, fiche annonce, bouton « Contacter » (fake). Le tout en fake service, interface prête pour un backend.
- Depuis la fiche de lecture : bloc « Où l acheter » (meilleur prix neuf / occasion) -> ouvre le Marché filtré sur ce livre.
- Page d accueil du Marché : bonnes affaires du moment, annonces récentes, recherche.

## 3. Scanner sobre
- Le scanner actuel est trop coloré / bizarre. Le refaire sobre et élégant : aperçu caméra plein écran, voile sombre neutre, cadre de visée fin (coins blancs ou crème), ligne de balayage discrète, une seule touche d accent bordeaux maximum, texte d aide court. Saisie manuelle d ISBN en feuille basse discrète. Retour haptique + petite animation à la détection. Scan code-barres EAN-13 (ISBN), pas besoin de QR.

## Livrables
- flutter analyze propre, tests verts (anciens + nouveaux).
- Captures dans docs/screens/v2/ : fiche avec notation (jour/nuit), widget de notation, Tendance avec étoiles, Marché accueil + comparateur + annonce, scanner avant/après.
- Rebuild web (build/web, servi sur :8240) puis APK dist/ela.apk. Commits séparés par partie, push. Mettre à jour docs/VALIDATION-UI.md.
- Commandes lourdes séquentielles (RAM LXC limitée), pas de daemon Gradle.
