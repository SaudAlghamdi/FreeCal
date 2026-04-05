import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../calendars/data/models/calendar_model.dart';
import '../../../calendars/presentation/providers/calendar_notifier.dart';
import '../../../events/data/models/event_model.dart';
import '../../../events/presentation/providers/event_notifier.dart';
import '../../../events/presentation/screens/add_event_screen.dart';
import '../../../events/presentation/screens/event_details_screen.dart';
import '../widgets/calendar_filter_bar.dart';
import '../widgets/day_view.dart';
import '../widgets/week_view.dart';

/// Provides the set of active calendar IDs for filtering.
final _activeCalendarIdsProvider =
    StateProvider<Set<String>?>((ref) => null);

/// Tracks the currently selected date.
final _selectedDateProvider =
    StateProvider<DateTime>((ref) => DateTime.now());

/// Home screen with calendar day/week view, filter bar, and timeline.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarsAsync = ref.watch(calendarNotifierProvider);
    final eventsAsync = ref.watch(eventNotifierProvider);
    final selectedDate = ref.watch(_selectedDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FreeCal'),
        actions: [
          // Day/week toggle
          _ViewToggle(),
          // Today button
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Today',
            onPressed: () {
              ref.read(_selectedDateProvider.notifier).state = DateTime.now();
            },
          ),
        ],
      ),
      body: calendarsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (calendars) {
          // Initialize active calendar IDs on first load.
          var activeIds = ref.watch(_activeCalendarIdsProvider);
          if (activeIds == null) {
            activeIds = calendars.map((c) => c.id).toSet();
            Future.microtask(() {
              ref.read(_activeCalendarIdsProvider.notifier).state = activeIds;
            });
          }

          final calMap = <String, CalendarModel>{
            for (final c in calendars) c.id: c,
          };

          return eventsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (allEvents) {
              // Filter events by active calendars.
              final events = allEvents
                  .where((e) => activeIds!.contains(e.sourceCalendarId))
                  .toList();

              return Column(
                children: [
                  // Calendar filter bar
                  CalendarFilterBar(
                    calendars: calendars,
                    activeCalendarIds: activeIds!,
                    onToggle: (id) {
                      final current =
                          Set<String>.from(ref.read(_activeCalendarIdsProvider) ?? {});
                      if (current.contains(id)) {
                        current.remove(id);
                      } else {
                        current.add(id);
                      }
                      ref.read(_activeCalendarIdsProvider.notifier).state = current;
                    },
                  ),
                  const SizedBox(height: 4),
                  // Date header
                  _DateHeader(date: selectedDate),
                  const SizedBox(height: 4),
                  // Calendar view
                  Expanded(
                    child: _CalendarViewBody(
                      selectedDate: selectedDate,
                      events: events,
                      calendarMap: calMap,
                      onDaySelected: (day) {
                        ref.read(_selectedDateProvider.notifier).state = day;
                      },
                      onEventTap: (event) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EventDetailsScreen(event: event),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEvent(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToAddEvent(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEventScreen()),
    );
  }
}

/// Tracks whether the user is in day or week view.
final _viewModeProvider = StateProvider<_ViewMode>((ref) => _ViewMode.day);

enum _ViewMode { day, week }

class _ViewToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(_viewModeProvider);
    return SegmentedButton<_ViewMode>(
      segments: const [
        ButtonSegment(value: _ViewMode.day, icon: Icon(Icons.view_day, size: 18)),
        ButtonSegment(value: _ViewMode.week, icon: Icon(Icons.view_week, size: 18)),
      ],
      selected: {mode},
      onSelectionChanged: (selected) {
        ref.read(_viewModeProvider.notifier).state = selected.first;
      },
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime date;

  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _CalendarViewBody extends ConsumerWidget {
  final DateTime selectedDate;
  final List<EventModel> events;
  final Map<String, CalendarModel> calendarMap;
  final ValueChanged<DateTime> onDaySelected;
  final void Function(EventModel event) onEventTap;

  const _CalendarViewBody({
    required this.selectedDate,
    required this.events,
    required this.calendarMap,
    required this.onDaySelected,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(_viewModeProvider);

    return switch (mode) {
      _ViewMode.day => DayView(
          selectedDate: selectedDate,
          events: events,
          calendarMap: calendarMap,
          onEventTap: onEventTap,
        ),
      _ViewMode.week => WeekView(
          selectedDate: selectedDate,
          events: events,
          calendarMap: calendarMap,
          onDaySelected: onDaySelected,
          onEventTap: onEventTap,
        ),
    };
  }
}
