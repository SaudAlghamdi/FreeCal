/// Represents a per-event override for how an event appears in a target calendar.
class EventTargetSettingModel {
  final String id;
  final String eventId;
  final String targetCalendarId;
  final String mode;
  final bool overrideRule;

  const EventTargetSettingModel({
    required this.id,
    required this.eventId,
    required this.targetCalendarId,
    required this.mode,
    required this.overrideRule,
  });

  factory EventTargetSettingModel.fromMap(Map<String, dynamic> map) {
    return EventTargetSettingModel(
      id: map['id'] as String,
      eventId: map['eventId'] as String,
      targetCalendarId: map['targetCalendarId'] as String,
      mode: map['mode'] as String,
      overrideRule: (map['overrideRule'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'targetCalendarId': targetCalendarId,
      'mode': mode,
      'overrideRule': overrideRule ? 1 : 0,
    };
  }

  EventTargetSettingModel copyWith({
    String? id,
    String? eventId,
    String? targetCalendarId,
    String? mode,
    bool? overrideRule,
  }) {
    return EventTargetSettingModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      targetCalendarId: targetCalendarId ?? this.targetCalendarId,
      mode: mode ?? this.mode,
      overrideRule: overrideRule ?? this.overrideRule,
    );
  }
}
