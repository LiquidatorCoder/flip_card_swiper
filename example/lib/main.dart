import 'package:flip_card_swiper/flip_card_swiper.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _shouldPlayAnimation = false;
  final List<Map<String, dynamic>> cards = [
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
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _shouldPlayAnimation = !_shouldPlayAnimation;
            });
          },
          child: Icon(_shouldPlayAnimation ? Icons.pause : Icons.play_arrow),
        ),
        body: Center(
          child: FlipCardSwiper(
            onCardCollectionAnimationComplete: (value) {
              setState(() {
                _shouldPlayAnimation = value;
              });
            },
            shouldStartCardCollectionAnimation: _shouldPlayAnimation,
            cardData: cards,
            animationDuration: const Duration(milliseconds: 600),
            downDragDuration: const Duration(milliseconds: 200),
            onCardChange: (index) {},
            cardBuilder: (context, index, visibleIndex) {
              if (index < 0 || index >= cards.length) {
                return const SizedBox.shrink();
              }
              final card = cards[index];
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  final bool isIncoming =
                      child.key == ValueKey<int>(visibleIndex);

                  if (isIncoming) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  } else {
                    return child;
                  }
                },
                child: Container(
                  key: ValueKey<int>(visibleIndex),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: card['color'] as Color,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 40,
                      )
                    ],
                  ),
                  width: 300,
                  height: 200,
                  alignment: Alignment.center,
                  child: Text(
                    card['text'] as String,
                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
