import 'package:flip_card_swiper/flip_card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _Harness {
  final List<int> changes = <int>[];
}

Future<_Harness> _pump(
  WidgetTester tester, {
  int count = 5,
  Duration duration = const Duration(milliseconds: 600),
}) async {
  final _Harness h = _Harness();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: FlipCardSwiper<int>(
            cardData: List<int>.generate(count, (i) => i),
            animationDuration: duration,
            onCardChange: h.changes.add,
            cardBuilder: (context, index, visibleIndex) =>
                SizedBox(key: ValueKey<int>(index), width: 300, height: 200, child: Text('card $index')),
          ),
        ),
      ),
    ),
  );
  return h;
}

Offset _center(WidgetTester tester) => tester.getCenter(find.byType(FlipCardSwiper<int>));

/// Moves the pointer in [steps] even increments over [duration], pumping between moves.
Future<void> _drag(WidgetTester tester, Offset delta, Duration duration, {int steps = 20}) async {
  final Offset start = _center(tester);
  final TestGesture g = await tester.startGesture(start);
  final Duration step = duration ~/ steps;
  for (int i = 1; i <= steps; i++) {
    await g.moveTo(start + delta * (i / steps), timeStamp: step * i);
    await tester.pump(step);
  }
  await g.up(timeStamp: duration);
}

void main() {
  testWidgets('a slow drag that outlasts the flip animation flips exactly one card', (tester) async {
    final h = await _pump(tester, duration: const Duration(milliseconds: 300));

    // 300 px over 1.2 s: the completion animation finishes long before the finger lifts.
    await _drag(tester, const Offset(0, -300), const Duration(milliseconds: 1200), steps: 40);
    await tester.pumpAndSettle();

    expect(h.changes, <int>[1]);
  });

  testWidgets('a short fast flick flips the card', (tester) async {
    final h = await _pump(tester);

    await _drag(tester, const Offset(0, -55), const Duration(milliseconds: 50), steps: 5);
    await tester.pumpAndSettle();

    expect(h.changes, <int>[1]);
  });

  testWidgets('a slow short drag springs back without flipping', (tester) async {
    final h = await _pump(tester);

    await _drag(tester, const Offset(0, -40), const Duration(milliseconds: 600));
    final int frames = await tester.pumpAndSettle(const Duration(milliseconds: 16));

    expect(h.changes, isEmpty);
    // The spring must not keep ticking after it has visually settled.
    expect(frames, lessThan(30), reason: 'spring-back took $frames frames');
  });

  testWidgets('a swipe made while the previous flip is finishing is not dropped', (tester) async {
    final h = await _pump(tester);

    await _drag(tester, const Offset(0, -240), const Duration(milliseconds: 90), steps: 6);
    await tester.pump(const Duration(milliseconds: 60)); // previous flip still animating
    await _drag(tester, const Offset(0, -240), const Duration(milliseconds: 90), steps: 6);
    await tester.pumpAndSettle();

    expect(h.changes, <int>[1, 2]);
  });

  testWidgets('a new drag during a spring-back does not complete the cancelled flip', (tester) async {
    final h = await _pump(tester);

    await _drag(tester, const Offset(0, -45), const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 16)); // spring-back in flight
    await _drag(tester, const Offset(0, -35), const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(h.changes, isEmpty);
  });

  testWidgets('arrow up flips after the stack is tapped', (tester) async {
    final h = await _pump(tester);

    await tester.tapAt(_center(tester));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();

    expect(h.changes, <int>[1]);
  });

  testWidgets('a downward drag rebounds without flipping', (tester) async {
    final h = await _pump(tester);

    await _drag(tester, const Offset(0, 120), const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(h.changes, isEmpty);
  });
}
