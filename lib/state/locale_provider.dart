import 'package:flutter/material.dart';
import '../services/storage_service.dart';

/// 应用语言偏好管理状态机
class LocaleProvider extends ChangeNotifier {
  final IStorageService _storage;
  String _currentLocaleCode = 'system';

  LocaleProvider(this._storage) {
    _currentLocaleCode = _storage.loadLocale();
  }

  /// 当前配置代码（'system', 'zh', 'en'）
  String get currentLocaleCode => _currentLocaleCode;

  /// 供 MaterialApp 使用的当前 Locale（若为 system 则返回 null 以跟随系统）
  Locale? get locale => switch (_currentLocaleCode) {
        'zh' => const Locale('zh'),
        'en' => const Locale('en'),
        _ => null,
      };

  /// 设置并持久化语言选项
  Future<void> setLocale(String code) async {
    if (_currentLocaleCode == code) return;
    _currentLocaleCode = code;
    await _storage.saveLocale(code);
    notifyListeners();
  }
}
