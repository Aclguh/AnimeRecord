import 'package:anime_record/l10n/l10n.dart';
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

  Widget createTestApp({
    AnimeProvider? customAnimeProvider,
    Locale locale = const Locale('zh'),
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomeScreen(
        animeProvider: customAnimeProvider ?? animeProvider,
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

      expect(find.text('暂无番剧记录'), findsOneWidget);

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
      expect(find.byType(SliverReorderableList), findsOneWidget);

      // 点击完成退出排序模式
      await tester.tap(find.text('完成'));
      await tester.pumpAndSettle();

      // 退出排序模式，还原为网格视图
      expect(find.byType(SliverReorderableList), findsNothing);
    });

    testWidgets('triggers export shortcut on Ctrl+S', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Trigger Ctrl+S shortcut
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
    });

    testWidgets('triggers sync via app bar sync button', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final syncBtn = find.byIcon(Icons.sync_rounded);
      expect(syncBtn, findsOneWidget);
      await tester.tap(syncBtn);
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.textContaining('请先配置 GitHub Token'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4)); // drain Toast timer
    });

    testWidgets('edits anime record via card edit button', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final record = AnimeRecord.createEmpty().copyWith(
        id: 'edit_target',
        titleZh: '待编辑番剧',
        status: AnimeStatus.watching,
      );
      await animeProvider.addRecord(record);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap edit button on AnimeCard
      final editBtn = find.byIcon(Icons.edit_outlined);
      expect(editBtn, findsOneWidget);
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      expect(find.byType(AnimeFormDialog), findsOneWidget);
      expect(find.text('编辑番剧'), findsOneWidget);
    });

    testWidgets('deletes anime record via card delete button and confirm dialog', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final record = AnimeRecord.createEmpty().copyWith(
        id: 'del_target',
        titleZh: '待删除番剧',
        status: AnimeStatus.watching,
      );
      await animeProvider.addRecord(record);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap delete button on card
      final delBtn = find.byIcon(Icons.delete_outline_rounded);
      expect(delBtn, findsOneWidget);
      await tester.tap(delBtn);
      await tester.pumpAndSettle();

      // Confirm dialog appears
      expect(find.text('删除番剧'), findsOneWidget);
      expect(find.text('确定要删除「待删除番剧」吗？此操作不可撤销。'), findsOneWidget);

      // Confirm deletion
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();

      expect(animeProvider.allRecords, isEmpty);
      expect(find.text('「待删除番剧」已删除'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4)); // drain Toast timer
    });

    testWidgets('filters anime records by search query and clears search', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await animeProvider.addRecord(AnimeRecord.createEmpty().copyWith(
        id: 's1',
        titleZh: '魔法少女小圆',
        status: AnimeStatus.watching,
      ));
      await animeProvider.addRecord(AnimeRecord.createEmpty().copyWith(
        id: 's2',
        titleZh: '命运石之门',
        status: AnimeStatus.watching,
      ));

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('魔法少女小圆'), findsOneWidget);
      expect(find.text('命运石之门'), findsOneWidget);

      // Search '小圆'
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, '小圆');
      await tester.pump(const Duration(milliseconds: 350)); // debounce
      await tester.pumpAndSettle();

      expect(find.text('魔法少女小圆'), findsOneWidget);
      expect(find.text('命运石之门'), findsNothing);

      // Tap clear search button
      final clearBtn = find.byIcon(Icons.close_rounded);
      expect(clearBtn, findsOneWidget);
      await tester.tap(clearBtn);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('魔法少女小圆'), findsOneWidget);
      expect(find.text('命运石之门'), findsOneWidget);
    });

    testWidgets('filters anime records by weekday chips', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await animeProvider.addRecord(AnimeRecord.createEmpty().copyWith(
        id: 'w1',
        titleZh: '周一番剧',
        status: AnimeStatus.watching,
        week: WeekDay.mon,
      ));
      await animeProvider.addRecord(AnimeRecord.createEmpty().copyWith(
        id: 'w2',
        titleZh: '周二番剧',
        status: AnimeStatus.watching,
        week: WeekDay.tue,
      ));

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('周一番剧'), findsOneWidget);
      expect(find.text('周二番剧'), findsOneWidget);

      // Tap Monday filter chip
      await tester.tap(find.text('周一').first);
      await tester.pumpAndSettle();

      expect(find.text('周一番剧'), findsOneWidget);
      expect(find.text('周二番剧'), findsNothing);

      // Tap Monday again to unselect
      await tester.tap(find.text('周一').first);
      await tester.pumpAndSettle();

      expect(find.text('周一番剧'), findsOneWidget);
      expect(find.text('周二番剧'), findsOneWidget);
    });

    testWidgets('adapts grid crossAxisCount across mobile, tablet, and wide desktop breakpoints', (tester) async {
      await animeProvider.addRecord(AnimeRecord.createEmpty().copyWith(
        id: 'b1',
        titleZh: '断点测试番剧 1',
        status: AnimeStatus.watching,
      ));
      await animeProvider.addRecord(AnimeRecord.createEmpty().copyWith(
        id: 'b2',
        titleZh: '断点测试番剧 2',
        status: AnimeStatus.watching,
      ));

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1.0;

      // 1. Mobile screen (< 660) -> 1 column
      tester.view.physicalSize = const Size(500, 800);
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();
      var grid = tester.widget<SliverGrid>(find.byType(SliverGrid));
      var delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, equals(1));

      // 2. Tablet / medium screen (>= 660 and < 1050) -> 2 columns
      tester.view.physicalSize = const Size(800, 800);
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();
      grid = tester.widget<SliverGrid>(find.byType(SliverGrid));
      delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, equals(2));

      // 3. Wide desktop (>= 1050) -> 3 columns
      tester.view.physicalSize = const Size(1200, 800);
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();
      grid = tester.widget<SliverGrid>(find.byType(SliverGrid));
      delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, equals(3));
    });
  });
}
