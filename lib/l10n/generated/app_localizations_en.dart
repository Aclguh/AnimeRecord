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
  String get totalRecords => 'Total';

  @override
  String get episodesWatched => 'eps watched';

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
}
