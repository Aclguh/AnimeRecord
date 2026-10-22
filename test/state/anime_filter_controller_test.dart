import 'package:anime_record/models/anime_record.dart';
import 'package:anime_record/models/app_constants.dart';
import 'package:anime_record/state/anime_filter_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnimeFilterController Tests', () {
    late AnimeFilterController controller;

    setUp(() {
      controller = AnimeFilterController();
    });

    test('initial state defaults correctly', () {
      expect(controller.activeStatus, equals(AnimeStatus.watchingValue));
      expect(controller.activeWeek, isEmpty);
      expect(controller.searchQuery, isEmpty);
      expect(controller.sortBy, equals(SortOption.defaultSort));
      expect(controller.currentPage, equals(1));
    });

    test('setStatusFilter resets activeWeek and page', () {
      controller.setWeekFilter('mon');
      controller.setStatusFilter(AnimeStatus.watchedValue);

      expect(controller.activeStatus, equals(AnimeStatus.watchedValue));
      expect(controller.activeWeek, isEmpty);
      expect(controller.currentPage, equals(1));
    });

    test('setWeekFilter updates week and resets page', () {
      controller.setWeekFilter('tue');
      expect(controller.activeWeek, equals('tue'));
      expect(controller.currentPage, equals(1));
    });

    test('setSearchQuery updates query and resets page', () {
      controller.setSearchQuery('芙莉莲');
      expect(controller.searchQuery, equals('芙莉莲'));
      expect(controller.currentPage, equals(1));
    });

    test('setSortBy updates sort and resets page', () {
      controller.setSortBy(SortOption.dateAddedDesc);
      expect(controller.sortBy, equals(SortOption.dateAddedDesc));
      expect(controller.currentPage, equals(1));
    });

    test('filterAndSort applies multi-field search and status filtering', () {
      final records = [
        AnimeRecord.createEmpty().copyWith(
          id: '1',
          titleZh: '葬送的芙莉莲',
          titleJa: 'Sousou no Frieren',
          status: AnimeStatus.watching,
          week: 'fri',
          tags: ['奇幻'],
        ),
        AnimeRecord.createEmpty().copyWith(
          id: '2',
          titleZh: '鬼灭之刃',
          titleJa: 'Kimetsu no Yaiba',
          status: AnimeStatus.watched,
          week: 'sun',
          notes: '热血神作',
        ),
        AnimeRecord.createEmpty().copyWith(
          id: '3',
          titleZh: '迷宫饭',
          status: AnimeStatus.watching,
          week: 'thu',
          notes: '料理魔物',
        ),
      ];

      // 默认 watching 筛选
      var filtered = controller.filterAndSort(records);
      expect(filtered.length, equals(2));
      expect(filtered.map((r) => r.id), containsAll(['1', '3']));

      // 搜索标签
      controller.setSearchQuery('奇幻');
      filtered = controller.filterAndSort(records);
      expect(filtered.length, equals(1));
      expect(filtered.first.id, equals('1'));

      // 搜索备注
      controller.setSearchQuery('料理');
      filtered = controller.filterAndSort(records);
      expect(filtered.length, equals(1));
      expect(filtered.first.id, equals('3'));

      // 搜索日文标题
      controller.setStatusFilter(AnimeStatus.allValue);
      controller.setSearchQuery('Kimetsu');
      filtered = controller.filterAndSort(records);
      expect(filtered.length, equals(1));
      expect(filtered.first.id, equals('2'));
    });

    test('sortRecords orders properly by date, title, episodes left, and status default', () {
      final recA = AnimeRecord.createEmpty().copyWith(
        id: 'A',
        titleZh: 'AAA',
        createdAt: '2023-01-01T00:00:00.000Z',
        episodesWatched: 1,
        episodesTotal: 10, // 9 left
        status: AnimeStatus.watched,
      );
      final recB = AnimeRecord.createEmpty().copyWith(
        id: 'B',
        titleZh: 'BBB',
        createdAt: '2023-02-01T00:00:00.000Z',
        episodesWatched: 5,
        episodesTotal: 6, // 1 left
        status: AnimeStatus.watching,
      );

      // 日期升序
      var sorted = AnimeFilterController.sortRecords([recA, recB], SortOption.dateAddedAsc);
      expect(sorted.first.id, equals('A'));

      // 日期降序
      sorted = AnimeFilterController.sortRecords([recA, recB], SortOption.dateAddedDesc);
      expect(sorted.first.id, equals('B'));

      // 标题升序 / 降序
      sorted = AnimeFilterController.sortRecords([recA, recB], SortOption.titleZhAsc);
      expect(sorted.first.id, equals('A'));
      sorted = AnimeFilterController.sortRecords([recA, recB], SortOption.titleZhDesc);
      expect(sorted.first.id, equals('B'));

      // 剩余集数最少优先
      sorted = AnimeFilterController.sortRecords([recA, recB], SortOption.episodesLeft);
      expect(sorted.first.id, equals('B')); // 1 left < 9 left

      // 默认排序：watching 优先级高于 watched
      sorted = AnimeFilterController.sortRecords([recA, recB], SortOption.defaultSort);
      expect(sorted.first.id, equals('B'));
    });

    test('pagination and loadMore operates correctly', () {
      final manyRecords = List.generate(
        35,
        (i) => AnimeRecord.createEmpty().copyWith(
          id: 'rec_$i',
          titleZh: '番剧 $i',
          status: AnimeStatus.watching,
        ),
      );

      var paged = controller.getPaged(manyRecords);
      expect(paged.length, equals(AnimeFilterController.pageSize)); // 20
      expect(controller.hasMore(manyRecords), isTrue);

      final loaded = controller.loadMore(manyRecords.length);
      expect(loaded, isTrue);
      expect(controller.currentPage, equals(2));

      paged = controller.getPaged(manyRecords);
      expect(paged.length, equals(35));
      expect(controller.hasMore(manyRecords), isFalse);

      final noMore = controller.loadMore(manyRecords.length);
      expect(noMore, isFalse);
    });

    test('computeStatusCounts sums all 5 statuses', () {
      final records = [
        AnimeRecord.createEmpty().copyWith(status: AnimeStatus.watching),
        AnimeRecord.createEmpty().copyWith(status: AnimeStatus.watching),
        AnimeRecord.createEmpty().copyWith(status: AnimeStatus.watched),
        AnimeRecord.createEmpty().copyWith(status: AnimeStatus.wantToWatch),
      ];

      final counts = AnimeFilterController.computeStatusCounts(records);
      expect(counts[AnimeStatus.watchingValue], equals(2));
      expect(counts[AnimeStatus.watchedValue], equals(1));
      expect(counts[AnimeStatus.wantToWatchValue], equals(1));
      expect(counts[AnimeStatus.onHoldValue], equals(0));
      expect(counts[AnimeStatus.droppedValue], equals(0));
    });
  });
}
