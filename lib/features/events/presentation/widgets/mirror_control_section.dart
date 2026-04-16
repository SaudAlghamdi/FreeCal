import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freecal/features/calendar/domain/entities/calendar_entity.dart';
import 'package:freecal/features/events/domain/entities/event_target_settings_entity.dart';
import 'package:freecal/features/events/domain/entities/mirror_link_entity.dart';
import 'package:freecal/features/events/presentation/providers/event_provider.dart';
import 'package:freecal/features/rules/domain/entities/sync_rule_entity.dart';
import 'package:freecal/features/rules/presentation/providers/rules_provider.dart';

/// The Mirror Control Section displayed in AddEventScreen.
/// Allows users to configure how an event appears in each target calendar.
class MirrorControlSection extends ConsumerWidget {
  const MirrorControlSection({
    super.key,
    required this.targetCalendars,
    required this.sourceCalendarId,
    required this.startTime,
  });

  final List<CalendarEntity> targetCalendars;
  final String sourceCalendarId;
  final DateTime startTime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final formState = ref.watch(eventFormProvider);
    final rulesAsync = ref.watch(rulesForCalendarProvider(sourceCalendarId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(
              Icons.sync_alt,
              size: 18,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Show in Other Calendars',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Per-calendar mirror mode selectors
        ...targetCalendars.map((calendar) {
          final settings = formState.targetSettings.firstWhere(
            (s) => s.targetCalendarId == calendar.id,
            orElse: () => EventTargetSettingsEntity(
              id: calendar.id,
              eventId: '',
              targetCalendarId: calendar.id,
              mode: _getDefaultMode(calendar.id, rulesAsync),
            ),
          );

          return _MirrorCalendarRow(
            calendar: calendar,
            settings: settings,
            startTime: startTime,
            onModeChanged: (mode) {
              ref
                  .read(eventFormProvider.notifier)
                  .setModeForCalendar(calendar.id, mode);
            },
            onSettingsChanged: (updated) {
              ref
                  .read(eventFormProvider.notifier)
                  .updateTargetSettings(updated);
            },
          );
        }),
      ],
    );
  }

  MirrorMode _getDefaultMode(
    String targetCalendarId,
    AsyncValue<List<SyncRuleEntity>> rulesAsync,
  ) {
    return rulesAsync.whenOrNull(
          data: (rules) {
            try {
              return rules
                  .firstWhere((r) => r.targetCalendarId == targetCalendarId)
                  .mode;
            } on StateError {
              return null;
            }
          },
        ) ??
        MirrorMode.none;
  }
}

// ---------------------------------------------------------------------------
// Per-calendar row widget
// ---------------------------------------------------------------------------

class _MirrorCalendarRow extends ConsumerStatefulWidget {
  const _MirrorCalendarRow({
    required this.calendar,
    required this.settings,
    required this.startTime,
    required this.onModeChanged,
    required this.onSettingsChanged,
  });

  final CalendarEntity calendar;
  final EventTargetSettingsEntity settings;
  final DateTime startTime;
  final void Function(MirrorMode) onModeChanged;
  final void Function(EventTargetSettingsEntity) onSettingsChanged;

  @override
  ConsumerState<_MirrorCalendarRow> createState() =>
      _MirrorCalendarRowState();
}

class _MirrorCalendarRowState extends ConsumerState<_MirrorCalendarRow> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final current = widget.settings;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar label and mode selector
            Row(
              children: [
                CircleAvatar(
                  radius: 8,
                  backgroundColor: widget.calendar.color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.calendar.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                _MirrorModeChip(
                  selectedMode: current.mode,
                  availableModes: _availableModes(widget.calendar.type),
                  onSelected: widget.onModeChanged,
                ),
              ],
            ),

            // Extra options (expanded)
            if (current.mode != MirrorMode.none) ...[
              const SizedBox(height: 4),
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Row(
                  children: [
                    Text(
                      'Options',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                          ),
                    ),
                    Icon(
                      _isExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              ),
              if (_isExpanded) ...[
                const SizedBox(height: 8),
                _OptionToggle(
                  label: 'Hide details',
                  subtitle: 'Show only time block, no title or notes',
                  value: current.hideDetails,
                  onChanged: (v) => widget.onSettingsChanged(
                    current.copyWith(hideDetails: v),
                  ),
                ),
                _OptionToggle(
                  label: 'Apply work-hours rule',
                  subtitle: 'Only sync during allowed hours',
                  value: current.applyWorkHoursRule,
                  onChanged: (v) => widget.onSettingsChanged(
                    current.copyWith(applyWorkHoursRule: v),
                  ),
                ),
                _OptionToggle(
                  label: 'Override default rule',
                  subtitle: 'Use this setting instead of sync rules',
                  value: current.overrideRule,
                  onChanged: (v) => widget.onSettingsChanged(
                    current.copyWith(overrideRule: v),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  List<MirrorMode> _availableModes(CalendarType type) {
    switch (type) {
      case CalendarType.work:
        return [
          MirrorMode.busy,
          MirrorMode.outOfOffice,
          MirrorMode.full,
          MirrorMode.none,
        ];
      case CalendarType.business:
        return [MirrorMode.busy, MirrorMode.full, MirrorMode.none];
      case CalendarType.family:
        return [MirrorMode.full, MirrorMode.none];
      case CalendarType.personal:
        return MirrorMode.values;
    }
  }
}

// ---------------------------------------------------------------------------
// Mirror Mode Chip Selector
// ---------------------------------------------------------------------------

class _MirrorModeChip extends StatelessWidget {
  const _MirrorModeChip({
    required this.selectedMode,
    required this.availableModes,
    required this.onSelected,
  });

  final MirrorMode selectedMode;
  final List<MirrorMode> availableModes;
  final void Function(MirrorMode) onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<MirrorMode>(
      initialValue: selectedMode,
      onSelected: onSelected,
      itemBuilder: (context) => availableModes
          .map(
            (mode) => PopupMenuItem(
              value: mode,
              child: Row(
                children: [
                  Icon(
                    _iconForMode(mode),
                    size: 16,
                    color: _colorForMode(mode, Theme.of(context).colorScheme),
                  ),
                  const SizedBox(width: 8),
                  Text(mode.label),
                ],
              ),
            ),
          )
          .toList(),
      child: Chip(
        avatar: Icon(
          _iconForMode(selectedMode),
          size: 14,
          color: _colorForMode(
            selectedMode,
            Theme.of(context).colorScheme,
          ),
        ),
        label: Text(
          selectedMode.shortLabel,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  IconData _iconForMode(MirrorMode mode) {
    switch (mode) {
      case MirrorMode.full:
        return Icons.event_note;
      case MirrorMode.busy:
        return Icons.circle;
      case MirrorMode.outOfOffice:
        return Icons.do_not_disturb_on;
      case MirrorMode.none:
        return Icons.visibility_off;
    }
  }

  Color _colorForMode(MirrorMode mode, ColorScheme scheme) {
    switch (mode) {
      case MirrorMode.full:
        return scheme.primary;
      case MirrorMode.busy:
        return scheme.secondary;
      case MirrorMode.outOfOffice:
        return scheme.error;
      case MirrorMode.none:
        return scheme.outline;
    }
  }
}

// ---------------------------------------------------------------------------
// Option Toggle Row
// ---------------------------------------------------------------------------

class _OptionToggle extends StatelessWidget {
  const _OptionToggle({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String subtitle;
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      title: Text(label, style: Theme.of(context).textTheme.bodySmall),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
      ),
      value: value,
      onChanged: onChanged,
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }
}
