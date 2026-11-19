import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/book_item.dart';
import '../models/remote_file.dart';
import '../models/server_profile.dart';
import '../providers/download_provider.dart';
import '../providers/library_provider.dart';
import '../providers/server_provider.dart';
import '../services/remote_cover_service.dart';
import 'console_kit.dart';

enum _Row { servers, files, actions }

/// "Console" servers page for large windows: a row of server cards, the
/// content of the open folder as tiles, and the folder actions. Driven by
/// mouse or keyboard (arrows, Enter, Escape = parent folder, F5 = refresh).
class ConsoleServersView extends StatefulWidget {
  const ConsoleServersView({
    super.key,
    required this.onAddServer,
    required this.onEditServer,
    required this.onTestServer,
    required this.onDeleteServer,
    required this.onOpenBook,
  });

  final VoidCallback onAddServer;
  final ValueChanged<ServerProfile> onEditServer;
  final ValueChanged<ServerProfile> onTestServer;
  final ValueChanged<ServerProfile> onDeleteServer;
  final ValueChanged<BookItem> onOpenBook;

  @override
  State<ConsoleServersView> createState() => _ConsoleServersViewState();
}

class _ConsoleServersViewState extends State<ConsoleServersView>
    with SingleTickerProviderStateMixin {
  static const _gap = 22.0;

  final _focus = FocusNode(debugLabel: 'console-servers');
  final _serverScroll = ScrollController();
  final _fileScroll = ScrollController();
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  _Row _row = _Row.servers;
  int _si = 0, _fi = 0, _ai = 0;
  String? _shownPath;

  double _cardW = 280, _cardH = 150, _tw = 128, _th = 179;

  @override
  void initState() {
    super.initState();
    // Open the active (or first) server so its folders show straight away.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = context.read<ServerProvider>();
      if (p.servers.isEmpty) return;
      final s = p.activeServer ?? p.servers.first;
      _si = math.max(0, p.servers.indexWhere((e) => e.id == s.id));
      if (!p.isBrowsing || p.activeServer == null) p.openServer(s);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _focus.dispose();
    _serverScroll.dispose();
    _fileScroll.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------ Data

  List<RemoteFile> _items(ServerProvider p) => [
        ...p.remoteFiles.where((f) => f.isDirectory),
        ...p.remoteFiles.where((f) => !f.isDirectory && f.isSupportedBook),
      ];

  BookItem? _localBook(ServerProfile s, RemoteFile f) =>
      context.read<LibraryProvider>().getBookByServerPath(s.id, f.path);

  List<RemoteFile> _missing(ServerProvider p, DownloadProvider d) {
    final s = p.activeServer;
    if (s == null) return const [];
    return _items(p)
        .where((f) =>
            !f.isDirectory &&
            _localBook(s, f) == null &&
            d.getActiveTaskForRemotePath(f.path) == null)
        .toList();
  }

  List<ConsoleAction> _actions(ServerProvider p, DownloadProvider d) {
    final s = p.activeServer;
    if (s == null) return const [];
    final missing = _missing(p, d);
    return [
      if (missing.isNotEmpty)
        ConsoleAction(l10n.consoleDownloadMissing(missing.length),
            () => _downloadAll(s, missing),
            icon: Icons.download_rounded, primary: true),
      if (p.canNavigateUp)
        ConsoleAction(l10n.parentFolder, _parent,
            icon: Icons.arrow_upward_rounded),
      ConsoleAction(l10n.refresh, p.fetchRemoteFiles,
          icon: Icons.refresh_rounded),
      ConsoleAction(l10n.editServer, () => widget.onEditServer(s),
          icon: Icons.edit_rounded),
    ];
  }

  // ------------------------------------------------------------ Actions

  void _snack(String text) {
    final m = ScaffoldMessenger.of(context);
    m.hideCurrentSnackBar();
    m.showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        content: Text(text)));
  }

  Future<void> _downloadAll(ServerProfile s, List<RemoteFile> files) async {
    if (files.length > 3) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.downloadAllTitle),
          content: Text(l10n.downloadAllBody(files.length)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel)),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.downloadAllCount(files.length))),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    final d = context.read<DownloadProvider>();
    for (final f in files) {
      d.enqueueDownload(server: s, remoteFile: f);
    }
    _snack(l10n.volumesQueuedCount(files.length));
  }

  void _openServer(int i) {
    final p = context.read<ServerProvider>();
    if (i >= p.servers.length) {
      widget.onAddServer();
      return;
    }
    final s = p.servers[i];
    setState(() {
      _si = i;
      _row = _Row.files;
      _fi = 0;
    });
    if (p.activeServer?.id != s.id || !p.isBrowsing) p.openServer(s);
  }

  void _openItem(RemoteFile f) {
    final p = context.read<ServerProvider>();
    final s = p.activeServer;
    if (s == null) return;
    if (f.isDirectory) {
      setState(() => _fi = 0);
      p.navigateTo(f.path);
      return;
    }
    final book = _localBook(s, f);
    if (book != null) {
      widget.onOpenBook(book);
      return;
    }
    final d = context.read<DownloadProvider>();
    if (d.getActiveTaskForRemotePath(f.path) != null) {
      _snack(l10n.consoleAlreadyQueued);
      return;
    }
    d.enqueueDownload(server: s, remoteFile: f);
    _snack(l10n.downloadingNamePlain(f.name));
  }

  void _parent() {
    final p = context.read<ServerProvider>();
    if (p.canNavigateUp) {
      setState(() => _fi = 0);
      p.navigateUp();
    }
  }

  void _activate() {
    final p = context.read<ServerProvider>();
    switch (_row) {
      case _Row.servers:
        _openServer(_si);
      case _Row.files:
        final items = _items(p);
        if (_fi < items.length) _openItem(items[_fi]);
      case _Row.actions:
        final a = _actions(p, context.read<DownloadProvider>());
        if (_ai < a.length) a[_ai].run();
    }
  }

  void _move(int dx, int dy) {
    final p = context.read<ServerProvider>();
    setState(() {
      if (dy != 0) {
        final i = (_row.index + dy).clamp(0, _Row.values.length - 1).toInt();
        _row = _Row.values[i];
        return;
      }
      switch (_row) {
        case _Row.servers:
          _si = (_si + dx).clamp(0, p.servers.length).toInt();
        case _Row.files:
          _fi = (_fi + dx).clamp(0, math.max(0, _items(p).length - 1)).toInt();
        case _Row.actions:
          final n = _actions(p, context.read<DownloadProvider>()).length;
          _ai = (_ai + dx).clamp(0, math.max(0, n - 1)).toInt();
      }
    });
    if (_row == _Row.servers) {
      consoleScrollTo(_serverScroll, _si, _cardW + _gap);
    } else if (_row == _Row.files) {
      consoleScrollTo(_fileScroll, _fi, _tw + _gap);
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.arrowLeft) {
      _move(-1, 0);
    } else if (k == LogicalKeyboardKey.arrowRight) {
      _move(1, 0);
    } else if (k == LogicalKeyboardKey.arrowUp) {
      _move(0, -1);
    } else if (k == LogicalKeyboardKey.arrowDown) {
      _move(0, 1);
    } else if (k == LogicalKeyboardKey.enter ||
        k == LogicalKeyboardKey.numpadEnter ||
        k == LogicalKeyboardKey.space) {
      if (e is KeyRepeatEvent) return KeyEventResult.handled;
      _activate();
    } else if (k == LogicalKeyboardKey.escape ||
        k == LogicalKeyboardKey.backspace) {
      final p = context.read<ServerProvider>();
      if (p.canNavigateUp) {
        _parent();
      } else if (_row != _Row.servers) {
        setState(() => _row = _Row.servers);
      } else {
        return KeyEventResult.ignored;
      }
    } else if (k == LogicalKeyboardKey.f5) {
      context.read<ServerProvider>().fetchRemoteFiles();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  Future<void> _serverMenu(ServerProfile s, Offset at) async {
    final v = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(at.dx, at.dy, at.dx, at.dy),
      items: [
        PopupMenuItem(value: 'edit', child: Text(l10n.editServer)),
        PopupMenuItem(value: 'test', child: Text(l10n.testConnection)),
        PopupMenuItem(value: 'delete', child: Text(l10n.deleteThisServer)),
      ],
    );
    if (v == 'edit') widget.onEditServer(s);
    if (v == 'test') widget.onTestServer(s);
    if (v == 'delete') widget.onDeleteServer(s);
  }

  // ------------------------------------------------------------ Build

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ServerProvider>();
    final d = context.watch<DownloadProvider>();
    context.watch<LibraryProvider>();
    final theme = Theme.of(context);
    final active = p.activeServer;

    // A new folder starts at its first tile.
    if (_shownPath != p.currentPath) {
      _shownPath = p.currentPath;
      _fi = 0;
      if (_fileScroll.hasClients) _fileScroll.jumpTo(0);
    }
    final items = _items(p);
    _fi = math.min(_fi, math.max(0, items.length - 1));
    _si = math.min(_si, p.servers.length);
    final actions = _actions(p, d);
    _ai = math.min(_ai, math.max(0, actions.length - 1));

    return LayoutBuilder(builder: (context, box) {
      final h = box.maxHeight;
      _cardH = (h * .19).clamp(120.0, 160.0);
      _cardW = _cardH * 1.8;
      _th = ((h - 420) / 1.3).clamp(130.0, 230.0);
      _tw = _th * .715;

      return Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (_) => _focus.requestFocus(),
          child: ConsoleBackdrop(
            color: active == null
                ? theme.colorScheme.primary
                : consoleColor(active.name),
            child: Column(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: box.maxWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildServers(theme, p),
                          ConsoleLabel(
                            [
                              if (active != null) active.name,
                              ...p.breadcrumbs,
                            ].join('  ›  '),
                            trailing: active == null
                                ? null
                                : '· ${l10n.consoleItemsCount(items.length)}',
                          ),
                          _buildFiles(theme, p, d, items),
                          if (actions.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(28, 0, 28, 10),
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 10,
                                children: [
                                  for (var i = 0; i < actions.length; i++)
                                    MouseRegion(
                                      onEnter: (_) => setState(() {
                                        _row = _Row.actions;
                                        _ai = i;
                                      }),
                                      child: ConsoleActionButton(
                                        action: actions[i],
                                        focused:
                                            _row == _Row.actions && _ai == i,
                                        onTap: () {
                                          _focus.requestFocus();
                                          actions[i].run();
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                ConsoleHints([
                  (['←', '→', '↑', '↓'], l10n.consoleHintMove),
                  (['↵'], l10n.consoleHintOpenDownload),
                  (['Esc'], l10n.parentFolder),
                  (['F5'], l10n.refresh),
                ]),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildServers(ThemeData theme, ServerProvider p) {
    final cs = theme.colorScheme;
    final padV = _cardH * .06 + 26;
    return SizedBox(
      height: _cardH + padV * 2,
      child: consoleWheel(
        _serverScroll,
        ListView.builder(
          controller: _serverScroll,
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: padV),
          itemCount: p.servers.length + 1,
          itemBuilder: (context, i) {
            final add = i == p.servers.length;
            final s = add ? null : p.servers[i];
            final focused = _row == _Row.servers && _si == i;
            final selected = s != null && p.activeServer?.id == s.id;
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() {
                _row = _Row.servers;
                _si = i;
              }),
              child: GestureDetector(
                onTap: () {
                  _focus.requestFocus();
                  _openServer(i);
                },
                onSecondaryTapDown:
                    s == null ? null : (e) => _serverMenu(s, e.globalPosition),
                child: Semantics(
                  button: true,
                  selected: selected,
                  label: s?.name ?? l10n.addServer,
                  child: ConsoleTile(
                    width: _cardW,
                    height: _cardH,
                    focused: focused,
                    scale: 1.06,
                    dimmed: _row != _Row.servers && !selected,
                    pulse: _pulse,
                    cover: add
                        ? _AddServerCard(color: cs.onSurfaceVariant)
                        : _ServerCard(server: s!, selected: selected),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFiles(ThemeData theme, ServerProvider p, DownloadProvider d,
      List<RemoteFile> items) {
    final padV = _th * .07 + 24;
    final height = _th + padV * 2;
    final muted = theme.textTheme.titleMedium
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final s = p.activeServer;
    Widget message(Widget child) =>
        SizedBox(height: height, child: Center(child: child));

    if (s == null) return message(Text(l10n.consoleChooseServer, style: muted));
    if (p.isLoading && items.isEmpty) {
      return message(const CircularProgressIndicator());
    }
    if (p.errorMessage != null) {
      return message(Column(mainAxisSize: MainAxisSize.min, children: [
        Text(p.errorMessage!, style: muted, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        FilledButton.icon(
            onPressed: p.fetchRemoteFiles,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.retry)),
      ]));
    }
    if (items.isEmpty) return message(Text(l10n.folderEmpty, style: muted));

    return SizedBox(
      height: height,
      child: consoleWheel(
        _fileScroll,
        ListView.builder(
          controller: _fileScroll,
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: padV),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final f = items[i];
            final focused = _row == _Row.files && _fi == i;
            final book = f.isDirectory ? null : _localBook(s, f);
            final task =
                f.isDirectory ? null : d.getActiveTaskForRemotePath(f.path);
            final Widget? badge;
            if (book != null) {
              badge =
                  const ConsoleBadge(Icons.check_rounded, Color(0xFF0E9F6E));
            } else if (task != null) {
              badge = const ConsoleBadge(
                  Icons.downloading_rounded, Color(0xFF0891B2));
            } else if (!f.isDirectory) {
              badge =
                  const ConsoleBadge(Icons.cloud_outlined, Color(0xBF0A0B22));
            } else {
              badge = null;
            }
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() {
                _row = _Row.files;
                _fi = i;
              }),
              child: GestureDetector(
                onTap: () {
                  _focus.requestFocus();
                  _openItem(f);
                },
                child: Semantics(
                  button: true,
                  label: f.name,
                  child: ConsoleTile(
                    width: _tw,
                    height: _th,
                    radius: 16,
                    focused: focused,
                    pulse: _pulse,
                    badge: badge,
                    progress: task?.progress ?? 0,
                    cover: f.isDirectory
                        ? _FolderCover(name: f.name)
                        : Stack(fit: StackFit.expand, children: [
                            ConsoleRemoteCover(
                                server: s,
                                file: f,
                                localCover: book?.coverPath),
                            _TitleBand(_displayName(f.name)),
                          ]),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static String _displayName(String name) {
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }
}

// ------------------------------------------------------------------ Pieces

class _ServerCard extends StatelessWidget {
  const _ServerCard({required this.server, required this.selected});
  final ServerProfile server;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = consoleColor(server.name);
    final kind = switch (server.serverType) {
      ServerType.webdav => 'WebDAV',
      ServerType.ftp => 'FTP',
      ServerType.httpDirectory => 'HTTP',
    };
    return ColoredBox(
      color: cs.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(13)),
                child: Icon(
                    server.serverType == ServerType.webdav
                        ? Icons.dns_rounded
                        : Icons.cloud_rounded,
                    color: Colors.white),
              ),
              const Spacer(),
              if (selected)
                Icon(Icons.folder_open_rounded, color: cs.primary, size: 20),
            ]),
            const Spacer(),
            Text(server.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text('$kind · ${server.host}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _AddServerCard extends StatelessWidget {
  const _AddServerCard({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: .5),
          border: Border.all(color: color.withValues(alpha: .45), width: 2),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 34, color: color),
            const SizedBox(height: 4),
            Text(l10n.addServer,
                style: TextStyle(fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      );
}

class _FolderCover extends StatelessWidget {
  const _FolderCover({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final c = consoleColor(name);
    final dark = consoleColor(name, l: .26);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c, dark]),
      ),
      child: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        return Stack(children: [
          Positioned(
            left: 0,
            top: 0,
            width: w * .58,
            height: 16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .22),
                borderRadius:
                    const BorderRadius.only(bottomRight: Radius.circular(12)),
              ),
            ),
          ),
          Positioned(
            left: w * .1,
            top: w * .22,
            child: Icon(Icons.folder_rounded,
                color: Colors.white.withValues(alpha: .9), size: w * .26),
          ),
          Positioned(
            left: w * .1,
            right: w * .08,
            bottom: w * .1,
            child: Text(name,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: w * .115,
                    height: 1.1)),
          ),
        ]);
      }),
    );
  }
}

class _TitleBand extends StatelessWidget {
  const _TitleBand(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(9, 22, 9, 10),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xC0000000)]),
          ),
          child: Text(title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  height: 1.15)),
        ),
      );
}

/// Cover of a remote book: the local cover once downloaded, otherwise the
/// cover fetched from the server (cached by [RemoteCoverService]).
class ConsoleRemoteCover extends StatefulWidget {
  const ConsoleRemoteCover(
      {super.key, required this.server, required this.file, this.localCover});
  final ServerProfile server;
  final RemoteFile file;
  final String? localCover;

  @override
  State<ConsoleRemoteCover> createState() => _ConsoleRemoteCoverState();
}

class _ConsoleRemoteCoverState extends State<ConsoleRemoteCover> {
  String? _path;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ConsoleRemoteCover old) {
    super.didUpdateWidget(old);
    if (old.file.path != widget.file.path ||
        old.localCover != widget.localCover) {
      _path = null;
      _load();
    }
  }

  /// Local or already cached cover, without waiting.
  String? _immediate() {
    final local = widget.localCover;
    if (local != null && File(local).existsSync()) return local;
    return RemoteCoverService().getCachedCoverSync(widget.server, widget.file);
  }

  void _load() {
    _path = _immediate();
    if (_path != null) return;
    RemoteCoverService()
        .getCoverForRemoteBook(server: widget.server, file: widget.file)
        .then((path) {
      if (mounted && path != null) setState(() => _path = path);
    });
  }

  @override
  Widget build(BuildContext context) => ConsoleCover(
        path: _path,
        title: widget.file.name,
      );
}
