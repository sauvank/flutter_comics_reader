import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../../providers/library_provider.dart';
import '../../providers/server_provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/sync/sync_service.dart';
import '../../services/sync/firebase_bootstrap.dart';
import '../../services/sync/sync_models.dart';
import '../../services/android_signing_certificate_service.dart';

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
        title: const Text('Réinitialiser le coffre ?'),
        content: const Text(
          'Si vous avez perdu votre phrase de récupération, la réinitialisation créera un nouveau coffre vierge. '
          'Les données protégées de vos autres appareils devront être synchronisées à nouveau.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Réinitialiser')),
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
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber),
                SizedBox(width: 8),
                Expanded(child: Text('Confirmer la phrase secrète')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Avez-vous bien noté votre phrase secrète dans un endroit sûr ?\n\n'
                  'Elle est indispensable pour restaurer vos données ou synchroniser un nouvel appareil. '
                  'ComicStream ne la conserve pas et ne pourra jamais la récupérer pour vous.',
                ),
                const SizedBox(height: 12),
                const Text('Votre phrase secrète :',
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
                child: const Text('Modifier'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('J’ai bien noté, continuer'),
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
          title: const Text('Modifier la phrase secrète'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Définissez une nouvelle phrase secrète (16 caractères minimum) pour sécuriser votre synchronisation.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPhraseController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'Nouvelle phrase secrète',
                    helperText: '16 caractères minimum',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                          obscureNew ? Icons.visibility : Icons.visibility_off),
                      onPressed: () =>
                          setDialogState(() => obscureNew = !obscureNew),
                      tooltip: obscureNew
                          ? 'Afficher la phrase'
                          : 'Masquer la phrase',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPhraseController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirmer la nouvelle phrase',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () => setDialogState(
                          () => obscureConfirm = !obscureConfirm),
                      tooltip: obscureConfirm
                          ? 'Afficher la phrase'
                          : 'Masquer la phrase',
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
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                final phrase = newPhraseController.text.trim();
                final confirm = confirmPhraseController.text.trim();
                if (phrase.length < 16) {
                  setDialogState(() => errorText =
                      'La phrase doit comporter au moins 16 caractères.');
                  return;
                }
                if (phrase != confirm) {
                  setDialogState(() =>
                      errorText = 'Les deux phrases ne correspondent pas.');
                  return;
                }
                Navigator.of(ctx).pop(phrase);
              },
              child: const Text('Continuer'),
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
          title: const Text('Confirmer le changement ?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Votre coffre va être mis à jour avec cette nouvelle phrase secrète.\n'
                'Assurez-vous de l’avoir bien notée :',
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
              child: const Text('Modifier'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Confirmer et enregistrer'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        await _run(() async {
          await _sync.updateRecoveryPhrase(result);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Phrase secrète mise à jour avec succès.')),
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
            .showSnackBar(const SnackBar(content: Text('Opération terminée.')));
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
      var message = 'Impossible de continuer : $error';
      if (error.toString().contains('invalid-cert-hash')) {
        final hashes = await AndroidSigningCertificateService.currentSha1();
        if (hashes.isNotEmpty) {
          message = 'Certificat Android non autorisé : ${hashes.join(', ')}';
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
    return '$date à $time';
  }

  Future<void> _resolveConflicts(List<SyncConflict> conflicts) async {
    for (final conflict in conflicts) {
      if (!mounted) return;
      final choice = await showDialog<SyncConflictResolution>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Conflit de synchronisation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Deux versions de « ${conflict.label} » ont été modifiées.'),
              const SizedBox(height: 12),
              Text(
                  'Cet appareil : ${_formatConflictDate(conflict.localUpdatedAt)}'),
              const SizedBox(height: 4),
              Text(
                  'Données Google : ${_formatConflictDate(conflict.remoteUpdatedAt)}'),
              const SizedBox(height: 12),
              Text('Cet appareil : ${conflict.localSummary}'),
              const SizedBox(height: 4),
              Text('Google : ${conflict.remoteSummary}'),
              const SizedBox(height: 12),
              const Text(
                  'En gardant Google, ces données remplaceront celles de cet appareil.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Plus tard'),
            ),
            OutlinedButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(SyncConflictResolution.keepRemote),
              child: const Text('Garder Google'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(SyncConflictResolution.keepLocal),
              child: const Text('Garder cet appareil'),
            ),
          ],
        ),
      );
      if (choice == null) return;
      await _sync.resolveConflict(conflict, choice);
    }
  }

  Future<void> _resolveAutomaticConflicts(SyncProvider syncProvider) async {
    final serverProvider = context.read<ServerProvider>();
    final libraryProvider = context.read<LibraryProvider>();
    setState(() => _syncing = true);
    try {
      await _resolveConflicts(syncProvider.conflicts);
      if (!mounted) return;
      await syncProvider.syncNow();
      if (!mounted) return;
      await serverProvider.loadServers();
      await libraryProvider.loadLibrary();
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!FirebaseBootstrap.isAvailable) {
      return Scaffold(
        appBar: AppBar(title: const Text('Compte et synchronisation')),
        body: const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
              'La synchronisation sera disponible après la configuration du projet Firebase. Le lecteur et vos données locales continuent de fonctionner normalement.'),
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
          appBar: AppBar(title: const Text('Compte et synchronisation')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (user != null) ...[
                ListTile(
                  leading: Icon(
                    _hasLocalVault == true
                        ? Icons.verified_user_outlined
                        : Icons.lock_outline,
                    color: _hasLocalVault == true ? Colors.green : Colors.amber,
                  ),
                  title: Text(user.email ?? 'Compte connecté'),
                  subtitle: Text(
                    _hasLocalVault == true
                        ? 'Coffre déverrouillé. Vos données sont chiffrées de bout en bout.'
                        : 'Coffre verrouillé ou non initialisé.',
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
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _hasRemoteVault == true
                                      ? 'Déverrouiller le coffre'
                                      : 'Initialiser votre coffre chiffré',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _hasRemoteVault == true
                                ? 'Un coffre chiffré est associé à ce compte. Saisissez votre phrase de récupération pour déverrouiller la synchronisation sur cet appareil.'
                                : 'Pour protéger vos mots de passe de serveurs et vos données, choisissez une phrase secrète (16 caractères minimum). Elle est indispensable pour restaurer vos données sur un nouvel appareil.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _phrase,
                            obscureText: _obscurePhrase,
                            decoration: InputDecoration(
                              labelText: _hasRemoteVault == true
                                  ? 'Phrase de récupération'
                                  : 'Phrase secrète (16 caractères minimum)',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePhrase
                                    ? Icons.visibility
                                    : Icons.visibility_off),
                                onPressed: () => setState(
                                    () => _obscurePhrase = !_obscurePhrase),
                                tooltip: _obscurePhrase
                                    ? 'Afficher la phrase'
                                    : 'Masquer la phrase',
                              ),
                            ),
                          ),
                          if (_hasRemoteVault != true) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: _confirmPhrase,
                              obscureText: _obscureConfirmPhrase,
                              decoration: InputDecoration(
                                labelText: 'Confirmer la phrase secrète',
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureConfirmPhrase
                                      ? Icons.visibility
                                      : Icons.visibility_off),
                                  onPressed: () => setState(() =>
                                      _obscureConfirmPhrase =
                                          !_obscureConfirmPhrase),
                                  tooltip: _obscureConfirmPhrase
                                      ? 'Afficher la phrase'
                                      : 'Masquer la phrase',
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
                                                'Veuillez saisir votre phrase de récupération.');
                                          }
                                          await _sync.restoreVault(phrase);
                                        } else {
                                          final confirm =
                                              _confirmPhrase.text.trim();
                                          if (phrase.length < 16) {
                                            throw ArgumentError(
                                                'La phrase secrète doit comporter au moins 16 caractères.');
                                          }
                                          if (phrase != confirm) {
                                            throw ArgumentError(
                                                'Les phrases secrètes ne correspondent pas.');
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
                                    ? 'Déverrouiller la synchronisation'
                                    : 'Créer et activer le coffre',
                              ),
                            ),
                          ),
                          if (_hasRemoteVault == true) ...[
                            const SizedBox(height: 8),
                            Center(
                              child: TextButton(
                                onPressed: _busy ? null : _showResetVaultDialog,
                                child: const Text(
                                    'Phrase oubliée ? Réinitialiser le coffre'),
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
                            color:
                                Theme.of(context).colorScheme.onErrorContainer),
                        title: const Text('Conflit de synchronisation'),
                        subtitle: Text(
                          '${automaticSync.conflicts.length} modification${automaticSync.conflicts.length > 1 ? 's' : ''} attend${automaticSync.conflicts.length > 1 ? 'ent' : ''} votre choix.',
                        ),
                        trailing: FilledButton(
                          onPressed: _syncing
                              ? null
                              : () => _resolveAutomaticConflicts(automaticSync),
                          child: const Text('Voir'),
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
                                'Coffre déverrouillé',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'La synchronisation est active et protégée par chiffrement de bout en bout.',
                          ),
                          const SizedBox(height: 16),
                          if (_syncing) ...[
                            const LinearProgressIndicator(),
                            const SizedBox(height: 12),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _busy
                                      ? null
                                      : () async {
                                          final serverProvider =
                                              context.read<ServerProvider>();
                                          final libraryProvider =
                                              context.read<LibraryProvider>();
                                          setState(() => _syncing = true);
                                          try {
                                            await _run(() async {
                                              final conflicts =
                                                  await _sync.syncNow();
                                              if (conflicts.isNotEmpty) {
                                                await _resolveConflicts(
                                                    conflicts);
                                              }
                                              // Profiles imported by the sync
                                              // service are persisted directly.
                                              // Refresh the in-memory list used by
                                              // the Server tab before returning.
                                              if (mounted) {
                                                await serverProvider
                                                    .loadServers();
                                                await libraryProvider
                                                    .loadLibrary();
                                              }
                                            });
                                          } finally {
                                            if (mounted) {
                                              setState(() => _syncing = false);
                                            }
                                          }
                                        },
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
                                      ? 'Synchronisation…'
                                      : 'Synchroniser'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: _busy
                                    ? null
                                    : _showEditRecoveryPhraseDialog,
                                icon: const Icon(Icons.key),
                                label: const Text('Modifier la phrase'),
                              ),
                            ],
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
                  child: const Text('Se déconnecter'),
                ),
              ] else ...[
                Text(_createMode ? 'Créer un compte' : 'Se connecter',
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
                    labelText: 'Mot de passe (12 caractères minimum)',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      tooltip: _obscurePassword
                          ? 'Afficher le mot de passe'
                          : 'Masquer le mot de passe',
                    ),
                  ),
                ),
                if (_createMode) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _recovery,
                    obscureText: _obscureRecovery,
                    decoration: InputDecoration(
                      labelText: 'Phrase secrète (16 caractères minimum)',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureRecovery
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () => setState(
                            () => _obscureRecovery = !_obscureRecovery),
                        tooltip: _obscureRecovery
                            ? 'Afficher la phrase'
                            : 'Masquer la phrase',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmRecovery,
                    obscureText: _obscureConfirmRecovery,
                    decoration: InputDecoration(
                      labelText: 'Confirmer la phrase secrète',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmRecovery
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () => setState(() =>
                            _obscureConfirmRecovery = !_obscureConfirmRecovery),
                        tooltip: _obscureConfirmRecovery
                            ? 'Afficher la phrase'
                            : 'Masquer la phrase',
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
                                    'La phrase secrète doit comporter au moins 16 caractères.');
                              }
                              if (phrase != confirm) {
                                throw ArgumentError(
                                    'Les phrases secrètes ne correspondent pas.');
                              }
                              final confirmed =
                                  await _showConfirmCreationDialog(phrase);
                              if (!confirmed) return;
                              await _sync.createAccount(
                                  email: _email.text, password: _password.text);
                              await _sync.createVault(phrase);
                            } else {
                              await _sync.signIn(
                                  email: _email.text, password: _password.text);
                            }
                            await _checkVault();
                          }),
                  child: Text(_createMode ? 'Créer le compte' : 'Se connecter'),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _createMode = !_createMode),
                  child: Text(
                      _createMode ? 'J’ai déjà un compte' : 'Créer un compte'),
                ),
                const Divider(height: 32),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                            await _sync.signInWithGoogle();
                            await _checkVault();
                          }),
                  icon: const Icon(Icons.g_mobiledata),
                  label: const Text('Continuer avec Google'),
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                  'La phrase de récupération est indispensable pour restaurer les mots de passe de serveurs sur un nouvel appareil. Elle n’est jamais sauvegardée par ComicStream.'),
            ],
          ),
        );
      },
    );
  }
}
