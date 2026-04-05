/// Represents an event (source or mirrored) in the local database.
///
/// Times are stored as ISO 8601 strings for SQLite compatibility.
class EventModel {
  final String id;
  final String title;
  final String startTime;
  final String endTime;
  final String sourceCalendarId;
  final bool isMirror;
  final String? notes;
  final String? location;

  const EventModel({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.sourceCalendarId,
    required this.isMirror,
    this.notes,
    this.location,
  });

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'] as String,
      title: map['title'] as String,
      startTime: map['startTime'] as String,
      endTime: map['endTime'] as String,
      sourceCalendarId: map['sourceCalendarId'] as String,
      isMirror: (map['isMirror'] as int) == 1,
      notes: map['notes'] as String?,
      location: map['location'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'startTime': startTime,
      'endTime': endTime,
      'sourceCalendarId': sourceCalendarId,
      'isMirror': isMirror ? 1 : 0,
      'notes': notes,
      'location': location,
    };
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? startTime,
    String? endTime,
    String? sourceCalendarId,
    bool? isMirror,
    String? notes,
    String? location,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      sourceCalendarId: sourceCalendarId ?? this.sourceCalendarId,
      isMirror: isMirror ?? this.isMirror,
      notes: notes ?? this.notes,
      location: location ?? this.location,
    );
  }
}
