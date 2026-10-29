// Smoke test for the example app (FlipCardSwiper demo).

import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('home lists examples and opens the basic stack', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Basic'), findsOneWidget);
    expect(find.text('Credit Cards'), findsOneWidget);

    await tester.tap(find.text('Basic'));
    await tester.pumpAndSettle();

    expect(find.text('Card 1'), findsOneWidget);
  });
}
