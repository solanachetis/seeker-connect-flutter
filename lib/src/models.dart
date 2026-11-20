import 'dart:typed_data';

/// The dapp identity shown by the wallet. [uri] must be `https`.
class DappIdentity {
  const DappIdentity({required this.name, required this.uri, this.icon});

  final String name;
  final String uri;

  /// Icon path relative to [uri], or an absolute URL.
  final String? icon;
}

/// Plugin configuration, passed to `SeekerConnect.configure`.
class SeekerConnectConfig {
  const SeekerConnectConfig({
    required this.identity,
    this.chain = 'solana:mainnet',
    this.showDialogs = true,
  });

  final DappIdentity identity;

  /// CAIP-2 chain id, e.g. `solana:mainnet` or `solana:devnet`.
  final String chain;

  /// Whether `SeekerConnectDialogs` shows its built-in progress/error cards.
  final bool showDialogs;
}

/// Which wallet a connection would reach on this device.
enum WalletAvailability {
  /// A certified wallet (the Seeker's own) opens directly.
  certified,

  /// No certified wallet, but another Mobile Wallet Adapter wallet: the system chooser opens.
  other,

  /// No compatible wallet.
  none,
}

/// An account authorized by the wallet.
class SeekerAccount {
  const SeekerAccount({required this.address, required this.publicKey, this.label});

  /// Base58 address.
  final String address;
  final Uint8List publicKey;
  final String? label;

  @override
  String toString() => 'SeekerAccount($address${label == null ? '' : ', $label'})';
}

/// What the connected wallet supports.
class SeekerWalletCapabilities {
  const SeekerWalletCapabilities({
    this.maxMessagesPerRequest,
    this.maxTransactionsPerRequest,
    this.supportedTransactionVersions = const [],
    this.features = const [],
    this.supportsSignAndSendTransactions = false,
  });

  final int? maxMessagesPerRequest;
  final int? maxTransactionsPerRequest;
  final List<String> supportedTransactionVersions;
  final List<String> features;
  final bool supportsSignAndSendTransactions;
}

/// The authorization held by the app. The wallet's auth token never leaves
/// the native side, so it is deliberately absent here.
class StoredAuthorization {
  const StoredAuthorization({
    required this.accounts,
    required this.walletUriBase,
    required this.chain,
    required this.capabilities,
  });

  final List<SeekerAccount> accounts;
  final String? walletUriBase;
  final String chain;
  final SeekerWalletCapabilities capabilities;

  @override
  String toString() => 'StoredAuthorization(accounts: $accounts, chain: $chain)';
}

/// Sign-In With Solana payload. All fields are optional.
class SeekerSignInPayload {
  const SeekerSignInPayload({
    this.domain,
    this.address,
    this.statement,
    this.uri,
    this.version,
    this.chainId,
    this.nonce,
    this.issuedAt,
    this.expirationTime,
    this.notBefore,
    this.requestId,
    this.resources,
  });

  final String? domain;
  final String? address;
  final String? statement;
  final String? uri;
  final String? version;
  final String? chainId;
  final String? nonce;
  final String? issuedAt;
  final String? expirationTime;
  final String? notBefore;
  final String? requestId;
  final List<String>? resources;
}

/// Result of a Sign-In With Solana request.
class SeekerSignInResult {
  const SeekerSignInResult({
    required this.address,
    required this.publicKey,
    required this.signedMessage,
    required this.signature,
  });

  final String address;
  final Uint8List publicKey;
  final Uint8List signedMessage;
  final Uint8List signature;

  @override
  String toString() => 'SeekerSignInResult($address)';
}

/// Options for `signAndSendTransactions`.
class SeekerSignAndSendOptions {
  const SeekerSignAndSendOptions({
    this.minContextSlot,
    this.commitment,
    this.skipPreflight,
    this.maxRetries,
    this.waitForCommitmentToSendNextTransaction,
  });

  final int? minContextSlot;
  final String? commitment;
  final bool? skipPreflight;
  final int? maxRetries;
  final bool? waitForCommitmentToSendNextTransaction;
}
