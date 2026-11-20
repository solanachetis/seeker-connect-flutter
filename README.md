# seeker_connect_flutter

> **Unofficial community Flutter plugin for Solana Mobile Seeker Connect.**
> Not affiliated with, endorsed by, or maintained by Solana Mobile.
> It wraps the official [Seeker Connect Android SDK](https://github.com/solana-mobile/seeker-connect) (`com.solanamobile:seeker-connect` 0.2.0).

Add a one-tap **"Connect with Seeker"** button to your Flutter app. On a Solana Seeker it opens the phone's own wallet directly: no wallet picker, no "Mobile Wallet Adapter" option to explain. On other Android phones it falls back to any compatible Mobile Wallet Adapter wallet.

- Connect, restore after relaunch, disconnect (optionally revoking in the wallet)
- Sign-In With Solana
- Sign messages, sign transactions, sign and send transactions
- `SeekerConnectButton`, matching the official button
- `SeekerConnectDialogs`: progress and error cards with the official copy (English, French provided), which you can turn off
- The wallet's auth token never leaves the native side

**Android only**, like the official SDK. On iOS and other platforms every call reports `SeekerConnectErrorCode.unsupportedPlatform` and `walletAvailability()` returns `none`.

## Requirements

- Flutter 3.50+ / Dart 3.14+ (developed and tested on Flutter 3.50.1)
- Android `minSdk` 24, `compileSdk` 36, Android Gradle Plugin 8.9.1+, Kotlin 2.0+
- **Your `MainActivity` must extend `FlutterFragmentActivity`** (see step 2)

## Setup

### 1. Add the package

```yaml
dependencies:
  seeker_connect_flutter: ^0.1.0
```

### 2. Use `FlutterFragmentActivity`

Seeker Connect launches the wallet from an androidx `ComponentActivity`. In `android/app/src/main/kotlin/.../MainActivity.kt`:

```kotlin
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
```

Without this, wallet calls fail with `hostNotSupported`.

### 3. Keep the wallet authorization out of Android backups (recommended)

The SDK stores the wallet authorization in the app's private `SeekerConnectAuthorizationCache` preferences. Exclude it from cloud backups and device transfers. Create `android/app/src/main/res/xml/data_extraction_rules.xml`:

```xml
<data-extraction-rules>
    <cloud-backup>
        <exclude domain="sharedpref" path="SeekerConnectAuthorizationCache.xml" />
    </cloud-backup>
    <device-transfer>
        <exclude domain="sharedpref" path="SeekerConnectAuthorizationCache.xml" />
    </device-transfer>
</data-extraction-rules>
```

and `android/app/src/main/res/xml/backup_rules.xml`:

```xml
<full-backup-content>
    <exclude domain="sharedpref" path="SeekerConnectAuthorizationCache.xml" />
</full-backup-content>
```

then reference both on `<application>` in `AndroidManifest.xml`:

```xml
android:dataExtractionRules="@xml/data_extraction_rules"
android:fullBackupContent="@xml/backup_rules"
```

## Quick start

```dart
import 'package:flutter/widgets.dart';
import 'package:seeker_connect_flutter/seeker_connect_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SeekerConnect.configure(const SeekerConnectConfig(
    identity: DappIdentity(name: 'My App', uri: 'https://myapp.example', icon: 'favicon.ico'),
    chain: 'solana:mainnet', // or 'solana:devnet'
  ));
  await SeekerConnect.restore(); // previous connection, without opening the wallet
  runApp(MyApp()); // wrap your app: builder: (_, child) => SeekerConnectDialogs(child: child!)
}

// Anywhere in your UI:
SeekerConnectButton(onPressed: () async {
  try {
    final auth = await SeekerConnect.connect();
    final address = auth.accounts.first.address;
    final signed = await SeekerConnect.signMessages([address], [utf8.encode('Hello')]);
  } on SeekerConnectException catch (e) {
    // e.code: authorizationDeclined, requestDeclined, noWalletFound, …
  }
});
```

Show the built-in cards by wrapping your app once, e.g. `MaterialApp(builder: (context, child) => SeekerConnectDialogs(child: child!))`. Pass `strings: SeekerConnectStrings.fr` for French, or your own `SeekerConnectStrings`. Set `showDialogs: false` in the config to draw your own UI from `SeekerConnect.interactions`.

## API

| Call | What it does |
|---|---|
| `configure(config)` | Sets the dapp identity (https URI) and chain. Call first. |
| `walletAvailability()` | `certified` (the Seeker wallet opens directly), `other` (system chooser), or `none`. Opens nothing. |
| `restore()` | The cached authorization, without opening the wallet. |
| `connect()` | Restores, or opens the wallet to authorize. Concurrent calls open the wallet once. |
| `signIn([payload])` | Sign-In With Solana. |
| `signMessages(addresses, payloads)` | Signs each payload. Wallets may return the signature alone (64 bytes) or the message with the signature appended. |
| `signTransactions(payloads)` | Returns signed transaction bytes. |
| `signAndSendTransactions(payloads, [options])` | Signs and submits; returns signatures. |
| `disconnect({revoke})` | Forgets the authorization. With `revoke: true`, first asks the wallet to revoke it; the app is disconnected even if that fails, and the error is then thrown. |
| `authorization` / `currentAuthorization` | Stream and current value of the held authorization. |
| `interactions` / `cancelInteraction(id)` | Wallet interaction events, for custom UI. |

### Error codes (`SeekerConnectErrorCode`)

`noWalletFound`, `associationFailed`, `authorizationDeclined`, `requestDeclined`, `sessionClosed`, `cancelled`, `walletError` (from the official SDK), plus `unsupportedPlatform`, `notConfigured`, `hostNotSupported`.

> ⚠️ **Never retry `signAndSendTransactions` automatically**, even after `sessionClosed`: the transaction may already have been submitted. Check on-chain first.

## Example

`example/` is a devnet-only demo: connect, Sign-In With Solana, sign a message (with Ed25519 verification), sign a memo transaction, sign and send it, disconnect, disconnect and revoke.

```sh
cd example
flutter run
```

## License

Apache-2.0. See `LICENSE` and `NOTICE`. "Seeker" and the Seeker marks are trademarks of Solana Mobile Inc.
