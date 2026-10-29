import 'package:flip_card_swiper/flip_card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Counts how often each card's State is created, to detect remounts.
class _Probe extends StatefulWidget {
  const _Probe({super.key, required this.index, required this.mounts, this.label = ''});

  final int index;
  final Map<int, int> mounts;
  final String label;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.mounts.update(widget.index, (v) => v + 1, ifAbsent: () => 1);
  }

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 300, height: 200, child: Text('card ${widget.index}${widget.label}'));
}

Future<void> _flick(WidgetTester tester) async {
  await tester.fling(find.byType(FlipCardSwiper<int>), const Offset(0, -300), 2000);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('cards keep their State through a flip (no remounts)', (tester) async {
    final Map<int, int> mounts = <int, int>{};
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: FlipCardSwiper<int>(
            cardData: const <int>[0, 1, 2, 3, 4],
            cardBuilder: (context, index, visibleIndex) =>
                _Probe(key: ValueKey<int>(index), index: index, mounts: mounts),
          ),
        ),
      ),
    );
    expect(mounts, <int, int>{0: 1, 1: 1, 2: 1});

    await _flick(tester);

    // Card 3 is newly visible; cards 0-2 must not have been rebuilt from scratch.
    expect(mounts, <int, int>{0: 1, 1: 1, 2: 1, 3: 1});
  });

  for (final int count in <int>[2, 3]) {
    testWidgets('a $count-card deck never remounts a card across several flips', (tester) async {
      final Map<int, int> mounts = <int, int>{};
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: FlipCardSwiper<int>(
              cardData: List<int>.generate(count, (i) => i),
              cardBuilder: (context, index, visibleIndex) =>
                  _Probe(key: ValueKey<int>(index), index: index, mounts: mounts),
            ),
          ),
        ),
      );

      for (int i = 0; i < 4; i++) {
        await _flick(tester);
      }

      expect(mounts, <int, int>{for (int i = 0; i < count; i++) i: 1});
    });
  }

  testWidgets('cardBuilder may read inherited widgets such as Theme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
        home: Center(
          child: FlipCardSwiper<int>(
            cardData: const <int>[0, 1, 2],
            cardBuilder: (context, index, visibleIndex) => Container(
              width: 300,
              height: 200,
              color: Theme.of(context).colorScheme.primary,
              child: Text('card $index'),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('card 0'), findsOneWidget);
  });

  testWidgets('cards rebuild when the parent rebuilds with a new cardBuilder', (tester) async {
    final Map<int, int> mounts = <int, int>{};
    String suffix = '';
    late StateSetter setOuter;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return FlipCardSwiper<int>(
                cardData: const <int>[0, 1, 2],
                cardBuilder: (context, index, visibleIndex) =>
                    _Probe(key: ValueKey<int>(index), index: index, mounts: mounts, label: suffix),
              );
            },
          ),
        ),
      ),
    );

    setOuter(() => suffix = ' (revealed)');
    await tester.pump();

    expect(find.text('card 0 (revealed)'), findsOneWidget);
  });
}
