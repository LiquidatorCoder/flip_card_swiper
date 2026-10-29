import 'package:flip_card_swiper/flip_card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late StateSetter setOuter;
  late List<int> data;
  final List<int> changes = <int>[];

  Future<void> pump(WidgetTester tester, List<int> initial) {
    data = initial;
    return tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return FlipCardSwiper<int>(
                cardData: data,
                onCardChange: changes.add,
                cardBuilder: (context, index, visibleIndex) =>
                    SizedBox(width: 300, height: 200, child: Text('card ${data[index]}')),
              );
            },
          ),
        ),
      ),
    );
  }

  testWidgets('data replaced mid-flip (after swap)', (tester) async {
    await pump(tester, [0, 1, 2, 3, 4]);
    await tester.drag(find.byType(FlipCardSwiper<int>), const Offset(0, -150));
    await tester.pump(const Duration(milliseconds: 80));
    setOuter(() => data = [10, 11, 12]);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('card 10'), findsOneWidget);
  });

  testWidgets('data shrinks to one card mid-flip', (tester) async {
    await pump(tester, [0, 1, 2, 3, 4]);
    await tester.drag(find.byType(FlipCardSwiper<int>), const Offset(0, -150));
    await tester.pump(const Duration(milliseconds: 80));
    setOuter(() => data = [7]);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('card 7'), findsOneWidget);
  });

  testWidgets('data becomes empty mid-flip then refills', (tester) async {
    await pump(tester, [0, 1, 2]);
    await tester.drag(find.byType(FlipCardSwiper<int>), const Offset(0, -150));
    await tester.pump(const Duration(milliseconds: 80));
    setOuter(() => data = []);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    setOuter(() => data = [5, 6]);
    await tester.pumpAndSettle();
    expect(find.text('card 5'), findsOneWidget);
    await tester.fling(find.byType(FlipCardSwiper<int>), const Offset(0, -300), 2000);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposed mid-flip and mid-haptic', (tester) async {
    await pump(tester, [0, 1, 2]);
    await tester.drag(find.byType(FlipCardSwiper<int>), const Offset(0, -150));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('two-card deck flips repeatedly', (tester) async {
    changes.clear();
    await pump(tester, [0, 1]);
    for (int i = 0; i < 3; i++) {
      await tester.fling(find.byType(FlipCardSwiper<int>), const Offset(0, -300), 2000);
      await tester.pumpAndSettle();
    }
    expect(changes, [1, 0, 1]);
    expect(tester.takeException(), isNull);
  });

  for (final List<int> next in <List<int>>[
    <int>[7],
    <int>[],
  ]) {
    testWidgets('an idle stack whose data changes to $next does not overflow the stack', (tester) async {
      await pump(tester, <int>[0, 1, 2]);
      setOuter(() => data = next);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('removing items from the same list instance is picked up', (tester) async {
    final List<int> shared = <int>[0, 1, 2, 3, 4];
    final List<int> built = <int>[];
    late StateSetter setLocal;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: StatefulBuilder(
            builder: (context, setState) {
              setLocal = setState;
              return FlipCardSwiper<int>(
                cardData: shared,
                cardBuilder: (context, index, visibleIndex) {
                  built.add(index);
                  return SizedBox(width: 300, height: 200, child: Text('card ${shared[index]}'));
                },
              );
            },
          ),
        ),
      ),
    );

    setLocal(() => shared.removeRange(1, 5)); // same instance, now one item
    built.clear();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(built, everyElement(lessThan(1)), reason: 'cardBuilder must not get stale indices');
    expect(find.text('card 0'), findsOneWidget);
  });
}
