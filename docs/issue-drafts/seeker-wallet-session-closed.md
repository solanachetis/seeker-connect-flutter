# Brouillon de signalement pour Solana Mobile
n**Publié le 2026-11-21 (une seule issue) :** https://github.com/solana-mobile/seeker-connect/issues/44

**Où le publier :** https://github.com/solana-mobile/seeker-connect/issues/new
(leur `CONTRIBUTING.md` demande de passer par une issue, une question par issue, avec les versions).
Ce brouillon contient deux problèmes liés. Tu peux soit les publier en une seule issue (ils ont la même cause côté wallet),
soit les séparer en deux issues (titres A et B ci-dessous) pour respecter « une question par issue ».

**Avant de publier, vérifie :**
- aucune capture d'écran sans flouter ton nom `.skr` et ton adresse (la feuille du wallet affiche ton nom `.skr`) ;
- c'est toi qui publies, avec ton compte GitHub.

---

## Titre (une seule issue)

Seeker Wallet 1.22.0 closes the MWA session instead of returning an error, so Seeker Connect apps get `SESSION_CLOSED` for declines and network mismatches

## Corps

**Versions**
- Device: Solana Seeker, Android 16
- Seeker Wallet: 1.22.0 (`com.solanamobile.wallet`)
- SDK: `com.solanamobile:seeker-connect` 0.2.0 (Kotlin), used through a community Flutter wrapper ([link to the repo once public])
- Transport: local association (`LocalAssociationScenario`)

**Summary**

In two common cases the Seeker Wallet stops its local MWA WebSocket server without sending a JSON-RPC error for the pending request. The SDK then (correctly) reports `SeekerConnectException.Code.SESSION_CLOSED`, and `SeekerConnectDialogs` shows *Connection lost*. Apps cannot tell a user decline or a wallet-side validation failure from a real interruption, and `REQUEST_DECLINED` is never produced.

### A. Declining a signing request

Steps:
1. `connect()` (accepted).
2. `signMessages(...)` (or `signTransactions(...)`).
3. In the wallet's bottom sheet, decline. There is no reject button; the only way is the close (×) button.

Expected: the wallet answers the request with an MWA "not signed" error, the SDK throws `REQUEST_DECLINED`, the official card shows *Request declined*.

Actual: the wallet logs `JSON-RPC 2.0 message received`, then ~4 s later `Stopping local mobile-wallet-adapter WebSocket server` with no `Responding with ...` line for that request. The dapp sees `LocalAssociationScenario: Session terminated normally` and the SDK throws `SESSION_CLOSED`.

### B. Network mismatch only surfaces at signing time, also as a closed session

Steps:
1. Seeker Wallet network set to **mainnet** (wallet settings).
2. Dapp configured with `chain = "solana:devnet"`; `connect()` succeeds (the wallet issues an authorization for devnet).
3. `signTransactions(...)` with a legacy transaction using a recent **devnet** blockhash.

Expected: either `authorize` fails for a chain the wallet is not on, or the signing request returns an MWA error the dapp can map to a clear message.

Actual: the wallet shows *Network mismatch – Your current network is set to mainnet, but this transaction is for devnet*; after closing it, the session is terminated without a response and the SDK throws `SESSION_CLOSED`. After switching the wallet to devnet, the same request is signed normally.

**Why it matters for Seeker Connect adoption**

Developers following the docs will map `REQUEST_DECLINED` to "user said no" and `SESSION_CLOSED` to "something broke". On the Seeker today, every decline lands in the second bucket, and the built-in cards tell users the connection was lost when they simply said no.

**Possible directions**
- Wallet: reply to the pending request with the MWA "not signed" error when the sheet is dismissed, and with an error (or refuse `authorize`) on a chain mismatch.
- SDK/docs: until then, document that on Seeker Wallet a dismissal arrives as `SESSION_CLOSED`, and consider softer copy for `SESSION_CLOSED` during a signing request.

**Side observation (not verified further):** `get_capabilities` returned `supports_sign_and_send_transactions: false`, features `["solana:signTransactions"]`, transaction versions `["legacy"]`. If that legacy flag doesn't reflect actual sign-and-send support under MWA 2.0, apps that read `SeekerWalletCapabilities.supportsSignAndSendTransactions` may hide a feature that works.

Happy to test a fix on a device.

---

## Si tu préfères deux issues

- **A.** « Seeker Wallet: dismissing a signing request closes the MWA session instead of returning "not signed" (apps get SESSION_CLOSED, never REQUEST_DECLINED) » → Versions + Summary + section A + Why it matters.
- **B.** « Seeker Wallet: chain mismatch (wallet on mainnet, dapp on devnet) is accepted at authorize and fails at signing as SESSION_CLOSED » → Versions + section B.
