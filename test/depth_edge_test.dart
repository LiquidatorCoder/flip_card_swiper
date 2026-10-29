import 'package:flip_card_swiper/flip_card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const Color _edge = Color(0xFF123456);

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: FlipCardSwiper<int>(
            cardData: List<int>.generate(4, (i) => i),
            cardEdgeThickness: 6,
            cardEdgeColorBuilder: (_) => _edge,
            cardBuilder: (context, index, visibleIndex) => SizedBox(
              width: 300,
              height: 200,
              child: ColoredBox(color: Colors.blue, child: Text('card $index')),
            ),
          ),
        ),
      ),
    ),
  );
}

Finder _edgeStrips() => find.byWidgetPredicate((w) => w is ColoredBox && w.color == _edge);

void main() {
  testWidgets('depth edges show only while the card is tilted', (tester) async {
    await _pump(tester);
    expect(_edgeStrips(), findsNothing);

    final TestGesture g = await tester.startGesture(tester.getCenter(find.byType(FlipCardSwiper<int>)));
    await g.moveBy(const Offset(0, -60));
    await tester.pump();
    expect(_edgeStrips(), findsOneWidget);

    await g.up();
    await tester.pumpAndSettle();
    expect(_edgeStrips(), findsNothing);
  });

  // A strip folded 90° has zero height on its own; it only has area when drawn under the
  // perspective that tilts the card. A composited transform (one whose subtree holds a
  // repaint boundary, like each card) records the strip in a separate picture without that
  // perspective, so the engine culls it and the edge never appears on screen.
  testWidgets('depth edges are painted under the tilt, not inside a composited layer', (tester) async {
    await _pump(tester);
    final TestGesture g = await tester.startGesture(tester.getCenter(find.byType(FlipCardSwiper<int>)));
    await g.moveBy(const Offset(0, -60));
    await tester.pump();

    final RenderObject strip = tester.renderObject(_edgeStrips());
    final List<RenderTransform> transforms = <RenderTransform>[];
    for (RenderObject? node = strip.parent; node != null && node is! RenderRepaintBoundary; node = node.parent) {
      if (node is RenderTransform) transforms.add(node);
    }
    // The strip's own fold plus the card's tilt.
    expect(transforms.length, greaterThanOrEqualTo(2));
    for (final RenderTransform t in transforms) {
      expect(t.needsCompositing, isFalse, reason: 'a composited transform drops the perspective the edge needs');
    }

    await g.up();
    await tester.pumpAndSettle();
  });
}
