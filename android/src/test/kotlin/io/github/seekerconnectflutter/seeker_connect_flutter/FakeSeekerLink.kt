package io.github.seekerconnectflutter.seeker_connect_flutter

import com.solanamobile.seekerconnect.SeekerAccount
import com.solanamobile.seekerconnect.SeekerAuthorization
import com.solanamobile.seekerconnect.SeekerConnectConfig
import com.solanamobile.seekerconnect.SeekerConnectException
import com.solanamobile.seekerconnect.SeekerLink
import com.solanamobile.seekerconnect.SeekerSignAndSendOptions
import com.solanamobile.seekerconnect.SeekerSignInPayload
import com.solanamobile.seekerconnect.SeekerSignInResult
import com.solanamobile.seekerconnect.SeekerWallet
import com.solanamobile.seekerconnect.SeekerWalletCapabilities
import com.solanamobile.seekerconnect.WalletAvailability
import kotlinx.coroutines.CompletableDeferred

object FakeHost

const val FAKE_ADDRESS = "FakeAddr1111111111111111111111111111111111"
const val FAKE_TOKEN = "secret-auth-token"
val FAKE_PUBLIC_KEY = ByteArray(32) { 9 }

/** A scripted wallet link: counts sessions, can fail, can block until released. */
class FakeSeekerLink : SeekerLink<FakeHost> {
    var availability = WalletAvailability.CERTIFIED
    var transactCount = 0

    /** Thrown by the next wallet request (authorize or any request), then cleared. */
    var failNext: SeekerConnectException? = null

    /** When set, every session suspends until this completes. */
    var gate: CompletableDeferred<Unit>? = null
    val wallet = FakeWallet(this)

    override fun walletAvailability(config: SeekerConnectConfig) = availability

    override suspend fun <T> transact(
        host: FakeHost,
        config: SeekerConnectConfig,
        walletUriBase: String?,
        block: suspend (SeekerWallet) -> T,
    ): T {
        transactCount++
        gate?.await()
        return block(wallet)
    }

    fun maybeFail() {
        failNext?.let {
            failNext = null
            throw it
        }
    }
}

class FakeWallet(private val link: FakeSeekerLink) : SeekerWallet {
    val deauthorized = mutableListOf<String>()
    var lastAddresses: List<String>? = null
    var lastOptions: SeekerSignAndSendOptions? = null
    var lastSignInPayload: SeekerSignInPayload? = null

    override suspend fun authorize(
        chain: String?,
        authToken: String?,
        signInPayload: SeekerSignInPayload?,
    ): SeekerAuthorization {
        link.maybeFail()
        lastSignInPayload = signInPayload
        return SeekerAuthorization(
            accounts = listOf(SeekerAccount(FAKE_ADDRESS, FAKE_PUBLIC_KEY, "main")),
            authToken = FAKE_TOKEN,
            walletUriBase = "https://wallet.example",
            signInResult = signInPayload?.let {
                SeekerSignInResult(FAKE_ADDRESS, FAKE_PUBLIC_KEY, byteArrayOf(1, 2), ByteArray(64) { 7 })
            },
        )
    }

    override suspend fun deauthorize(authToken: String) {
        link.maybeFail()
        deauthorized += authToken
    }

    override suspend fun getCapabilities() = SeekerWalletCapabilities(
        maxMessagesPerRequest = 4,
        supportedTransactionVersions = listOf("legacy", 0),
        supportsSignAndSendTransactions = true,
    )

    override suspend fun signMessages(addresses: List<String>, payloads: List<ByteArray>): List<ByteArray> {
        link.maybeFail()
        lastAddresses = addresses
        return payloads.map { it + byteArrayOf(0x51) }
    }

    override suspend fun signTransactions(payloads: List<ByteArray>): List<ByteArray> {
        link.maybeFail()
        return payloads.map { it + byteArrayOf(0x54) }
    }

    override suspend fun signAndSendTransactions(
        payloads: List<ByteArray>,
        options: SeekerSignAndSendOptions?,
    ): List<ByteArray> {
        link.maybeFail()
        lastOptions = options
        return payloads.map { ByteArray(64) { 5 } }
    }
}
