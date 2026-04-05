import 'dart:async';

import 'package:freecal/core/database/database_helper.dart';
import 'package:freecal/features/events/data/models/event_model.dart';
import 'package:freecal/features/events/data/models/event_target_settings_model.dart';
import 'package:freecal/features/events/data/models/mirror_link_model.dart';
import 'package:freecal/features/events/domain/entities/event_entity.dart';
import 'package:freecal/features/events/domain/entities/event_target_settings_entity.dart';
import 'package:freecal/features/events/domain/entities/mirror_link_entity.dart';
import 'package:freecal/features/events/domain/repositories/event_repository.dart';

/// SQLite-backed implementation of [EventRepository].
class EventRepositoryImpl implements EventRepository {
  EventRepositoryImpl({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;
  final StreamController<List<EventEntity>> _controller =
      StreamController<List<EventEntity>>.broadcast();

  // ---------------------------------------------------------------------------
  // Events
  // ---------------------------------------------------------------------------

  @override
  Future<List<EventEntity>> getAllEvents() async {
    final db = await _dbHelper.database;
    final maps = await db.query('events', orderBy: 'startTime ASC');
    return maps.map((m) => EventModel.fromMap(m).toEntity()).toList();
  }

  @override
  Future<List<EventEntity>> getEventsByCalendar(String calendarId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'events',
      where: 'sourceCalendarId = ?',
      whereArgs: [calendarId],
      orderBy: 'startTime ASC',
    );
    return maps.map((m) => EventModel.fromMap(m).toEntity()).toList();
  }

  @override
  Future<List<EventEntity>> getEventsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'events',
      where: 'startTime >= ? AND endTime <= ?',
      whereArgs: [
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
      orderBy: 'startTime ASC',
    );
    return maps.map((m) => EventModel.fromMap(m).toEntity()).toList();
  }

  @override
  Future<EventEntity?> getEventById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'events',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return EventModel.fromMap(maps.first).toEntity();
  }

  @override
  Future<String> insertEvent(EventEntity event) async {
    final db = await _dbHelper.database;
    final model = EventModel.fromEntity(event);
    await db.insert('events', model.toMap());
    _notifyListeners();
    return event.id;
  }

  @override
  Future<void> updateEvent(EventEntity event) async {
    final db = await _dbHelper.database;
    final model = EventModel.fromEntity(event);
    await db.update(
      'events',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
    _notifyListeners();
  }

  @override
  Future<void> deleteEvent(String id) async {
    final db = await _dbHelper.database;
    await db.delete('events', where: 'id = ?', whereArgs: [id]);
    _notifyListeners();
  }

  @override
  Stream<List<EventEntity>> watchEvents() {
    getAllEvents().then(_controller.add);
    return _controller.stream;
  }

  // ---------------------------------------------------------------------------
  // Mirror Links
  // ---------------------------------------------------------------------------

  @override
  Future<List<MirrorLinkEntity>> getMirrorLinksForEvent(
    String eventId,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'mirror_links',
      where: 'sourceEventId = ?',
      whereArgs: [eventId],
    );
    return maps.map((m) => MirrorLinkModel.fromMap(m).toEntity()).toList();
  }

  @override
  Future<List<MirrorLinkEntity>> getMirrorLinksForCalendar(
    String targetCalendarId,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'mirror_links',
      where: 'targetCalendarId = ?',
      whereArgs: [targetCalendarId],
    );
    return maps.map((m) => MirrorLinkModel.fromMap(m).toEntity()).toList();
  }

  @override
  Future<String> insertMirrorLink(MirrorLinkEntity link) async {
    final db = await _dbHelper.database;
    final model = MirrorLinkModel.fromEntity(link);
    await db.insert('mirror_links', model.toMap());
    return link.id;
  }

  @override
  Future<void> updateMirrorLink(MirrorLinkEntity link) async {
    final db = await _dbHelper.database;
    final model = MirrorLinkModel.fromEntity(link);
    await db.update(
      'mirror_links',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [link.id],
    );
  }

  @override
  Future<void> deleteMirrorLink(String id) async {
    final db = await _dbHelper.database;
    await db.delete('mirror_links', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> deleteMirrorLinksForEvent(String eventId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'mirror_links',
      where: 'sourceEventId = ?',
      whereArgs: [eventId],
    );
  }

  // ---------------------------------------------------------------------------
  // Event Target Settings
  // ---------------------------------------------------------------------------

  @override
  Future<List<EventTargetSettingsEntity>> getTargetSettingsForEvent(
    String eventId,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'event_target_settings',
      where: 'eventId = ?',
      whereArgs: [eventId],
    );
    return maps
        .map((m) => EventTargetSettingsModel.fromMap(m).toEntity())
        .toList();
  }

  @override
  Future<EventTargetSettingsEntity?> getTargetSettingsForEventAndCalendar(
    String eventId,
    String targetCalendarId,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'event_target_settings',
      where: 'eventId = ? AND targetCalendarId = ?',
      whereArgs: [eventId, targetCalendarId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return EventTargetSettingsModel.fromMap(maps.first).toEntity();
  }

  @override
  Future<String> insertTargetSettings(
    EventTargetSettingsEntity settings,
  ) async {
    final db = await _dbHelper.database;
    final model = EventTargetSettingsModel.fromEntity(settings);
    await db.insert('event_target_settings', model.toMap());
    return settings.id;
  }

  @override
  Future<void> updateTargetSettings(
    EventTargetSettingsEntity settings,
  ) async {
    final db = await _dbHelper.database;
    final model = EventTargetSettingsModel.fromEntity(settings);
    await db.update(
      'event_target_settings',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [settings.id],
    );
  }

  @override
  Future<void> deleteTargetSettings(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'event_target_settings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _notifyListeners() {
    getAllEvents().then(_controller.add);
  }

  void dispose() {
    _controller.close();
  }
}
