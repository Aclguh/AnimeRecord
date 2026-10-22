import 'package:anime_record/models/anime_record.dart';
import 'package:anime_record/models/app_constants.dart';
import 'package:anime_record/services/storage_service.dart';
import 'package:anime_record/state/anime_provider.dart';
import 'package:anime_record/state/theme_provider.dart';
import 'package:anime_record/ui/dialogs/anime_form_dialog.dart';
import 'package:anime_record/ui/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late AnimeProvider animeProvider;
  late ThemeProvider themeProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = StorageService(prefs);
    animeProvider = AnimeProvider(storage: storage);
    themeProvider = ThemeProvider(storage);
  });

  Widget createTestApp() {
    return MaterialApp(
      home: HomeScreen(
        animeProvider: animeProvider,
        themeProvider: themeProvider,
      ),
    );
  }

  group('HomeScreen Full Flow Tests', () {
    testWidgets('renders empty state and opens add dialog', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('还没有番剧记录'), findsOneWidget);

      // Tap add first anime button
      await tester.tap(find.text('添加第一部番剧'));
      await tester.pumpAndSettle();

      expect(find.byType(AnimeFormDialog), findsOneWidget);
    });

    testWidgets('renders anime card and handles episode +1 and theme toggling', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const record = AnimeRecord(
        id: 'hs_1',
        titleZh: '葬送的芙莉莲',
        status: AnimeStatus.watching,
        episodesWatched: 5,
        episodesTotal: 28,
        createdAt: '2026-01-01T00:00:00.000Z',
        updatedAt: '2026-01-01T00:00:00.000Z',
      );
      await animeProvider.addRecord(record);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('葬送的芙莉莲'), findsOneWidget);
      expect(find.text('5 / 28 集'), findsNothing);

      // Tap theme toggle button
      await tester.tap(find.byIcon(Icons.dark_mode_outlined));
      await tester.pumpAndSettle();
      expect(themeProvider.themeMode, ThemeMode.dark);

      // Tap +1 episode
      await tester.tap(find.text('+1 集'));
      await tester.pumpAndSettle();
      expect(animeProvider.allRecords.first.episodesWatched, 6);

      // Switch to non-default sort to test virtualized grid
      animeProvider.setSortBy(SortOption.dateAddedDesc);
      await tester.pumpAndSettle();
      expect(find.text('葬送的芙莉莲'), findsOneWidget);

      // Open settings
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      expect(find.text('设置'), findsOneWidget);
    });

    testWidgets('triggers add dialog on Ctrl+N shortcut', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Trigger Ctrl+N shortcut
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(find.byType(AnimeFormDialog), findsOneWidget);
    });

    testWidgets('toggles reordering mode and renders ReorderableListView', (tester) async {
      final record1 = AnimeRecord.createEmpty().copyWith(
        titleZh: '番剧 A',
        status: AnimeStatus.watching,
      );
      final record2 = AnimeRecord.createEmpty().copyWith(
        titleZh: '番剧 B',
        status: AnimeStatus.watching,
      );
      await animeProvider.addRecord(record1);
      await animeProvider.addRecord(record2);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // 点击调整顺序按钮进入排序模式
      final reorderBtn = find.byIcon(Icons.swap_vert_rounded);
      expect(reorderBtn, findsOneWidget);
      await tester.tap(reorderBtn);
      await tester.pumpAndSettle();

      // 验证重排视图与提示出现
      expect(find.text('长按并拖动右侧手柄调整番剧排序'), findsOneWidget);
      expect(find.byType(ReorderableListView), findsOneWidget);

      // 点击完成退出排序模式
      await tester.tap(find.text('完成'));
      await tester.pumpAndSettle();

      // 退出排序模式，还原为网格视图
      expect(find.byType(ReorderableListView), findsNothing);
    });
  });
}
