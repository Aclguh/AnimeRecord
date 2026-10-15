import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_record/services/storage_service.dart';
import 'package:anime_record/state/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'theme': 'dark'});
    final prefs = await SharedPreferences.getInstance();
    storage = StorageService(prefs);
  });

  group('ThemeProvider Tests', () {
    test('initializes with saved theme mode', () {
      final provider = ThemeProvider(storage);
      expect(provider.themeMode, ThemeMode.dark);
    });

    test('setThemeMode updates theme and persists value', () async {
      final provider = ThemeProvider(storage);

      await provider.setThemeMode(ThemeMode.light);
      expect(provider.themeMode, ThemeMode.light);
      expect(storage.loadTheme(), 'light');

      await provider.setThemeMode(ThemeMode.system);
      expect(provider.themeMode, ThemeMode.system);
      expect(storage.loadTheme(), 'system');
    });

    testWidgets('toggleTheme toggles between light and dark based on context', (tester) async {
      final provider = ThemeProvider(storage);

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => provider.toggleTheme(context),
              child: const Text('Toggle'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Toggle'));
      await tester.pumpAndSettle();

      expect(provider.themeMode, ThemeMode.dark);
    });
  });
}
