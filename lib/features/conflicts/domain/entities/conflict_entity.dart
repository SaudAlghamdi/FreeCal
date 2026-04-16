import 'package:freecal/features/events/domain/entities/event_entity.dart';

/// Represents a scheduling conflict between two events.
class ConflictEntity {
  const ConflictEntity({
    required this.id,
    required this.eventA,
    required this.eventB,
    required this.type,
  });

  final String id;
  final EventEntity eventA;
  final EventEntity eventB;
  final ConflictType type;

  bool get isResolved => false;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConflictEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ConflictEntity(type: $type, a: ${eventA.title}, b: ${eventB.title})';
}

enum ConflictType {
  sameCalendar,
  crossCalendar,
  duplicateMirror;

  String get label {
    switch (this) {
      case ConflictType.sameCalendar:
        return 'Same Calendar Overlap';
      case ConflictType.crossCalendar:
        return 'Cross-Calendar Conflict';
      case ConflictType.duplicateMirror:
        return 'Duplicate Mirror';
    }
  }
}

enum ConflictResolution {
  keepBoth,
  convertToBusy,
  reschedule,
  disableMirroring;

  String get label {
    switch (this) {
      case ConflictResolution.keepBoth:
        return 'Keep Both';
      case ConflictResolution.convertToBusy:
        return 'Convert to Busy';
      case ConflictResolution.reschedule:
        return 'Reschedule';
      case ConflictResolution.disableMirroring:
        return 'Disable Mirroring';
    }
  }
}
