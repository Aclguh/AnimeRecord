import 'package:flutter/widgets.dart';
import 'anime_provider.dart';
import 'locale_provider.dart';
import 'theme_provider.dart';

/// 应用程序全局状态作用域容器（基于 InheritedWidget 实现轻量、高效的依赖注入，消除 Prop Drilling）
class AnimeScope extends InheritedWidget {
  final AnimeProvider animeProvider;
  final ThemeProvider themeProvider;
  final LocaleProvider localeProvider;

  const AnimeScope({
    super.key,
    required this.animeProvider,
    required this.themeProvider,
    required this.localeProvider,
    required super.child,
  });

  static AnimeScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AnimeScope>();
  }

  static AnimeScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'No AnimeScope found in context');
    return scope!;
  }

  static AnimeProvider animeOf(BuildContext context) => of(context).animeProvider;
  static ThemeProvider themeOf(BuildContext context) => of(context).themeProvider;
  static LocaleProvider localeOf(BuildContext context) => of(context).localeProvider;

  @override
  bool updateShouldNotify(AnimeScope oldWidget) {
    return animeProvider != oldWidget.animeProvider ||
        themeProvider != oldWidget.themeProvider ||
        localeProvider != oldWidget.localeProvider;
  }
}

/// BuildContext 便捷扩展方法
extension AnimeScopeContextExtension on BuildContext {
  AnimeProvider get animeProvider => AnimeScope.animeOf(this);
  ThemeProvider get themeProvider => AnimeScope.themeOf(this);
  LocaleProvider get localeProvider => AnimeScope.localeOf(this);
}
