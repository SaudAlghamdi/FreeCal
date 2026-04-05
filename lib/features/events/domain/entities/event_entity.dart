/// Represents a calendar event in FreeCal.
class EventEntity {
  const EventEntity({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.sourceCalendarId,
    this.notes,
    this.location,
    this.isMirror = false,
    this.isAllDay = false,
  });

  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String sourceCalendarId;
  final String? notes;
  final String? location;
  final bool isMirror;
  final bool isAllDay;

  EventEntity copyWith({
    String? id,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    String? sourceCalendarId,
    String? notes,
    String? location,
    bool? isMirror,
    bool? isAllDay,
  }) {
    return EventEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      sourceCalendarId: sourceCalendarId ?? this.sourceCalendarId,
      notes: notes ?? this.notes,
      location: location ?? this.location,
      isMirror: isMirror ?? this.isMirror,
      isAllDay: isAllDay ?? this.isAllDay,
    );
  }

  Duration get duration => endTime.difference(startTime);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'EventEntity(id: $id, title: $title, startTime: $startTime)';
}
