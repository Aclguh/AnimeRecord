import 'dart:ui';
import 'package:anime_record/main.dart';
import 'package:anime_record/models/anime_record.dart';
import 'package:anime_record/models/app_constants.dart';
import 'package:anime_record/services/import_export_service.dart';
import 'package:anime_record/services/storage_service.dart';
import 'package:anime_record/services/sync_service.dart';
import 'package:anime_record/state/anime_provider.dart';
import 'package:anime_record/state/locale_provider.dart';
import 'package:anime_record/state/theme_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AnimeRecord Model Tests', () {
    test('createEmpty initializes valid record', () {
      final record = AnimeRecord.createEmpty();
      expect(record.id.isNotEmpty, isTrue);
      expect(record.status, equals(AnimeStatus.wantToWatch));
      expect(record.episodesWatched, equals(0));
      expect(record.episodesTotal, equals(0));
      expect(record.createdAt.isNotEmpty, isTrue);
    });

    test('validation rules check required fields', () {
      final invalid = AnimeRecord.createEmpty();
      expect(invalid.validate(), equals('请输入番剧名称'));

      final valid = invalid.copyWith(titleZh: '葬送的芙莉莲');
      expect(valid.validate(), isNull);

      final invalidEp = valid.copyWith(episodesWatched: 15, episodesTotal: 10);
      expect(invalidEp.validate(), equals('已看集数不能超过总集数'));

      final invalidUrl = valid.copyWith(coverUrl: 'javascript:alert(1)');
      expect(invalidUrl.validate(), equals('封面链接必须是以 http:// 或 https:// 开头的有效网址'));

      final validUrl = valid.copyWith(coverUrl: 'https://example.com/cover.jpg');
      expect(validUrl.validate(), isNull);
    });

    test('JSON serialization & deserialization works seamlessly', () {
      const original = AnimeRecord(
        id: 'test-id-1',
        titleZh: '葬送的芙莉莲',
        titleJa: '葬送のフリーレン',
        status: AnimeStatus.watching,
        week: WeekDay.fri,
        airStatus: AirStatus.airing,
        rating: 9.5,
        episodesWatched: 12,
        episodesTotal: 28,
        tags: ['奇幻', '冒险'],
        notes: '很好看',
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-02T00:00:00.000Z',
      );

      final json = original.toJson();
      final restored = AnimeRecord.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.titleZh, equals(original.titleZh));
      expect(restored.titleJa, equals(original.titleJa));
      expect(restored.status, equals(original.status));
      expect(restored.week, equals(original.week));
      expect(restored.airStatus, equals(original.airStatus));
      expect(restored.rating, equals(original.rating));
      expect(restored.episodesWatched, equals(original.episodesWatched));
      expect(restored.episodesTotal, equals(original.episodesTotal));
      expect(restored.tags, equals(original.tags));
      expect(restored.watchStatus, equals(WatchStatus.watching));
      expect(restored.weekDayEnum, equals(WeekDayEnum.fri));
      expect(restored.airStatusEnum, equals(AirStatusEnum.airing));
      expect(restored.notes, equals(original.notes));
    });

    test('AnimeRecord incrementEpisode transitions status correctly', () {
      final rec = AnimeRecord.createEmpty().copyWith(
        titleZh: '测试番剧',
        status: AnimeStatus.wantToWatch,
        episodesWatched: 11,
        episodesTotal: 12,
      );

      // want_to_watch -> watched (because nextWatched=12 >= total=12)
      final res = rec.incrementEpisode();
      expect(res.record.status, equals(AnimeStatus.watched));
      expect(res.record.watchStatus, equals(WatchStatus.watched));
      expect(res.record.episodesWatched, equals(12));
      expect(res.record.endDate.isNotEmpty, isTrue);
      expect(res.statusChangedMessage, contains('已追完'));
    });

    test('AnimeRecord value equality and hashCode behave correctly', () {
      final rec1 = AnimeRecord.createEmpty().copyWith(
        id: 'test_id',
        titleZh: '测试番剧',
        tags: ['搞笑', '日常'],
      );
      final rec2 = rec1.copyWith();
      final rec3 = rec1.copyWith(titleZh: '不同标题');

      expect(rec1, equals(rec2));
      expect(rec1.hashCode, equals(rec2.hashCode));
      expect(rec1, isNot(equals(rec3)));
      expect(rec1.toString(), contains('test_id'));
    });
  });

  group('StorageService & Tombstones Tests', () {
    test('save and load records with tombstone tracking', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);

      final rec = AnimeRecord.createEmpty().copyWith(titleZh: '鬼灭之刃');
      final added = await storage.addRecord(rec);
      expect(added, isNotNull);

      var list = storage.loadRecords();
      expect(list.length, equals(1));
      expect(list.first.titleZh, equals('鬼灭之刃'));

      // Delete record and verify tombstone is recorded
      await storage.deleteRecord(added!.id);
      list = storage.loadRecords();
      expect(list.isEmpty, isTrue);

      final tombstones = storage.getTombstones();
      expect(tombstones.containsKey(added.id), isTrue);
    });

    test('recovers from backup snapshot and self-heals when main key is corrupted', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);

      final rec1 = AnimeRecord.createEmpty().copyWith(titleZh: '备份测试番剧1');
      await storage.saveRecords([rec1]);

      // 再次保存以触发快照机制
      final rec2 = AnimeRecord.createEmpty().copyWith(titleZh: '备份测试番剧2');
      await storage.saveRecords([rec1, rec2]);

      expect(prefs.containsKey(StorageService.backupKey), isTrue);

      // 人为破坏主存储数据
      await prefs.setString(StorageService.storageKey, '{ invalid json corrupted content }');

      // 读取时应触发容灾恢复
      final restored = storage.loadRecords();
      expect(restored.length, equals(1));
      expect(restored.first.titleZh, equals('备份测试番剧1'));

      // 验证自愈修复：主存储应已被重新写入有效内容
      final healedContent = prefs.getString(StorageService.storageKey);
      expect(healedContent, isNotNull);
      expect(healedContent!.contains('备份测试番剧1'), isTrue);
    });
  });

  group('SyncService Bidirectional Merge Tests', () {
    test('mergeSyncRecords adopts newer updates and respects tombstones', () {
      final syncService = SyncService();

      const localRec = AnimeRecord(
        id: '1',
        titleZh: '番剧A',
        episodesWatched: 5,
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T10:00:00.000Z',
      );

      const remoteRec = AnimeRecord(
        id: '1',
        titleZh: '番剧A',
        episodesWatched: 8,
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T12:00:00.000Z',
      );

      final mergeRes = syncService.mergeSyncRecords(
        [localRec],
        [remoteRec],
        {},
        {},
      );

      expect(mergeRes.mergedRecords.length, equals(1));
      expect(mergeRes.mergedRecords.first.episodesWatched, equals(8));
      expect(mergeRes.hasChanges, isTrue);
    });

    test('cleanGistId extracts pure Gist ID from URL or raw ID', () {
      expect(
        SyncService.cleanGistId('https://gist.github.com/user/a1b2c3d4e5f6'),
        equals('a1b2c3d4e5f6'),
      );
      expect(
        SyncService.cleanGistId('https://gist.github.com/a1b2c3d4e5f6'),
        equals('a1b2c3d4e5f6'),
      );
      expect(
        SyncService.cleanGistId('  a1b2c3d4e5f6/  '),
        equals('a1b2c3d4e5f6'),
      );
    });
  });

  group('ImportExportService Tests', () {
    test('parseImportJson filters template comments and parses correctly', () {
      final template = ImportExportService.exportTemplateJson();
      final records = ImportExportService.parseImportJson(template);
      expect(records.length, equals(2));
      expect(records.any((r) => r.titleZh.contains('葬送的芙莉莲')), isTrue);
    });
  });

  group('UI Smoke Test', () {
    testWidgets('App renders Home screen correctly', (WidgetTester tester) async {
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);
      final animeProvider = AnimeProvider(storage: storage);
      final themeProvider = ThemeProvider(storage);
      final localeProvider = LocaleProvider(storage);
      await localeProvider.setLocale('zh');

      await tester.pumpWidget(
        AnimeRecordApp(
          animeProvider: animeProvider,
          themeProvider: themeProvider,
          localeProvider: localeProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('看番记录'), findsOneWidget);
      expect(find.text('全部'), findsOneWidget);
      expect(find.text('在看'), findsWidgets);
      expect(find.text('添加番剧'), findsOneWidget);
    });

    testWidgets('App renders Home screen in English when locale is set to en', (WidgetTester tester) async {
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);
      final animeProvider = AnimeProvider(storage: storage);
      final themeProvider = ThemeProvider(storage);
      final localeProvider = LocaleProvider(storage);
      await localeProvider.setLocale('en');

      await tester.pumpWidget(
        AnimeRecordApp(
          animeProvider: animeProvider,
          themeProvider: themeProvider,
          localeProvider: localeProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Anime Record'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Watching'), findsWidgets);
      expect(find.text('Add Anime'), findsOneWidget);
    });

    testWidgets('App flushes debounced save on lifecycle paused', (WidgetTester tester) async {
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);
      final animeProvider = AnimeProvider(storage: storage);
      final themeProvider = ThemeProvider(storage);
      final localeProvider = LocaleProvider(storage);
      await localeProvider.setLocale('zh');

      final rec = AnimeRecord.createEmpty().copyWith(titleZh: '生命周期测试番剧');
      await animeProvider.addRecord(rec);

      await tester.pumpWidget(
        AnimeRecordApp(
          animeProvider: animeProvider,
          themeProvider: themeProvider,
          localeProvider: localeProvider,
        ),
      );
      await tester.pumpAndSettle();

      // 触发 +1 集（带 300ms 写入防抖）
      await animeProvider.episodePlusOne(rec.id, debounce: true);
      expect(animeProvider.hasPendingSave, isTrue);

      // 模拟系统后台暂停事件
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      // 验证防抖计时器已立即刷写落盘
      expect(animeProvider.hasPendingSave, isFalse);
    });
  });
}
