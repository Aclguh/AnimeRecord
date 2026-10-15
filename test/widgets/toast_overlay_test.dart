import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anime_record/ui/widgets/toast_overlay.dart';

void main() {
  group('ToastOverlay Widget Tests', () {
    testWidgets('shows and auto-dismisses toast message', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Toast.show(
                  context,
                  '操作成功完成',
                  type: ToastType.success,
                  duration: const Duration(seconds: 1),
                );
              },
              child: const Text('Show Toast'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show Toast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('操作成功完成'), findsOneWidget);

      // Advance past duration (1s) + reverse animation (250ms)
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('操作成功完成'), findsNothing);
    });

    testWidgets('replaces previous toast when new toast is shown', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                ElevatedButton(
                  onPressed: () => Toast.show(
                    context,
                    '第一条提示',
                    type: ToastType.info,
                    duration: const Duration(seconds: 1),
                  ),
                  child: const Text('Toast 1'),
                ),
                ElevatedButton(
                  onPressed: () => Toast.show(
                    context,
                    '第二条警告',
                    type: ToastType.warning,
                    duration: const Duration(seconds: 1),
                  ),
                  child: const Text('Toast 2'),
                ),
              ],
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Toast 1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('第一条提示'), findsOneWidget);

      await tester.tap(find.text('Toast 2'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('第一条提示'), findsNothing);
      expect(find.text('第二条警告'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('第二条警告'), findsNothing);
    });
  });
}
