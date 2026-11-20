## 0.1.0

First release (unofficial community plugin).

- Wraps the official Seeker Connect Android SDK `com.solanamobile:seeker-connect` 0.2.0.
- `SeekerConnect`: configure, walletAvailability, restore, connect, signIn, signMessages, signTransactions, signAndSendTransactions, disconnect (with optional revoke), authorization stream, interaction events.
- `SeekerConnectButton` and `SeekerConnectDialogs` with the official copy, plus a French translation.
- The wallet auth token never crosses into Dart.
- Android only; other platforms report `unsupportedPlatform`.
