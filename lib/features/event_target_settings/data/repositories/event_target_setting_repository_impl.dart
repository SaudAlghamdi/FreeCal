import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_constants.dart';
import '../../domain/repositories/event_target_setting_repository.dart';
import '../models/event_target_setting_model.dart';

/// SQLite implementation of [EventTargetSettingRepository].
class EventTargetSettingRepositoryImpl implements EventTargetSettingRepository {
  final Database _db;

  EventTargetSettingRepositoryImpl(this._db);

  @override
  Future<List<EventTargetSettingModel>> getAll() async {
    final maps = await _db.query(DbConstants.tableEventTargetSettings);
    return maps.map(EventTargetSettingModel.fromMap).toList();
  }

  @override
  Future<EventTargetSettingModel?> getById(String id) async {
    final maps = await _db.query(
      DbConstants.tableEventTargetSettings,
      where: '${DbConstants.columnId} = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return EventTargetSettingModel.fromMap(maps.first);
  }

  @override
  Future<List<EventTargetSettingModel>> getByEventId(String eventId) async {
    final maps = await _db.query(
      DbConstants.tableEventTargetSettings,
      where: '${DbConstants.columnEventId} = ?',
      whereArgs: [eventId],
    );
    return maps.map(EventTargetSettingModel.fromMap).toList();
  }

  @override
  Future<void> insert(EventTargetSettingModel setting) async {
    await _db.insert(
      DbConstants.tableEventTargetSettings,
      setting.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> update(EventTargetSettingModel setting) async {
    await _db.update(
      DbConstants.tableEventTargetSettings,
      setting.toMap(),
      where: '${DbConstants.columnId} = ?',
      whereArgs: [setting.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    await _db.delete(
      DbConstants.tableEventTargetSettings,
      where: '${DbConstants.columnId} = ?',
      whereArgs: [id],
    );
  }
}
