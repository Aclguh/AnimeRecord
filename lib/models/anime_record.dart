import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'app_constants.dart';

const _uuid = Uuid();

/// 番剧数据校验失败原因枚举（领域层错误类型，解耦具体 UI 显示语言）
enum AnimeValidationError {
  emptyTitle('请输入番剧名称'),
  invalidRating('评分应在 0-10 之间'),
  negativeEpisodes('集数不能为负数'),
  invalidWeek('更新频率取值无效'),
  invalidAirStatus('播放状态取值无效'),
  invalidCoverUrl('封面链接必须是以 http:// 或 https:// 开头的有效网址'),
  episodesExceeded('已看集数不能超过总集数');

  final String defaultMessage;
  const AnimeValidationError(this.defaultMessage);
}

/// 单条看番记录
class AnimeRecord {
  final String id;
  final String titleZh;
  final String titleJa;
  final String coverUrl;
  final String status;
  final String week;
  final String airStatus;
  final double rating;
  final int episodesWatched;
  final int episodesTotal;
  final List<String> tags;
  final String notes;
  final String startDate;
  final String endDate;
  final int year;
  final String season;
  final String createdAt;
  final String updatedAt;

  const AnimeRecord({
    required this.id,
    required this.titleZh,
    this.titleJa = '',
    this.coverUrl = '',
    this.status = AnimeStatus.wantToWatch,
    this.week = '',
    this.airStatus = '',
    this.rating = 0.0,
    this.episodesWatched = 0,
    this.episodesTotal = 0,
    this.tags = const [],
    this.notes = '',
    this.startDate = '',
    this.endDate = '',
    this.year = 0,
    this.season = '',
    required this.createdAt,
    required this.updatedAt,
  });

  /// 创建空白新记录模板
  factory AnimeRecord.createEmpty() {
    final now = DateTime.now().toIso8601String();
    return AnimeRecord(
      id: _uuid.v4(),
      titleZh: '',
      titleJa: '',
      coverUrl: '',
      status: AnimeStatus.wantToWatch,
      week: '',
      airStatus: '',
      rating: 0.0,
      episodesWatched: 0,
      episodesTotal: 0,
      tags: const [],
      notes: '',
      startDate: '',
      endDate: '',
      year: DateTime.now().year,
      season: '',
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 复制并更新部分属性
  AnimeRecord copyWith({
    String? id,
    String? titleZh,
    String? titleJa,
    String? coverUrl,
    String? status,
    String? week,
    String? airStatus,
    double? rating,
    int? episodesWatched,
    int? episodesTotal,
    List<String>? tags,
    String? notes,
    String? startDate,
    String? endDate,
    int? year,
    String? season,
    String? createdAt,
    String? updatedAt,
  }) {
    return AnimeRecord(
      id: id ?? this.id,
      titleZh: titleZh ?? this.titleZh,
      titleJa: titleJa ?? this.titleJa,
      coverUrl: coverUrl ?? this.coverUrl,
      status: status ?? this.status,
      week: week ?? this.week,
      airStatus: airStatus ?? this.airStatus,
      rating: rating ?? this.rating,
      episodesWatched: (episodesWatched ?? this.episodesWatched) < 0 ? 0 : (episodesWatched ?? this.episodesWatched),
      episodesTotal: (episodesTotal ?? this.episodesTotal) < 0 ? 0 : (episodesTotal ?? this.episodesTotal),
      tags: tags != null ? List<String>.unmodifiable(tags) : this.tags,
      notes: notes ?? this.notes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      year: year ?? this.year,
      season: season ?? this.season,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 从 JSON 映射恢复（与 Web 端字段完全一致且兼容缺失字段）
  factory AnimeRecord.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now().toIso8601String();
    final createdAt = json['createdAt']?.toString() ?? now;
    final updatedAt = json['updatedAt']?.toString() ?? createdAt;

    List<String> parsedTags = [];
    if (json['tags'] is List) {
      parsedTags = (json['tags'] as List).map((e) => e.toString()).toList();
    }

    double parsedRating = 0.0;
    if (json['rating'] != null) {
      if (json['rating'] is num) {
        parsedRating = (json['rating'] as num).toDouble();
      } else {
        parsedRating = double.tryParse(json['rating'].toString()) ?? 0.0;
      }
    }

    int parsedEpWatched = 0;
    if (json['episodesWatched'] != null) {
      if (json['episodesWatched'] is num) {
        parsedEpWatched = (json['episodesWatched'] as num).toInt();
      } else {
        parsedEpWatched = int.tryParse(json['episodesWatched'].toString()) ?? 0;
      }
    }

    int parsedEpTotal = 0;
    if (json['episodesTotal'] != null) {
      if (json['episodesTotal'] is num) {
        parsedEpTotal = (json['episodesTotal'] as num).toInt();
      } else {
        parsedEpTotal = int.tryParse(json['episodesTotal'].toString()) ?? 0;
      }
    }

    int parsedYear = DateTime.now().year;
    if (json['year'] != null) {
      if (json['year'] is num) {
        parsedYear = (json['year'] as num).toInt();
      } else {
        parsedYear = int.tryParse(json['year'].toString()) ?? DateTime.now().year;
      }
    }

    return AnimeRecord(
      id: json['id']?.toString() ?? _uuid.v4(),
      titleZh: json['titleZh']?.toString() ?? '',
      titleJa: json['titleJa']?.toString() ?? '',
      coverUrl: json['coverUrl']?.toString() ?? '',
      status: json['status']?.toString() ?? AnimeStatus.wantToWatch,
      week: json['week']?.toString() ?? '',
      airStatus: json['airStatus']?.toString() ?? '',
      rating: parsedRating,
      episodesWatched: parsedEpWatched < 0 ? 0 : parsedEpWatched,
      episodesTotal: parsedEpTotal < 0 ? 0 : parsedEpTotal,
      tags: List<String>.unmodifiable(parsedTags),
      notes: json['notes']?.toString() ?? '',
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      year: parsedYear,
      season: json['season']?.toString() ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// 转换为 JSON（完全兼容 Web 端格式）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titleZh': titleZh,
      'titleJa': titleJa,
      'coverUrl': coverUrl,
      'status': status,
      'week': week,
      'airStatus': airStatus,
      'rating': rating,
      'episodesWatched': episodesWatched,
      'episodesTotal': episodesTotal,
      'tags': tags,
      'notes': notes,
      'startDate': startDate,
      'endDate': endDate,
      'year': year,
      'season': season,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// 强类型领域验证方法，返回具体的验证失败原因枚举，null 表示通过
  AnimeValidationError? validateError() {
    if (titleZh.trim().isEmpty) {
      return AnimeValidationError.emptyTitle;
    }
    if (rating < 0 || rating > 10) {
      return AnimeValidationError.invalidRating;
    }
    if (episodesWatched < 0 || episodesTotal < 0) {
      return AnimeValidationError.negativeEpisodes;
    }
    if (week.isNotEmpty && !WeekDay.order.contains(week)) {
      return AnimeValidationError.invalidWeek;
    }
    if (airStatus.isNotEmpty && !AirStatus.allValues.contains(airStatus)) {
      return AnimeValidationError.invalidAirStatus;
    }
    if (coverUrl.trim().isNotEmpty) {
      final uri = Uri.tryParse(coverUrl.trim());
      if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https') || uri.host.isEmpty) {
        return AnimeValidationError.invalidCoverUrl;
      }
    }
    if (episodesTotal > 0 && episodesWatched > episodesTotal) {
      return AnimeValidationError.episodesExceeded;
    }
    return null;
  }

  /// 验证有效性（向后兼容），null 表示通过
  String? validate() => validateError()?.defaultMessage;

  /// 相对修改时间文本描述（支持根据当前语言代码格式化输出）
  String formatRelativeUpdatedAt({String locale = 'zh'}) {
    if (updatedAt.isEmpty) return '';
    try {
      final date = DateTime.tryParse(updatedAt);
      if (date == null) return '';

      final now = DateTime.now();
      final diff = now.difference(date);
      final isEn = locale.startsWith('en');

      if (diff.isNegative || diff.inMinutes < 1) {
        return isEn ? 'Just now' : '刚刚';
      }
      if (diff.inHours < 1) {
        return isEn ? '${diff.inMinutes}m ago' : '${diff.inMinutes}分钟前';
      }
      if (diff.inDays < 1) {
        return isEn ? '${diff.inHours}h ago' : '${diff.inHours}小时前';
      }
      if (diff.inDays < 3) {
        return isEn ? '${diff.inDays}d ago' : '${diff.inDays}天前';
      }

      final isSameYear = date.year == now.year;
      final m = date.month;
      final d = date.day;
      if (isEn) {
        return isSameYear ? '$m/$d' : '$m/$d/${date.year}';
      }
      return isSameYear ? '$m月$d日' : '${date.year}年$m月$d日';
    } catch (_) {
      return '';
    }
  }

  /// 完整时间戳展示（用于 Tooltip / 悬停详情）
  String formatFullUpdatedAt() {
    if (updatedAt.isEmpty) return '';
    try {
      final date = DateTime.tryParse(updatedAt);
      if (date == null) return '';
      final y = date.year;
      final m = date.month.toString().padLeft(2, '0');
      final d = date.day.toString().padLeft(2, '0');
      final h = date.hour.toString().padLeft(2, '0');
      final min = date.minute.toString().padLeft(2, '0');
      return '$y-$m-$d $h:$min';
    } catch (_) {
      return '';
    }
  }

  /// 强类型状态枚举 Getter
  WatchStatus get watchStatus => WatchStatus.fromValue(status);

  /// 强类型更新日枚举 Getter
  WeekDayEnum? get weekDayEnum => WeekDayEnum.fromValue(week);

  /// 强类型播放状态枚举 Getter
  AirStatusEnum? get airStatusEnum => AirStatusEnum.fromValue(airStatus);

  /// 强类型季度枚举 Getter
  SeasonEnum? get seasonEnum => SeasonEnum.fromValue(season);

  /// 核心领域状态机方法：集数递增并自动触发状态流转（到达总集数标记完成，想看/搁置流转为在看，支持注入确定性时钟）
  ({AnimeRecord record, String? statusChangedMessage, WatchStatus? transitionedStatus}) incrementEpisode({
    DateTime? now,
  }) {
    final currentNow = now ?? DateTime.now();
    int newWatched = episodesWatched + 1;
    String newStatus = status;
    String newEndDate = endDate;

    // 状态自动切换：想看 / 搁置 时点 +1 自动变为在看
    if (status == AnimeStatus.wantToWatch || status == AnimeStatus.onHold) {
      newStatus = AnimeStatus.watching;
    }

    // 达到总集数时自动标记为看过并填补结束日期
    if (episodesTotal > 0 && newWatched >= episodesTotal) {
      newStatus = AnimeStatus.watched;
      if (newEndDate.isEmpty) {
        newEndDate = currentNow.toIso8601String().split('T').first;
      }
      newWatched = episodesTotal;
    }

    final updated = copyWith(
      episodesWatched: newWatched,
      status: newStatus,
      endDate: newEndDate,
      updatedAt: currentNow.toIso8601String(),
    );

    String? msg;
    WatchStatus? transitioned;
    if (newStatus != status) {
      transitioned = WatchStatus.fromValue(newStatus);
      if (newStatus == AnimeStatus.watched) {
        msg = '「${updated.titleZh}」已追完';
      } else if (newStatus == AnimeStatus.watching) {
        msg = '「${updated.titleZh}」状态已切换为「在看」';
      }
    }

    return (record: updated, statusChangedMessage: msg, transitionedStatus: transitioned);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnimeRecord &&
        other.id == id &&
        other.titleZh == titleZh &&
        other.titleJa == titleJa &&
        other.coverUrl == coverUrl &&
        other.status == status &&
        other.week == week &&
        other.airStatus == airStatus &&
        other.rating == rating &&
        other.episodesWatched == episodesWatched &&
        other.episodesTotal == episodesTotal &&
        listEquals(other.tags, tags) &&
        other.notes == notes &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.year == year &&
        other.season == season &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        titleZh,
        titleJa,
        coverUrl,
        status,
        week,
        airStatus,
        rating,
        episodesWatched,
        episodesTotal,
        Object.hashAll(tags),
        notes,
        startDate,
        endDate,
        year,
        season,
        createdAt,
        updatedAt,
      ]);

  @override
  String toString() => 'AnimeRecord(id: $id, titleZh: $titleZh, status: $status, ep: $episodesWatched/$episodesTotal)';
}

