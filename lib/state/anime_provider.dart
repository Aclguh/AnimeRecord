import 'package:flutter/foundation.dart';
import '../models/anime_record.dart';
import '../models/app_constants.dart';
import '../models/sync_config.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';

/// 追番记录核心状态管理
class AnimeProvider extends ChangeNotifier {
  final StorageService storage;
  final SyncService _syncService;

  List<AnimeRecord> _records = [];
  String _activeStatus = AnimeStatus.watching;
  String _activeWeek = '';
  String _searchQuery = '';
  String _sortBy = SortOption.defaultSort;

  int _currentPage = 1;
  static const int pageSize = 20;

  bool _isSyncing = false;
  SyncConfig _syncConfig = const SyncConfig();

  String? _lastErrorMessage;

  AnimeProvider({
    required this.storage,
    SyncService? syncService,
  }) : _syncService = syncService ?? SyncService() {
    _init();
  }

  // Getters
  List<AnimeRecord> get allRecords => _records;
  String get activeStatus => _activeStatus;
  String get activeWeek => _activeWeek;
  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;
  bool get isSyncing => _isSyncing;
  SyncConfig get syncConfig => _syncConfig;
  String? get lastErrorMessage => _lastErrorMessage;

  void _init() {
    _activeStatus = storage.loadDefaultStatus();
    _syncConfig = storage.loadSyncConfig();
    _records = storage.loadRecords();

    // 如果开启自动同步，延时在后台静默触发
    if (_syncConfig.autoSync && _syncConfig.isConfigured) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        performSync(silent: true);
      });
    }
  }

  // ============================================
  // 筛选与排序
  // ============================================

  void setStatusFilter(String status) {
    if (_activeStatus == status) return;
    _activeStatus = status;
    _currentPage = 1;
    notifyListeners();
  }

  void setWeekFilter(String week) {
    if (_activeWeek == week) return;
    _activeWeek = week;
    _currentPage = 1;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _currentPage = 1;
    notifyListeners();
  }

  void setSortBy(String sort) {
    if (_sortBy == sort) return;
    _sortBy = sort;
    _currentPage = 1;
    notifyListeners();
  }

  void loadMore() {
    if (hasMore) {
      _currentPage++;
      notifyListeners();
    }
  }

  /// 过滤及排序后的所有符合条件的记录列表
  List<AnimeRecord> get filteredRecords {
    List<AnimeRecord> list = List.from(_records);

    // 1. 状态筛选
    if (_activeStatus != 'all') {
      list = list.where((r) => r.status == _activeStatus).toList();
    }

    // 2. 周几筛选
    if (_activeWeek.isNotEmpty) {
      list = list.where((r) => r.week == _activeWeek).toList();
    }

    // 3. 搜索匹配
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

    // 4. 排序
    return _sortList(list, _sortBy);
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
        // 默认排序：状态权重 + 创建时间倒序
        sorted.sort((a, b) {
          final orderA = AnimeStatus.getOrder(a.status);
          final orderB = AnimeStatus.getOrder(b.status);
          if (orderA != orderB) {
            return orderA.compareTo(orderB);
          }
          return b.createdAt.compareTo(a.createdAt);
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
      AnimeStatus.wantToWatch: 0,
      AnimeStatus.watching: 0,
      AnimeStatus.watched: 0,
      AnimeStatus.onHold: 0,
      AnimeStatus.dropped: 0,
    };
    for (final r in _records) {
      counts[r.status] = (counts[r.status] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> get activeWeekCounts {
    final counts = <String, int>{};
    for (final r in _records) {
      if (r.week.isNotEmpty && WeekDay.order.contains(r.week)) {
        counts[r.week] = (counts[r.week] ?? 0) + 1;
      }
    }
    return counts;
  }

  // ============================================
  // CRUD 操作
  // ============================================

  Future<AnimeRecord?> addRecord(AnimeRecord record) async {
    final created = await storage.addRecord(record);
    if (created != null) {
      _records = storage.loadRecords();
      notifyListeners();
    }
    return created;
  }

  Future<AnimeRecord?> updateRecord(String id, AnimeRecord data) async {
    final updated = await storage.updateRecord(id, data);
    if (updated != null) {
      _records = storage.loadRecords();
      notifyListeners();
    }
    return updated;
  }

  Future<bool> deleteRecord(String id) async {
    final success = await storage.deleteRecord(id);
    if (success) {
      _records = storage.loadRecords();
      notifyListeners();
    }
    return success;
  }

  /// 快捷 +1 集
  Future<({AnimeRecord? record, String? statusChangedMessage})> episodePlusOne(String id) async {
    final index = _records.indexWhere((r) => r.id == id);
    if (index == -1) return (record: null, statusChangedMessage: null);

    final record = _records[index];
    int newWatched = record.episodesWatched + 1;
    String newStatus = record.status;
    String newEndDate = record.endDate;

    // 状态自动切换：想看 / 搁置 时点 +1 自动变为在看
    if (record.status == AnimeStatus.wantToWatch || record.status == AnimeStatus.onHold) {
      newStatus = AnimeStatus.watching;
    }

    // 达到总集数时自动标记为看过
    if (record.episodesTotal > 0 && newWatched >= record.episodesTotal) {
      newStatus = AnimeStatus.watched;
      newEndDate = DateTime.now().toIso8601String().split('T').first;
      newWatched = record.episodesTotal;
    }

    final updated = record.copyWith(
      episodesWatched: newWatched,
      status: newStatus,
      endDate: newEndDate,
    );

    final res = await storage.updateRecord(id, updated);
    if (res != null) {
      _records = storage.loadRecords();
      notifyListeners();

      String? msg;
      if (newStatus != record.status) {
        if (newStatus == AnimeStatus.watched) {
          msg = '「${res.titleZh}」已追完';
        } else if (newStatus == AnimeStatus.watching) {
          msg = '「${res.titleZh}」状态已切换为「在看」';
        }
      }
      return (record: res, statusChangedMessage: msg);
    }
    return (record: null, statusChangedMessage: null);
  }

  /// 拖动重排并持久化可见卡片相对顺序
  Future<void> reorder(int oldIndex, int newIndex) async {
    if (_sortBy != SortOption.defaultSort) {
      _sortBy = SortOption.defaultSort;
    }

    final currentPaged = pagedRecords;
    if (oldIndex < 0 || oldIndex >= currentPaged.length) return;
    if (newIndex < 0 || newIndex > currentPaged.length) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final item = currentPaged.removeAt(oldIndex);
    currentPaged.insert(newIndex, item);

    final orderedIds = currentPaged.map((r) => r.id).toList();
    await storage.reorderRecords(orderedIds);
    _records = storage.loadRecords();
    notifyListeners();
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
    bool ok;
    if (replace) {
      ok = await storage.saveRecords(records);
    } else {
      final current = storage.loadRecords();
      final existingTitles = current.map((r) => r.titleZh.trim().toLowerCase()).toSet();
      final merged = List<AnimeRecord>.from(current);

      for (final r in records) {
        if (!existingTitles.contains(r.titleZh.trim().toLowerCase())) {
          merged.add(r);
          existingTitles.add(r.titleZh.trim().toLowerCase());
        }
      }
      ok = await storage.saveRecords(merged);
    }

    if (ok) {
      _records = storage.loadRecords();
      notifyListeners();
    }
    return ok;
  }

  // ============================================
  // 云端同步
  // ============================================

  Future<({bool success, String message})> performSync({bool silent = false}) async {
    if (_isSyncing) {
      return (success: false, message: '同步正在进行中，请稍候...');
    }

    if (!_syncConfig.isConfigured) {
      return (success: false, message: '请先配置 GitHub Token 与 Gist ID');
    }

    try {
      _isSyncing = true;
      notifyListeners();

      final localRecords = storage.loadRecords();
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
      );

      // 3. 保存至本地
      await storage.saveRecords(mergeResult.mergedRecords);
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

      _records = storage.loadRecords();
      notifyListeners();

      final count = mergeResult.mergedRecords.length;
      return (success: true, message: '同步成功！共 $count 部番剧已与云端同步');
    } catch (err) {
      final msg = err.toString().replaceFirst('Exception: ', '');
      _lastErrorMessage = msg;
      return (success: false, message: '同步失败：$msg');
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
    final records = storage.loadRecords();
    final tombstones = storage.getTombstones();
    final gistId = await _syncService.createSecretGist(token, records, tombstones);

    final updated = _syncConfig.copyWith(
      token: token,
      gistId: gistId,
      lastSyncTime: DateTime.now().toIso8601String(),
    );
    await setSyncConfig(updated);
    return gistId;
  }
}
