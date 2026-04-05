import 'package:freecal/features/events/domain/entities/mirror_link_entity.dart';

/// Per-event override settings for a specific target calendar.
class EventTargetSettingsEntity {
  const EventTargetSettingsEntity({
    required this.id,
    required this.eventId,
    required this.targetCalendarId,
    required this.mode,
    this.overrideRule = false,
    this.hideDetails = false,
    this.applyWorkHoursRule = false,
  });

  final String id;
  final String eventId;
  final String targetCalendarId;
  final MirrorMode mode;
  final bool overrideRule;
  final bool hideDetails;
  final bool applyWorkHoursRule;

  EventTargetSettingsEntity copyWith({
    String? id,
    String? eventId,
    String? targetCalendarId,
    MirrorMode? mode,
    bool? overrideRule,
    bool? hideDetails,
    bool? applyWorkHoursRule,
  }) {
    return EventTargetSettingsEntity(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      targetCalendarId: targetCalendarId ?? this.targetCalendarId,
      mode: mode ?? this.mode,
      overrideRule: overrideRule ?? this.overrideRule,
      hideDetails: hideDetails ?? this.hideDetails,
      applyWorkHoursRule: applyWorkHoursRule ?? this.applyWorkHoursRule,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventTargetSettingsEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'EventTargetSettingsEntity(eventId: $eventId, '
      'targetCalendarId: $targetCalendarId, mode: $mode)';
}
