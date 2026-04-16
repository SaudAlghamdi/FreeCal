import 'package:freecal/features/events/domain/entities/mirror_link_entity.dart';

/// SQLite data model for [MirrorLinkEntity].
class MirrorLinkModel {
  const MirrorLinkModel({
    required this.id,
    required this.sourceEventId,
    required this.targetCalendarId,
    required this.mirrorMode,
  });

  final String id;
  final String sourceEventId;
  final String targetCalendarId;
  final String mirrorMode;

  factory MirrorLinkModel.fromMap(Map<String, Object?> map) {
    return MirrorLinkModel(
      id: map['id'] as String,
      sourceEventId: map['sourceEventId'] as String,
      targetCalendarId: map['targetCalendarId'] as String,
      mirrorMode: map['mirrorMode'] as String,
    );
  }

  factory MirrorLinkModel.fromEntity(MirrorLinkEntity entity) {
    return MirrorLinkModel(
      id: entity.id,
      sourceEventId: entity.sourceEventId,
      targetCalendarId: entity.targetCalendarId,
      mirrorMode: entity.mirrorMode.name,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'sourceEventId': sourceEventId,
      'targetCalendarId': targetCalendarId,
      'mirrorMode': mirrorMode,
    };
  }

  MirrorLinkEntity toEntity() {
    return MirrorLinkEntity(
      id: id,
      sourceEventId: sourceEventId,
      targetCalendarId: targetCalendarId,
      mirrorMode: _modeFromString(mirrorMode),
    );
  }

  static MirrorMode _modeFromString(String value) {
    return MirrorMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MirrorMode.busy,
    );
  }
}
