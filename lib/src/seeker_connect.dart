import 'dart:async';

import 'package:flutter/services.dart';

import 'errors.dart';
import 'events.dart';
import 'models.dart';
import 'platform.dart';

/// Connects a Flutter app to the Seeker's own wallet through the official
/// Seeker Connect SDK. Android only; other platforms report
/// [SeekerConnectErrorCode.unsupportedPlatform].
///
/// Call [configure] once at startup, then [restore] or [connect].
abstract final class SeekerConnect {
  static SeekerConnectConfig? _config;
  static StoredAuthorization? _current;
  static SeekerConnectPlatform? _platform;
  static StreamSubscription<StoredAuthorization?>? _subscription;
  static final _authorizations = StreamController<StoredAuthorization?>.broadcast();

  /// The platform in use; resubscribes (and resets state) when it is replaced.
  static SeekerConnectPlatform get _p {
    final platform = SeekerConnectPlatform.instance;
    if (!identical(platform, _platform)) {
      _subscription?.cancel();
      _platform = platform;
      _config = null;
      _current = null;
      _subscription = platform.authorizationChanges.listen(_setCurrent);
    }
    return platform;
  }

  static void _setCurrent(StoredAuthorization? authorization) {
    _current = authorization;
    _authorizations.add(authorization);
  }

  /// The configuration passed to [configure], or null before it.
  static SeekerConnectConfig? get config {
    _p;
    return _config;
  }

  /// The authorization currently held, or null while disconnected.
  static StoredAuthorization? get currentAuthorization {
    _p;
    return _current;
  }

  /// Emits the held authorization whenever it changes (null when disconnected).
  static Stream<StoredAuthorization?> get authorization {
    _p;
    return _authorizations.stream;
  }

  /// Wallet interaction lifecycle, used by `SeekerConnectDialogs`.
  static Stream<SeekerInteractionEvent> get interactions => _p.interactions;

  /// Sets the dapp identity and chain. Call once before anything else.
  static Future<void> configure(SeekerConnectConfig config) async {
    final platform = _p;
    await _guard(() => platform.configure(config));
    _config = config;
  }

  /// Which wallet a connection would reach, without opening anything.
  static Future<WalletAvailability> walletAvailability() => _guard(() => _p.walletAvailability());

  /// The cached authorization, without opening the wallet.
  static Future<StoredAuthorization?> restore() async {
    final auth = await _guard(() => _p.restore());
    if (auth != null) _current = auth;
    return auth;
  }

  /// Restores, or opens the wallet to authorize this app.
  static Future<StoredAuthorization> connect() async {
    final auth = await _guard(() => _p.connect());
    _current = auth;
    return auth;
  }

  /// Sign-In With Solana, connecting in the same wallet session when needed.
  static Future<SeekerSignInResult> signIn([SeekerSignInPayload? payload]) => _guard(() => _p.signIn(payload));

  /// Signs every payload with each of [addresses] (base58).
  static Future<List<Uint8List>> signMessages(List<String> addresses, List<Uint8List> payloads) {
    _requireNotEmpty(addresses, 'addresses');
    _requireNotEmpty(payloads, 'payloads');
    return _guard(() => _p.signMessages(addresses, payloads));
  }

  /// Returns the signed transaction bytes, one per payload.
  static Future<List<Uint8List>> signTransactions(List<Uint8List> payloads) {
    _requireNotEmpty(payloads, 'payloads');
    return _guard(() => _p.signTransactions(payloads));
  }

  /// Signs and submits; returns each transaction's signature.
  ///
  /// Never retry automatically on failure (including `sessionClosed`): the
  /// transaction may have been submitted. Check on-chain first.
  static Future<List<Uint8List>> signAndSendTransactions(
    List<Uint8List> payloads, [
    SeekerSignAndSendOptions? options,
  ]) {
    _requireNotEmpty(payloads, 'payloads');
    return _guard(() => _p.signAndSendTransactions(payloads, options));
  }

  /// Forgets the authorization. With [revoke], first asks the wallet to revoke
  /// it; the local authorization is forgotten even if that fails, and the
  /// failure is then rethrown.
  static Future<void> disconnect({bool revoke = false}) async {
    try {
      await _guard(() => _p.disconnect(revoke: revoke));
    } finally {
      _current = null;
    }
  }

  /// Cancels the wallet interaction [id] reported by [interactions].
  static Future<void> cancelInteraction(int id) => _guard(() => _p.cancelInteraction(id));

  static void _requireNotEmpty(List<Object> list, String name) {
    if (list.isEmpty) throw ArgumentError.value(list, name, 'must not be empty');
  }

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PlatformException catch (e) {
      throw SeekerConnectException(codeFromString(e.code), e.message ?? e.code);
    }
  }
}
