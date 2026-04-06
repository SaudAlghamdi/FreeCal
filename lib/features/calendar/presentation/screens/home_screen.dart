import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freecal/features/calendar/domain/entities/calendar_entity.dart';
import 'package:freecal/features/calendar/presentation/providers/calendar_provider.dart';
import 'package:freecal/features/events/domain/entities/event_entity.dart';
import 'package:freecal/features/events/presentation/providers/event_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

/// The main Home Screen showing the unified calendar view.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;
  String? _filterCalendarId;

  @override
  Widget build(BuildContext context) {
    final calendarsAsync = ref.watch(calendarsStreamProvider);
    final eventsAsync = ref.watch(eventsStreamProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FreeCal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.rule),
            tooltip: 'Sync Rules',
            onPressed: () => context.push('/rules'),
          ),
          IconButton(
            icon: const Icon(Icons.warning_amber_outlined),
            tooltip: 'Conflicts',
            onPressed: () => context.push('/conflicts'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar filter chips
          calendarsAsync.when(
            data: (calendars) => _buildCalendarFilterChips(
              context,
              calendars,
              colorScheme,
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // TableCalendar
          eventsAsync.when(
            data: (events) => _buildCalendar(context, events, colorScheme),
            loading: () => _buildCalendar(context, [], colorScheme),
            error: (_, __) => _buildCalendar(context, [], colorScheme),
          ),

          const Divider(height: 1),

          // Event list for selected day
          Expanded(
            child: eventsAsync.when(
              data: (events) =>
                  _buildEventList(context, events, colorScheme),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-event'),
        tooltip: 'Add Event',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalendarFilterChips(
    BuildContext context,
    List<CalendarEntity> calendars,
    ColorScheme colorScheme,
  ) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: calendars.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            // "All" chip
            return FilterChip(
              label: const Text('All'),
              selected: _filterCalendarId == null,
              onSelected: (_) =>
                  setState(() => _filterCalendarId = null),
            );
          }
          final cal = calendars[index - 1];
          return FilterChip(
            avatar: CircleAvatar(
              radius: 6,
              backgroundColor: cal.color,
            ),
            label: Text(cal.name),
            selected: _filterCalendarId == cal.id,
            selectedColor: cal.color.withValues(alpha: 0.2),
            onSelected: (_) =>
                setState(() => _filterCalendarId = cal.id),
          );
        },
      ),
    );
  }

  Widget _buildCalendar(
    BuildContext context,
    List<EventEntity> events,
    ColorScheme colorScheme,
  ) {
    final filtered = _filterCalendarId == null
        ? events
        : events
            .where((e) => e.sourceCalendarId == _filterCalendarId)
            .toList();

    Map<DateTime, List<EventEntity>> eventsByDay = {};
    for (final event in filtered) {
      final day = DateTime(
        event.startTime.year,
        event.startTime.month,
        event.startTime.day,
      );
      eventsByDay[day] = [...(eventsByDay[day] ?? []), event];
    }

    return TableCalendar<EventEntity>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selected, focused) {
        setState(() {
          _selectedDay = selected;
          _focusedDay = focused;
        });
      },
      onFormatChanged: (format) {
        setState(() => _calendarFormat = format);
      },
      eventLoader: (day) {
        final key = DateTime(day.year, day.month, day.day);
        return eventsByDay[key] ?? [];
      },
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(color: colorScheme.onPrimaryContainer),
        selectedDecoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: TextStyle(color: colorScheme.onPrimary),
        markerDecoration: BoxDecoration(
          color: colorScheme.tertiary,
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: HeaderStyle(
        formatButtonDecoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        formatButtonTextStyle: TextStyle(color: colorScheme.primary),
        titleTextStyle: Theme.of(context).textTheme.titleMedium!,
      ),
    );
  }

  Widget _buildEventList(
    BuildContext context,
    List<EventEntity> events,
    ColorScheme colorScheme,
  ) {
    final dayEvents = events.where((e) {
      final sameDay = isSameDay(e.startTime, _selectedDay);
      if (_filterCalendarId != null) {
        return sameDay && e.sourceCalendarId == _filterCalendarId;
      }
      return sameDay;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    if (dayEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_available,
              size: 48,
              color: colorScheme.outlineVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No events on this day',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.outline,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: dayEvents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _EventTile(event: dayEvents[index]);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable Event Tile Widget
// ---------------------------------------------------------------------------

class _EventTile extends ConsumerWidget {
  const _EventTile({required this.event});

  final EventEntity event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarsAsync = ref.watch(calendarsStreamProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final timeFormat = DateFormat.jm();

    final calColor = calendarsAsync.whenOrNull(
          data: (cals) {
            try {
              return cals
                  .firstWhere((c) => c.id == event.sourceCalendarId)
                  .color;
            } on StateError {
              return colorScheme.primary;
            }
          },
        ) ??
        colorScheme.primary;

    return Card(
      child: InkWell(
        onTap: () => context.push('/event/${event.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Color indicator
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: calColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.isMirror
                                ? _getMirrorDisplayTitle(event)
                                : event.title,
                            style: Theme.of(context).textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (event.isMirror) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.sync,
                            size: 14,
                            color: colorScheme.outline,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${timeFormat.format(event.startTime)} – '
                      '${timeFormat.format(event.endTime)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                    ),
                    if (event.location != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: colorScheme.outline),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMirrorDisplayTitle(EventEntity event) {
    // For privacy: mirror events don't show details
    return 'Busy';
  }
}
