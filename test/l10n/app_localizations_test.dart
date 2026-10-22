import 'package:anime_record/l10n/l10n.dart';
import 'package:anime_record/models/anime_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLocalizations Multi-language Verification', () {
    testWidgets('loads and resolves Chinese (zh) localization correctly', (tester) async {
      late AppLocalizations l10n;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = context.l10n;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(l10n.appTitle, equals('看番记录'));
      expect(l10n.addAnime, equals('添加番剧'));
      expect(l10n.statusWantToWatch, equals('想看'));
      expect(l10n.statusWatching, equals('在看'));
      expect(l10n.statusWatched, equals('看过'));
      expect(l10n.statusOnHold, equals('搁置'));
      expect(l10n.statusDropped, equals('抛弃'));
      expect(l10n.sync, equals('同步'));
      expect(l10n.settings, equals('设置'));
      expect(l10n.totalRecords, equals('共收录'));
      expect(l10n.episodesWatched, equals('集已观看'));
      expect(l10n.cancel, equals('取消'));
      expect(l10n.confirm, equals('确认'));
      expect(l10n.weekMon, equals('周一'));
      expect(l10n.weekSun, equals('周日'));
      expect(l10n.airStatusAiring, equals('连载中'));
      expect(l10n.airStatusFinished, equals('已完结'));
      expect(l10n.exportData, equals('导出数据'));
      expect(l10n.importData, equals('导入数据'));
      expect(l10n.emptyStateTitle, equals('暂无番剧记录'));
    });

    testWidgets('loads and resolves English (en) localization correctly', (tester) async {
      late AppLocalizations l10n;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = context.l10n;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(l10n.appTitle, equals('Anime Record'));
      expect(l10n.addAnime, equals('Add Anime'));
      expect(l10n.statusWantToWatch, equals('Plan to Watch'));
      expect(l10n.statusWatching, equals('Watching'));
      expect(l10n.statusWatched, equals('Completed'));
      expect(l10n.statusOnHold, equals('On Hold'));
      expect(l10n.statusDropped, equals('Dropped'));
      expect(l10n.sync, equals('Sync'));
      expect(l10n.settings, equals('Settings'));
      expect(l10n.totalRecords, equals('Total'));
      expect(l10n.episodesWatched, equals('eps watched'));
      expect(l10n.cancel, equals('Cancel'));
      expect(l10n.confirm, equals('Confirm'));
      expect(l10n.weekMon, equals('Mon'));
      expect(l10n.weekSun, equals('Sun'));
      expect(l10n.airStatusAiring, equals('Airing'));
      expect(l10n.airStatusFinished, equals('Finished'));
      expect(l10n.exportData, equals('Export Data'));
      expect(l10n.importData, equals('Import Data'));
      expect(l10n.emptyStateTitle, equals('No Anime Records Yet'));
    });

    test('AnimeRecord formatRelativeUpdatedAt formats relative time in zh and en', () {
      final now = DateTime.now();
      final tenMinutesAgo = now.subtract(const Duration(minutes: 10)).toIso8601String();
      final twoHoursAgo = now.subtract(const Duration(hours: 2)).toIso8601String();
      final twoDaysAgo = now.subtract(const Duration(days: 2)).toIso8601String();

      final rec10m = AnimeRecord.createEmpty().copyWith(updatedAt: tenMinutesAgo);
      expect(rec10m.formatRelativeUpdatedAt(locale: 'zh'), '10分钟前');
      expect(rec10m.formatRelativeUpdatedAt(locale: 'en'), '10m ago');

      final rec2h = AnimeRecord.createEmpty().copyWith(updatedAt: twoHoursAgo);
      expect(rec2h.formatRelativeUpdatedAt(locale: 'zh'), '2小时前');
      expect(rec2h.formatRelativeUpdatedAt(locale: 'en'), '2h ago');

      final rec2d = AnimeRecord.createEmpty().copyWith(updatedAt: twoDaysAgo);
      expect(rec2d.formatRelativeUpdatedAt(locale: 'zh'), '2天前');
      expect(rec2d.formatRelativeUpdatedAt(locale: 'en'), '2d ago');
    });
  });
}
