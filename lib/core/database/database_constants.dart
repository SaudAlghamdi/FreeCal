/// Constants for database table and column names.
class DbConstants {
  DbConstants._();

  // Database
  static const String databaseName = 'free_cal.db';
  static const int databaseVersion = 1;

  // Table names
  static const String tableCalendars = 'calendars';
  static const String tableEvents = 'events';
  static const String tableMirrorLinks = 'mirror_links';
  static const String tableSyncRules = 'sync_rules';
  static const String tableEventTargetSettings = 'event_target_settings';

  // Common columns
  static const String columnId = 'id';

  // Calendars columns
  static const String columnName = 'name';
  static const String columnType = 'type';
  static const String columnColor = 'color';

  // Events columns
  static const String columnTitle = 'title';
  static const String columnStartTime = 'startTime';
  static const String columnEndTime = 'endTime';
  static const String columnSourceCalendarId = 'sourceCalendarId';
  static const String columnIsMirror = 'isMirror';
  static const String columnNotes = 'notes';
  static const String columnLocation = 'location';

  // Mirror links columns
  static const String columnSourceEventId = 'sourceEventId';
  static const String columnTargetCalendarId = 'targetCalendarId';
  static const String columnMirrorMode = 'mirrorMode';

  // Sync rules columns
  static const String columnMode = 'mode';
  static const String columnTimeWindowStart = 'timeWindowStart';
  static const String columnTimeWindowEnd = 'timeWindowEnd';

  // Event target settings columns
  static const String columnEventId = 'eventId';
  static const String columnOverrideRule = 'overrideRule';
}
