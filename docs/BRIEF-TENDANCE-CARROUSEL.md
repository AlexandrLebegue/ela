# Brief : page Tendance « catchy » avec carrousel (demande Chef 31/10 02h)

La page Tendance est LA plus importante de l app (premier écran). Retour de Chef : pas assez accrocheuse. Refais sa mise en page pour qu elle donne vraiment envie, en restant dans la DA « livre » (papier, typo littéraire, bordeaux) établie dans lib/core/design.

## Attendu
1. **Carrousel héros** en haut : grandes couvertures (≈ 60-70 % de la largeur), effet coverflow / perspective (la carte centrale grande et nette, voisines plus petites, inclinées, atténuées), défilement fluide au doigt avec snap, indicateurs de page, défilement auto lent (pause au toucher). Titre, auteur, accroche courte et badge (« N°1 », « En hausse », « Coup de cœur ») sous la carte active, avec transition animée au changement. Fond qui reprend la teinte dominante de la couverture active (dégradé doux), animé.
2. Tap sur la carte -> fiche de lecture avec transition Hero sur la couverture. Bouton rapide « + Pile à lire ».
3. Sous le héros : rangées horizontales thématiques défilables (ex. « En hausse cette semaine », « Classiques qu on relit », « Courts, à lire en une soirée »), petites couvertures, numéros de classement stylés façon typographie de livre pour le top 10.
4. Micro-animations soignées (apparition en cascade, parallaxe légère au scroll), 60 fps visés, accessibilité conservée (Semantics, texte ×1,3, réduction des animations si l OS le demande -> pas d auto-défilement).
5. Couvertures : utiliser les vraies si dispo, sinon la couverture générée existante (book_cover.dart) rendue plus riche. Données fake existantes acceptées (étoffer demo_books si nécessaire pour remplir le carrousel et les rangées).
6. Mode jour ET nuit, pas d overflow en 360x640.

## Livrables
- Tests/goldens à jour, `flutter analyze` propre, tests verts.
- Captures avant/après de Tendance (jour + nuit) + une petite séquence de 3-4 captures du carrousel à différentes positions dans docs/screens/tendance/.
- Rebuild web (build/web, servi par ProxBoss sur :8240) puis APK dist/ela.apk. Commits séparés, push. Mettre à jour docs/VALIDATION-UI.md.
Commandes lourdes séquentielles (RAM LXC limitée), pas de daemon Gradle.
