import 'package:flip_card_swiper/flip_card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<String> haptics;

  setUp(() {
    haptics = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'HapticFeedback.vibrate') haptics.add(call.arguments as String);
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });

  Future<void> pump(WidgetTester tester, {bool enableHaptics = true}) => tester.pumpWidget(
    MaterialApp(
      home: Center(
        child: FlipCardSwiper<int>(
          cardData: const <int>[0, 1, 2],
          enableHaptics: enableHaptics,
          cardBuilder: (context, index, visibleIndex) => SizedBox(width: 300, height: 200, child: Text('card $index')),
        ),
      ),
    ),
  );

  testWidgets('a flip plays a light impact then a selection click', (tester) async {
    await pump(tester);
    await tester.fling(find.byType(FlipCardSwiper<int>), const Offset(0, -300), 2000);
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 300));

    expect(haptics, <String>['HapticFeedbackType.lightImpact', 'HapticFeedbackType.selectionClick']);
  });

  testWidgets('pulling down to the limit plays the blocked pattern once', (tester) async {
    await pump(tester);
    final TestGesture g = await tester.startGesture(tester.getCenter(find.byType(FlipCardSwiper<int>)));
    for (int i = 1; i <= 10; i++) {
      await g.moveBy(const Offset(0, 20));
      await tester.pump();
    }
    await g.up();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));

    expect(haptics, <String>[
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.mediumImpact',
    ]);
  });

  testWidgets('enableHaptics: false is silent', (tester) async {
    await pump(tester, enableHaptics: false);
    await tester.fling(find.byType(FlipCardSwiper<int>), const Offset(0, -300), 2000);
    await tester.drag(find.byType(FlipCardSwiper<int>), const Offset(0, 200));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));

    expect(haptics, isEmpty);
  });
}
