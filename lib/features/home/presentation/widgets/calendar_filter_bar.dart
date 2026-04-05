import 'package:flutter/material.dart';

import '../../../calendars/data/models/calendar_model.dart';
import '../../../../core/widgets/calendar_color_dot.dart';

/// Horizontal filter bar to toggle calendar visibility.
class CalendarFilterBar extends StatelessWidget {
  final List<CalendarModel> calendars;
  final Set<String> activeCalendarIds;
  final ValueChanged<String> onToggle;

  const CalendarFilterBar({
    super.key,
    required this.calendars,
    required this.activeCalendarIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (calendars.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: calendars.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cal = calendars[index];
          final isActive = activeCalendarIds.contains(cal.id);
          return FilterChip(
            selected: isActive,
            showCheckmark: false,
            avatar: CalendarColorDot(colorValue: cal.color, size: 10),
            label: Text(cal.name, style: const TextStyle(fontSize: 12)),
            onSelected: (_) => onToggle(cal.id),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}
