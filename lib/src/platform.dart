
import 'package:flutter/foundation.dart';

import 'events.dart';
import 'models.dart';
import 'pigeon_platform.dart';
import 'unsupported_platform.dart';

/// The native side of Seeker Connect. Replaceable in tests.
///
/// Implementations may throw `PlatformException`s whose code is a
/// `SeekerConnectErrorCode` name; `SeekerConnect` converts them.
abstract class SeekerConnectPlatform {
  static SeekerConnectPlatform? _instance;

  /// The active platform: the Pigeon bridge on Android, unsupported elsewhere.
  static SeekerConnectPlatform get instance => _instance ??=
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
          ? PigeonSeekerConnectPlatform()
          : UnsupportedSeekerConnectPlatform();

  static set instance(SeekerConnectPlatform platform) {
    _instance = platform;
    instanceChanged.value++;
  }

  /// Bumped whenever [instance] is replaced, so listeners can resubscribe.
  @visibleForTesting
  static final ValueNotifier<int> instanceChanged = ValueNotifier(0);

  Stream<StoredAuthorization?> get authorizationChanges;
  Stream<SeekerInteractionEvent> get interactions;

  Future<void> configure(SeekerConnectConfig config);
  Future<WalletAvailability> walletAvailability();
  Future<StoredAuthorization?> restore();
  Future<StoredAuthorization> connect();
  Future<SeekerSignInResult> signIn(SeekerSignInPayload? payload);
  Future<List<Uint8List>> signMessages(List<String> addresses, List<Uint8List> payloads);
  Future<List<Uint8List>> signTransactions(List<Uint8List> payloads);
  Future<List<Uint8List>> signAndSendTransactions(List<Uint8List> payloads, SeekerSignAndSendOptions? options);
  Future<void> disconnect({required bool revoke});
  Future<void> cancelInteraction(int id);
}
