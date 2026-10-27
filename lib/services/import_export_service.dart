import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/anime_record.dart';
import '../models/result.dart';

/// 文件选择与保存抽象接口（便于单元测试 Mock 与跨端文件存储解耦）
abstract interface class IFilePickerService {
  Future<String?> pickJsonText();
  Future<String?> saveJsonFile({
    required String filename,
    required String content,
  });
}

/// 默认基于 file_picker 插件的文件选择服务实现
class PlatformFilePickerService implements IFilePickerService {
  const PlatformFilePickerService();

  @override
  Future<String?> pickJsonText() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (file == null) return null;

    final bytes = await file.readAsBytes();
    return utf8.decode(bytes);
  }

  @override
  Future<String?> saveJsonFile({
    required String filename,
    required String content,
  }) async {
    final bytes = Uint8List.fromList(utf8.encode(content));
    final uri = await FilePicker.saveFile(
      fileName: filename,
      bytes: bytes,
      dialogTitle: '保存备份文件',
      type: FileType.custom,
      allowedExtensions: ['json'],
      mimeType: 'application/json',
    );

    return uri?.toString();
  }
}

/// 导入与导出服务
class ImportExportService {
  /// 全局文件选择器实例，测试时可动态替换为 Mock / Fake 实现
  static IFilePickerService filePicker = const PlatformFilePickerService();
  /// 导出为 JSON 字符串
  static String exportToJson(List<AnimeRecord> records) {
    final exportObj = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'totalRecords': records.length,
      'records': records.map((r) => r.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(exportObj);
  }

  /// 异步导出为 JSON 字符串（在后台 Isolate 执行，防止大批量记录序列化阻塞主线程）
  static Future<String> exportToJsonAsync(List<AnimeRecord> records) {
    return compute(exportToJson, records);
  }

  /// 导出导入模板 JSON 字符串
  static String exportTemplateJson() {
    final template = {
      '_description': 'Anime Record 导入模板',
      '_instructions': [
        '1. 每条记录只需填写必要字段（titleZh 为必填）',
        '2. 未知字段可以留空或删除',
        '3. status 可选值: want_to_watch | watching | watched | on_hold | dropped',
        '4. week（更新频率，显示为卡片标记）可选值: mon | tue | wed | thu | fri | sat | sun，留空表示不显示标记',
        '5. airStatus（播放状态，显示为卡片标记）可选值: airing（正在更新）| finished（完结），留空表示不显示标记',
        '6. season 可选值: winter | spring | summer | fall（也可留空）',
        '7. rating 范围 1-10，0 表示未评分',
        '8. tags 为字符串数组，可自定义',
        '9. 导入时会自动生成 id、createdAt、updatedAt 字段',
        '10. 删除此模板中的 _description 和 _instructions 字段后即可导入'
      ],
      'version': 1,
      'records': [
        {
          'titleZh': '示例：葬送的芙莉莲',
          'titleJa': '葬送のフリーレン',
          'coverUrl': 'https://example.com/cover.jpg',
          'status': 'watching',
          'week': 'fri',
          'airStatus': 'airing',
          'rating': 8,
          'episodesWatched': 12,
          'episodesTotal': 28,
          'tags': ['奇幻', '冒险'],
          'notes': '这是一部很好看的番，推荐给所有人。',
          'startDate': '2023-09-29',
          'endDate': '',
          'year': 2023,
          'season': 'fall'
        },
        {
          'titleZh': '示例：鬼灭之刃 柱训练篇',
          'titleJa': '鬼滅の刃 柱稽古編',
          'coverUrl': '',
          'status': 'want_to_watch',
          'week': '',
          'airStatus': '',
          'rating': 0,
          'episodesWatched': 0,
          'episodesTotal': 8,
          'tags': ['战斗', '热血'],
          'notes': '',
          'startDate': '',
          'endDate': '',
          'year': 2024,
          'season': 'spring'
        }
      ]
    };
    return const JsonEncoder.withIndent('  ').convert(template);
  }

  /// 解析待导入的 JSON 内容并滤除说明字段
  static List<AnimeRecord> parseImportJson(String jsonString) {
    final parsed = jsonDecode(jsonString);
    List rawList;
    if (parsed is Map && parsed['records'] is List) {
      rawList = parsed['records'] as List;
    } else if (parsed is List) {
      rawList = parsed;
    } else {
      throw Exception('无效的导入文件格式：缺少 records 数组');
    }

    final valid = <AnimeRecord>[];
    for (final item in rawList) {
      if (item is! Map) continue;
      if (item.containsKey('_description') || item.containsKey('_instructions')) {
        continue;
      }
      final title = item['titleZh']?.toString().trim() ?? '';
      if (title.isEmpty) continue;

      valid.add(AnimeRecord.fromJson(Map<String, dynamic>.from(item)));
    }

    if (valid.isEmpty) {
      throw Exception('导入文件中没有有效的番剧记录');
    }

    return valid;
  }

  /// 异步解析待导入的 JSON 内容（在后台 Isolate 执行，防止大文件反序列化阻塞主线程）
  static Future<List<AnimeRecord>> parseImportJsonAsync(String jsonString) {
    return compute(parseImportJson, jsonString);
  }

  /// 安全解析待导入的 JSON 字符串，返回强类型 Result 结果
  static Result<List<AnimeRecord>, String> tryParseImportJson(String jsonString) {
    try {
      final records = parseImportJson(jsonString);
      return Success(records);
    } catch (e) {
      return Failure(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// 合并导入（根据 titleZh 去重）
  static ({List<AnimeRecord> records, int added, int skipped}) mergeImport(
    List<AnimeRecord> current,
    List<AnimeRecord> incoming,
  ) {
    final result = List<AnimeRecord>.from(current);
    final existingTitles = current.map((r) => r.titleZh.trim().toLowerCase()).toSet();

    int added = 0;
    int skipped = 0;

    for (final inc in incoming) {
      final key = inc.titleZh.trim().toLowerCase();
      if (existingTitles.contains(key)) {
        skipped++;
      } else {
        result.add(inc);
        existingTitles.add(key);
        added++;
      }
    }

    return (records: result, added: added, skipped: skipped);
  }

  /// 拾取并读取 JSON 文本
  static Future<String?> pickJsonFile({IFilePickerService? picker}) async {
    final activePicker = picker ?? filePicker;
    return await activePicker.pickJsonText();
  }

  /// 保存 JSON 文本到文件
  static Future<String?> saveJsonFile({
    required String filename,
    required String content,
    IFilePickerService? picker,
  }) async {
    final activePicker = picker ?? filePicker;
    return await activePicker.saveJsonFile(
      filename: filename,
      content: content,
    );
  }
}
