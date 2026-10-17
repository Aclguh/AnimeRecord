import 'dart:convert';

import 'package:anime_record/models/anime_record.dart';
import 'package:anime_record/services/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

AnimeRecord _record({
  required String id,
  required String titleZh,
  int episodesWatched = 0,
  int episodesTotal = 12,
  String? updatedAt,
  String? createdAt,
}) {
  return AnimeRecord(
    id: id,
    titleZh: titleZh,
    episodesWatched: episodesWatched,
    episodesTotal: episodesTotal,
    createdAt: createdAt ?? '2026-01-01T00:00:00.000Z',
    updatedAt: updatedAt ?? '2026-01-01T00:00:00.000Z',
  );
}

http.Response _jsonResponse(dynamic data, [int statusCode = 200]) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(data)),
    statusCode,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

void main() {
  group('SyncService - Gist ID Cleaning', () {
    test('extracts clean ID from URL or formats correctly', () {
      expect(SyncService.cleanGistId('https://gist.github.com/aclguh/1234567890abcdef'), '1234567890abcdef');
      expect(SyncService.cleanGistId('https://gist.github.com/1234567890abcdef'), '1234567890abcdef');
      expect(SyncService.cleanGistId('1234567890abcdef'), '1234567890abcdef');
      expect(SyncService.cleanGistId('/1234567890abcdef/'), '1234567890abcdef');
      expect(SyncService.cleanGistId('  '), '');
    });
  });

  group('SyncService - testGitHubToken', () {
    test('throws when token is empty', () async {
      final service = SyncService();
      expect(() => service.testGitHubToken(''), throwsA(isA<Exception>()));
    });

    test('returns username on 200 response', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/user');
        expect(request.headers['Authorization'], 'Bearer valid_token');
        return http.Response(jsonEncode({'login': 'octocat'}), 200);
      });

      final service = SyncService(mockClient);
      final user = await service.testGitHubToken('valid_token');
      expect(user, 'octocat');
    });

    test('throws specific error on 401 Unauthorized', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'message': 'Bad credentials'}), 401);
      });

      final service = SyncService(mockClient);
      expect(
        () => service.testGitHubToken('bad_token'),
        throwsA(predicate((e) => e.toString().contains('Token 无效或已过期'))),
      );
    });

    test('throws specific error on 403 Forbidden / Rate limit', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'message': 'rate limit exceeded'}), 403);
      });

      final service = SyncService(mockClient);
      expect(
        () => service.testGitHubToken('limited_token'),
        throwsA(predicate((e) => e.toString().contains('访问被拒绝或达到速率限制'))),
      );
    });

    test('throws specific error on 404 Not Found', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'message': 'Not Found'}), 404);
      });

      final service = SyncService(mockClient);
      expect(
        () => service.testGitHubToken('tok'),
        throwsA(predicate((e) => e.toString().contains('未找到指定的云端 Gist'))),
      );
    });

    test('throws message from response body on 500 error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'message': 'Internal Server Error'}), 500);
      });

      final service = SyncService(mockClient);
      expect(
        () => service.testGitHubToken('tok'),
        throwsA(predicate((e) => e.toString().contains('Internal Server Error'))),
      );
    });

    test('handles client exception gracefully', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Failed to connect');
      });

      final service = SyncService(mockClient);
      expect(
        () => service.testGitHubToken('tok'),
        throwsA(predicate((e) => e.toString().contains('网络连接失败'))),
      );
    });
  });

  group('SyncService - createSecretGist', () {
    test('creates gist and returns new Gist ID', () async {
      final records = [
        _record(id: 'a1', titleZh: '测试番剧1', episodesWatched: 5, episodesTotal: 12),
      ];
      final tombstones = {'del1': '2026-01-01T00:00:00.000Z'};

      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/gists');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['public'], false);
        expect(body['files'][SyncService.gistDataFilename], isNotNull);

        return http.Response(jsonEncode({'id': 'new_gist_id_123'}), 201);
      });

      final service = SyncService(mockClient);
      final id = await service.createSecretGist('token', records, tombstones);
      expect(id, 'new_gist_id_123');
    });

    test('throws error if response missing ID', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({}), 201);
      });

      final service = SyncService(mockClient);
      expect(
        () => service.createSecretGist('token', [], {}),
        throwsA(predicate((e) => e.toString().contains('未返回有效 ID'))),
      );
    });
  });

  group('SyncService - fetchRemoteGist', () {
    test('throws if Gist ID is empty', () async {
      final service = SyncService();
      expect(() => service.fetchRemoteGist('token', ''), throwsA(isA<Exception>()));
    });

    test('throws if response has no files', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'id': '123'}), 200);
      });

      final service = SyncService(mockClient);
      expect(
        () => service.fetchRemoteGist('token', '123'),
        throwsA(predicate((e) => e.toString().contains('未包含文件'))),
      );
    });

    test('returns empty records if target json file not found', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({
          'files': {'readme.txt': {'content': 'hello'}}
        }), 200);
      });

      final service = SyncService(mockClient);
      final res = await service.fetchRemoteGist('token', '123');
      expect(res.records, isEmpty);
      expect(res.tombstones, isEmpty);
    });

    test('parses standard anime-record-data.json successfully', () async {
      final dataObj = {
        'version': 1,
        'updatedAt': '2026-03-01T12:00:00.000Z',
        'records': [
          {'id': 'r1', 'titleZh': '从零开始', 'episodesWatched': 10, 'createdAt': '2026-01-01T00:00:00.000Z'}
        ],
        'tombstones': {'old_del': '2026-01-01T00:00:00.000Z'}
      };

      final mockClient = MockClient((request) async {
        return _jsonResponse({
          'files': {
            SyncService.gistDataFilename: {'content': jsonEncode(dataObj)}
          }
        });
      });

      final service = SyncService(mockClient);
      final res = await service.fetchRemoteGist('token', '123');
      expect(res.records.length, 1);
      expect(res.records.first.titleZh, '从零开始');
      expect(res.tombstones['old_del'], '2026-01-01T00:00:00.000Z');
      expect(res.updatedAt, '2026-03-01T12:00:00.000Z');
    });

    test('supports fallback array format json', () async {
      final dataArray = [
        {'id': 'r2', 'titleZh': '命运石之门', 'episodesWatched': 24, 'createdAt': '2026-01-01T00:00:00.000Z'}
      ];

      final mockClient = MockClient((request) async {
        return _jsonResponse({
          'files': {
            'custom_backup.json': {'content': jsonEncode(dataArray)}
          }
        });
      });

      final service = SyncService(mockClient);
      final res = await service.fetchRemoteGist('token', '123');
      expect(res.records.length, 1);
      expect(res.records.first.titleZh, '命运石之门');
    });

    test('fetches truncated file from githubusercontent.com securely', () async {
      final dataObj = {
        'version': 1,
        'records': [
          {'id': 'r3', 'titleZh': '进击的巨人', 'episodesWatched': 25, 'createdAt': '2026-01-01T00:00:00.000Z'}
        ],
        'tombstones': {}
      };

      final mockClient = MockClient((request) async {
        if (request.url.host == 'api.github.com') {
          return _jsonResponse({
            'files': {
              SyncService.gistDataFilename: {
                'truncated': true,
                'raw_url': 'https://gist.githubusercontent.com/raw/123/anime-record-data.json',
              }
            }
          });
        } else if (request.url.host == 'gist.githubusercontent.com') {
          return _jsonResponse(dataObj);
        }
        return http.Response('Not Found', 404);
      });

      final service = SyncService(mockClient);
      final res = await service.fetchRemoteGist('token', '123');
      expect(res.records.length, 1);
      expect(res.records.first.titleZh, '进击的巨人');
    });

    test('rejects truncated raw_url with untrusted domain', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({
          'files': {
            SyncService.gistDataFilename: {
              'truncated': true,
              'raw_url': 'https://evil-phishing.com/data.json',
            }
          }
        }), 200);
      });

      final service = SyncService(mockClient);
      expect(
        () => service.fetchRemoteGist('token', '123'),
        throwsA(predicate((e) => e.toString().contains('来源地址不安全'))),
      );
    });

    test('throws if remote file content is invalid JSON', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({
          'files': {
            SyncService.gistDataFilename: {'content': 'invalid { corrupted json'}
          }
        }), 200);
      });

      final service = SyncService(mockClient);
      expect(
        () => service.fetchRemoteGist('token', '123'),
        throwsA(predicate((e) => e.toString().contains('不是有效的 JSON 格式'))),
      );
    });
  });

  group('SyncService - pushRemoteGist', () {
    test('sends PATCH request with encoded content', () async {
      final records = [
        _record(id: 'push1', titleZh: '推送到云端')
      ];

      final mockClient = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/gists/gist999');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['files'][SyncService.gistDataFilename], isNotNull);
        return http.Response(jsonEncode({'id': 'gist999'}), 200);
      });

      final service = SyncService(mockClient);
      await service.pushRemoteGist('token', 'gist999', records, {});
    });
  });

  group('SyncService - mergeSyncRecords & Cliff Protection', () {
    final service = SyncService();

    test('correctly merges tombstones and respects latest deletion timestamp', () {
      final localTombstones = {'rec1': '2026-02-01T10:00:00.000Z'};
      final remoteTombstones = {
        'rec1': '2026-02-01T12:00:00.000Z', // newer
        'rec2': '2026-01-01T00:00:00.000Z',
      };

      final localRecords = [
        _record(id: 'rec1', titleZh: '已删本地', updatedAt: '2026-02-01T11:00:00.000Z'),
        _record(id: 'rec3', titleZh: '正常番剧', updatedAt: '2026-03-01T00:00:00.000Z'),
      ];
      final remoteRecords = [
        _record(id: 'rec2', titleZh: '已删远端', updatedAt: '2025-12-31T00:00:00.000Z'),
      ];

      final res = service.mergeSyncRecords(localRecords, remoteRecords, localTombstones, remoteTombstones);
      expect(res.mergedTombstones['rec1'], '2026-02-01T12:00:00.000Z');
      expect(res.mergedTombstones['rec2'], '2026-01-01T00:00:00.000Z');
      // rec1 and rec2 are filtered out by tombstones
      expect(res.mergedRecords.length, 1);
      expect(res.mergedRecords.first.id, 'rec3');
    });

    test('merges records taking newer updated record', () {
      final localRecords = [
        _record(id: 'shared', titleZh: '本地较旧', episodesWatched: 3, updatedAt: '2026-01-01T00:00:00.000Z'),
      ];
      final remoteRecords = [
        _record(id: 'shared', titleZh: '云端较新', episodesWatched: 8, updatedAt: '2026-02-01T00:00:00.000Z'),
      ];

      final res = service.mergeSyncRecords(localRecords, remoteRecords, {}, {});
      expect(res.mergedRecords.length, 1);
      expect(res.mergedRecords.first.titleZh, '云端较新');
      expect(res.mergedRecords.first.episodesWatched, 8);
      expect(res.pulledCount, 1);
    });

    test('triggers data cliff protection when remote records drops by > 60%', () {
      final remoteRecords = List.generate(
        10,
        (i) => _record(id: 'remote_$i', titleZh: '番剧 $i', updatedAt: '2026-01-01T00:00:00.000Z'),
      );
      // Local only has 2 records, resulting in 2 out of 10 (< 40%)
      final localRecords = [
        _record(id: 'remote_0', titleZh: '番剧 0', updatedAt: '2026-01-01T00:00:00.000Z'),
        _record(id: 'remote_1', titleZh: '番剧 1', updatedAt: '2026-01-01T00:00:00.000Z'),
      ];
      // Local tombstones deleted 8 records
      final localTombstones = {
        for (int i = 2; i < 10; i++) 'remote_$i': '2026-02-01T00:00:00.000Z',
      };

      expect(
        () => service.mergeSyncRecords(localRecords, remoteRecords, localTombstones, {}),
        throwsA(predicate((e) => e.toString().contains('数据安全防护触发'))),
      );
    });

    test('triggers bidirectional data cliff protection when local has records and remote drops by > 60%', () {
      final localRecords = List.generate(
        10,
        (i) => _record(id: 'local_$i', titleZh: '本地番剧 $i', updatedAt: '2026-01-01T00:00:00.000Z'),
      );
      // Remote is empty or only 1 record, but remote tombstones deleted 9 local records
      final remoteTombstones = {
        for (int i = 1; i < 10; i++) 'local_$i': '2026-02-01T00:00:00.000Z',
      };

      expect(
        () => service.mergeSyncRecords(localRecords, [], {}, remoteTombstones),
        throwsA(predicate((e) => e.toString().contains('数据安全防护触发'))),
      );
    });
  });
}
