import 'dart:async';

import 'package:flip_card_swiper/flip_card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<int> changes;

  Widget swiper(FlipCardSwiperController? controller, {int count = 5}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: FlipCardSwiper<int>(
            controller: controller,
            cardData: List<int>.generate(count, (i) => i),
            animationDuration: const Duration(milliseconds: 600),
            onCardChange: changes.add,
            cardBuilder: (context, index, visibleIndex) =>
                SizedBox(key: ValueKey<int>(index), width: 300, height: 200, child: Text('card $index')),
          ),
        ),
      ),
    );
  }

  setUp(() => changes = <int>[]);

  testWidgets('flipToNext flips exactly one card', (tester) async {
    final controller = FlipCardSwiperController();
    await tester.pumpWidget(swiper(controller));
    expect(controller.isAttached, isTrue);

    expect(controller.flipToNext(), isTrue);
    await tester.pumpAndSettle();

    expect(changes, <int>[1]);
    expect(controller.isAnimating, isFalse);
  });

  testWidgets('flipToNext does nothing while a pointer is down on the stack', (tester) async {
    final controller = FlipCardSwiperController();
    await tester.pumpWidget(swiper(controller));

    final TestGesture g = await tester.startGesture(tester.getCenter(find.byType(FlipCardSwiper<int>)));
    await tester.pump();
    expect(controller.isUserTouching, isTrue);
    expect(controller.flipToNext(), isFalse);
    await tester.pumpAndSettle();
    expect(changes, isEmpty);

    await g.up();
    await tester.pump();
    expect(controller.isUserTouching, isFalse);
    expect(controller.flipToNext(), isTrue);
    await tester.pumpAndSettle();
    expect(changes, <int>[1]);
  });

  testWidgets('flipToNext does nothing while a flip is running', (tester) async {
    final controller = FlipCardSwiperController();
    await tester.pumpWidget(swiper(controller));

    expect(controller.flipToNext(), isTrue);
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.isAnimating, isTrue);
    expect(controller.flipToNext(), isFalse);
    await tester.pumpAndSettle();

    expect(changes, <int>[1]);
  });

  testWidgets('flipToNext does nothing with a single card', (tester) async {
    final controller = FlipCardSwiperController();
    await tester.pumpWidget(swiper(controller, count: 1));

    expect(controller.flipToNext(), isFalse);
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
  });

  test('an unattached controller does nothing', () {
    final controller = FlipCardSwiperController();
    expect(controller.isAttached, isFalse);
    expect(controller.isUserTouching, isFalse);
    expect(controller.isAnimating, isFalse);
    expect(controller.flipToNext(), isFalse);
  });

  testWidgets('the controller detaches when the swiper is disposed', (tester) async {
    final controller = FlipCardSwiperController();
    await tester.pumpWidget(swiper(controller));
    expect(controller.isAttached, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(controller.isAttached, isFalse);
    expect(controller.flipToNext(), isFalse);
  });

  testWidgets('swapping controllers detaches the old one and attaches the new one', (tester) async {
    final first = FlipCardSwiperController();
    final second = FlipCardSwiperController();
    await tester.pumpWidget(swiper(first));

    await tester.pumpWidget(swiper(second));
    expect(first.isAttached, isFalse);
    expect(second.isAttached, isTrue);
    expect(first.flipToNext(), isFalse);
    expect(second.flipToNext(), isTrue);
    await tester.pumpAndSettle();
    expect(changes, <int>[1]);

    await tester.pumpWidget(swiper(null));
    expect(second.isAttached, isFalse);
  });

  testWidgets('a periodic timer auto-plays the stack and skips beats while touched', (tester) async {
    final controller = FlipCardSwiperController();
    await tester.pumpWidget(swiper(controller));
    final Timer timer = Timer.periodic(const Duration(seconds: 2), (_) => controller.flipToNext());

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(changes, <int>[1]);

    final TestGesture g = await tester.startGesture(tester.getCenter(find.byType(FlipCardSwiper<int>)));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(changes, <int>[1]);

    await g.up();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(changes, <int>[1, 2]);
    timer.cancel();
  });
}
