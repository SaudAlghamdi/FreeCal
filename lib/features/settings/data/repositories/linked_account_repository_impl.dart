import 'dart:async';

import 'package:freecal/core/database/database_helper.dart';
import 'package:freecal/features/settings/data/models/linked_account_model.dart';
import 'package:freecal/features/settings/domain/entities/linked_account_entity.dart';
import 'package:freecal/features/settings/domain/repositories/linked_account_repository.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite-backed implementation of [LinkedAccountRepository].
class LinkedAccountRepositoryImpl implements LinkedAccountRepository {
  LinkedAccountRepositoryImpl({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;
  final StreamController<List<LinkedAccountEntity>> _controller =
      StreamController<List<LinkedAccountEntity>>.broadcast();

  @override
  Future<List<LinkedAccountEntity>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('linked_accounts');
    return maps.map((m) => LinkedAccountModel.fromMap(m).toEntity()).toList();
  }

  @override
  Future<LinkedAccountEntity?> getByProvider(AccountProvider provider) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'linked_accounts',
      where: 'providerKey = ?',
      whereArgs: [provider.key],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return LinkedAccountModel.fromMap(maps.first).toEntity();
  }

  @override
  Future<void> upsert(LinkedAccountEntity account) async {
    final db = await _dbHelper.database;
    final model = LinkedAccountModel.fromEntity(account);
    await db.insert(
      'linked_accounts',
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    unawaited(_notifyListeners());
  }

  @override
  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete('linked_accounts', where: 'id = ?', whereArgs: [id]);
    unawaited(_notifyListeners());
  }

  @override
  Stream<List<LinkedAccountEntity>> watchAll() {
    unawaited(getAll().then((accounts) => _controller.add(accounts)));
    return _controller.stream;
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }

  Future<void> _notifyListeners() async {
    final accounts = await getAll();
    if (!_controller.isClosed) {
      _controller.add(accounts);
    }
  }
}
