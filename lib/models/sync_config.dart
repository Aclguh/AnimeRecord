import 'anime_record.dart';

/// GitHub Gist 云同步配置
class SyncConfig {
  final String token;
  final String gistId;
  final bool autoSync;
  final String lastSyncTime;

  const SyncConfig({
    this.token = '',
    this.gistId = '',
    this.autoSync = false,
    this.lastSyncTime = '',
  });

  SyncConfig copyWith({
    String? token,
    String? gistId,
    bool? autoSync,
    String? lastSyncTime,
  }) {
    return SyncConfig(
      token: token ?? this.token,
      gistId: gistId ?? this.gistId,
      autoSync: autoSync ?? this.autoSync,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }

  bool get isConfigured => token.trim().isNotEmpty && gistId.trim().isNotEmpty;
}

/// 同步合并结果
class SyncMergeResult {
  final List<AnimeRecord> mergedRecords;
  final Map<String, String> mergedTombstones;
  final bool hasChanges;
  final int pulledCount;
  final int pushedCount;

  const SyncMergeResult({
    required this.mergedRecords,
    required this.mergedTombstones,
    required this.hasChanges,
    required this.pulledCount,
    required this.pushedCount,
  });
}
