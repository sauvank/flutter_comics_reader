import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../utils/desktop_layout.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../../providers/library_provider.dart';
import '../../providers/server_provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/sync/sync_service.dart';
import '../../services/sync/desktop_google_sign_in.dart';
import '../../services/sync/firebase_bootstrap.dart';
import '../../services/sync/sync_models.dart';
import '../../services/android_signing_certificate_service.dart';
import '../../l10n/l10n.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _sync = SyncService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _recovery = TextEditingController();
  final _confirmRecovery = TextEditingController();
  final _phrase = TextEditingController();
  final _confirmPhrase = TextEditingController();
  bool _createMode = false;
  bool _busy = false;
  bool _syncing = false;
  bool? _hasLocalVault;
  bool? _hasRemoteVault;
  bool _loadingVault = false;

  bool _obscurePassword = true;
  bool _obscureRecovery = true;
  bool _obscureConfirmRecovery = true;
  bool _obscurePhrase = true;
  bool _obscureConfirmPhrase = true;

  @override
  void initState() {
    super.initState();
    // The local-only fallback must be able to render before FirebaseAuth is
    // resolved: FirebaseAuth.instance throws without a default Firebase app.
    if (FirebaseBootstrap.isAvailable && _sync.user != null) {
      _checkVault();
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _recovery.dispose();
    _confirmRecovery.dispose();
    _phrase.dispose();
    _confirmPhrase.dispose();
    super.dispose();
  }

  Future<void> _checkVault() async {
    if (_sync.user == null) return;
    setState(() => _loadingVault = true);
    try {
      final local = await _sync.hasLocalKey();
      final remote = local ? true : await _sync.hasRemoteVault();
      if (mounted) {
        setState(() {
          _hasLocalVault = local;
          _hasRemoteVault = remote;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasLocalVault = false;
          _hasRemoteVault = false;
        });
      }
    } finally {
      if (mounted) setState(() => _loadingVault = false);
    }
  }

  Future<void> _showResetVaultDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.resetVaultTitle),
        content: Text(
          l10n.resetVaultBody,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.reset)),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _hasRemoteVault = false);
    }
  }

  Future<bool> _showConfirmCreationDialog(String phrase) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber),
                SizedBox(width: 8),
                Expanded(child: Text(l10n.confirmSecretPhrase)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.secretPhraseWrittenDownBody,
                ),
                const SizedBox(height: 12),
                Text(l10n.yourSecretPhrase,
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Theme.of(ctx).colorScheme.outlineVariant),
                  ),
                  child: SelectableText(
                    phrase,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.edit),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.phraseNotedContinue),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _showEditRecoveryPhraseDialog() async {
    final newPhraseController = TextEditingController();
    final confirmPhraseController = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;
    String? errorText;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.changeSecretPhrase),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.changeSecretPhraseBody,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPhraseController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: l10n.newSecretPhrase,
                    helperText: l10n.min16Characters,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                          obscureNew ? Icons.visibility : Icons.visibility_off),
                      onPressed: () =>
                          setDialogState(() => obscureNew = !obscureNew),
                      tooltip: obscureNew ? l10n.showPhrase : l10n.hidePhrase,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPhraseController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: l10n.confirmNewPhrase,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () => setDialogState(
                          () => obscureConfirm = !obscureConfirm),
                      tooltip:
                          obscureConfirm ? l10n.showPhrase : l10n.hidePhrase,
                    ),
                  ),
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorText!,
                    style: TextStyle(
                        color: Theme.of(ctx).colorScheme.error, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                final phrase = newPhraseController.text.trim();
                final confirm = confirmPhraseController.text.trim();
                if (phrase.length < 16) {
                  setDialogState(() => errorText = l10n.phraseTooShort);
                  return;
                }
                if (phrase != confirm) {
                  setDialogState(() => errorText = l10n.phrasesDoNotMatch);
                  return;
                }
                Navigator.of(ctx).pop(phrase);
              },
              child: Text(l10n.continueLabel),
            ),
          ],
        ),
      ),
    );

    newPhraseController.dispose();
    confirmPhraseController.dispose();

    if (result != null && mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.confirmChangeTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.confirmChangeBody,
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Theme.of(ctx).colorScheme.outlineVariant),
                ),
                child: SelectableText(
                  result,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.edit),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.confirmAndSave),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        await _run(() async {
          await _sync.updateRecoveryPhrase(result);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.secretPhraseUpdated)),
            );
          }
        });
      }
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.operationDone)));
      }
    } catch (error) {
      if (error is GoogleSignInException &&
          error.code == GoogleSignInExceptionCode.canceled) {
        return;
      }
      if (error is FirebaseAuthException &&
          error.code == 'web-context-canceled') {
        return;
      }
      if (error is DesktopGoogleSignInCanceled) return;
      var message = l10n.cannotContinue(error);
      if (error.toString().contains('invalid-cert-hash')) {
        final hashes = await AndroidSigningCertificateService.currentSha1();
        if (hashes.isNotEmpty) {
          message = l10n.androidCertNotAllowed(hashes.join(', '));
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _formatConflictDate(DateTime value) {
    final local = value.toLocal();
    final date = MaterialLocalizations.of(context).formatMediumDate(local);
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(local));
    return l10n.dateAtTime(date, time);
  }

  Future<bool> _resolveConflicts(List<SyncConflict> conflicts) async {
    for (final conflict in conflicts) {
      if (!mounted) return false;
      final choice = await showDialog<SyncConflictResolution>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.syncConflict),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.syncConflictBody(conflict.label)),
              const SizedBox(height: 12),
              Text(l10n.thisDeviceValue(
                  _formatConflictDate(conflict.localUpdatedAt))),
              const SizedBox(height: 4),
              Text(l10n.syncServerValue(
                  _formatConflictDate(conflict.remoteUpdatedAt))),
              const SizedBox(height: 12),
              Text(l10n.thisDeviceSummary(conflict.localSummary)),
              const SizedBox(height: 4),
              Text(l10n.serverSummary(conflict.remoteSummary)),
              const SizedBox(height: 12),
              Text(
                l10n.chooseReferenceVersion,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.of(ctx).pop(SyncConflictResolution.keepRemote),
                  icon: const Icon(Icons.arrow_downward_rounded),
                  label: Text(l10n.fetchFromServer),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () =>
                      Navigator.of(ctx).pop(SyncConflictResolution.keepLocal),
                  icon: const Icon(Icons.arrow_upward_rounded),
                  label: Text(l10n.sendToServer),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.later),
            ),
          ],
        ),
      );
      if (choice == null) return false;
      await _sync.resolveConflict(conflict, choice);
    }
    return true;
  }

  Future<void> _resolveAutomaticConflicts(SyncProvider syncProvider) async {
    final serverProvider = context.read<ServerProvider>();
    final libraryProvider = context.read<LibraryProvider>();
    setState(() => _syncing = true);
    try {
      final resolved = await _resolveConflicts(syncProvider.conflicts);
      if (!resolved || !mounted) return;
      await syncProvider.syncNow();
      if (!mounted) return;
      await serverProvider.loadServers();
      await libraryProvider.loadLibrary();
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _showDeviceNameDialog() async {
    final controller =
        TextEditingController(text: await _sync.currentDeviceName());
    if (!mounted) {
      controller.dispose();
      return;
    }
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.thisDeviceName),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: l10n.deviceNameHint,
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null) return;
    await _run(() async {
      final result = await _sync.renameCurrentDevice(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result == DeviceRenameResult.synced
                ? l10n.deviceNameSavedOnServer
                : l10n.deviceNameSavedLocally),
          ),
        );
      }
    });
  }

  Future<void> _startManualSync() async {
    final automaticSyncProvider = context.read<SyncProvider>();
    final serverProvider = context.read<ServerProvider>();
    final libraryProvider = context.read<LibraryProvider>();
    List<SyncDeviceBackup> backups;
    try {
      backups = await _sync.listDeviceBackups();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.cannotPrepareSync(error))),
        );
      }
      return;
    }
    if (!mounted) return;
    final choice = await showAdaptiveSheet<SyncDeviceBackup>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l10n.whichBackupToUse),
                subtitle: Text(
                  l10n.whichBackupBody,
                ),
              ),
              for (final backup in backups)
                ListTile(
                  leading: Icon(backup.isCurrentDevice
                      ? Icons.phone_android
                      : Icons.devices_other),
                  title: Text(backup.label),
                  subtitle: Text(backup.updatedAt == null
                      ? l10n.notBackedUpYet
                      : l10n
                          .backedUpAt(_formatConflictDate(backup.updatedAt!))),
                  trailing: backup.isCurrentDevice
                      ? Text(l10n.currentUpper)
                      : const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(sheetContext).pop(backup),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (choice == null || !mounted) return;
    setState(() => _syncing = true);
    var completed = true;
    try {
      await _run(() async {
        if (choice.isCurrentDevice) {
          final conflicts = await _sync.syncNow();
          if (conflicts.isNotEmpty) {
            completed = await _resolveConflicts(conflicts);
          }
        } else {
          await _sync.restoreDeviceBackup(choice.id);
        }
        if (!completed) return;
        automaticSyncProvider.clearResolvedConflicts();
        if (!mounted) return;
        await serverProvider.loadServers();
        await libraryProvider.loadLibrary();
      });
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!FirebaseBootstrap.isAvailable) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.accountAndSync)),
        body: DesktopContent(
          maxWidth: 720,
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(l10n.syncUnavailableNoFirebase),
          ),
        ),
      );
    }
    return StreamBuilder(
      stream: _sync.authChanges,
      builder: (context, _) {
        final automaticSync = context.watch<SyncProvider>();
        final user = _sync.user;
        if (user != null && _hasLocalVault == null && !_loadingVault) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _checkVault());
        }
        return Scaffold(
          appBar: AppBar(title: Text(l10n.accountAndSync)),
          // Readable column on PC instead of stretching to the window.
          body: DesktopContent(
              maxWidth: 720,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (user != null) ...[
                    ListTile(
                      leading: Icon(
                        _hasLocalVault == true
                            ? Icons.verified_user_outlined
                            : Icons.lock_outline,
                        color: _hasLocalVault == true
                            ? Colors.green
                            : Colors.amber,
                      ),
                      title: Text(user.email ?? l10n.accountConnected),
                      subtitle: Text(
                        _hasLocalVault == true
                            ? l10n.vaultUnlockedE2e
                            : l10n.vaultLockedOrNew,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_loadingVault) ...[
                      const Center(
                          child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator())),
                    ] else if (_hasLocalVault == false) ...[
                      Card(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withAlpha(120),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _hasRemoteVault == true
                                        ? Icons.lock_reset
                                        : Icons.shield_outlined,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _hasRemoteVault == true
                                          ? l10n.unlockVault
                                          : l10n.initEncryptedVault,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _hasRemoteVault == true
                                    ? l10n.unlockVaultBody
                                    : l10n.initVaultBody,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _phrase,
                                obscureText: _obscurePhrase,
                                decoration: InputDecoration(
                                  labelText: _hasRemoteVault == true
                                      ? l10n.recoveryPhrase
                                      : l10n.secretPhraseMin16,
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePhrase
                                        ? Icons.visibility
                                        : Icons.visibility_off),
                                    onPressed: () => setState(
                                        () => _obscurePhrase = !_obscurePhrase),
                                    tooltip: _obscurePhrase
                                        ? l10n.showPhrase
                                        : l10n.hidePhrase,
                                  ),
                                ),
                              ),
                              if (_hasRemoteVault != true) ...[
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _confirmPhrase,
                                  obscureText: _obscureConfirmPhrase,
                                  decoration: InputDecoration(
                                    labelText: l10n.confirmSecretPhrase,
                                    border: const OutlineInputBorder(),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscureConfirmPhrase
                                          ? Icons.visibility
                                          : Icons.visibility_off),
                                      onPressed: () => setState(() =>
                                          _obscureConfirmPhrase =
                                              !_obscureConfirmPhrase),
                                      tooltip: _obscureConfirmPhrase
                                          ? l10n.showPhrase
                                          : l10n.hidePhrase,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: _busy
                                      ? null
                                      : () => _run(() async {
                                            final phrase = _phrase.text.trim();
                                            if (_hasRemoteVault == true) {
                                              if (phrase.isEmpty) {
                                                throw ArgumentError(
                                                    l10n.enterRecoveryPhrase);
                                              }
                                              await _sync.restoreVault(phrase);
                                            } else {
                                              final confirm =
                                                  _confirmPhrase.text.trim();
                                              if (phrase.length < 16) {
                                                throw ArgumentError(
                                                    l10n.secretPhraseTooShort);
                                              }
                                              if (phrase != confirm) {
                                                throw ArgumentError(l10n
                                                    .secretPhrasesDoNotMatch);
                                              }
                                              final confirmed =
                                                  await _showConfirmCreationDialog(
                                                      phrase);
                                              if (!confirmed) return;
                                              await _sync.createVault(phrase);
                                            }
                                            _phrase.clear();
                                            _confirmPhrase.clear();
                                            await _checkVault();
                                          }),
                                  icon: Icon(_hasRemoteVault == true
                                      ? Icons.lock_open
                                      : Icons.vpn_key),
                                  label: Text(
                                    _hasRemoteVault == true
                                        ? l10n.unlockSync
                                        : l10n.createAndEnableVault,
                                  ),
                                ),
                              ),
                              if (_hasRemoteVault == true) ...[
                                const SizedBox(height: 8),
                                Center(
                                  child: TextButton(
                                    onPressed:
                                        _busy ? null : _showResetVaultDialog,
                                    child: Text(l10n.forgotPhraseReset),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      if (automaticSync.status == SyncStatus.conflict) ...[
                        Card(
                          color: Theme.of(context).colorScheme.errorContainer,
                          child: ListTile(
                            leading: Icon(Icons.warning_amber_rounded,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer),
                            title: Text(l10n.syncConflict),
                            subtitle: Text(
                              l10n.pendingConflicts(
                                  automaticSync.conflicts.length),
                            ),
                            trailing: FilledButton(
                              onPressed: _syncing
                                  ? null
                                  : () =>
                                      _resolveAutomaticConflicts(automaticSync),
                              child: Text(l10n.view),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.verified_user,
                                      color: Colors.green),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.vaultUnlocked,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.syncActiveE2e,
                              ),
                              const SizedBox(height: 16),
                              if (_syncing) ...[
                                const LinearProgressIndicator(),
                                const SizedBox(height: 12),
                              ],
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final syncButton = FilledButton.icon(
                                    onPressed: _busy ? null : _startManualSync,
                                    icon: _syncing
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.sync),
                                    label: Text(_syncing
                                        ? l10n.syncing
                                        : l10n.synchronize),
                                  );
                                  final recoveryButton = OutlinedButton.icon(
                                    onPressed: _busy
                                        ? null
                                        : _showEditRecoveryPhraseDialog,
                                    icon: const Icon(Icons.key),
                                    label: Text(l10n.changePhrase),
                                  );
                                  if (constraints.maxWidth < 520) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        syncButton,
                                        const SizedBox(height: 8),
                                        recoveryButton,
                                      ],
                                    );
                                  }
                                  return Row(
                                    children: [
                                      Expanded(child: syncButton),
                                      const SizedBox(width: 8),
                                      recoveryButton,
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading:
                                    const Icon(Icons.devices_other_outlined),
                                title: Text(l10n.thisDeviceName),
                                subtitle: Text(l10n.shownWhenChoosingBackup),
                                trailing: OutlinedButton(
                                  onPressed:
                                      _busy ? null : _showDeviceNameDialog,
                                  child: Text(l10n.edit),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                                await _sync.signOut();
                                setState(() {
                                  _hasLocalVault = null;
                                  _hasRemoteVault = null;
                                });
                              }),
                      child: Text(l10n.signOut),
                    ),
                  ] else ...[
                    Text(_createMode ? l10n.createAccount : l10n.signIn,
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 12),
                    TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                            labelText: 'E-mail', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _password,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: l10n.passwordMin12,
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          tooltip: _obscurePassword
                              ? l10n.showPassword
                              : l10n.hidePassword,
                        ),
                      ),
                    ),
                    if (_createMode) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _recovery,
                        obscureText: _obscureRecovery,
                        decoration: InputDecoration(
                          labelText: l10n.secretPhraseMin16,
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureRecovery
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () => setState(
                                () => _obscureRecovery = !_obscureRecovery),
                            tooltip: _obscureRecovery
                                ? l10n.showPhrase
                                : l10n.hidePhrase,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmRecovery,
                        obscureText: _obscureConfirmRecovery,
                        decoration: InputDecoration(
                          labelText: l10n.confirmSecretPhrase,
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmRecovery
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () => setState(() =>
                                _obscureConfirmRecovery =
                                    !_obscureConfirmRecovery),
                            tooltip: _obscureConfirmRecovery
                                ? l10n.showPhrase
                                : l10n.hidePhrase,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                                if (_createMode) {
                                  final phrase = _recovery.text.trim();
                                  final confirm = _confirmRecovery.text.trim();
                                  if (phrase.length < 16) {
                                    throw ArgumentError(
                                        l10n.secretPhraseTooShort);
                                  }
                                  if (phrase != confirm) {
                                    throw ArgumentError(
                                        l10n.secretPhrasesDoNotMatch);
                                  }
                                  final confirmed =
                                      await _showConfirmCreationDialog(phrase);
                                  if (!confirmed) return;
                                  await _sync.createAccount(
                                      email: _email.text,
                                      password: _password.text);
                                  await _sync.createVault(phrase);
                                } else {
                                  await _sync.signIn(
                                      email: _email.text,
                                      password: _password.text);
                                }
                                await _checkVault();
                              }),
                      child: Text(
                          _createMode ? l10n.createTheAccount : l10n.signIn),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() => _createMode = !_createMode),
                      child: Text(_createMode
                          ? l10n.alreadyHaveAccount
                          : l10n.createAccount),
                    ),
                    // Windows signs in through the browser when the build has a
                    // desktop OAuth client; Linux keeps email and password only.
                    if (FirebaseBootstrap.supportsGoogleSignIn) ...[
                      const Divider(height: 32),
                      OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _run(() async {
                                  await _sync.signInWithGoogle();
                                  await _checkVault();
                                }),
                        icon: const Icon(Icons.g_mobiledata),
                        label: Text(l10n.continueWithGoogle),
                      ),
                    ],
                  ],
                  const SizedBox(height: 24),
                  Text(l10n.recoveryPhraseRequiredNote),
                ],
              )),
        );
      },
    );
  }
}
