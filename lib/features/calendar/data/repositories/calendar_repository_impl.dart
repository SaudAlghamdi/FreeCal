import 'dart:async';

import 'package:freecal/core/database/database_helper.dart';
import 'package:freecal/features/calendar/data/models/calendar_model.dart';
import 'package:freecal/features/calendar/domain/entities/calendar_entity.dart';
import 'package:freecal/features/calendar/domain/repositories/calendar_repository.dart';

/// SQLite-backed implementation of [CalendarRepository].
class CalendarRepositoryImpl implements CalendarRepository {
  CalendarRepositoryImpl({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;
  final StreamController<List<CalendarEntity>> _controller =
      StreamController<List<CalendarEntity>>.broadcast();

  @override
  Future<List<CalendarEntity>> getAllCalendars() async {
    final db = await _dbHelper.database;
    final maps = await db.query('calendars');
    return maps.map((m) => CalendarModel.fromMap(m).toEntity()).toList();
  }

  @override
  Future<CalendarEntity?> getCalendarById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'calendars',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CalendarModel.fromMap(maps.first).toEntity();
  }

  @override
  Future<String> insertCalendar(CalendarEntity calendar) async {
    final db = await _dbHelper.database;
    final model = CalendarModel.fromEntity(calendar);
    await db.insert('calendars', model.toMap());
    _notifyListeners();
    return calendar.id;
  }

  @override
  Future<void> updateCalendar(CalendarEntity calendar) async {
    final db = await _dbHelper.database;
    final model = CalendarModel.fromEntity(calendar);
    await db.update(
      'calendars',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [calendar.id],
    );
    _notifyListeners();
  }

  @override
  Future<void> deleteCalendar(String id) async {
    final db = await _dbHelper.database;
    await db.delete('calendars', where: 'id = ?', whereArgs: [id]);
    _notifyListeners();
  }

  @override
  Stream<List<CalendarEntity>> watchCalendars() {
    // Emit current state immediately
    getAllCalendars().then(_controller.add);
    return _controller.stream;
  }

  void _notifyListeners() {
    getAllCalendars().then(_controller.add);
  }

  void dispose() {
    _controller.close();
  }
}
