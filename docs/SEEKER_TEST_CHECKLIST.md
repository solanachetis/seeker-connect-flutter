# Liste de tests sur Seeker — v0.1.0

À faire sur un vrai Seeker avec l'app d'exemple (`example/`, réseau **devnet**).
Installer : `cd example` puis `flutter run`, ou installer `example/build/app/outputs/flutter-apk/app-debug.apk`.

Pour chaque ligne : cocher, et noter ce qui s'affiche en bas de l'écran si quelque chose ne va pas.

## Connexion
- [ ] Au lancement, « Wallet: certified » s'affiche.
- [ ] « Connect with Seeker » ouvre directement le Seeker Wallet, sans écran de choix de wallet.
- [ ] La fenêtre « Continue in your Seeker Wallet » apparaît pendant que le wallet est ouvert.
- [ ] Après acceptation, « Account: <adresse> » s'affiche.
- [ ] Refuser la connexion dans le wallet → fenêtre « Connection declined », et l'app reste utilisable.
- [ ] Ouvrir la connexion, puis appuyer sur « Close » dans la fenêtre de l'app → « Error cancelled » en bas, rien ne reste bloqué.
- [ ] Fermer complètement l'app puis la relancer → « Restored previous connection. » sans ouvrir le wallet.

## Signatures
- [ ] « Sign in with Seeker » → « signature valid ✓ ».
- [ ] « Sign message » → « Message signature valid ✓ ».
- [ ] Refuser une signature dans le wallet → fenêtre « Request declined ».
- [ ] « Sign devnet memo transaction » → « Devnet transaction signed (not sent) ».
- [ ] (Optionnel, demande un peu de SOL devnet sur l'adresse) « Sign & send devnet memo » → une signature s'affiche ; la vérifier sur un explorateur devnet.

## Déconnexion
- [ ] « Disconnect » → « Not connected », sans ouvrir le wallet.
- [ ] Se reconnecter, puis « Disconnect + revoke » → le wallet s'ouvre, puis « Disconnected and revoked in the wallet. »
- [ ] Après une révocation, « Connect with Seeker » redemande l'autorisation dans le wallet.

## Cas limites
- [ ] Tourner l'écran pendant que le wallet est ouvert → l'action se termine normalement.
- [ ] Appuyer deux fois très vite sur « Connect with Seeker » → le wallet ne s'ouvre qu'une fois.
- [ ] (Si un autre téléphone Android est disponible) « Wallet: other » ou « none », et l'app ne plante pas.

## À noter
- Version du Seeker Wallet :
- Version d'Android du Seeker :
- Problèmes rencontrés :
