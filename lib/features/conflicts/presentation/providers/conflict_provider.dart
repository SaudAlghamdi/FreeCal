import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../events/presentation/providers/event_notifier.dart';
import '../../../mirror_links/presentation/providers/mirror_link_notifier.dart';
import '../../domain/conflict_detector.dart';
import '../../domain/conflict_model.dart';

/// Provides the [ConflictDetector] instance.
final conflictDetectorProvider = Provider<ConflictDetector>((ref) {
  return const ConflictDetector();
});

/// Provides the current list of detected conflicts, recomputed whenever
/// events or mirror links change.
final conflictsProvider = FutureProvider<List<ConflictModel>>((ref) async {
  final events = await ref.watch(eventNotifierProvider.future);
  final mirrorLinks = await ref.watch(mirrorLinkNotifierProvider.future);
  final detector = ref.watch(conflictDetectorProvider);

  return detector.detectAll(events: events, mirrorLinks: mirrorLinks);
});
