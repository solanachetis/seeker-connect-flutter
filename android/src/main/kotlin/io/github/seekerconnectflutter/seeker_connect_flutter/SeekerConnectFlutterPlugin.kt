package io.github.seekerconnectflutter.seeker_connect_flutter

import io.flutter.embedding.engine.plugins.FlutterPlugin

/** SeekerConnectFlutterPlugin */
class SeekerConnectFlutterPlugin :
    FlutterPlugin,
    SeekerConnectFlutterPluginApi {
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        SeekerConnectFlutterPluginApi.setUp(flutterPluginBinding.binaryMessenger, this)
    }

    override fun getPlatformVersion(): String = "Android ${android.os.Build.VERSION.RELEASE}"

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        SeekerConnectFlutterPluginApi.setUp(binding.binaryMessenger, null)
    }
}
