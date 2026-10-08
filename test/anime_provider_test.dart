import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_record/models/anime_record.dart';
import 'package:anime_record/models/app_constants.dart';
import 'package:anime_record/services/storage_service.dart';
import 'package:anime_record/state/anime_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;
  late AnimeProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storageService = StorageService(prefs);
    provider = AnimeProvider(storage: storageService);
  });

  group('AnimeProvider CRUD & In-Memory Operations', () {
    test('addRecord inserts new record and triggers optimistic update', () async {
      final record = AnimeRecord.createEmpty().copyWith(
        titleZh: '葬送的芙莉莲',
        status: AnimeStatus.watching,
      );

      final created = await provider.addRecord(record);
      expect(created, isNotNull);
      expect(provider.allRecords.length, equals(1));
      expect(provider.allRecords.first.titleZh, equals('葬送的芙莉莲'));
      expect(provider.totalRecordsCount, equals(1));
    });

    test('updateRecord modifies existing item without duplicate reload', () async {
      final record = AnimeRecord.createEmpty().copyWith(titleZh: '初始标题');
      final created = await provider.addRecord(record);

      final updated = await provider.updateRecord(
        created!.id,
        created.copyWith(titleZh: '修改后标题', rating: 9.0),
      );

      expect(updated, isNotNull);
      expect(provider.allRecords.first.titleZh, equals('修改后标题'));
      expect(provider.allRecords.first.rating, equals(9.0));
    });

    test('deleteRecord removes item and updates count', () async {
      final record = AnimeRecord.createEmpty().copyWith(titleZh: '待删除番剧');
      final created = await provider.addRecord(record);
      expect(provider.allRecords.length, equals(1));

      final success = await provider.deleteRecord(created!.id);
      expect(success, isTrue);
      expect(provider.allRecords.isEmpty, isTrue);
      expect(provider.totalRecordsCount, equals(0));
    });
  });

  group('AnimeProvider episodePlusOne & State Transitions', () {
    test('want_to_watch transitions to watching on episode +1', () async {
      final record = AnimeRecord.createEmpty().copyWith(
        titleZh: '想看番剧',
        status: AnimeStatus.wantToWatch,
        episodesWatched: 0,
        episodesTotal: 12,
      );
      final created = await provider.addRecord(record);

      final res = await provider.episodePlusOne(created!.id);
      expect(res.record, isNotNull);
      expect(res.record!.episodesWatched, equals(1));
      expect(res.record!.status, equals(AnimeStatus.watching));
      expect(res.statusChangedMessage, contains('状态已切换为「在看」'));
    });

    test('on_hold transitions to watching on episode +1', () async {
      final record = AnimeRecord.createEmpty().copyWith(
        titleZh: '搁置番剧',
        status: AnimeStatus.onHold,
        episodesWatched: 3,
        episodesTotal: 12,
      );
      final created = await provider.addRecord(record);

      final res = await provider.episodePlusOne(created!.id);
      expect(res.record!.status, equals(AnimeStatus.watching));
    });

    test('reaching total episodes transitions to watched and populates endDate', () async {
      final record = AnimeRecord.createEmpty().copyWith(
        titleZh: '快看完的番剧',
        status: AnimeStatus.watching,
        episodesWatched: 11,
        episodesTotal: 12,
      );
      final created = await provider.addRecord(record);

      final res = await provider.episodePlusOne(created!.id);
      expect(res.record!.episodesWatched, equals(12));
      expect(res.record!.status, equals(AnimeStatus.watched));
      expect(res.record!.endDate.isNotEmpty, isTrue);
      expect(res.statusChangedMessage, contains('已追完'));
    });
  });

  group('AnimeProvider Filtering, Searching & Memoization', () {
    setUp(() async {
      final records = [
        AnimeRecord.createEmpty().copyWith(
          titleZh: '葬送的芙莉莲',
          titleJa: 'Sousou no Frieren',
          status: AnimeStatus.watching,
          week: WeekDay.fri,
          tags: ['奇幻', '冒险'],
          episodesWatched: 10,
          episodesTotal: 28,
        ),
        AnimeRecord.createEmpty().copyWith(
          titleZh: '鬼灭之刃 柱训练篇',
          titleJa: 'Kimetsu no Yaiba',
          status: AnimeStatus.wantToWatch,
          week: WeekDay.sun,
          tags: ['热血', '战斗'],
          episodesWatched: 0,
          episodesTotal: 8,
        ),
        AnimeRecord.createEmpty().copyWith(
          titleZh: '间谍过家家',
          titleJa: 'SPY x FAMILY',
          status: AnimeStatus.watched,
          tags: ['搞笑', '日常'],
          notes: '阿尼亚很可爱',
          episodesWatched: 25,
          episodesTotal: 25,
        ),
      ];

      for (final r in records) {
        await provider.addRecord(r);
      }
    });

    test('status filter returns matching subset', () {
      provider.setStatusFilter(AnimeStatus.watching);
      expect(provider.filteredRecords.length, equals(1));
      expect(provider.filteredRecords.first.titleZh, equals('葬送的芙莉莲'));

      provider.setStatusFilter('all');
      expect(provider.filteredRecords.length, equals(3));
    });

    test('week filter returns correct day items', () {
      provider.setStatusFilter('all');
      provider.setWeekFilter(WeekDay.fri);
      expect(provider.filteredRecords.length, equals(1));
      expect(provider.filteredRecords.first.titleZh, equals('葬送的芙莉莲'));

      provider.setWeekFilter(WeekDay.sun);
      expect(provider.filteredRecords.length, equals(1));
      expect(provider.filteredRecords.first.titleZh, equals('鬼灭之刃 柱训练篇'));
    });

    test('search query matches across titleZh, titleJa, notes and tags', () {
      provider.setStatusFilter('all');

      // 匹配日文名
      provider.setSearchQuery('frieren');
      expect(provider.filteredRecords.length, equals(1));
      expect(provider.filteredRecords.first.titleZh, equals('葬送的芙莉莲'));

      // 匹配备注
      provider.setSearchQuery('阿尼亚');
      expect(provider.filteredRecords.length, equals(1));
      expect(provider.filteredRecords.first.titleZh, equals('间谍过家家'));

      // 匹配标签
      provider.setSearchQuery('热血');
      expect(provider.filteredRecords.length, equals(1));
      expect(provider.filteredRecords.first.titleZh, equals('鬼灭之刃 柱训练篇'));
    });
  });

  group('AnimeProvider Sorting & Reordering', () {
    test('sort by episodes left puts least remaining first', () async {
      await provider.addRecord(
        AnimeRecord.createEmpty().copyWith(titleZh: '剩8集', episodesWatched: 4, episodesTotal: 12),
      );
      await provider.addRecord(
        AnimeRecord.createEmpty().copyWith(titleZh: '剩2集', episodesWatched: 10, episodesTotal: 12),
      );

      provider.setStatusFilter('all');
      provider.setSortBy(SortOption.episodesLeft);

      expect(provider.filteredRecords.first.titleZh, equals('剩2集'));
      expect(provider.filteredRecords.last.titleZh, equals('剩8集'));
    });

    test('reorder swaps positions correctly', () async {
      await provider.addRecord(AnimeRecord.createEmpty().copyWith(titleZh: 'A'));
      await provider.addRecord(AnimeRecord.createEmpty().copyWith(titleZh: 'B'));

      provider.setStatusFilter('all');
      expect(provider.pagedRecords.first.titleZh, equals('B'));

      await provider.reorder(0, 2);
      expect(provider.pagedRecords.first.titleZh, equals('A'));
      expect(provider.pagedRecords.last.titleZh, equals('B'));
    });
  });

  group('AnimeProvider Import & Overviews', () {
    test('importRecords with replace=false deduplicates by title', () async {
      await provider.addRecord(AnimeRecord.createEmpty().copyWith(titleZh: '现有番剧'));

      final incoming = [
        AnimeRecord.createEmpty().copyWith(titleZh: '现有番剧'),
        AnimeRecord.createEmpty().copyWith(titleZh: '全新番剧'),
      ];

      final ok = await provider.importRecords(incoming, replace: false);
      expect(ok, isTrue);
      expect(provider.allRecords.length, equals(2));
      expect(provider.allRecords.any((r) => r.titleZh == '全新番剧'), isTrue);
    });

    test('overview calculations correctly sum stats', () async {
      await provider.addRecord(
        AnimeRecord.createEmpty().copyWith(
          status: AnimeStatus.watching,
          week: WeekDay.mon,
          episodesWatched: 5,
        ),
      );
      await provider.addRecord(
        AnimeRecord.createEmpty().copyWith(
          status: AnimeStatus.watched,
          week: WeekDay.mon,
          episodesWatched: 12,
        ),
      );

      expect(provider.totalEpisodesWatched, equals(17));
      expect(provider.statusCounts[AnimeStatus.watching], equals(1));
      expect(provider.statusCounts[AnimeStatus.watched], equals(1));
      expect(provider.activeWeekCounts[WeekDay.mon], equals(2));
    });
  });
}
