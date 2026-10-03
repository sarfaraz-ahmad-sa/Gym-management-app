import 'dart:convert';
import 'package:file_selector/file_selector.dart';
import '../core/message_templates.dart';
import '../widgets/workspace_logo.dart';
import '../services/workspace_export.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/gym_store.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import '../services/export_service.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _gym = TextEditingController(), _country = TextEditingController();
  final _details = <String, TextEditingController>{
    for (final key in [
      'gym_address',
      'gym_phone',
      'gym_email',
      'gym_hours',
      'message_tagline',
      'message_payment',
      'message_welcome',
      'message_renewal',
    ])
      key: TextEditingController(),
  };
  String _currency = 'PKR';
  bool _initialized = false, _busy = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final store = context.read<GymStore>();
      _gym.text = store.gymName;
      _currency = store.currency;
      _country.text = '92';
      for (final entry in _details.entries) {
        final fallback = switch (entry.key) {
          'message_tagline' => defaultTagline,
          'message_payment' => defaultPaymentTemplate,
          'message_welcome' => defaultWelcomeTemplate,
          'message_renewal' => defaultRenewalTemplate,
          _ => '',
        };
        entry.value.text = store.setting(entry.key, fallback);
      }
      store.db.setting('country_code').then((v) {
        if (mounted && v != null) _country.text = v;
      });
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _gym.dispose();
    _country.dispose();
    for (final c in _details.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) toast(context, success);
    } catch (e) {
      if (mounted) toast(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore(GymStore store) async {
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(
          label: 'FitGuide backup',
          extensions: ['json'],
          mimeTypes: ['application/json'],
        ),
      ],
    );
    if (file == null || !mounted) return;
    if (!await confirm(
      context,
      'Replace workspace records?',
      'Restore ${file.name}? This replaces all gym records and settings. Your owner account stays the same. Export a backup first.',
      label: 'Restore backup',
    )) {
      return;
    }
    await _run(() async {
      await store.db.importData(await file.readAsString());
      await store.load();
      _gym.text = store.gymName;
      _currency = store.currency;
      _country.text = await store.db.setting('country_code') ?? '92';
      for (final entry in _details.entries) {
        entry.value.text = store.setting(entry.key, entry.value.text);
      }
    }, 'Backup restored');
  }

  Future<void> _pickLogo(GymStore store) async {
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(
          label: 'Workspace logo',
          extensions: ['png', 'jpg', 'jpeg', 'webp'],
          mimeTypes: ['image/png', 'image/jpeg', 'image/webp'],
        ),
      ],
    );
    if (file == null) return;
    await _run(() async {
      final bytes = await file.readAsBytes();
      if (bytes.length > 190 * 1024) {
        throw StateError('Choose a logo under 190 KB.');
      }
      final extension = file.name.split('.').last.toLowerCase();
      final mime = extension == 'png'
          ? 'png'
          : extension == 'webp'
          ? 'webp'
          : 'jpeg';
      await store.db.setSetting(
        'gym_logo',
        'data:image/$mime;base64,${base64Encode(bytes)}',
      );
      await store.load();
    }, 'Workspace logo updated');
  }

  Future<void> _newWorkspace(AuthService auth) async {
    final name = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create another workspace'),
        content: TextField(
          controller: name,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Workspace / gym name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isNotEmpty) {
                Navigator.pop(ctx, name.text.trim());
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
    name.dispose();
    if (result != null && mounted) {
      await _run(() => auth.createWorkspace(result), 'Workspace created');
    }
  }

  Future<void> _changePassword(AuthService auth) async {
    final current = TextEditingController(), next = TextEditingController();
    final form = GlobalKey<FormState>();
    var busy = false;
    String? error;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => PopScope(
          canPop: !busy,
          child: AlertDialog(
            title: const Text('Change password'),
            content: SizedBox(
              width: 380,
              child: Form(
                key: form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: current,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Current password',
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Enter current password'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: next,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New password',
                      ),
                      validator: (v) => v == null || v.length < 8
                          ? 'Use at least 8 characters'
                          : null,
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(ctx).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: busy ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: busy
                    ? null
                    : () async {
                        if (!form.currentState!.validate()) return;
                        update(() => busy = true);
                        try {
                          await auth.changePassword(current.text, next.text);
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          if (ctx.mounted) {
                            update(() {
                              busy = false;
                              error = friendlyError(e);
                            });
                          }
                        }
                      },
                child: Text(busy ? 'Saving…' : 'Update password'),
              ),
            ],
          ),
        ),
      ),
    );
    current.dispose();
    next.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GymStore>();
    final auth = context.watch<AuthService>();
    final theme = context.watch<ThemeController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeading(
          title: 'Workspace settings',
          subtitle: 'Make FitGuide feel like your club.',
        ),
        const SizedBox(height: 26),
        if (auth.cloudMode && !auth.demo) ...[
          SectionCard(
            title: 'Your workspaces',
            subtitle: 'Each gym has its own members, branding and records.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: auth.workspaceId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Active workspace',
                  ),
                  items: auth.workspaces
                      .map(
                        (w) => DropdownMenuItem(
                          value: w['id'] as String,
                          child: Text(
                            w['id'] == auth.workspaceId
                                ? store.gymName
                                : w['name'] as String,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _busy
                      ? null
                      : (id) {
                          if (id != null) auth.selectWorkspace(id);
                        },
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _newWorkspace(auth),
                  icon: const Icon(Icons.add_business_outlined),
                  label: const Text('Create workspace'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
        ],
        SectionCard(
          title: 'Club details',
          subtitle: 'Used on receipts and member messages.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  WorkspaceLogo(data: store.setting('gym_logo'), size: 72),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _pickLogo(store),
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Upload logo'),
                  ),
                  if (store.setting('gym_logo').isNotEmpty)
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                              await store.db.setSetting('gym_logo', '');
                              await store.load();
                            }, 'Logo removed'),
                      child: const Text('Remove logo'),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _gym,
                decoration: const InputDecoration(
                  labelText: 'Workspace / gym name',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
              ),
              const SizedBox(height: 18),
              for (final key in [
                'gym_address',
                'gym_phone',
                'gym_email',
                'gym_hours',
              ]) ...[
                TextField(
                  controller: _details[key],
                  decoration: InputDecoration(
                    labelText: switch (key) {
                      'gym_address' => 'Gym address',
                      'gym_phone' => 'Reception phone',
                      'gym_email' => 'Contact email',
                      _ => 'Opening hours',
                    },
                  ),
                ),
                const SizedBox(height: 18),
              ],
              DropdownButtonFormField<String>(
                initialValue: _currency,
                decoration: const InputDecoration(labelText: 'Currency'),
                items: ['PKR', 'USD', 'AED', 'GBP', 'EUR', 'INR', 'SAR']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => _currency = v!,
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _country,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Phone country code',
                  helperText:
                      'Used for WhatsApp numbers starting with 0. Example: 92 for Pakistan.',
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Changing currency updates labels only; amounts are not converted.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                        if (_gym.text.trim().isEmpty) {
                          throw StateError('Enter your club name.');
                        }
                        if (!RegExp(
                          r'^[1-9]\d{0,3}$',
                        ).hasMatch(_country.text)) {
                          throw StateError('Enter a valid country code.');
                        }
                        await store.db.setSettings({
                          'gym_name': _gym.text.trim(),
                          'currency': _currency,
                          'country_code': _country.text,
                          ..._details.map(
                            (key, c) => MapEntry(key, c.text.trim()),
                          ),
                        });
                        await store.load();
                      }, 'Workspace settings saved'),
                child: Text(_busy ? 'Saving…' : 'Save changes'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SectionCard(
          title: 'Workspace message templates',
          subtitle: 'Personalize fee reminders, welcomes and renewals.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Available fields: {member}, {workspace}, {pending_amount}, {due_date}, {due_month}, {last_payment_line}, {last_payment_amount}, {last_payment_date}, {plan}, {expiry_date}, {tagline}',
              ),
              const SizedBox(height: 18),
              for (final key in [
                'message_tagline',
                'message_payment',
                'message_welcome',
                'message_renewal',
              ]) ...[
                TextField(
                  controller: _details[key],
                  minLines: key == 'message_tagline' ? 1 : 4,
                  maxLines: 10,
                  decoration: InputDecoration(
                    labelText: switch (key) {
                      'message_tagline' => 'Fitness line',
                      'message_payment' => 'Fee reminder',
                      'message_welcome' => 'Welcome message',
                      _ => 'Renewal message',
                    },
                  ),
                ),
                const SizedBox(height: 18),
              ],
              FilledButton(
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                        await store.db.setSettings({
                          for (final e in _details.entries.where(
                            (e) => e.key.startsWith('message_'),
                          ))
                            e.key: e.value.text,
                        });
                        await store.load();
                      }, 'Message templates saved'),
                child: const Text('Save templates'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SectionCard(
          title: 'Appearance & account',
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: theme.dark,
                onChanged: (_) => theme.toggle(),
                title: const Text('Dark appearance'),
                subtitle: const Text('A softer view for the late shift.'),
                secondary: const Icon(Icons.dark_mode_outlined),
              ),
              if (!auth.demo)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Owner password'),
                  subtitle: Text(
                    store.isCloud
                        ? 'Update your owner password across mobile and web.'
                        : 'Update the password for this local workspace.',
                  ),
                  trailing: TextButton(
                    onPressed: () => _changePassword(auth),
                    child: const Text('Change'),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SectionCard(
          title: 'Backups & portability',
          subtitle: 'Keep a copy of the records that matter.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                store.isCloud
                    ? 'Records are saved in your shared cloud workspace. Sign in on mobile and web to access the same data. Refresh to see changes from other devices.'
                    : 'Demo records are stored locally on this device/browser.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _run(
                            () async => downloadText(
                              'fitguide-backup.json',
                              await store.db.exportData(),
                              'application/json',
                            ),
                            'Backup ready',
                          ),
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Export backup'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _run(
                            () => exportWorkspace(store),
                            'All workspace data downloaded',
                          ),
                    icon: const Icon(Icons.folder_zip_outlined),
                    label: const Text('Download all data (ZIP + CSV'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _restore(store),
                    icon: const Icon(Icons.upload_file_outlined),
                    label: const Text('Restore backup'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Backups include gym records and settings. Passwords and sessions are excluded.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SectionCard(
          child: Row(
            children: [
              const Brand(compact: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FitGuide Pro 3.0',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    const Text('Your club. Your community. Your workspace.'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
