import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freecal/core/services/sync_scheduler.dart';
import 'package:freecal/features/settings/domain/entities/linked_account_entity.dart';
import 'package:freecal/features/settings/presentation/providers/linked_account_provider.dart';
import 'package:intl/intl.dart';

/// Main settings screen.  Lets the user link / unlink external mail accounts
/// and shows the current sync status.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(linkedAccountsStreamProvider);
    final syncStatusAsync = ref.watch(syncStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── Account Linking ──────────────────────────────────────────────
          _SectionHeader(title: 'Linked Mail Accounts'),
          accountsAsync.when(
            data: (accounts) => Column(
              children: AccountProvider.values.map((provider) {
                final linked = accounts.firstWhere(
                  (a) => a.provider == provider && a.isConnected,
                  orElse: () => LinkedAccountEntity(
                    id: '',
                    provider: provider,
                    email: '',
                    isConnected: false,
                  ),
                );
                return _AccountTile(
                  provider: provider,
                  linkedAccount: linked.isConnected ? linked : null,
                );
              }).toList(),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error loading accounts: $e'),
            ),
          ),

          const Divider(height: 32),

          // ── Sync Status ──────────────────────────────────────────────────
          _SectionHeader(title: 'Sync'),
          syncStatusAsync.when(
            data: (status) => _SyncStatusTile(status: status),
            loading: () => ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Sync'),
              subtitle: const Text('Waiting for first sync…'),
            ),
            error: (e, _) => ListTile(
              leading: const Icon(Icons.sync_problem, color: Colors.red),
              title: const Text('Sync error'),
              subtitle: Text(e.toString()),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Account tile
// ---------------------------------------------------------------------------

class _AccountTile extends ConsumerWidget {
  const _AccountTile({
    required this.provider,
    required this.linkedAccount,
  });

  final AccountProvider provider;
  final LinkedAccountEntity? linkedAccount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLinked = linkedAccount != null;

    return ListTile(
      leading: _ProviderIcon(provider: provider),
      title: Text(provider.displayName),
      subtitle: isLinked
          ? Text(
              linkedAccount!.email,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : const Text('Not connected'),
      trailing: isLinked
          ? TextButton(
              onPressed: () => _confirmUnlink(context, ref),
              child: const Text('Disconnect'),
            )
          : FilledButton.tonal(
              onPressed: () => _showLinkDialog(context, ref),
              child: const Text('Connect'),
            ),
    );
  }

  Future<void> _showLinkDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Connect ${provider.displayName}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Email address',
              hintText: 'you@example.com',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter an email address';
              }
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref
          .read(linkedAccountNotifierProvider.notifier)
          .linkAccount(provider, controller.text.trim());
    }
  }

  Future<void> _confirmUnlink(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Disconnect ${provider.displayName}'),
        content: Text(
          'Are you sure you want to disconnect ${linkedAccount!.email}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref
          .read(linkedAccountNotifierProvider.notifier)
          .unlinkAccount(provider);
    }
  }
}

// ---------------------------------------------------------------------------
// Provider icon
// ---------------------------------------------------------------------------

class _ProviderIcon extends StatelessWidget {
  const _ProviderIcon({required this.provider});
  final AccountProvider provider;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = switch (provider) {
      AccountProvider.google => (Icons.mail_outline, const Color(0xFFEA4335)),
      AccountProvider.outlook =>
        (Icons.mark_email_unread_outlined, const Color(0xFF0078D4)),
      AccountProvider.icloud =>
        (Icons.cloud_outlined, const Color(0xFF3478F6)),
    };

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.12),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

// ---------------------------------------------------------------------------
// Sync status tile
// ---------------------------------------------------------------------------

class _SyncStatusTile extends StatelessWidget {
  const _SyncStatusTile({required this.status});
  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('HH:mm:ss');
    final timeStr = formatter.format(status.lastSyncAt);

    if (status.hasError) {
      return ListTile(
        leading: const Icon(Icons.sync_problem, color: Colors.red),
        title: const Text('Sync failed'),
        subtitle: Text(status.error!),
      );
    }

    final label = status.syncedProviders.isEmpty
        ? 'No accounts connected'
        : status.syncedProviders.map((p) => p.displayName).join(', ');

    return ListTile(
      leading: const Icon(Icons.sync),
      title: const Text('Auto-sync every 30 s'),
      subtitle: Text('Last sync: $timeStr — $label'),
    );
  }
}
