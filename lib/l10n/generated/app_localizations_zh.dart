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
  String get edit => '编辑';

  @override
  String get delete => '删除';

  @override
  String get reorder => '调整排序';

  @override
  String get reorderTip => '长按并拖动右侧手柄调整番剧排序';

  @override
  String get loadMore => '加载更多';

  @override
  String get noMatchingAnime => '没有找到符合条件的番剧';

  @override
  String get noMatchingAnimeSubtitle => '没有找到符合条件的番剧，试试调整筛选条件吧！';

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
  String get sortDateAddedDesc => '最近添加';

  @override
  String get sortDateAddedAsc => '最早添加';

  @override
  String get sortTitleZhAsc => '名称 A-Z';

  @override
  String get sortTitleZhDesc => '名称 Z-A';

  @override
  String get sortEpisodesLeft => '剩余集数';

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
  String completedEpisodes(int count) {
    return '已完成 $count 集';
  }

  @override
  String remainingEpisodes(int count) {
    return '剩 $count 集';
  }

  @override
  String watchedEpisodes(int count) {
    return '已看 $count 集';
  }

  @override
  String get notStartedYet => '尚未开始观看';

  @override
  String get completed => '已追完';

  @override
  String get justNow => '刚刚';

  @override
  String minutesAgo(int count) {
    return '$count分钟前';
  }

  @override
  String hoursAgo(int count) {
    return '$count小时前';
  }

  @override
  String daysAgo(int count) {
    return '$count天前';
  }

  @override
  String lastModified(String time) {
    return '最后修改：$time';
  }

  @override
  String deleteAnimeConfirm(String title) {
    return '确定要删除「$title」吗？此操作不可撤销。';
  }

  @override
  String animeAddedSuccess(String title) {
    return '「$title」已添加';
  }

  @override
  String animeUpdatedSuccess(String title) {
    return '「$title」已更新';
  }

  @override
  String animeDeletedSuccess(String title) {
    return '「$title」已删除';
  }

  @override
  String statusChangedWatched(String title) {
    return '「$title」已追完';
  }

  @override
  String statusChangedWatching(String title) {
    return '「$title」状态已切换为「在看」';
  }

  @override
  String get titleZhLabel => '中文名称';

  @override
  String get titleZhHint => '例：葬送的芙莉莲';

  @override
  String get titleZhValidation => '请输入番剧名称';

  @override
  String get titleJaLabel => '日文原名';

  @override
  String get titleJaHint => '例：葬送のフリーレン';

  @override
  String get coverUrlLabel => '封面链接';

  @override
  String get coverUrlHint => '以 http:// 或 https:// 开头';

  @override
  String get coverUrlValidation => '封面链接必须是以 http:// 或 https:// 开头的有效网址';

  @override
  String get watchStatusSelectLabel => '观看状态';

  @override
  String get airDaySelectLabel => '更新频率';

  @override
  String get airDayNone => '不设置';

  @override
  String get airStatusSelectLabel => '播放状态';

  @override
  String get airStatusNone => '不设置';

  @override
  String get episodesWatchedLabel => '已看集数';

  @override
  String get episodesTotalLabel => '总集数';

  @override
  String get episodesTotalHint => '0 表示未知或未完结';

  @override
  String get ratingLabel => '个人评分';

  @override
  String get ratingHint => '0.0 表示未评分';

  @override
  String get tagsLabel => '标签分类';

  @override
  String get notesLabel => '追番笔记与短评';

  @override
  String get notesHint => '写点短评、追番感受或备忘...';

  @override
  String get advancedOptions => '更多高级选项';

  @override
  String get unnamedAnime => '未命名番剧';

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
