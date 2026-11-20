import 'dart:async';
import 'dart:typed_data';

import 'errors.dart';
import 'events.dart';
import 'messages.g.dart';
import 'models.dart';
import 'platform.dart';

/// Android implementation over the Pigeon bridge to the Kotlin plugin.
class PigeonSeekerConnectPlatform extends SeekerConnectPlatform implements SeekerConnectFlutterApi {
  PigeonSeekerConnectPlatform({SeekerConnectHostApi? hostApi}) : _host = hostApi ?? SeekerConnectHostApi() {
    SeekerConnectFlutterApi.setUp(this);
  }

  final SeekerConnectHostApi _host;
  final _authorizations = StreamController<StoredAuthorization?>.broadcast();
  final _interactions = StreamController<SeekerInteractionEvent>.broadcast();

  @override
  Stream<StoredAuthorization?> get authorizationChanges => _authorizations.stream;

  @override
  Stream<SeekerInteractionEvent> get interactions => _interactions.stream;

  // ---- Dart -> Kotlin ----

  @override
  Future<void> configure(SeekerConnectConfig config) => _host.configure(
        MsgConfig(
          identity: MsgDappIdentity(name: config.identity.name, uri: config.identity.uri, icon: config.identity.icon),
          chain: config.chain,
        ),
      );

  @override
  Future<WalletAvailability> walletAvailability() async => switch (await _host.walletAvailability()) {
        MsgWalletAvailability.certified => WalletAvailability.certified,
        MsgWalletAvailability.other => WalletAvailability.other,
        MsgWalletAvailability.none => WalletAvailability.none,
      };

  @override
  Future<StoredAuthorization?> restore() async => _authorization(await _host.restore());

  @override
  Future<StoredAuthorization> connect() async => _authorization(await _host.connect())!;

  @override
  Future<SeekerSignInResult> signIn(SeekerSignInPayload? payload) async {
    final r = await _host.signIn(
      payload == null
          ? null
          : MsgSignInPayload(
              domain: payload.domain,
              address: payload.address,
              statement: payload.statement,
              uri: payload.uri,
              version: payload.version,
              chainId: payload.chainId,
              nonce: payload.nonce,
              issuedAt: payload.issuedAt,
              expirationTime: payload.expirationTime,
              notBefore: payload.notBefore,
              requestId: payload.requestId,
              resources: payload.resources,
            ),
    );
    return SeekerSignInResult(
      address: r.address,
      publicKey: r.publicKey,
      signedMessage: r.signedMessage,
      signature: r.signature,
    );
  }

  @override
  Future<List<Uint8List>> signMessages(List<String> addresses, List<Uint8List> payloads) =>
      _host.signMessages(addresses, payloads);

  @override
  Future<List<Uint8List>> signTransactions(List<Uint8List> payloads) => _host.signTransactions(payloads);

  @override
  Future<List<Uint8List>> signAndSendTransactions(List<Uint8List> payloads, SeekerSignAndSendOptions? options) =>
      _host.signAndSendTransactions(
        payloads,
        options == null
            ? null
            : MsgSignAndSendOptions(
                minContextSlot: options.minContextSlot,
                commitment: options.commitment,
                skipPreflight: options.skipPreflight,
                maxRetries: options.maxRetries,
                waitForCommitmentToSendNextTransaction: options.waitForCommitmentToSendNextTransaction,
              ),
      );

  @override
  Future<void> disconnect({required bool revoke}) => _host.disconnect(revoke);

  @override
  Future<void> cancelInteraction(int id) => _host.cancelInteraction(id);

  // ---- Kotlin -> Dart ----

  @override
  void onAuthorizationChanged(MsgAuthorization? authorization) => _authorizations.add(_authorization(authorization));

  @override
  void onInteractionStarted(int id) => _interactions.add(SeekerInteractionStarted(id));

  @override
  void onInteractionSettled(int id) => _interactions.add(SeekerInteractionSettled(id));

  @override
  void onInteractionFailed(String code) => _interactions.add(SeekerInteractionFailed(codeFromString(code)));

  static StoredAuthorization? _authorization(MsgAuthorization? m) => m == null
      ? null
      : StoredAuthorization(
          accounts: [
            for (final a in m.accounts) SeekerAccount(address: a.address, publicKey: a.publicKey, label: a.label),
          ],
          walletUriBase: m.walletUriBase,
          chain: m.chain,
          capabilities: SeekerWalletCapabilities(
            maxMessagesPerRequest: m.capabilities.maxMessagesPerRequest,
            maxTransactionsPerRequest: m.capabilities.maxTransactionsPerRequest,
            supportedTransactionVersions: m.capabilities.supportedTransactionVersions,
            features: m.capabilities.features,
            supportsSignAndSendTransactions: m.capabilities.supportsSignAndSendTransactions,
          ),
        );
}
