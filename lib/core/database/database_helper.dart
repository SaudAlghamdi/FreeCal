import 'package:path/path.dart' as path_pkg;
import 'package:sqflite/sqflite.dart';

/// Manages the SQLite database lifecycle and schema for FreeCal.
class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const String _databaseName = 'freecal.db';
  static const int _databaseVersion = 2;

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final dbPath = path_pkg.join(databasesPath, _databaseName);
    return openDatabase(
      dbPath,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(_createCalendarsTable);
    await db.execute(_createEventsTable);
    await db.execute(_createMirrorLinksTable);
    await db.execute(_createSyncRulesTable);
    await db.execute(_createEventTargetSettingsTable);
    await db.execute(_createLinkedAccountsTable);
    await _insertDefaultData(db);
  }

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute(_createLinkedAccountsTable);
    }
  }

  // ---------------------------------------------------------------------------
  // Table DDL
  // ---------------------------------------------------------------------------

  static const String _createCalendarsTable = '''
    CREATE TABLE IF NOT EXISTS calendars (
      id TEXT PRIMARY KEY NOT NULL,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      color INTEGER NOT NULL
    )
  ''';

  static const String _createEventsTable = '''
    CREATE TABLE IF NOT EXISTS events (
      id TEXT PRIMARY KEY NOT NULL,
      title TEXT NOT NULL,
      startTime INTEGER NOT NULL,
      endTime INTEGER NOT NULL,
      sourceCalendarId TEXT NOT NULL,
      notes TEXT,
      location TEXT,
      isMirror INTEGER NOT NULL DEFAULT 0,
      isAllDay INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (sourceCalendarId) REFERENCES calendars(id) ON DELETE CASCADE
    )
  ''';

  static const String _createMirrorLinksTable = '''
    CREATE TABLE IF NOT EXISTS mirror_links (
      id TEXT PRIMARY KEY NOT NULL,
      sourceEventId TEXT NOT NULL,
      targetCalendarId TEXT NOT NULL,
      mirrorMode TEXT NOT NULL,
      FOREIGN KEY (sourceEventId) REFERENCES events(id) ON DELETE CASCADE,
      FOREIGN KEY (targetCalendarId) REFERENCES calendars(id) ON DELETE CASCADE
    )
  ''';

  static const String _createSyncRulesTable = '''
    CREATE TABLE IF NOT EXISTS sync_rules (
      id TEXT PRIMARY KEY NOT NULL,
      sourceCalendarId TEXT NOT NULL,
      targetCalendarId TEXT NOT NULL,
      mode TEXT NOT NULL,
      timeWindowStart INTEGER,
      timeWindowEnd INTEGER,
      isActive INTEGER NOT NULL DEFAULT 1,
      FOREIGN KEY (sourceCalendarId) REFERENCES calendars(id) ON DELETE CASCADE,
      FOREIGN KEY (targetCalendarId) REFERENCES calendars(id) ON DELETE CASCADE
    )
  ''';

  static const String _createEventTargetSettingsTable = '''
    CREATE TABLE IF NOT EXISTS event_target_settings (
      id TEXT PRIMARY KEY NOT NULL,
      eventId TEXT NOT NULL,
      targetCalendarId TEXT NOT NULL,
      mode TEXT NOT NULL,
      overrideRule INTEGER NOT NULL DEFAULT 0,
      hideDetails INTEGER NOT NULL DEFAULT 0,
      applyWorkHoursRule INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (eventId) REFERENCES events(id) ON DELETE CASCADE,
      FOREIGN KEY (targetCalendarId) REFERENCES calendars(id) ON DELETE CASCADE
    )
  ''';

  static const String _createLinkedAccountsTable = '''
    CREATE TABLE IF NOT EXISTS linked_accounts (
      id TEXT PRIMARY KEY NOT NULL,
      providerKey TEXT NOT NULL UNIQUE,
      email TEXT NOT NULL,
      isConnected INTEGER NOT NULL DEFAULT 0,
      lastSyncAt INTEGER
    )
  ''';

  // ---------------------------------------------------------------------------
  // Default seed data
  // ---------------------------------------------------------------------------

  Future<void> _insertDefaultData(Database db) async {
    // Insert default calendars
    final batch = db.batch();

    batch.insert('calendars', {
      'id': 'cal-personal',
      'name': 'Personal',
      'type': 'personal',
      'color': 0xFF1976D2,
    });
    batch.insert('calendars', {
      'id': 'cal-work',
      'name': 'Work',
      'type': 'work',
      'color': 0xFF388E3C,
    });
    batch.insert('calendars', {
      'id': 'cal-business',
      'name': 'Private Business',
      'type': 'business',
      'color': 0xFFF57C00,
    });
    batch.insert('calendars', {
      'id': 'cal-family',
      'name': 'Family Business',
      'type': 'family',
      'color': 0xFF7B1FA2,
    });

    // Default sync rule: Personal → Work (Busy, 6 AM – 6 PM)
    batch.insert('sync_rules', {
      'id': 'rule-personal-work',
      'sourceCalendarId': 'cal-personal',
      'targetCalendarId': 'cal-work',
      'mode': 'busy',
      'timeWindowStart': 6,
      'timeWindowEnd': 18,
      'isActive': 1,
    });

    await batch.commit(noResult: true);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Closes the database connection.
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Deletes all rows from all tables. Used for testing.
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('event_target_settings');
    await db.delete('mirror_links');
    await db.delete('sync_rules');
    await db.delete('events');
    await db.delete('calendars');
    await db.delete('linked_accounts');
  }
}
