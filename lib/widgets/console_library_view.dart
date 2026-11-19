import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/book_item.dart';
import '../models/series_item.dart';
import '../providers/library_provider.dart';

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

class _Action {
  const _Action(this.label, this.run, {this.icon, this.primary = false});
  final String label;
  final VoidCallback run;
  final IconData? icon;
  final bool primary;
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

  List<_Action> _actionsFor(SeriesItem s) {
    final next = s.nextToReadBook;
    final actions = <_Action>[];
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
      actions.add(_Action(
          label, () => widget.onOpenBook(s.isCompleted ? s.books.first : next),
          icon: Icons.play_arrow_rounded, primary: true));
    }
    actions.add(_Action(l10n.seeVolumes, () {
      setState(() {
        _row = _ConsoleRow.volumes;
        _vi = next == null ? 0 : s.books.indexOf(next);
      });
      _scrollTo(_volumeScroll, _vi, _vw);
    }));
    actions.add(_Action(l10n.openSeriesSheet, () => widget.onOpenSeries(s),
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

  /// The mouse wheel scrolls a horizontal row.
  Widget _wheel(ScrollController c, Widget child) => Listener(
        onPointerSignal: (e) {
          if (e is! PointerScrollEvent || !c.hasClients) return;
          final d = e.scrollDelta.dx.abs() > e.scrollDelta.dy.abs()
              ? e.scrollDelta.dx
              : e.scrollDelta.dy;
          GestureBinding.instance.pointerSignalResolver.register(e, (_) {
            c.jumpTo((c.offset + d).clamp(0.0, c.position.maxScrollExtent));
          });
        },
        child: child,
      );

  // ---------------------------------------------------------------- Build

  static Color seriesColor(String name, {double l = .5}) {
    var h = 0;
    for (final c in name.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return HSLColor.fromAHSL(1, (h % 360).toDouble(), .55, l).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = _current;
    _shownSeries = s?.name;
    final amb = s == null ? theme.colorScheme.primary : seriesColor(s.name);

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
          _KeyCap('Q'),
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
                    child: _Pill(
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
          _KeyCap('E'),
        ],
      ),
    );
  }

  Widget _buildSeriesRow(ThemeData theme) {
    final padV = _sh * .07 + 30;
    return SizedBox(
      height: _sh + padV * 2,
      child: _wheel(
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
                  child: _Tile(
                    width: _sw,
                    height: _sh,
                    focused: focused,
                    dimmed: _row == _ConsoleRow.volumes ||
                            _row == _ConsoleRow.actions
                        ? i != _si
                        : false,
                    pulse: _pulse,
                    pileColor:
                        s.totalBooks > 1 ? seriesColor(s.name, l: .38) : null,
                    pileCount: math.min(2, s.totalBooks - 1),
                    cover: _Cover(path: s.coverPath, title: s.name, number: 1),
                    bottomLeft: s.totalBooks > 1 && _sw >= 140
                        ? _Chip(l10n.volumeCountPlural(s.totalBooks))
                        : null,
                    badge: s.isCompleted
                        ? const _Badge(Icons.check_rounded, Color(0xFF0E9F6E))
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
                Text(
                  s.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.displaySmall
                      ?.copyWith(fontWeight: FontWeight.w900, height: 1.05),
                ),
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
                  child: _ActionButton(
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
          child: _wheel(
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
                      child: _Tile(
                        width: _vw,
                        height: _vh,
                        radius: 14,
                        focused: focused,
                        scale: 1.14,
                        pulse: _pulse,
                        cover: _Cover(
                            path: b.coverPath, title: s.name, number: i + 1),
                        badge: b.isCompleted
                            ? const _Badge(
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
            for (final k in keys) ...[_KeyCap(k), const SizedBox(width: 4)],
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

// ------------------------------------------------------------------ Pieces

class _Tile extends StatelessWidget {
  const _Tile({
    required this.width,
    required this.height,
    required this.focused,
    required this.pulse,
    required this.cover,
    this.radius = 18,
    this.scale = 1.12,
    this.dimmed = false,
    this.pileColor,
    this.pileCount = 0,
    this.bottomLeft,
    this.badge,
    this.progress = 0,
  });

  final double width, height, radius, scale;
  final bool focused, dimmed;
  final Animation<double> pulse;
  final Widget cover;
  final Color? pileColor;
  final int pileCount;
  final Widget? bottomLeft, badge;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const spring = Curves.easeOutBack;
    const d = Duration(milliseconds: 420);
    // Neighbours move aside so the enlarged tile never covers them.
    final grow = width * (scale - 1) / 2 + 10;
    return AnimatedPadding(
      duration: d,
      curve: spring,
      padding: EdgeInsets.symmetric(horizontal: focused ? 11 + grow : 11),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: dimmed ? .5 : 1,
        child: AnimatedScale(
          duration: d,
          curve: spring,
          scale: focused ? scale : 1,
          child: AnimatedSlide(
            duration: d,
            curve: spring,
            offset: Offset(0, focused ? -.03 : 0),
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Pile of volumes behind the cover, tucked away when focused.
                  if (pileColor != null)
                    for (var p = pileCount; p >= 1; p--)
                      Positioned.fill(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 220),
                          opacity: focused ? 0 : 1,
                          child: Transform.translate(
                            offset: Offset(0, -7.0 * p),
                            child: Transform.scale(
                              scale: 1 - .07 * p,
                              alignment: Alignment.topCenter,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Color.lerp(
                                      pileColor, Colors.black, .12 * (p - 1)),
                                  borderRadius: BorderRadius.circular(radius),
                                  border: Border(
                                      top: BorderSide(
                                          color: Colors.white
                                              .withValues(alpha: .3))),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: pulse,
                      builder: (context, child) {
                        final glow = focused ? 8 + 3 * pulse.value : 0.0;
                        return DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(radius),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: focused ? .32 : .2),
                                blurRadius: focused ? 30 : 18,
                                offset: Offset(0, focused ? 16 : 8),
                              ),
                              if (focused) ...[
                                BoxShadow(
                                    color: cs.primary.withValues(
                                        alpha: .95 - .35 * pulse.value),
                                    spreadRadius: glow),
                                const BoxShadow(
                                    color: Colors.white, spreadRadius: 4),
                              ],
                            ],
                          ),
                          child: child,
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(radius),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            cover,
                            if (badge != null)
                              Positioned(left: 8, top: 8, child: badge!),
                            if (bottomLeft != null)
                              Positioned(
                                  left: 10, bottom: 14, child: bottomLeft!),
                            if (progress > 0)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                height: 6,
                                child: ColoredBox(
                                  color: Colors.black38,
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: progress.clamp(0.0, 1.0),
                                    child: const ColoredBox(
                                        color: Color(0xFF22D3EE)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.path, required this.title, required this.number});
  final String? path;
  final String title;
  final int number;

  @override
  Widget build(BuildContext context) {
    final fallback = _placeholder();
    final p = path;
    if (p == null) return fallback;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Image.file(
      File(p),
      fit: BoxFit.cover,
      cacheWidth: (280 * dpr).round(),
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  Widget _placeholder() {
    final c = _ConsoleLibraryViewState.seriesColor(title);
    final dark = _ConsoleLibraryViewState.seriesColor(title, l: .18);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c, dark],
        ),
      ),
      // Sized from the tile so small volume tiles never overflow.
      child: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        final pad = w * .07;
        return Stack(
          children: [
            Positioned(
              left: pad,
              top: pad,
              right: pad,
              child: Text(title.toUpperCase(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: w * .09,
                      height: 1.05)),
            ),
            Positioned(
              right: pad,
              bottom: pad,
              child: Text(number.toString().padLeft(2, '0'),
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: w * .2,
                      height: 1)),
            ),
          ],
        );
      }),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xC70A0B22),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12)),
      );
}

class _Badge extends StatelessWidget {
  const _Badge(this.icon, this.color);
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)]),
        child: Icon(icon, size: 16, color: Colors.white),
      );
}

class _KeyCap extends StatelessWidget {
  const _KeyCap(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 24),
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(7),
        border: Border(bottom: BorderSide(color: cs.outlineVariant, width: 2)),
      ),
      child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.focused,
    required this.onTap,
  });
  final String label;
  final bool selected, focused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedScale(
      scale: focused ? 1.06 : 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      child: Material(
        color: selected ? cs.primary : Colors.transparent,
        shape: StadiumBorder(
            side: focused
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: selected ? cs.onPrimary : cs.onSurfaceVariant)),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(
      {required this.action, required this.focused, required this.onTap});
  final _Action action;
  final bool focused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = action.primary ? cs.primary : cs.surfaceContainerHigh;
    final fg = action.primary ? cs.onPrimary : cs.onSurface;
    return AnimatedScale(
      scale: focused ? 1.07 : 1,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          boxShadow: [
            if (focused) ...[
              BoxShadow(color: cs.primary, spreadRadius: 7),
              const BoxShadow(color: Colors.white, spreadRadius: 4),
            ],
          ],
        ),
        child: Material(
          color: bg,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (action.icon != null) ...[
                    Icon(action.icon, size: 20, color: fg),
                    const SizedBox(width: 8),
                  ],
                  Text(action.label,
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: fg)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
