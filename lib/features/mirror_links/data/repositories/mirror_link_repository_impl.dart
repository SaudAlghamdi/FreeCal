import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_constants.dart';
import '../../domain/repositories/mirror_link_repository.dart';
import '../models/mirror_link_model.dart';

/// SQLite implementation of [MirrorLinkRepository].
class MirrorLinkRepositoryImpl implements MirrorLinkRepository {
  final Database _db;

  MirrorLinkRepositoryImpl(this._db);

  @override
  Future<List<MirrorLinkModel>> getAll() async {
    final maps = await _db.query(DbConstants.tableMirrorLinks);
    return maps.map(MirrorLinkModel.fromMap).toList();
  }

  @override
  Future<MirrorLinkModel?> getById(String id) async {
    final maps = await _db.query(
      DbConstants.tableMirrorLinks,
      where: '${DbConstants.columnId} = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return MirrorLinkModel.fromMap(maps.first);
  }

  @override
  Future<List<MirrorLinkModel>> getBySourceEventId(String eventId) async {
    final maps = await _db.query(
      DbConstants.tableMirrorLinks,
      where: '${DbConstants.columnSourceEventId} = ?',
      whereArgs: [eventId],
    );
    return maps.map(MirrorLinkModel.fromMap).toList();
  }

  @override
  Future<void> insert(MirrorLinkModel mirrorLink) async {
    await _db.insert(
      DbConstants.tableMirrorLinks,
      mirrorLink.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> update(MirrorLinkModel mirrorLink) async {
    await _db.update(
      DbConstants.tableMirrorLinks,
      mirrorLink.toMap(),
      where: '${DbConstants.columnId} = ?',
      whereArgs: [mirrorLink.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    await _db.delete(
      DbConstants.tableMirrorLinks,
      where: '${DbConstants.columnId} = ?',
      whereArgs: [id],
    );
  }
}
