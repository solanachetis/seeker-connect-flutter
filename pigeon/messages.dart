import 'package:pigeon/pigeon.dart';

// Bridge between the Dart API and the Kotlin plugin.
// Regenerate with: dart run pigeon --input pigeon/messages.dart
//
// Security rule: the wallet's auth token never appears in any type here.

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'seeker_connect_flutter',
    dartOut: 'lib/src/messages.g.dart',
    kotlinOut:
        'android/src/main/kotlin/io/github/seekerconnectflutter/seeker_connect_flutter/Messages.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'io.github.seekerconnectflutter.seeker_connect_flutter',
    ),
  ),
)
class MsgDappIdentity {
  MsgDappIdentity({required this.name, required this.uri, this.icon});
  String name;
  String uri;
  String? icon;
}

class MsgConfig {
  MsgConfig({required this.identity, required this.chain});
  MsgDappIdentity identity;
  String chain;
}

enum MsgWalletAvailability { certified, other, none }

class MsgAccount {
  MsgAccount({required this.address, required this.publicKey, this.label});
  String address;
  Uint8List publicKey;
  String? label;
}

class MsgCapabilities {
  MsgCapabilities({
    this.maxMessagesPerRequest,
    this.maxTransactionsPerRequest,
    required this.supportedTransactionVersions,
    required this.features,
    required this.supportsSignAndSendTransactions,
  });
  int? maxMessagesPerRequest;
  int? maxTransactionsPerRequest;
  List<String> supportedTransactionVersions;
  List<String> features;
  bool supportsSignAndSendTransactions;
}

class MsgAuthorization {
  MsgAuthorization({
    required this.accounts,
    this.walletUriBase,
    required this.chain,
    required this.capabilities,
  });
  List<MsgAccount> accounts;
  String? walletUriBase;
  String chain;
  MsgCapabilities capabilities;
}

class MsgSignInPayload {
  MsgSignInPayload({
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
  String? domain;
  String? address;
  String? statement;
  String? uri;
  String? version;
  String? chainId;
  String? nonce;
  String? issuedAt;
  String? expirationTime;
  String? notBefore;
  String? requestId;
  List<String>? resources;
}

class MsgSignInResult {
  MsgSignInResult({
    required this.address,
    required this.publicKey,
    required this.signedMessage,
    required this.signature,
  });
  String address;
  Uint8List publicKey;
  Uint8List signedMessage;
  Uint8List signature;
}

class MsgSignAndSendOptions {
  MsgSignAndSendOptions({
    this.minContextSlot,
    this.commitment,
    this.skipPreflight,
    this.maxRetries,
    this.waitForCommitmentToSendNextTransaction,
  });
  int? minContextSlot;
  String? commitment;
  bool? skipPreflight;
  int? maxRetries;
  bool? waitForCommitmentToSendNextTransaction;
}

@HostApi()
abstract class SeekerConnectHostApi {
  @async
  void configure(MsgConfig config);

  @async
  MsgWalletAvailability walletAvailability();

  @async
  MsgAuthorization? restore();

  @async
  MsgAuthorization connect();

  @async
  MsgSignInResult signIn(MsgSignInPayload? payload);

  @async
  List<Uint8List> signMessages(List<String> addresses, List<Uint8List> payloads);

  @async
  List<Uint8List> signTransactions(List<Uint8List> payloads);

  @async
  List<Uint8List> signAndSendTransactions(
    List<Uint8List> payloads,
    MsgSignAndSendOptions? options,
  );

  @async
  void disconnect(bool revoke);

  @async
  void cancelInteraction(int id);
}

@FlutterApi()
abstract class SeekerConnectFlutterApi {
  void onAuthorizationChanged(MsgAuthorization? authorization);
  void onInteractionStarted(int id);
  void onInteractionSettled(int id);
  void onInteractionFailed(String code);
}
