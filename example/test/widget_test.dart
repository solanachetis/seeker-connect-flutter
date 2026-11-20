import 'package:flutter_test/flutter_test.dart';
import 'package:seeker_connect_flutter_example/main.dart' as app;

void main() {
  testWidgets('example builds', (tester) async {
    app.main();
    await tester.pump();
  });
}
