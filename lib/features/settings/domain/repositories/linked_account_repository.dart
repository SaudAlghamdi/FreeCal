import 'package:freecal/features/settings/domain/entities/linked_account_entity.dart';

abstract class LinkedAccountRepository {
  Future<List<LinkedAccountEntity>> getAll();
  Future<LinkedAccountEntity?> getByProvider(AccountProvider provider);
  Future<void> upsert(LinkedAccountEntity account);
  Future<void> delete(String id);
  Stream<List<LinkedAccountEntity>> watchAll();
  Future<void> dispose();
}
