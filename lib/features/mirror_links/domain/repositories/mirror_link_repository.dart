import '../../data/models/mirror_link_model.dart';

/// Abstract interface for mirror link CRUD operations.
abstract class MirrorLinkRepository {
  Future<List<MirrorLinkModel>> getAll();
  Future<MirrorLinkModel?> getById(String id);
  Future<List<MirrorLinkModel>> getBySourceEventId(String eventId);
  Future<void> insert(MirrorLinkModel mirrorLink);
  Future<void> update(MirrorLinkModel mirrorLink);
  Future<void> delete(String id);
}
