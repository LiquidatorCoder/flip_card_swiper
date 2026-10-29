// End-to-end checks for every example screen, run on a real device or simulator:
//
//   flutter test integration_test -d <device-id>
//
// Each case prints a `METRIC {...}` JSON line (latency in ms, frame stats) so runs
// can be compared before and after a change.

import 'dart:convert';
import 'dart:ui';

import 'package:example/main.dart';
import 'package:flip_card_swiper/flip_card_swiper.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const List<({String title, int count})> _examples = [
  (title: 'Basic', count: 10),
  (title: 'Credit Cards', count: 4),
  (title: 'Flash Cards', count: 5),
  (title: 'Travel Destinations', count: 5),
  (title: 'Profile Cards', count: 5),
  (title: 'Minimal News', count: 5),
];

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('Flash Cards: tap reveals the answer, and a cancelled drag keeps it revealed', (tester) async {
    await tester.pumpWidget(const MyApp());
    await _settle(tester);
    await tester.tap(find.text('Flash Cards'));
    await _settle(tester);
    final Offset center = tester.getCenter(find.byWidgetPredicate((w) => w is FlipCardSwiper));

    await tester.tapAt(center);
    await _settle(tester);
    expect(find.text('O(log n)'), findsOneWidget);

    await _drag(tester, center, const Offset(0, -40), const Duration(milliseconds: 500));
    await _settle(tester);
    expect(find.text('O(log n)'), findsOneWidget, reason: 'card state must survive a cancelled drag');
    expect(_counter(tester), 1);

    await _drag(tester, center, const Offset(0, -260), const Duration(milliseconds: 200));
    await _settle(tester);
    expect(_counter(tester), 2);
    expect(find.text("What does\nDRY stand for?"), findsOneWidget);
  });

  testWidgets('Basic: removing cards down to none and restoring never crashes', (tester) async {
    await tester.pumpWidget(const MyApp());
    await _settle(tester);
    await tester.tap(find.text('Basic'));
    await _settle(tester);
    final Finder swiper = find.byWidgetPredicate((w) => w is FlipCardSwiper);
    final Offset center = tester.getCenter(swiper);

    // Flip once so the stack is mid-deck, then shrink the deck card by card.
    await _drag(tester, center, const Offset(0, -260), const Duration(milliseconds: 200));
    await _settle(tester);
    for (int remaining = 9; remaining >= 1; remaining--) {
      await tester.tap(find.byKey(const Key('remove-card')));
      await _settle(tester);
      expect(tester.takeException(), isNull);
      expect(_counterText(tester), '1 / $remaining');
    }

    // A single card cannot flip.
    await _drag(tester, center, const Offset(0, -260), const Duration(milliseconds: 200));
    await _settle(tester);
    expect(_counterText(tester), '1 / 1');

    await tester.tap(find.byKey(const Key('remove-card')));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(_counterText(tester), 'No cards');

    await tester.tap(find.byKey(const Key('reset-cards')));
    await _settle(tester);
    expect(_counterText(tester), '1 / 10');
    await _drag(tester, center, const Offset(0, -260), const Duration(milliseconds: 200));
    await _settle(tester);
    expect(_counterText(tester), '2 / 10');
  });

  for (final example in _examples) {
    group(example.title, () {
      testWidgets('flip, cancel, rebound, rapid flips and wrap-around', (tester) async {
        final frames = _FrameRecorder()..start();
        await tester.pumpWidget(const MyApp());
        await _settle(tester);

        final Stopwatch open = Stopwatch()..start();
        await tester.tap(find.text(example.title));
        await _settle(tester);
        open.stop();
        _metric(example.title, 'open_page_ms', open.elapsedMilliseconds);

        final Finder swiper = find.byWidgetPredicate((w) => w is FlipCardSwiper);
        expect(swiper, findsOneWidget);
        expect(_counter(tester), 1);
        final Offset center = tester.getCenter(swiper);

        // 1. Slow, deliberate drag past the midpoint.
        int released = await _drag(tester, center, const Offset(0, -260), const Duration(milliseconds: 600));
        int settle = await _settle(tester);
        _metric(example.title, 'slow_drag_release_to_settled_ms', settle);
        expect(_counter(tester), 2, reason: 'slow drag should flip once');

        // 2. Fast fling.
        released = await _drag(tester, center, const Offset(0, -260), const Duration(milliseconds: 120));
        settle = await _settle(tester);
        _metric(example.title, 'fling_release_to_settled_ms', settle);
        expect(_counter(tester), 3, reason: 'fling should flip once');

        // 3. Short, quick flick (below the distance threshold but fast).
        released = await _drag(tester, center, const Offset(0, -55), const Duration(milliseconds: 60));
        final int flickLatency = await _waitForCounter(tester, 4);
        settle = await _settle(tester);
        _metric(example.title, 'short_flick_release_to_change_ms', flickLatency);
        expect(_counter(tester), 4, reason: 'a quick short flick should flip');
        final int afterFlick = _counter(tester);

        // 4. Small drag then release: springs back without flipping.
        released = await _drag(tester, center, const Offset(0, -40), const Duration(milliseconds: 500));
        settle = await _settle(tester);
        _metric(example.title, 'cancel_release_to_settled_ms', settle);
        expect(_counter(tester), afterFlick, reason: 'small slow drag must not flip');

        // 5. Downward drag: rubber-bands back, no flip.
        released = await _drag(tester, center, const Offset(0, 120), const Duration(milliseconds: 400));
        settle = await _settle(tester);
        _metric(example.title, 'down_drag_release_to_settled_ms', settle);
        expect(_counter(tester), afterFlick, reason: 'down drag must not flip');

        // 6. Horizontal drag is ignored.
        await _drag(tester, center, const Offset(-150, 0), const Duration(milliseconds: 200));
        await _settle(tester);
        expect(_counter(tester), afterFlick, reason: 'horizontal drag must not flip');

        // 7. Rapid flips: the next swipe starts while the previous flip is finishing.
        final int beforeRapid = _counter(tester);
        const int rapid = 3;
        final Stopwatch rapidWatch = Stopwatch()..start();
        for (int i = 0; i < rapid; i++) {
          await _drag(tester, center, const Offset(0, -240), const Duration(milliseconds: 90));
          await tester.pump(const Duration(milliseconds: 60));
        }
        await _settle(tester);
        rapidWatch.stop();
        final int registered = _wrapDelta(beforeRapid, _counter(tester), example.count);
        _metric(example.title, 'rapid_swipes_registered', registered);
        _metric(example.title, 'rapid_swipes_sent', rapid);
        _metric(example.title, 'rapid_total_ms', rapidWatch.elapsedMilliseconds);
        expect(registered, rapid, reason: 'swipes made while a flip is finishing must not be dropped');

        // 8. Wrap-around: keep flipping until we are back at card 1.
        int guard = example.count * 2;
        while (_counter(tester) != 1 && guard-- > 0) {
          await _drag(tester, center, const Offset(0, -260), const Duration(milliseconds: 200));
          await _settle(tester);
        }
        expect(_counter(tester), 1, reason: 'deck should wrap back to the first card');

        frames.stop();
        _metric(example.title, 'frames', frames.summary());
        expect(released, greaterThanOrEqualTo(0));
      });

      testWidgets('frame cost of back-to-back flips', (tester) async {
        await tester.pumpWidget(const MyApp());
        await _settle(tester);
        await tester.tap(find.text(example.title));
        await _settle(tester);
        await tester.tapAt(tester.getCenter(find.byWidgetPredicate((w) => w is FlipCardSwiper)));
        await _settle(tester);

        // Warm up (shader compilation, first layout) before measuring.
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await _settle(tester);

        final frames = _FrameRecorder()..start();
        final Stopwatch sw = Stopwatch()..start();
        for (int i = 0; i < 8; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
          await _settle(tester);
        }
        sw.stop();
        frames.stop();
        _metric(example.title, 'perf_8_flips_ms', sw.elapsedMilliseconds);
        _metric(example.title, 'perf_frames', frames.summary());
      });

      testWidgets('keyboard and accessibility flip', (tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        await tester.pumpWidget(const MyApp());
        await _settle(tester);
        await tester.tap(find.text(example.title));
        await _settle(tester);

        // Arrow-up flips once the swiper has focus (tap it first, like a user would).
        final Finder swiper = find.byWidgetPredicate((w) => w is FlipCardSwiper);
        await tester.tapAt(tester.getCenter(swiper));
        await _settle(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await _settle(tester);
        expect(_counter(tester), 2, reason: 'arrow up should flip once the stack has focus');

        // Screen readers: the stack announces its position and "increase" flips it.
        final SemanticsData data = tester.getSemantics(swiper).getSemanticsData();
        expect(data.value, '2 of ${example.count}');
        tester.semantics.increase(find.semantics.byValue('2 of ${example.count}'));
        await _settle(tester);
        expect(_counter(tester), 3, reason: 'the semantics increase action should flip');
        semantics.dispose();
      });
    });
  }
}

String _counterText(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('card-counter'))).data!;

int _counter(WidgetTester tester) {
  final Text text = tester.widget<Text>(find.byKey(const Key('card-counter')));
  return int.parse(text.data!.split('/').first.trim());
}

int _wrapDelta(int from, int to, int count) => (to - from) % count;

/// Drags with evenly spaced moves over [duration]; returns ms since epoch at release.
Future<int> _drag(WidgetTester tester, Offset start, Offset delta, Duration duration) async {
  const int steps = 12;
  final TestGesture gesture = await tester.startGesture(start, kind: PointerDeviceKind.touch);
  final Duration step = duration ~/ steps;
  for (int i = 1; i <= steps; i++) {
    await gesture.moveTo(start + delta * (i / steps), timeStamp: step * i);
    await tester.pump(step);
  }
  await gesture.up(timeStamp: duration);
  return DateTime.now().millisecondsSinceEpoch;
}

/// Pumps until no animation is ticking; returns elapsed wall-clock ms.
Future<int> _settle(WidgetTester tester, {Duration timeout = const Duration(seconds: 5)}) async {
  final Stopwatch sw = Stopwatch()..start();
  await tester.pump();
  while (sw.elapsed < timeout) {
    if (SchedulerBinding.instance.transientCallbackCount == 0 && !tester.binding.hasScheduledFrame) {
      break;
    }
    await tester.pump(const Duration(milliseconds: 4));
  }
  return sw.elapsedMilliseconds;
}

/// Pumps until the counter shows [value]; returns ms waited, or -1 on timeout.
Future<int> _waitForCounter(WidgetTester tester, int value, {Duration timeout = const Duration(seconds: 2)}) async {
  final Stopwatch sw = Stopwatch()..start();
  while (sw.elapsed < timeout) {
    if (_counter(tester) == value) return sw.elapsedMilliseconds;
    await tester.pump(const Duration(milliseconds: 4));
  }
  return -1;
}

void _metric(String example, String name, Object value) {
  // ignore: avoid_print
  print('METRIC ${jsonEncode({'example': example, 'name': name, 'value': value})}');
}

class _FrameRecorder {
  final List<FrameTiming> _timings = <FrameTiming>[];

  void _onTimings(List<FrameTiming> t) => _timings.addAll(t);

  void start() => SchedulerBinding.instance.addTimingsCallback(_onTimings);

  void stop() => SchedulerBinding.instance.removeTimingsCallback(_onTimings);

  Map<String, Object> summary() {
    if (_timings.isEmpty) return {'count': 0};
    List<double> ms(Duration Function(FrameTiming) f) =>
        _timings.map((t) => f(t).inMicroseconds / 1000.0).toList()..sort();
    final build = ms((t) => t.buildDuration);
    final raster = ms((t) => t.rasterDuration);
    double p(List<double> v, double q) => v[((v.length - 1) * q).round()];
    double avg(List<double> v) => v.reduce((a, b) => a + b) / v.length;
    String f(double v) => v.toStringAsFixed(2);
    return {
      'count': _timings.length,
      'build_avg': f(avg(build)),
      'build_p90': f(p(build, 0.9)),
      'build_max': f(build.last),
      'raster_avg': f(avg(raster)),
      'raster_p90': f(p(raster, 0.9)),
      'raster_max': f(raster.last),
      'janky_over_16ms': _timings
          .where((t) => t.buildDuration.inMicroseconds > 16667 || t.rasterDuration.inMicroseconds > 16667)
          .length,
      'over_8ms_ui_raster': _timings
          .where((t) => t.buildDuration.inMicroseconds > 8333 || t.rasterDuration.inMicroseconds > 8333)
          .length,
    };
  }
}
