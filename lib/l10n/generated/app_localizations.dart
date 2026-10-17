import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// 应用程序主标题
  ///
  /// In zh, this message translates to:
  /// **'看番记录'**
  String get appTitle;

  /// 添加番剧操作文案
  ///
  /// In zh, this message translates to:
  /// **'添加番剧'**
  String get addAnime;

  /// 编辑番剧操作文案
  ///
  /// In zh, this message translates to:
  /// **'编辑番剧'**
  String get editAnime;

  /// 删除番剧操作文案
  ///
  /// In zh, this message translates to:
  /// **'删除番剧'**
  String get deleteAnime;

  /// 同步按钮文案
  ///
  /// In zh, this message translates to:
  /// **'同步'**
  String get sync;

  /// 设置标题文案
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// 保存按钮文案
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// 取消按钮文案
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// 确认按钮文案
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get confirm;

  /// 完成按钮文案
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get done;

  /// 统计栏共收录记录数标签
  ///
  /// In zh, this message translates to:
  /// **'共收录'**
  String get totalRecords;

  /// 统计栏已观看集数标签
  ///
  /// In zh, this message translates to:
  /// **'集已观看'**
  String get episodesWatched;

  /// 搜索框占位提示
  ///
  /// In zh, this message translates to:
  /// **'搜索番剧名称、日文名或备注...'**
  String get searchHint;

  /// 全部状态筛选标签
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get statusAll;

  /// 想看状态标签
  ///
  /// In zh, this message translates to:
  /// **'想看'**
  String get statusWantToWatch;

  /// 在看状态标签
  ///
  /// In zh, this message translates to:
  /// **'在看'**
  String get statusWatching;

  /// 看过状态标签
  ///
  /// In zh, this message translates to:
  /// **'看过'**
  String get statusWatched;

  /// 搁置状态标签
  ///
  /// In zh, this message translates to:
  /// **'搁置'**
  String get statusOnHold;

  /// 抛弃状态标签
  ///
  /// In zh, this message translates to:
  /// **'抛弃'**
  String get statusDropped;

  /// 默认排序选项
  ///
  /// In zh, this message translates to:
  /// **'默认排序'**
  String get sortDefault;

  /// 按评分降序排列
  ///
  /// In zh, this message translates to:
  /// **'评分最高'**
  String get sortRating;

  /// 按观看集数降序排列
  ///
  /// In zh, this message translates to:
  /// **'看最多'**
  String get sortEpisodes;

  /// 按最近更新时间排序
  ///
  /// In zh, this message translates to:
  /// **'最近更新'**
  String get sortUpdated;

  /// 空白页主提示
  ///
  /// In zh, this message translates to:
  /// **'暂无番剧记录'**
  String get emptyStateTitle;

  /// 空白页副提示
  ///
  /// In zh, this message translates to:
  /// **'点击右上角「+」或下方按钮开启追番之旅'**
  String get emptyStateSubtitle;

  /// 空白页快速添加按钮
  ///
  /// In zh, this message translates to:
  /// **'添加第一部番剧'**
  String get emptyStateAction;

  /// 卡片快捷加一集按钮
  ///
  /// In zh, this message translates to:
  /// **'+1 集'**
  String get episodePlusOne;

  /// 快捷标记全部看完按钮
  ///
  /// In zh, this message translates to:
  /// **'看完'**
  String get finishWatching;

  /// 备注字段
  ///
  /// In zh, this message translates to:
  /// **'备注'**
  String get notes;

  /// 评分字段
  ///
  /// In zh, this message translates to:
  /// **'评分'**
  String get rating;

  /// 集数字段
  ///
  /// In zh, this message translates to:
  /// **'集数'**
  String get episodes;

  /// 每周更新日字段
  ///
  /// In zh, this message translates to:
  /// **'更新日'**
  String get weekLabel;

  /// 放送状态字段
  ///
  /// In zh, this message translates to:
  /// **'放送状态'**
  String get airStatusLabel;

  /// 连载中状态
  ///
  /// In zh, this message translates to:
  /// **'连载中'**
  String get airStatusAiring;

  /// 已完结状态
  ///
  /// In zh, this message translates to:
  /// **'已完结'**
  String get airStatusFinished;

  /// 未开播状态
  ///
  /// In zh, this message translates to:
  /// **'未开播'**
  String get airStatusUpcoming;

  /// 星期一
  ///
  /// In zh, this message translates to:
  /// **'周一'**
  String get weekMon;

  /// 星期二
  ///
  /// In zh, this message translates to:
  /// **'周二'**
  String get weekTue;

  /// 星期三
  ///
  /// In zh, this message translates to:
  /// **'周三'**
  String get weekWed;

  /// 星期四
  ///
  /// In zh, this message translates to:
  /// **'周四'**
  String get weekThu;

  /// 星期五
  ///
  /// In zh, this message translates to:
  /// **'周五'**
  String get weekFri;

  /// 星期六
  ///
  /// In zh, this message translates to:
  /// **'周六'**
  String get weekSat;

  /// 星期日
  ///
  /// In zh, this message translates to:
  /// **'周日'**
  String get weekSun;

  /// 设置中跟随屏幕方向旋转选项
  ///
  /// In zh, this message translates to:
  /// **'跟随屏幕选择'**
  String get followScreenRotation;

  /// 通用设置标题
  ///
  /// In zh, this message translates to:
  /// **'默认打开的页面'**
  String get generalSettings;

  /// 云同步分组标题
  ///
  /// In zh, this message translates to:
  /// **'云端同步（GitHub Gist）'**
  String get cloudSync;

  /// 本地数据管理分组标题
  ///
  /// In zh, this message translates to:
  /// **'本地数据管理'**
  String get localDataManagement;

  /// 导出本地备份按钮
  ///
  /// In zh, this message translates to:
  /// **'导出数据'**
  String get exportData;

  /// 导入备份数据按钮
  ///
  /// In zh, this message translates to:
  /// **'导入数据'**
  String get importData;

  /// 下载批量导入模板按钮
  ///
  /// In zh, this message translates to:
  /// **'下载模板'**
  String get downloadTemplate;

  /// 测试云同步连通性按钮
  ///
  /// In zh, this message translates to:
  /// **'测试连接'**
  String get testConnection;

  /// 自动在GitHub新建Gist按钮
  ///
  /// In zh, this message translates to:
  /// **'自动新建 Gist'**
  String get autoCreateGist;

  /// 上次同步时间前缀
  ///
  /// In zh, this message translates to:
  /// **'上次同步：'**
  String get lastSync;

  /// 未曾同步过的状态文案
  ///
  /// In zh, this message translates to:
  /// **'从未同步'**
  String get neverSynced;

  /// 保存云同步配置按钮
  ///
  /// In zh, this message translates to:
  /// **'保存配置'**
  String get saveConfig;

  /// 立即触发同步按钮
  ///
  /// In zh, this message translates to:
  /// **'立即同步'**
  String get syncNow;

  /// 删除确认弹窗标题
  ///
  /// In zh, this message translates to:
  /// **'删除番剧'**
  String get deleteConfirmTitle;

  /// 删除确认弹窗正文
  ///
  /// In zh, this message translates to:
  /// **'确定要删除该番剧记录吗？删除后可在云端同步中同步删除。'**
  String get deleteConfirmMessage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
