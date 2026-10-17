import 'dart:convert';
import 'package:anime_record/models/anime_record.dart';
import 'package:anime_record/models/app_constants.dart';
import 'package:anime_record/services/import_export_service.dart';
import 'package:anime_record/services/storage_service.dart';
import 'package:anime_record/services/sync_service.dart';
import 'package:anime_record/state/anime_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Anime Full Lifecycle End-to-End Integration Tests', () {
    test(
      'complete lifecycle: create -> episode plus one -> auto transition -> export -> corruption self-heal -> gist merge',
      () async {
        // 1. 初始化持久化与状态机
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final storage = StorageService(prefs);
        final provider = AnimeProvider(storage: storage);

        expect(provider.allRecords, isEmpty);

        // 2. 新增一部在看状态的新番
        final initialAnime = AnimeRecord.createEmpty().copyWith(
          titleZh: '孤独摇滚！',
          titleJa: 'Bocchi the Rock!',
          status: AnimeStatus.watching,
          week: WeekDay.sun,
          episodesWatched: 11,
          episodesTotal: 12,
          rating: 9.8,
          tags: ['音乐', '日常', '芳文社'],
        );

        final created = await provider.addRecord(initialAnime);
        expect(created, isNotNull);
        expect(provider.totalRecordsCount, equals(1));
        expect(provider.allRecords.first.titleZh, equals('孤独摇滚！'));

        // 3. 快捷更新集数至最后一集，验证状态自动流转为「已看」
        final result = await provider.episodePlusOne(created!.id);
        expect(result.record, isNotNull);
        expect(result.record!.episodesWatched, equals(12));
        expect(result.record!.status, equals(AnimeStatus.watched));
        expect(result.record!.endDate.isNotEmpty, isTrue);
        expect(result.statusChangedMessage, contains('已追完'));

        // 刷写防抖持久化
        await provider.flushPendingSaves();
        final storedList = storage.loadRecords();
        expect(storedList.first.status, equals(AnimeStatus.watched));
        expect(storedList.first.episodesWatched, equals(12));

        // 4. 导出本地数据为备份 JSON 快照（验证后台 Isolate 异步解析）
        final exportedJson = await ImportExportService.exportToJsonAsync(provider.allRecords);
        expect(exportedJson.isNotEmpty, isTrue);

        final parsedBack = await ImportExportService.parseImportJsonAsync(exportedJson);
        expect(parsedBack.length, equals(1));
        expect(parsedBack.first.titleZh, equals('孤独摇滚！'));
        expect(parsedBack.first.status, equals(AnimeStatus.watched));

        // 5. 模拟主存储数据严重损坏（格式错误损坏主 key）
        await prefs.setString(StorageService.storageKey, '{ invalid json corrupted !');

        // 通过 StorageService 触发自愈机制，成功从上一份安全备份快照（集数 11）恢复
        final recoveredRecords = storage.loadRecords();
        expect(recoveredRecords.length, equals(1));
        expect(recoveredRecords.first.titleZh, equals('孤独摇滚！'));
        expect(recoveredRecords.first.episodesWatched, equals(11));

        // 验证主 key 是否已自愈恢复为合法 JSON
        final repairedRaw = prefs.getString(StorageService.storageKey);
        expect(repairedRaw, isNotNull);
        expect(jsonDecode(repairedRaw!), isA<List>());

        // 6. 模拟云端智能合并（双向合并与墓碑防复活验证）
        final syncService = SyncService();
        final remoteAnime = AnimeRecord.createEmpty().copyWith(
          titleZh: '葬送的芙莉莲',
          status: AnimeStatus.watching,
          episodesWatched: 20,
          episodesTotal: 28,
        );

        // 模拟本地删除了一部旧番并产生墓碑
        const tombstonedId = 'deleted-old-anime-id';
        await storage.recordDeletedTombstone(tombstonedId);

        // 云端带有该已被本地删除的旧番（更新时间早于删除时间）与一部新番
        final pastTime = DateTime.now().subtract(const Duration(hours: 2)).toIso8601String();
        final remoteRecords = [
          remoteAnime,
          AnimeRecord.createEmpty().copyWith(
            id: tombstonedId,
            titleZh: '已被本地删除的云端旧番',
            createdAt: pastTime,
            updatedAt: pastTime,
          ),
        ];

        final mergeResult = syncService.mergeSyncRecords(
          provider.allRecords,
          remoteRecords,
          storage.getTombstones(),
          {},
        );

        // 验证墓碑番剧被成功拦截防复活，且本地与远端有效记录成功合并
        expect(mergeResult.mergedRecords.any((r) => r.id == tombstonedId), isFalse);
        expect(mergeResult.mergedRecords.length, equals(2));
        expect(
          mergeResult.mergedRecords.map((r) => r.titleZh).toSet(),
          containsAll(['孤独摇滚！', '葬送的芙莉莲']),
        );

        // 7. 导入合并结果至 Provider
        await provider.importRecords(mergeResult.mergedRecords, replace: true);
        expect(provider.totalRecordsCount, equals(2));
        expect(provider.statusCounts[AnimeStatus.watched], equals(1));
        expect(provider.statusCounts[AnimeStatus.watching], equals(1));

        // 8. 验证生命周期结束与销毁
        provider.dispose();
      },
    );
  });
}
