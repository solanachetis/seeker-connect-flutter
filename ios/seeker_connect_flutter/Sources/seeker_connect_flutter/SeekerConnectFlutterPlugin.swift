import Flutter
import UIKit

/// Seeker Connect is Android-only. On iOS the Dart side reports
/// `unsupportedPlatform` without calling into native code.
public class SeekerConnectFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {}
}
