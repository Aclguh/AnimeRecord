import 'dart:convert';

import 'package:anime_record/l10n/l10n.dart';
import 'package:anime_record/models/anime_record.dart';
import 'package:anime_record/models/app_constants.dart';
import 'package:anime_record/services/storage_service.dart';
import 'package:anime_record/services/sync_service.dart';
import 'package:anime_record/state/anime_provider.dart';
import 'package:anime_record/state/locale_provider.dart';
import 'package:anime_record/ui/dialogs/settings_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrapSettings(
  AnimeProvider provider, {
  LocaleProvider? localeProvider,
  Locale locale = const Locale('zh'),
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => SettingsDialog.show(
            context,
            provider,
            localeProvider: localeProvider,
          ),
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
    FlutterSecureStorage.setMockInitialValues({});
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

    testWidgets('toggles follow screen rotation setting', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrapSettings(provider));
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      // Toggle rotation switch
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(storage.loadFollowScreenRotation(), isTrue);
    });

    testWidgets('tests GitHub Token and Gist connectivity with MockClient', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockClient = MockClient((request) async {
        if (request.url.path == '/user') {
          return http.Response(
            jsonEncode({'login': 'TestAnimeDev'}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (request.url.path.contains('/gists/')) {
          return http.Response(
            jsonEncode({
              'files': {
                SyncService.gistDataFilename: {
                  'content': jsonEncode({
                    'version': 1,
                    'records': [{'id': '1', 'titleZh': '测试番剧'}],
                  }),
                }
              }
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final customProvider = AnimeProvider(
        storage: storage,
        syncService: SyncService(mockClient),
      );

      await tester.pumpWidget(_wrapSettings(customProvider));
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'ghp_mock_token');
      await tester.enterText(textFields.at(1), 'gist_mock_id');

      final testButton = find.widgetWithText(OutlinedButton, '测试连接');
      await tester.ensureVisible(testButton);
      await tester.tap(testButton);
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.textContaining('TestAnimeDev'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4)); // drain Toast timer
    });

    testWidgets('handles auto create Gist flow with MockClient', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockClient = MockClient((request) async {
        if (request.url.path == '/gists' && request.method == 'POST') {
          return http.Response(
            jsonEncode({'id': 'new_auto_created_gist_888'}),
            201,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final customProvider = AnimeProvider(
        storage: storage,
        syncService: SyncService(mockClient),
      );

      await tester.pumpWidget(_wrapSettings(customProvider));
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'ghp_mock_token');

      final autoCreateBtn = find.widgetWithText(OutlinedButton, '自动新建 Gist');
      await tester.ensureVisible(autoCreateBtn);
      await tester.tap(autoCreateBtn);
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.textContaining('已成功在 GitHub 创建私有 Gist 并完成绑定'), findsOneWidget);
      expect(find.text('new_auto_created_gist_888'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4)); // drain Toast timer
    });

    testWidgets('shows error toast when testToken fails', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'message': 'Bad credentials'}), 401);
      });

      final customProvider = AnimeProvider(
        storage: storage,
        syncService: SyncService(mockClient),
      );

      await tester.pumpWidget(_wrapSettings(customProvider));
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'invalid_token');

      final testButton = find.widgetWithText(OutlinedButton, '测试连接');
      await tester.ensureVisible(testButton);
      await tester.tap(testButton);
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.textContaining('测试失败'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4)); // drain Toast timer
    });

    testWidgets('shows error toast when autoCreateGist fails', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockClient = MockClient((request) async {
        return http.Response('Validation Failed', 422);
      });

      final customProvider = AnimeProvider(
        storage: storage,
        syncService: SyncService(mockClient),
      );

      await tester.pumpWidget(_wrapSettings(customProvider));
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'ghp_token');

      final autoCreateBtn = find.widgetWithText(OutlinedButton, '自动新建 Gist');
      await tester.ensureVisible(autoCreateBtn);
      await tester.tap(autoCreateBtn);
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.textContaining('创建 Gist 失败'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4)); // drain Toast timer
    });

    testWidgets('triggers syncNow and handles success', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockClient = MockClient((request) async {
        if (request.method == 'GET' && request.url.path.contains('/gists/')) {
          return http.Response(
            jsonEncode({
              'files': {
                SyncService.gistDataFilename: {
                  'content': jsonEncode({
                    'version': 1,
                    'records': [],
                  }),
                }
              }
            }),
            200,
          );
        }
        if (request.method == 'PATCH' && request.url.path.contains('/gists/')) {
          return http.Response('{}', 200);
        }
        return http.Response('Not Found', 404);
      });

      final customProvider = AnimeProvider(
        storage: storage,
        syncService: SyncService(mockClient),
      );
      await customProvider.setSyncConfig(customProvider.syncConfig.copyWith(
        token: 'ghp_valid_token',
        gistId: 'gist_valid_id',
      ));

      await tester.pumpWidget(_wrapSettings(customProvider));
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      final syncNowBtn = find.widgetWithText(ElevatedButton, '立即同步');
      await tester.ensureVisible(syncNowBtn);
      await tester.tap(syncNowBtn);
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.textContaining('同步成功'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4)); // drain Toast timer
    });

    testWidgets('triggers syncNow cliff warning and cancels', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockClient = MockClient((request) async {
        if (request.method == 'GET' && request.url.path.contains('/gists/')) {
          final payload = jsonEncode({
            'files': {
              SyncService.gistDataFilename: {
                'content': jsonEncode({
                  'version': 1,
                  'records': [
                    {'id': 'r1', 'titleZh': '保留番剧'}
                  ],
                  'tombstones': {
                    for (int i = 1; i <= 6; i++) 'local_$i': '2099-01-01T00:00:00.000',
                  },
                }),
              }
            }
          });
          return http.Response.bytes(
            utf8.encode(payload),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final customProvider = AnimeProvider(
        storage: storage,
        syncService: SyncService(mockClient),
      );
      // Inject 6 records to trigger cliff drop when merged with only 1 remote
      for (int i = 1; i <= 6; i++) {
        await customProvider.addRecord(AnimeRecord.createEmpty().copyWith(
          id: 'local_$i',
          titleZh: '本地番剧 $i',
        ));
      }
      await customProvider.setSyncConfig(customProvider.syncConfig.copyWith(
        token: 'ghp_valid_token',
        gistId: 'gist_valid_id',
      ));

      await tester.pumpWidget(_wrapSettings(customProvider));
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      final syncNowBtn = find.widgetWithText(ElevatedButton, '立即同步');
      await tester.ensureVisible(syncNowBtn);
      await tester.tap(syncNowBtn);
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();

      expect(find.text('同步数据保护提醒'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('取消').last);
      await tester.pumpAndSettle();

      expect(find.text('同步数据保护提醒'), findsNothing);
    });

    testWidgets('triggers syncNow cliff warning and forces sync', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockClient = MockClient((request) async {
        if (request.method == 'GET' && request.url.path.contains('/gists/')) {
          final payload = jsonEncode({
            'files': {
              SyncService.gistDataFilename: {
                'content': jsonEncode({
                  'version': 1,
                  'records': [
                    {'id': 'r1', 'titleZh': '保留番剧'}
                  ],
                  'tombstones': {
                    for (int i = 1; i <= 6; i++) 'local_$i': '2099-01-01T00:00:00.000',
                  },
                }),
              }
            }
          });
          return http.Response.bytes(
            utf8.encode(payload),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (request.method == 'PATCH' && request.url.path.contains('/gists/')) {
          return http.Response('{}', 200);
        }
        return http.Response('Not Found', 404);
      });

      final customProvider = AnimeProvider(
        storage: storage,
        syncService: SyncService(mockClient),
      );
      for (int i = 1; i <= 6; i++) {
        await customProvider.addRecord(AnimeRecord.createEmpty().copyWith(
          id: 'local_$i',
          titleZh: '本地番剧 $i',
        ));
      }
      await customProvider.setSyncConfig(customProvider.syncConfig.copyWith(
        token: 'ghp_valid_token',
        gistId: 'gist_valid_id',
      ));

      await tester.pumpWidget(_wrapSettings(customProvider));
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      final syncNowBtn = find.widgetWithText(ElevatedButton, '立即同步');
      await tester.ensureVisible(syncNowBtn);
      await tester.tap(syncNowBtn);
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();

      expect(find.text('同步数据保护提醒'), findsOneWidget);

      // Confirm force sync
      final forceSyncBtn = find.text('强制覆盖同步');
      expect(forceSyncBtn, findsOneWidget);
      await tester.tap(forceSyncBtn);
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.textContaining('同步成功'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4)); // drain Toast timer
    });

    testWidgets('changes application language via locale provider dropdown', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final localeProvider = LocaleProvider(storage);

      await tester.pumpWidget(_wrapSettings(provider, localeProvider: localeProvider));
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // Find DropdownButton
      final dropdown = find.byType(DropdownButton<String>);
      expect(dropdown, findsOneWidget);

      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Select English
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();

      expect(localeProvider.locale, const Locale('en'));
    });

    testWidgets('toggles autoSync checkbox in sync section', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrapSettings(provider));
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      final checkboxFinder = find.byType(Checkbox);
      expect(checkboxFinder, findsOneWidget);

      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      expect(provider.syncConfig.autoSync, isTrue);
    });

    testWidgets('local data buttons are rendered and visible', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrapSettings(provider));
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(OutlinedButton, '导出数据'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, '导入数据'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, '下载模板'), findsOneWidget);
    });
  });
}
