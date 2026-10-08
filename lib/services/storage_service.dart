import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/anime_record.dart';
import '../models/app_constants.dart';
import '../models/sync_config.dart';

/// 本地数据持久化服务（基于 SharedPreferences，完美适配全平台）
class StorageService {
  static const String storageKey = 'anime-record-records';
  static const String versionKey = 'anime-record-version';
  static const String tombstonesKey = 'anime-record-tombstones';
  static const String defaultStatusKey = 'anime-record-default-status';
  static const String themeKey = 'theme';

  static const String syncTokenKey = 'anime-record-sync-token';
  static const String syncGistIdKey = 'anime-record-sync-gist-id';
  static const String syncAutoKey = 'anime-record-sync-auto';
  static const String syncLastTimeKey = 'anime-record-sync-last-time';

  static const int dataVersion = 1;

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // ============================================
  // 记录 CRUD
  // ============================================

  /// 读取所有记录
  List<AnimeRecord> loadRecords() {
    try {
      final raw = _prefs.getString(storageKey);
      if (raw == null || raw.trim().isEmpty) return [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      return decoded
          .map((item) {
            if (item is Map<String, dynamic>) {
              return AnimeRecord.fromJson(item);
            } else if (item is Map) {
              return AnimeRecord.fromJson(Map<String, dynamic>.from(item));
            }
            return null;
          })
          .whereType<AnimeRecord>()
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 保存所有记录
  Future<bool> saveRecords(List<AnimeRecord> records) async {
    try {
      final jsonList = records.map((r) => r.toJson()).toList();
      final raw = jsonEncode(jsonList);
      await _prefs.setString(storageKey, raw);
      await _prefs.setInt(versionKey, dataVersion);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 添加单条记录
  Future<AnimeRecord?> addRecord(AnimeRecord record) async {
    final records = loadRecords();
    final now = DateTime.now().toIso8601String();
    final newRecord = record.copyWith(
      createdAt: record.createdAt.isEmpty ? now : record.createdAt,
      updatedAt: now,
    );
    records.insert(0, newRecord);
    final ok = await saveRecords(records);
    if (ok) {
      await clearDeletedTombstone(newRecord.id);
      return newRecord;
    }
    return null;
  }

  /// 更新单条记录
  Future<AnimeRecord?> updateRecord(String id, AnimeRecord data) async {
    final records = loadRecords();
    final index = records.indexWhere((r) => r.id == id);
    if (index == -1) return null;

    final existing = records[index];
    final updated = data.copyWith(
      id: existing.id,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
    );
    records[index] = updated;

    final ok = await saveRecords(records);
    if (ok) {
      await clearDeletedTombstone(id);
      return updated;
    }
    return null;
  }

  /// 删除记录
  Future<bool> deleteRecord(String id) async {
    final records = loadRecords();
    final index = records.indexWhere((r) => r.id == id);
    if (index == -1) return false;

    records.removeAt(index);
    final ok = await saveRecords(records);
    if (ok) {
      await recordDeletedTombstone(id);
      return true;
    }
    return false;
  }

  /// 依据可视 ID 调整排序顺序
  Future<bool> reorderRecords(List<String> visibleIds) async {
    final records = loadRecords();
    final moved = <AnimeRecord>[];
    final movedIds = <String>{};

    for (final id in visibleIds) {
      if (movedIds.contains(id)) continue;
      final match = records.cast<AnimeRecord?>().firstWhere(
            (r) => r?.id == id,
            orElse: () => null,
          );
      if (match != null) {
        moved.add(match);
        movedIds.add(id);
      }
    }

    if (moved.length < 2) return true;

    int cursor = 0;
    final next = records.map((r) {
      if (movedIds.contains(r.id)) {
        return moved[cursor++];
      }
      return r;
    }).toList();

    return saveRecords(next);
  }

  // ============================================
  // 墓碑管理（防止已删除记录多端复活）
  // ============================================

  Map<String, String> getTombstones() {
    try {
      final raw = _prefs.getString(tombstonesKey);
      if (raw == null) return {};
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  Future<void> saveTombstones(Map<String, String> tombstones) async {
    try {
      await _prefs.setString(tombstonesKey, jsonEncode(tombstones));
    } catch (_) {}
  }

  Future<void> recordDeletedTombstone(String id) async {
    final tombstones = getTombstones();
    tombstones[id] = DateTime.now().toIso8601String();

    // 清理 60 天前的旧墓碑
    final cutoff = DateTime.now().subtract(const Duration(days: 60));
    tombstones.removeWhere((k, timeStr) {
      final time = DateTime.tryParse(timeStr);
      return time != null && time.isBefore(cutoff);
    });

    await saveTombstones(tombstones);
  }

  Future<void> clearDeletedTombstone(String id) async {
    final tombstones = getTombstones();
    if (tombstones.containsKey(id)) {
      tombstones.remove(id);
      await saveTombstones(tombstones);
    }
  }

  // ============================================
  // 偏好设置
  // ============================================

  /// 读取默认打开状态
  String loadDefaultStatus() {
    final v = _prefs.getString(defaultStatusKey);
    if (v != null && (v == 'all' || AnimeStatus.allValues.contains(v))) {
      return v;
    }
    return AnimeStatus.watching;
  }

  Future<void> saveDefaultStatus(String status) async {
    await _prefs.setString(defaultStatusKey, status);
  }

  /// 读取主题
  String loadTheme() {
    return _prefs.getString(themeKey) ?? 'system';
  }

  Future<void> saveTheme(String theme) async {
    await _prefs.setString(themeKey, theme);
  }

  // ============================================
  // 同步配置
  // ============================================

  SyncConfig loadSyncConfig() {
    return SyncConfig(
      token: _prefs.getString(syncTokenKey) ?? '',
      gistId: _prefs.getString(syncGistIdKey) ?? '',
      autoSync: _prefs.getBool(syncAutoKey) ?? false,
      lastSyncTime: _prefs.getString(syncLastTimeKey) ?? '',
    );
  }

  Future<void> saveSyncConfig(SyncConfig config) async {
    await _prefs.setString(syncTokenKey, config.token.trim());
    await _prefs.setString(syncGistIdKey, config.gistId.trim());
    await _prefs.setBool(syncAutoKey, config.autoSync);
    await _prefs.setString(syncLastTimeKey, config.lastSyncTime);
  }
}
