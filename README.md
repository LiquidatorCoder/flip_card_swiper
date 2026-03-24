<h1 align="center">Flip Card Swiper</h1>

<p align="center">
  <b>A customizable, swipeable card widget with smooth flip animations and haptic support.</b>
</p><br>

<p align="center">
  <a href="https://flutter.dev">
    <img src="https://img.shields.io/badge/Platform-Flutter-02569B?logo=flutter" alt="Platform" />
  </a>
  <a href="https://pub.dartlang.org/packages/flip_card_swiper">
    <img src="https://img.shields.io/pub/v/flip_card_swiper.svg" alt="Pub Package" />
  </a>
  <a href="https://opensource.org/licenses/MIT">
    <img src="https://img.shields.io/github/license/LiquidatorCoder/flip_card_swiper?color=red" alt="License: MIT" />
  </a>
  <a href="https://www.paypal.me/codenameakshay">
    <img src="https://img.shields.io/badge/Donate-PayPal-00457C?logo=paypal" alt="Donate" />
  </a>
</p><br>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#installation">Installation</a> •
  <a href="#usage">Usage</a> •
  <a href="#license">License</a> •
  <a href="#bugs-or-requests">Bugs or Requests</a>
</p><br>

---

| ![Colored Card Demo](https://raw.githubusercontent.com/LiquidatorCoder/flip_card_swiper/main/screenshots/colored.gif) | ![White Card Demo](https://raw.githubusercontent.com/LiquidatorCoder/flip_card_swiper/main/screenshots/white.gif) |
| --------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| **Flip Animation with Colored Cards**                                                                                 | **Flip Animation with White Cards**                                                                               |

---

## Features

- **Flip & Swipe Animations:**  
  Easily flip between cards with a vertical drag gesture. Cards smoothly animate through the stack.

- **Haptic Feedback:**  
  Provide tactile feedback to users as they flip through cards, enhancing user experience. Can be turned off with `enableHaptics: false`.

- **Accessibility:**  
  Basic `Semantics` labels, optional hints, arrow-up when focused, and reduced motion via `MediaQuery.disableAnimations`.

- **Dynamic Card Updates:**  
  The widget updates card order at mid-animation, allowing endless looping through your card collection.

- **Customizable Scaling & Offsets:**  
  Fine-tune card positions, scales, and transitions to achieve unique flipping and stacking effects.

**No extra dependencies or complicated setup—just integrate and start flipping!**

---

## Installation

Add the following line to your `pubspec.yaml`:

```yaml
dependencies:
  flip_card_swiper: ^2.1.3
```

Then, run:

```bash
flutter pub get
```

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:flip_card_swiper/flip_card_swiper.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final List<Map<String, dynamic>> cards = [
    {'color': Colors.blue, 'text': 'Card 1'},
    {'color': Colors.red, 'text': 'Card 2'},
    {'color': Colors.green, 'text': 'Card 3'},
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: FlipCardSwiper(
            cardData: cards,
            onCardChange: (newIndex) {
              // Do something when the top card changes
            },
            // Build each card widget
            cardBuilder: (context, index, visibleIndex) {
              final card = cards[index];
              return Container(
                width: 300,
                height: 200,
                decoration: BoxDecoration(
                  color: card['color'],
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  card['text'],
                  style: const TextStyle(fontSize: 24, color: Colors.white),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}


```

## License

```
MIT License

Copyright (c) 2024 Abhay Maurya

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Bugs or Requests

- For bugs, please [open an issue](https://github.com/LiquidatorCoder/flip_card_swiper/issues/new?template=bug_report.md).
- For features or enhancements, submit a [feature request](https://github.com/LiquidatorCoder/flip_card_swiper/issues/new?template=feature_request.md).
- PRs are welcome—contributions help make this tool better!
