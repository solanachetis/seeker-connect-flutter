// ignore_for_file: implementation_imports
import 'package:flutter_test/flutter_test.dart';
import 'package:seeker_connect_flutter/src/platform.dart';
import 'package:seeker_connect_flutter/src/unsupported_platform.dart';
import 'package:seeker_connect_flutter_example/main.dart';

void main() {
  testWidgets('example screen builds with every action', (tester) async {
    SeekerConnectPlatform.instance = UnsupportedSeekerConnectPlatform();
    await tester.pumpWidget(const ExampleApp());
    await tester.pump();

    expect(find.text('Connect with Seeker'), findsOneWidget);
    expect(find.text('Sign in with Seeker'), findsOneWidget);
    for (final label in [
      'Sign message',
      'Sign devnet memo transaction',
      'Sign & send devnet memo',
      'Disconnect',
      'Disconnect + revoke',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.textContaining('Wallet: none'), findsOneWidget);
  });

  testWidgets('a failed action is reported on screen', (tester) async {
    SeekerConnectPlatform.instance = UnsupportedSeekerConnectPlatform();
    await tester.pumpWidget(const ExampleApp());
    // Let the startup configure/restore finish so the buttons are enabled.
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Not connected.'), findsOneWidget);
    await tester.tap(find.text('Connect with Seeker'));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('unsupportedPlatform'), findsOneWidget);
  });
}
