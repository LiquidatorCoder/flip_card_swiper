import 'package:flip_card_swiper/flip_card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<int> changes;

  Future<void> pump(WidgetTester tester, {int count = 5}) {
    changes = <int>[];
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FlipCardSwiper<int>(
              cardData: List<int>.generate(count, (i) => i),
              onCardChange: changes.add,
              cardBuilder: (context, index, visibleIndex) =>
                  SizedBox(width: 200, height: 120, child: Text('card $index')),
            ),
          ),
        ),
      ),
    );
  }

  SemanticsNode stackNode(WidgetTester tester) => tester.getSemantics(find.byType(FlipCardSwiper<int>));

  testWidgets('only the top card is exposed to screen readers, with its position', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pump(tester);

    final SemanticsData data = stackNode(tester).getSemanticsData();
    expect(data.label, contains('card 0'));
    expect(data.label, isNot(contains('card 1')));
    expect(data.label, isNot(contains('card 2')));
    expect(data.value, '1 of 5');
    expect(data.increasedValue, '2 of 5');
    handle.dispose();
  });

  testWidgets('the increase and scroll-up actions flip to the next card', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pump(tester);
    final stack = find.semantics.byValue('1 of 5');

    tester.semantics.increase(stack);
    await tester.pumpAndSettle();
    expect(changes, <int>[1]);
    expect(stackNode(tester).getSemanticsData().value, '2 of 5');

    tester.semantics.performAction(find.semantics.byValue('2 of 5'), SemanticsAction.scrollUp);
    await tester.pumpAndSettle();
    expect(changes, <int>[1, 2]);
    handle.dispose();
  });

  testWidgets('a single card offers no flip action', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pump(tester, count: 1);

    final SemanticsData data = stackNode(tester).getSemanticsData();
    expect(data.hasAction(SemanticsAction.increase), isFalse);
    expect(data.hasAction(SemanticsAction.scrollUp), isFalse);
    handle.dispose();
  });
}
