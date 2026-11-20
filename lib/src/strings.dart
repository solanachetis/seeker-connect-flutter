import 'errors.dart';

/// Text shown by `SeekerConnectDialogs`. Defaults are the official Seeker
/// Connect copy (English); [SeekerConnectStrings.fr] is a French translation.
class SeekerConnectStrings {
  const SeekerConnectStrings({
    this.progressTitle = 'Continue in your Seeker Wallet',
    this.progressBody = 'Accept the connection request in your wallet',
    this.notFoundTitle = 'We can’t find your Seeker',
    this.notFoundBody = 'Make sure your Seeker Wallet is setup and try again.',
    this.connectionDeclinedTitle = 'Connection declined',
    this.connectionDeclinedBody = 'You declined the connection in your Seeker Wallet.',
    this.requestDeclinedTitle = 'Request declined',
    this.requestDeclinedBody = 'You declined the request in your Seeker Wallet.',
    this.connectionLostTitle = 'Connection lost',
    this.connectionLostBody = 'The connection to your Seeker Wallet was interrupted.',
    this.genericErrorTitle = 'Something went wrong',
    this.genericErrorBody = 'Your Seeker Wallet ran into an unexpected error.',
    this.close = 'Close',
  });

  final String progressTitle;
  final String progressBody;
  final String notFoundTitle;
  final String notFoundBody;
  final String connectionDeclinedTitle;
  final String connectionDeclinedBody;
  final String requestDeclinedTitle;
  final String requestDeclinedBody;
  final String connectionLostTitle;
  final String connectionLostBody;
  final String genericErrorTitle;
  final String genericErrorBody;
  final String close;

  /// French translation.
  static const SeekerConnectStrings fr = SeekerConnectStrings(
    progressTitle: 'Continuez dans votre Seeker Wallet',
    progressBody: 'Acceptez la demande de connexion dans votre wallet',
    notFoundTitle: 'Impossible de trouver votre Seeker',
    notFoundBody: 'Vérifiez que votre Seeker Wallet est configuré, puis réessayez.',
    connectionDeclinedTitle: 'Connexion refusée',
    connectionDeclinedBody: 'Vous avez refusé la connexion dans votre Seeker Wallet.',
    requestDeclinedTitle: 'Demande refusée',
    requestDeclinedBody: 'Vous avez refusé la demande dans votre Seeker Wallet.',
    connectionLostTitle: 'Connexion perdue',
    connectionLostBody: 'La connexion à votre Seeker Wallet a été interrompue.',
    genericErrorTitle: 'Une erreur est survenue',
    genericErrorBody: 'Votre Seeker Wallet a rencontré une erreur inattendue.',
    close: 'Fermer',
  );

  /// Title and body for an error card, following the official mapping.
  (String, String) error(SeekerConnectErrorCode code) => switch (code) {
        SeekerConnectErrorCode.noWalletFound || SeekerConnectErrorCode.associationFailed => (notFoundTitle, notFoundBody),
        SeekerConnectErrorCode.authorizationDeclined => (connectionDeclinedTitle, connectionDeclinedBody),
        SeekerConnectErrorCode.requestDeclined => (requestDeclinedTitle, requestDeclinedBody),
        SeekerConnectErrorCode.sessionClosed => (connectionLostTitle, connectionLostBody),
        SeekerConnectErrorCode.cancelled ||
        SeekerConnectErrorCode.walletError ||
        SeekerConnectErrorCode.unsupportedPlatform ||
        SeekerConnectErrorCode.notConfigured ||
        SeekerConnectErrorCode.hostNotSupported =>
          (genericErrorTitle, genericErrorBody),
      };
}
