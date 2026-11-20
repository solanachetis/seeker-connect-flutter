package io.github.seekerconnectflutter.seeker_connect_flutter

import com.solanamobile.seekerconnect.SeekerConnectException
import com.solanamobile.seekerconnect.SeekerConnectPresenter
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicLong

/** Events the bridge reports to Dart. */
interface BridgeEvents {
    fun authorizationChanged(authorization: MsgAuthorization?)
    fun interactionStarted(id: Long)
    fun interactionSettled(id: Long)
    fun interactionFailed(code: String)
}

/**
 * Forwards the SDK's interaction lifecycle to Dart so Flutter widgets can show
 * progress and error cards, and lets Dart cancel an interaction by id.
 */
internal class FlutterPresenter(private val events: BridgeEvents) : SeekerConnectPresenter {
    private val nextId = AtomicLong(0)
    private val cancels = ConcurrentHashMap<Long, () -> Unit>()

    override fun interactionStarted(cancel: () -> Unit): () -> Unit {
        val id = nextId.incrementAndGet()
        cancels[id] = cancel
        events.interactionStarted(id)
        return {
            if (cancels.remove(id) != null) events.interactionSettled(id)
        }
    }

    override fun interactionFailed(error: SeekerConnectException) {
        events.interactionFailed(error.code.toFlutterCode())
    }

    fun cancel(id: Long) {
        cancels[id]?.invoke()
    }
}
