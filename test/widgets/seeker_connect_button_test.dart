import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seeker_connect_flutter/seeker_connect_flutter.dart';
import 'package:seeker_connect_flutter/src/widgets/brand_glyph.dart';

const _black = Color(0xFF000000);
const _white = Color(0xFFFFFFFF);

Widget _host(Widget child, {double width = 1000}) => Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: SizedBox(width: width, child: Align(child: child))),
    );

Color _background(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(of: find.byType(SeekerConnectButton), matching: find.byType(DecoratedBox)),
  );
  return (box.decoration as BoxDecoration).color!;
}

Color _textColor(WidgetTester tester, String label) => tester.widget<Text>(find.text(label)).style!.color!;

void main() {
  testWidgets('hasOfficialSize', (tester) async {
    await tester.pumpWidget(_host(SeekerConnectButton(onPressed: () {})));
    expect(tester.getSize(find.byType(SeekerConnectButton)), const Size(368, 56));
    await tester.pumpWidget(_host(SeekerConnectButton(onPressed: () {}), width: 300));
    expect(tester.getSize(find.byType(SeekerConnectButton)), const Size(300, 56));
  });

  testWidgets('lightThemeIsBlackWithWhiteText', (tester) async {
    await tester.pumpWidget(_host(SeekerConnectButton(onPressed: () {}, brightness: Brightness.light)));
    expect(_background(tester), _black);
    expect(_textColor(tester, 'Connect with Seeker'), _white);
  });

  testWidgets('darkThemeIsWhiteWithBlackText', (tester) async {
    await tester.pumpWidget(_host(SeekerConnectButton(onPressed: () {}, brightness: Brightness.dark)));
    expect(_background(tester), _white);
    expect(_textColor(tester, 'Connect with Seeker'), _black);
  });

  testWidgets('disabledUsesFortyPercentOpacityAndIgnoresTaps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(SeekerConnectButton(
      onPressed: () => taps++,
      enabled: false,
      brightness: Brightness.light,
    )));
    expect(_background(tester), _black.withValues(alpha: 0.4));
    expect(_textColor(tester, 'Connect with Seeker'), _white.withValues(alpha: 0.4));
    await tester.tap(find.byType(SeekerConnectButton));
    expect(taps, 0);
  });

  testWidgets('labelsPerVariant', (tester) async {
    await tester.pumpWidget(_host(SeekerConnectButton(onPressed: () {})));
    expect(find.text('Connect with Seeker'), findsOneWidget);
    await tester.pumpWidget(_host(SeekerConnectButton(onPressed: () {}, variant: SeekerConnectButtonVariant.signIn)));
    expect(find.text('Sign in with Seeker'), findsOneWidget);
  });

  testWidgets('tapCallsOnPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(SeekerConnectButton(onPressed: () => taps++)));
    await tester.tap(find.byType(SeekerConnectButton));
    expect(taps, 1);
  });

  testWidgets('textIs20Medium', (tester) async {
    await tester.pumpWidget(_host(SeekerConnectButton(onPressed: () {})));
    final style = tester.widget<Text>(find.text('Connect with Seeker')).style!;
    expect(style.fontSize, 20);
    expect(style.fontWeight, FontWeight.w500);
  });

  testWidgets('isAnAccessibleButton', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(SeekerConnectButton(onPressed: () {})));
    expect(
      tester.getSemantics(find.byType(SeekerConnectButton)),
      matchesSemantics(label: 'Connect with Seeker', isButton: true, isEnabled: true, hasEnabledState: true, hasTapAction: true),
    );
    handle.dispose();
  });

  test('glyph fits the official viewBox', () {
    final bounds = sGlyphPath().getBounds();
    const viewBox = Rect.fromLTRB(88.4, 449, 106.6, 473);
    expect(bounds.left, closeTo(viewBox.left, 0.05));
    expect(bounds.top, closeTo(viewBox.top, 0.05));
    expect(bounds.right, closeTo(viewBox.right, 0.05));
    expect(bounds.bottom, closeTo(viewBox.bottom, 0.05));
  });
}
