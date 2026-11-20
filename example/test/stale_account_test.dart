// ignore_for_file: implementation_imports
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seeker_connect_flutter/seeker_connect_flutter.dart';
import 'package:seeker_connect_flutter/src/unsupported_platform.dart';
import 'package:seeker_connect_flutter/src/platform.dart';
import 'package:seeker_connect_flutter_example/main.dart';

/// Connects fine, but the wallet declines the revoke.
class _RevokeDeclinedPlatform extends UnsupportedSeekerConnectPlatform {
  @override
  Future<WalletAvailability> walletAvailability() async => WalletAvailability.certified;

  @override
  Future<StoredAuthorization> connect() async => StoredAuthorization(
        accounts: [SeekerAccount(address: 'Addr111', publicKey: Uint8List(32))],
        walletUriBase: null,
        chain: 'solana:devnet',
        capabilities: const SeekerWalletCapabilities(),
      );

  @override
  Future<void> disconnect({required bool revoke}) async {
    if (revoke) throw PlatformException(code: 'requestDeclined', message: 'declined');
  }
}

void main() {
  testWidgets('a failed revoke does not leave a stale account on screen', (tester) async {
    SeekerConnectPlatform.instance = _RevokeDeclinedPlatform();
    await tester.pumpWidget(const ExampleApp());
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Connect with Seeker'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Account: Addr111'), findsOneWidget);

    await tester.tap(find.text('Disconnect + revoke'));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('requestDeclined'), findsOneWidget);
    expect(find.text('Account: Addr111'), findsNothing);
    expect(find.text('Not connected'), findsOneWidget);
  });
}
