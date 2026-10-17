import 'package:flutter/widgets.dart';
import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

/// 便捷扩展：安全获取当前区域的 AppLocalizations
extension AppLocalizationsX on BuildContext {
  /// 安全获取当前上下文的本地化资源，未注入时安全返回 null（保证测试与独立组件健壮性）
  AppLocalizations? get l10nOrNull => AppLocalizations.of(this);

  /// 快捷获取当前上下文的本地化资源
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
