
import 'seeker_connect_flutter_platform_interface.dart';

class SeekerConnectFlutter {
  Future<String?> getPlatformVersion() {
    return SeekerConnectFlutterPlatform.instance.getPlatformVersion();
  }
}
