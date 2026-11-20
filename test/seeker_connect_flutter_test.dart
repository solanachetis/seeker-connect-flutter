import 'package:flutter_test/flutter_test.dart';
import 'package:seeker_connect_flutter/seeker_connect_flutter.dart';
import 'package:seeker_connect_flutter/seeker_connect_flutter_pigeon.dart';
import 'package:seeker_connect_flutter/seeker_connect_flutter_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSeekerConnectFlutterPlatform
    with MockPlatformInterfaceMixin
    implements SeekerConnectFlutterPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final initialPlatform = SeekerConnectFlutterPlatform.instance;

  test('PigeonSeekerConnectFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<PigeonSeekerConnectFlutter>());
  });

  test('getPlatformVersion', () async {
    SeekerConnectFlutter seekerConnectFlutterPlugin = SeekerConnectFlutter();
    MockSeekerConnectFlutterPlatform fakePlatform = MockSeekerConnectFlutterPlatform();
    SeekerConnectFlutterPlatform.instance = fakePlatform;

    expect(await seekerConnectFlutterPlugin.getPlatformVersion(), '42');
  });
}
