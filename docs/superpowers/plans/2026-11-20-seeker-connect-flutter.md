# Seeker Connect pour Flutter — plan de construction

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal :** un plugin Flutter `seeker_connect_flutter` qui relie les apps Flutter au SDK Kotlin officiel Seeker Connect 0.2.0, avec bouton, fenêtres et app d'exemple.

**Architecture :** une API Dart statique `SeekerConnect` parle, via un pont typé Pigeon, à un plugin Kotlin qui pilote `com.solanamobile.seekerconnect.SeekerConnect<ComponentActivity>`. La logique du pont (`Bridge<H>`) est générique sur l'hôte pour être testée sur JVM avec un faux `SeekerLink`. Bouton et fenêtres sont des widgets Flutter qui reproduisent l'officiel ; le jeton d'autorisation ne quitte jamais Kotlin.

**Tech Stack :** Flutter stable (dernière), Dart 3, Pigeon (dernière stable), Kotlin 2.x, coroutines, `com.solanamobile:seeker-connect:0.2.0`, JUnit 4 + kotlinx-coroutines-test, flutter_test.

**Spec :** `docs/superpowers/specs/2026-11-20-seeker-connect-flutter-design.md` (à lire avant toute tâche).

**Référence de code officielle** (lecture seule, Apache-2.0) : https://github.com/solana-mobile/seeker-connect — notamment `android/seeker-connect-core/…/SeekerConnect.kt`, `Models.kt`, `SeekerLink.kt`, `android/seeker-connect-compose/…/SeekerConnectButton.kt`, `SeekerConnectDialogs.kt`, `BrandVectors.kt` (`S_GLYPH_MONO_PATHS`), et le pont React Native `js/packages/react-native/android/…/SeekerConnectModule.kt`.

## Global Constraints

- Nom du paquet Dart : `seeker_connect_flutter`. Paquet Kotlin : `io.github.seekerconnectflutter`. Licence Apache-2.0 + `NOTICE` (attribution des tracés vectoriels Solana Mobile).
- Description et README : « Unofficial community Flutter plugin for Solana Mobile Seeker Connect. Not affiliated with Solana Mobile. »
- Android : dépendance `com.solanamobile:seeker-connect:0.2.0`, compileSdk 36, AGP ≥ 8.9.1, Kotlin ≥ 2.0. minSdk = celui exigé par le SDK (relevé en Task 1).
- L'app hôte doit utiliser `FlutterFragmentActivity` ; sinon erreur `hostNotSupported`.
- Le jeton d'autorisation (`authToken`) n'apparaît dans **aucun** type Pigeon ni Dart, ni dans aucun log. Aucun `toString` n'affiche de signature ou de clé complète.
- Jamais de nouvel essai automatique de `signAndSendTransactions`.
- iOS et autres plateformes : compilent ; toute méthode lève `unsupportedPlatform`, `walletAvailability()` renvoie `none`.
- Codes d'erreur (chaînes identiques côté Kotlin `FlutterError.code` et noms de l'enum Dart `SeekerConnectErrorCode`) : `noWalletFound`, `associationFailed`, `authorizationDeclined`, `requestDeclined`, `sessionClosed`, `cancelled`, `walletError`, `unsupportedPlatform`, `notConfigured`, `hostNotSupported`.
- Textes officiels des fenêtres (anglais, copiés tels quels) : progression « Continue in your Seeker Wallet » / « Accept the connection request in your wallet » ; erreurs : `noWalletFound`/`associationFailed` → « We can’t find your Seeker » / « Make sure your Seeker Wallet is setup and try again. » ; `authorizationDeclined` → « Connection declined » / « You declined the connection in your Seeker Wallet. » ; `requestDeclined` → « Request declined » / « You declined the request in your Seeker Wallet. » ; `sessionClosed` → « Connection lost » / « The connection to your Seeker Wallet was interrupted. » ; `cancelled`/`walletError` (et codes propres au module) → « Something went wrong » / « Your Seeker Wallet ran into an unexpected error. » ; bouton « Close ». (Vérifier la correspondance exacte code → texte dans `errorCopy()` de `SeekerConnectDialogs.kt` ; en cas d'écart, l'officiel fait foi.)
- Bouton : hauteur 56, largeur max 368 et pleine largeur, rayon 16, fond noir/texte blanc sur thème clair et inverse sur thème sombre, opacité 0,4 désactivé, glyphe « S » 18,2×24 avec marge droite 19 (viewport `Rect(88.4, 449, 106.6, 473)`), texte 20 medium ; libellés « Connect with Seeker » / « Sign in with Seeker ».
- Exemple : devnet uniquement (`solana:devnet`), jamais mainnet.
- Git : dépôt local, commits locaux uniquement, **aucun push**.

## Review Focus

1. **L'utilisateur quitte l'app ou Android détruit l'activité pendant que le wallet est ouvert** → l'appel Dart en cours se termine par une erreur (`cancelled` ou `sessionClosed`), il ne reste jamais bloqué. Test : Task 3, `inFlightCallCompletesWhenHostDetached`.
2. **Double appui rapide sur « Connect »** → le wallet ne s'ouvre qu'une fois, les deux appels reçoivent la même autorisation. Test : Task 3, `concurrentConnectLaunchesWalletOnce`.
3. **Appel sans activité attachée** (démarrage, arrière-plan, `FlutterActivity` classique) → erreur `hostNotSupported`, pas de plantage. Test : Task 3, `missingHostFailsWithHostNotSupported`.
4. **Listes vides ou de tailles incohérentes** passées à `signMessages` / `signTransactions` / `signAndSendTransactions` → `ArgumentError` côté Dart avant tout appel natif. Test : Task 4, `rejectsEmptyPayloads`.
5. **Hot restart Flutter / second `configure`** → la nouvelle config remplace l'ancienne sans fuite ; `restore()` retrouve l'autorisation du cache. Test : Task 3, `reconfigureReplacesClientAndKeepsCache`.

---

### Task 0 : Installer Flutter et vérifier l'environnement

**Files :** aucun dans le dépôt.

- [ ] **Step 1 : demander l'accord de l'utilisateur** pour télécharger le SDK Flutter stable officiel (source : flutter.dev / storage.googleapis.com, archive Windows d'environ 1 Go) dans `C:\Users\User\flutter` (ou `git clone https://github.com/flutter/flutter.git -b stable`), et l'ajouter au PATH utilisateur.
- [ ] **Step 2 : vérifier**
  Run : `flutter doctor -v`
  Expected : Flutter (stable) ✓, Android toolchain ✓ (accepter les licences avec `flutter doctor --android-licenses` si demandé). Visual Studio / Chrome peuvent rester en ✗.

### Task 1 : Squelette du plugin + dépendance au SDK officiel

**Files :**
- Create : squelette via `flutter create --template=plugin --platforms=android,ios --org io.github.seekerconnectflutter --project-name seeker_connect_flutter .` dans `seeker-connect-flutter/` (le dossier `docs/` existe déjà).
- Modify : `android/build.gradle(.kts)` (dépendance `com.solanamobile:seeker-connect:0.2.0`, compileSdk 36, coroutines, deps de test JUnit4 / kotlin-test / kotlinx-coroutines-test), `example/android/app/src/main/kotlin/…/MainActivity.kt` (`FlutterFragmentActivity`), versions AGP/Kotlin de `example/android` si en dessous des planchers.
- Create : `LICENSE` (Apache-2.0), `NOTICE`, `.gitignore` Flutter.

- [ ] **Step 1 :** `git init`, générer le squelette, retirer le code d'exemple généré (`getPlatformVersion`).
- [ ] **Step 2 : vérifier la résolution du SDK**
  Run : `cd example/android && ./gradlew :seeker_connect_flutter:dependencies --configuration releaseRuntimeClasspath`
  Expected : `com.solanamobile:seeker-connect:0.2.0` et `mobile-wallet-adapter-clientlib` résolus.
- [ ] **Step 3 : vérifier la compilation**
  Run : `cd example && flutter build apk --debug`
  Expected : APK construit. Noter le minSdk effectif (fusion du manifeste) dans `README.md` (section Requirements, à créer en Task 7) et dans `android/build.gradle`.
- [ ] **Step 4 : commit** `chore: scaffold plugin with official Seeker Connect SDK`

### Task 2 : Modèles Dart, erreurs et schéma Pigeon

**Files :**
- Create : `lib/src/models.dart`, `lib/src/errors.dart`, `lib/src/events.dart`, `pigeons/messages.dart`
- Generated : `lib/src/messages.g.dart`, `android/src/main/kotlin/io/github/seekerconnectflutter/Messages.g.kt`
- Test : `test/models_test.dart`

**Interfaces — Produces :**
- `class DappIdentity { String name; String uri; String? icon; }`
- `class SeekerConnectConfig { DappIdentity identity; String chain = 'solana:mainnet'; bool showDialogs = true; }`
- `enum WalletAvailability { certified, other, none }`
- `class SeekerAccount { String address; Uint8List publicKey; String? label; }`
- `class SeekerWalletCapabilities { int? maxMessagesPerRequest; int? maxTransactionsPerRequest; List<String> supportedTransactionVersions; List<String> features; bool supportsSignAndSendTransactions; }` (versions Kotlin `List<Any>` → `toString()`)
- `class StoredAuthorization { List<SeekerAccount> accounts; String? walletUriBase; String chain; SeekerWalletCapabilities capabilities; }` — **pas d'authToken**
- `class SeekerSignInPayload` (12 champs optionnels du Kotlin : domain, address, statement, uri, version, chainId, nonce, issuedAt, expirationTime, notBefore, requestId, resources)
- `class SeekerSignInResult { String address; Uint8List publicKey; Uint8List signedMessage; Uint8List signature; }`
- `class SeekerSignAndSendOptions { int? minContextSlot; String? commitment; bool? skipPreflight; int? maxRetries; bool? waitForCommitmentToSendNextTransaction; }`
- `enum SeekerConnectErrorCode` (10 valeurs des Global Constraints) ; `class SeekerConnectException implements Exception { SeekerConnectErrorCode code; String message; }` ; `SeekerConnectErrorCode codeFromString(String s)` → `walletError` si inconnu.
- `sealed class SeekerInteractionEvent` : `SeekerInteractionStarted(int id)`, `SeekerInteractionSettled(int id)`, `SeekerInteractionFailed(SeekerConnectErrorCode code)`.
- Pigeon (`pigeons/messages.dart`) : types `Pigeon*` miroirs des modèles ci-dessus ; `@HostApi() SeekerConnectHostApi` avec méthodes `@async` : `configure(PigeonConfig)`, `walletAvailability() → PigeonWalletAvailability`, `restore() → PigeonAuthorization?`, `connect() → PigeonAuthorization`, `signIn(PigeonSignInPayload?) → PigeonSignInResult`, `signMessages(List<String> addresses, List<Uint8List> payloads) → List<Uint8List>`, `signTransactions(List<Uint8List>) → List<Uint8List>`, `signAndSendTransactions(List<Uint8List>, PigeonSignAndSendOptions?) → List<Uint8List>`, `disconnect(bool revoke)`, `cancelInteraction(int id)` ; `@FlutterApi() SeekerConnectFlutterApi` : `onAuthorizationChanged(PigeonAuthorization?)`, `onInteractionStarted(int id)`, `onInteractionSettled(int id)`, `onInteractionFailed(String code)`.

- [ ] **Step 1 : tests qui échouent** dans `test/models_test.dart` :
  - `codeFromString maps all ten codes` : chaque nom → valeur ; `'bogus'` → `walletError`.
  - `toString never prints full keys or signatures` : `SeekerSignInResult(...).toString()` ne contient pas l'encodage complet de `signature` ; `StoredAuthorization.toString()` contient l'adresse.
  - `StoredAuthorization has no authToken` : vérification structurelle, ex. `expect(StoredAuthorization.new, isNot(...))` — à défaut, test qui construit l'objet avec tous ses champs nommés (échoue à la compilation si un champ token est ajouté requis) + revue.
- [ ] **Step 2 :** `flutter test test/models_test.dart` → FAIL (classes absentes).
- [ ] **Step 3 :** écrire modèles/erreurs/événements et le schéma Pigeon ; générer : `dart run pigeon --input pigeons/messages.dart` (sorties Dart + Kotlin aux chemins ci-dessus, paquet Kotlin `io.github.seekerconnectflutter`).
- [ ] **Step 4 :** `flutter test test/models_test.dart` → PASS ; `flutter analyze` → aucun problème.
- [ ] **Step 5 : commit** `feat: models, errors and Pigeon schema`

### Task 3 : Pont Kotlin (`Bridge`, présentateur, plugin)

**Files :**
- Create : `android/src/main/kotlin/io/github/seekerconnectflutter/Bridge.kt`, `FlutterPresenter.kt`, `Mapping.kt`, `SeekerConnectFlutterPlugin.kt` (remplace le fichier généré)
- Test : `android/src/test/kotlin/io/github/seekerconnectflutter/BridgeTest.kt`, `FakeSeekerLink.kt`

**Interfaces :**
- Consumes : types Pigeon de Task 2 ; SDK : `SeekerConnect<H>(config, link, cache, presenter)`, `SeekerLink<H>`, `SeekerWallet`, `MemoryAuthorizationCache`, `SeekerConnectException.Code`.
- Produces :
  - `class Bridge<H : Any>(scope: CoroutineScope, hostProvider: () -> H?, clientFactory: (SeekerConnectConfig, SeekerConnectPresenter) -> SeekerConnect<H>, events: BridgeEvents)` avec une méthode `suspend` par méthode HostApi (mêmes noms), qui lève `BridgeError(code: String, message: String)`.
  - `interface BridgeEvents { fun authorizationChanged(a: PigeonAuthorization?); fun interactionStarted(id: Long); fun interactionSettled(id: Long); fun interactionFailed(code: String) }`
  - `class FlutterPresenter(events: BridgeEvents) : SeekerConnectPresenter` + `fun cancel(id: Long)` : ids croissants, map id → cancel, `settle` retire et émet `interactionSettled`.
  - `fun SeekerConnectException.Code.toFlutterCode(): String` (7 correspondances) ; conversions `StoredAuthorization → PigeonAuthorization` sans token.
  - Plugin : `FlutterPlugin` + `ActivityAware` ; `hostProvider = { activity as? ComponentActivity }` ; `clientFactory` réel = `SeekerConnect(config, MwaSeekerLink(appContext), SharedPreferencesAuthorizationCache(appContext), presenter)` ; chaque appel HostApi lancé dans le scope (Dispatchers.Main), `BridgeError` → `FlutterError(code, message)` ; observe `client.authorization` → `events.authorizationChanged` ; scope annulé à `onDetachedFromEngine`.
- `disconnect(revoke = true)` : si une autorisation existe → `client.transact(host) { deauthorize(it.authToken) }` en capturant l'éventuelle `SeekerConnectException`, puis `client.disconnect()` **toujours**, puis relancer l'erreur capturée ; sans autorisation → `client.disconnect()` seul, sans ouvrir le wallet.

- [ ] **Step 1 : faux `SeekerLink`** (`FakeSeekerLink<FakeHost>` + `FakeWallet`) : compte les `transact`, renvoie des comptes/octets fixes, peut lever un `SeekerConnectException` programmé, peut suspendre jusqu'à libération (pour l'annulation et le double appel).
- [ ] **Step 2 : tests qui échouent** (`runTest`) dans `BridgeTest.kt` :
  - `callsBeforeConfigureFailWithNotConfigured` → `BridgeError.code == "notConfigured"`.
  - `missingHostFailsWithHostNotSupported` : `hostProvider = { null }`, `connect()` → `"hostNotSupported"`, aucun `transact`.
  - `connectReturnsAccountsWithoutToken` : adresse/clé publique transmises ; le type `PigeonAuthorization` n'a pas de champ token (compilation).
  - `signingCallsPassBytesThrough` : `signIn`, `signMessages`, `signTransactions`, `signAndSendTransactions` (avec options) transmettent les octets et options au faux wallet et renvoient ses octets intacts.
  - `walletAvailabilityIsMapped` : `CERTIFIED`/`OTHER`/`NONE` → valeurs Pigeon correspondantes.
  - `walletCodesAreMapped` : chacun des 7 `Code` levés par le faux wallet → la chaîne attendue.
  - `cancelInteractionCancelsInFlightCall` : appel suspendu, `cancelInteraction(id reçu dans interactionStarted)` → `"cancelled"`, puis `interactionSettled`.
  - `concurrentConnectLaunchesWalletOnce` : deux `connect()` simultanés → 1 `transact`, même résultat.
  - `inFlightCallCompletesWhenHostDetached` : appel suspendu puis annulation du scope/détachement → l'appel se termine en erreur, ne reste pas pendant.
  - `disconnectWithRevokeDeauthorizesThenForgets` : `deauthorize` appelé avec le token mis en cache, puis `restore()` → null.
  - `disconnectWithRevokeForgetsEvenWhenWalletFails` : le faux wallet lève `REQUEST_DECLINED` → `restore()` → null **et** `BridgeError("requestDeclined")`.
  - `disconnectWithRevokeWithoutAuthorizationDoesNotOpenWallet` → 0 `transact`.
  - `reconfigureReplacesClientAndKeepsCache` : cache partagé, `configure` ×2, la 2ᵉ identité est utilisée, `restore()` renvoie l'autorisation existante.
  - `authorizationChangesAreForwarded` : connect puis disconnect → `authorizationChanged(non-null)` puis `(null)`.
- [ ] **Step 3 :** `cd example/android && ./gradlew :seeker_connect_flutter:testDebugUnitTest` → FAIL.
- [ ] **Step 4 :** implémenter `Mapping.kt`, `FlutterPresenter.kt`, `Bridge.kt`, puis le plugin.
- [ ] **Step 5 :** même commande → PASS ; `cd example && flutter build apk --debug` → OK.
- [ ] **Step 6 : commit** `feat: Kotlin bridge to the official Seeker Connect SDK`

### Task 4 : API Dart publique `SeekerConnect`

**Files :**
- Create : `lib/src/platform.dart` (`abstract class SeekerConnectPlatform`), `lib/src/pigeon_platform.dart`, `lib/src/unsupported_platform.dart`, `lib/src/seeker_connect.dart`
- Modify : `lib/seeker_connect_flutter.dart` (exports publics uniquement : modèles, erreurs, événements, `SeekerConnect`, widgets à venir)
- Test : `test/seeker_connect_test.dart` (avec `FakeSeekerConnectPlatform`)

**Interfaces — Produces :**
- `SeekerConnectPlatform` : mêmes méthodes que la HostApi en types Dart publics + `Stream<StoredAuthorization?> get authorizationChanges` + `Stream<SeekerInteractionEvent> get interactions` + `Future<void> cancelInteraction(int id)`. `static SeekerConnectPlatform instance` (par défaut : Pigeon sur Android, Unsupported ailleurs ; remplaçable en test).
- `class SeekerConnect` (statique) : `configure`, `walletAvailability`, `restore`, `connect`, `signIn([payload])`, `signMessages(addresses, payloads)`, `signTransactions(payloads)`, `signAndSendTransactions(payloads, [options])`, `disconnect({bool revoke = false})`, `Stream<StoredAuthorization?> get authorization`, `StoredAuthorization? get currentAuthorization`, `Stream<SeekerInteractionEvent> get interactions`, `Future<void> cancelInteraction(int id)`, `SeekerConnectConfig? get config`.
- `PlatformException(code, message)` → `SeekerConnectException(codeFromString(code), message)`.

- [ ] **Step 1 : tests qui échouent** :
  - `unsupportedPlatformThrows` : `UnsupportedSeekerConnectPlatform` → `connect()` lève `unsupportedPlatform` ; `walletAvailability()` → `WalletAvailability.none`.
  - `platformExceptionsBecomeSeekerConnectExceptions` : la fausse plateforme lève `PlatformException(code: 'authorizationDeclined')` → `SeekerConnectException` avec ce code.
  - `rejectsEmptyPayloads` : `signMessages([], [])`, `signMessages(['a'], [])`, `signTransactions([])`, `signAndSendTransactions([])` → `ArgumentError`, aucun appel plateforme.
  - `currentAuthorizationFollowsStream` : la plateforme émet une autorisation puis null → `currentAuthorization` suit.
  - `disconnectPassesRevokeFlag`.
- [ ] **Step 2 :** `flutter test test/seeker_connect_test.dart` → FAIL.
- [ ] **Step 3 :** implémenter (le `PigeonSeekerConnectPlatform` enregistre le `SeekerConnectFlutterApi` et alimente deux `StreamController.broadcast`).
- [ ] **Step 4 :** `flutter test` → PASS ; `flutter analyze` → propre.
- [ ] **Step 5 : commit** `feat: public Dart API`

### Task 5 : Widget `SeekerConnectButton`

**Files :**
- Create : `lib/src/widgets/seeker_connect_button.dart`, `lib/src/widgets/brand_glyph.dart` (tracés `S_GLYPH_MONO_PATHS` portés depuis `BrandVectors.kt`, parsés avec un petit analyseur SVG de chemins ou `path_parsing` ; attribution dans `NOTICE`)
- Test : `test/widgets/seeker_connect_button_test.dart`

**Interfaces — Produces :** `enum SeekerConnectButtonVariant { connect, signIn }` ; `SeekerConnectButton({required VoidCallback? onPressed, SeekerConnectButtonVariant variant = .connect, bool enabled = true, Brightness? brightness})` (`brightness` null → `Theme.of(context).brightness`).

- [ ] **Step 1 : tests qui échouent** :
  - `hasOfficialSize` : hauteur 56 ; dans un parent de 1000 de large, largeur 368 ; dans un parent de 300, largeur 300.
  - `lightThemeIsBlackOnWhiteText` / `darkThemeIsWhiteWithBlackText` (couleurs du fond et du texte).
  - `disabledUsesFortyPercentOpacityAndIgnoresTaps`.
  - `labelsPerVariant` : « Connect with Seeker » / « Sign in with Seeker ».
  - `tapCallsOnPressed`.
- [ ] **Step 2 :** `flutter test test/widgets/seeker_connect_button_test.dart` → FAIL.
- [ ] **Step 3 :** implémenter avec les valeurs des Global Constraints.
- [ ] **Step 4 :** → PASS.
- [ ] **Step 5 : commit** `feat: official-looking Connect with Seeker button`

### Task 6 : Fenêtres `SeekerConnectDialogs` + textes

**Files :**
- Create : `lib/src/widgets/seeker_connect_dialogs.dart`, `lib/src/strings.dart`
- Test : `test/widgets/seeker_connect_dialogs_test.dart`

**Interfaces :**
- Consumes : `SeekerConnect.interactions`, `SeekerConnect.cancelInteraction(id)`, `SeekerConnect.config?.showDialogs`.
- Produces : `class SeekerConnectStrings` (tous les textes des Global Constraints, constructeur `const` avec valeurs anglaises par défaut ; `static const SeekerConnectStrings fr` traduction française) ; `SeekerConnectDialogs({required Widget child, SeekerConnectStrings strings = const SeekerConnectStrings()})` — se place autour de l'app (ex. `MaterialApp.builder`), affiche une carte par-dessus `child`.

- [ ] **Step 1 : tests qui échouent** (plateforme factice de Task 4) :
  - `startedShowsProgressCard` : titre et corps officiels visibles.
  - `closeOnProgressCancelsInteraction` : appui sur « Close » → `cancelInteraction(id)` appelé avec l'id reçu.
  - `settledHidesProgressCard`.
  - `failedShowsOfficialCopyPerCode` : boucle sur les 10 codes → titre attendu ; « Close » ferme la carte.
  - `showDialogsFalseShowsNothing`.
  - `frenchStringsAreUsedWhenProvided`.
- [ ] **Step 2 :** → FAIL. **Step 3 :** implémenter (carte centrée, fond semi-opaque, spinner pendant la progression, mêmes éléments que l'officiel au plus proche). **Step 4 :** → PASS.
- [ ] **Step 5 : commit** `feat: interaction dialogs with official copy`

### Task 7 : App d'exemple, sauvegarde Android, docs, publication à blanc

**Files :**
- Modify : `example/lib/main.dart`, `example/pubspec.yaml`, `example/android/app/src/main/AndroidManifest.xml`
- Create : `example/android/app/src/main/res/xml/data_extraction_rules.xml`, `example/android/app/src/main/res/xml/backup_rules.xml`, `README.md`, `CHANGELOG.md` (0.1.0), `docs/SEEKER_TEST_CHECKLIST.md`
- Test : `example/test/widget_test.dart`

- [ ] **Step 1 : exemple** (`chain: 'solana:devnet'`, identité `https://` de démonstration) : affiche disponibilité + adresse ; boutons Connect (`SeekerConnectButton`), Sign in, Sign message (vérifie la signature Ed25519 côté Dart avec une bibliothèque Ed25519 au choix et affiche ✓/✗), Sign devnet memo transaction (transaction mémo construite en Dart avec un blockhash devnet récent — bibliothèque Solana Dart ou sérialisation à la main, au choix ; signature seule), Sign & send devnet memo (avec avertissement), Disconnect, Disconnect + revoke. App enveloppée dans `SeekerConnectDialogs`.
- [ ] **Step 2 : sauvegarde** : le SDK officiel ne déclare aucune exclusion ; exclure `sharedpref/SeekerConnectAuthorizationCache.xml` dans `data_extraction_rules.xml` (cloud-backup + device-transfer) et `backup_rules.xml`, référencés dans le manifeste ; même extrait dans le README.
- [ ] **Step 3 : test de fumée** `example/test/widget_test.dart` : l'écran se construit avec une plateforme factice et montre « Connect with Seeker ». Run : `cd example && flutter test` → PASS.
- [ ] **Step 4 : build** `cd example && flutter build apk --debug` → APK produit (chemin indiqué à l'utilisateur pour l'installer sur son Seeker).
- [ ] **Step 5 : README** : avertissement non-officiel en tête ; installation ; changement `FlutterFragmentActivity` ; exclusion de sauvegarde ; démarrage en 15 lignes (configure + bouton + connect + signMessages) ; codes d'erreur ; avertissement « ne jamais renvoyer un sign-and-send automatiquement, vérifier on-chain » ; Android uniquement. `docs/SEEKER_TEST_CHECKLIST.md` : les cas du §5.6 de la spec, à cocher par l'utilisateur.
- [ ] **Step 6 : vérifications finales**
  Run : `flutter analyze && flutter test && (cd example/android && ./gradlew :seeker_connect_flutter:testDebugUnitTest) && flutter pub publish --dry-run`
  Expected : tout passe ; le dry-run ne signale aucune erreur (des avertissements de métadonnées type `repository` absent sont acceptables, à lister). **Ne pas publier.**
- [ ] **Step 7 : commit** `feat: example app, docs and backup rules`
