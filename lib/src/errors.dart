/// Error codes reported by Seeker Connect.
///
/// The first seven mirror the official SDK's `SeekerConnectException.Code`;
/// the last three are specific to this plugin.
enum SeekerConnectErrorCode {
  noWalletFound,
  associationFailed,
  authorizationDeclined,
  requestDeclined,
  sessionClosed,
  cancelled,
  walletError,

  /// Seeker Connect only runs on Android.
  unsupportedPlatform,

  /// A call was made before [SeekerConnect.configure].
  notConfigured,

  /// No androidx `ComponentActivity` is attached. Use `FlutterFragmentActivity`.
  hostNotSupported,
}

/// Maps a platform error code to a [SeekerConnectErrorCode].
/// Unknown codes map to [SeekerConnectErrorCode.walletError].
SeekerConnectErrorCode codeFromString(String code) {
  for (final value in SeekerConnectErrorCode.values) {
    if (value.name == code) return value;
  }
  return SeekerConnectErrorCode.walletError;
}

/// A Seeker Connect failure.
class SeekerConnectException implements Exception {
  const SeekerConnectException(this.code, this.message);

  final SeekerConnectErrorCode code;
  final String message;

  @override
  String toString() => 'SeekerConnectException(${code.name}): $message';
}
