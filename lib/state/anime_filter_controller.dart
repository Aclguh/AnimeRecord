import 'package:flutter/foundation.dart';
import '../models/anime_record.dart';
import '../models/app_constants.dart';

/// 番剧列表展示与过滤状态控制器（负责管理搜索、状态筛选、周几筛选、排序与分页状态及计算缓存）
class AnimeFilterController extends ChangeNotifier {
  String _activeStatus;
  String _activeWeek = '';
  String _searchQuery = '';
  String _sortBy = SortOption.defaultSort;
  int _currentPage = 1;
  static const int pageSize = 20;

  // 过滤与排序缓存（Memoization）
  List<AnimeRecord>? _cachedFilteredRecords;
  Map<String, int>? _cachedActiveWeekCounts;
  List<AnimeRecord>? _lastSourceRecords;

  AnimeFilterController({String initialStatus = AnimeStatus.watchingValue})
      : _activeStatus = initialStatus;

  // Getters
  String get activeStatus => _activeStatus;
  String get activeWeek => _activeWeek;
  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;
  int get currentPage => _currentPage;

  /// 使计算缓存失效
  void invalidateCache() {
    _cachedFilteredRecords = null;
    _cachedActiveWeekCounts = null;
    _lastSourceRecords = null;
  }

  void setStatusFilter(String status) {
    if (_activeStatus == status) return;
    _activeStatus = status;
    _activeWeek = ''; // 切换主状态 Tab 时重置周几筛选，展示新状态的全量数据
    _currentPage = 1;
    invalidateCache();
    notifyListeners();
  }

  void setWeekFilter(String week) {
    if (_activeWeek == week) return;
    _activeWeek = week;
    _currentPage = 1;
    invalidateCache();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _currentPage = 1;
    invalidateCache();
    notifyListeners();
  }

  void setSortBy(String sort) {
    if (_sortBy == sort) return;
    _sortBy = sort;
    _currentPage = 1;
    invalidateCache();
    notifyListeners();
  }

  bool loadMore(int totalFilteredLength) {
    if (currentPage * pageSize < totalFilteredLength) {
      _currentPage++;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// 获取经过顶部状态与关键词筛选的记录列表
  List<AnimeRecord> getTopFiltered(List<AnimeRecord> records) {
    List<AnimeRecord> list = records;

    // 1. 顶部状态筛选
    if (_activeStatus != 'all') {
      list = list.where((r) => r.status == _activeStatus).toList();
    }

    // 2. 顶部搜索匹配（支持中文标题、日文标题、备注评价、标签短路匹配）
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((r) => r.matchesSearch(q)).toList();
    }

    return list;
  }

  /// 计算符合当前条件的记录列表（带缓存机制）
  List<AnimeRecord> filterAndSort(List<AnimeRecord> records) {
    if (_cachedFilteredRecords != null && identical(_lastSourceRecords, records)) {
      return _cachedFilteredRecords!;
    }

    final topList = getTopFiltered(records);
    final weekCounts = computeActiveWeekCounts(records);

    // 周几联动筛选（若当前选中的周几在当前顶部筛选下已无任何匹配记录，则回退为全部）
    var list = topList;
    var effectiveWeek = _activeWeek;
    if (effectiveWeek.isNotEmpty && (weekCounts[effectiveWeek] ?? 0) == 0) {
      effectiveWeek = '';
    }

    if (effectiveWeek.isNotEmpty) {
      list = list.where((r) => r.week == effectiveWeek).toList();
    }

    // 排序
    final sorted = sortRecords(list, _sortBy);

    _cachedFilteredRecords = sorted;
    _lastSourceRecords = records;
    return sorted;
  }

  /// 排序算法
  static List<AnimeRecord> sortRecords(List<AnimeRecord> list, String sort) {
    final sorted = List<AnimeRecord>.from(list);

    switch (sort) {
      case SortOption.dateAddedDesc:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.dateAddedAsc:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortOption.titleZhAsc:
        sorted.sort((a, b) => a.titleZh.compareTo(b.titleZh));
        break;
      case SortOption.titleZhDesc:
        sorted.sort((a, b) => b.titleZh.compareTo(a.titleZh));
        break;
      case SortOption.episodesLeft:
        sorted.sort((a, b) {
          final leftA = a.episodesTotal > 0
              ? (a.episodesTotal - a.episodesWatched).clamp(0, 999999)
              : 9999999;
          final leftB = b.episodesTotal > 0
              ? (b.episodesTotal - b.episodesWatched).clamp(0, 999999)
              : 9999999;
          return leftA.compareTo(leftB);
        });
        break;
      default:
        // 默认排序：按状态权重优先级分组，同一状态内保持用户自定义拖拽顺序
        sorted.sort((a, b) {
          final orderA = AnimeStatus.getOrder(a.status);
          final orderB = AnimeStatus.getOrder(b.status);
          return orderA.compareTo(orderB);
        });
        break;
    }

    return sorted;
  }

  /// 获取当前分页截取记录
  List<AnimeRecord> getPaged(List<AnimeRecord> filtered) {
    final count = (_currentPage * pageSize).clamp(0, filtered.length);
    return filtered.take(count).toList();
  }

  /// 是否有更多数据待分页加载
  bool hasMore(List<AnimeRecord> filtered) {
    return filtered.length > (_currentPage * pageSize);
  }

  /// 计算当前筛选条件下的周几统计
  Map<String, int> computeActiveWeekCounts(List<AnimeRecord> records) {
    if (_cachedActiveWeekCounts != null && identical(_lastSourceRecords, records)) {
      return _cachedActiveWeekCounts!;
    }

    final topList = getTopFiltered(records);
    final counts = <String, int>{};
    for (final r in topList) {
      if (r.week.isNotEmpty && WeekDay.order.contains(r.week)) {
        counts[r.week] = (counts[r.week] ?? 0) + 1;
      }
    }

    _cachedActiveWeekCounts = counts;
    return counts;
  }

  /// 计算全局状态数量统计
  static Map<String, int> computeStatusCounts(List<AnimeRecord> records) {
    final counts = <String, int>{
      AnimeStatus.wantToWatchValue: 0,
      AnimeStatus.watchingValue: 0,
      AnimeStatus.watchedValue: 0,
      AnimeStatus.onHoldValue: 0,
      AnimeStatus.droppedValue: 0,
    };
    for (final r in records) {
      counts[r.status] = (counts[r.status] ?? 0) + 1;
    }
    return counts;
  }
}
