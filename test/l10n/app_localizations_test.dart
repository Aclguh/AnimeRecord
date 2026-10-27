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

    test('exercises all parameterized methods and comprehensive getters on AppLocalizationsEn', () {
      final en = lookupAppLocalizations(const Locale('en'));

      expect(en.deleteAnimeConfirm('Title'), contains('Title'));
      expect(en.animeAddedSuccess('Title'), contains('Title'));
      expect(en.animeUpdatedSuccess('Title'), contains('Title'));
      expect(en.animeDeletedSuccess('Title'), contains('Title'));
      expect(en.statusChangedWatched('Title'), contains('Title'));
      expect(en.statusChangedWatching('Title'), contains('Title'));
      expect(en.completedEpisodes(12), contains('12'));
      expect(en.remainingEpisodes(4), contains('4'));
      expect(en.watchedEpisodes(8), contains('8'));
      expect(en.minutesAgo(5), contains('5'));
      expect(en.hoursAgo(2), contains('2'));
      expect(en.daysAgo(3), contains('3'));
      expect(en.lastModified('2026-01-01'), contains('2026-01-01'));
      expect(en.defaultOpenPageDescription('Watching'), contains('Watching'));
      expect(en.syncConnectSuccess('user', 'info'), contains('user'));
      expect(en.syncConnectFailed('err'), contains('err'));
      expect(en.gistCreateFailed('err'), contains('err'));
      expect(en.exportSuccess(10), contains('10'));
      expect(en.exportFailed('err'), contains('err'));
      expect(en.templateExportFailed('err'), contains('err'));
      expect(en.importDialogFound(5), contains('5'));
      expect(en.importDialogCurrent(8), contains('8'));
      expect(en.importReplaceSuccess(5), contains('5'));
      expect(en.importFailed('err'), contains('err'));
      expect(en.cliffMessage(10, 2), contains('10'));
      expect(en.airStatusBadgeTooltip('Airing'), contains('Airing'));
      expect(en.weekBadgeTooltip('Mon'), contains('Mon'));

      // 验证未在 smoke test 中触发的各类标题、提示、占位符
      expect(en.sortDefault, isNotEmpty);
      expect(en.sortDateAddedDesc, isNotEmpty);
      expect(en.sortDateAddedAsc, isNotEmpty);
      expect(en.sortTitleZhAsc, isNotEmpty);
      expect(en.sortTitleZhDesc, isNotEmpty);
      expect(en.sortEpisodesLeft, isNotEmpty);
      expect(en.sortRating, isNotEmpty);
      expect(en.sortEpisodes, isNotEmpty);
      expect(en.sortUpdated, isNotEmpty);
      expect(en.searchHint, isNotEmpty);
      expect(en.reorderTip, isNotEmpty);
      expect(en.finishWatching, isNotEmpty);
      expect(en.notStartedYet, isNotEmpty);
      expect(en.completed, isNotEmpty);
      expect(en.justNow, isNotEmpty);
      expect(en.titleZhHint, isNotEmpty);
      expect(en.titleZhValidation, isNotEmpty);
      expect(en.titleJaLabel, isNotEmpty);
      expect(en.titleJaHint, isNotEmpty);
      expect(en.coverUrlLabel, isNotEmpty);
      expect(en.coverUrlHint, isNotEmpty);
      expect(en.coverUrlValidation, isNotEmpty);
      expect(en.watchStatusSelectLabel, isNotEmpty);
      expect(en.airDaySelectLabel, isNotEmpty);
      expect(en.airDayNone, isNotEmpty);
      expect(en.airStatusSelectLabel, isNotEmpty);
      expect(en.airStatusNone, isNotEmpty);
      expect(en.episodesWatchedLabel, isNotEmpty);
      expect(en.episodesTotalLabel, isNotEmpty);
      expect(en.episodesTotalHint, isNotEmpty);
      expect(en.ratingLabel, isNotEmpty);
      expect(en.ratingHint, isNotEmpty);
      expect(en.tagsLabel, isNotEmpty);
      expect(en.notesLabel, isNotEmpty);
      expect(en.notesHint, isNotEmpty);
      expect(en.advancedOptions, isNotEmpty);
      expect(en.unnamedAnime, isNotEmpty);
      expect(en.notes, isNotEmpty);
      expect(en.rating, isNotEmpty);
      expect(en.episodes, isNotEmpty);
      expect(en.weekLabel, isNotEmpty);
      expect(en.airStatusLabel, isNotEmpty);
      expect(en.airStatusUpcoming, isNotEmpty);
      expect(en.weekTue, isNotEmpty);
      expect(en.weekWed, isNotEmpty);
      expect(en.weekThu, isNotEmpty);
      expect(en.weekFri, isNotEmpty);
      expect(en.weekSat, isNotEmpty);
      expect(en.followScreenRotation, isNotEmpty);
      expect(en.generalSettings, isNotEmpty);
      expect(en.cloudSync, isNotEmpty);
      expect(en.localDataManagement, isNotEmpty);
      expect(en.downloadTemplate, isNotEmpty);
      expect(en.testConnection, isNotEmpty);
      expect(en.autoCreateGist, isNotEmpty);
      expect(en.lastSync, isNotEmpty);
      expect(en.neverSynced, isNotEmpty);
      expect(en.saveConfig, isNotEmpty);
      expect(en.syncNow, isNotEmpty);
      expect(en.deleteConfirmTitle, isNotEmpty);
      expect(en.deleteConfirmMessage, isNotEmpty);
      expect(en.syncConnected, isNotEmpty);
      expect(en.syncNotConfigured, isNotEmpty);
      expect(en.copyTokenCreateLink, isNotEmpty);
      expect(en.tokenCopied, isNotEmpty);
      expect(en.tokenPermissionHint, isNotEmpty);
      expect(en.gistIdHint, isNotEmpty);
      expect(en.autoSyncOnStartup, isNotEmpty);
      expect(en.syncSafetyHint, isNotEmpty);
      expect(en.localDataHint, isNotEmpty);
      expect(en.displaySettings, isNotEmpty);
      expect(en.interfaceLanguage, isNotEmpty);
      expect(en.interfaceLanguageSubtitle, isNotEmpty);
      expect(en.followSystem, isNotEmpty);
      expect(en.followScreenRotationSubtitle, isNotEmpty);
      expect(en.syncConfigSaved, isNotEmpty);
      expect(en.syncTokenRequired, isNotEmpty);
      expect(en.gistCreatedSuccess, isNotEmpty);
      expect(en.templateExportSuccess, isNotEmpty);
      expect(en.importDialogTitle, isNotEmpty);
      expect(en.importDialogSelectMode, isNotEmpty);
      expect(en.importMerge, isNotEmpty);
      expect(en.importReplace, isNotEmpty);
      expect(en.importMergeSuccess, isNotEmpty);
      expect(en.importSaveFailed, isNotEmpty);
      expect(en.cliffTitle, isNotEmpty);
      expect(en.cliffForceSync, isNotEmpty);
      expect(en.switchToLightTheme, isNotEmpty);
      expect(en.switchToDarkTheme, isNotEmpty);
      expect(en.reorderModeDone, isNotEmpty);
      expect(en.reorderModeStart, isNotEmpty);
    });

    test('exercises all parameterized methods and comprehensive getters on AppLocalizationsZh', () {
      final zh = lookupAppLocalizations(const Locale('zh'));

      expect(zh.deleteAnimeConfirm('标题'), contains('标题'));
      expect(zh.animeAddedSuccess('标题'), contains('标题'));
      expect(zh.animeUpdatedSuccess('标题'), contains('标题'));
      expect(zh.animeDeletedSuccess('标题'), contains('标题'));
      expect(zh.statusChangedWatched('标题'), contains('标题'));
      expect(zh.statusChangedWatching('标题'), contains('标题'));
      expect(zh.completedEpisodes(12), contains('12'));
      expect(zh.remainingEpisodes(4), contains('4'));
      expect(zh.watchedEpisodes(8), contains('8'));
      expect(zh.minutesAgo(5), contains('5'));
      expect(zh.hoursAgo(2), contains('2'));
      expect(zh.daysAgo(3), contains('3'));
      expect(zh.lastModified('2026-01-01'), contains('2026-01-01'));
      expect(zh.defaultOpenPageDescription('在看'), contains('在看'));
      expect(zh.syncConnectSuccess('user', 'info'), contains('user'));
      expect(zh.syncConnectFailed('err'), contains('err'));
      expect(zh.gistCreateFailed('err'), contains('err'));
      expect(zh.exportSuccess(10), contains('10'));
      expect(zh.exportFailed('err'), contains('err'));
      expect(zh.templateExportFailed('err'), contains('err'));
      expect(zh.importDialogFound(5), contains('5'));
      expect(zh.importDialogCurrent(8), contains('8'));
      expect(zh.importReplaceSuccess(5), contains('5'));
      expect(zh.importFailed('err'), contains('err'));
      expect(zh.cliffMessage(10, 2), contains('10'));
      expect(zh.airStatusBadgeTooltip('连载中'), contains('连载中'));
      expect(zh.weekBadgeTooltip('周一'), contains('周一'));
      expect(zh.switchToLightTheme, isNotEmpty);
      expect(zh.switchToDarkTheme, isNotEmpty);
      expect(zh.reorderModeDone, isNotEmpty);
      expect(zh.reorderModeStart, isNotEmpty);
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
