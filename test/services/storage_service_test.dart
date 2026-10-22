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

    test('saves and loads sync config', () async {
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
    });
  });
}
