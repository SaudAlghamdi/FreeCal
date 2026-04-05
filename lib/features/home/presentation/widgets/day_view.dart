import 'package:flutter/material.dart';

import '../../../calendars/data/models/calendar_model.dart';
import '../../../events/data/models/event_model.dart';
import 'event_tile.dart';

/// Displays events for a single day as a vertical timeline.
class DayView extends StatelessWidget {
  final DateTime selectedDate;
  final List<EventModel> events;
  final Map<String, CalendarModel> calendarMap;
  final void Function(EventModel event) onEventTap;

  const DayView({
    super.key,
    required this.selectedDate,
    required this.events,
    required this.calendarMap,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    final dayEvents = events.where((e) {
      final dt = DateTime.tryParse(e.startTime);
      if (dt == null) return false;
      return dt.year == selectedDate.year &&
          dt.month == selectedDate.month &&
          dt.day == selectedDate.day;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    if (dayEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(
              'No events',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: dayEvents.length,
      itemBuilder: (context, index) {
        final event = dayEvents[index];
        return EventTile(
          event: event,
          calendar: calendarMap[event.sourceCalendarId],
          onTap: () => onEventTap(event),
        );
      },
    );
  }
}
