import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'database_constants.dart';

/// Singleton helper that manages the SQLite database lifecycle.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, DbConstants.databaseName);
    final db = await openDatabase(
      path,
      version: DbConstants.databaseVersion,
      onCreate: _onCreate,
    );
    await db.execute('PRAGMA foreign_keys = ON');
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE ${DbConstants.tableCalendars} (
        ${DbConstants.columnId} TEXT PRIMARY KEY,
        ${DbConstants.columnName} TEXT NOT NULL,
        ${DbConstants.columnType} TEXT NOT NULL,
        ${DbConstants.columnColor} INTEGER NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE ${DbConstants.tableEvents} (
        ${DbConstants.columnId} TEXT PRIMARY KEY,
        ${DbConstants.columnTitle} TEXT NOT NULL,
        ${DbConstants.columnStartTime} TEXT NOT NULL,
        ${DbConstants.columnEndTime} TEXT NOT NULL,
        ${DbConstants.columnSourceCalendarId} TEXT NOT NULL,
        ${DbConstants.columnIsMirror} INTEGER NOT NULL DEFAULT 0,
        ${DbConstants.columnNotes} TEXT,
        ${DbConstants.columnLocation} TEXT,
        FOREIGN KEY (${DbConstants.columnSourceCalendarId})
          REFERENCES ${DbConstants.tableCalendars} (${DbConstants.columnId})
      )
    ''');

    batch.execute('''
      CREATE TABLE ${DbConstants.tableMirrorLinks} (
        ${DbConstants.columnId} TEXT PRIMARY KEY,
        ${DbConstants.columnSourceEventId} TEXT NOT NULL,
        ${DbConstants.columnTargetCalendarId} TEXT NOT NULL,
        ${DbConstants.columnMirrorMode} TEXT NOT NULL,
        FOREIGN KEY (${DbConstants.columnSourceEventId})
          REFERENCES ${DbConstants.tableEvents} (${DbConstants.columnId}),
        FOREIGN KEY (${DbConstants.columnTargetCalendarId})
          REFERENCES ${DbConstants.tableCalendars} (${DbConstants.columnId})
      )
    ''');

    batch.execute('''
      CREATE TABLE ${DbConstants.tableSyncRules} (
        ${DbConstants.columnId} TEXT PRIMARY KEY,
        ${DbConstants.columnSourceCalendarId} TEXT NOT NULL,
        ${DbConstants.columnTargetCalendarId} TEXT NOT NULL,
        ${DbConstants.columnMode} TEXT NOT NULL,
        ${DbConstants.columnTimeWindowStart} TEXT,
        ${DbConstants.columnTimeWindowEnd} TEXT,
        FOREIGN KEY (${DbConstants.columnSourceCalendarId})
          REFERENCES ${DbConstants.tableCalendars} (${DbConstants.columnId}),
        FOREIGN KEY (${DbConstants.columnTargetCalendarId})
          REFERENCES ${DbConstants.tableCalendars} (${DbConstants.columnId})
      )
    ''');

    batch.execute('''
      CREATE TABLE ${DbConstants.tableEventTargetSettings} (
        ${DbConstants.columnId} TEXT PRIMARY KEY,
        ${DbConstants.columnEventId} TEXT NOT NULL,
        ${DbConstants.columnTargetCalendarId} TEXT NOT NULL,
        ${DbConstants.columnMode} TEXT NOT NULL,
        ${DbConstants.columnOverrideRule} INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (${DbConstants.columnEventId})
          REFERENCES ${DbConstants.tableEvents} (${DbConstants.columnId}),
        FOREIGN KEY (${DbConstants.columnTargetCalendarId})
          REFERENCES ${DbConstants.tableCalendars} (${DbConstants.columnId})
      )
    ''');

    await batch.commit(noResult: true);
  }
}
