package io.github.seekerconnectflutter.seeker_connect_flutter

import com.solanamobile.seekerconnect.MemoryAuthorizationCache
import com.solanamobile.seekerconnect.SeekerConnect
import com.solanamobile.seekerconnect.SeekerConnectException
import com.solanamobile.seekerconnect.SeekerConnectException.Code
import com.solanamobile.seekerconnect.WalletAvailability
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.async
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class BridgeTest {
    private val config = MsgConfig(MsgDappIdentity("Test", "https://test.example", "favicon.ico"), "solana:devnet")

    private class Recorder : BridgeEvents {
        val log = mutableListOf<String>()
        val authorizations = mutableListOf<MsgAuthorization?>()
        override fun authorizationChanged(authorization: MsgAuthorization?) {
            authorizations += authorization
        }
        override fun interactionStarted(id: Long) {
            log += "started:$id"
        }
        override fun interactionSettled(id: Long) {
            log += "settled:$id"
        }
        override fun interactionFailed(code: String) {
            log += "failed:$code"
        }
    }

    private class Harness(test: TestScope, var host: FakeHost? = FakeHost) {
        val link = FakeSeekerLink()
        val cache = MemoryAuthorizationCache()
        val events = Recorder()
        val identities = mutableListOf<String>()
        val scope = CoroutineScope(SupervisorJob() + StandardTestDispatcher(test.testScheduler))
        val bridge = Bridge(scope, { host }, { cfg, presenter ->
            identities += cfg.identity.name
            SeekerConnect(cfg, link, cache, presenter)
        }, events)
    }

    private suspend fun assertCode(code: String, block: suspend () -> Unit) {
        val e = assertFailsWith<FlutterError> { block() }
        assertEquals(code, e.code)
    }

    @Test
    fun callsBeforeConfigureFailWithNotConfigured() = runTest {
        val h = Harness(this)
        assertCode("notConfigured") { h.bridge.connect() }
        assertCode("notConfigured") { h.bridge.restore() }
        assertCode("notConfigured") { h.bridge.walletAvailability() }
    }

    @Test
    fun missingHostFailsWithHostNotSupported() = runTest {
        val h = Harness(this, host = null)
        h.bridge.configure(config)
        assertCode("hostNotSupported") { h.bridge.connect() }
        assertEquals(0, h.link.transactCount)
    }

    @Test
    fun connectReturnsAccountsWithoutToken() = runTest {
        val h = Harness(this)
        h.bridge.configure(config)
        val auth = h.bridge.connect()
        assertEquals(FAKE_ADDRESS, auth.accounts.single().address)
        assertContentEquals(FAKE_PUBLIC_KEY, auth.accounts.single().publicKey)
        assertEquals("solana:devnet", auth.chain)
        assertEquals(listOf("legacy", "0"), auth.capabilities.supportedTransactionVersions)
        assertEquals(4L, auth.capabilities.maxMessagesPerRequest)
        assertTrue(FAKE_TOKEN !in auth.toString())
    }

    @Test
    fun signingCallsPassBytesThrough() = runTest {
        val h = Harness(this)
        h.bridge.configure(config)
        val msg = byteArrayOf(10, 11)
        assertContentEquals(msg + byteArrayOf(0x51), h.bridge.signMessages(listOf(FAKE_ADDRESS), listOf(msg)).single())
        assertEquals(listOf(FAKE_ADDRESS), h.link.wallet.lastAddresses)
        val tx = byteArrayOf(20, 21)
        assertContentEquals(tx + byteArrayOf(0x54), h.bridge.signTransactions(listOf(tx)).single())
        val options = MsgSignAndSendOptions(minContextSlot = 5, commitment = "confirmed", skipPreflight = true, maxRetries = 2)
        assertEquals(64, h.bridge.signAndSendTransactions(listOf(tx), options).single().size)
        assertEquals(5, h.link.wallet.lastOptions?.minContextSlot)
        assertEquals("confirmed", h.link.wallet.lastOptions?.commitment)
        assertEquals(true, h.link.wallet.lastOptions?.skipPreflight)
        assertEquals(2, h.link.wallet.lastOptions?.maxRetries)
        val signIn = h.bridge.signIn(MsgSignInPayload(domain = "test.example", statement = "Hi"))
        assertEquals(FAKE_ADDRESS, signIn.address)
        assertEquals(64, signIn.signature.size)
        assertEquals("Hi", h.link.wallet.lastSignInPayload?.statement)
    }

    @Test
    fun walletAvailabilityIsMapped() = runTest {
        val h = Harness(this)
        h.bridge.configure(config)
        h.link.availability = WalletAvailability.CERTIFIED
        assertEquals(MsgWalletAvailability.CERTIFIED, h.bridge.walletAvailability())
        h.link.availability = WalletAvailability.OTHER
        assertEquals(MsgWalletAvailability.OTHER, h.bridge.walletAvailability())
        h.link.availability = WalletAvailability.NONE
        assertEquals(MsgWalletAvailability.NONE, h.bridge.walletAvailability())
    }

    @Test
    fun walletCodesAreMapped() = runTest {
        val expected = mapOf(
            Code.NO_WALLET_FOUND to "noWalletFound",
            Code.ASSOCIATION_FAILED to "associationFailed",
            Code.AUTHORIZATION_DECLINED to "authorizationDeclined",
            Code.REQUEST_DECLINED to "requestDeclined",
            Code.SESSION_CLOSED to "sessionClosed",
            Code.CANCELLED to "cancelled",
            Code.WALLET_ERROR to "walletError",
        )
        assertEquals(Code.entries.toSet(), expected.keys)
        for ((code, name) in expected) {
            val h = Harness(this)
            h.bridge.configure(config)
            h.link.failNext = SeekerConnectException(code, "boom")
            assertCode(name) { h.bridge.connect() }
            assertTrue("failed:$name" in h.events.log, "presenter failure for $name")
        }
    }

    @Test
    fun cancelInteractionCancelsInFlightCall() = runTest {
        val h = Harness(this)
        h.bridge.configure(config)
        h.link.gate = CompletableDeferred()
        val call = async { runCatching { h.bridge.connect() } }
        advanceUntilIdle()
        val id = h.events.log.single { it.startsWith("started:") }.removePrefix("started:").toLong()
        h.bridge.cancelInteraction(id)
        advanceUntilIdle()
        val error = call.await().exceptionOrNull() as FlutterError
        assertEquals("cancelled", error.code)
        assertTrue("settled:$id" in h.events.log)
    }

    @Test
    fun concurrentConnectLaunchesWalletOnce() = runTest {
        val h = Harness(this)
        h.bridge.configure(config)
        h.link.gate = CompletableDeferred()
        val a = async { h.bridge.connect() }
        val b = async { h.bridge.connect() }
        advanceUntilIdle()
        h.link.gate!!.complete(Unit)
        assertEquals(a.await().accounts.single().address, b.await().accounts.single().address)
        assertEquals(1, h.link.transactCount)
    }

    @Test
    fun inFlightCallCompletesWhenHostDetached() = runTest {
        val h = Harness(this)
        h.bridge.configure(config)
        h.link.gate = CompletableDeferred()
        val call = async { runCatching { h.bridge.connect() } }
        advanceUntilIdle()
        h.bridge.cancelAll()
        advanceUntilIdle()
        val error = call.await().exceptionOrNull() as FlutterError
        assertEquals("cancelled", error.code)
        // The bridge keeps working afterwards.
        h.link.gate = null
        assertEquals(FAKE_ADDRESS, h.bridge.connect().accounts.single().address)
    }

    @Test
    fun disconnectWithRevokeDeauthorizesThenForgets() = runTest {
        val h = Harness(this)
        h.bridge.configure(config)
        h.bridge.connect()
        h.bridge.disconnect(revoke = true)
        assertEquals(listOf(FAKE_TOKEN), h.link.wallet.deauthorized)
        assertNull(h.bridge.restore())
    }

    @Test
    fun disconnectWithRevokeForgetsEvenWhenWalletFails() = runTest {
        val h = Harness(this)
        h.bridge.configure(config)
        h.bridge.connect()
        h.link.failNext = SeekerConnectException(Code.REQUEST_DECLINED, "no")
        assertCode("requestDeclined") { h.bridge.disconnect(revoke = true) }
        assertNull(h.bridge.restore())
    }

    @Test
    fun disconnectWithRevokeWithoutAuthorizationDoesNotOpenWallet() = runTest {
        val h = Harness(this)
        h.bridge.configure(config)
        h.bridge.disconnect(revoke = true)
        assertEquals(0, h.link.transactCount)
    }

    @Test
    fun plainDisconnectDoesNotOpenWallet() = runTest {
        val h = Harness(this)
        h.bridge.configure(config)
        h.bridge.connect()
        h.bridge.disconnect(revoke = false)
        assertEquals(1, h.link.transactCount)
        assertNull(h.bridge.restore())
    }

    @Test
    fun reconfigureReplacesClientAndKeepsCache() = runTest {
        val h = Harness(this)
        h.bridge.configure(config)
        h.bridge.connect()
        h.bridge.configure(config.copy(identity = MsgDappIdentity("Second", "https://second.example")))
        assertEquals(listOf("Test", "Second"), h.identities)
        assertNotNull(h.bridge.restore())
    }

    @Test
    fun authorizationChangesAreForwarded() = runTest {
        val h = Harness(this)
        h.bridge.configure(config)
        h.bridge.connect()
        advanceUntilIdle()
        h.bridge.disconnect(revoke = false)
        advanceUntilIdle()
        val seen = h.events.authorizations
        assertTrue(seen.any { it?.accounts?.single()?.address == FAKE_ADDRESS })
        assertNull(seen.last())
    }
}
