/// Represents a default sync rule between two calendars.
///
/// Time windows define when mirroring is active (e.g., 6 AM – 6 PM).
class SyncRuleModel {
  final String id;
  final String sourceCalendarId;
  final String targetCalendarId;
  final String mode;
  final String? timeWindowStart;
  final String? timeWindowEnd;

  const SyncRuleModel({
    required this.id,
    required this.sourceCalendarId,
    required this.targetCalendarId,
    required this.mode,
    this.timeWindowStart,
    this.timeWindowEnd,
  });

  factory SyncRuleModel.fromMap(Map<String, dynamic> map) {
    return SyncRuleModel(
      id: map['id'] as String,
      sourceCalendarId: map['sourceCalendarId'] as String,
      targetCalendarId: map['targetCalendarId'] as String,
      mode: map['mode'] as String,
      timeWindowStart: map['timeWindowStart'] as String?,
      timeWindowEnd: map['timeWindowEnd'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sourceCalendarId': sourceCalendarId,
      'targetCalendarId': targetCalendarId,
      'mode': mode,
      'timeWindowStart': timeWindowStart,
      'timeWindowEnd': timeWindowEnd,
    };
  }

  SyncRuleModel copyWith({
    String? id,
    String? sourceCalendarId,
    String? targetCalendarId,
    String? mode,
    String? timeWindowStart,
    String? timeWindowEnd,
  }) {
    return SyncRuleModel(
      id: id ?? this.id,
      sourceCalendarId: sourceCalendarId ?? this.sourceCalendarId,
      targetCalendarId: targetCalendarId ?? this.targetCalendarId,
      mode: mode ?? this.mode,
      timeWindowStart: timeWindowStart ?? this.timeWindowStart,
      timeWindowEnd: timeWindowEnd ?? this.timeWindowEnd,
    );
  }
}
