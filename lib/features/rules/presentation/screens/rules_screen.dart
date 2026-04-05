import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freecal/features/calendar/domain/entities/calendar_entity.dart';
import 'package:freecal/features/calendar/presentation/providers/calendar_provider.dart';
import 'package:freecal/features/events/domain/entities/mirror_link_entity.dart';
import 'package:freecal/features/rules/domain/entities/sync_rule_entity.dart';
import 'package:freecal/features/rules/presentation/providers/rules_provider.dart';

/// Displays and manages default sync rules between calendars.
class RulesScreen extends ConsumerWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(syncRulesStreamProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Rules'),
      ),
      body: rulesAsync.when(
        data: (rules) {
          if (rules.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.rule,
                    size: 56,
                    color: colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No sync rules configured',
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
            itemCount: rules.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _SyncRuleTile(rule: rules[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRuleDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Rule'),
      ),
    );
  }

  Future<void> _showAddRuleDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => const _AddRuleDialog(),
    );
  }
}

// ---------------------------------------------------------------------------
// Sync Rule Tile
// ---------------------------------------------------------------------------

class _SyncRuleTile extends ConsumerWidget {
  const _SyncRuleTile({required this.rule});

  final SyncRuleEntity rule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final calendarsAsync = ref.watch(calendarsStreamProvider);

    final sourceName = _resolveName(calendarsAsync, rule.sourceCalendarId);
    final targetName = _resolveName(calendarsAsync, rule.targetCalendarId);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _CalendarBadge(
                  name: sourceName,
                  color: colorScheme.primary,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: colorScheme.outline,
                  ),
                ),
                _CalendarBadge(
                  name: targetName,
                  color: colorScheme.secondary,
                ),
                const Spacer(),
                Switch.adaptive(
                  value: rule.isActive,
                  onChanged: (v) {
                    ref
                        .read(syncRuleRepositoryProvider)
                        .updateRule(rule.copyWith(isActive: v));
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(
                    rule.mode.label,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  avatar: Icon(
                    _iconForMode(rule.mode),
                    size: 14,
                    color: colorScheme.primary,
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                if (rule.hasTimeWindow) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(
                      '${rule.timeWindowStart}:00 – ${rule.timeWindowEnd}:00',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    avatar: Icon(
                      Icons.schedule,
                      size: 14,
                      color: colorScheme.tertiary,
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () =>
                      ref.read(syncRuleRepositoryProvider).deleteRule(rule.id),
                  tooltip: 'Delete rule',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _resolveName(
    AsyncValue<List<CalendarEntity>> calendarsAsync,
    String calendarId,
  ) {
    return calendarsAsync.whenOrNull(
          data: (cals) {
            try {
              return cals.firstWhere((c) => c.id == calendarId).name;
            } on StateError {
              return calendarId;
            }
          },
        ) ??
        calendarId;
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
}

class _CalendarBadge extends StatelessWidget {
  const _CalendarBadge({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 6, backgroundColor: color),
        const SizedBox(width: 6),
        Text(
          name,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Add Rule Dialog
// ---------------------------------------------------------------------------

class _AddRuleDialog extends ConsumerStatefulWidget {
  const _AddRuleDialog();

  @override
  ConsumerState<_AddRuleDialog> createState() => _AddRuleDialogState();
}

class _AddRuleDialogState extends ConsumerState<_AddRuleDialog> {
  String? _sourceId;
  String? _targetId;
  MirrorMode _mode = MirrorMode.busy;
  int? _windowStart;
  int? _windowEnd;

  @override
  Widget build(BuildContext context) {
    final calendarsAsync = ref.watch(calendarsStreamProvider);
    final calendars = calendarsAsync.valueOrNull ?? [];

    return AlertDialog(
      title: const Text('New Sync Rule'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _sourceId,
              decoration: const InputDecoration(labelText: 'From Calendar'),
              items: calendars
                  .map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _sourceId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _targetId,
              decoration: const InputDecoration(labelText: 'To Calendar'),
              items: calendars
                  .where((c) => c.id != _sourceId)
                  .map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _targetId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<MirrorMode>(
              value: _mode,
              decoration: const InputDecoration(labelText: 'Mirror Mode'),
              items: MirrorMode.values
                  .map(
                    (m) => DropdownMenuItem(value: m, child: Text(m.label)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _mode = v ?? MirrorMode.busy),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Start Hour (0–23)',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        setState(() => _windowStart = int.tryParse(v)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'End Hour (0–23)',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        setState(() => _windowEnd = int.tryParse(v)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: (_sourceId != null && _targetId != null)
              ? () => _save(context)
              : null,
          child: const Text('Add'),
        ),
      ],
    );
  }

  Future<void> _save(BuildContext context) async {
    final rule = SyncRuleEntity(
      id: 'rule-${DateTime.now().millisecondsSinceEpoch}',
      sourceCalendarId: _sourceId!,
      targetCalendarId: _targetId!,
      mode: _mode,
      timeWindowStart: _windowStart,
      timeWindowEnd: _windowEnd,
    );
    await ref.read(syncRuleRepositoryProvider).insertRule(rule);
    if (context.mounted) Navigator.pop(context);
  }
}
