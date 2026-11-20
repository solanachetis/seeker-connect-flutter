package io.github.seekerconnectflutter.seeker_connect_flutter

import com.solanamobile.seekerconnect.DEFAULT_ASSOCIATION_TIMEOUT_MS
import com.solanamobile.seekerconnect.DEFAULT_FIRST_CONNECT_WALLET_BASE_URI
import com.solanamobile.seekerconnect.DappIdentity
import com.solanamobile.seekerconnect.SeekerConnectConfig
import com.solanamobile.seekerconnect.SeekerConnectException
import com.solanamobile.seekerconnect.SeekerSignAndSendOptions
import com.solanamobile.seekerconnect.SeekerSignInPayload
import com.solanamobile.seekerconnect.SeekerSignInResult
import com.solanamobile.seekerconnect.SeekerWalletCapabilities
import com.solanamobile.seekerconnect.StoredAuthorization
import com.solanamobile.seekerconnect.WalletAvailability

/** Error codes shared with the Dart `SeekerConnectErrorCode` enum (same spelling). */
internal object Codes {
    const val NOT_CONFIGURED = "notConfigured"
    const val HOST_NOT_SUPPORTED = "hostNotSupported"
    const val CANCELLED = "cancelled"
    const val WALLET_ERROR = "walletError"
}

internal fun SeekerConnectException.Code.toFlutterCode(): String = when (this) {
    SeekerConnectException.Code.NO_WALLET_FOUND -> "noWalletFound"
    SeekerConnectException.Code.ASSOCIATION_FAILED -> "associationFailed"
    SeekerConnectException.Code.AUTHORIZATION_DECLINED -> "authorizationDeclined"
    SeekerConnectException.Code.REQUEST_DECLINED -> "requestDeclined"
    SeekerConnectException.Code.SESSION_CLOSED -> "sessionClosed"
    SeekerConnectException.Code.CANCELLED -> Codes.CANCELLED
    SeekerConnectException.Code.WALLET_ERROR -> Codes.WALLET_ERROR
}

internal fun MsgConfig.toSdk() = SeekerConnectConfig(
    identity = DappIdentity(identity.name, identity.uri, identity.icon),
    chain = chain,
    firstConnectWalletBaseUri = firstConnectWalletBaseUri ?: DEFAULT_FIRST_CONNECT_WALLET_BASE_URI,
    associationTimeoutMs = associationTimeoutMs ?: DEFAULT_ASSOCIATION_TIMEOUT_MS,
)

internal fun WalletAvailability.toMsg() = when (this) {
    WalletAvailability.CERTIFIED -> MsgWalletAvailability.CERTIFIED
    WalletAvailability.OTHER -> MsgWalletAvailability.OTHER
    WalletAvailability.NONE -> MsgWalletAvailability.NONE
}

/** Deliberately drops the auth token: it never crosses into Dart. */
internal fun StoredAuthorization.toMsg() = MsgAuthorization(
    accounts = accounts.map { MsgAccount(it.address, it.publicKey, it.label) },
    walletUriBase = walletUriBase,
    chain = chain,
    capabilities = capabilities.toMsg(),
)

internal fun SeekerWalletCapabilities.toMsg() = MsgCapabilities(
    maxMessagesPerRequest = maxMessagesPerRequest?.toLong(),
    maxTransactionsPerRequest = maxTransactionsPerRequest?.toLong(),
    supportedTransactionVersions = supportedTransactionVersions.map { it.toString() },
    features = features,
    supportsSignAndSendTransactions = supportsSignAndSendTransactions,
)

internal fun MsgSignInPayload.toSdk() = SeekerSignInPayload(
    domain = domain,
    address = address,
    statement = statement,
    uri = uri,
    version = version,
    chainId = chainId,
    nonce = nonce,
    issuedAt = issuedAt,
    expirationTime = expirationTime,
    notBefore = notBefore,
    requestId = requestId,
    resources = resources,
)

internal fun SeekerSignInResult.toMsg() = MsgSignInResult(address, publicKey, signedMessage, signature)

internal fun MsgSignAndSendOptions.toSdk() = SeekerSignAndSendOptions(
    minContextSlot = minContextSlot?.toInt(),
    commitment = commitment,
    skipPreflight = skipPreflight,
    maxRetries = maxRetries?.toInt(),
    waitForCommitmentToSendNextTransaction = waitForCommitmentToSendNextTransaction,
)
