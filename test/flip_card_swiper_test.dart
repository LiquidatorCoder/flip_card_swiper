import 'package:flip_card_swiper/flip_card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

FlipCardSwiper<int> _swiper(List<int> data, {void Function(int)? onCardChange}) => FlipCardSwiper<int>(
  cardData: data,
  onCardChange: onCardChange,
  cardBuilder: (context, index, visibleIndex) =>
      SizedBox(key: ValueKey<int>(index), width: 200, height: 120, child: Text('card $index')),
);

void main() {
  testWidgets('renders the top three cards of the stack', (tester) async {
    await tester.pumpWidget(_app(_swiper(<int>[0, 1, 2, 3, 4])));

    expect(find.text('card 0'), findsOneWidget);
    expect(find.text('card 1'), findsOneWidget);
    expect(find.text('card 2'), findsOneWidget);
    expect(find.text('card 3'), findsNothing);
  });

  testWidgets('empty data renders nothing and does not throw', (tester) async {
    await tester.pumpWidget(_app(_swiper(<int>[])));

    expect(find.byType(Text), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a single card cannot be flipped', (tester) async {
    int changes = 0;
    await tester.pumpWidget(_app(_swiper(<int>[0], onCardChange: (_) => changes++)));

    await tester.drag(find.text('card 0'), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(changes, 0);
    expect(find.text('card 0'), findsOneWidget);
  });
}
