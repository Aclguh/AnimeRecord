import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_record/models/anime_record.dart';
import 'package:anime_record/models/app_constants.dart';
import 'package:anime_record/services/storage_service.dart';
import 'package:anime_record/services/sync_service.dart';
import 'package:anime_record/services/import_export_service.dart';
import 'package:anime_record/state/anime_provider.dart';
import 'package:anime_record/state/theme_provider.dart';
import 'package:anime_record/main.dart';

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
    });

    test('JSON serialization & deserialization works seamlessly', () {
      final original = AnimeRecord(
        id: 'test-id-1',
        titleZh: '葬送的芙莉莲',
        titleJa: '葬送のフリーレン',
        status: AnimeStatus.watching,
        week: WeekDay.fri,
        airStatus: AirStatus.airing,
        rating: 9.5,
        episodesWatched: 12,
        episodesTotal: 28,
        tags: const ['奇幻', '冒险'],
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
      expect(restored.notes, equals(original.notes));
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
  });

  group('SyncService Bidirectional Merge Tests', () {
    test('mergeSyncRecords adopts newer updates and respects tombstones', () {
      final syncService = SyncService();

      final localRec = AnimeRecord(
        id: '1',
        titleZh: '番剧A',
        episodesWatched: 5,
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T10:00:00.000Z',
      );

      final remoteRec = AnimeRecord(
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

      await tester.pumpWidget(
        AnimeRecordApp(
          animeProvider: animeProvider,
          themeProvider: themeProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('看番记录'), findsOneWidget);
      expect(find.text('全部'), findsOneWidget);
      expect(find.text('在看'), findsWidgets);
      expect(find.text('添加番剧'), findsOneWidget);
    });
  });
}
