import 'package:anime_record/models/app_constants.dart';
import 'package:anime_record/ui/widgets/week_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WeekFilterBar Widget Tests', () {
    testWidgets('hides completely when no week counts exist', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WeekFilterBar(
            activeWeek: '',
            weekCounts: const {},
            onSelectWeek: (_) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(WeekFilterBar), findsOneWidget);
      expect(find.text('更新日'), findsNothing);
    });

    testWidgets('shows chips when week counts exist and fires callback', (tester) async {
      String selected = '';

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WeekFilterBar(
            activeWeek: '',
            weekCounts: const {WeekDay.fri: 4, WeekDay.sat: 2},
            onSelectWeek: (w) => selected = w,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('更新日'), findsOneWidget);
      expect(find.text('全部'), findsOneWidget);
      expect(find.text('周五'), findsOneWidget);
      expect(find.text('周六'), findsOneWidget);
      expect(find.text('周日'), findsNothing); // 0 count is hidden

      await tester.tap(find.text('周五'));
      expect(selected, WeekDay.fri);
    });
  });
}
