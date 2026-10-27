import 'package:anime_record/main.dart';
import 'package:anime_record/models/anime_record.dart';
import 'package:anime_record/services/storage_service.dart';
import 'package:anime_record/state/anime_provider.dart';
import 'package:anime_record/state/locale_provider.dart';
import 'package:anime_record/state/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('English Locale Full Flow Smoke Tests', () {
    testWidgets('renders all major screens, dialogs, cards and validation in English', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);
      final animeProvider = AnimeProvider(storage: storage);
      final themeProvider = ThemeProvider(storage);
      final localeProvider = LocaleProvider(storage);
      await localeProvider.setLocale('en');

      // 准备测试数据（涵盖在看、完结、无海报）
      final recWatching = AnimeRecord.createEmpty().copyWith(
        id: 'rec-1',
        titleZh: 'Frieren: Beyond Journey''s End',
        titleJa: '葬送のフリーレン',
        status: 'watching',
        episodesWatched: 12,
        episodesTotal: 28,
        week: 'fri',
        airStatus: 'airing',
        rating: 9.5,
      );

      final recCompleted = AnimeRecord.createEmpty().copyWith(
        id: 'rec-2',
        titleZh: 'Steins;Gate',
        status: 'watched',
        episodesWatched: 24,
        episodesTotal: 24,
      );

      await animeProvider.addRecord(recWatching);
      await animeProvider.addRecord(recCompleted);

      await tester.pumpWidget(
        AnimeRecordApp(
          animeProvider: animeProvider,
          themeProvider: themeProvider,
          localeProvider: localeProvider,
        ),
      );
      await tester.pumpAndSettle();

      // 1. 验证首页 AppBar 与基础文字全英文
      expect(find.text('Anime Record'), findsOneWidget);
      expect(find.text('Sync'), findsOneWidget);
      expect(find.text('All'), findsWidgets);
      expect(find.text('Plan to Watch'), findsWidgets);
      expect(find.text('Watching'), findsWidgets);
      expect(find.text('Completed'), findsWidgets);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('eps watched'), findsOneWidget);

      // 2. 切换至 All 状态标签以查看所有卡片
      await tester.tap(find.text('All').first);
      await tester.pumpAndSettle();

      // 验证卡片英文文案（集数进度、状态流转）
      expect(find.text('16 left'), findsOneWidget);
      expect(find.text('Completed 24 eps'), findsOneWidget);
      expect(find.text('Edit'), findsWidgets);
      expect(find.text('+1 Ep'), findsWidgets);

      // 3. 点击「+1 Ep」，验证状态流转与英文 Toast 逻辑
      await tester.tap(find.text('+1 Ep').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // 4. 打开添加番剧弹窗并验证英文表单及校验
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Anime'));
      await tester.pumpAndSettle();

      expect(find.text('Add Anime'), findsWidgets);
      expect(find.text('Chinese Title'), findsOneWidget);
      expect(find.text('Watch Status'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      // 故意留空标题点击保存，验证英文校验提示
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('Please enter anime title'), findsWidgets);

      // 关闭添加弹窗
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await tester.pumpAndSettle();

      // 5. 打开设置弹窗并验证英文设置项
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Display & Appearance'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Cloud Sync (GitHub Gist)'), findsOneWidget);
      expect(find.text('Local Data Management'), findsOneWidget);
      expect(find.text('Export Data'), findsOneWidget);
      expect(find.text('Import Data'), findsOneWidget);

      // 关闭设置弹窗
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
    });
  });
}
