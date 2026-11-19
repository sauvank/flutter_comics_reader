import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/server_profile.dart';
import '../providers/server_provider.dart';
import '../l10n/l10n.dart';

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
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final s = widget.server;
    _nameController = TextEditingController(text: s?.name ?? '');
    _hostController = TextEditingController(text: s?.host ?? '');
    _portController =
        TextEditingController(text: s != null ? s.port.toString() : '8080');
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

  void _onHostChanged(String value) {
    String input = value.trim();
    bool changed = false;

    if (input.startsWith('http://')) {
      input = input.replaceFirst('http://', '');
      _isHttps = false;
      changed = true;
    } else if (input.startsWith('https://')) {
      input = input.replaceFirst('https://', '');
      _isHttps = true;
      changed = true;
    }

    // Extract path
    if (input.contains('/')) {
      final parts = input.split('/');
      input = parts.first;
      final path = '/${parts.skip(1).join('/')}';
      _pathController.text = path;
      changed = true;
    }

    // Extract port
    if (input.contains(':')) {
      final parts = input.split(':');
      input = parts.first;
      _portController.text = parts.last;
      changed = true;
    }

    if (changed) {
      _hostController.text = input;
      // Move cursor to end
      _hostController.selection =
          TextSelection.fromPosition(TextPosition(offset: input.length));
      setState(() {});
    }
  }

  ServerProfile _buildProfile() {
    return ServerProfile(
      id: widget.server?.id ?? const Uuid().v4(),
      name: _nameController.text.trim().isEmpty
          ? l10n.serverDefaultName
          : _nameController.text.trim(),
      host: _hostController.text.trim(),
      port: int.tryParse(_portController.text.trim()) ??
          (_serverType == ServerType.ftp
              ? 21
              : _isHttps
                  ? 443
                  : 80),
      path: _pathController.text.trim().isEmpty
          ? '/'
          : _pathController.text.trim().replaceAll('\\', '/'),
      isHttps: _isHttps,
      serverType: _serverType,
      username: _userController.text.trim().isEmpty
          ? null
          : _userController.text.trim(),
      password: _passController.text.trim().isEmpty
          ? null
          : _passController.text.trim(),
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
        _testResult = l10n.connectionFailedCheck;
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
          ? l10n.connectionOkFolderValid
          : l10n.folderMissingOnServer(server.path);
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
        _testResult = l10n.checkingFolder;
        _testSuccess = null;
      });

      final connSuccess = await provider.testConnection(server);
      if (!connSuccess) {
        if (!mounted) return;
        setState(() {
          _isTesting = false;
          _testSuccess = false;
          _testResult = l10n.cannotReachServerCheck;
        });
        return;
      }

      final pathExists = await provider.verifyPathExists(server);
      if (!pathExists) {
        if (!mounted) return;
        setState(() {
          _isTesting = false;
          _testSuccess = false;
          _testResult = l10n.cannotSaveFolderMissing(server.path);
        });
        return;
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop(server);
  }

  void _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteServerTitle),
        content: Text(l10n.deleteProfileBody(widget.server?.name ?? '')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm == true && mounted && widget.server != null) {
      final serverName = widget.server?.name ?? '';
      await context.read<ServerProvider>().deleteServer(widget.server!.id);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.serverDeleted(serverName)),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
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
                      child: Icon(Icons.dns_rounded,
                          color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.server == null
                            ? l10n.addLocalServer
                            : l10n.editServer,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (widget.server != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
                        tooltip: l10n.deleteThisServer,
                        onPressed: _confirmDelete,
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
                  decoration: InputDecoration(
                    labelText: l10n.serverName,
                    prefixIcon: Icon(Icons.label_outline),
                    hintText: l10n.serverNameHint,
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? l10n.enterName : null,
                ),
                const SizedBox(height: 14),

                // Server Type Selector
                SegmentedButton<ServerType>(
                  segments: [
                    ButtonSegment(
                      value: ServerType.webdav,
                      label: Text('WebDAV'),
                      icon: Icon(Icons.folder_shared_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: ServerType.ftp,
                      label: Text(l10n.ftpPort21),
                      icon:
                          Icon(Icons.swap_horizontal_circle_outlined, size: 16),
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
                      if (_serverType == ServerType.ftp &&
                          (_portController.text == '8080' ||
                              _portController.text == '80')) {
                        _portController.text = '21';
                      } else if (_serverType == ServerType.webdav &&
                          _portController.text == '21') {
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
                        onChanged: _onHostChanged,
                        decoration: InputDecoration(
                          labelText: l10n.hostIp,
                          prefixIcon: Icon(Icons.router_outlined),
                          hintText: l10n.hostHint,
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? l10n.hostRequired
                            : null,
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
                  decoration: InputDecoration(
                    labelText: l10n.rootPath,
                    prefixIcon: Icon(Icons.folder_open_outlined),
                    hintText: '/webdav ou /comics ou /',
                  ),
                ),
                const SizedBox(height: 10),

                // HTTPS switch
                SwitchListTile(
                  title: Text(l10n.secureConnectionHttps,
                      style: TextStyle(fontSize: 14)),
                  value: _isHttps,
                  onChanged: (val) => setState(() => _isHttps = val),
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(height: 24),

                // Credentials section
                Text(
                  l10n.authenticationOptional,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _userController,
                  decoration: InputDecoration(
                    labelText: l10n.usernameLabel,
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _passController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: l10n.password,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
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
                          _testSuccess == true
                              ? Icons.check_circle
                              : Icons.error_outline,
                          color:
                              _testSuccess == true ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _testResult!,
                            style: TextStyle(
                              fontSize: 12,
                              color: _testSuccess == true
                                  ? Colors.green.shade200
                                  : Colors.red.shade200,
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
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.sensors, size: 18),
                        label: Text(l10n.test),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save_rounded, size: 18),
                        label: Text(l10n.save),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
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
