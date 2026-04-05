import 'package:flutter/material.dart';

import '../../../calendars/data/models/calendar_model.dart';
import '../../../events/data/models/event_model.dart';
import '../../../../core/widgets/calendar_color_dot.dart';

/// Displays a 7-day week strip with event dots and a list of selected day's events.
class WeekView extends StatelessWidget {
  final DateTime selectedDate;
  final List<EventModel> events;
  final Map<String, CalendarModel> calendarMap;
  final ValueChanged<DateTime> onDaySelected;
  final void Function(EventModel event) onEventTap;

  const WeekView({
    super.key,
    required this.selectedDate,
    required this.events,
    required this.calendarMap,
    required this.onDaySelected,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    final weekStart = selectedDate.subtract(
      Duration(days: selectedDate.weekday % 7),
    );
    final theme = Theme.of(context);

    return Column(
      children: [
        // Week day strip
        SizedBox(
          height: 72,
          child: Row(
            children: List.generate(7, (i) {
              final day = weekStart.add(Duration(days: i));
              final isSelected = day.year == selectedDate.year &&
                  day.month == selectedDate.month &&
                  day.day == selectedDate.day;
              final isToday = _isToday(day);
              final dayEvents = _eventsForDay(day);

              return Expanded(
                child: GestureDetector(
                  onTap: () => onDaySelected(day),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isToday && !isSelected
                          ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _dayAbbr(day.weekday),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${day.day}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Event dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: dayEvents.take(3).map((e) {
                            final color = calendarMap[e.sourceCalendarId]?.color ?? 0xFF9E9E9E;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 1),
                              child: CalendarColorDot(colorValue: color, size: 5),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const Divider(height: 1),
        // Day event list
        Expanded(
          child: _buildDayEventList(context),
        ),
      ],
    );
  }

  Widget _buildDayEventList(BuildContext context) {
    final dayEvents = _eventsForDay(selectedDate)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    if (dayEvents.isEmpty) {
      return Center(
        child: Text(
          'No events',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: dayEvents.length,
      itemBuilder: (context, index) {
        final event = dayEvents[index];
        final cal = calendarMap[event.sourceCalendarId];
        return _WeekEventRow(event: event, calendar: cal, onTap: () => onEventTap(event));
      },
    );
  }

  List<EventModel> _eventsForDay(DateTime day) {
    return events.where((e) {
      final dt = DateTime.tryParse(e.startTime);
      if (dt == null) return false;
      return dt.year == day.year && dt.month == day.month && dt.day == day.day;
    }).toList();
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  String _dayAbbr(int weekday) {
    const abbrs = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return abbrs[(weekday - 1) % 7];
  }
}

class _WeekEventRow extends StatelessWidget {
  final EventModel event;
  final CalendarModel? calendar;
  final VoidCallback onTap;

  const _WeekEventRow({
    required this.event,
    required this.calendar,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final calColor = calendar?.color ?? 0xFF9E9E9E;
    final startDt = DateTime.tryParse(event.startTime);
    final timeStr = startDt != null
        ? '${startDt.hour % 12 == 0 ? 12 : startDt.hour % 12}:${startDt.minute.toString().padLeft(2, '0')} ${startDt.hour < 12 ? 'AM' : 'PM'}'
        : '';

    return ListTile(
      onTap: onTap,
      dense: true,
      leading: CalendarColorDot(colorValue: calColor),
      title: Text(event.title, overflow: TextOverflow.ellipsis),
      trailing: Text(
        timeStr,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
