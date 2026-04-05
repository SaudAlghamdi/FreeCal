import 'package:flutter/material.dart';

import '../../../../core/enums/mirror_mode.dart';
import '../../../../core/widgets/calendar_color_dot.dart';
import '../../../calendars/data/models/calendar_model.dart';

/// Per-calendar mirror mode selection used in the Add Event screen.
///
/// Displays each target calendar with a segmented button to pick the mirror mode.
class MirrorControlSection extends StatelessWidget {
  final List<CalendarModel> targetCalendars;
  final Map<String, MirrorMode> selections;
  final ValueChanged<Map<String, MirrorMode>> onChanged;

  const MirrorControlSection({
    super.key,
    required this.targetCalendars,
    required this.selections,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (targetCalendars.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Show in other calendars', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ...targetCalendars.map((cal) {
          final mode = selections[cal.id] ?? MirrorMode.none;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CalendarColorDot(colorValue: cal.color),
                    const SizedBox(width: 8),
                    Text(cal.name, style: theme.textTheme.bodyMedium),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<MirrorMode>(
                    segments: MirrorMode.values.map((m) {
                      return ButtonSegment<MirrorMode>(
                        value: m,
                        label: Text(
                          m.label,
                          style: const TextStyle(fontSize: 11),
                        ),
                      );
                    }).toList(),
                    selected: {mode},
                    onSelectionChanged: (selected) {
                      final updated = Map<String, MirrorMode>.from(selections);
                      updated[cal.id] = selected.first;
                      onChanged(updated);
                    },
                    showSelectedIcon: false,
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
