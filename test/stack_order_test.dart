import 'package:flip_card_swiper/flip_card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Data indices of the stack layers, bottom to top (paint order).
List<int> _layerOrder(WidgetTester tester) {
  final Stack stack = tester.widget<Stack>(
    find.descendant(of: find.byType(FlipCardSwiper<int>), matching: find.byType(Stack)).first,
  );
  return stack.children.map((w) => (w.key! as ValueKey<int>).value).toList();
}

void main() {
  Future<void> pump(WidgetTester tester, int count) => tester.pumpWidget(
    MaterialApp(
      home: Center(
        child: FlipCardSwiper<int>(
          cardData: List<int>.generate(count, (i) => i),
          animationDuration: const Duration(milliseconds: 600),
          cardBuilder: (context, index, visibleIndex) => SizedBox(width: 300, height: 200, child: Text('card $index')),
        ),
      ),
    ),
  );

  testWidgets('the next card waits under the tucking card, so the flip ends without a pop', (tester) async {
    await pump(tester, 5);
    expect(_layerOrder(tester), <int>[2, 1, 0]);

    await tester.drag(find.byType(FlipCardSwiper<int>), const Offset(0, -150));
    await tester.pump(const Duration(milliseconds: 100)); // second half, after the swap

    // Popped card 0 at the bottom, incoming card 3 above it, then 2 and the new top 1.
    expect(_layerOrder(tester), <int>[0, 3, 2, 1]);

    await tester.pumpAndSettle();
    expect(_layerOrder(tester), <int>[3, 2, 1]);
  });

  testWidgets('a three-card deck tucks the popped card into the third slot directly', (tester) async {
    await pump(tester, 3);

    await tester.drag(find.byType(FlipCardSwiper<int>), const Offset(0, -150));
    await tester.pump(const Duration(milliseconds: 100));

    expect(_layerOrder(tester), <int>[0, 2, 1]);
  });
}
