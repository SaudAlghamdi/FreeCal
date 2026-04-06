import 'package:freecal/features/settings/domain/entities/linked_account_entity.dart';

/// SQLite data model for [LinkedAccountEntity].
class LinkedAccountModel {
  const LinkedAccountModel({
    required this.id,
    required this.providerKey,
    required this.email,
    required this.isConnected,
    this.lastSyncAt,
  });

  final String id;
  final String providerKey;
  final String email;
  final int isConnected;
  final int? lastSyncAt;

  factory LinkedAccountModel.fromMap(Map<String, Object?> map) {
    return LinkedAccountModel(
      id: map['id'] as String,
      providerKey: map['providerKey'] as String,
      email: map['email'] as String,
      isConnected: map['isConnected'] as int,
      lastSyncAt: map['lastSyncAt'] as int?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'providerKey': providerKey,
      'email': email,
      'isConnected': isConnected,
      'lastSyncAt': lastSyncAt,
    };
  }

  factory LinkedAccountModel.fromEntity(LinkedAccountEntity entity) {
    return LinkedAccountModel(
      id: entity.id,
      providerKey: entity.provider.key,
      email: entity.email,
      isConnected: entity.isConnected ? 1 : 0,
      lastSyncAt: entity.lastSyncAt?.millisecondsSinceEpoch,
    );
  }

  LinkedAccountEntity toEntity() {
    return LinkedAccountEntity(
      id: id,
      provider: AccountProviderX.fromKey(providerKey),
      email: email,
      isConnected: isConnected == 1,
      lastSyncAt: lastSyncAt != null
          ? DateTime.fromMillisecondsSinceEpoch(lastSyncAt!)
          : null,
    );
  }
}
