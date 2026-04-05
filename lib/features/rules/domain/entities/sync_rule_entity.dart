import 'package:freecal/features/events/domain/entities/mirror_link_entity.dart';

/// A sync rule that automatically mirrors events between two calendars.
class SyncRuleEntity {
  const SyncRuleEntity({
    required this.id,
    required this.sourceCalendarId,
    required this.targetCalendarId,
    required this.mode,
    this.timeWindowStart,
    this.timeWindowEnd,
    this.isActive = true,
  });

  final String id;
  final String sourceCalendarId;
  final String targetCalendarId;
  final MirrorMode mode;

  /// Optional start of the time window (hour of day, 0–23).
  final int? timeWindowStart;

  /// Optional end of the time window (hour of day, 0–23).
  final int? timeWindowEnd;

  final bool isActive;

  bool get hasTimeWindow =>
      timeWindowStart != null && timeWindowEnd != null;

  /// Returns true if the given [hour] falls within this rule's time window.
  bool isHourInWindow(int hour) {
    if (!hasTimeWindow) return true;
    final start = timeWindowStart!;
    final end = timeWindowEnd!;
    return hour >= start && hour < end;
  }

  /// Returns true if the given [dateTime] falls within the rule's time window.
  bool isInTimeWindow(DateTime dateTime) {
    if (!hasTimeWindow) return true;
    return isHourInWindow(dateTime.hour);
  }

  SyncRuleEntity copyWith({
    String? id,
    String? sourceCalendarId,
    String? targetCalendarId,
    MirrorMode? mode,
    int? timeWindowStart,
    int? timeWindowEnd,
    bool? isActive,
  }) {
    return SyncRuleEntity(
      id: id ?? this.id,
      sourceCalendarId: sourceCalendarId ?? this.sourceCalendarId,
      targetCalendarId: targetCalendarId ?? this.targetCalendarId,
      mode: mode ?? this.mode,
      timeWindowStart: timeWindowStart ?? this.timeWindowStart,
      timeWindowEnd: timeWindowEnd ?? this.timeWindowEnd,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncRuleEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SyncRuleEntity(source: $sourceCalendarId, target: $targetCalendarId, '
      'mode: $mode, window: $timeWindowStart–$timeWindowEnd)';
}
