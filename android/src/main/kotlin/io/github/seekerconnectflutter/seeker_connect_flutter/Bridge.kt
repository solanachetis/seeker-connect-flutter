package io.github.seekerconnectflutter.seeker_connect_flutter

import com.solanamobile.seekerconnect.SeekerConnect
import com.solanamobile.seekerconnect.SeekerConnectConfig
import com.solanamobile.seekerconnect.SeekerConnectException
import com.solanamobile.seekerconnect.SeekerConnectPresenter
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.async
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

/**
 * Implements the Pigeon host API on top of the official Seeker Connect SDK.
 *
 * Generic over the wallet host [H] (a `ComponentActivity` in the app, a fake in
 * JVM tests). Every SDK failure is rethrown as a [FlutterError] whose code is
 * one of the Dart `SeekerConnectErrorCode` names. The wallet auth token stays
 * inside the SDK and is never mapped to a message type.
 */
class Bridge<H : Any>(
    private val scope: CoroutineScope,
    private val hostProvider: () -> H?,
    private val clientFactory: (SeekerConnectConfig, SeekerConnectPresenter) -> SeekerConnect<H>,
    private val events: BridgeEvents,
) : SeekerConnectHostApi {
    private val presenter = FlutterPresenter(events)
    private var client: SeekerConnect<H>? = null
    private var authorizationJob: Job? = null
    private var work = newWorkJob()

    override suspend fun configure(config: MsgConfig) {
        val newClient = try {
            clientFactory(config.toSdk(), presenter)
        } catch (e: IllegalArgumentException) {
            throw FlutterError(Codes.WALLET_ERROR, e.message ?: "Invalid configuration")
        }
        client = newClient
        newClient.restore()
        authorizationJob?.cancel()
        authorizationJob = scope.launch {
            // Report the restored state once, then every change.
            events.authorizationChanged(newClient.authorization.value?.toMsg())
            newClient.authorization.drop(1).collect { events.authorizationChanged(it?.toMsg()) }
        }
    }

    override suspend fun walletAvailability(): MsgWalletAvailability =
        requireClient().walletAvailability().toMsg()

    override suspend fun restore(): MsgAuthorization? =
        run { requireClient().restore()?.toMsg() }

    override suspend fun connect(): MsgAuthorization =
        withHost { client, host -> client.connect(host).toMsg() }

    override suspend fun signIn(payload: MsgSignInPayload?): MsgSignInResult =
        withHost { client, host ->
            val sdkPayload = payload?.toSdk()
            (if (sdkPayload == null) client.signIn(host) else client.signIn(host, sdkPayload)).toMsg()
        }

    override suspend fun signMessages(addresses: List<String>, payloads: List<ByteArray>): List<ByteArray> =
        withHost { client, host -> client.signMessages(host, addresses, payloads) }

    override suspend fun signTransactions(payloads: List<ByteArray>): List<ByteArray> =
        withHost { client, host -> client.signTransactions(host, payloads) }

    override suspend fun signAndSendTransactions(
        payloads: List<ByteArray>,
        options: MsgSignAndSendOptions?,
    ): List<ByteArray> =
        withHost { client, host -> client.signAndSendTransactions(host, payloads, options?.toSdk()) }

    override suspend fun disconnect(revoke: Boolean) {
        val client = requireClient()
        if (!revoke || client.restore() == null) {
            client.disconnect()
            return
        }
        // Revoke in the wallet, then always forget locally, then report a revoke failure.
        val failure = try {
            withHost { c, host -> c.transact(host) { authorization -> deauthorize(authorization.authToken) } }
            null
        } catch (e: FlutterError) {
            e
        }
        client.disconnect()
        failure?.let { throw it }
    }

    override suspend fun cancelInteraction(id: Long) {
        presenter.cancel(id)
    }

    /** Cancels every in-flight wallet call (activity or engine going away). */
    fun cancelAll() {
        work.cancel()
        work = newWorkJob()
    }

    private fun newWorkJob() = SupervisorJob(scope.coroutineContext[Job])

    private fun requireClient(): SeekerConnect<H> =
        client ?: throw FlutterError(Codes.NOT_CONFIGURED, "Call SeekerConnect.configure() first")

    private suspend fun <T> withHost(action: suspend (SeekerConnect<H>, H) -> T): T {
        val client = requireClient()
        val host = hostProvider() ?: throw FlutterError(
            Codes.HOST_NOT_SUPPORTED,
            "No androidx ComponentActivity is attached: use FlutterFragmentActivity as the app's MainActivity",
        )
        return run { action(client, host) }
    }

    /** Runs [block] in the cancellable work scope and maps failures to [FlutterError]. */
    private suspend fun <T> run(block: suspend () -> T): T {
        val call = CoroutineScope(scope.coroutineContext + work).async { block() }
        try {
            return call.await()
        } catch (e: FlutterError) {
            throw e
        } catch (e: SeekerConnectException) {
            throw FlutterError(e.code.toFlutterCode(), e.message)
        } catch (e: CancellationException) {
            if (!currentCoroutineContext().isActive) throw e
            throw FlutterError(Codes.CANCELLED, "The wallet interaction was cancelled")
        } catch (e: Exception) {
            throw FlutterError(Codes.WALLET_ERROR, e.message ?: e.javaClass.simpleName)
        }
    }
}
