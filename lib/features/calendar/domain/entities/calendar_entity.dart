import 'package:flutter/material.dart';

/// Represents a calendar in FreeCal.
class CalendarEntity {
  const CalendarEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
  });

  final String id;
  final String name;
  final CalendarType type;
  final Color color;

  CalendarEntity copyWith({
    String? id,
    String? name,
    CalendarType? type,
    Color? color,
  }) {
    return CalendarEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CalendarEntity(id: $id, name: $name, type: $type)';
}

enum CalendarType {
  personal,
  work,
  business,
  family;

  String get label {
    switch (this) {
      case CalendarType.personal:
        return 'Personal';
      case CalendarType.work:
        return 'Work';
      case CalendarType.business:
        return 'Business';
      case CalendarType.family:
        return 'Family';
    }
  }
}
