import 'package:flutter/material.dart';
import 'package:freecal/features/calendar/domain/entities/calendar_entity.dart';

/// SQLite data model for [CalendarEntity].
class CalendarModel {
  const CalendarModel({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
  });

  final String id;
  final String name;
  final String type;
  final int color;

  factory CalendarModel.fromMap(Map<String, Object?> map) {
    return CalendarModel(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      color: map['color'] as int,
    );
  }

  factory CalendarModel.fromEntity(CalendarEntity entity) {
    return CalendarModel(
      id: entity.id,
      name: entity.name,
      type: entity.type.name,
      color: entity.color.value,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'color': color,
    };
  }

  CalendarEntity toEntity() {
    return CalendarEntity(
      id: id,
      name: name,
      type: _typeFromString(type),
      color: Color(color),
    );
  }

  static CalendarType _typeFromString(String value) {
    return CalendarType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CalendarType.personal,
    );
  }
}
