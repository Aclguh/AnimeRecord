import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/anime_record.dart';
import '../models/app_constants.dart';
import '../models/sync_config.dart';

/// 本地持久化与偏好存储抽象接口（解耦底层存储实现，方便未来无缝迁移到 SQLite / Drift / Isar 数据库）
abstract interface class IStorageService {
  List<AnimeRecord> loadRecords();
  Future<bool> saveRecords(List<AnimeRecord> records);
  Future<AnimeRecord?> addRecord(AnimeRecord record);
  Future<AnimeRecord?> updateRecord(String id, AnimeRecord data);
  Future<bool> deleteRecord(String id);
  Future<bool> reorderRecords(List<String> visibleIds);

  Map<String, String> getTombstones();
  Future<void> saveTombstones(Map<String, String> tombstones);
  Future<void> recordDeletedTombstone(String id);
  Future<void> clearDeletedTombstone(String id);

  String loadDefaultStatus();
  Future<void> saveDefaultStatus(String status);
  String loadTheme();
  Future<void> saveTheme(String theme);
  String loadLocale();
  Future<void> saveLocale(String locale);
  bool loadFollowScreenRotation();
  Future<void> saveFollowScreenRotation(bool value);

  SyncConfig loadSyncConfig();
  Future<void> saveSyncConfig(SyncConfig config);

  /// 全量导出存储数据（用于平滑迁移或底层数据库迁移导出）
  Map<String, dynamic> exportAllStorageData();

  /// 全量恢复或迁移存储数据（用于从备份或旧存储引擎平滑迁入）
  Future<void> importAllStorageData(Map<String, dynamic> data);
}

/// 本地数据持久化服务（普通数据使用 SharedPreferences，敏感凭据使用硬件级 FlutterSecureStorage）
class StorageService implements IStorageService {
  static const String storageKey = 'anime-record-records';
  static const String backupKey = 'anime-record-records-backup';
  static const String rollingBackupPrefix = 'anime-record-records-backup-slot-';
  static const String rollingBackupIndexKey = 'anime-record-records-backup-index';
  static const int maxRollingBackups = 3;

  static const String versionKey = 'anime-record-version';
  static const String tombstonesKey = 'anime-record-tombstones';
  static const String defaultStatusKey = 'anime-record-default-status';
  static const String themeKey = 'theme';
  static const String localeKey = 'anime-record-locale';

  static const String syncTokenKey = 'anime-record-sync-token';
  static const String syncGistIdKey = 'anime-record-sync-gist-id';
  static const String syncAutoKey = 'anime-record-sync-auto';
  static const String syncLastTimeKey = 'anime-record-sync-last-time';
  static const String followScreenRotationKey = 'anime-record-follow-screen-rotation';

  static const int dataVersion = 1;
  static const String _tokenFallbackPrefix = 'enc:v1:';

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;
  String _cachedToken = '';

  StorageService(this._prefs, [FlutterSecureStorage? secureStorage])
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// 对降级存储的敏感 Token 进行轻量应用级加密混淆，杜绝明文凭据落盘
  static String _encryptFallback(String plain) {
    if (plain.isEmpty) return '';
    final bytes = utf8.encode(plain);
    // 使用应用内特征掩码进行可逆异或混淆
    const mask = 0x5A;
    final obfuscated = bytes.map((b) => b ^ mask).toList();
    return '$_tokenFallbackPrefix${base64Encode(obfuscated)}';
  }

  /// 解密还原降级存储的敏感 Token
  static String _decryptFallback(String cipher) {
    if (!cipher.startsWith(_tokenFallbackPrefix)) return cipher;
    try {
      final base64Str = cipher.substring(_tokenFallbackPrefix.length);
      final bytes = base64Decode(base64Str);
      const mask = 0x5A;
      final deobfuscated = bytes.map((b) => b ^ mask).toList();
      return utf8.decode(deobfuscated);
    } catch (_) {
      return '';
    }
  }

  static Future<StorageService> init({
    SharedPreferences? prefs,
    FlutterSecureStorage? secureStorage,
  }) async {
    final preferences = prefs ?? await SharedPreferences.getInstance();
    final secure = secureStorage ?? const FlutterSecureStorage();
    final service = StorageService(preferences, secure);

    // 1. 从硬件级安全存储读取敏感 GitHub Token
    try {
      final token = await secure.read(key: syncTokenKey);
      if (token != null && token.isNotEmpty) {
        service._cachedToken = token;
        // 确保清理历史残留的偏好键
        await preferences.remove(syncTokenKey);
      } else {
        // 检查是否存在降级或旧版明文存储
        final legacyToken = preferences.getString(syncTokenKey);
        if (legacyToken != null && legacyToken.isNotEmpty) {
          final actualToken = _decryptFallback(legacyToken);
          service._cachedToken = actualToken;
          try {
            await secure.write(key: syncTokenKey, value: actualToken);
            await preferences.remove(syncTokenKey);
          } catch (_) {
            // SecureStorage 仍不可用时，确保存储的是混淆密文而非裸明文
            if (!legacyToken.startsWith(_tokenFallbackPrefix)) {
              await preferences.setString(syncTokenKey, _encryptFallback(actualToken));
            }
          }
        }
      }
    } catch (e, st) {
      debugPrint('StorageService: SecureStorage 初始化异常，回退读取加密缓存: $e\n$st');
      final raw = preferences.getString(syncTokenKey) ?? '';
      service._cachedToken = _decryptFallback(raw);
    }

    return service;
  }

  // ============================================
  // 记录 CRUD
  // ============================================

  List<AnimeRecord> _parseJsonRecords(String raw) {
    if (raw.trim().isEmpty) return [];
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
  }

  /// 读取所有记录（优先从主存储加载，主存储损坏时依次从多版本循环滚动快照与容灾备份自愈修复）
  @override
  List<AnimeRecord> loadRecords() {
    final raw = _prefs.getString(storageKey);
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        return _parseJsonRecords(raw);
      } catch (e, st) {
        debugPrint('StorageService: 主存储数据损坏或反序列化失败: $e\n$st\n尝试从容灾备份快照恢复...');
      }
    }

    // 1. 优先尝试从多版本循环滚动快照自愈（从最新槽位倒序查找有效快照）
    final currentSlot = _prefs.getInt(rollingBackupIndexKey) ?? 0;
    for (int i = 0; i < maxRollingBackups; i++) {
      final slotIndex = (currentSlot - i + maxRollingBackups) % maxRollingBackups;
      final slotRaw = _prefs.getString('$rollingBackupPrefix$slotIndex');
      if (slotRaw != null && slotRaw.trim().isNotEmpty) {
        try {
          final restored = _parseJsonRecords(slotRaw);
          if (restored.isNotEmpty) {
            debugPrint('StorageService: 成功从滚动快照槽位 $slotIndex 恢复 ${restored.length} 条记录，自愈修复主存储...');
            _prefs.setString(storageKey, slotRaw);
            return restored;
          }
        } catch (_) {}
      }
    }

    // 2. 尝试从单版本备份快照恢复
    try {
      final backupRaw = _prefs.getString(backupKey);
      if (backupRaw != null && backupRaw.trim().isNotEmpty) {
        final restored = _parseJsonRecords(backupRaw);
        if (restored.isNotEmpty) {
          debugPrint('StorageService: 成功从备份快照恢复 ${restored.length} 条记录，正在自愈修复主存储...');
          _prefs.setString(storageKey, backupRaw);
          return restored;
        }
      }
    } catch (e, st) {
      debugPrint('StorageService: 备份快照恢复失败: $e\n$st');
    }

    return [];
  }

  /// 保存所有记录（在写入新记录前自动保留多版本滚动快照与容灾备份）
  @override
  Future<bool> saveRecords(List<AnimeRecord> records) async {
    try {
      // 1. 若当前主存储存在有效数据，转存为容灾备份快照并轮转滚动快照
      final currentRaw = _prefs.getString(storageKey);
      if (currentRaw != null && currentRaw.trim().isNotEmpty) {
        await _prefs.setString(backupKey, currentRaw);

        // 轮转推进循环滚动快照槽位
        final currentSlot = _prefs.getInt(rollingBackupIndexKey) ?? 0;
        final nextSlot = (currentSlot + 1) % maxRollingBackups;
        await _prefs.setString('$rollingBackupPrefix$nextSlot', currentRaw);
        await _prefs.setInt(rollingBackupIndexKey, nextSlot);
      }

      final jsonList = records.map((r) => r.toJson()).toList();
      final raw = jsonEncode(jsonList);
      await _prefs.setString(storageKey, raw);
      await _prefs.setInt(versionKey, dataVersion);
      return true;
    } catch (e, st) {
      debugPrint('StorageService: 保存记录失败: $e\n$st');
      return false;
    }
  }

  /// 添加单条记录（用于兼容独立调用）
  @override
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
  @override
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
  @override
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
  @override
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

  @override
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

  @override
  Future<void> saveTombstones(Map<String, String> tombstones) async {
    try {
      await _prefs.setString(tombstonesKey, jsonEncode(tombstones));
    } catch (e, st) {
      debugPrint('StorageService: 保存墓碑数据失败: $e\n$st');
    }
  }

  @override
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

  @override
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
  @override
  String loadDefaultStatus() {
    final v = _prefs.getString(defaultStatusKey);
    if (v != null && (v == 'all' || AnimeStatus.allValues.contains(v))) {
      return v;
    }
    return AnimeStatus.watchingValue;
  }

  @override
  Future<void> saveDefaultStatus(String status) async {
    await _prefs.setString(defaultStatusKey, status);
  }

  /// 读取主题
  @override
  String loadTheme() {
    return _prefs.getString(themeKey) ?? 'system';
  }

  @override
  Future<void> saveTheme(String theme) async {
    await _prefs.setString(themeKey, theme);
  }

  /// 读取语言设置（默认跟随系统 system，可选 zh, en）
  @override
  String loadLocale() {
    return _prefs.getString(localeKey) ?? 'system';
  }

  @override
  Future<void> saveLocale(String locale) async {
    await _prefs.setString(localeKey, locale);
  }

  /// 读取跟随屏幕选择/旋转设置（默认关闭）
  @override
  bool loadFollowScreenRotation() {
    return _prefs.getBool(followScreenRotationKey) ?? false;
  }

  @override
  Future<void> saveFollowScreenRotation(bool value) async {
    await _prefs.setBool(followScreenRotationKey, value);
  }

  // ============================================
  // 云端同步配置（敏感 Token 通过 SecureStorage 安全加密）
  // ============================================

  @override
  SyncConfig loadSyncConfig() {
    return SyncConfig(
      token: _cachedToken,
      gistId: _prefs.getString(syncGistIdKey) ?? '',
      autoSync: _prefs.getBool(syncAutoKey) ?? false,
      lastSyncTime: _prefs.getString(syncLastTimeKey) ?? '',
    );
  }

  @override
  Future<void> saveSyncConfig(SyncConfig config) async {
    final token = config.token.trim();
    _cachedToken = token;

    if (token.isEmpty) {
      try {
        await _secureStorage.delete(key: syncTokenKey);
      } catch (_) {}
      await _prefs.remove(syncTokenKey);
    } else {
      bool secureSaved = false;
      try {
        await _secureStorage.write(key: syncTokenKey, value: token);
        secureSaved = true;
        // 成功写入安全存储，移除偏好存储中可能存在的密文或明文，杜绝冗余落盘
        await _prefs.remove(syncTokenKey);
      } catch (e, st) {
        debugPrint('StorageService: 写入 SecureStorage 失败，应用轻量级混淆加密后降级写入 SharedPreferences: $e\n$st');
      }

      if (!secureSaved) {
        // 安全存储不可用时，存储混淆密文而非明文，防范未授权读取
        await _prefs.setString(syncTokenKey, _encryptFallback(token));
      }
    }

    await _prefs.setString(syncGistIdKey, config.gistId.trim());
    await _prefs.setBool(syncAutoKey, config.autoSync);
    await _prefs.setString(syncLastTimeKey, config.lastSyncTime);
  }

  // ============================================
  // 全量数据平滑迁移与备份支持
  // ============================================

  @override
  Map<String, dynamic> exportAllStorageData() {
    return {
      'version': dataVersion,
      'records': loadRecords().map((r) => r.toJson()).toList(),
      'tombstones': getTombstones(),
      'defaultStatus': loadDefaultStatus(),
      'theme': loadTheme(),
      'locale': loadLocale(),
      'followScreenRotation': loadFollowScreenRotation(),
      'syncConfig': loadSyncConfig().toJson(),
    };
  }

  @override
  Future<void> importAllStorageData(Map<String, dynamic> data) async {
    if (data['records'] is List) {
      final records = <AnimeRecord>[];
      for (final item in data['records'] as List) {
        if (item is Map) {
          records.add(AnimeRecord.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      await saveRecords(records);
    }
    if (data['tombstones'] is Map) {
      final tombstones = Map<String, String>.from(data['tombstones'] as Map);
      await saveTombstones(tombstones);
    }
    if (data['defaultStatus'] is String) {
      await saveDefaultStatus(data['defaultStatus'] as String);
    }
    if (data['theme'] is String) {
      await saveTheme(data['theme'] as String);
    }
    if (data['locale'] is String) {
      await saveLocale(data['locale'] as String);
    }
    if (data['followScreenRotation'] is bool) {
      await saveFollowScreenRotation(data['followScreenRotation'] as bool);
    }
    if (data['syncConfig'] is Map) {
      final config = SyncConfig.fromJson(Map<String, dynamic>.from(data['syncConfig'] as Map));
      await saveSyncConfig(config);
    }
  }
}
