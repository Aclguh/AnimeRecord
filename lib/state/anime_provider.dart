import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/anime_record.dart';
import '../models/app_constants.dart';
import '../models/sync_config.dart';
import '../services/anime_repository.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';
import 'anime_filter_controller.dart';

/// 追番记录核心状态管理门面（Facade 模式统筹 AnimeRepository 数据层与 AnimeFilterController 展示过滤层）
class AnimeProvider extends ChangeNotifier {
  final IStorageService storage;
  final Duration saveDebounceDuration;

  final AnimeRepository _repository;
  final AnimeFilterController _filterController;
  final bool _ownsRepository;
  final bool _ownsFilterController;

  AnimeProvider({
    required this.storage,
    SyncService? syncService,
    AnimeRepository? repository,
    AnimeFilterController? filterController,
    this.saveDebounceDuration = const Duration(milliseconds: 300),
  })  : _ownsRepository = repository == null,
        _ownsFilterController = filterController == null,
        _repository = repository ??
            AnimeRepository(
              storage: storage,
              syncService: syncService,
              saveDebounceDuration: saveDebounceDuration,
            ),
        _filterController = filterController ??
            AnimeFilterController(
              initialStatus: storage.loadDefaultStatus(),
            ) {
    _repository.addListener(_onRepositoryChanged);
    _filterController.addListener(_onFilterChanged);
  }

  // 子控制器暴露（供未来细粒度局部消费）
  AnimeRepository get repository => _repository;
  AnimeFilterController get filterController => _filterController;

  // 数据层状态代理
  List<AnimeRecord> get allRecords => _repository.records;
  bool get isSyncing => _repository.isSyncing;
  SyncConfig get syncConfig => _repository.syncConfig;
  String? get lastErrorMessage => _repository.lastErrorMessage;
  bool get hasPendingSave => _repository.hasPendingSave;

  // 过滤展示层状态代理
  String get activeStatus => _filterController.activeStatus;
  String get activeWeek {
    final week = _filterController.activeWeek;
    if (week.isNotEmpty && (activeWeekCounts[week] ?? 0) == 0) {
      return '';
    }
    return week;
  }

  String get searchQuery => _filterController.searchQuery;
  String get sortBy => _filterController.sortBy;

  /// 计算后的完整符合条件记录列表
  List<AnimeRecord> get filteredRecords => _filterController.filterAndSort(_repository.records);

  /// 当前分页展示的可视记录
  List<AnimeRecord> get pagedRecords => _filterController.getPaged(filteredRecords);

  /// 是否有更多数据待加载
  bool get hasMore => _filterController.hasMore(filteredRecords);

  // 统计概览计算
  int get totalRecordsCount => _repository.records.length;
  int get totalEpisodesWatched => _repository.records.fold(0, (sum, r) => sum + r.episodesWatched);
  Map<String, int> get statusCounts => AnimeFilterController.computeStatusCounts(_repository.records);
  Map<String, int> get activeWeekCounts => _filterController.computeActiveWeekCounts(_repository.records);

  void _onRepositoryChanged() {
    _filterController.invalidateCache();
    notifyListeners();
  }

  void _onFilterChanged() {
    notifyListeners();
  }

  // ============================================
  // 筛选与排序交互
  // ============================================

  void setStatusFilter(String status) => _filterController.setStatusFilter(status);
  void setWeekFilter(String week) => _filterController.setWeekFilter(week);
  void setSearchQuery(String query) => _filterController.setSearchQuery(query);
  void setSortBy(String sort) => _filterController.setSortBy(sort);
  void loadMore() => _filterController.loadMore(filteredRecords.length);

  // ============================================
  // 数据增删改查业务交互
  // ============================================

  Future<void> flushPendingSaves() => _repository.flushPendingSaves();

  Future<AnimeRecord?> addRecord(AnimeRecord record) => _repository.addRecord(record);

  Future<AnimeRecord?> updateRecord(String id, AnimeRecord data) => _repository.updateRecord(id, data);

  Future<bool> deleteRecord(String id) => _repository.deleteRecord(id);

  Future<({AnimeRecord? record, String? statusChangedMessage, WatchStatus? transitionedStatus})> episodePlusOne(
    String id, {
    bool debounce = true,
  }) =>
      _repository.episodePlusOne(id, debounce: debounce);

  /// 拖拽重排并持久化
  Future<void> reorder(int oldIndex, int newIndex) async {
    if (_filterController.sortBy != SortOption.defaultSort) {
      _filterController.setSortBy(SortOption.defaultSort);
    }
    await _repository.reorderPagedSubset(
      oldIndex: oldIndex,
      newIndex: newIndex,
      currentPaged: pagedRecords,
    );
  }

  // ============================================
  // 偏好设置与导入导出
  // ============================================

  Future<void> setDefaultStatus(String status) => _repository.setDefaultStatus(status);
  String getDefaultStatus() => _repository.getDefaultStatus();
  Future<void> setSyncConfig(SyncConfig config) => _repository.setSyncConfig(config);
  Future<bool> importRecords(List<AnimeRecord> records, {required bool replace}) =>
      _repository.importRecords(records, replace: replace);

  // ============================================
  // 云端同步
  // ============================================

  Future<({bool success, String message, bool isCliff, int baselineCount, int mergedCount})> performSync({
    bool silent = false,
    bool force = false,
  }) =>
      _repository.performSync(silent: silent, force: force);

  Future<String> testToken(String token) => _repository.testToken(token);
  Future<int> checkGistCount(String token, String gistId) => _repository.checkGistCount(token, gistId);
  Future<String> autoCreateGist(String token) => _repository.autoCreateGist(token);

  @override
  void dispose() {
    _repository.removeListener(_onRepositoryChanged);
    _filterController.removeListener(_onFilterChanged);

    if (_ownsRepository) {
      _repository.dispose();
    }
    if (_ownsFilterController) {
      _filterController.dispose();
    }
    super.dispose();
  }
}
