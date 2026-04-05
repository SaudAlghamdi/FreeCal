import 'package:freecal/features/events/domain/entities/event_target_settings_entity.dart';
import 'package:freecal/features/events/domain/entities/mirror_link_entity.dart';

/// SQLite data model for [EventTargetSettingsEntity].
class EventTargetSettingsModel {
  const EventTargetSettingsModel({
    required this.id,
    required this.eventId,
    required this.targetCalendarId,
    required this.mode,
    required this.overrideRule,
    required this.hideDetails,
    required this.applyWorkHoursRule,
  });

  final String id;
  final String eventId;
  final String targetCalendarId;
  final String mode;
  final int overrideRule;
  final int hideDetails;
  final int applyWorkHoursRule;

  factory EventTargetSettingsModel.fromMap(Map<String, Object?> map) {
    return EventTargetSettingsModel(
      id: map['id'] as String,
      eventId: map['eventId'] as String,
      targetCalendarId: map['targetCalendarId'] as String,
      mode: map['mode'] as String,
      overrideRule: map['overrideRule'] as int,
      hideDetails: map['hideDetails'] as int,
      applyWorkHoursRule: map['applyWorkHoursRule'] as int,
    );
  }

  factory EventTargetSettingsModel.fromEntity(
    EventTargetSettingsEntity entity,
  ) {
    return EventTargetSettingsModel(
      id: entity.id,
      eventId: entity.eventId,
      targetCalendarId: entity.targetCalendarId,
      mode: entity.mode.name,
      overrideRule: entity.overrideRule ? 1 : 0,
      hideDetails: entity.hideDetails ? 1 : 0,
      applyWorkHoursRule: entity.applyWorkHoursRule ? 1 : 0,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'targetCalendarId': targetCalendarId,
      'mode': mode,
      'overrideRule': overrideRule,
      'hideDetails': hideDetails,
      'applyWorkHoursRule': applyWorkHoursRule,
    };
  }

  EventTargetSettingsEntity toEntity() {
    return EventTargetSettingsEntity(
      id: id,
      eventId: eventId,
      targetCalendarId: targetCalendarId,
      mode: _modeFromString(mode),
      overrideRule: overrideRule == 1,
      hideDetails: hideDetails == 1,
      applyWorkHoursRule: applyWorkHoursRule == 1,
    );
  }

  static MirrorMode _modeFromString(String value) {
    return MirrorMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MirrorMode.busy,
    );
  }
}
