import 'package:anime_record/services/storage_service.dart';
import 'package:anime_record/state/anime_provider.dart';
import 'package:anime_record/state/anime_scope.dart';
import 'package:anime_record/state/locale_provider.dart';
import 'package:anime_record/state/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late AnimeProvider animeProvider;
  late ThemeProvider themeProvider;
  late LocaleProvider localeProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = StorageService(prefs);
    animeProvider = AnimeProvider(storage: storage);
    themeProvider = ThemeProvider(storage);
    localeProvider = LocaleProvider(storage);
  });

  group('AnimeScope Widget Tests', () {
    testWidgets('maybeOf returns null when no AnimeScope is present', (tester) async {
      AnimeScope? resolved;

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            resolved = AnimeScope.maybeOf(context);
            return const Placeholder();
          },
        ),
      );

      expect(resolved, isNull);
    });

    testWidgets('of and context extensions correctly resolve providers', (tester) async {
      late AnimeProvider resolvedAnime;
      late ThemeProvider resolvedTheme;
      late LocaleProvider resolvedLocale;

      await tester.pumpWidget(
        AnimeScope(
          animeProvider: animeProvider,
          themeProvider: themeProvider,
          localeProvider: localeProvider,
          child: Builder(
            builder: (context) {
              resolvedAnime = context.animeProvider;
              resolvedTheme = context.themeProvider;
              resolvedLocale = context.localeProvider;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(resolvedAnime, same(animeProvider));
      expect(resolvedTheme, same(themeProvider));
      expect(resolvedLocale, same(localeProvider));
      expect(AnimeScope.animeOf(tester.element(find.byType(SizedBox))), same(animeProvider));
      expect(AnimeScope.themeOf(tester.element(find.byType(SizedBox))), same(themeProvider));
      expect(AnimeScope.localeOf(tester.element(find.byType(SizedBox))), same(localeProvider));
    });

    testWidgets('updateShouldNotify correctly detects provider reference change', (tester) async {
      final scope1 = AnimeScope(
        animeProvider: animeProvider,
        themeProvider: themeProvider,
        localeProvider: localeProvider,
        child: const SizedBox(),
      );

      final scopeSame = AnimeScope(
        animeProvider: animeProvider,
        themeProvider: themeProvider,
        localeProvider: localeProvider,
        child: const SizedBox(),
      );

      expect(scopeSame.updateShouldNotify(scope1), isFalse);

      final newAnimeProvider = AnimeProvider(storage: storage);
      final scopeDiffAnime = AnimeScope(
        animeProvider: newAnimeProvider,
        themeProvider: themeProvider,
        localeProvider: localeProvider,
        child: const SizedBox(),
      );
      expect(scopeDiffAnime.updateShouldNotify(scope1), isTrue);

      final newThemeProvider = ThemeProvider(storage);
      final scopeDiffTheme = AnimeScope(
        animeProvider: animeProvider,
        themeProvider: newThemeProvider,
        localeProvider: localeProvider,
        child: const SizedBox(),
      );
      expect(scopeDiffTheme.updateShouldNotify(scope1), isTrue);

      final newLocaleProvider = LocaleProvider(storage);
      final scopeDiffLocale = AnimeScope(
        animeProvider: animeProvider,
        themeProvider: themeProvider,
        localeProvider: newLocaleProvider,
        child: const SizedBox(),
      );
      expect(scopeDiffLocale.updateShouldNotify(scope1), isTrue);
    });

    testWidgets('of asserts when not found in context', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            expect(() => AnimeScope.of(context), throwsAssertionError);
            return const SizedBox();
          },
        ),
      );
    });
  });
}
