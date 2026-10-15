import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anime_record/models/anime_record.dart';
import 'package:anime_record/models/app_constants.dart';
import 'package:anime_record/ui/widgets/anime_card.dart';

AnimeRecord _makeRecord({
  required String id,
  required String titleZh,
  String titleJa = '',
  String coverUrl = '',
  String status = AnimeStatus.wantToWatch,
  String week = '',
  String airStatus = '',
  double rating = 0.0,
  int episodesWatched = 0,
  int episodesTotal = 0,
  List<String> tags = const [],
  String notes = '',
  String? createdAt,
  String? updatedAt,
}) {
  return AnimeRecord(
    id: id,
    titleZh: titleZh,
    titleJa: titleJa,
    coverUrl: coverUrl,
    status: status,
    week: week,
    airStatus: airStatus,
    rating: rating,
    episodesWatched: episodesWatched,
    episodesTotal: episodesTotal,
    tags: tags,
    notes: notes,
    createdAt: createdAt ?? '2026-01-01T00:00:00.000Z',
    updatedAt: updatedAt ?? '2026-01-01T00:00:00.000Z',
  );
}

Widget _wrapWithApp(Widget child, {ThemeMode themeMode = ThemeMode.light}) {
  return MaterialApp(
    themeMode: themeMode,
    theme: ThemeData.light(useMaterial3: true),
    darkTheme: ThemeData.dark(useMaterial3: true),
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 400,
          height: 250,
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  group('AnimeCard Widget Tests', () {
    testWidgets('renders basic anime information without cover', (tester) async {
      final record = _makeRecord(
        id: 'c1',
        titleZh: '葬送的芙莉莲',
        titleJa: '葬送のフリーレン',
        status: AnimeStatus.watching,
        week: WeekDay.fri,
        airStatus: AirStatus.airing,
        rating: 9.5,
        episodesWatched: 12,
        episodesTotal: 28,
      );

      bool edited = false;
      bool deleted = false;
      bool episodeAdded = false;

      await tester.pumpWidget(_wrapWithApp(
        AnimeCard(
          record: record,
          onEdit: () => edited = true,
          onDelete: () => deleted = true,
          onEpisodePlusOne: () => episodeAdded = true,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('葬送的芙莉莲'), findsOneWidget);
      expect(find.text('葬送のフリーレン'), findsOneWidget);
      expect(find.text('在看'), findsOneWidget);
      expect(find.text('周五'), findsOneWidget);
      expect(find.text('正在更新'), findsOneWidget);
      expect(find.text('9.5'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text(' / 28'), findsOneWidget);
      expect(find.text('剩 16 集'), findsOneWidget);

      // Verify buttons interaction
      await tester.tap(find.text('编辑'));
      expect(edited, isTrue);

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      expect(deleted, isTrue);

      await tester.tap(find.text('+1 集'));
      expect(episodeAdded, isTrue);
    });

    testWidgets('renders cover image when coverUrl is present', (tester) async {
      final record = _makeRecord(
        id: 'c2',
        titleZh: '间谍过家家',
        coverUrl: 'https://example.com/cover.jpg',
        status: AnimeStatus.watching,
        episodesWatched: 5,
        episodesTotal: 12,
      );

      await tester.pumpWidget(_wrapWithApp(
        AnimeCard(
          record: record,
          onEdit: () {},
          onDelete: () {},
          onEpisodePlusOne: () {},
        ),
      ));
      await tester.pump();

      expect(find.text('间谍过家家'), findsOneWidget);
      expect(find.text('在看'), findsOneWidget);
    });

    testWidgets('displays completed state when watched equals total', (tester) async {
      final record = _makeRecord(
        id: 'c3',
        titleZh: '钢之炼金术师FA',
        status: AnimeStatus.watched,
        episodesWatched: 64,
        episodesTotal: 64,
      );

      await tester.pumpWidget(_wrapWithApp(
        AnimeCard(
          record: record,
          onEdit: () {},
          onDelete: () {},
          onEpisodePlusOne: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('钢之炼金术师FA'), findsOneWidget);
      expect(find.text('已追完'), findsOneWidget);
      expect(find.text('+1 集'), findsNothing);
    });

    testWidgets('renders properly in dark mode', (tester) async {
      final record = _makeRecord(
        id: 'c4',
        titleZh: '孤独摇滚',
        status: AnimeStatus.wantToWatch,
      );

      await tester.pumpWidget(_wrapWithApp(
        AnimeCard(
          record: record,
          onEdit: () {},
          onDelete: () {},
          onEpisodePlusOne: () {},
        ),
        themeMode: ThemeMode.dark,
      ));
      await tester.pumpAndSettle();

      expect(find.text('孤独摇滚'), findsOneWidget);
      expect(find.text('想看'), findsOneWidget);
    });
  });
}
