import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anime_record/l10n/l10n.dart';

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
    });
  });
}
