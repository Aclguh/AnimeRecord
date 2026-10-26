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

  static void _log(
    LogLevel level,
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );

    if (_logBuffer.length >= maxBufferEntries) {
      _logBuffer.removeAt(0);
    }
    _logBuffer.add(entry);

    final prefix = '[${level.label}] [$tag]';
    if (kDebugMode) {
      if (error != null) {
        debugPrint('$prefix $message\nError: $error${stackTrace != null ? "\n$stackTrace" : ""}');
      } else {
        debugPrint('$prefix $message');
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
