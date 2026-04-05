/// Represents a calendar entity in the local database.
class CalendarModel {
  final String id;
  final String name;
  final String type;
  final int color;

  const CalendarModel({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
  });

  factory CalendarModel.fromMap(Map<String, dynamic> map) {
    return CalendarModel(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      color: map['color'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'color': color,
    };
  }

  CalendarModel copyWith({
    String? id,
    String? name,
    String? type,
    int? color,
  }) {
    return CalendarModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      color: color ?? this.color,
    );
  }
}
