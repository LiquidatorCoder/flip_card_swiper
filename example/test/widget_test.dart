// Basic smoke test for the example app (FlipCardSwiper demo).

import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('renders stack with first card visible', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Card 1'), findsOneWidget);
  });
}
