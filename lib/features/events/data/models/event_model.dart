import 'package:freecal/features/events/domain/entities/event_entity.dart';

/// SQLite data model for [EventEntity].
class EventModel {
  const EventModel({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.sourceCalendarId,
    this.notes,
    this.location,
    required this.isMirror,
    required this.isAllDay,
  });

  final String id;
  final String title;
  final int startTime;
  final int endTime;
  final String sourceCalendarId;
  final String? notes;
  final String? location;
  final int isMirror;
  final int isAllDay;

  factory EventModel.fromMap(Map<String, Object?> map) {
    return EventModel(
      id: map['id'] as String,
      title: map['title'] as String,
      startTime: map['startTime'] as int,
      endTime: map['endTime'] as int,
      sourceCalendarId: map['sourceCalendarId'] as String,
      notes: map['notes'] as String?,
      location: map['location'] as String?,
      isMirror: map['isMirror'] as int,
      isAllDay: map['isAllDay'] as int,
    );
  }

  factory EventModel.fromEntity(EventEntity entity) {
    return EventModel(
      id: entity.id,
      title: entity.title,
      startTime: entity.startTime.millisecondsSinceEpoch,
      endTime: entity.endTime.millisecondsSinceEpoch,
      sourceCalendarId: entity.sourceCalendarId,
      notes: entity.notes,
      location: entity.location,
      isMirror: entity.isMirror ? 1 : 0,
      isAllDay: entity.isAllDay ? 1 : 0,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'startTime': startTime,
      'endTime': endTime,
      'sourceCalendarId': sourceCalendarId,
      'notes': notes,
      'location': location,
      'isMirror': isMirror,
      'isAllDay': isAllDay,
    };
  }

  EventEntity toEntity() {
    return EventEntity(
      id: id,
      title: title,
      startTime: DateTime.fromMillisecondsSinceEpoch(startTime),
      endTime: DateTime.fromMillisecondsSinceEpoch(endTime),
      sourceCalendarId: sourceCalendarId,
      notes: notes,
      location: location,
      isMirror: isMirror == 1,
      isAllDay: isAllDay == 1,
    );
  }
}
