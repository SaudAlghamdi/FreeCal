/// Application-wide constants for FreeCal.
abstract class AppConstants {
  AppConstants._();

  /// Default time window start hour (6 AM).
  static const int defaultWorkHoursStart = 6;

  /// Default time window end hour (6 PM).
  static const int defaultWorkHoursEnd = 18;

  /// Maximum event title length.
  static const int maxTitleLength = 200;

  /// Maximum notes length.
  static const int maxNotesLength = 2000;

  /// Database version.
  static const int databaseVersion = 1;

  /// Pre-seeded calendar IDs.
  static const String personalCalendarId = 'cal-personal';
  static const String workCalendarId = 'cal-work';
  static const String businessCalendarId = 'cal-business';
  static const String familyCalendarId = 'cal-family';
}
