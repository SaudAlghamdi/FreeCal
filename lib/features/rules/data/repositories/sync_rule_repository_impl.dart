import 'dart:async';

import 'package:freecal/core/database/database_helper.dart';
import 'package:freecal/features/rules/data/models/sync_rule_model.dart';
import 'package:freecal/features/rules/domain/entities/sync_rule_entity.dart';
import 'package:freecal/features/rules/domain/repositories/sync_rule_repository.dart';

/// SQLite-backed implementation of [SyncRuleRepository].
class SyncRuleRepositoryImpl implements SyncRuleRepository {
  SyncRuleRepositoryImpl({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;
  final StreamController<List<SyncRuleEntity>> _controller =
      StreamController<List<SyncRuleEntity>>.broadcast();

  @override
  Future<List<SyncRuleEntity>> getAllRules() async {
    final db = await _dbHelper.database;
    final maps = await db.query('sync_rules');
    return maps.map((m) => SyncRuleModel.fromMap(m).toEntity()).toList();
  }

  @override
  Future<List<SyncRuleEntity>> getRulesForSourceCalendar(
    String sourceCalendarId,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'sync_rules',
      where: 'sourceCalendarId = ?',
      whereArgs: [sourceCalendarId],
    );
    return maps.map((m) => SyncRuleModel.fromMap(m).toEntity()).toList();
  }

  @override
  Future<SyncRuleEntity?> getRuleById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'sync_rules',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return SyncRuleModel.fromMap(maps.first).toEntity();
  }

  @override
  Future<String> insertRule(SyncRuleEntity rule) async {
    final db = await _dbHelper.database;
    final model = SyncRuleModel.fromEntity(rule);
    await db.insert('sync_rules', model.toMap());
    _notifyListeners();
    return rule.id;
  }

  @override
  Future<void> updateRule(SyncRuleEntity rule) async {
    final db = await _dbHelper.database;
    final model = SyncRuleModel.fromEntity(rule);
    await db.update(
      'sync_rules',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [rule.id],
    );
    _notifyListeners();
  }

  @override
  Future<void> deleteRule(String id) async {
    final db = await _dbHelper.database;
    await db.delete('sync_rules', where: 'id = ?', whereArgs: [id]);
    _notifyListeners();
  }

  @override
  Stream<List<SyncRuleEntity>> watchRules() {
    getAllRules().then(_controller.add);
    return _controller.stream;
  }

  void _notifyListeners() {
    getAllRules().then(_controller.add);
  }

  void dispose() {
    _controller.close();
  }
}
