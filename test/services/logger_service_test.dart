import 'package:anime_record/services/logger_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    AppLogger.clear();
  });

  group('AppLogger Tests', () {
    test('logs debug, info, warn, error and records into buffer', () {
      expect(AppLogger.logHistory, isEmpty);

      AppLogger.debug('TagD', 'debug message');
      AppLogger.info('TagI', 'info message');
      AppLogger.warn('TagW', 'warn message', Exception('test warn'));
      AppLogger.error('TagE', 'error message', Exception('test error'), StackTrace.current);

      final history = AppLogger.logHistory;
      expect(history.length, 4);

      expect(history[0].level, LogLevel.debug);
      expect(history[0].message, 'debug message');

      expect(history[1].level, LogLevel.info);
      expect(history[1].tag, 'TagI');

      expect(history[2].level, LogLevel.warning);
      expect(history[2].error, isNotNull);

      expect(history[3].level, LogLevel.error);
      expect(history[3].stackTrace, isNotNull);

      final str = history[2].toString();
      expect(str.contains('[WARN]'), isTrue);
      expect(str.contains('TagW'), isTrue);
      expect(str.contains('test warn'), isTrue);
    });

    test('ring buffer limits history to maxBufferEntries', () {
      for (int i = 0; i < AppLogger.maxBufferEntries + 20; i++) {
        AppLogger.info('Test', 'Msg $i');
      }

      expect(AppLogger.logHistory.length, AppLogger.maxBufferEntries);
      expect(AppLogger.logHistory.last.message, 'Msg ${AppLogger.maxBufferEntries + 19}');
    });

    test('clear wipes out all history', () {
      AppLogger.info('Test', 'hello');
      expect(AppLogger.logHistory.length, 1);
      AppLogger.clear();
      expect(AppLogger.logHistory, isEmpty);
    });
  });
}
