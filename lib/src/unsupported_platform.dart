import 'dart:typed_data';

import 'errors.dart';
import 'events.dart';
import 'models.dart';
import 'platform.dart';

/// Used on every platform except Android: there is no Seeker wallet there.
class UnsupportedSeekerConnectPlatform extends SeekerConnectPlatform {
  Never _unsupported() => throw const SeekerConnectException(
        SeekerConnectErrorCode.unsupportedPlatform,
        'Seeker Connect is only available on Android',
      );

  @override
  Stream<StoredAuthorization?> get authorizationChanges => const Stream.empty();

  @override
  Stream<SeekerInteractionEvent> get interactions => const Stream.empty();

  @override
  Future<void> configure(SeekerConnectConfig config) async {}

  @override
  Future<WalletAvailability> walletAvailability() async => WalletAvailability.none;

  @override
  Future<StoredAuthorization?> restore() async => null;

  @override
  Future<StoredAuthorization> connect() async => _unsupported();

  @override
  Future<SeekerSignInResult> signIn(SeekerSignInPayload? payload) async => _unsupported();

  @override
  Future<List<Uint8List>> signMessages(List<String> addresses, List<Uint8List> payloads) async => _unsupported();

  @override
  Future<List<Uint8List>> signTransactions(List<Uint8List> payloads) async => _unsupported();

  @override
  Future<List<Uint8List>> signAndSendTransactions(
    List<Uint8List> payloads,
    SeekerSignAndSendOptions? options,
  ) async =>
      _unsupported();

  @override
  Future<void> disconnect({required bool revoke}) async {}

  @override
  Future<void> cancelInteraction(int id) async {}
}
