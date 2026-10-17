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
}
