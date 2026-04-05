import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_constants.dart';
import '../../domain/repositories/event_repository.dart';
import '../models/event_model.dart';

/// SQLite implementation of [EventRepository].
class EventRepositoryImpl implements EventRepository {
  final Database _db;

  EventRepositoryImpl(this._db);

  @override
  Future<List<EventModel>> getAll() async {
    final maps = await _db.query(DbConstants.tableEvents);
    return maps.map(EventModel.fromMap).toList();
  }

  @override
  Future<EventModel?> getById(String id) async {
    final maps = await _db.query(
      DbConstants.tableEvents,
      where: '${DbConstants.columnId} = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return EventModel.fromMap(maps.first);
  }

  @override
  Future<List<EventModel>> getByCalendarId(String calendarId) async {
    final maps = await _db.query(
      DbConstants.tableEvents,
      where: '${DbConstants.columnSourceCalendarId} = ?',
      whereArgs: [calendarId],
    );
    return maps.map(EventModel.fromMap).toList();
  }

  @override
  Future<void> insert(EventModel event) async {
    await _db.insert(
      DbConstants.tableEvents,
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> update(EventModel event) async {
    await _db.update(
      DbConstants.tableEvents,
      event.toMap(),
      where: '${DbConstants.columnId} = ?',
      whereArgs: [event.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    await _db.delete(
      DbConstants.tableEvents,
      where: '${DbConstants.columnId} = ?',
      whereArgs: [id],
    );
  }
}
