import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:seeker_connect_flutter/src/errors.dart';
import 'package:seeker_connect_flutter/src/events.dart';
import 'package:seeker_connect_flutter/src/models.dart';

void main() {
  group('codeFromString', () {
    test('maps all ten codes', () {
      const names = {
        'noWalletFound': SeekerConnectErrorCode.noWalletFound,
        'associationFailed': SeekerConnectErrorCode.associationFailed,
        'authorizationDeclined': SeekerConnectErrorCode.authorizationDeclined,
        'requestDeclined': SeekerConnectErrorCode.requestDeclined,
        'sessionClosed': SeekerConnectErrorCode.sessionClosed,
        'cancelled': SeekerConnectErrorCode.cancelled,
        'walletError': SeekerConnectErrorCode.walletError,
        'unsupportedPlatform': SeekerConnectErrorCode.unsupportedPlatform,
        'notConfigured': SeekerConnectErrorCode.notConfigured,
        'hostNotSupported': SeekerConnectErrorCode.hostNotSupported,
      };
      expect(SeekerConnectErrorCode.values, hasLength(10));
      names.forEach((name, code) => expect(codeFromString(name), code));
    });

    test('unknown code falls back to walletError', () {
      expect(codeFromString('bogus'), SeekerConnectErrorCode.walletError);
    });
  });

  group('toString', () {
    final key = Uint8List.fromList(List.filled(32, 9));
    final sig = Uint8List.fromList(List.filled(64, 7));

    test('SeekerSignInResult never prints full keys or signatures', () {
      final result = SeekerSignInResult(
        address: 'Addr111',
        publicKey: key,
        signedMessage: Uint8List.fromList([1, 2, 3]),
        signature: sig,
      );
      final s = result.toString();
      expect(s, contains('Addr111'));
      expect(s, isNot(contains('7, 7, 7')));
      expect(s, isNot(contains('9, 9, 9')));
    });

    test('StoredAuthorization prints the address, no key bytes, no token', () {
      final auth = StoredAuthorization(
        accounts: [SeekerAccount(address: 'Addr111', publicKey: key)],
        walletUriBase: 'https://wallet.example',
        chain: 'solana:devnet',
        capabilities: const SeekerWalletCapabilities(),
      );
      final s = auth.toString();
      expect(s, contains('Addr111'));
      expect(s, isNot(contains('9, 9, 9')));
      expect(s.toLowerCase(), isNot(contains('token')));
    });
  });

  test('SeekerConnectException carries code and message', () {
    const e = SeekerConnectException(SeekerConnectErrorCode.requestDeclined, 'no');
    expect(e.code, SeekerConnectErrorCode.requestDeclined);
    expect(e.toString(), contains('requestDeclined'));
  });

  test('interaction events are distinguishable', () {
    final List<SeekerInteractionEvent> events = [
      const SeekerInteractionStarted(1),
      const SeekerInteractionSettled(1),
      const SeekerInteractionFailed(SeekerConnectErrorCode.cancelled),
    ];
    expect(events[0], isA<SeekerInteractionStarted>().having((e) => e.id, 'id', 1));
    expect(events[2], isA<SeekerInteractionFailed>().having((e) => e.code, 'code', SeekerConnectErrorCode.cancelled));
  });

  test('config defaults', () {
    final c = SeekerConnectConfig(identity: const DappIdentity(name: 'A', uri: 'https://a.example'));
    expect(c.chain, 'solana:mainnet');
    expect(c.showDialogs, isTrue);
  });
}
