import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'seeker_connect_flutter_pigeon.dart';

abstract class SeekerConnectFlutterPlatform extends PlatformInterface {
  /// Constructs a SeekerConnectFlutterPlatform.
  SeekerConnectFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static SeekerConnectFlutterPlatform _instance = PigeonSeekerConnectFlutter();

  /// The instance of [SeekerConnectFlutterPlatform] to use.
  ///
  /// Defaults to [PigeonSeekerConnectFlutter].
  static SeekerConnectFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SeekerConnectFlutterPlatform] when
  /// they register themselves.
  static set instance(SeekerConnectFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
