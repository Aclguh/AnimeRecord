import 'package:uuid/uuid.dart';
import 'app_constants.dart';

const _uuid = Uuid();

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
      episodesWatched: episodesWatched ?? this.episodesWatched,
      episodesTotal: episodesTotal ?? this.episodesTotal,
      tags: tags ?? this.tags,
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
      episodesWatched: parsedEpWatched,
      episodesTotal: parsedEpTotal,
      tags: parsedTags,
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

  /// 验证有效性，null 表示通过
  String? validate() {
    if (titleZh.trim().isEmpty) {
      return '请输入番剧名称';
    }
    if (rating < 0 || rating > 10) {
      return '评分应在 0-10 之间';
    }
    if (episodesWatched < 0 || episodesTotal < 0) {
      return '集数不能为负数';
    }
    if (week.isNotEmpty && !WeekDay.order.contains(week)) {
      return '更新频率取值无效';
    }
    if (airStatus.isNotEmpty && !AirStatus.allValues.contains(airStatus)) {
      return '播放状态取值无效';
    }
    if (episodesTotal > 0 && episodesWatched > episodesTotal) {
      return '已看集数不能超过总集数';
    }
    return null;
  }

  /// 相对修改时间文本描述
  String formatRelativeUpdatedAt() {
    if (updatedAt.isEmpty) return '';
    try {
      final date = DateTime.tryParse(updatedAt);
      if (date == null) return '';

      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.isNegative || diff.inMinutes < 1) {
        return '刚刚';
      }
      if (diff.inHours < 1) {
        return '${diff.inMinutes}分钟前';
      }
      if (diff.inDays < 1) {
        return '${diff.inHours}小时前';
      }
      if (diff.inDays < 3) {
        return '${diff.inDays}天前';
      }

      final isSameYear = date.year == now.year;
      final m = date.month;
      final d = date.day;
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
}
