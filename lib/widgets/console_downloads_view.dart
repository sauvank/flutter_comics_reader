import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/book_item.dart';
import '../models/download_task.dart';
import '../models/remote_file.dart';
import '../models/server_profile.dart';
import '../providers/download_provider.dart';
import '../providers/library_provider.dart';
import '../providers/server_provider.dart';
import '../utils/format_utils.dart';
import 'console_kit.dart';
import 'console_servers_view.dart';

enum _Row { live, queue, history }

/// "Console" downloads page for large windows: running downloads as large
/// cards, then the queue in start order, then the history. Keyboard: arrows,
/// Enter = read / retry, Delete = cancel.
class ConsoleDownloadsView extends StatefulWidget {
  const ConsoleDownloadsView({super.key, required this.onOpenBook});

  final ValueChanged<BookItem> onOpenBook;

  @override
  State<ConsoleDownloadsView> createState() => _ConsoleDownloadsViewState();
}

class _ConsoleDownloadsViewState extends State<ConsoleDownloadsView>
    with SingleTickerProviderStateMixin {
  static const _gap = 22.0;
  static const _live = Color(0xFF06B6D4);

  final _focus = FocusNode(debugLabel: 'console-downloads');
  final _scrolls = {for (final r in _Row.values) r: ScrollController()};
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  _Row _row = _Row.live;
  final _idx = {for (final r in _Row.values) r: 0};

  double _cw = 500, _ch = 170, _tw = 118, _th = 165;

  @override
  void dispose() {
    _pulse.dispose();
    _focus.dispose();
    for (final c in _scrolls.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ------------------------------------------------------------ Data

  static bool _running(DownloadTask t) =>
      t.status == DownloadStatus.downloading ||
      t.status == DownloadStatus.converting;

  Map<_Row, List<DownloadTask>> _lists(DownloadProvider d) {
    final active = d.activeTasks;
    return {
      _Row.live: active.where(_running).toList(),
      _Row.queue:
          active.where((t) => t.status == DownloadStatus.pending).toList(),
      _Row.history: d.tasks.where((t) => !active.contains(t)).toList(),
    };
  }

  ServerProfile? _server(DownloadTask t) {
    final servers = context.read<ServerProvider>().servers;
    for (final s in servers) {
      if (s.id == t.serverId) return s;
    }
    return null;
  }

  Widget _cover(DownloadTask t) {
    final book = context.read<LibraryProvider>().getBookById(t.bookId);
    final server = _server(t);
    if (book?.coverPath == null && server != null) {
      return ConsoleRemoteCover(
        server: server,
        file: RemoteFile(
            name: t.fileName,
            path: t.remotePath,
            isDirectory: false,
            size: t.totalBytes),
      );
    }
    return ConsoleCover(path: book?.coverPath, title: _title(t.fileName));
  }

  static String _title(String name) {
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  // ------------------------------------------------------------ Actions

  void _activate(DownloadTask t) {
    final d = context.read<DownloadProvider>();
    switch (t.status) {
      case DownloadStatus.completed:
        final book = context.read<LibraryProvider>().getBookById(t.bookId);
        if (book != null) widget.onOpenBook(book);
      case DownloadStatus.failed:
      case DownloadStatus.cancelled:
        final s = _server(t);
        if (s != null) d.retryDownload(t.id, s);
      default:
        break;
    }
  }

  void _cancel(DownloadTask t) {
    if (t.status == DownloadStatus.pending || _running(t)) {
      context.read<DownloadProvider>().cancelDownload(t.id);
    }
  }

  DownloadTask? _focused(Map<_Row, List<DownloadTask>> lists) {
    final l = lists[_row]!;
    final i = _idx[_row]!;
    return i < l.length ? l[i] : null;
  }

  void _move(int dx, int dy) {
    final lists = _lists(context.read<DownloadProvider>());
    setState(() {
      if (dy != 0) {
        // Skip empty rows.
        var i = _row.index;
        while (true) {
          i += dy;
          if (i < 0 || i >= _Row.values.length) return;
          if (lists[_Row.values[i]]!.isNotEmpty) break;
        }
        _row = _Row.values[i];
        return;
      }
      final n = lists[_row]!.length;
      _idx[_row] = (_idx[_row]! + dx).clamp(0, math.max(0, n - 1)).toInt();
    });
    final extent = (_row == _Row.live ? _cw : _tw) + _gap;
    consoleScrollTo(_scrolls[_row]!, _idx[_row]!, extent);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final k = e.logicalKey;
    final lists = _lists(context.read<DownloadProvider>());
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
      final t = _focused(lists);
      if (t != null) _activate(t);
    } else if (k == LogicalKeyboardKey.delete) {
      final t = _focused(lists);
      if (t != null) _cancel(t);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  // ------------------------------------------------------------ Build

  @override
  Widget build(BuildContext context) {
    final d = context.watch<DownloadProvider>();
    context.watch<LibraryProvider>();
    final theme = Theme.of(context);
    final lists = _lists(d);

    // Keep the focus on a row that still has items.
    if (lists[_row]!.isEmpty) {
      _row = _Row.values
          .firstWhere((r) => lists[r]!.isNotEmpty, orElse: () => _Row.live);
    }
    for (final r in _Row.values) {
      _idx[r] = math.min(_idx[r]!, math.max(0, lists[r]!.length - 1));
    }

    return LayoutBuilder(builder: (context, box) {
      final h = box.maxHeight;
      _ch = (h * .21).clamp(164.0, 184.0);
      _cw = math.min(520.0, box.maxWidth - 80);
      _th = ((h - _ch - 330) / 2.3).clamp(110.0, 170.0);
      _tw = _th * .715;

      return Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (_) => _focus.requestFocus(),
          child: ConsoleBackdrop(
            color: _live,
            child: Column(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: box.maxWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ConsoleLabel(
                              l10n.inProgressCount(lists[_Row.live]!.length)),
                          _buildRow(theme, _Row.live, lists[_Row.live]!,
                              l10n.noDownloadInProgress),
                          ConsoleLabel(
                              '${l10n.consoleQueue} · ${lists[_Row.queue]!.length}',
                              trailing: lists[_Row.queue]!.isEmpty
                                  ? null
                                  : '— ${l10n.consoleQueueHint}'),
                          _buildRow(
                              theme, _Row.queue, lists[_Row.queue]!, null),
                          ConsoleLabel(
                              l10n.historyCount(lists[_Row.history]!.length)),
                          _buildRow(theme, _Row.history, lists[_Row.history]!,
                              l10n.consoleNothingYet),
                        ],
                      ),
                    ),
                  ),
                ),
                ConsoleHints([
                  (['←', '→', '↑', '↓'], l10n.consoleHintMove),
                  (['↵'], l10n.consoleHintReadRetry),
                  (['Suppr'], l10n.cancel),
                ]),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildRow(
      ThemeData theme, _Row row, List<DownloadTask> tasks, String? emptyText) {
    final live = row == _Row.live;
    final w = live ? _cw : _tw, h = live ? _ch : _th;
    final padV = h * .06 + 20;
    if (tasks.isEmpty) {
      return SizedBox(
        height: emptyText == null ? 24 : 64,
        child: emptyText == null
            ? null
            : Padding(
                padding: const EdgeInsets.fromLTRB(28, 14, 28, 0),
                child: Text(emptyText,
                    style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700)),
              ),
      );
    }
    return SizedBox(
      height: h + padV * 2,
      child: consoleWheel(
        _scrolls[row]!,
        ListView.builder(
          controller: _scrolls[row],
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: padV),
          itemCount: tasks.length,
          itemBuilder: (context, i) {
            final t = tasks[i];
            final focused = _row == row && _idx[row] == i;
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() {
                _row = row;
                _idx[row] = i;
              }),
              child: GestureDetector(
                onTap: () {
                  _focus.requestFocus();
                  _activate(t);
                },
                child: Semantics(
                  button: true,
                  label: t.fileName,
                  child: ConsoleTile(
                    width: w,
                    height: h,
                    radius: live ? 20 : 14,
                    scale: live ? 1.04 : 1.12,
                    focused: focused,
                    pulse: _pulse,
                    badge: switch (row) {
                      _Row.live => null,
                      _Row.queue => _Number(i + 1),
                      _Row.history => t.status == DownloadStatus.completed
                          ? const ConsoleBadge(
                              Icons.check_rounded, Color(0xFF0E9F6E))
                          : const ConsoleBadge(
                              Icons.priority_high_rounded, Color(0xFFD6345B)),
                    },
                    cover: live
                        ? _LiveCard(
                            task: t,
                            cover: _cover(t),
                            onCancel: () => _cancel(t),
                          )
                        : Stack(fit: StackFit.expand, children: [
                            _cover(t),
                            _Band(row == _Row.history
                                ? switch (t.status) {
                                    DownloadStatus.completed =>
                                      l10n.consoleReady,
                                    DownloadStatus.cancelled =>
                                      l10n.consoleCancelled,
                                    _ => l10n.consoleFailed,
                                  }
                                : _title(t.fileName)),
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
}

// ------------------------------------------------------------------ Pieces

class _LiveCard extends StatelessWidget {
  const _LiveCard(
      {required this.task, required this.cover, required this.onCancel});
  final DownloadTask task;
  final Widget cover;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final t = task;
    final converting = t.status == DownloadStatus.converting;
    return ColoredBox(
      color: cs.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: .715,
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(10), child: cover),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _ConsoleDownloadsViewState._title(t.fileName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (t.totalBytes > 0)
                        FormatUtils.formatBytes(t.totalBytes),
                      t.statusDescription ?? '',
                    ].where((e) => e.isNotEmpty).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  _GlowBar(value: converting ? null : t.progress),
                  const SizedBox(height: 6),
                  Row(children: [
                    Text('${(t.progress * 100).round()} %',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const Spacer(),
                    if (t.speedBytesPerSec > 0)
                      Flexible(
                        child: Text(
                          [
                            FormatUtils.formatSpeed(t.speedBytesPerSec),
                            if (t.etaString != null) t.etaString!,
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.w800, color: cs.primary),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: Text(l10n.cancel),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.error,
                        visualDensity: VisualDensity.compact,
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Progress bar with a glow; indeterminate when [value] is null.
class _GlowBar extends StatelessWidget {
  const _GlowBar({required this.value});
  final double? value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 12,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF06B6D4).withValues(alpha: .35),
              blurRadius: 12),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value ?? 0),
          duration: const Duration(milliseconds: 600),
          builder: (_, v, __) => LinearProgressIndicator(
            value: value == null ? null : v,
            minHeight: 12,
            backgroundColor: cs.onSurface.withValues(alpha: .1),
            color: const Color(0xFF06B6D4),
          ),
        ),
      ),
    );
  }
}

class _Number extends StatelessWidget {
  const _Number(this.n);
  final int n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cs.surface,
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: Text('$n',
          style: TextStyle(
              fontWeight: FontWeight.w900, color: cs.onSurface, fontSize: 13)),
    );
  }
}

class _Band extends StatelessWidget {
  const _Band(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(8, 20, 8, 9),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xC0000000)]),
          ),
          child: Text(text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                  height: 1.15)),
        ),
      );
}
