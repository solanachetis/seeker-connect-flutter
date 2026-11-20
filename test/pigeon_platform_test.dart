import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:seeker_connect_flutter/seeker_connect_flutter.dart';
import 'package:seeker_connect_flutter/src/messages.g.dart';
import 'package:seeker_connect_flutter/src/pigeon_platform.dart';

class _RecordingHostApi extends SeekerConnectHostApi {
  MsgConfig? config;
  MsgSignAndSendOptions? options;

  @override
  Future<void> configure(MsgConfig config) async => this.config = config;

  @override
  Future<List<Uint8List>> signAndSendTransactions(List<Uint8List> payloads, MsgSignAndSendOptions? options) async {
    this.options = options;
    return payloads;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('configure maps every config field', () async {
    final host = _RecordingHostApi();
    await PigeonSeekerConnectPlatform(hostApi: host).configure(const SeekerConnectConfig(
      identity: DappIdentity(name: 'N', uri: 'https://n.example', icon: 'i.png'),
      chain: 'solana:devnet',
      firstConnectWalletBaseUri: 'https://wallet.example',
      associationTimeoutMs: 5000,
    ));
    final c = host.config!;
    expect([c.identity.name, c.identity.uri, c.identity.icon, c.chain], ['N', 'https://n.example', 'i.png', 'solana:devnet']);
    expect(c.firstConnectWalletBaseUri, 'https://wallet.example');
    expect(c.associationTimeoutMs, 5000);
  });

  test('configure leaves SDK defaults when options are omitted', () async {
    final host = _RecordingHostApi();
    await PigeonSeekerConnectPlatform(hostApi: host)
        .configure(const SeekerConnectConfig(identity: DappIdentity(name: 'N', uri: 'https://n.example')));
    expect(host.config!.firstConnectWalletBaseUri, isNull);
    expect(host.config!.associationTimeoutMs, isNull);
  });

  test('sign-and-send options are mapped field by field', () async {
    final host = _RecordingHostApi();
    await PigeonSeekerConnectPlatform(hostApi: host).signAndSendTransactions(
      [Uint8List(1)],
      const SeekerSignAndSendOptions(
        minContextSlot: 1,
        commitment: 'confirmed',
        skipPreflight: true,
        maxRetries: 3,
        waitForCommitmentToSendNextTransaction: false,
      ),
    );
    final o = host.options!;
    expect([o.minContextSlot, o.commitment, o.skipPreflight, o.maxRetries, o.waitForCommitmentToSendNextTransaction],
        [1, 'confirmed', true, 3, false]);
  });
}
