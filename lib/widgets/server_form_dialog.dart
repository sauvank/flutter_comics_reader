import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/server_profile.dart';
import '../providers/server_provider.dart';

class ServerFormDialog extends StatefulWidget {
  final ServerProfile? server;

  const ServerFormDialog({super.key, this.server});

  @override
  State<ServerFormDialog> createState() => _ServerFormDialogState();
}

class _ServerFormDialogState extends State<ServerFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _pathController;
  late TextEditingController _userController;
  late TextEditingController _passController;

  ServerType _serverType = ServerType.webdav;
  bool _isHttps = false;
  bool _isTesting = false;
  String? _testResult;
  bool? _testSuccess;

  @override
  void initState() {
    super.initState();
    final s = widget.server;
    _nameController = TextEditingController(text: s?.name ?? '');
    _hostController = TextEditingController(text: s?.host ?? '');
    _portController = TextEditingController(text: s != null ? s.port.toString() : '8080');
    _pathController = TextEditingController(text: s?.path ?? '');
    _userController = TextEditingController(text: s?.username ?? '');
    _passController = TextEditingController(text: s?.password ?? '');
    _serverType = s?.serverType ?? ServerType.webdav;
    _isHttps = s?.isHttps ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _pathController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  ServerProfile _buildProfile() {
    return ServerProfile(
      id: widget.server?.id ?? const Uuid().v4(),
      name: _nameController.text.trim().isEmpty ? 'Serveur' : _nameController.text.trim(),
      host: _hostController.text.trim(),
      port: int.tryParse(_portController.text.trim()) ?? (_serverType == ServerType.ftp ? 21 : _isHttps ? 443 : 80),
      path: _pathController.text.trim().isEmpty ? '/' : _pathController.text.trim().replaceAll('\\', '/'),
      isHttps: _isHttps,
      serverType: _serverType,
      username: _userController.text.trim().isEmpty ? null : _userController.text.trim(),
      password: _passController.text.trim().isEmpty ? null : _passController.text.trim(),
      isActive: widget.server?.isActive ?? true,
    );
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isTesting = true;
      _testResult = null;
      _testSuccess = null;
    });

    final server = _buildProfile();
    final provider = context.read<ServerProvider>();
    final connSuccess = await provider.testConnection(server);

    if (!connSuccess) {
      if (!mounted) return;
      setState(() {
        _isTesting = false;
        _testSuccess = false;
        _testResult = '❌ Échec de connexion. Vérifiez l\'adresse IP, le port et les identifiants.';
      });
      return;
    }

    // Check if the specified path actually exists
    final pathExists = await provider.verifyPathExists(server);
    if (!mounted) return;

    setState(() {
      _isTesting = false;
      _testSuccess = pathExists;
      _testResult = pathExists
          ? '✅ Connexion réussie et dossier validé !'
          : '❌ Le serveur répond, mais le dossier "${server.path}" n\'existe pas sur le serveur.';
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final server = _buildProfile();
    final provider = context.read<ServerProvider>();

    // If path is not root, check if it exists before allowing save
    if (server.path != '/' && server.path.isNotEmpty) {
      setState(() {
        _isTesting = true;
        _testResult = 'Vérification du dossier sur le serveur...';
        _testSuccess = null;
      });

      final connSuccess = await provider.testConnection(server);
      if (!connSuccess) {
        if (!mounted) return;
        setState(() {
          _isTesting = false;
          _testSuccess = false;
          _testResult = '❌ Impossible de joindre le serveur. Vérifiez les paramètres.';
        });
        return;
      }

      final pathExists = await provider.verifyPathExists(server);
      if (!pathExists) {
        if (!mounted) return;
        setState(() {
          _isTesting = false;
          _testSuccess = false;
          _testResult = '❌ Impossible d\'enregistrer : le dossier "${server.path}" n\'existe pas sur le serveur.';
        });
        return;
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop(server);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.dns_rounded, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.server == null ? 'Ajouter un serveur local' : 'Modifier le serveur',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Server Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du serveur',
                    prefixIcon: Icon(Icons.label_outline),
                    hintText: 'Ex: NAS Salon, PC Bureau...',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Veuillez saisir un nom' : null,
                ),
                const SizedBox(height: 14),

                // Server Type Selector
                SegmentedButton<ServerType>(
                  segments: const [
                    ButtonSegment(
                      value: ServerType.webdav,
                      label: Text('WebDAV'),
                      icon: Icon(Icons.folder_shared_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: ServerType.ftp,
                      label: Text('FTP (Port 21)'),
                      icon: Icon(Icons.swap_horizontal_circle_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: ServerType.httpDirectory,
                      label: Text('HTTP'),
                      icon: Icon(Icons.http_rounded, size: 16),
                    ),
                  ],
                  selected: {_serverType},
                  onSelectionChanged: (set) {
                    setState(() {
                      _serverType = set.first;
                      if (_serverType == ServerType.ftp && (_portController.text == '8080' || _portController.text == '80')) {
                        _portController.text = '21';
                      } else if (_serverType == ServerType.webdav && _portController.text == '21') {
                        _portController.text = '8080';
                      }
                    });
                  },
                ),
                const SizedBox(height: 14),

                // Host & Port Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _hostController,
                        decoration: const InputDecoration(
                          labelText: 'Hôte / IP',
                          prefixIcon: Icon(Icons.router_outlined),
                          hintText: 'ex: 192.168.1.10 ou nas.local',
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'IP ou domaine requis' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _portController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Port',
                          prefixIcon: Icon(Icons.tag),
                          hintText: '8080',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Path
                TextFormField(
                  controller: _pathController,
                  decoration: const InputDecoration(
                    labelText: 'Chemin racine (Path)',
                    prefixIcon: Icon(Icons.folder_open_outlined),
                    hintText: '/webdav ou /comics ou /',
                  ),
                ),
                const SizedBox(height: 10),

                // HTTPS switch
                SwitchListTile(
                  title: const Text('Connexion sécurisée (HTTPS)', style: TextStyle(fontSize: 14)),
                  value: _isHttps,
                  onChanged: (val) => setState(() => _isHttps = val),
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(height: 24),

                // Credentials section
                const Text(
                  'Authentification (Optionnel)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _userController,
                  decoration: const InputDecoration(
                    labelText: 'Identifiant / Nom d\'utilisateur',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _passController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 16),

                // Test result banner
                if (_testResult != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _testSuccess == true
                          ? Colors.green.withAlpha(30)
                          : Colors.red.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _testSuccess == true ? Colors.green : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _testSuccess == true ? Icons.check_circle : Icons.error_outline,
                          color: _testSuccess == true ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _testResult!,
                            style: TextStyle(
                              fontSize: 12,
                              color: _testSuccess == true ? Colors.green.shade200 : Colors.red.shade200,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isTesting ? null : _testConnection,
                        icon: _isTesting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.sensors, size: 18),
                        label: const Text('Tester'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save_rounded, size: 18),
                        label: const Text('Enregistrer'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
