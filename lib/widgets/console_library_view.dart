import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/book_item.dart';
import '../models/series_item.dart';
import '../providers/library_provider.dart';
import 'console_kit.dart';

enum _ConsoleRow { tabs, series, actions, volumes }

/// "Console" library view for large windows: a row of series covers, the
/// focused series sheet and a row of its volumes, driven by mouse or keyboard
/// (arrows, Enter, Escape, Q/E for the filter tabs).
class ConsoleLibraryView extends StatefulWidget {
  const ConsoleLibraryView({
    super.key,
    required this.series,
    required this.filter,
    required this.onFilter,
    required this.onOpenBook,
    required this.onOpenSeries,
  });

  final List<SeriesItem> series;
  final LibraryFilter filter;
  final ValueChanged<LibraryFilter> onFilter;
  final ValueChanged<BookItem> onOpenBook;
  final ValueChanged<SeriesItem> onOpenSeries;

  static const filters = [
    LibraryFilter.all,
    LibraryFilter.inProgress,
    LibraryFilter.unread,
    LibraryFilter.favorites,
    LibraryFilter.completed,
  ];

  @override
  State<ConsoleLibraryView> createState() => _ConsoleLibraryViewState();
}

class _ConsoleLibraryViewState extends State<ConsoleLibraryView>
    with SingleTickerProviderStateMixin {
  static const _move = Duration(milliseconds: 420);
  static const _gap = 22.0;

  final _focus = FocusNode(debugLabel: 'console-library');
  final _seriesScroll = ScrollController();
  final _volumeScroll = ScrollController();
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  _ConsoleRow _row = _ConsoleRow.series;
  int _si = 0;
  int _vi = 0;
  int _ai = 0;
  String? _shownSeries;

  // Tile sizes, recomputed from the available height.
  double _sw = 196, _sh = 274, _vw = 118, _vh = 165;

  SeriesItem? get _current => widget.series.isEmpty ? null : widget.series[_si];

  @override
  void didUpdateWidget(covariant ConsoleLibraryView old) {
    super.didUpdateWidget(old);
    if (widget.series.isEmpty) {
      _si = 0;
      return;
    }
    // Keep the same series focused when the list is rebuilt.
    final keep = widget.series.indexWhere((s) => s.name == _shownSeries);
    _si = keep >= 0 ? keep : math.min(_si, widget.series.length - 1);
    final cur = widget.series[_si];
    _vi = math.min(_vi, math.max(0, cur.books.length - 1));
  }

  @override
  void dispose() {
    _pulse.dispose();
    _focus.dispose();
    _seriesScroll.dispose();
    _volumeScroll.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- Actions

  int _numberOf(SeriesItem s, BookItem b) => s.books.indexOf(b) + 1;

  List<ConsoleAction> _actionsFor(SeriesItem s) {
    final next = s.nextToReadBook;
    final actions = <ConsoleAction>[];
    if (next != null) {
      final n = _numberOf(s, next);
      final String label;
      if (s.isCompleted) {
        label = l10n.readAgain;
      } else if (next.progress > 0) {
        label = l10n.resumeVolumeNumber(n);
      } else if (s.completedBooks > 0) {
        label = l10n.readVolumeNumber(n);
      } else {
        label = l10n.startReading;
      }
      actions.add(ConsoleAction(
          label, () => widget.onOpenBook(s.isCompleted ? s.books.first : next),
          icon: Icons.play_arrow_rounded, primary: true));
    }
    actions.add(ConsoleAction(l10n.seeVolumes, () {
      setState(() {
        _row = _ConsoleRow.volumes;
        _vi = next == null ? 0 : s.books.indexOf(next);
      });
      _scrollTo(_volumeScroll, _vi, _vw);
    }));
    actions.add(ConsoleAction(
        l10n.openSeriesSheet, () => widget.onOpenSeries(s),
        icon: Icons.folder_open_rounded));
    return actions;
  }

  void _activate() {
    final s = _current;
    switch (_row) {
      case _ConsoleRow.tabs:
        setState(() => _row = _ConsoleRow.series);
      case _ConsoleRow.series:
        if (s != null) {
          setState(() {
            _row = _ConsoleRow.actions;
            _ai = 0;
          });
        }
      case _ConsoleRow.actions:
        if (s != null) _actionsFor(s)[_ai].run();
      case _ConsoleRow.volumes:
        if (s != null && s.books.isNotEmpty) widget.onOpenBook(s.books[_vi]);
    }
  }

  bool _back() {
    if (_row == _ConsoleRow.series) return false;
    setState(() => _row = _ConsoleRow.series);
    return true;
  }

  void _cycleFilter(int d) {
    const f = ConsoleLibraryView.filters;
    final i = f.indexOf(widget.filter);
    widget.onFilter(f[(i + d + f.length) % f.length]);
    setState(() {
      _si = 0;
      _vi = 0;
    });
    if (_seriesScroll.hasClients) _seriesScroll.jumpTo(0);
  }

  void _moveFocus(int dx, int dy) {
    final s = _current;
    if (dy == 0 && _row == _ConsoleRow.tabs) {
      _cycleFilter(dx);
      return;
    }
    setState(() {
      if (dy != 0) {
        final order = _ConsoleRow.values;
        final i = (order.indexOf(_row) + dy).clamp(0, order.length - 1).toInt();
        if (s != null || order[i] == _ConsoleRow.tabs) _row = order[i];
        return;
      }
      switch (_row) {
        case _ConsoleRow.tabs:
          break;
        case _ConsoleRow.series:
          final n = (_si + dx)
              .clamp(0, math.max(0, widget.series.length - 1))
              .toInt();
          if (n != _si) {
            _si = n;
            _vi = 0;
            if (_volumeScroll.hasClients) _volumeScroll.jumpTo(0);
          }
        case _ConsoleRow.actions:
          if (s != null) {
            _ai = (_ai + dx).clamp(0, _actionsFor(s).length - 1).toInt();
          }
        case _ConsoleRow.volumes:
          if (s != null) _vi = (_vi + dx).clamp(0, s.books.length - 1).toInt();
      }
    });
    if (_row == _ConsoleRow.series) _scrollTo(_seriesScroll, _si, _sw);
    if (_row == _ConsoleRow.volumes) _scrollTo(_volumeScroll, _vi, _vw);
  }

  /// Keeps the focused tile near the left edge with a neighbour visible.
  void _scrollTo(ScrollController c, int index, double tileWidth) {
    if (!c.hasClients) return;
    final extent = tileWidth + _gap;
    final viewport = c.position.viewportDimension;
    final anchor = math.min(viewport * .2, extent * 1.6);
    final target =
        (index * extent - anchor).clamp(0.0, c.position.maxScrollExtent);
    c.animateTo(target, duration: _move, curve: Curves.easeOutCubic);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.arrowLeft) {
      _moveFocus(-1, 0);
    } else if (k == LogicalKeyboardKey.arrowRight) {
      _moveFocus(1, 0);
    } else if (k == LogicalKeyboardKey.arrowUp) {
      _moveFocus(0, -1);
    } else if (k == LogicalKeyboardKey.arrowDown) {
      _moveFocus(0, 1);
    } else if (k == LogicalKeyboardKey.enter ||
        k == LogicalKeyboardKey.numpadEnter ||
        k == LogicalKeyboardKey.space) {
      if (e is KeyRepeatEvent) return KeyEventResult.handled;
      _activate();
    } else if (k == LogicalKeyboardKey.escape ||
        k == LogicalKeyboardKey.backspace) {
      return _back() ? KeyEventResult.handled : KeyEventResult.ignored;
    } else if (k == LogicalKeyboardKey.keyQ) {
      _cycleFilter(-1);
    } else if (k == LogicalKeyboardKey.keyE) {
      _cycleFilter(1);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  // ---------------------------------------------------------------- Build

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = _current;
    _shownSeries = s?.name;
    final amb = s == null ? theme.colorScheme.primary : consoleColor(s.name);

    return LayoutBuilder(builder: (context, box) {
      final h = box.maxHeight;
      // Height left for the two rows once tabs, hints, the series sheet and
      // the row paddings are taken; volumes are 60 % of the series height.
      final rest = h - 330;
      _sh = ((rest - 104) / 1.836).clamp(140.0, 274.0);
      _sw = _sh * .715;
      _vh = (_sh * .6).clamp(90.0, 165.0);
      _vw = _vh * .715;

      return Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (_) => _focus.requestFocus(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-.65, -1.15),
                radius: 1.25,
                colors: [
                  amb.withValues(alpha: .34),
                  amb.withValues(alpha: 0),
                ],
              ),
            ),
            child: Column(
              children: [
                _buildTabs(theme),
                Expanded(
                  child: s == null
                      ? Center(
                          child: Text(l10n.consoleEmpty,
                              style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                        )
                      // Very short windows: shrink everything instead of
                      // overflowing.
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: box.maxWidth,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildSeriesRow(theme),
                                _buildInfo(theme, s),
                                _buildVolumesRow(theme, s),
                              ],
                            ),
                          ),
                        ),
                ),
                _buildHints(theme),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTabs(ThemeData theme) {
    final cs = theme.colorScheme;
    final labels = {
      LibraryFilter.all: l10n.all,
      LibraryFilter.inProgress: l10n.inProgress,
      LibraryFilter.unread: l10n.unread,
      LibraryFilter.favorites: l10n.favorites,
      LibraryFilter.completed: l10n.finished,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 6, 28, 0),
      child: Row(
        children: [
          ConsoleKeyCap('Q'),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh.withValues(alpha: .8),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              children: [
                for (final f in ConsoleLibraryView.filters)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: ConsolePill(
                      label: labels[f]!,
                      selected: widget.filter == f,
                      focused: _row == _ConsoleRow.tabs && widget.filter == f,
                      onTap: () {
                        widget.onFilter(f);
                        setState(() => _si = 0);
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ConsoleKeyCap('E'),
        ],
      ),
    );
  }

  Widget _buildSeriesRow(ThemeData theme) {
    final padV = _sh * .07 + 30;
    return SizedBox(
      height: _sh + padV * 2,
      child: consoleWheel(
        _seriesScroll,
        ListView.builder(
          controller: _seriesScroll,
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.hardEdge,
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: padV),
          itemCount: widget.series.length,
          itemBuilder: (context, i) {
            final s = widget.series[i];
            final focused = _row == _ConsoleRow.series && i == _si;
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) {
                if (_row != _ConsoleRow.series || _si != i) {
                  setState(() {
                    _row = _ConsoleRow.series;
                    _si = i;
                    _vi = 0;
                  });
                  if (_volumeScroll.hasClients) _volumeScroll.jumpTo(0);
                }
              },
              child: GestureDetector(
                onTap: () {
                  _focus.requestFocus();
                  setState(() {
                    _si = i;
                    _row = _ConsoleRow.actions;
                    _ai = 0;
                  });
                },
                child: Semantics(
                  button: true,
                  selected: i == _si,
                  label:
                      '${s.name}, ${l10n.volumeCountPlural(s.totalBooks)}, ${l10n.readOfTotal(s.completedBooks, s.totalBooks)}',
                  child: ConsoleTile(
                    width: _sw,
                    height: _sh,
                    focused: focused,
                    dimmed: _row == _ConsoleRow.volumes ||
                            _row == _ConsoleRow.actions
                        ? i != _si
                        : false,
                    pulse: _pulse,
                    pileColor:
                        s.totalBooks > 1 ? consoleColor(s.name, l: .38) : null,
                    pileCount: math.min(2, s.totalBooks - 1),
                    cover: ConsoleCover(
                        path: s.coverPath, title: s.name, number: 1),
                    bottomLeft: s.totalBooks > 1 && _sw >= 140
                        ? ConsoleChip(l10n.volumeCountPlural(s.totalBooks))
                        : null,
                    badge: s.isCompleted
                        ? const ConsoleBadge(
                            Icons.check_rounded, Color(0xFF0E9F6E))
                        : null,
                    progress: s.isCompleted ? 0 : s.overallProgress,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfo(ThemeData theme, SeriesItem s) {
    final cs = theme.colorScheme;
    final actions = _actionsFor(s);
    _ai = math.min(_ai, actions.length - 1);
    final chips = [
      l10n.volumeCountPlural(s.totalBooks),
      l10n.readOfTotal(s.completedBooks, s.totalBooks),
      if (s.inProgressBooks > 0) '${l10n.inProgress} · ${s.inProgressBooks}',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 6),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.end,
        runSpacing: 12,
        spacing: 24,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Always two lines tall, text at the bottom: the page no
                // longer jumps when a title takes one or two lines.
                Builder(builder: (context) {
                  final style = theme.textTheme.displaySmall
                      ?.copyWith(fontWeight: FontWeight.w900, height: 1.05);
                  final line = MediaQuery.textScalerOf(context)
                          .scale(style?.fontSize ?? 36) *
                      1.05;
                  return SizedBox(
                    height: line * 2 + 4,
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        s.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: style,
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 6, children: [
                  for (final c in chips)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh.withValues(alpha: .85),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(c,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  width: 360,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: s.overallProgress),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => LinearProgressIndicator(
                          value: v,
                          minHeight: 9,
                          backgroundColor: cs.onSurface.withValues(alpha: .1)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              for (var i = 0; i < actions.length; i++)
                MouseRegion(
                  onEnter: (_) => setState(() {
                    _row = _ConsoleRow.actions;
                    _ai = i;
                  }),
                  child: ConsoleActionButton(
                    action: actions[i],
                    focused: _row == _ConsoleRow.actions && _ai == i,
                    onTap: () {
                      _focus.requestFocus();
                      actions[i].run();
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVolumesRow(ThemeData theme, SeriesItem s) {
    final padV = _vh * .08 + 22;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 10, 28, 0),
          child: Text(
            l10n.volumesCount(s.totalBooks).toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        SizedBox(
          height: _vh + padV * 2,
          child: consoleWheel(
            _volumeScroll,
            ListView.builder(
              key: PageStorageKey('console-volumes-${s.name}'),
              controller: _volumeScroll,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 28, vertical: padV),
              itemCount: s.books.length,
              itemBuilder: (context, i) {
                final b = s.books[i];
                final focused = _row == _ConsoleRow.volumes && i == _vi;
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) {
                    if (_row != _ConsoleRow.volumes || _vi != i) {
                      setState(() {
                        _row = _ConsoleRow.volumes;
                        _vi = i;
                      });
                    }
                  },
                  child: GestureDetector(
                    onTap: () {
                      _focus.requestFocus();
                      widget.onOpenBook(b);
                    },
                    child: Semantics(
                      button: true,
                      label: '${b.title}, ${(b.progress * 100).round()} %',
                      child: ConsoleTile(
                        width: _vw,
                        height: _vh,
                        radius: 14,
                        focused: focused,
                        scale: 1.14,
                        pulse: _pulse,
                        cover: ConsoleCover(
                            path: b.coverPath, title: s.name, number: i + 1),
                        badge: b.isCompleted
                            ? const ConsoleBadge(
                                Icons.check_rounded, Color(0xFF0E9F6E))
                            : null,
                        progress: b.isCompleted ? 0 : b.progress,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHints(ThemeData theme) {
    final style = TextStyle(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurfaceVariant,
        fontSize: 13);
    Widget hint(List<String> keys, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final k in keys) ...[
              ConsoleKeyCap(k),
              const SizedBox(width: 4)
            ],
            const SizedBox(width: 3),
            Text(label, style: style),
          ],
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 14),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 22,
          runSpacing: 6,
          children: [
            hint(['←', '→', '↑', '↓'], l10n.consoleHintMove),
            hint(['↵'], l10n.consoleHintOpen),
            hint(['Esc'], l10n.consoleHintBack),
            hint(['Q', 'E'], l10n.consoleHintFilter),
          ],
        ),
      ),
    );
  }
}
