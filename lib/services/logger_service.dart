import 'package:flutter/foundation.dart';

/// 日志严重级别
enum LogLevel {
  debug('DEBUG'),
  info('INFO'),
  warning('WARN'),
  error('ERROR');

  final String label;
  const LogLevel(this.label);
}

/// 单条结构化日志条目
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.stackTrace,
  });

  @override
  String toString() {
    final timeStr = timestamp.toIso8601String().split('T').last.substring(0, 8);
    final errorStr = error != null ? ' | Error: $error' : '';
    return '[$timeStr] [${level.label}] [$tag] $message$errorStr';
  }
}

/// 统一结构化日志门面（支持控制台分级输出与内存循环诊断缓冲）
class AppLogger {
  static const int maxBufferEntries = 150;
  static final List<LogEntry> _logBuffer = [];

  /// 获取当前内存中保留的近期日志快照（供故障诊断或问题排查导出）
  static List<LogEntry> get logHistory => List.unmodifiable(_logBuffer);

  /// 敏感信息脱敏过滤器（自动过滤 GitHub Personal Access Token 与 Authorization 请求头）
  static String sanitize(String input) {
    if (input.isEmpty) return input;
    var sanitized = input;
    sanitized = sanitized.replaceAll(RegExp(r'ghp_[a-zA-Z0-9]{20,}'), '[REDACTED_TOKEN]');
    sanitized = sanitized.replaceAll(RegExp(r'github_pat_[a-zA-Z0-9_]{20,}'), '[REDACTED_TOKEN]');
    sanitized = sanitized.replaceAll(
      RegExp(r'Bearer\s+[a-zA-Z0-9_\-\.]{15,}', caseSensitive: false),
      'Bearer [REDACTED_TOKEN]',
    );
    return sanitized;
  }

  static void _log(
    LogLevel level,
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    final cleanMessage = sanitize(message);
    final cleanError = error != null ? sanitize(error.toString()) : null;

    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: cleanMessage,
      error: cleanError,
      stackTrace: stackTrace,
    );

    if (_logBuffer.length >= maxBufferEntries) {
      _logBuffer.removeAt(0);
    }
    _logBuffer.add(entry);

    final prefix = '[${level.label}] [$tag]';
    if (kDebugMode) {
      if (cleanError != null) {
        debugPrint('$prefix $cleanMessage\nError: $cleanError${stackTrace != null ? "\n$stackTrace" : ""}');
      } else {
        debugPrint('$prefix $cleanMessage');
      }
    }
  }

  static void debug(String tag, String message) {
    _log(LogLevel.debug, tag, message);
  }

  static void info(String tag, String message) {
    _log(LogLevel.info, tag, message);
  }

  static void warn(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, tag, message, error, stackTrace);
  }

  static void error(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, tag, message, error, stackTrace);
  }

  /// 清空当前日志缓冲
  static void clear() {
    _logBuffer.clear();
  }
}
