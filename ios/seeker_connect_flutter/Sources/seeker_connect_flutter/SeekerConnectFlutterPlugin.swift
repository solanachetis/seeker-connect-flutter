import Flutter
import UIKit

public class SeekerConnectFlutterPlugin: NSObject, FlutterPlugin, SeekerConnectFlutterPluginApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = SeekerConnectFlutterPlugin()
    SeekerConnectFlutterPluginApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
  }

  public func getPlatformVersion() throws -> String {
    return "iOS " + UIDevice.current.systemVersion
  }
}
