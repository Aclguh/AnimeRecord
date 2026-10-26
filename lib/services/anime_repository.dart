import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/anime_record.dart';
import '../models/app_constants.dart';
import '../models/sync_config.dart';
import 'storage_service.dart';
import 'sync_service.dart';

/// 追番记录数据仓储（负责统筹底层本地持久化与云端 Gist 同步，维护数据单源真理 Single Source of Truth）
class AnimeRepository extends ChangeNotifier {
  final IStorageService storage;
  final SyncService _syncService;
  final Duration saveDebounceDuration;

  Timer? _saveDebounceTimer;
  List<AnimeRecord> _records = [];
  SyncConfig _syncConfig = const SyncConfig();
  bool _isSyncing = false;
  String? _lastErrorMessage;

  AnimeRepository({
    required this.storage,
    SyncService? syncService,
    this.saveDebounceDuration = const Duration(milliseconds: 300),
  }) : _syncService = syncService ?? SyncService() {
    _init();
  }

  // Getters
  List<AnimeRecord> get records => List.unmodifiable(_records);
  SyncConfig get syncConfig => _syncConfig;
  bool get isSyncing => _isSyncing;
  String? get lastErrorMessage => _lastErrorMessage;
  bool get hasPendingSave => _saveDebounceTimer != null;

  void _init() {
    _syncConfig = storage.loadSyncConfig();
    _records = storage.loadRecords();

    // 如果开启自动同步且已配置，后台静默触发
    if (_syncConfig.autoSync && _syncConfig.isConfigured) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        performSync(silent: true);
      });
    }
  }

  /// 立即刷盘挂起的防抖写入
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

  // ============================================
  // CRUD 核心业务
  // ============================================

  Future<AnimeRecord?> addRecord(AnimeRecord record) async {
    await flushPendingSaves();

    final now = DateTime.now().toIso8601String();
    final newRecord = record.copyWith(
      createdAt: record.createdAt.isEmpty ? now : record.createdAt,
      updatedAt: now,
    );

    _records.insert(0, newRecord);
    notifyListeners();

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

    _records[index] = updated;
    notifyListeners();

    await storage.saveRecords(_records);
    await storage.clearDeletedTombstone(id);

    return updated;
  }

  Future<bool> deleteRecord(String id) async {
    await flushPendingSaves();

    final index = _records.indexWhere((r) => r.id == id);
    if (index == -1) return false;

    _records.removeAt(index);
    notifyListeners();

    final ok = await storage.saveRecords(_records);
    if (ok) {
      await storage.recordDeletedTombstone(id);
    }
    return ok;
  }

  /// 快捷 +1 集（业务状态自动流转，支持写入防抖与强类型状态流转事件）
  Future<({AnimeRecord? record, String? statusChangedMessage, WatchStatus? transitionedStatus})> episodePlusOne(
    String id, {
    bool debounce = true,
  }) async {
    final index = _records.indexWhere((r) => r.id == id);
    if (index == -1) return (record: null, statusChangedMessage: null, transitionedStatus: null);

    final result = _records[index].incrementEpisode();
    final updated = result.record;

    _records[index] = updated;
    notifyListeners();

    if (debounce) {
      _scheduleDebouncedSave();
    } else {
      await flushPendingSaves();
      await storage.saveRecords(_records);
    }

    return (
      record: updated,
      statusChangedMessage: result.statusChangedMessage,
      transitionedStatus: result.transitionedStatus,
    );
  }

  /// 重新排列当前展示记录对应的物理存储顺序
  Future<void> reorderPagedSubset({
    required int oldIndex,
    required int newIndex,
    required List<AnimeRecord> currentPaged,
  }) async {
    await flushPendingSaves();

    if (oldIndex < 0 || oldIndex >= currentPaged.length) return;
    if (newIndex < 0 || newIndex > currentPaged.length) return;

    final paged = List<AnimeRecord>.from(currentPaged);
    var targetIndex = newIndex;
    if (oldIndex < targetIndex) {
      targetIndex -= 1;
    }

    final item = paged.removeAt(oldIndex);
    paged.insert(targetIndex, item);

    final visibleSet = paged.map((r) => r.id).toSet();
    int cursor = 0;
    _records = _records.map((r) {
      if (visibleSet.contains(r.id)) {
        return paged[cursor++];
      }
      return r;
    }).toList();

    notifyListeners();
    await storage.saveRecords(_records);
  }

  // ============================================
  // 偏好与导入导出
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

  Future<bool> importRecords(List<AnimeRecord> incoming, {required bool replace}) async {
    await flushPendingSaves();

    if (replace) {
      _records = List.from(incoming);
    } else {
      final existingTitles = _records.map((r) => r.titleZh.trim().toLowerCase()).toSet();
      final existingIds = _records.map((r) => r.id).toSet();
      final merged = List<AnimeRecord>.from(_records);

      for (final r in incoming) {
        final titleKey = r.titleZh.trim().toLowerCase();
        if (!existingTitles.contains(titleKey) && !existingIds.contains(r.id)) {
          merged.add(r);
          existingTitles.add(titleKey);
          existingIds.add(r.id);
        }
      }
      _records = merged;
    }

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

      // 2. 双向合并
      final mergeResult = _syncService.mergeSyncRecords(
        localRecords,
        remoteData.records,
        localTombstones,
        remoteData.tombstones,
        force: force,
      );

      // 3. 更新本地与墓碑
      _records = mergeResult.mergedRecords;
      await storage.saveRecords(_records);
      await storage.saveTombstones(mergeResult.mergedTombstones);

      // 4. 回写云端
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

  Future<String> testToken(String token) async {
    return await _syncService.testGitHubToken(token);
  }

  Future<int> checkGistCount(String token, String gistId) async {
    final remote = await _syncService.fetchRemoteGist(token, gistId);
    return remote.records.length;
  }

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
