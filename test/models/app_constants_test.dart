import 'package:anime_record/models/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WatchStatus & AnimeStatus Tests', () {
    test('fromValue returns corresponding status or fallback', () {
      expect(WatchStatus.fromValue('watching'), WatchStatus.watching);
      expect(WatchStatus.fromValue('want_to_watch'), WatchStatus.wantToWatch);
      expect(WatchStatus.fromValue('watched'), WatchStatus.watched);
      expect(WatchStatus.fromValue('on_hold'), WatchStatus.onHold);
      expect(WatchStatus.fromValue('dropped'), WatchStatus.dropped);
      expect(WatchStatus.fromValue('unknown'), WatchStatus.wantToWatch);
      expect(WatchStatus.fromValue(null), WatchStatus.wantToWatch);
    });

    test('getColor and getSoftColor in light and dark modes', () {
      for (final s in WatchStatus.values) {
        expect(s.getColor(isDark: false), isA<Color>());
        expect(s.getColor(isDark: true), isA<Color>());
        expect(s.getSoftColor(isDark: false), isA<Color>());
        expect(s.getSoftColor(isDark: true), isA<Color>());
      }
    });

    test('AnimeStatus bridges getters correctly', () {
      expect(AnimeStatus.getLabel(AnimeStatus.watching), '在看');
      expect(AnimeStatus.getOrder(AnimeStatus.watching), 1);
      expect(AnimeStatus.getColor(AnimeStatus.watching), isA<Color>());
      expect(AnimeStatus.getSoftColor(AnimeStatus.watching), isA<Color>());
    });
  });

  group('WeekDay & WeekDayEnum Tests', () {
    test('WeekDayEnum fromValue and colors', () {
      expect(WeekDayEnum.fromValue('mon'), WeekDayEnum.mon);
      expect(WeekDayEnum.fromValue('invalid'), isNull);
      for (final w in WeekDayEnum.values) {
        final (bg, fg) = w.colors;
        expect(bg, isA<Color>());
        expect(fg, isA<Color>());
      }
    });

    test('WeekDay helper methods', () {
      expect(WeekDay.getLabel('mon'), '周一');
      expect(WeekDay.getLabel('unknown'), '');
      expect(WeekDay.getFullLabel('mon'), '每周一');
      expect(WeekDay.getFullLabel(null), '不设置');
      final (bg, fg) = WeekDay.getColors('mon');
      expect(bg, isA<Color>());
      expect(fg, isA<Color>());
      final (defaultBg, defaultFg) = WeekDay.getColors(null);
      expect(defaultBg, isA<Color>());
      expect(defaultFg, isA<Color>());
    });
  });

  group('AirStatus & AirStatusEnum Tests', () {
    test('AirStatusEnum fromValue and colors', () {
      expect(AirStatusEnum.fromValue('airing'), AirStatusEnum.airing);
      expect(AirStatusEnum.fromValue('finished'), AirStatusEnum.finished);
      expect(AirStatusEnum.fromValue(null), isNull);
      for (final a in AirStatusEnum.values) {
        final (bg, fg) = a.colors;
        expect(bg, isA<Color>());
        expect(fg, isA<Color>());
      }
    });

    test('AirStatus helper methods', () {
      expect(AirStatus.getLabel('airing'), '正在更新');
      expect(AirStatus.getLabel(null), '');
      final (bg, fg) = AirStatus.getColors('airing');
      expect(bg, isA<Color>());
      expect(fg, isA<Color>());
      final (fallbackBg, fallbackFg) = AirStatus.getColors('unknown');
      expect(fallbackBg, isA<Color>());
      expect(fallbackFg, isA<Color>());
    });
  });

  group('Season & SeasonEnum Tests', () {
    test('SeasonEnum fromValue and Season.getLabel', () {
      expect(SeasonEnum.fromValue('winter'), SeasonEnum.winter);
      expect(SeasonEnum.fromValue('spring'), SeasonEnum.spring);
      expect(SeasonEnum.fromValue('summer'), SeasonEnum.summer);
      expect(SeasonEnum.fromValue('fall'), SeasonEnum.fall);
      expect(SeasonEnum.fromValue('unknown'), isNull);

      expect(Season.getLabel('winter'), '冬季');
      expect(Season.getLabel(null), '');
    });
  });

  group('SortMode & PresetTags Tests', () {
    test('SortMode fromValue', () {
      expect(SortMode.fromValue(''), SortMode.defaultSort);
      expect(SortMode.fromValue('date_added_desc'), SortMode.dateAddedDesc);
      expect(SortMode.fromValue('unknown'), SortMode.defaultSort);
    });

    test('kPresetTags is non-empty', () {
      expect(kPresetTags, isNotEmpty);
      expect(kPresetTags.contains('奇幻'), isTrue);
    });
  });
}
