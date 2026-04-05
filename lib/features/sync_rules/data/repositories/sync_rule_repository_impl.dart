import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_constants.dart';
import '../../domain/repositories/sync_rule_repository.dart';
import '../models/sync_rule_model.dart';

/// SQLite implementation of [SyncRuleRepository].
class SyncRuleRepositoryImpl implements SyncRuleRepository {
  final Database _db;

  SyncRuleRepositoryImpl(this._db);

  @override
  Future<List<SyncRuleModel>> getAll() async {
    final maps = await _db.query(DbConstants.tableSyncRules);
    return maps.map(SyncRuleModel.fromMap).toList();
  }

  @override
  Future<SyncRuleModel?> getById(String id) async {
    final maps = await _db.query(
      DbConstants.tableSyncRules,
      where: '${DbConstants.columnId} = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return SyncRuleModel.fromMap(maps.first);
  }

  @override
  Future<List<SyncRuleModel>> getBySourceCalendarId(String calendarId) async {
    final maps = await _db.query(
      DbConstants.tableSyncRules,
      where: '${DbConstants.columnSourceCalendarId} = ?',
      whereArgs: [calendarId],
    );
    return maps.map(SyncRuleModel.fromMap).toList();
  }

  @override
  Future<void> insert(SyncRuleModel rule) async {
    await _db.insert(
      DbConstants.tableSyncRules,
      rule.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> update(SyncRuleModel rule) async {
    await _db.update(
      DbConstants.tableSyncRules,
      rule.toMap(),
      where: '${DbConstants.columnId} = ?',
      whereArgs: [rule.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    await _db.delete(
      DbConstants.tableSyncRules,
      where: '${DbConstants.columnId} = ?',
      whereArgs: [id],
    );
  }
}
