# Seeker Connect pour Flutter — conception

Date : 2026-11-20 · Statut : brouillon à valider

## 1. Pourquoi

La plainte n°1 des propriétaires de Seeker sur X depuis un an : « je n'arrive pas à connecter mon wallet Seeker » à une app. Solana Mobile a sorti le 21 octobre 2026 **Seeker Connect**, un SDK qui ouvre directement le wallet du Seeker en un bouton (« Connect with Seeker »). Il existe pour Kotlin, Expo/React Native et le web, **mais pas pour Flutter**, et aucune app connue ne l'utilise encore.

But du projet : **aider Solana Mobile à faire adopter Seeker Connect** en donnant aux développeurs Flutter un module prêt à l'emploi. Bénéfice pour la communauté : moins d'apps où le wallet du Seeker ne se connecte pas. Bénéfice pour le porteur du projet : un module public visible (pub.dev, GitHub), éligible à une Builder Grant ou au prochain hackathon, et un apprentissage concret du lien app ↔ wallet.

## 2. Objectifs, non-objectifs, anti-objectifs

**Objectifs (v0.1)**
- Un module Flutter (plugin Android) qui expose **toutes les fonctions publiques** du SDK Kotlin officiel `com.solanamobile:seeker-connect` 0.2.0 : `configure`, `walletAvailability`, `restore`, `connect`, `signIn` (SIWS), `signMessages`, `signTransactions`, `signAndSendTransactions`, `disconnect`, et l'état d'autorisation en flux.
- `disconnect(revoke: true)` qui révoque aussi le jeton côté wallet (`transact { deauthorize(it.authToken) }` puis oubli local) — demandé par la communauté côté React Native (issue #43 du dépôt officiel).
- Un widget **`SeekerConnectButton`** identique au bouton officiel.
- Des **fenêtres d'interaction** (progression avec annulation, erreur par code) identiques aux fenêtres officielles, **désactivables**.
- Une **app d'exemple** qui sert de démo et de banc de test sur un vrai Seeker.
- Des tests automatiques (Dart, Kotlin, widgets) + une check-list de test manuel sur Seeker.

**Non-objectifs (v0.1)**
- iOS : pas de wallet Seeker. Le module compile sur iOS et répond `none` / erreur `unsupportedPlatform`, sans planter.
- Flutter web (via le paquet Wallet Standard officiel) : plus tard.
- Réimplémenter le protocole Mobile Wallet Adapter en Dart.
- Le bloc `transact { … }` multi-requêtes en une seule ouverture du wallet : plus tard (v0.2).
- Le transport Nostr / relais.
- La publication sur pub.dev et l'annonce publique : faites par le porteur du projet après validation sur Seeker, hors de ce chantier.

**Anti-objectifs (échec même si « ça marche »)**
- Laisser croire que le module est officiel Solana Mobile (nom, description, README, logo hors bouton).
- Toucher, stocker ou journaliser des clés privées, phrases secrètes ou jetons d'autorisation (jamais de jeton dans les logs).
- Réessayer automatiquement un `signAndSend` qui a échoué (la doc officielle l'interdit : vérifier on-chain d'abord).
- Faire planter une app sur un téléphone non-Seeker ou sur iOS.

## 3. Contraintes

- **Android uniquement**, comme le SDK officiel. Exigences du SDK : compileSdk 36+, Android Gradle Plugin 8.9.1+, Kotlin 2.0+ (le dépôt officiel utilise Kotlin 2.4.10, coroutines 1.11.0). Version minimale d'Android : celle imposée par le SDK, à relever à la compilation.
- **Activité hôte** : le SDK lance le wallet depuis une `androidx.activity.ComponentActivity`. L'app Flutter doit donc utiliser `FlutterFragmentActivity` au lieu de `FlutterActivity` (changement d'une ligne dans `MainActivity.kt`, à documenter en tête du README). Si ce n'est pas le cas, le module renvoie une erreur claire `hostNotSupported`.
- Le SDK s'instancie ainsi : `SeekerConnect(config, MwaSeekerLink(context), SharedPreferencesAuthorizationCache(context), presenter)`. Les appels qui ouvrent le wallet prennent l'activité en paramètre.
- L'URI d'identité de l'app doit être en `https`.
- **Licence** : Apache-2.0, comme le SDK officiel. Le logo « S » du bouton est porté depuis les tracés vectoriels du dépôt officiel (Apache-2.0) : garder l'attribution dans `NOTICE`.
- **Marque** : « Seeker » est une marque de Solana Mobile. Le bouton reproduit le bouton officiel destiné aux dApps ; le README dit clairement « module communautaire, non officiel, non affilié à Solana Mobile ».
- Environnement du porteur : Windows 11, Android Studio installé (JDK + Android SDK présents), **Flutter pas encore installé**, un Seeker physique pour les tests.

## 4. Approches envisagées

| | Approche | Ce qu'elle apporte | Ce qu'elle coûte |
|---|---|---|---|
| **A (retenue)** | Pont vers le SDK Kotlin officiel ; bouton et fenêtres redessinés en Flutter à l'identique | Léger, naturel dans toute app Flutter, fenêtres désactivables / personnalisables, toute la logique wallet reste celle de Solana Mobile | Recopier fidèlement le style officiel (simple : bouton ≈ 40 lignes, 2 types de fenêtres) et le suivre s'il change |
| B | Afficher le bouton et les fenêtres Compose officiels via des vues natives (PlatformView) | Apparence garantie identique, suit les mises à jour | Compose embarqué dans chaque app, bugs d'affichage connus des vues natives dans Flutter, peu personnalisable |
| C (écartée) | Tout en Dart avec la connexion MWA classique (ex. `solana_mobile_client`) | Pas de code natif | Contourne l'ouverture directe du wallet certifié du Seeker : va contre le but du projet |

Choix : **A**, choisi par Claude (le porteur a délégué les choix techniques).

## 5. Conception

### 5.1 Structure du dépôt
```
seeker-connect-flutter/
  lib/                      API Dart publique + widgets
  android/                  plugin Kotlin (pont vers com.solanamobile:seeker-connect)
  pigeons/                  définition du pont typé (Pigeon)
  example/                  app de démo (FlutterFragmentActivity)
  test/                     tests Dart + widgets
  docs/                     conception, check-list Seeker
  README.md, CHANGELOG.md, LICENSE (Apache-2.0), NOTICE
```
Nom du paquet : **`seeker_connect_flutter`** (libre sur pub.dev au 2026-11-20 ; « seeker_connect » seul est évité pour ne pas paraître officiel). Choix de Claude.

### 5.2 API Dart (miroir du paquet React Native officiel)
```dart
await SeekerConnect.configure(SeekerConnectConfig(
  identity: DappIdentity(name: 'Mon app', uri: 'https://monapp.example', icon: 'favicon.ico'),
  chain: 'solana:mainnet',          // défaut
  showDialogs: true,                // fenêtres intégrées
));
SeekerConnect.walletAvailability();  // Future<WalletAvailability> certified | other | none
SeekerConnect.restore();             // Future<StoredAuthorization?> sans ouvrir le wallet
SeekerConnect.connect();             // Future<StoredAuthorization>
SeekerConnect.signIn([SeekerSignInPayload? payload]);           // Future<SeekerSignInResult>
SeekerConnect.signMessages(List<String> addresses, List<Uint8List> payloads);
SeekerConnect.signTransactions(List<Uint8List> payloads);
SeekerConnect.signAndSendTransactions(List<Uint8List> payloads, [SeekerSignAndSendOptions? options]);
SeekerConnect.disconnect({bool revoke = false});
SeekerConnect.authorization;          // Stream<StoredAuthorization?> + SeekerConnect.currentAuthorization
SeekerConnect.interactions;           // Stream<SeekerInteractionEvent> (started / settled / failed(code))
```
Modèles Dart = modèles Kotlin (`SeekerAccount`, `StoredAuthorization`, `SeekerWalletCapabilities`, `SeekerSignInPayload`, `SeekerSignInResult`, `SeekerSignAndSendOptions`, `DappIdentity`). Octets en `Uint8List`, adresses en base58 `String`.

**Référence en cas d'écart** (choix de Claude) : le SDK Kotlin 0.2.0 fait foi pour **ce qui existe** (fonctions, champs, comportements) ; le paquet React Native officiel sert seulement de modèle pour **la forme** de l'API Dart (méthodes statiques, noms). `SeekerWalletCapabilities` est exposé via le champ `capabilities` de `StoredAuthorization`, comme en Kotlin.

**Le jeton d'autorisation ne passe jamais en Dart** (choix de Claude, pour tenir l'anti-objectif) : la classe Dart `StoredAuthorization` contient `accounts`, `walletUriBase`, `chain`, `capabilities`, **sans `authToken`**. Le jeton reste côté Kotlin ; la signature et la révocation le relisent là-bas. Le seul stockage du jeton est celui du SDK officiel (`SharedPreferencesAuthorizationCache`, préférences privées de l'app) ; le module n'ajoute aucun stockage. Le constructeur vérifie si ce cache est exclu des sauvegardes Android ; sinon, le README et l'app d'exemple fournissent les règles d'exclusion. Aucun `toString` de modèle n'affiche de jeton ni de signature complète.

**`disconnect(revoke: true)`** (choix de Claude) : ouvre le wallet pour révoquer le jeton, avec les mêmes fenêtres (progression annulable, erreur) que les autres interactions. **Quoi qu'il arrive, l'autorisation locale est ensuite oubliée** (l'utilisateur a demandé à se déconnecter, il ne doit pas rester connecté). Si la révocation a échoué (pas de wallet, refus, annulation, session coupée), l'appel lève ensuite la `SeekerConnectException` correspondante, pour que l'app sache que le jeton peut rester valide côté wallet. Sans autorisation en cours, `revoke: true` se comporte comme une déconnexion simple, sans ouvrir le wallet.

Erreurs : `SeekerConnectException(code, message)` avec `SeekerConnectErrorCode` = les 7 codes officiels (`noWalletFound`, `associationFailed`, `authorizationDeclined`, `requestDeclined`, `sessionClosed`, `cancelled`, `walletError`) + 3 codes propres au module : `unsupportedPlatform` (iOS…), `notConfigured` (appel avant `configure`), `hostNotSupported` (pas de `ComponentActivity` attachée).

### 5.3 Pont Dart ↔ Kotlin
- **Pigeon** (génération de code typé) plutôt que des MethodChannel écrits à la main : moins d'erreurs de conversion. Choix de Claude.
- `HostApi` asynchrone (Dart → Kotlin) pour chaque fonction ci-dessus + `cancelInteraction(id)`.
- `FlutterApi` (Kotlin → Dart) pour : changements d'autorisation, `interactionStarted(id)`, `interactionSettled(id)`, `interactionFailed(id, code)`.
- Côté Kotlin : le plugin implémente `FlutterPlugin` + `ActivityAware`, garde l'activité courante (si c'est une `ComponentActivity`), crée l'instance `SeekerConnect` à `configure`, exécute les appels dans un `CoroutineScope` lié au plugin (annulé au détachement), traduit `SeekerConnectException.Code` vers les codes Dart, observe `authorization: StateFlow` pour pousser l'état vers Dart.
- Le `SeekerConnectPresenter` Kotlin transmet les débuts / fins / échecs d'interaction à Dart et garde la fonction d'annulation, appelée quand Dart envoie `cancelInteraction(id)`.

### 5.4 Interface
- **`SeekerConnectButton`** : `onPressed`, `variant` (`connect` « Connect with Seeker » / `signIn` « Sign in with Seeker »), `enabled`, `brightness` (par défaut celle du thème). Fidèle à l'officiel : hauteur 56, largeur max 368 et pleine largeur, coins arrondis 16, noir sur écran clair / blanc sur écran sombre, opacité 0,4 désactivé, logo « S » 18,2×24 avec marge droite 19, texte 20 medium.
- **`SeekerConnectDialogs`** : widget à placer une fois en haut de l'app (ou via `MaterialApp.builder`) qui écoute `SeekerConnect.interactions` :
  - progression : « Continue in your Seeker Wallet » / « Accept the connection request in your wallet », bouton Close = annule l'interaction ;
  - erreur : mêmes titres et textes que l'officiel par code (« We can't find your Seeker », « Connection declined », « Request declined », « Connection lost », « Something went wrong »).
  - Textes en anglais par défaut (copie officielle), remplaçables via un objet `SeekerConnectStrings` (une traduction française est fournie en exemple). Choix de Claude.
  - `showDialogs: false` dans la config → aucune fenêtre ; l'app peut écouter `interactions` elle-même.

### 5.5 App d'exemple
Écran unique : état (disponibilité du wallet, adresse connectée), boutons **Connect**, **Sign in**, **Sign message** (affiche la signature et la vérifie en Ed25519 côté Dart), **Sign devnet memo transaction** (signature seule, rien n'est envoyé), **Sign & send devnet memo** (optionnel, devnet seulement, avec avertissement), **Disconnect** / **Disconnect + revoke**. Chaîne : devnet. Utilise `FlutterFragmentActivity`. La construction de la transaction mémo en Dart passe par une bibliothèque Solana Dart existante (au choix du constructeur) ou des octets construits à la main ; jamais de mainnet dans l'exemple.

### 5.6 Tests
- **Dart** : API publique contre une fausse implémentation de la plateforme (conversions, erreurs, flux d'autorisation, iOS → `unsupportedPlatform`).
- **Kotlin** : le pont contre un faux `SeekerLink` (l'interface du SDK le permet) : conversion des codes, des octets, annulation, révocation, absence de `ComponentActivity`.
- **Widgets** : rendu du bouton (clair / sombre / désactivé / variante), fenêtres (progression → annulation, chaque code d'erreur, `showDialogs: false`).
- **Manuel sur Seeker** (fait par le porteur, check-list dans `docs/`) : connexion, refus, annulation, retour après relance de l'app, signature message, signature transaction, déconnexion simple et avec révocation ; et sur un Android non-Seeker si disponible (disponibilité `other`/`none`).

## 6. Critère de réussite de la v0.1
Sur le Seeker du porteur, l'app d'exemple : se connecte en un appui sur le bouton, retrouve la connexion après relance, signe un message (signature vérifiée), signe une transaction devnet, gère proprement refus et annulation, se déconnecte avec et sans révocation. Tous les tests automatiques passent. Le README permet à un développeur Flutter d'intégrer le module en moins de 15 minutes.

## 7. Laissé au constructeur
Versions exactes de Pigeon, Gradle, AGP et Flutter compatibles ; organisation interne des fichiers ; choix de la bibliothèque Solana Dart pour l'exemple ; style exact des fenêtres au-delà de ce qui est décrit ; forme des tests ; contenu détaillé du README.
