import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seeker_connect_flutter/seeker_connect_flutter_pigeon.dart';
import 'package:seeker_connect_flutter/src/messages.g.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('getPlatformVersion', () async {
    final api = FakeSeekerConnectFlutterPluginApi(platformVersion: '42');
    final plugin = PigeonSeekerConnectFlutter(api: api);

    expect(await plugin.getPlatformVersion(), '42');
  });
}

/// Fake implementation of the Pigeon API that provides a pre-set response.
class FakeSeekerConnectFlutterPluginApi implements SeekerConnectFlutterPluginApi {
  FakeSeekerConnectFlutterPluginApi({required this.platformVersion});

  final String platformVersion;

  @override
  Future<String> getPlatformVersion() async {
    return platformVersion;
  }

  @override
  // ignore: non_constant_identifier_names
  BinaryMessenger? get pigeonVar_binaryMessenger => null;

  @override
  // ignore: non_constant_identifier_names
  String get pigeonVar_messageChannelSuffix => '';
}
