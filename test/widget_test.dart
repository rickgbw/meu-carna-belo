import 'package:flutter_test/flutter_test.dart';

import 'package:meu_carna_belo/main.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MeuCarnaBHApp());

    // Verify that the splash screen shows the app title.
    expect(find.text('Meu Carna BH'), findsOneWidget);
    expect(find.text('BLOCOS DE RUA 2026'), findsOneWidget);
  });
}
