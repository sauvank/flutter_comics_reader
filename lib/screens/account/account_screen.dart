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
  bool _createMode = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _recovery.dispose();
    super.dispose();
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
        return Scaffold(
          appBar: AppBar(title: const Text('Compte et synchronisation')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (user != null) ...[
                ListTile(leading: const Icon(Icons.verified_user_outlined), title: Text(user.email ?? 'Compte connecté'), subtitle: const Text('Vos données sont chiffrées avant synchronisation.')),
                FilledButton.icon(onPressed: _busy ? null : () => _run(() async { final conflicts = await _sync.syncNow(); if (conflicts.isNotEmpty) throw StateError('${conflicts.length} conflit(s) à résoudre'); }), icon: const Icon(Icons.sync), label: const Text('Synchroniser maintenant')),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: _busy ? null : () => _run(_sync.signOut), child: const Text('Se déconnecter')),
              ] else ...[
                Text(_createMode ? 'Créer un compte' : 'Se connecter', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-mail')),
                TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Mot de passe (12 caractères minimum)')),
                if (_createMode) TextField(controller: _recovery, obscureText: true, decoration: const InputDecoration(labelText: 'Phrase de récupération (à conserver hors ligne)')),
                const SizedBox(height: 16),
                FilledButton(onPressed: _busy ? null : () => _run(() async { if (_createMode) { await _sync.createAccount(email: _email.text, password: _password.text); await _sync.createVault(_recovery.text); } else { await _sync.signIn(email: _email.text, password: _password.text); } }), child: Text(_createMode ? 'Créer le compte' : 'Se connecter')),
                TextButton(onPressed: _busy ? null : () => setState(() => _createMode = !_createMode), child: Text(_createMode ? 'J’ai déjà un compte' : 'Créer un compte')),
                const Divider(height: 32),
                OutlinedButton.icon(onPressed: _busy ? null : () => _run(() async => _sync.signInWithGoogle()), icon: const Icon(Icons.g_mobiledata), label: const Text('Continuer avec Google')),
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
