import 'package:anime_record/models/anime_record.dart';
import 'package:anime_record/models/app_constants.dart';
import 'package:anime_record/services/anime_repository.dart';
import 'package:anime_record/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late AnimeRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = StorageService(prefs);
    repository = AnimeRepository(storage: storage);
  });

  group('AnimeRepository Unit Tests', () {
    test('addRecord and deleteRecord maintains repository state', () async {
      final record = AnimeRecord.createEmpty().copyWith(
        titleZh: '物语系列',
        status: AnimeStatus.watching,
      );

      final added = await repository.addRecord(record);
      expect(added, isNotNull);
      expect(repository.records.length, equals(1));
      expect(repository.records.first.titleZh, equals('物语系列'));

      final ok = await repository.deleteRecord(added!.id);
      expect(ok, isTrue);
      expect(repository.records, isEmpty);
    });

    test('updateRecord updates fields without duplicate entries', () async {
      final record = AnimeRecord.createEmpty().copyWith(titleZh: '原标题');
      final created = await repository.addRecord(record);

      final updated = await repository.updateRecord(
        created!.id,
        created.copyWith(titleZh: '新标题', rating: 9.5),
      );

      expect(updated, isNotNull);
      expect(repository.records.first.titleZh, equals('新标题'));
      expect(repository.records.first.rating, equals(9.5));
    });

    test('episodePlusOne increments count and flushes', () async {
      final record = AnimeRecord.createEmpty().copyWith(
        titleZh: '单集测试',
        episodesWatched: 3,
        episodesTotal: 12,
        status: AnimeStatus.watching,
      );
      final created = await repository.addRecord(record);

      final res = await repository.episodePlusOne(created!.id, debounce: false);
      expect(res.record, isNotNull);
      expect(res.record!.episodesWatched, equals(4));
      expect(repository.records.first.episodesWatched, equals(4));
    });

    test('reorderPagedSubset maps subset index to full list properly', () async {
      final r1 = AnimeRecord.createEmpty().copyWith(id: '1', titleZh: 'A');
      final r2 = AnimeRecord.createEmpty().copyWith(id: '2', titleZh: 'B');
      final r3 = AnimeRecord.createEmpty().copyWith(id: '3', titleZh: 'C');

      await repository.addRecord(r3);
      await repository.addRecord(r2);
      await repository.addRecord(r1);

      // Current records: [A, B, C]
      final paged = [r1, r2, r3];
      // Drag A (index 0) to after B (target index 2)
      await repository.reorderPagedSubset(
        oldIndex: 0,
        newIndex: 2,
        currentPaged: paged,
      );

      expect(repository.records.map((r) => r.id).toList(), equals(['2', '1', '3']));
    });

    test('importRecords handles replace and deduplicate merge modes', () async {
      final r1 = AnimeRecord.createEmpty().copyWith(id: '1', titleZh: '老番');
      await repository.addRecord(r1);

      final r2 = AnimeRecord.createEmpty().copyWith(id: '2', titleZh: '老番'); // 重复
      final r3 = AnimeRecord.createEmpty().copyWith(id: '3', titleZh: '新番');

      // 增量合并
      await repository.importRecords([r2, r3], replace: false);
      expect(repository.records.length, equals(2));
      expect(repository.records.map((r) => r.id), containsAll(['1', '3']));

      // 覆盖替换
      await repository.importRecords([r3], replace: true);
      expect(repository.records.length, equals(1));
      expect(repository.records.first.id, equals('3'));
    });
  });
}
