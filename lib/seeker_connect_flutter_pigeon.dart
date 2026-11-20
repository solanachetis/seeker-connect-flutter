import 'package:flutter/foundation.dart';

import 'seeker_connect_flutter_platform_interface.dart';
import 'src/messages.g.dart';

/// An implementation of [SeekerConnectFlutterPlatform] that uses Pigeon, for
/// non-web platforms.
class PigeonSeekerConnectFlutter extends SeekerConnectFlutterPlatform {
  /// Creates a new plugin implementation instance.
  PigeonSeekerConnectFlutter({@visibleForTesting SeekerConnectFlutterPluginApi? api})
    : _hostApi = api ?? SeekerConnectFlutterPluginApi();

  final SeekerConnectFlutterPluginApi _hostApi;

  @override
  Future<String?> getPlatformVersion() async {
    return _hostApi.getPlatformVersion();
  }
}
