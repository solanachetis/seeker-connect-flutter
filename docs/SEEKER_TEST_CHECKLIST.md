# Liste de tests sur Seeker — v0.1.0

À faire sur un vrai Seeker avec l'app d'exemple (`example/`, réseau **devnet**).
Installer : `cd example` puis `flutter run`, ou installer `example/build/app/outputs/flutter-apk/app-debug.apk`.

Pour chaque ligne : cocher, et noter ce qui s'affiche en bas de l'écran si quelque chose ne va pas.

## Connexion
- [x] Au lancement, « Wallet: certified » s'affiche.
- [x] « Connect with Seeker » ouvre directement le Seeker Wallet, sans écran de choix de wallet.
- [ ] La fenêtre « Continue in your Seeker Wallet » apparaît pendant que le wallet est ouvert.
- [x] Après acceptation, « Account: <adresse> » s'affiche.
- [ ] Refuser la connexion dans le wallet → fenêtre « Connection declined », et l'app reste utilisable.
- [ ] Ouvrir la connexion, puis appuyer sur « Close » dans la fenêtre de l'app → « Error cancelled » en bas, rien ne reste bloqué.
- [x] Fermer complètement l'app puis la relancer → « Restored previous connection. » sans ouvrir le wallet.

## Signatures
- [x] « Sign in with Seeker » → « signature valid ✓ ».
- [x] « Sign message » → « Message signature valid ✓ ».
- [~] Refuser une signature dans le wallet → fenêtre « Request declined ».
  Résultat 2026-11-21 : le Seeker Wallet n'a pas de bouton de refus, seulement la croix ; fermer avec la croix coupe la session → fenêtre « Connection lost » (`sessionClosed`). Comportement du wallet, pas du module.
- [x] « Sign devnet memo transaction » → « Devnet transaction signed (not sent) ».
- [ ] (Optionnel, demande un peu de SOL devnet sur l'adresse) « Sign & send devnet memo » → une signature s'affiche ; la vérifier sur un explorateur devnet.

## Déconnexion
- [x] « Disconnect » → « Not connected », sans ouvrir le wallet.
- [x] Se reconnecter, puis « Disconnect + revoke » → le wallet s'ouvre, puis « Disconnected and revoked in the wallet. »
- [ ] Après une révocation, « Connect with Seeker » redemande l'autorisation dans le wallet.

## Cas limites
- [ ] Tourner l'écran pendant que le wallet est ouvert → l'action se termine normalement.
- [ ] Appuyer deux fois très vite sur « Connect with Seeker » → le wallet ne s'ouvre qu'une fois.
- [ ] (Si un autre téléphone Android est disponible) « Wallet: other » ou « none », et l'app ne plante pas.

## À noter
- Date du test : 2026-11-21 (APK debug, commit f51b2cc)
- Version du Seeker Wallet : 1.22.0 (com.solanamobile.wallet)
- Version d'Android du Seeker : 16
- Problèmes rencontrés :
  - Wallet réglé sur mainnet + transaction devnet → le wallet affiche « Network mismatch » puis la session se ferme (`sessionClosed`). Passer le wallet sur devnet a réglé le problème. Le wallet avait pourtant accepté l'autorisation `solana:devnet`.
  - Pas de bouton de refus dans le wallet : un refus arrive toujours en `sessionClosed`, jamais en `requestDeclined`.
  - Les capacités annoncées par le wallet indiquent `supportsSignAndSendTransactions: false` (features : `solana:signTransactions`, versions : `legacy`).
  - Fenêtres de progression/erreur du module : affichage correct sur l'appareil (thème sombre).
