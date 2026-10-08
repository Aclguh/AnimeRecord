import 'package:flutter/material.dart';

/// 观看状态常量
class AnimeStatus {
  static const String wantToWatch = 'want_to_watch';
  static const String watching = 'watching';
  static const String watched = 'watched';
  static const String onHold = 'on_hold';
  static const String dropped = 'dropped';

  static const List<String> allValues = [
    wantToWatch,
    watching,
    watched,
    onHold,
    dropped,
  ];

  static String getLabel(String status) {
    switch (status) {
      case wantToWatch:
        return '想看';
      case watching:
        return '在看';
      case watched:
        return '看过';
      case onHold:
        return '搁置';
      case dropped:
        return '抛弃';
      default:
        return status;
    }
  }

  static int getOrder(String status) {
    switch (status) {
      case watching:
        return 1;
      case wantToWatch:
        return 2;
      case onHold:
        return 3;
      case watched:
        return 4;
      case dropped:
        return 5;
      default:
        return 99;
    }
  }

  static Color getColor(String status, {bool isDark = false}) {
    switch (status) {
      case wantToWatch:
        return isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6);
      case watching:
        return isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
      case watched:
        return isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B);
      case onHold:
        return isDark ? const Color(0xFF9AA4B8) : const Color(0xFF8A94A6);
      case dropped:
        return isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444);
      default:
        return const Color(0xFF999999);
    }
  }

  static Color getSoftColor(String status, {bool isDark = false}) {
    switch (status) {
      case wantToWatch:
        return isDark ? const Color(0xFF16243D) : const Color(0xFFE8F1FF);
      case watching:
        return isDark ? const Color(0xFF10251D) : const Color(0xFFE6F8F1);
      case watched:
        return isDark ? const Color(0xFF2A2110) : const Color(0xFFFFF5E3);
      case onHold:
        return isDark ? const Color(0xFF232733) : const Color(0xFFEEF1F5);
      case dropped:
        return isDark ? const Color(0xFF2A1517) : const Color(0xFFFFECEC);
      default:
        return isDark ? const Color(0xFF1E2025) : const Color(0xFFF3F4F6);
    }
  }
}

/// 更新频率（周几）常量
class WeekDay {
  static const String mon = 'mon';
  static const String tue = 'tue';
  static const String wed = 'wed';
  static const String thu = 'thu';
  static const String fri = 'fri';
  static const String sat = 'sat';
  static const String sun = 'sun';

  static const List<String> order = [mon, tue, wed, thu, fri, sat, sun];

  static String getLabel(String? week) {
    switch (week) {
      case mon:
        return '周一';
      case tue:
        return '周二';
      case wed:
        return '周三';
      case thu:
        return '周四';
      case fri:
        return '周五';
      case sat:
        return '周六';
      case sun:
        return '周日';
      default:
        return '';
    }
  }

  static String getFullLabel(String? week) {
    switch (week) {
      case mon:
        return '每周一';
      case tue:
        return '每周二';
      case wed:
        return '每周三';
      case thu:
        return '每周四';
      case fri:
        return '每周五';
      case sat:
        return '每周六';
      case sun:
        return '每周日';
      default:
        return '不设置';
    }
  }

  static (Color bg, Color fg) getColors(String? week) {
    switch (week) {
      case mon:
        return (const Color(0xFFFEF3C7), const Color(0xFFB45309));
      case tue:
        return (const Color(0xFFFCE7F3), const Color(0xFFBE185D));
      case wed:
        return (const Color(0xFFDCFCE7), const Color(0xFF15803D));
      case thu:
        return (const Color(0xFFFFEDD5), const Color(0xFFC2410C));
      case fri:
        return (const Color(0xFFDBEAFE), const Color(0xFF1D4ED8));
      case sat:
        return (const Color(0xFFEDE9FE), const Color(0xFF6D28D9));
      case sun:
        return (const Color(0xFFFFE4E6), const Color(0xFFBE123C));
      default:
        return (const Color(0xFFF1F5F9), const Color(0xFF475569));
    }
  }
}

/// 播放状态常量
class AirStatus {
  static const String airing = 'airing';
  static const String finished = 'finished';

  static const List<String> allValues = [airing, finished];

  static String getLabel(String? status) {
    switch (status) {
      case airing:
        return '正在更新';
      case finished:
        return '完结';
      default:
        return '';
    }
  }

  static (Color bg, Color fg) getColors(String? status) {
    switch (status) {
      case airing:
        return (const Color(0xFFCCFBF1), const Color(0xFF0F766E));
      case finished:
        return (const Color(0xFFE2E8F0), const Color(0xFF475569));
      default:
        return (const Color(0xFFF1F5F9), const Color(0xFF475569));
    }
  }
}

/// 季度常量
class Season {
  static const String winter = 'winter';
  static const String spring = 'spring';
  static const String summer = 'summer';
  static const String fall = 'fall';

  static const List<String> allValues = [winter, spring, summer, fall];

  static String getLabel(String? season) {
    switch (season) {
      case winter:
        return '冬季';
      case spring:
        return '春季';
      case summer:
        return '夏季';
      case fall:
        return '秋季';
      default:
        return '';
    }
  }
}

/// 排序选项常量
class SortOption {
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
