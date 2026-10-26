import 'package:anime_record/models/anime_record.dart';
import 'package:anime_record/models/app_constants.dart';
import 'package:anime_record/models/sync_config.dart';
import 'package:anime_record/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late StorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = StorageService(prefs);
  });

  group('StorageService Core CRUD & Reorder', () {
    test('addRecord, updateRecord, and deleteRecord maintain consistency', () async {
      final initial = AnimeRecord.createEmpty().copyWith(
        titleZh: '新番剧',
        status: AnimeStatus.watching,
      );

      final added = await storage.addRecord(initial);
      expect(added, isNotNull);
      expect(storage.loadRecords().length, 1);

      final updated = await storage.updateRecord(
        added!.id,
        added.copyWith(titleZh: '更新后的标题', episodesWatched: 5),
      );
      expect(updated, isNotNull);
      expect(updated!.titleZh, '更新后的标题');
      expect(storage.loadRecords().first.titleZh, '更新后的标题');

      final deleted = await storage.deleteRecord(added.id);
      expect(deleted, isTrue);
      expect(storage.loadRecords(), isEmpty);

      // Verify tombstone is recorded on delete
      final tombstones = storage.getTombstones();
      expect(tombstones.containsKey(added.id), isTrue);

      // Clearing tombstone
      await storage.clearDeletedTombstone(added.id);
      expect(storage.getTombstones().containsKey(added.id), isFalse);
    });

    test('reorderRecords adjusts record order by visible IDs', () async {
      final r1 = AnimeRecord.createEmpty().copyWith(id: '1', titleZh: '一');
      final r2 = AnimeRecord.createEmpty().copyWith(id: '2', titleZh: '二');
      final r3 = AnimeRecord.createEmpty().copyWith(id: '3', titleZh: '三');

      await storage.saveRecords([r1, r2, r3]);

      // Reverse order: 3, 2, 1
      final ok = await storage.reorderRecords(['3', '2', '1']);
      expect(ok, isTrue);

      final reordered = storage.loadRecords();
      expect(reordered.map((r) => r.id).toList(), ['3', '2', '1']);
    });
  });

  group('StorageService Tombstone Expiration', () {
    test('cleans up tombstones older than 60 days', () async {
      final now = DateTime.now();
      final expiredDate = now.subtract(const Duration(days: 65)).toIso8601String();
      final freshDate = now.subtract(const Duration(days: 10)).toIso8601String();

      await storage.saveTombstones({
        'expired_id': expiredDate,
        'fresh_id': freshDate,
      });

      // Record a new deletion, which triggers 60-day cleanup
      await storage.recordDeletedTombstone('new_id');

      final result = storage.getTombstones();
      expect(result.containsKey('expired_id'), isFalse);
      expect(result.containsKey('fresh_id'), isTrue);
      expect(result.containsKey('new_id'), isTrue);
    });
  });

  group('StorageService Preferences & Sync Config', () {
    test('saves and loads default status with fallback', () async {
      expect(storage.loadDefaultStatus(), AnimeStatus.watchingValue);

      await storage.saveDefaultStatus(AnimeStatus.wantToWatch);
      expect(storage.loadDefaultStatus(), AnimeStatus.wantToWatch);

      await prefs.setString(StorageService.defaultStatusKey, 'invalid_status_value');
      expect(storage.loadDefaultStatus(), AnimeStatus.watchingValue);
    });

    test('saves and loads theme mode and screen rotation preference', () async {
      expect(storage.loadTheme(), 'system');
      await storage.saveTheme('dark');
      expect(storage.loadTheme(), 'dark');

      expect(storage.loadLocale(), 'system');
      await storage.saveLocale('zh');
      expect(storage.loadLocale(), 'zh');

      expect(storage.loadFollowScreenRotation(), isFalse);
      await storage.saveFollowScreenRotation(true);
      expect(storage.loadFollowScreenRotation(), isTrue);
    });

    test('saves and loads sync config with fallback obfuscation', () async {
      const config = SyncConfig(
        token: 'ghp_test_123',
        gistId: 'gist_id_abc',
        autoSync: true,
        lastSyncTime: '2026-03-01T10:00:00.000Z',
      );

      await storage.saveSyncConfig(config);
      final loaded = storage.loadSyncConfig();

      expect(loaded.token, 'ghp_test_123');
      expect(loaded.gistId, 'gist_id_abc');
      expect(loaded.autoSync, isTrue);
      expect(loaded.lastSyncTime, '2026-03-01T10:00:00.000Z');
      expect(loaded.isConfigured, isTrue);

      // 验证降级存储中未保存明文 Token
      final rawPrefsToken = prefs.getString(StorageService.syncTokenKey);
      if (rawPrefsToken != null) {
        expect(rawPrefsToken.contains('ghp_test_123'), isFalse);
        expect(rawPrefsToken.startsWith('enc:v1:'), isTrue);
      }
    });

    test('recovers from rolling backup snapshots when main storage and old backup are corrupted', () async {
      final r1 = AnimeRecord.createEmpty().copyWith(id: 'roll_1', titleZh: '第一代快照');
      final r2 = AnimeRecord.createEmpty().copyWith(id: 'roll_2', titleZh: '第二代快照');
      final r3 = AnimeRecord.createEmpty().copyWith(id: 'roll_3', titleZh: '第三代快照');

      await storage.saveRecords([r1]);
      await storage.saveRecords([r1, r2]);
      await storage.saveRecords([r1, r2, r3]);

      expect(storage.loadRecords().length, 3);

      // 故意破坏主键与单一 backupKey
      await prefs.setString(StorageService.storageKey, '{ corrupted main json }');
      await prefs.setString(StorageService.backupKey, '{ corrupted legacy backup }');

      // 从滚动快照槽位恢复
      final restored = storage.loadRecords();
      expect(restored.isNotEmpty, isTrue);
      expect(restored.any((r) => r.id == 'roll_1'), isTrue);
    });

    test('exportAllStorageData and importAllStorageData performs smooth full backup and restore', () async {
      final r1 = AnimeRecord.createEmpty().copyWith(id: 'mig_1', titleZh: '平滑迁移测试番剧');
      await storage.saveRecords([r1]);
      await storage.saveTheme('light');
      await storage.saveLocale('en');
      await storage.saveFollowScreenRotation(true);
      await storage.saveDefaultStatus(AnimeStatus.watched);
      await storage.recordDeletedTombstone('tomb_mig_1');
      await storage.saveSyncConfig(const SyncConfig(token: 'ghp_mig', gistId: 'gist_mig', autoSync: true));

      final exported = storage.exportAllStorageData();
      expect(exported['version'], equals(StorageService.dataVersion));
      expect((exported['records'] as List).length, equals(1));
      expect(exported['theme'], equals('light'));
      expect(exported['locale'], equals('en'));
      expect(exported['followScreenRotation'], isTrue);
      expect(exported['defaultStatus'], equals(AnimeStatus.watched));
      expect(exported['tombstones'], isNotNull);

      // 创建一个全新的空 storage
      SharedPreferences.setMockInitialValues({});
      final newPrefs = await SharedPreferences.getInstance();
      final newStorage = StorageService(newPrefs);
      expect(newStorage.loadRecords(), isEmpty);

      // 执行全量迁入
      await newStorage.importAllStorageData(exported);
      expect(newStorage.loadRecords().length, equals(1));
      expect(newStorage.loadRecords().first.titleZh, equals('平滑迁移测试番剧'));
      expect(newStorage.loadTheme(), equals('light'));
      expect(newStorage.loadLocale(), equals('en'));
      expect(newStorage.loadFollowScreenRotation(), isTrue);
      expect(newStorage.loadDefaultStatus(), equals(AnimeStatus.watched));
      expect(newStorage.getTombstones().containsKey('tomb_mig_1'), isTrue);
    });
  });
}
