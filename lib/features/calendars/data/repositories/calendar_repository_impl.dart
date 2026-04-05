import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_constants.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../models/calendar_model.dart';

/// SQLite implementation of [CalendarRepository].
class CalendarRepositoryImpl implements CalendarRepository {
  final Database _db;

  CalendarRepositoryImpl(this._db);

  @override
  Future<List<CalendarModel>> getAll() async {
    final maps = await _db.query(DbConstants.tableCalendars);
    return maps.map(CalendarModel.fromMap).toList();
  }

  @override
  Future<CalendarModel?> getById(String id) async {
    final maps = await _db.query(
      DbConstants.tableCalendars,
      where: '${DbConstants.columnId} = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return CalendarModel.fromMap(maps.first);
  }

  @override
  Future<void> insert(CalendarModel calendar) async {
    await _db.insert(
      DbConstants.tableCalendars,
      calendar.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> update(CalendarModel calendar) async {
    await _db.update(
      DbConstants.tableCalendars,
      calendar.toMap(),
      where: '${DbConstants.columnId} = ?',
      whereArgs: [calendar.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    await _db.delete(
      DbConstants.tableCalendars,
      where: '${DbConstants.columnId} = ?',
      whereArgs: [id],
    );
  }
}
