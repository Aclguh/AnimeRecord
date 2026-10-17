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
  String get done => '完成';

  @override
  String get totalRecords => '共收录';

  @override
  String get episodesWatched => '集已观看';

  @override
  String get searchHint => '搜索番剧名称、日文名或备注...';

  @override
  String get statusAll => '全部';

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

  @override
  String get sortDefault => '默认排序';

  @override
  String get sortRating => '评分最高';

  @override
  String get sortEpisodes => '看最多';

  @override
  String get sortUpdated => '最近更新';

  @override
  String get emptyStateTitle => '暂无番剧记录';

  @override
  String get emptyStateSubtitle => '点击右上角「+」或下方按钮开启追番之旅';

  @override
  String get emptyStateAction => '添加第一部番剧';

  @override
  String get episodePlusOne => '+1 集';

  @override
  String get finishWatching => '看完';

  @override
  String get notes => '备注';

  @override
  String get rating => '评分';

  @override
  String get episodes => '集数';

  @override
  String get weekLabel => '更新日';

  @override
  String get airStatusLabel => '放送状态';

  @override
  String get airStatusAiring => '连载中';

  @override
  String get airStatusFinished => '已完结';

  @override
  String get airStatusUpcoming => '未开播';

  @override
  String get weekMon => '周一';

  @override
  String get weekTue => '周二';

  @override
  String get weekWed => '周三';

  @override
  String get weekThu => '周四';

  @override
  String get weekFri => '周五';

  @override
  String get weekSat => '周六';

  @override
  String get weekSun => '周日';

  @override
  String get followScreenRotation => '跟随屏幕选择';

  @override
  String get generalSettings => '默认打开的页面';

  @override
  String get cloudSync => '云端同步（GitHub Gist）';

  @override
  String get localDataManagement => '本地数据管理';

  @override
  String get exportData => '导出数据';

  @override
  String get importData => '导入数据';

  @override
  String get downloadTemplate => '下载模板';

  @override
  String get testConnection => '测试连接';

  @override
  String get autoCreateGist => '自动新建 Gist';

  @override
  String get lastSync => '上次同步：';

  @override
  String get neverSynced => '从未同步';

  @override
  String get saveConfig => '保存配置';

  @override
  String get syncNow => '立即同步';

  @override
  String get deleteConfirmTitle => '删除番剧';

  @override
  String get deleteConfirmMessage => '确定要删除该番剧记录吗？删除后可在云端同步中同步删除。';
}
