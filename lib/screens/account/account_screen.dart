import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../services/sync/sync_service.dart';
import '../../services/sync/firebase_bootstrap.dart';
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
  final _phrase = TextEditingController();
  bool _createMode = false;
  bool _busy = false;
  bool? _hasLocalVault;
  bool? _hasRemoteVault;
  bool _loadingVault = false;

  @override
  void initState() {
    super.initState();
    if (_sync.user != null) {
      _checkVault();
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _recovery.dispose();
    _phrase.dispose();
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
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Réinitialiser')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _hasRemoteVault = false);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opération terminée.')));
    } catch (error) {
      if (error is GoogleSignInException && error.code == GoogleSignInExceptionCode.canceled) {
        return;
      }
      if (error is FirebaseAuthException && error.code == 'web-context-canceled') {
        return;
      }
      var message = 'Impossible de continuer : $error';
      if (error.toString().contains('invalid-cert-hash')) {
        final hashes = await AndroidSigningCertificateService.currentSha1();
        if (hashes.isNotEmpty) {
          message = 'Certificat Android non autorisé : ${hashes.join(', ')}';
        }
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!FirebaseBootstrap.isAvailable) {
      return Scaffold(
        appBar: AppBar(title: const Text('Compte et synchronisation')),
        body: const Padding(
          padding: EdgeInsets.all(24),
          child: Text('La synchronisation sera disponible après la configuration du projet Firebase. Le lecteur et vos données locales continuent de fonctionner normalement.'),
        ),
      );
    }
    return StreamBuilder(
      stream: _sync.authChanges,
      builder: (context, _) {
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
                    _hasLocalVault == true ? Icons.verified_user_outlined : Icons.lock_outline,
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
                  const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
                ] else if (_hasLocalVault == false) ...[
                  Card(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(120),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _hasRemoteVault == true ? Icons.lock_reset : Icons.shield_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _hasRemoteVault == true
                                      ? 'Déverrouiller le coffre'
                                      : 'Initialiser votre coffre chiffré',
                                  style: Theme.of(context).textTheme.titleMedium,
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
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: _hasRemoteVault == true
                                  ? 'Phrase de récupération'
                                  : 'Phrase secrète (16 caractères minimum)',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _busy
                                  ? null
                                  : () => _run(() async {
                                        if (_hasRemoteVault == true) {
                                          await _sync.restoreVault(_phrase.text);
                                        } else {
                                          await _sync.createVault(_phrase.text);
                                        }
                                        _phrase.clear();
                                        await _checkVault();
                                      }),
                              icon: Icon(_hasRemoteVault == true ? Icons.lock_open : Icons.vpn_key),
                              label: Text(
                                _hasRemoteVault == true ? 'Déverrouiller la synchronisation' : 'Créer et activer le coffre',
                              ),
                            ),
                          ),
                          if (_hasRemoteVault == true) ...[
                            const SizedBox(height: 8),
                            Center(
                              child: TextButton(
                                onPressed: _busy ? null : _showResetVaultDialog,
                                child: const Text('Phrase oubliée ? Réinitialiser le coffre'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _run(() async {
                              final conflicts = await _sync.syncNow();
                              if (conflicts.isNotEmpty) throw StateError('${conflicts.length} conflit(s) à résoudre');
                            }),
                    icon: const Icon(Icons.sync),
                    label: const Text('Synchroniser maintenant'),
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
                Text(_createMode ? 'Créer un compte' : 'Se connecter', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-mail')),
                TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Mot de passe (12 caractères minimum)')),
                if (_createMode) TextField(controller: _recovery, obscureText: true, decoration: const InputDecoration(labelText: 'Phrase de récupération (à conserver hors ligne)')),
                const SizedBox(height: 16),
                FilledButton(onPressed: _busy ? null : () => _run(() async { if (_createMode) { await _sync.createAccount(email: _email.text, password: _password.text); await _sync.createVault(_recovery.text); } else { await _sync.signIn(email: _email.text, password: _password.text); } await _checkVault(); }), child: Text(_createMode ? 'Créer le compte' : 'Se connecter')),
                TextButton(onPressed: _busy ? null : () => setState(() => _createMode = !_createMode), child: Text(_createMode ? 'J’ai déjà un compte' : 'Créer un compte')),
                const Divider(height: 32),
                OutlinedButton.icon(onPressed: _busy ? null : () => _run(() async { await _sync.signInWithGoogle(); await _checkVault(); }), icon: const Icon(Icons.g_mobiledata), label: const Text('Continuer avec Google')),
              ],
              const SizedBox(height: 24),
              const Text('La phrase de récupération est indispensable pour restaurer les mots de passe de serveurs sur un nouvel appareil. Elle n’est jamais sauvegardée par ComicStream.'),
            ],
          ),
        );
      },
    );
  }
}
