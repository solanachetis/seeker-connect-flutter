import 'dart:async';

import 'package:flutter/services.dart';
import 'package:seeker_connect_flutter/seeker_connect_flutter.dart';
import 'package:seeker_connect_flutter/src/platform.dart';

/// Scriptable in-memory platform for Dart and widget tests.
class FakeSeekerConnectPlatform extends SeekerConnectPlatform {
  final calls = <String>[];
  final cancelled = <int>[];
  final authController = StreamController<StoredAuthorization?>.broadcast();
  final interactionController = StreamController<SeekerInteractionEvent>.broadcast();

  /// When set, the next call throws it, then it is cleared.
  Object? throwNext;
  bool? lastRevoke;
  SeekerConnectConfig? lastConfig;

  static final account = SeekerAccount(address: 'Addr111', publicKey: Uint8List(32));
  static final authorization = StoredAuthorization(
    accounts: [account],
    walletUriBase: null,
    chain: 'solana:devnet',
    capabilities: const SeekerWalletCapabilities(),
  );

  Future<T> _call<T>(String name, T result) async {
    calls.add(name);
    final error = throwNext;
    if (error != null) {
      throwNext = null;
      throw error;
    }
    return result;
  }

  @override
  Stream<StoredAuthorization?> get authorizationChanges => authController.stream;

  @override
  Stream<SeekerInteractionEvent> get interactions => interactionController.stream;

  @override
  Future<void> configure(SeekerConnectConfig config) {
    lastConfig = config;
    return _call('configure', null);
  }

  @override
  Future<WalletAvailability> walletAvailability() => _call('walletAvailability', WalletAvailability.certified);

  @override
  Future<StoredAuthorization?> restore() => _call('restore', null);

  @override
  Future<StoredAuthorization> connect() => _call('connect', authorization);

  @override
  Future<SeekerSignInResult> signIn(SeekerSignInPayload? payload) => _call(
        'signIn',
        SeekerSignInResult(
          address: 'Addr111',
          publicKey: Uint8List(32),
          signedMessage: Uint8List(3),
          signature: Uint8List(64),
        ),
      );

  @override
  Future<List<Uint8List>> signMessages(List<String> addresses, List<Uint8List> payloads) =>
      _call('signMessages', payloads);

  @override
  Future<List<Uint8List>> signTransactions(List<Uint8List> payloads) => _call('signTransactions', payloads);

  @override
  Future<List<Uint8List>> signAndSendTransactions(List<Uint8List> payloads, SeekerSignAndSendOptions? options) =>
      _call('signAndSendTransactions', payloads);

  @override
  Future<void> disconnect({required bool revoke}) {
    lastRevoke = revoke;
    return _call('disconnect', null);
  }

  @override
  Future<void> cancelInteraction(int id) {
    cancelled.add(id);
    return _call('cancelInteraction', null);
  }

  /// Helper for tests that expect a platform error code.
  static PlatformException error(String code) => PlatformException(code: code, message: 'test');
}
