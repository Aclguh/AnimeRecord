import 'package:anime_record/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnimeThemeColors Tests', () {
    test('light and dark constants have defined colors', () {
      expect(AnimeThemeColors.light.wantToWatch, isNotNull);
      expect(AnimeThemeColors.light.watching, isNotNull);
      expect(AnimeThemeColors.light.watched, isNotNull);
      expect(AnimeThemeColors.light.onHold, isNotNull);
      expect(AnimeThemeColors.light.dropped, isNotNull);

      expect(AnimeThemeColors.dark.wantToWatch, isNotNull);
      expect(AnimeThemeColors.dark.watching, isNotNull);
      expect(AnimeThemeColors.dark.watched, isNotNull);
      expect(AnimeThemeColors.dark.onHold, isNotNull);
      expect(AnimeThemeColors.dark.dropped, isNotNull);
    });

    test('copyWith modifies only provided colors', () {
      const original = AnimeThemeColors.light;
      final modified = original.copyWith(
        wantToWatch: const Color(0xFF112233),
        watching: const Color(0xFF445566),
      );

      expect(modified.wantToWatch, const Color(0xFF112233));
      expect(modified.watching, const Color(0xFF445566));
      expect(modified.watched, original.watched);
      expect(modified.onHold, original.onHold);
      expect(modified.dropped, original.dropped);
    });

    test('lerp interpolates between two AnimeThemeColors', () {
      const light = AnimeThemeColors.light;
      const dark = AnimeThemeColors.dark;

      final mid = light.lerp(dark, 0.5);
      expect(mid.wantToWatch, Color.lerp(light.wantToWatch, dark.wantToWatch, 0.5));
      expect(mid.watching, Color.lerp(light.watching, dark.watching, 0.5));
      expect(mid.watched, Color.lerp(light.watched, dark.watched, 0.5));
      expect(mid.onHold, Color.lerp(light.onHold, dark.onHold, 0.5));
      expect(mid.dropped, Color.lerp(light.dropped, dark.dropped, 0.5));

      // Lerping with null or different type returns this
      expect(light.lerp(null, 0.5), same(light));
    });
  });

  group('AppTheme Tests', () {
    test('lightTheme has correct brightness, primary and extensions', () {
      final theme = AppTheme.lightTheme;
      expect(theme.brightness, Brightness.light);
      expect(theme.primaryColor, AppTheme.primaryLight);
      expect(theme.colorScheme.primary, AppTheme.primaryLight);
      expect(theme.extension<AnimeThemeColors>(), isNotNull);
    });

    test('darkTheme has correct brightness, primary and extensions', () {
      final theme = AppTheme.darkTheme;
      expect(theme.brightness, Brightness.dark);
      expect(theme.primaryColor, AppTheme.primaryDark);
      expect(theme.colorScheme.primary, AppTheme.primaryDark);
      expect(theme.extension<AnimeThemeColors>(), isNotNull);
    });
  });
}
