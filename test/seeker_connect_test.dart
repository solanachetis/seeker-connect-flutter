import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:seeker_connect_flutter/seeker_connect_flutter.dart';
import 'package:seeker_connect_flutter/src/platform.dart';
import 'package:seeker_connect_flutter/src/unsupported_platform.dart';

import 'fake_platform.dart';

const _config = SeekerConnectConfig(
  identity: DappIdentity(name: 'Test', uri: 'https://test.example'),
  chain: 'solana:devnet',
);

void main() {
  late FakeSeekerConnectPlatform fake;

  setUp(() {
    fake = FakeSeekerConnectPlatform();
    SeekerConnectPlatform.instance = fake;
  });

  test('configure stores the config and forwards it', () async {
    await SeekerConnect.configure(_config);
    expect(SeekerConnect.config, same(_config));
    expect(fake.lastConfig, same(_config));
  });

  test('unsupportedPlatformThrows', () async {
    SeekerConnectPlatform.instance = UnsupportedSeekerConnectPlatform();
    expect(await SeekerConnect.walletAvailability(), WalletAvailability.none);
    await expectLater(
      SeekerConnect.connect(),
      throwsA(isA<SeekerConnectException>()
          .having((e) => e.code, 'code', SeekerConnectErrorCode.unsupportedPlatform)),
    );
  });

  test('platformExceptionsBecomeSeekerConnectExceptions', () async {
    fake.throwNext = FakeSeekerConnectPlatform.error('authorizationDeclined');
    await expectLater(
      SeekerConnect.connect(),
      throwsA(isA<SeekerConnectException>()
          .having((e) => e.code, 'code', SeekerConnectErrorCode.authorizationDeclined)),
    );
  });

  test('rejectsEmptyPayloads', () async {
    final one = [Uint8List(1)];
    expect(() => SeekerConnect.signMessages([], []), throwsArgumentError);
    expect(() => SeekerConnect.signMessages(['a'], []), throwsArgumentError);
    expect(() => SeekerConnect.signMessages([], one), throwsArgumentError);
    expect(() => SeekerConnect.signTransactions([]), throwsArgumentError);
    expect(() => SeekerConnect.signAndSendTransactions([]), throwsArgumentError);
    expect(fake.calls, isEmpty);
  });

  test('signing returns platform results', () async {
    final payload = Uint8List.fromList([1, 2, 3]);
    expect(await SeekerConnect.signMessages(['a'], [payload]), [payload]);
    expect(await SeekerConnect.signTransactions([payload]), [payload]);
    expect(await SeekerConnect.signAndSendTransactions([payload]), [payload]);
    expect((await SeekerConnect.signIn()).address, 'Addr111');
  });

  test('currentAuthorizationFollowsStream', () async {
    expect(SeekerConnect.currentAuthorization, isNull);
    final seen = <StoredAuthorization?>[];
    final sub = SeekerConnect.authorization.listen(seen.add);
    fake.authController.add(FakeSeekerConnectPlatform.authorization);
    await pumpEventQueue();
    expect(SeekerConnect.currentAuthorization, same(FakeSeekerConnectPlatform.authorization));
    fake.authController.add(null);
    await pumpEventQueue();
    expect(SeekerConnect.currentAuthorization, isNull);
    expect(seen, [FakeSeekerConnectPlatform.authorization, null]);
    await sub.cancel();
  });

  test('connect updates currentAuthorization immediately', () async {
    final auth = await SeekerConnect.connect();
    expect(SeekerConnect.currentAuthorization, same(auth));
  });

  test('disconnectPassesRevokeFlag', () async {
    await SeekerConnect.disconnect();
    expect(fake.lastRevoke, isFalse);
    await SeekerConnect.disconnect(revoke: true);
    expect(fake.lastRevoke, isTrue);
    expect(SeekerConnect.currentAuthorization, isNull);
  });

  test('cancelInteraction is forwarded', () async {
    await SeekerConnect.cancelInteraction(7);
    expect(fake.cancelled, [7]);
  });
}
