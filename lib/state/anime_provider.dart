import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/anime_record.dart';
import '../models/app_constants.dart';
import '../models/sync_config.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';

/// 追番记录核心状态管理（维护内存单源真理 Single Source of Truth，具备计算缓存与乐观更新能力）
class AnimeProvider extends ChangeNotifier {
  final IStorageService storage;
  final SyncService _syncService;
  final Duration saveDebounceDuration;

  Timer? _saveDebounceTimer;

  List<AnimeRecord> _records = [];
  String _activeStatus = AnimeStatus.watchingValue;
  String _activeWeek = '';
  String _searchQuery = '';
  String _sortBy = SortOption.defaultSort;

  int _currentPage = 1;
  static const int pageSize = 20;

  bool _isSyncing = false;
  SyncConfig _syncConfig = const SyncConfig();

  String? _lastErrorMessage;

  // 过滤与排序结果缓存（Memoization）
  List<AnimeRecord>? _cachedFilteredRecords;
  Map<String, int>? _cachedActiveWeekCounts;

  AnimeProvider({
    required this.storage,
    SyncService? syncService,
    this.saveDebounceDuration = const Duration(milliseconds: 300),
  })  : _syncService = syncService ?? SyncService() {
    _init();
  }

  // Getters
  List<AnimeRecord> get allRecords => List.unmodifiable(_records);
  String get activeStatus => _activeStatus;
  String get activeWeek {
    if (_activeWeek.isNotEmpty && (activeWeekCounts[_activeWeek] ?? 0) == 0) {
      return '';
    }
    return _activeWeek;
  }
  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;
  bool get isSyncing => _isSyncing;
  SyncConfig get syncConfig => _syncConfig;
  String? get lastErrorMessage => _lastErrorMessage;
  bool get hasPendingSave => _saveDebounceTimer != null;

  /// 立即刷写所有挂起的防抖写入至持久化存储
  Future<void> flushPendingSaves() async {
    if (_saveDebounceTimer != null) {
      _saveDebounceTimer!.cancel();
      _saveDebounceTimer = null;
      await storage.saveRecords(_records);
    }
  }

  void _scheduleDebouncedSave() {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(saveDebounceDuration, () {
      _saveDebounceTimer = null;
      unawaited(storage.saveRecords(_records));
    });
  }

  void _init() {
    _activeStatus = storage.loadDefaultStatus();
    _syncConfig = storage.loadSyncConfig();
    _records = storage.loadRecords();
    _invalidateCache();

    // 如果开启自动同步，延时在后台静默触发
    if (_syncConfig.autoSync && _syncConfig.isConfigured) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        performSync(silent: true);
      });
    }
  }

  void _invalidateCache() {
    _cachedFilteredRecords = null;
    _cachedActiveWeekCounts = null;
  }

  // ============================================
  // 筛选与排序
  // ============================================

  void setStatusFilter(String status) {
    if (_activeStatus == status) return;
    _activeStatus = status;
    _activeWeek = ''; // 切换主状态 Tab 时重置周几筛选，展示新状态的全量数据
    _currentPage = 1;
    _invalidateCache();
    notifyListeners();
  }

  void setWeekFilter(String week) {
    if (_activeWeek == week) return;
    _activeWeek = week;
    _currentPage = 1;
    _invalidateCache();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _currentPage = 1;
    _invalidateCache();
    notifyListeners();
  }

  void setSortBy(String sort) {
    if (_sortBy == sort) return;
    _sortBy = sort;
    _currentPage = 1;
    _invalidateCache();
    notifyListeners();
  }

  void loadMore() {
    if (hasMore) {
      _currentPage++;
      notifyListeners();
    }
  }

  /// 符合顶部筛选（状态与搜索匹配）的记录列表
  List<AnimeRecord> get _topFilteredRecords {
    List<AnimeRecord> list = _records;

    // 1. 顶部状态筛选
    if (_activeStatus != 'all') {
      list = list.where((r) => r.status == _activeStatus).toList();
    }

    // 2. 顶部搜索匹配（支持中文标题、日文标题、备注评价、标签模糊匹配）
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((r) {
        final matchZh = r.titleZh.toLowerCase().contains(q);
        final matchJa = r.titleJa.toLowerCase().contains(q);
        final matchNotes = r.notes.toLowerCase().contains(q);
        final matchTags = r.tags.any((t) => t.toLowerCase().contains(q));
        return matchZh || matchJa || matchNotes || matchTags;
      }).toList();
    }

    return list;
  }

  /// 过滤及排序后的所有符合条件的记录列表（带内存缓存保护）
  List<AnimeRecord> get filteredRecords {
    if (_cachedFilteredRecords != null) {
      return _cachedFilteredRecords!;
    }

    // 1. 顶部筛选结果
    List<AnimeRecord> list = _topFilteredRecords;

    // 2. 周几联动筛选（若当前选中的周几在当前顶部筛选下已无任何匹配记录，则回退为全部）
    final currentWeek = activeWeek;
    if (currentWeek.isNotEmpty) {
      list = list.where((r) => r.week == currentWeek).toList();
    }

    // 3. 排序
    final sorted = _sortList(list, _sortBy);
    _cachedFilteredRecords = sorted;
    return sorted;
  }

  List<AnimeRecord> _sortList(List<AnimeRecord> list, String sort) {
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

  /// 当前分页展示的可视记录
  List<AnimeRecord> get pagedRecords {
    final all = filteredRecords;
    final count = (_currentPage * pageSize).clamp(0, all.length);
    return all.take(count).toList();
  }

  /// 是否有更多数据待加载
  bool get hasMore => filteredRecords.length > pagedRecords.length;

  // ============================================
  // 统计概览计算
  // ============================================

  int get totalRecordsCount => _records.length;

  int get totalEpisodesWatched {
    return _records.fold(0, (sum, r) => sum + r.episodesWatched);
  }

  Map<String, int> get statusCounts {
    final counts = <String, int>{
      AnimeStatus.wantToWatchValue: 0,
      AnimeStatus.watchingValue: 0,
      AnimeStatus.watchedValue: 0,
      AnimeStatus.onHoldValue: 0,
      AnimeStatus.droppedValue: 0,
    };
    for (final r in _records) {
      counts[r.status] = (counts[r.status] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> get activeWeekCounts {
    if (_cachedActiveWeekCounts != null) {
      return _cachedActiveWeekCounts!;
    }

    final counts = <String, int>{};
    for (final r in _topFilteredRecords) {
      if (r.week.isNotEmpty && WeekDay.order.contains(r.week)) {
        counts[r.week] = (counts[r.week] ?? 0) + 1;
      }
    }
    _cachedActiveWeekCounts = counts;
    return counts;
  }

  // ============================================
  // CRUD 核心业务操作（内存乐观更新 + 异步持久化）
  // ============================================

  Future<AnimeRecord?> addRecord(AnimeRecord record) async {
    await flushPendingSaves();

    final now = DateTime.now().toIso8601String();
    final newRecord = record.copyWith(
      createdAt: record.createdAt.isEmpty ? now : record.createdAt,
      updatedAt: now,
    );

    // 1. 内存即时更新
    _records.insert(0, newRecord);
    _invalidateCache();
    notifyListeners();

    // 2. 后台异步持久化
    await storage.saveRecords(_records);
    await storage.clearDeletedTombstone(newRecord.id);

    return newRecord;
  }

  Future<AnimeRecord?> updateRecord(String id, AnimeRecord data) async {
    await flushPendingSaves();

    final index = _records.indexWhere((r) => r.id == id);
    if (index == -1) return null;

    final existing = _records[index];
    final updated = data.copyWith(
      id: existing.id,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
    );

    // 1. 内存即时更新
    _records[index] = updated;
    _invalidateCache();
    notifyListeners();

    // 2. 后台异步持久化
    await storage.saveRecords(_records);
    await storage.clearDeletedTombstone(id);

    return updated;
  }

  Future<bool> deleteRecord(String id) async {
    await flushPendingSaves();

    final index = _records.indexWhere((r) => r.id == id);
    if (index == -1) return false;

    // 1. 内存即时移除
    _records.removeAt(index);
    _invalidateCache();
    notifyListeners();

    // 2. 后台异步持久化与墓碑记录
    final ok = await storage.saveRecords(_records);
    if (ok) {
      await storage.recordDeletedTombstone(id);
    }
    return ok;
  }

  /// 快捷 +1 集（业务状态自动流转，支持 300ms 写入防抖）
  Future<({AnimeRecord? record, String? statusChangedMessage})> episodePlusOne(
    String id, {
    bool debounce = true,
  }) async {
    final index = _records.indexWhere((r) => r.id == id);
    if (index == -1) return (record: null, statusChangedMessage: null);

    final result = _records[index].incrementEpisode();
    final updated = result.record;

    // 1. 内存即时更新
    _records[index] = updated;
    _invalidateCache();
    notifyListeners();

    // 2. 存储持久化（若开启防抖则延时批量写入，否则立即同步持久化）
    if (debounce) {
      _scheduleDebouncedSave();
    } else {
      await flushPendingSaves();
      await storage.saveRecords(_records);
    }

    return (record: updated, statusChangedMessage: result.statusChangedMessage);
  }

  /// 拖动重排并持久化可见卡片相对顺序
  Future<void> reorder(int oldIndex, int newIndex) async {
    await flushPendingSaves();

    if (_sortBy != SortOption.defaultSort) {
      _sortBy = SortOption.defaultSort;
    }

    final currentPaged = List<AnimeRecord>.from(pagedRecords);
    if (oldIndex < 0 || oldIndex >= currentPaged.length) return;
    if (newIndex < 0 || newIndex > currentPaged.length) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final item = currentPaged.removeAt(oldIndex);
    currentPaged.insert(newIndex, item);

    final visibleSet = currentPaged.map((r) => r.id).toSet();
    int cursor = 0;
    _records = _records.map((r) {
      if (visibleSet.contains(r.id)) {
        return currentPaged[cursor++];
      }
      return r;
    }).toList();

    _invalidateCache();
    notifyListeners();

    await storage.saveRecords(_records);
  }

  // ============================================
  // 设置 & 导入导出
  // ============================================

  Future<void> setDefaultStatus(String status) async {
    await storage.saveDefaultStatus(status);
    notifyListeners();
  }

  String getDefaultStatus() {
    return storage.loadDefaultStatus();
  }

  Future<void> setSyncConfig(SyncConfig config) async {
    _syncConfig = config;
    await storage.saveSyncConfig(config);
    notifyListeners();
  }

  Future<bool> importRecords(List<AnimeRecord> records, {required bool replace}) async {
    await flushPendingSaves();

    if (replace) {
      _records = List.from(records);
    } else {
      final existingTitles = _records.map((r) => r.titleZh.trim().toLowerCase()).toSet();
      final existingIds = _records.map((r) => r.id).toSet();
      final merged = List<AnimeRecord>.from(_records);

      for (final r in records) {
        final titleKey = r.titleZh.trim().toLowerCase();
        if (!existingTitles.contains(titleKey) && !existingIds.contains(r.id)) {
          merged.add(r);
          existingTitles.add(titleKey);
          existingIds.add(r.id);
        }
      }
      _records = merged;
    }

    _invalidateCache();
    notifyListeners();

    return await storage.saveRecords(_records);
  }

  // ============================================
  // 云端同步
  // ============================================

  Future<({bool success, String message, bool isCliff, int baselineCount, int mergedCount})> performSync({
    bool silent = false,
    bool force = false,
  }) async {
    if (_isSyncing) {
      return (
        success: false,
        message: '同步正在进行中，请稍候...',
        isCliff: false,
        baselineCount: 0,
        mergedCount: 0,
      );
    }

    if (!_syncConfig.isConfigured) {
      return (
        success: false,
        message: '请先配置 GitHub Token 与 Gist ID',
        isCliff: false,
        baselineCount: 0,
        mergedCount: 0,
      );
    }

    await flushPendingSaves();

    try {
      _isSyncing = true;
      notifyListeners();

      final localRecords = _records;
      final localTombstones = storage.getTombstones();

      // 1. 拉取云端
      final remoteData = await _syncService.fetchRemoteGist(
        _syncConfig.token,
        _syncConfig.gistId,
      );

      // 2. 双向智能合并
      final mergeResult = _syncService.mergeSyncRecords(
        localRecords,
        remoteData.records,
        localTombstones,
        remoteData.tombstones,
        force: force,
      );

      // 3. 更新本地内存与持久化
      _records = mergeResult.mergedRecords;
      _invalidateCache();
      await storage.saveRecords(_records);
      await storage.saveTombstones(mergeResult.mergedTombstones);

      // 4. 回写至云端 Gist
      await _syncService.pushRemoteGist(
        _syncConfig.token,
        _syncConfig.gistId,
        mergeResult.mergedRecords,
        mergeResult.mergedTombstones,
      );

      // 5. 更新同步时间
      final now = DateTime.now().toIso8601String();
      final updatedConfig = _syncConfig.copyWith(lastSyncTime: now);
      await setSyncConfig(updatedConfig);

      final count = mergeResult.mergedRecords.length;
      return (
        success: true,
        message: '同步成功！共 $count 部番剧已与云端同步',
        isCliff: false,
        baselineCount: 0,
        mergedCount: 0,
      );
    } on SyncCliffException catch (cliff) {
      _lastErrorMessage = cliff.message;
      return (
        success: false,
        message: cliff.message,
        isCliff: true,
        baselineCount: cliff.baselineCount,
        mergedCount: cliff.mergedCount,
      );
    } catch (err) {
      final msg = err is SyncException ? err.message : err.toString().replaceFirst('Exception: ', '');
      _lastErrorMessage = msg;
      return (
        success: false,
        message: '同步失败：$msg',
        isCliff: false,
        baselineCount: 0,
        mergedCount: 0,
      );
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// 测试 Token
  Future<String> testToken(String token) async {
    return await _syncService.testGitHubToken(token);
  }

  /// 测试 Gist 连接并返回记录条数
  Future<int> checkGistCount(String token, String gistId) async {
    final remote = await _syncService.fetchRemoteGist(token, gistId);
    return remote.records.length;
  }

  /// 自动新建 Gist
  Future<String> autoCreateGist(String token) async {
    await flushPendingSaves();
    final tombstones = storage.getTombstones();
    final gistId = await _syncService.createSecretGist(token, _records, tombstones);

    final updated = _syncConfig.copyWith(
      token: token,
      gistId: gistId,
      lastSyncTime: DateTime.now().toIso8601String(),
    );
    await setSyncConfig(updated);
    return gistId;
  }

  @override
  void dispose() {
    if (_saveDebounceTimer != null) {
      _saveDebounceTimer!.cancel();
      _saveDebounceTimer = null;
      unawaited(storage.saveRecords(_records));
    }
    super.dispose();
  }
}
