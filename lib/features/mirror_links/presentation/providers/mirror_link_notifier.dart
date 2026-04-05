import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_provider.dart';
import '../../data/models/mirror_link_model.dart';
import '../../domain/repositories/mirror_link_repository.dart';

/// State notifier that manages mirror links.
class MirrorLinkNotifier extends AsyncNotifier<List<MirrorLinkModel>> {
  late MirrorLinkRepository _repository;

  @override
  Future<List<MirrorLinkModel>> build() async {
    _repository = await ref.watch(mirrorLinkRepositoryProvider.future);
    return _repository.getAll();
  }

  Future<void> addLink(MirrorLinkModel link) async {
    await _repository.insert(link);
    ref.invalidateSelf();
  }

  Future<void> addLinks(List<MirrorLinkModel> links) async {
    for (final link in links) {
      await _repository.insert(link);
    }
    ref.invalidateSelf();
  }

  Future<void> updateLink(MirrorLinkModel link) async {
    await _repository.update(link);
    ref.invalidateSelf();
  }

  Future<void> deleteLink(String id) async {
    await _repository.delete(id);
    ref.invalidateSelf();
  }

  /// Removes all mirror links for a given source event.
  Future<void> deleteLinksForEvent(String eventId) async {
    final links = await _repository.getBySourceEventId(eventId);
    for (final link in links) {
      await _repository.delete(link.id);
    }
    ref.invalidateSelf();
  }

  Future<List<MirrorLinkModel>> getLinksForEvent(String eventId) async {
    return _repository.getBySourceEventId(eventId);
  }
}

/// Provider for the mirror links list state.
final mirrorLinkNotifierProvider =
    AsyncNotifierProvider<MirrorLinkNotifier, List<MirrorLinkModel>>(
  MirrorLinkNotifier.new,
);
