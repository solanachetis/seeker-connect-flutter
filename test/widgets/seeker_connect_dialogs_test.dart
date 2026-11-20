import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seeker_connect_flutter/seeker_connect_flutter.dart';
import 'package:seeker_connect_flutter/src/platform.dart';

import '../fake_platform.dart';

Widget _app({SeekerConnectStrings strings = const SeekerConnectStrings()}) => Directionality(
      textDirection: TextDirection.ltr,
      child: SeekerConnectDialogs(strings: strings, child: const Center(child: Text('app content'))),
    );

void main() {
  late FakeSeekerConnectPlatform fake;

  setUp(() {
    fake = FakeSeekerConnectPlatform();
    SeekerConnectPlatform.instance = fake;
  });

  Future<void> emit(WidgetTester tester, SeekerInteractionEvent event) async {
    fake.interactionController.add(event);
    await tester.pump();
    await tester.pump();
  }

  testWidgets('nothing is shown without interactions', (tester) async {
    await tester.pumpWidget(_app());
    expect(find.text('app content'), findsOneWidget);
    expect(find.text('Continue in your Seeker Wallet'), findsNothing);
  });

  testWidgets('startedShowsProgressCard', (tester) async {
    await tester.pumpWidget(_app());
    await emit(tester, const SeekerInteractionStarted(3));
    expect(find.text('Continue in your Seeker Wallet'), findsOneWidget);
    expect(find.text('Accept the connection request in your wallet'), findsOneWidget);
  });

  testWidgets('closeOnProgressCancelsInteraction', (tester) async {
    await tester.pumpWidget(_app());
    await emit(tester, const SeekerInteractionStarted(3));
    await tester.tap(find.text('Close'));
    await tester.pump();
    expect(fake.cancelled, [3]);
  });

  testWidgets('settledHidesProgressCard', (tester) async {
    await tester.pumpWidget(_app());
    await emit(tester, const SeekerInteractionStarted(3));
    await emit(tester, const SeekerInteractionSettled(3));
    expect(find.text('Continue in your Seeker Wallet'), findsNothing);
  });

  testWidgets('settled for another id keeps the card', (tester) async {
    await tester.pumpWidget(_app());
    await emit(tester, const SeekerInteractionStarted(4));
    await emit(tester, const SeekerInteractionSettled(3));
    expect(find.text('Continue in your Seeker Wallet'), findsOneWidget);
  });

  testWidgets('failedShowsOfficialCopyPerCode', (tester) async {
    const expected = {
      SeekerConnectErrorCode.noWalletFound: ('We can’t find your Seeker', 'Make sure your Seeker Wallet is setup and try again.'),
      SeekerConnectErrorCode.associationFailed: ('We can’t find your Seeker', 'Make sure your Seeker Wallet is setup and try again.'),
      SeekerConnectErrorCode.authorizationDeclined: ('Connection declined', 'You declined the connection in your Seeker Wallet.'),
      SeekerConnectErrorCode.requestDeclined: ('Request declined', 'You declined the request in your Seeker Wallet.'),
      SeekerConnectErrorCode.sessionClosed: ('Connection lost', 'The connection to your Seeker Wallet was interrupted.'),
      SeekerConnectErrorCode.cancelled: ('Something went wrong', 'Your Seeker Wallet ran into an unexpected error.'),
      SeekerConnectErrorCode.walletError: ('Something went wrong', 'Your Seeker Wallet ran into an unexpected error.'),
      SeekerConnectErrorCode.unsupportedPlatform: ('Something went wrong', 'Your Seeker Wallet ran into an unexpected error.'),
      SeekerConnectErrorCode.notConfigured: ('Something went wrong', 'Your Seeker Wallet ran into an unexpected error.'),
      SeekerConnectErrorCode.hostNotSupported: ('Something went wrong', 'Your Seeker Wallet ran into an unexpected error.'),
    };
    expect(expected.keys.toSet(), SeekerConnectErrorCode.values.toSet());
    await tester.pumpWidget(_app());
    for (final MapEntry(key: code, value: (title, body)) in expected.entries) {
      await emit(tester, SeekerInteractionFailed(code));
      expect(find.text(title), findsOneWidget, reason: code.name);
      expect(find.text(body), findsOneWidget, reason: code.name);
      await tester.tap(find.text('Close'));
      await tester.pump();
      expect(find.text(title), findsNothing, reason: '${code.name} closes');
    }
    expect(fake.cancelled, isEmpty);
  });

  testWidgets('showDialogsFalseShowsNothing', (tester) async {
    await SeekerConnect.configure(const SeekerConnectConfig(
      identity: DappIdentity(name: 'T', uri: 'https://t.example'),
      showDialogs: false,
    ));
    await tester.pumpWidget(_app());
    await emit(tester, const SeekerInteractionStarted(1));
    await emit(tester, const SeekerInteractionFailed(SeekerConnectErrorCode.requestDeclined));
    expect(find.text('Continue in your Seeker Wallet'), findsNothing);
    expect(find.text('Request declined'), findsNothing);
  });

  testWidgets('frenchStringsAreUsedWhenProvided', (tester) async {
    await tester.pumpWidget(_app(strings: SeekerConnectStrings.fr));
    await emit(tester, const SeekerInteractionStarted(1));
    expect(find.text('Continuez dans votre Seeker Wallet'), findsOneWidget);
    expect(find.text('Fermer'), findsOneWidget);
    await emit(tester, const SeekerInteractionSettled(1));
    await emit(tester, const SeekerInteractionFailed(SeekerConnectErrorCode.authorizationDeclined));
    expect(find.text('Connexion refusée'), findsOneWidget);
  });

  testWidgets('cardTextIsNotUnderlinedUnderMaterialFallbackStyle', (tester) async {
    // MaterialApp's builder output sits under a yellow double-underline fallback style.
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: DefaultTextStyle(
        style: TextStyle(decoration: TextDecoration.underline, decorationColor: Color(0xFFFFFF00)),
        child: SeekerConnectDialogs(child: SizedBox.shrink()),
      ),
    ));
    await emit(tester, const SeekerInteractionStarted(1));
    final texts = tester.widgetList<RichText>(find.byType(RichText)).toList();
    expect(texts, isNotEmpty);
    for (final t in texts) {
      expect(t.text.style?.decoration, TextDecoration.none, reason: t.text.toPlainText());
    }
  });
}
