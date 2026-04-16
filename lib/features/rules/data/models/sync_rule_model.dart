import 'package:freecal/features/events/domain/entities/mirror_link_entity.dart';
import 'package:freecal/features/rules/domain/entities/sync_rule_entity.dart';

/// SQLite data model for [SyncRuleEntity].
class SyncRuleModel {
  const SyncRuleModel({
    required this.id,
    required this.sourceCalendarId,
    required this.targetCalendarId,
    required this.mode,
    this.timeWindowStart,
    this.timeWindowEnd,
    required this.isActive,
  });

  final String id;
  final String sourceCalendarId;
  final String targetCalendarId;
  final String mode;
  final int? timeWindowStart;
  final int? timeWindowEnd;
  final int isActive;

  factory SyncRuleModel.fromMap(Map<String, Object?> map) {
    return SyncRuleModel(
      id: map['id'] as String,
      sourceCalendarId: map['sourceCalendarId'] as String,
      targetCalendarId: map['targetCalendarId'] as String,
      mode: map['mode'] as String,
      timeWindowStart: map['timeWindowStart'] as int?,
      timeWindowEnd: map['timeWindowEnd'] as int?,
      isActive: map['isActive'] as int,
    );
  }

  factory SyncRuleModel.fromEntity(SyncRuleEntity entity) {
    return SyncRuleModel(
      id: entity.id,
      sourceCalendarId: entity.sourceCalendarId,
      targetCalendarId: entity.targetCalendarId,
      mode: entity.mode.name,
      timeWindowStart: entity.timeWindowStart,
      timeWindowEnd: entity.timeWindowEnd,
      isActive: entity.isActive ? 1 : 0,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'sourceCalendarId': sourceCalendarId,
      'targetCalendarId': targetCalendarId,
      'mode': mode,
      'timeWindowStart': timeWindowStart,
      'timeWindowEnd': timeWindowEnd,
      'isActive': isActive,
    };
  }

  SyncRuleEntity toEntity() {
    return SyncRuleEntity(
      id: id,
      sourceCalendarId: sourceCalendarId,
      targetCalendarId: targetCalendarId,
      mode: _modeFromString(mode),
      timeWindowStart: timeWindowStart,
      timeWindowEnd: timeWindowEnd,
      isActive: isActive == 1,
    );
  }

  static MirrorMode _modeFromString(String value) {
    return MirrorMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MirrorMode.busy,
    );
  }
}
