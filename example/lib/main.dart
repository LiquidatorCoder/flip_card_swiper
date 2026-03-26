import 'package:flip_card_swiper/flip_card_swiper.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final List<Map<String, dynamic>> _cards = [
    {'color': Colors.blue, 'text': 'Card 1'},
    {'color': Colors.red, 'text': 'Card 2'},
    {'color': Colors.green, 'text': 'Card 3'},
    {'color': Colors.purple, 'text': 'Card 4'},
    {'color': Colors.orange, 'text': 'Card 5'},
    {'color': Colors.teal, 'text': 'Card 6'},
    {'color': Colors.pink, 'text': 'Card 7'},
    {'color': Colors.amber, 'text': 'Card 8'},
    {'color': Colors.indigo, 'text': 'Card 9'},
    {'color': Colors.brown, 'text': 'Card 10'},
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Stack Animation',
      home: Scaffold(
        backgroundColor: const Color(0xFFEEEEEE),
        body: Center(
          child: FlipCardSwiper(
            cardData: _cards,
            animationDuration: const Duration(milliseconds: 600),
            downDragDuration: const Duration(milliseconds: 200),
            onCardChange: (index) {},
            cardEdgeColorBuilder:(index) => darken(_cards[index]['color'] as Color, 0.1),
            cardBuilder: (context, index, visibleIndex) {
              if (index < 0 || index >= _cards.length) {
                return const SizedBox.shrink();
              }
              final card = _cards[index];
              return Container(
                key: ValueKey<int>(index),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(0),
                  color: card['color'] as Color,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 40)],
                ),
                width: 300,
                height: 200,
                alignment: Alignment.center,
                child: Text(card['text'] as String, style: const TextStyle(color: Colors.black45, fontSize: 12)),
              );
            },
          ),
        ),
      ),
    );
  }
}


// method to darken a color by a percentage (0.0 to 1.0)
Color darken(Color color, double amount) {
  assert(amount >= 0 && amount <= 1);
  final hsl = HSLColor.fromColor(color);
  final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
  return hslDark.toColor();
}