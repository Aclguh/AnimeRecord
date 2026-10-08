import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/anime_record.dart';
import '../models/sync_config.dart';

/// GitHub Secret Gist 云同步服务
class SyncService {
  static const String gistDataFilename = 'anime-record-data.json';

  final http.Client _client;

  SyncService([http.Client? client]) : _client = client ?? http.Client();

  /// 提取规范的 Gist ID（支持纯 ID 或网页 URL）
  static String cleanGistId(String raw) {
    if (raw.trim().isEmpty) return '';
    final val = raw.trim();
    final reg = RegExp(r'gist\.github\.com\/(?:[^/]+\/)?([a-f0-9]+)', caseSensitive: false);
    final match = reg.firstMatch(val);
    if (match != null) {
      return match.group(1) ?? '';
    }
    return val.replaceAll(RegExp(r'^\/|\/$'), '');
  }

  /// 统一的 GitHub API 请求封装
  Future<dynamic> _requestGitHub(
    String endpoint,
    String token, {
    String method = 'GET',
    Map<String, String>? headers,
    String? body,
  }) async {
    final trimmedToken = token.trim();
    if (trimmedToken.isEmpty) {
      throw Exception('未提供 GitHub Token');
    }

    final url = endpoint.startsWith('http')
        ? Uri.parse(endpoint)
        : Uri.parse('https://api.github.com$endpoint');

    final requestHeaders = {
      'Accept': 'application/vnd.github+json',
      'Authorization': 'Bearer $trimmedToken',
      'X-GitHub-Api-Version': '2022-11-28',
      ...?headers,
    };

    http.Response res;
    if (method == 'POST') {
      res = await _client.post(url, headers: requestHeaders, body: body);
    } else if (method == 'PATCH') {
      res = await _client.patch(url, headers: requestHeaders, body: body);
    } else {
      res = await _client.get(url, headers: requestHeaders);
    }

    if (res.statusCode == 401) {
      throw Exception('GitHub Token 无效或已过期，请检查 Token 权限');
    }
    if (res.statusCode == 403) {
      throw Exception('GitHub API 访问被拒绝或达到速率限制，请检查 Token 的 gist 权限');
    }
    if (res.statusCode == 404) {
      throw Exception('未找到指定的云端 Gist，请检查 Gist ID 是否正确');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      try {
        final errJson = jsonDecode(res.body);
        final msg = errJson['message'] ?? 'GitHub 请求失败 (${res.statusCode})';
        throw Exception(msg);
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('GitHub 请求失败 (${res.statusCode})');
      }
    }

    if (res.statusCode == 204) return null;
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  /// 测试 GitHub Token 有效性
  Future<String> testGitHubToken(String token) async {
    final user = await _requestGitHub('/user', token);
    return user['login']?.toString() ?? 'GitHub User';
  }

  /// 在云端创建私有 Gist
  Future<String> createSecretGist(
    String token,
    List<AnimeRecord> records,
    Map<String, String> tombstones,
  ) async {
    final now = DateTime.now().toIso8601String();
    final contentObj = {
      'version': 1,
      'updatedAt': now,
      'records': records.map((r) => r.toJson()).toList(),
      'tombstones': tombstones,
    };

    final payload = {
      'description': 'Anime Record 追番记录数据备份与同步',
      'public': false,
      'files': {
        gistDataFilename: {
          'content': const JsonEncoder.withIndent('  ').convert(contentObj),
        }
      }
    };

    final result = await _requestGitHub(
      '/gists',
      token,
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    final id = result['id']?.toString();
    if (id == null || id.isEmpty) {
      throw Exception('创建 Gist 失败：未返回有效 ID');
    }
    return id;
  }

  /// 从 Gist 拉取数据
  Future<({List<AnimeRecord> records, Map<String, String> tombstones, String? updatedAt})>
      fetchRemoteGist(String token, String gistId) async {
    final cleanId = cleanGistId(gistId);
    if (cleanId.isEmpty) throw Exception('缺少 Gist ID');

    final gist = await _requestGitHub('/gists/$cleanId', token);
    if (gist == null || gist['files'] == null) {
      throw Exception('Gist 数据格式异常：未包含文件');
    }

    final files = gist['files'] as Map<String, dynamic>;
    dynamic targetFile = files[gistDataFilename];

    if (targetFile == null) {
      for (final key in files.keys) {
        if (key.endsWith('.json')) {
          targetFile = files[key];
          break;
        }
      }
    }

    if (targetFile == null) {
      return (records: <AnimeRecord>[], tombstones: <String, String>{}, updatedAt: null);
    }

    String content = targetFile['content']?.toString() ?? '';
    final bool isTruncated = targetFile['truncated'] == true;
    final String? rawUrl = targetFile['raw_url']?.toString();

    if (isTruncated && rawUrl != null && rawUrl.isNotEmpty) {
      final rawRes = await _client.get(Uri.parse(rawUrl));
      if (rawRes.statusCode == 200) {
        content = utf8.decode(rawRes.bodyBytes);
      }
    }

    if (content.trim().isEmpty) {
      return (records: <AnimeRecord>[], tombstones: <String, String>{}, updatedAt: null);
    }

    try {
      final parsed = jsonDecode(content);
      List<AnimeRecord> records = [];
      Map<String, String> tombstones = {};
      String? updatedAt;

      if (parsed is Map) {
        if (parsed['records'] is List) {
          records = (parsed['records'] as List)
              .whereType<Map>()
              .map((m) => AnimeRecord.fromJson(Map<String, dynamic>.from(m)))
              .toList();
        }
        if (parsed['tombstones'] is Map) {
          tombstones = (parsed['tombstones'] as Map)
              .map((k, v) => MapEntry(k.toString(), v.toString()));
        }
        updatedAt = parsed['updatedAt']?.toString();
      } else if (parsed is List) {
        records = parsed
            .whereType<Map>()
            .map((m) => AnimeRecord.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }

      return (records: records, tombstones: tombstones, updatedAt: updatedAt);
    } catch (_) {
      throw Exception('Gist 中的数据不是有效的 JSON 格式');
    }
  }

  /// 推送数据至云端 Gist
  Future<void> pushRemoteGist(
    String token,
    String gistId,
    List<AnimeRecord> records,
    Map<String, String> tombstones,
  ) async {
    final cleanId = cleanGistId(gistId);
    if (cleanId.isEmpty) throw Exception('缺少 Gist ID');

    final now = DateTime.now().toIso8601String();
    final contentObj = {
      'version': 1,
      'updatedAt': now,
      'records': records.map((r) => r.toJson()).toList(),
      'tombstones': tombstones,
    };

    final payload = {
      'description': 'Anime Record 追番记录数据备份与同步',
      'files': {
        gistDataFilename: {
          'content': const JsonEncoder.withIndent('  ').convert(contentObj),
        }
      }
    };

    await _requestGitHub(
      '/gists/$cleanId',
      token,
      method: 'PATCH',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
  }

  /// 双向智能合并算法
  SyncMergeResult mergeSyncRecords(
    List<AnimeRecord> localRecords,
    List<AnimeRecord> remoteRecords,
    Map<String, String> localTombstones,
    Map<String, String> remoteTombstones,
  ) {
    // 1. 合并墓碑（取较新的删除时间）
    final mergedTombstones = Map<String, String>.from(localTombstones);
    for (final entry in remoteTombstones.entries) {
      final id = entry.key;
      final timeStr = entry.value;
      if (!mergedTombstones.containsKey(id)) {
        mergedTombstones[id] = timeStr;
      } else {
        final existingTime = DateTime.tryParse(mergedTombstones[id]!) ?? DateTime(1970);
        final remoteTime = DateTime.tryParse(timeStr) ?? DateTime(1970);
        if (remoteTime.isAfter(existingTime)) {
          mergedTombstones[id] = timeStr;
        }
      }
    }

    String getKey(AnimeRecord rec) {
      if (rec.id.isNotEmpty) return 'id:${rec.id}';
      return 'title:${rec.titleZh.trim().toLowerCase()}';
    }

    bool isRecordDeleted(AnimeRecord rec) {
      if (rec.id.isEmpty) return false;
      final deletedAtStr = mergedTombstones[rec.id];
      if (deletedAtStr == null) return false;
      final deletedAt = DateTime.tryParse(deletedAtStr);
      if (deletedAt == null) return false;
      final updatedAt = DateTime.tryParse(rec.updatedAt.isNotEmpty ? rec.updatedAt : rec.createdAt) ?? DateTime(1970);
      return !updatedAt.isAfter(deletedAt);
    }

    final validRemoteKeys = <String>{};
    for (final rem in remoteRecords) {
      if (!isRecordDeleted(rem)) {
        validRemoteKeys.add(getKey(rem));
      }
    }

    final map = <String, AnimeRecord>{};
    int pulledCount = 0;
    int pushedCount = 0;

    // 2. 填入本地记录
    for (final loc in localRecords) {
      if (isRecordDeleted(loc)) continue;
      final key = getKey(loc);
      map[key] = loc;

      if (!validRemoteKeys.contains(key)) {
        pushedCount++;
      }
    }

    // 3. 对比合并云端记录
    for (final rem in remoteRecords) {
      if (isRecordDeleted(rem)) continue;
      final key = getKey(rem);

      if (!map.containsKey(key)) {
        map[key] = rem;
        pulledCount++;
      } else {
        final loc = map[key]!;
        final locTime = DateTime.tryParse(loc.updatedAt.isNotEmpty ? loc.updatedAt : loc.createdAt) ?? DateTime(1970);
        final remTime = DateTime.tryParse(rem.updatedAt.isNotEmpty ? rem.updatedAt : rem.createdAt) ?? DateTime(1970);

        if (remTime.isAfter(locTime)) {
          map[key] = rem;
          pulledCount++;
        } else if (locTime.isAfter(remTime)) {
          pushedCount++;
        } else {
          if (rem.episodesWatched > loc.episodesWatched) {
            map[key] = rem;
          }
        }
      }
    }

    final mergedRecords = map.values.toList();

    // 4. 断崖骤减保护
    if (remoteRecords.length >= 5 && mergedRecords.length < remoteRecords.length * 0.4) {
      throw Exception(
        '数据安全防护触发：云端原有 ${remoteRecords.length} 部番剧，合并后仅剩 ${mergedRecords.length} 部。为防止数据异常丢失已终止同步。',
      );
    }

    return SyncMergeResult(
      mergedRecords: mergedRecords,
      mergedTombstones: mergedTombstones,
      hasChanges: pulledCount > 0 || pushedCount > 0,
      pulledCount: pulledCount,
      pushedCount: pushedCount,
    );
  }
}
