import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'l10n/generated/app_localizations.dart';
import 'services/storage_service.dart';
import 'state/anime_provider.dart';
import 'state/theme_provider.dart';
import 'ui/screens/home_screen.dart';
import 'ui/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化本地持久化存储
  final storageService = await StorageService.init();

  // 设置屏幕方向（默认锁定竖屏，若开启跟随屏幕选择则允许横屏旋转）
  final followScreen = storageService.loadFollowScreenRotation();
  if (!followScreen) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  } else {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  // 初始化核心状态管理
  final animeProvider = AnimeProvider(storage: storageService);
  final themeProvider = ThemeProvider(storageService);

  runApp(AnimeRecordApp(
    animeProvider: animeProvider,
    themeProvider: themeProvider,
  ));
}

/// 应用程序根组件
class AnimeRecordApp extends StatefulWidget {
  final AnimeProvider animeProvider;
  final ThemeProvider themeProvider;

  const AnimeRecordApp({
    super.key,
    required this.animeProvider,
    required this.themeProvider,
  });

  @override
  State<AnimeRecordApp> createState() => _AnimeRecordAppState();
}

class _AnimeRecordAppState extends State<AnimeRecordApp> {
  @override
  void initState() {
    super.initState();
    widget.themeProvider.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    widget.themeProvider.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '看番记录 - Anime Record',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: widget.themeProvider.themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomeScreen(
        animeProvider: widget.animeProvider,
        themeProvider: widget.themeProvider,
      ),
    );
  }
}
