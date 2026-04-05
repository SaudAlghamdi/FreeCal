import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freecal/features/calendar/domain/entities/calendar_entity.dart';
import 'package:freecal/features/calendar/presentation/providers/calendar_provider.dart';
import 'package:freecal/features/events/domain/entities/event_entity.dart';
import 'package:freecal/features/events/domain/entities/mirror_link_entity.dart';
import 'package:freecal/features/events/presentation/providers/event_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Displays full details for a single event.
class EventDetailsScreen extends ConsumerWidget {
  const EventDetailsScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsStreamProvider);
    final mirrorLinksAsync =
        ref.watch(mirrorLinksForEventProvider(eventId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: eventsAsync.when(
        data: (events) {
          final EventEntity? event;
          try {
            event = events.firstWhere((e) => e.id == eventId);
          } on StateError {
            return const Center(child: Text('Event not found'));
          }

          return _EventDetailsBody(
            event: event,
            mirrorLinksAsync: mirrorLinksAsync,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event?'),
        content: const Text(
          'This event and all its mirror links will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => ctx.pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(eventRepositoryProvider).deleteEvent(eventId);
      if (context.mounted) context.pop();
    }
  }
}

class _EventDetailsBody extends ConsumerWidget {
  const _EventDetailsBody({
    required this.event,
    required this.mirrorLinksAsync,
  });

  final EventEntity event;
  final AsyncValue<List<MirrorLinkEntity>> mirrorLinksAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final calendarsAsync = ref.watch(calendarsStreamProvider);
    final dateFormat = DateFormat('EEEE, MMM d, y');
    final timeFormat = DateFormat.jm();

    final calColor = _resolveCalendarColor(
      calendarsAsync,
      event.sourceCalendarId,
      colorScheme.primary,
    );
    final calName = _resolveCalendarName(
      calendarsAsync,
      event.sourceCalendarId,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 6,
              height: 56,
              decoration: BoxDecoration(
                color: calColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      CircleAvatar(radius: 6, backgroundColor: calColor),
                      const SizedBox(width: 6),
                      Text(
                        calName,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: colorScheme.outline),
                      ),
                      if (event.isMirror) ...[
                        const SizedBox(width: 8),
                        const Chip(
                          label: Text('Mirror'),
                          avatar: Icon(Icons.sync, size: 12),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _DetailRow(
          icon: Icons.schedule,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dateFormat.format(event.startTime)),
              Text(
                '${timeFormat.format(event.startTime)} – '
                '${timeFormat.format(event.endTime)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
        if (event.location != null) ...[
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.location_on_outlined,
            child: Text(event.location!),
          ),
        ],
        if (event.notes != null) ...[
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.notes,
            child: Text(event.notes!),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          'Mirror Targets',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
              ),
        ),
        const SizedBox(height: 8),
        mirrorLinksAsync.when(
          data: (links) {
            if (links.isEmpty) {
              return Text(
                'No mirroring configured',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
              );
            }
            return Column(
              children: links
                  .map<Widget>((link) => _MirrorLinkTile(link: link))
                  .toList(),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }

  Color _resolveCalendarColor(
    AsyncValue<List<CalendarEntity>> calendarsAsync,
    String calendarId,
    Color fallback,
  ) {
    return calendarsAsync.whenOrNull(
          data: (cals) {
            try {
              return cals.firstWhere((c) => c.id == calendarId).color;
            } on StateError {
              return fallback;
            }
          },
        ) ??
        fallback;
  }

  String _resolveCalendarName(
    AsyncValue<List<CalendarEntity>> calendarsAsync,
    String calendarId,
  ) {
    return calendarsAsync.whenOrNull(
          data: (cals) {
            try {
              return cals.firstWhere((c) => c.id == calendarId).name;
            } on StateError {
              return 'Unknown';
            }
          },
        ) ??
        'Unknown';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.child});

  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 12),
        Expanded(child: child),
      ],
    );
  }
}

class _MirrorLinkTile extends ConsumerWidget {
  const _MirrorLinkTile({required this.link});

  final MirrorLinkEntity link;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final calendarsAsync = ref.watch(calendarsStreamProvider);

    final calName = calendarsAsync.whenOrNull(
          data: (cals) {
            try {
              return cals.firstWhere((c) => c.id == link.targetCalendarId).name;
            } on StateError {
              return 'Unknown';
            }
          },
        ) ??
        'Unknown';

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.sync_alt, size: 16, color: colorScheme.primary),
      title: Text(calName),
      trailing: Chip(
        label: Text(
          link.mirrorMode.label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
