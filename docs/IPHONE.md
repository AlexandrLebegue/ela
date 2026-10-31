# Installer Ela sur iPhone

Ce guide permet d'installer l'application Ela sur un iPhone **sans compte
développeur Apple payant**, avec un simple identifiant Apple (Apple ID) et un
ordinateur. Il faut compter environ 20 minutes la première fois.

> **À savoir avant de commencer**
> - L'application n'est pas sur l'App Store : on l'installe soi-même avec
>   l'outil gratuit **Sideloadly**.
> - Avec un Apple ID gratuit, l'application **expire au bout de 7 jours**. Il
>   suffit alors de refaire l'étape 4 (2 minutes) : la bibliothèque et les
>   réglages de l'app sont conservés.

## Ce qu'il faut

- Un iPhone sous iOS 13 ou plus récent, et son câble USB.
- Un ordinateur Windows 10/11 ou un Mac.
- Un Apple ID (celui de l'iPhone convient). Si la validation en deux étapes
  est activée, garder l'iPhone à portée de main pour recevoir le code.

## 1. Télécharger l'application

Ouvrir la page des
[releases d'Ela](https://github.com/AlexandrLebegue/ela/releases/latest)
et télécharger, dans la rubrique *Assets*, le fichier
**`ela-vX.Y.Z-unsigned.ipa`** (par exemple `ela-v0.2.0-unsigned.ipa`).
Ne pas l'ouvrir : le garder dans le dossier Téléchargements.

Le fichier `SHA256SUMS-ios` permet de vérifier que le téléchargement est
intact (facultatif).

## 2. Préparer l'ordinateur

**Sur Windows** (sur Mac, passer directement au point 3) :

1. Installer **iTunes** et **iCloud** dans leur version téléchargée depuis le
   site d'Apple, **pas** celle du Microsoft Store : Sideloadly en a besoin pour
   dialoguer avec l'iPhone. Les liens sont donnés sur la page de Sideloadly.
2. Redémarrer l'ordinateur après l'installation.

**Sur Windows et sur Mac :**

3. Télécharger et installer **Sideloadly** depuis son site officiel :
   <https://sideloadly.io>. Ne pas utiliser d'autre site.

## 3. Brancher l'iPhone

1. Brancher l'iPhone à l'ordinateur avec le câble et le déverrouiller.
2. Si l'iPhone demande « Faire confiance à cet ordinateur ? », appuyer sur
   **Se fier** puis saisir le code de l'iPhone.

## 4. Installer Ela avec Sideloadly

1. Ouvrir Sideloadly. L'iPhone doit apparaître dans la liste *iDevice* en haut.
2. Glisser le fichier `.ipa` d'Ela sur la grande icône *IPA* à gauche (ou
   cliquer dessus pour le sélectionner).
3. Dans le champ *Apple account*, saisir l'adresse e-mail de l'Apple ID.
4. Cliquer sur **Start**, puis saisir le mot de passe de l'Apple ID quand il est
   demandé (et le code reçu sur l'iPhone si la validation en deux étapes est
   active). Le mot de passe est envoyé uniquement à Apple.
5. Attendre le message **Done** en bas de la fenêtre (1 à 2 minutes).
   L'icône Ela apparaît sur l'iPhone.

## 5. Autoriser l'application sur l'iPhone

Au premier lancement, iOS bloque l'application tant qu'on ne l'a pas autorisée.

1. **Faire confiance au développeur** : *Réglages* → *Général* →
   *VPN et gestion de l'appareil* → toucher l'adresse de l'Apple ID →
   **Faire confiance** → confirmer.
2. **Mode développeur** (iOS 16 et plus récents seulement) :
   *Réglages* → *Confidentialité et sécurité* → tout en bas,
   *Mode développeur* → activer → l'iPhone redémarre → après le redémarrage,
   confirmer **Activer**.
   Si l'option n'apparaît pas, essayer d'abord d'ouvrir Ela une fois,
   puis revenir dans ce menu.

## 6. Premier lancement

1. Ouvrir **Ela**.
2. À la première ouverture du **scanner**, iOS demande l'accès à
   l'**appareil photo** : répondre **Autoriser** (il sert uniquement à lire le
   code-barres ISBN des livres). Sans cet accès, la saisie manuelle de l'ISBN
   reste possible.
3. Une connexion Internet (Wi-Fi ou 4G/5G) est nécessaire pour la recherche de
   livres, les couvertures et les avis.

## 7. Tous les 7 jours : renouveler l'installation

Quand Ela ne s'ouvre plus (message « n'est plus disponible ») :
rebrancher l'iPhone, ouvrir Sideloadly et refaire l'étape 4 avec le même
fichier `.ipa` (ou celui de la dernière version). Les étapes 5 et 6 ne sont pas
à refaire.

## En cas de problème

| Problème | Solution |
|---|---|
| L'iPhone n'apparaît pas dans Sideloadly | Débloquer l'iPhone, accepter « Se fier », changer de câble ou de port USB. Sur Windows, vérifier qu'iTunes est la version du site d'Apple. |
| Erreur de mot de passe dans Sideloadly | Vérifier l'Apple ID sur appleid.apple.com, puis réessayer. |
| « Développeur non approuvé » à l'ouverture | Refaire l'étape 5.1. |
| « Mode développeur requis » | Refaire l'étape 5.2. |
| Le scanner reste noir | Autoriser la caméra : *Réglages* → *Ela* → *Appareil photo*. |
| L'application s'est arrêtée de fonctionner après une semaine | Normal avec un Apple ID gratuit : voir l'étape 7. |

## Limites de cette version de test

- Version de test, non signée par Apple : à réserver à un usage personnel.
- Un Apple ID gratuit permet au plus 3 applications installées de cette façon.

## Pour les mainteneurs

L'IPA est produite par le workflow GitHub Actions `.github/workflows/ios.yml`
(runner macOS, `flutter build ios --release --no-codesign`, puis empaquetage
`Payload/Runner.app` en `.ipa`) :

- à chaque tag `v*` : l'IPA est jointe automatiquement à la release du tag ;
- à la demande (*Actions* → *iOS* → *Run workflow*) : saisir un tag existant
  (ex. `v0.2.0`) pour compléter sa release, ou laisser vide pour obtenir
  seulement l'artefact `ela-ipa-unsigned`.
