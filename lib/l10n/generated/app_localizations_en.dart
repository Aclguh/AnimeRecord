// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Anime Record';

  @override
  String get addAnime => 'Add Anime';

  @override
  String get editAnime => 'Edit Anime';

  @override
  String get deleteAnime => 'Delete Anime';

  @override
  String get sync => 'Sync';

  @override
  String get settings => 'Settings';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get done => 'Done';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get reorder => 'Reorder';

  @override
  String get reorderTip => 'Drag handle on the right to reorder anime';

  @override
  String get loadMore => 'Load More';

  @override
  String get noMatchingAnime => 'No matching anime found';

  @override
  String get noMatchingAnimeSubtitle =>
      'Try adjusting your filter or search keywords!';

  @override
  String get totalRecords => 'Total';

  @override
  String get episodesWatched => 'eps watched';

  @override
  String get searchHint => 'Search anime title, alias or notes...';

  @override
  String get statusAll => 'All';

  @override
  String get statusWantToWatch => 'Plan to Watch';

  @override
  String get statusWatching => 'Watching';

  @override
  String get statusWatched => 'Completed';

  @override
  String get statusOnHold => 'On Hold';

  @override
  String get statusDropped => 'Dropped';

  @override
  String get sortDefault => 'Default';

  @override
  String get sortDateAddedDesc => 'Recently Added';

  @override
  String get sortDateAddedAsc => 'Oldest Added';

  @override
  String get sortTitleZhAsc => 'Title A-Z';

  @override
  String get sortTitleZhDesc => 'Title Z-A';

  @override
  String get sortEpisodesLeft => 'Remaining Episodes';

  @override
  String get sortRating => 'Highest Rating';

  @override
  String get sortEpisodes => 'Most Watched';

  @override
  String get sortUpdated => 'Recently Updated';

  @override
  String get emptyStateTitle => 'No Anime Records Yet';

  @override
  String get emptyStateSubtitle =>
      'Click + on the top-right or button below to start tracking';

  @override
  String get emptyStateAction => 'Add Your First Anime';

  @override
  String get episodePlusOne => '+1 Ep';

  @override
  String get finishWatching => 'Finish';

  @override
  String completedEpisodes(int count) {
    return 'Completed $count eps';
  }

  @override
  String remainingEpisodes(int count) {
    return '$count left';
  }

  @override
  String watchedEpisodes(int count) {
    return 'Watched $count eps';
  }

  @override
  String get notStartedYet => 'Not started';

  @override
  String get completed => 'Completed';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String hoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String daysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String lastModified(String time) {
    return 'Last modified: $time';
  }

  @override
  String deleteAnimeConfirm(String title) {
    return 'Are you sure you want to delete \"$title\"? This action cannot be undone.';
  }

  @override
  String animeAddedSuccess(String title) {
    return 'Added \"$title\"';
  }

  @override
  String animeUpdatedSuccess(String title) {
    return 'Updated \"$title\"';
  }

  @override
  String animeDeletedSuccess(String title) {
    return 'Deleted \"$title\"';
  }

  @override
  String statusChangedWatched(String title) {
    return 'Finished watching \"$title\"';
  }

  @override
  String statusChangedWatching(String title) {
    return '\"$title\" switched to Watching';
  }

  @override
  String get titleZhLabel => 'Chinese Title';

  @override
  String get titleZhHint => 'e.g. Frieren: Beyond Journey\'s End';

  @override
  String get titleZhValidation => 'Please enter anime title';

  @override
  String get titleJaLabel => 'Original Title (Japanese)';

  @override
  String get titleJaHint => 'e.g. 葬送のフリーレン';

  @override
  String get coverUrlLabel => 'Cover URL';

  @override
  String get coverUrlHint => 'Starts with http:// or https://';

  @override
  String get coverUrlValidation =>
      'Cover URL must be a valid http:// or https:// link';

  @override
  String get watchStatusSelectLabel => 'Watch Status';

  @override
  String get airDaySelectLabel => 'Air Day';

  @override
  String get airDayNone => 'None';

  @override
  String get airStatusSelectLabel => 'Broadcast Status';

  @override
  String get airStatusNone => 'None';

  @override
  String get episodesWatchedLabel => 'Episodes Watched';

  @override
  String get episodesTotalLabel => 'Total Episodes';

  @override
  String get episodesTotalHint => '0 means ongoing/unknown';

  @override
  String get ratingLabel => 'Rating';

  @override
  String get ratingHint => '0.0 means unrated';

  @override
  String get tagsLabel => 'Tags';

  @override
  String get notesLabel => 'Notes & Review';

  @override
  String get notesHint => 'Write your review or thoughts...';

  @override
  String get advancedOptions => 'More Options';

  @override
  String get unnamedAnime => 'Untitled Anime';

  @override
  String get notes => 'Notes';

  @override
  String get rating => 'Rating';

  @override
  String get episodes => 'Episodes';

  @override
  String get weekLabel => 'Air Day';

  @override
  String get airStatusLabel => 'Broadcast Status';

  @override
  String get airStatusAiring => 'Airing';

  @override
  String get airStatusFinished => 'Finished';

  @override
  String get airStatusUpcoming => 'Upcoming';

  @override
  String get weekMon => 'Mon';

  @override
  String get weekTue => 'Tue';

  @override
  String get weekWed => 'Wed';

  @override
  String get weekThu => 'Thu';

  @override
  String get weekFri => 'Fri';

  @override
  String get weekSat => 'Sat';

  @override
  String get weekSun => 'Sun';

  @override
  String get followScreenRotation => 'Follow Screen Rotation';

  @override
  String get generalSettings => 'Default Open Page';

  @override
  String get cloudSync => 'Cloud Sync (GitHub Gist)';

  @override
  String get localDataManagement => 'Local Data Management';

  @override
  String get exportData => 'Export Data';

  @override
  String get importData => 'Import Data';

  @override
  String get downloadTemplate => 'Download Template';

  @override
  String get testConnection => 'Test Connection';

  @override
  String get autoCreateGist => 'Auto Create Gist';

  @override
  String get lastSync => 'Last sync: ';

  @override
  String get neverSynced => 'Never synced';

  @override
  String get saveConfig => 'Save Config';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get deleteConfirmTitle => 'Delete Anime';

  @override
  String get deleteConfirmMessage =>
      'Are you sure you want to delete this anime record? It will also be deleted from the cloud upon next sync.';

  @override
  String get syncConnected => 'Connected';

  @override
  String get syncNotConfigured => 'Not Configured';

  @override
  String get copyTokenCreateLink => 'Copy Token Link ↗';

  @override
  String get tokenCopied => 'Token creation link copied to clipboard';

  @override
  String get tokenPermissionHint =>
      'Only gist read/write permission needed, securely stored on device.';

  @override
  String get gistIdHint =>
      'Enter the same Gist ID across multiple devices to sync progress.';

  @override
  String get autoSyncOnStartup => 'Auto sync on startup';

  @override
  String get syncSafetyHint =>
      '🛡️ Safe: Uses timestamp-based two-way incremental merge. New devices pull first.';

  @override
  String get localDataHint =>
      'Export local JSON file for offline backup or download template for batch import.';

  @override
  String get displaySettings => 'Display & Appearance';

  @override
  String get interfaceLanguage => 'Language';

  @override
  String get interfaceLanguageSubtitle => 'Select application display language';

  @override
  String get followSystem => 'Follow System';

  @override
  String get followScreenRotationSubtitle =>
      'Allow app to rotate to landscape (default off)';

  @override
  String defaultOpenPageDescription(String category) {
    return 'Default to showing \"$category\" tab on app launch';
  }

  @override
  String get syncConfigSaved => 'Cloud sync configuration saved';

  @override
  String get syncTokenRequired => 'Please enter GitHub Token first';

  @override
  String syncConnectSuccess(String username, String gistInfo) {
    return 'Connection successful! GitHub account: $username$gistInfo';
  }

  @override
  String syncConnectFailed(String error) {
    return 'Test failed: $error';
  }

  @override
  String get gistCreatedSuccess =>
      'Successfully created private Gist on GitHub and bound!';

  @override
  String gistCreateFailed(String error) {
    return 'Failed to create Gist: $error';
  }

  @override
  String exportSuccess(int count) {
    return 'Exported $count records';
  }

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get templateExportSuccess => 'Import template downloaded and saved';

  @override
  String templateExportFailed(String error) {
    return 'Failed to export template: $error';
  }

  @override
  String get importDialogTitle => 'Import Data';

  @override
  String importDialogFound(int count) {
    return 'Found $count incoming records.';
  }

  @override
  String importDialogCurrent(int count) {
    return 'Currently has $count records.';
  }

  @override
  String get importDialogSelectMode => 'Please select import mode:';

  @override
  String get importMerge => 'Merge Import';

  @override
  String get importReplace => 'Replace All';

  @override
  String importReplaceSuccess(int count) {
    return 'Replaced and imported $count records';
  }

  @override
  String get importMergeSuccess => 'Successfully merged and imported records';

  @override
  String get importSaveFailed => 'Import save failed';

  @override
  String importFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get cliffTitle => 'Sync Data Protection Warning';

  @override
  String cliffMessage(int baseline, int merged) {
    return 'Detected sharp decrease in records after merging (baseline: $baseline, merged: $merged).\n\nThis usually occurs when clearing or switching to an empty Gist. If this is intended, please choose \"Force Sync\".';
  }

  @override
  String get cliffForceSync => 'Force Sync';

  @override
  String get switchToLightTheme => 'Switch to light theme';

  @override
  String get switchToDarkTheme => 'Switch to dark theme';

  @override
  String get reorderModeDone => 'Done reordering';

  @override
  String get reorderModeStart => 'Reorder';

  @override
  String airStatusBadgeTooltip(String status) {
    return 'Air status: $status';
  }

  @override
  String weekBadgeTooltip(String week) {
    return 'Schedule: $week';
  }
}
