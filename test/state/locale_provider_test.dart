import 'package:anime_record/services/storage_service.dart';
import 'package:anime_record/state/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'anime-record-locale': 'zh'});
    final prefs = await SharedPreferences.getInstance();
    storage = StorageService(prefs);
  });

  group('LocaleProvider Tests', () {
    test('initializes with saved locale and maps to Locale object', () {
      final provider = LocaleProvider(storage);
      expect(provider.currentLocaleCode, 'zh');
      expect(provider.locale, const Locale('zh'));
    });

    test('setLocale updates to English and persists value', () async {
      final provider = LocaleProvider(storage);

      await provider.setLocale('en');
      expect(provider.currentLocaleCode, 'en');
      expect(provider.locale, const Locale('en'));
      expect(storage.loadLocale(), 'en');

      // Set to system (maps to null to follow system default)
      await provider.setLocale('system');
      expect(provider.currentLocaleCode, 'system');
      expect(provider.locale, isNull);
      expect(storage.loadLocale(), 'system');
    });
  });
}
