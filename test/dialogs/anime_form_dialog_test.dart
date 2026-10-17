import 'package:anime_record/models/anime_record.dart';
import 'package:anime_record/models/app_constants.dart';
import 'package:anime_record/ui/dialogs/anime_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrapDialog(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => child,
            );
          },
          child: const Text('Open Dialog'),
        ),
      ),
    ),
  );
}

void main() {
  group('AnimeFormDialog Widget Tests', () {
    testWidgets('shows validation error when titleZh is empty on save', (tester) async {
      AnimeRecord? savedRecord;

      await tester.pumpWidget(_wrapDialog(
        AnimeFormDialog(
          onSave: (record) => savedRecord = record,
        ),
      ));
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('添加番剧'), findsOneWidget);

      // Tap save without filling in title
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.text('请输入番剧名称'), findsOneWidget);
      expect(savedRecord, isNull);
    });

    testWidgets('successfully creates new record with entered values', (tester) async {
      AnimeRecord? savedRecord;

      await tester.pumpWidget(_wrapDialog(
        AnimeFormDialog(
          onSave: (record) => savedRecord = record,
        ),
      ));
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Enter title
      await tester.enterText(find.byType(TextFormField).first, '夏日重现');

      // Tap save
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(savedRecord, isNotNull);
      expect(savedRecord!.titleZh, '夏日重现');
      expect(savedRecord!.status, AnimeStatus.wantToWatch);
      expect(find.text('添加番剧'), findsNothing); // dialog closed
    });

    testWidgets('renders edit mode with initialRecord and triggers onDelete', (tester) async {
      const initial = AnimeRecord(
        id: 'edit_1',
        titleZh: '命运石之门',
        episodesWatched: 12,
        episodesTotal: 24,
        status: AnimeStatus.watching,
        createdAt: '2026-01-01T00:00:00.000Z',
        updatedAt: '2026-01-01T00:00:00.000Z',
      );

      bool deleted = false;
      AnimeRecord? saved;

      await tester.pumpWidget(_wrapDialog(
        AnimeFormDialog(
          initialRecord: initial,
          onSave: (rec) => saved = rec,
          onDelete: () => deleted = true,
        ),
      ));
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('编辑番剧'), findsOneWidget);
      expect(find.text('命运石之门'), findsOneWidget);

      // Tap delete button in dialog
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();

      // Confirm dialog appears
      expect(find.text('确定要删除「命运石之门」吗？此操作不可撤销。'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, '确认'));
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
      expect(saved, isNull);
    });

    testWidgets('automatically marks as watched when episodes watched reaches total', (tester) async {
      const initial = AnimeRecord(
        id: 'auto_watch_1',
        titleZh: '间谍过家家',
        episodesWatched: 11,
        episodesTotal: 12,
        status: AnimeStatus.watching,
        createdAt: '2026-01-01T00:00:00.000Z',
        updatedAt: '2026-01-01T00:00:00.000Z',
      );

      AnimeRecord? savedRecord;

      await tester.pumpWidget(_wrapDialog(
        AnimeFormDialog(
          initialRecord: initial,
          onSave: (record) => savedRecord = record,
        ),
      ));
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Change watched episode to 12
      final watchedField = find.widgetWithText(TextFormField, '11');
      await tester.enterText(watchedField, '12');

      // Tap save
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(savedRecord, isNotNull);
      expect(savedRecord!.episodesWatched, 12);
      expect(savedRecord!.status, AnimeStatus.watched);
      expect(savedRecord!.endDate.isNotEmpty, isTrue);
    });

    testWidgets('shows validation error when coverUrl is invalid URL', (tester) async {
      AnimeRecord? savedRecord;

      await tester.pumpWidget(_wrapDialog(
        AnimeFormDialog(
          onSave: (record) => savedRecord = record,
        ),
      ));
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Enter valid title
      await tester.enterText(find.byType(TextFormField).first, '合法番剧名');

      // Expand advanced section
      await tester.tap(find.textContaining('展开更多信息'));
      await tester.pumpAndSettle();

      // Enter invalid cover url
      final coverField = find.widgetWithText(TextFormField, 'https://example.com/poster.jpg');
      await tester.enterText(coverField, 'ftp://invalid-url');
      await tester.pump();

      // Tap save
      await tester.tap(find.text('保存'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('封面链接必须是以 http:// 或 https:// 开头的有效网址'), findsOneWidget);
      expect(savedRecord, isNull);
    });
  });
}
