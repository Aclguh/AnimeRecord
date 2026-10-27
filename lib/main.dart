import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'l10n/generated/app_localizations.dart';
import 'services/storage_service.dart';
import 'state/anime_provider.dart';
import 'state/anime_scope.dart';
import 'state/locale_provider.dart';
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
  final localeProvider = LocaleProvider(storageService);

  runApp(AnimeRecordApp(
    animeProvider: animeProvider,
    themeProvider: themeProvider,
    localeProvider: localeProvider,
  ));
}

/// 应用程序根组件
class AnimeRecordApp extends StatefulWidget {
  final AnimeProvider animeProvider;
  final ThemeProvider themeProvider;
  final LocaleProvider? localeProvider;

  const AnimeRecordApp({
    super.key,
    required this.animeProvider,
    required this.themeProvider,
    this.localeProvider,
  });

  @override
  State<AnimeRecordApp> createState() => _AnimeRecordAppState();
}

class _AnimeRecordAppState extends State<AnimeRecordApp> {
  late final AppLifecycleListener _lifecycleListener;
  late final LocaleProvider _effectiveLocaleProvider;

  @override
  void initState() {
    super.initState();
    _effectiveLocaleProvider = widget.localeProvider ?? LocaleProvider(widget.animeProvider.storage);
    widget.themeProvider.addListener(_onThemeChanged);
    _effectiveLocaleProvider.addListener(_onLocaleChanged);
    _lifecycleListener = AppLifecycleListener(
      onInactive: () => widget.animeProvider.flushPendingSaves(),
      onPause: () => widget.animeProvider.flushPendingSaves(),
      onDetach: () => widget.animeProvider.flushPendingSaves(),
      onExitRequested: () async {
        await widget.animeProvider.flushPendingSaves();
        return AppExitResponse.exit;
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    widget.themeProvider.removeListener(_onThemeChanged);
    _effectiveLocaleProvider.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimeScope(
      animeProvider: widget.animeProvider,
      themeProvider: widget.themeProvider,
      localeProvider: _effectiveLocaleProvider,
      child: MaterialApp(
        title: '看番记录 - Anime Record',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: widget.themeProvider.themeMode,
        locale: _effectiveLocaleProvider.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HomeScreen(),
      ),
    );
  }
}
