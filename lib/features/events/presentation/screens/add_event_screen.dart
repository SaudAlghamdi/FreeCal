import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freecal/features/calendar/domain/entities/calendar_entity.dart';
import 'package:freecal/features/calendar/presentation/providers/calendar_provider.dart';
import 'package:freecal/features/events/domain/entities/event_entity.dart';
import 'package:freecal/features/events/domain/entities/event_target_settings_entity.dart';
import 'package:freecal/features/events/presentation/providers/event_provider.dart';
import 'package:freecal/features/events/presentation/widgets/mirror_control_section.dart';
import 'package:freecal/features/conflicts/presentation/providers/conflict_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

/// Screen for creating a new calendar event with mirror settings.
class AddEventScreen extends ConsumerStatefulWidget {
  const AddEventScreen({super.key});

  @override
  ConsumerState<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends ConsumerState<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime _startTime = _defaultStart();
  DateTime _endTime = _defaultEnd();
  String? _selectedCalendarId;
  bool _isSaving = false;

  static DateTime _defaultStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour + 1);
  }

  static DateTime _defaultEnd() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour + 2);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calendarsAsync = ref.watch(calendarsStreamProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Event'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          FilledButton(
            onPressed: _isSaving ? null : _saveEvent,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- Title ---
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                prefixIcon: Icon(Icons.title),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // --- Source Calendar ---
            calendarsAsync.when(
              data: (calendars) => _buildCalendarDropdown(
                context,
                calendars,
                colorScheme,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error loading calendars: $e'),
            ),
            const SizedBox(height: 16),

            // --- Date & Time ---
            _SectionHeader(
              icon: Icons.access_time,
              label: 'Date & Time',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DateTimeButton(
                    label: 'Starts',
                    dateTime: _startTime,
                    onTap: () => _pickDateTime(isStart: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateTimeButton(
                    label: 'Ends',
                    dateTime: _endTime,
                    onTap: () => _pickDateTime(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- Location ---
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // --- Notes ---
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            // --- Mirror Control Section ---
            if (_selectedCalendarId != null)
              calendarsAsync.when(
                data: (calendars) {
                  final targets = calendars
                      .where((c) => c.id != _selectedCalendarId)
                      .toList();
                  return MirrorControlSection(
                    targetCalendars: targets,
                    sourceCalendarId: _selectedCalendarId!,
                    startTime: _startTime,
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarDropdown(
    BuildContext context,
    List<CalendarEntity> calendars,
    ColorScheme colorScheme,
  ) {
    if (_selectedCalendarId == null && calendars.isNotEmpty) {
      // Default to first calendar
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _selectedCalendarId = calendars.first.id);
      });
    }

    return DropdownButtonFormField<String>(
      value: _selectedCalendarId,
      decoration: const InputDecoration(
        labelText: 'Calendar *',
        prefixIcon: Icon(Icons.calendar_today),
      ),
      items: calendars
          .map(
            (cal) => DropdownMenuItem(
              value: cal.id,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 8,
                    backgroundColor: cal.color,
                  ),
                  const SizedBox(width: 8),
                  Text(cal.name),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: (value) => setState(() => _selectedCalendarId = value),
      validator: (value) =>
          value == null ? 'Please select a calendar' : null,
    );
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    final newDt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (isStart) {
        _startTime = newDt;
        if (_endTime.isBefore(_startTime)) {
          _endTime = _startTime.add(const Duration(hours: 1));
        }
      } else {
        _endTime = newDt;
      }
    });
  }

  Future<void> _saveEvent() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCalendarId == null) return;

    setState(() => _isSaving = true);

    try {
      const uuid = Uuid();
      final eventId = uuid.v4();

      final event = EventEntity(
        id: eventId,
        title: _titleController.text.trim(),
        startTime: _startTime,
        endTime: _endTime,
        sourceCalendarId: _selectedCalendarId!,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
      );

      final eventRepo = ref.read(eventRepositoryProvider);
      await eventRepo.insertEvent(event);

      // Save per-event target settings and collect saved entities
      final formState = ref.read(eventFormProvider);
      final savedSettings = <EventTargetSettingsEntity>[];
      for (final settings in formState.targetSettings) {
        final s = EventTargetSettingsEntity(
          id: uuid.v4(),
          eventId: eventId,
          targetCalendarId: settings.targetCalendarId,
          mode: settings.mode,
          overrideRule: settings.overrideRule,
          hideDetails: settings.hideDetails,
          applyWorkHoursRule: settings.applyWorkHoursRule,
        );
        await eventRepo.insertTargetSettings(s);
        savedSettings.add(s);
      }

      // Run sync engine using the already-saved settings
      final syncEngine = ref.read(syncEngineProvider);
      await syncEngine.processEvent(event, targetSettings: savedSettings);

      // Reset form
      ref.read(eventFormProvider.notifier).reset();

      if (mounted) context.pop();
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving event: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

// ---------------------------------------------------------------------------
// Helper Widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }
}

class _DateTimeButton extends StatelessWidget {
  const _DateTimeButton({
    required this.label,
    required this.dateTime,
    required this.onTap,
  });

  final String label;
  final DateTime dateTime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMM d');
    final timeFormat = DateFormat.jm();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              dateFormat.format(dateTime),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              timeFormat.format(dateTime),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// syncEngineProvider is imported from conflict_provider.dart
