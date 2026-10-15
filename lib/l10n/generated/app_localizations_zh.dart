// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '看番记录';

  @override
  String get addAnime => '添加番剧';

  @override
  String get editAnime => '编辑番剧';

  @override
  String get deleteAnime => '删除番剧';

  @override
  String get sync => '同步';

  @override
  String get settings => '设置';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get totalRecords => '共收录';

  @override
  String get episodesWatched => '集已观看';

  @override
  String get statusWantToWatch => '想看';

  @override
  String get statusWatching => '在看';

  @override
  String get statusWatched => '看过';

  @override
  String get statusOnHold => '搁置';

  @override
  String get statusDropped => '抛弃';
}
