import 'package:anime_record/ui/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConfirmDialog Tests', () {
    testWidgets('shows dialog and resolves true on confirm', (tester) async {
      bool? result;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await ConfirmDialog.show(
                  context,
                  title: '确认清空',
                  message: '此操作将无法撤销',
                );
              },
              child: const Text('Show'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('确认清空'), findsOneWidget);
      expect(find.text('此操作将无法撤销'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, '确认'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('resolves false on cancel', (tester) async {
      bool? result;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await ConfirmDialog.show(
                  context,
                  title: '提示',
                  message: '取消测试',
                );
              },
              child: const Text('Show'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });
  });
}
