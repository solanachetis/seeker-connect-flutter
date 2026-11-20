package io.github.seekerconnectflutter.seeker_connect_flutter

import android.app.Activity
import android.content.Context
import androidx.activity.ComponentActivity
import com.solanamobile.seekerconnect.SeekerConnect
import com.solanamobile.seekerconnect.android.MwaSeekerLink
import com.solanamobile.seekerconnect.android.SharedPreferencesAuthorizationCache
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/**
 * Seeker Connect Flutter plugin: wires the Pigeon host API to [Bridge], which
 * drives the official `com.solanamobile:seeker-connect` SDK.
 *
 * The wallet is launched from the attached activity, which must be an androidx
 * `ComponentActivity` (use `FlutterFragmentActivity`).
 */
class SeekerConnectFlutterPlugin : FlutterPlugin, ActivityAware {
    private var scope: CoroutineScope? = null
    private var bridge: Bridge<ComponentActivity>? = null
    private var activity: Activity? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
        val appContext: Context = binding.applicationContext
        val flutterApi = SeekerConnectFlutterApi(binding.binaryMessenger)
        val events = object : BridgeEvents {
            // Delivery failures (e.g. engine shutting down) are ignored: they are UI hints only.
            private fun send(block: suspend () -> Unit) {
                scope.launch { runCatching { block() } }
            }
            override fun authorizationChanged(authorization: MsgAuthorization?) =
                send { flutterApi.onAuthorizationChanged(authorization) }
            override fun interactionStarted(id: Long) = send { flutterApi.onInteractionStarted(id) }
            override fun interactionSettled(id: Long) = send { flutterApi.onInteractionSettled(id) }
            override fun interactionFailed(code: String) = send { flutterApi.onInteractionFailed(code) }
        }
        val bridge = Bridge(
            scope = scope,
            hostProvider = { activity as? ComponentActivity },
            clientFactory = { config, presenter ->
                SeekerConnect(
                    config,
                    MwaSeekerLink(appContext),
                    SharedPreferencesAuthorizationCache(appContext),
                    presenter,
                )
            },
            events = events,
        )
        SeekerConnectHostApi.setUp(binding.binaryMessenger, bridge)
        this.scope = scope
        this.bridge = bridge
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        SeekerConnectHostApi.setUp(binding.binaryMessenger, null)
        bridge?.cancelAll()
        scope?.cancel()
        bridge = null
        scope = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        // The activity comes back right away (rotation): keep in-flight calls.
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
        bridge?.cancelAll()
    }
}
