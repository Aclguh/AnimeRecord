import 'package:anime_record/models/anime_record.dart';
import 'package:anime_record/models/sync_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncConfig Model Tests', () {
    test('default constructor initializes with empty and false values', () {
      const config = SyncConfig();
      expect(config.token, isEmpty);
      expect(config.gistId, isEmpty);
      expect(config.autoSync, isFalse);
      expect(config.lastSyncTime, isEmpty);
      expect(config.isConfigured, isFalse);
    });

    test('isConfigured returns true only when both token and gistId are non-empty', () {
      expect(const SyncConfig(token: 'abc', gistId: '').isConfigured, isFalse);
      expect(const SyncConfig(token: '  ', gistId: 'xyz').isConfigured, isFalse);
      expect(const SyncConfig(token: 'abc', gistId: 'xyz').isConfigured, isTrue);
    });

    test('copyWith updates specified fields only', () {
      const initial = SyncConfig(token: 'tok1', gistId: 'g1', autoSync: false);
      final updated = initial.copyWith(
        token: 'tok2',
        autoSync: true,
        lastSyncTime: '2026-01-01',
      );

      expect(updated.token, 'tok2');
      expect(updated.gistId, 'g1');
      expect(updated.autoSync, isTrue);
      expect(updated.lastSyncTime, '2026-01-01');
    });

    test('toJson and fromJson serialize and deserialize correctly', () {
      const config = SyncConfig(
        token: 'test_token',
        gistId: 'test_gist',
        autoSync: true,
        lastSyncTime: '2026-10-26T12:00:00Z',
      );

      final json = config.toJson();
      final restored = SyncConfig.fromJson(json);

      expect(restored, equals(config));
      expect(restored.hashCode, equals(config.hashCode));
    });

    test('fromJson handles null or missing keys safely', () {
      final config = SyncConfig.fromJson({});
      expect(config.token, isEmpty);
      expect(config.gistId, isEmpty);
      expect(config.autoSync, isFalse);
      expect(config.lastSyncTime, isEmpty);
    });

    test('equality and hashCode compare field values', () {
      const c1 = SyncConfig(token: 't', gistId: 'g', autoSync: true, lastSyncTime: 'now');
      const c2 = SyncConfig(token: 't', gistId: 'g', autoSync: true, lastSyncTime: 'now');
      const c3 = SyncConfig(token: 'diff', gistId: 'g', autoSync: true, lastSyncTime: 'now');

      expect(c1 == c2, isTrue);
      expect(c1 == c3, isFalse);
      expect(c1.hashCode == c2.hashCode, isTrue);
    });
  });

  group('SyncMergeResult Model Tests', () {
    test('instantiates and preserves properties', () {
      final dummyRecord = AnimeRecord.createEmpty().copyWith(id: 'r1', titleZh: '测试');
      final result = SyncMergeResult(
        mergedRecords: [dummyRecord],
        mergedTombstones: {'del1': '2026-01-01'},
        hasChanges: true,
        pulledCount: 1,
        pushedCount: 2,
      );

      expect(result.mergedRecords.length, 1);
      expect(result.mergedTombstones['del1'], '2026-01-01');
      expect(result.hasChanges, isTrue);
      expect(result.pulledCount, 1);
      expect(result.pushedCount, 2);
    });
  });
}
