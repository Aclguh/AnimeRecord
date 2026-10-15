import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_record/models/app_constants.dart';
import 'package:anime_record/services/storage_service.dart';
import 'package:anime_record/state/anime_provider.dart';
import 'package:anime_record/ui/dialogs/settings_dialog.dart';

Widget _wrapSettings(AnimeProvider provider) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => SettingsDialog.show(context, provider),
          child: const Text('Open Settings'),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late AnimeProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = StorageService(prefs);
    provider = AnimeProvider(storage: storage);
  });

  group('SettingsDialog Widget Tests', () {
    testWidgets('renders all main settings sections', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrapSettings(provider));
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      expect(find.text('设置'), findsOneWidget);
      expect(find.text('默认打开的页面'), findsOneWidget);
      expect(find.text('云端同步（GitHub Gist）'), findsOneWidget);
      expect(find.text('本地数据管理'), findsOneWidget);
    });

    testWidgets('modifies default status preference', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrapSettings(provider));
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // Tap '想看' chip in default open page section
      await tester.tap(find.text('想看').first);
      await tester.pumpAndSettle();

      expect(provider.getDefaultStatus(), AnimeStatus.wantToWatch);
    });

    testWidgets('saves GitHub Gist sync configuration', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrapSettings(provider));
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // Find token and gist text fields
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));

      await tester.enterText(textFields.at(0), 'ghp_secret_token_123');
      await tester.enterText(textFields.at(1), 'gist_abc_456');

      final saveButton = find.widgetWithText(OutlinedButton, '保存配置');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pump();
      await tester.pump(const Duration(seconds: 4)); // drain Toast timer

      expect(provider.syncConfig.token, 'ghp_secret_token_123');
      expect(provider.syncConfig.gistId, 'gist_abc_456');
    });

    testWidgets('displays warning toast when testing sync with empty token', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrapSettings(provider));
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      final testButton = find.widgetWithText(OutlinedButton, '测试连接');
      await tester.ensureVisible(testButton);
      await tester.tap(testButton);
      await tester.pump();

      expect(find.text('请先输入 GitHub Token'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4)); // drain Toast timer
    });

    testWidgets('closes dialog when clicking close button or done', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrapSettings(provider));
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      expect(find.text('设置'), findsOneWidget);

      await tester.tap(find.text('完成'));
      await tester.pumpAndSettle();

      expect(find.text('设置'), findsNothing);
    });
  });
}
