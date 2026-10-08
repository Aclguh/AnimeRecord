import 'package:flutter/material.dart';

/// 观看状态增强枚举 (WatchStatus)
enum WatchStatus {
  watching('watching', '在看', 1),
  wantToWatch('want_to_watch', '想看', 2),
  onHold('on_hold', '搁置', 3),
  watched('watched', '看过', 4),
  dropped('dropped', '抛弃', 5);

  final String value;
  final String label;
  final int order;

  const WatchStatus(this.value, this.label, this.order);

  static WatchStatus fromValue(String? val) {
    for (final s in WatchStatus.values) {
      if (s.value == val) return s;
    }
    return WatchStatus.wantToWatch;
  }
}

/// 观看状态常量与样式映射（对齐 AGENTS.md 规范色彩体系）
abstract final class AnimeStatus {
  static const String watching = 'watching';
  static const String wantToWatch = 'want_to_watch';
  static const String onHold = 'on_hold';
  static const String watched = 'watched';
  static const String dropped = 'dropped';

  static const String watchingValue = watching;
  static const String wantToWatchValue = wantToWatch;
  static const String onHoldValue = onHold;
  static const String watchedValue = watched;
  static const String droppedValue = dropped;

  static const List<String> allValues = [
    wantToWatch,
    watching,
    watched,
    onHold,
    dropped,
  ];

  static String getLabel(String status) => WatchStatus.fromValue(status).label;

  static int getOrder(String status) {
    for (final s in WatchStatus.values) {
      if (s.value == status) return s.order;
    }
    return 99;
  }

  /// 状态主色调（严格对齐原版网页 style.css 规范：想看蓝 #3B82F6、在看绿 #10B981、看过橙 #F59E0B、搁置灰 #8A94A6、抛弃红 #EF4444）
  static Color getColor(String status, {bool isDark = false}) {
    return switch (status) {
      wantToWatch => isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6), // 想看: 蓝
      watching => isDark ? const Color(0xFF34D399) : const Color(0xFF10B981),    // 在看: 绿
      watched => isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B),     // 看过: 琥珀橙
      onHold => isDark ? const Color(0xFF9AA4B8) : const Color(0xFF8A94A6),      // 搁置: 蓝灰
      dropped => isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444),     // 抛弃: 红
      _ => isDark ? const Color(0xFF9AA4B8) : const Color(0xFF8A94A6),
    };
  }

  /// 状态徽标与背景底色（严格对齐原版网页软底色）
  static Color getSoftColor(String status, {bool isDark = false}) {
    return switch (status) {
      wantToWatch => isDark ? const Color(0xFF16243D) : const Color(0xFFE8F1FF),
      watching => isDark ? const Color(0xFF10251D) : const Color(0xFFE6F8F1),
      watched => isDark ? const Color(0xFF2A2110) : const Color(0xFFFFF5E3),
      onHold => isDark ? const Color(0xFF232733) : const Color(0xFFEEF1F5),
      dropped => isDark ? const Color(0xFF2A1517) : const Color(0xFFFFECEC),
      _ => isDark ? const Color(0xFF1C2029) : const Color(0xFFF1F5F9),
    };
  }
}

/// 更新频率增强枚举 (WeekDayEnum)
enum WeekDayEnum {
  mon('mon', '周一', '每周一'),
  tue('tue', '周二', '每周二'),
  wed('wed', '周三', '每周三'),
  thu('thu', '周四', '每周四'),
  fri('fri', '周五', '每周五'),
  sat('sat', '周六', '每周六'),
  sun('sun', '周日', '每周日');

  final String value;
  final String label;
  final String fullLabel;

  const WeekDayEnum(this.value, this.label, this.fullLabel);

  static WeekDayEnum? fromValue(String? val) {
    for (final w in WeekDayEnum.values) {
      if (w.value == val) return w;
    }
    return null;
  }
}

/// 更新频率（周几）常量与工具方法
abstract final class WeekDay {
  static const String mon = 'mon';
  static const String tue = 'tue';
  static const String wed = 'wed';
  static const String thu = 'thu';
  static const String fri = 'fri';
  static const String sat = 'sat';
  static const String sun = 'sun';

  static const List<String> order = [mon, tue, wed, thu, fri, sat, sun];

  static String getLabel(String? week) => WeekDayEnum.fromValue(week)?.label ?? '';

  static String getFullLabel(String? week) => WeekDayEnum.fromValue(week)?.fullLabel ?? '不设置';

  static (Color bg, Color fg) getColors(String? week) {
    return switch (week) {
      mon => (const Color(0xFFFEF3C7), const Color(0xFFB45309)),
      tue => (const Color(0xFFFCE7F3), const Color(0xFFBE185D)),
      wed => (const Color(0xFFDCFCE7), const Color(0xFF15803D)),
      thu => (const Color(0xFFFFEDD5), const Color(0xFFC2410C)),
      fri => (const Color(0xFFDBEAFE), const Color(0xFF1D4ED8)),
      sat => (const Color(0xFFEDE9FE), const Color(0xFF6D28D9)),
      sun => (const Color(0xFFFFE4E6), const Color(0xFFBE123C)),
      _ => (const Color(0xFFF1F5F9), const Color(0xFF475569)),
    };
  }
}

/// 播放状态增强枚举 (AirStatusEnum)
enum AirStatusEnum {
  airing('airing', '正在更新'),
  finished('finished', '完结');

  final String value;
  final String label;

  const AirStatusEnum(this.value, this.label);

  static AirStatusEnum? fromValue(String? val) {
    for (final a in AirStatusEnum.values) {
      if (a.value == val) return a;
    }
    return null;
  }
}

/// 播放状态常量与工具方法
abstract final class AirStatus {
  static const String airing = 'airing';
  static const String finished = 'finished';

  static const List<String> allValues = [airing, finished];

  static String getLabel(String? status) => AirStatusEnum.fromValue(status)?.label ?? '';

  static (Color bg, Color fg) getColors(String? status) {
    return switch (status) {
      airing => (const Color(0xFFCCFBF1), const Color(0xFF0F766E)),
      finished => (const Color(0xFFE2E8F0), const Color(0xFF475569)),
      _ => (const Color(0xFFF1F5F9), const Color(0xFF475569)),
    };
  }
}

/// 季度枚举 (SeasonEnum)
enum SeasonEnum {
  winter('winter', '冬季'),
  spring('spring', '春季'),
  summer('summer', '夏季'),
  fall('fall', '秋季');

  final String value;
  final String label;

  const SeasonEnum(this.value, this.label);

  static SeasonEnum? fromValue(String? val) {
    for (final s in SeasonEnum.values) {
      if (s.value == val) return s;
    }
    return null;
  }
}

/// 季度常量与工具方法
abstract final class Season {
  static const String winter = 'winter';
  static const String spring = 'spring';
  static const String summer = 'summer';
  static const String fall = 'fall';

  static const List<String> allValues = [winter, spring, summer, fall];

  static String getLabel(String? season) => SeasonEnum.fromValue(season)?.label ?? '';
}

/// 排序选项增强枚举 (SortMode)
enum SortMode {
  defaultSort('', '默认排序'),
  dateAddedDesc('date_added_desc', '最近添加'),
  dateAddedAsc('date_added_asc', '最早添加'),
  titleZhAsc('title_zh_asc', '名称 A-Z'),
  titleZhDesc('title_zh_desc', '名称 Z-A'),
  episodesLeft('episodes_left', '剩余集数');

  final String value;
  final String label;

  const SortMode(this.value, this.label);

  static SortMode fromValue(String? val) {
    for (final s in SortMode.values) {
      if (s.value == val) return s;
    }
    return SortMode.defaultSort;
  }
}

/// 排序选项常量
abstract final class SortOption {
  static const String defaultSort = '';
  static const String dateAddedDesc = 'date_added_desc';
  static const String dateAddedAsc = 'date_added_asc';
  static const String titleZhAsc = 'title_zh_asc';
  static const String titleZhDesc = 'title_zh_desc';
  static const String episodesLeft = 'episodes_left';

  static const Map<String, String> labels = {
    defaultSort: '默认排序',
    dateAddedDesc: '最近添加',
    dateAddedAsc: '最早添加',
    titleZhAsc: '名称 A-Z',
    titleZhDesc: '名称 Z-A',
    episodesLeft: '剩余集数',
  };
}

/// 预设标签
const List<String> kPresetTags = [
  '奇幻', '冒险', '战斗', '热血', '搞笑', '日常',
  '恋爱', '校园', '科幻', '机战', '悬疑', '推理',
  '治愈', '致郁', '异世界', '穿越', '运动', '音乐',
  '美食', '职场', '历史', '战争', '恐怖', '魔法'
];
