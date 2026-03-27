<h1 align="center">Flip Card Swiper</h1>

<p align="center">
  <b>Swipeable cards with flip animations, optional haptics, and a simple API.</b>
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
  <a href="#changelog">Changelog</a> •
  <a href="#license">License</a> •
  <a href="#bugs-or-requests">Bugs or Requests</a>
</p><br>

---

| ![3D Edge Demo](https://raw.githubusercontent.com/LiquidatorCoder/flip_card_swiper/main/screenshots/3d.gif) | ![Credit Card Demo](https://raw.githubusercontent.com/LiquidatorCoder/flip_card_swiper/main/screenshots/credit.gif) | ![Minimal Demo](https://raw.githubusercontent.com/LiquidatorCoder/flip_card_swiper/main/screenshots/minimal.gif) |
| ------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| **3D Edge Flip Effect**                                                                                      | **Credit Card Style**                                                                                                 | **Minimal Style**                                                                                                 |

---

## Features

- **Flip and swipe:**  
  Drag up to flip the top card. Motion eases in and out; the second half of the flip stays smooth instead of feeling mushy at the end. After you pass halfway, how long the finish takes depends on how fast you flicked and on **`completionPhaseScale`**. You can also change **`animationDuration`**, **`thresholdValue`** (progress along the drag-past this, releasing can finish the flip even before the halfway point), **`maxDragDistance`**, and optional **`earlyLiftBoost`** / **`rotationStartFraction`** for extra lift at the start of the drag.

- **Gestures that always resolve:**  
  When you lift your finger, the flip either completes or springs back-you should not get stuck between the two after a partial swipe.

- **Haptics:**  
  Light feedback while cards move. Turn it off with **`enableHaptics: false`**.

- **Accessibility:**  
  Optional labels and hints for assistive technologies, plus support for the platform’s **reduce motion** setting (`MediaQuery.disableAnimations`).

- **Reordering:**  
  Cards swap order halfway through the flip so you can loop through a list without a hard cut.

- **Layout:**  
  Separate scale and offset for the top three cards so you can tune the stack look.

**No extra dependencies or complicated setup-just integrate and start flipping!**

---

## Installation

Add this under `dependencies` in `pubspec.yaml`:

```yaml
dependencies:
  flip_card_swiper: ^2.0.0
```

Fetch packages:

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
              // Runs when the top card changes after a flip.
            },
            // completionPhaseScale: 1.35,  // optional: longer second half
            // animationDuration: const Duration(milliseconds: 600),  // default
            cardBuilder: (context, index, visibleIndex) {
              final card = cards[index];
              // Use the data index (or another stable id) as the key so state
              // survives when cards move in the stack-not only visibleIndex.
              return Container(
                key: ValueKey(index),
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

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

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

- [Report a bug](https://github.com/LiquidatorCoder/flip_card_swiper/issues/new?template=bug_report.md).
- [Request a feature](https://github.com/LiquidatorCoder/flip_card_swiper/issues/new?template=feature_request.md).
- Pull requests are welcome.
