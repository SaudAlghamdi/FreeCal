/// The mail provider type for a linked account.
enum AccountProvider { google, outlook, icloud }

extension AccountProviderX on AccountProvider {
  String get displayName {
    switch (this) {
      case AccountProvider.google:
        return 'Google Mail';
      case AccountProvider.outlook:
        return 'Outlook Mail';
      case AccountProvider.icloud:
        return 'iCloud Mail';
    }
  }

  String get key {
    switch (this) {
      case AccountProvider.google:
        return 'google';
      case AccountProvider.outlook:
        return 'outlook';
      case AccountProvider.icloud:
        return 'icloud';
    }
  }

  static AccountProvider fromKey(String key) {
    switch (key) {
      case 'google':
        return AccountProvider.google;
      case 'outlook':
        return AccountProvider.outlook;
      case 'icloud':
        return AccountProvider.icloud;
      default:
        throw ArgumentError('Unknown AccountProvider key: $key');
    }
  }
}

/// Represents a linked external mail / calendar account.
class LinkedAccountEntity {
  const LinkedAccountEntity({
    required this.id,
    required this.provider,
    required this.email,
    required this.isConnected,
    this.lastSyncAt,
  });

  final String id;
  final AccountProvider provider;
  final String email;
  final bool isConnected;
  final DateTime? lastSyncAt;

  LinkedAccountEntity copyWith({
    String? id,
    AccountProvider? provider,
    String? email,
    bool? isConnected,
    DateTime? lastSyncAt,
  }) {
    return LinkedAccountEntity(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      email: email ?? this.email,
      isConnected: isConnected ?? this.isConnected,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkedAccountEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
