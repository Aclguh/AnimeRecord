import 'dart:convert';

import 'package:anime_record/models/anime_record.dart';
import 'package:anime_record/services/import_export_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImportExportService Tests', () {
    test('exportToJson serializes list of records correctly', () {
      final records = [
        const AnimeRecord(
          id: 'exp_1',
          titleZh: '轻音少女',
          createdAt: '2026-01-01T00:00:00.000Z',
          updatedAt: '2026-01-01T00:00:00.000Z',
        ),
      ];

      final jsonStr = ImportExportService.exportToJson(records);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(decoded['version'], 1);
      expect(decoded['totalRecords'], 1);
      expect((decoded['records'] as List).length, 1);
      expect(decoded['records'][0]['titleZh'], '轻音少女');
    });

    test('exportTemplateJson includes helpful guide fields', () {
      final templateStr = ImportExportService.exportTemplateJson();
      final decoded = jsonDecode(templateStr) as Map<String, dynamic>;

      expect(decoded['_description'], isNotNull);
      expect(decoded['_instructions'], isList);
      expect((decoded['records'] as List).length, greaterThan(0));
    });

    test('parseImportJson parses valid records and ignores meta headers', () {
      final jsonStr = jsonEncode({
        'version': 1,
        'records': [
          {'_description': '跳过说明项'},
          {'titleZh': ''}, // empty title skipped
          {
            'titleZh': 'CLANNAD',
            'episodesWatched': 24,
            'episodesTotal': 24,
          },
        ]
      });

      final parsed = ImportExportService.parseImportJson(jsonStr);
      expect(parsed.length, 1);
      expect(parsed.first.titleZh, 'CLANNAD');
    });

    test('parseImportJson throws on missing records or empty content', () {
      expect(
        () => ImportExportService.parseImportJson('{"invalid": true}'),
        throwsA(predicate((e) => e.toString().contains('缺少 records 数组'))),
      );

      expect(
        () => ImportExportService.parseImportJson('{"records": []}'),
        throwsA(predicate((e) => e.toString().contains('没有有效的番剧记录'))),
      );
    });

    test('mergeImport deduplicates against existing records', () {
      final current = [
        const AnimeRecord(
          id: 'cur_1',
          titleZh: '凉宫春日的忧郁',
          createdAt: '2026-01-01T00:00:00.000Z',
          updatedAt: '2026-01-01T00:00:00.000Z',
        ),
      ];

      final incoming = [
        const AnimeRecord(
          id: 'inc_1',
          titleZh: ' 凉宫春日的忧郁 ', // duplicate with whitespace
          createdAt: '2026-01-01T00:00:00.000Z',
          updatedAt: '2026-01-01T00:00:00.000Z',
        ),
        const AnimeRecord(
          id: 'inc_2',
          titleZh: '幸运星',
          createdAt: '2026-01-01T00:00:00.000Z',
          updatedAt: '2026-01-01T00:00:00.000Z',
        ),
      ];

      final res = ImportExportService.mergeImport(current, incoming);
      expect(res.added, 1);
      expect(res.skipped, 1);
      expect(res.records.length, 2);
      expect(res.records.any((r) => r.titleZh == '幸运星'), isTrue);
    });

    test('exportToJsonAsync and parseImportJsonAsync perform correctly in async isolate', () async {
      final records = [
        const AnimeRecord(
          id: 'iso_1',
          titleZh: '紫罗兰永恒花园',
          createdAt: '2026-01-01T00:00:00.000Z',
          updatedAt: '2026-01-01T00:00:00.000Z',
        ),
      ];

      final jsonStr = await ImportExportService.exportToJsonAsync(records);
      expect(jsonStr.contains('紫罗兰永恒花园'), isTrue);

      final parsed = await ImportExportService.parseImportJsonAsync(jsonStr);
      expect(parsed.length, 1);
      expect(parsed.first.titleZh, '紫罗兰永恒花园');
    });
  });
}
