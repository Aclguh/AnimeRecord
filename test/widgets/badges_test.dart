import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anime_record/models/app_constants.dart';
import 'package:anime_record/ui/widgets/badges/anime_air_status_badge.dart';
import 'package:anime_record/ui/widgets/badges/anime_rating_badge.dart';
import 'package:anime_record/ui/widgets/badges/anime_status_badge.dart';
import 'package:anime_record/ui/widgets/badges/anime_week_badge.dart';

void main() {
  group('Atomic Badges Widget Tests', () {
    testWidgets('AnimeStatusBadge renders label and color correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimeStatusBadge(
              status: AnimeStatus.watching,
              color: Colors.green,
              softColor: Colors.lightGreen,
            ),
          ),
        ),
      );

      expect(find.text('在看'), findsOneWidget);
    });

    testWidgets('AnimeWeekBadge renders day label and full tooltip', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimeWeekBadge(week: WeekDay.fri),
          ),
        ),
      );

      expect(find.text('周五'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
    });

    testWidgets('AnimeAirStatusBadge renders airing and finished states', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AnimeAirStatusBadge(airStatus: AirStatus.airing),
                AnimeAirStatusBadge(airStatus: AirStatus.finished),
              ],
            ),
          ),
        ),
      );

      expect(find.text('正在更新'), findsOneWidget);
      expect(find.text('完结'), findsOneWidget);
      expect(find.byIcon(Icons.sensors_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
    });

    testWidgets('AnimeRatingBadge renders formatted rating text and star icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AnimeRatingBadge(rating: 8.5, isDark: false),
                AnimeRatingBadge(rating: 9.0, isDark: true),
              ],
            ),
          ),
        ),
      );

      expect(find.text('8.5'), findsOneWidget);
      expect(find.text('9.0'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(2));
    });
  });
}
