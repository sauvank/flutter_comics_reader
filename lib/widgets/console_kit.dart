import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Shared pieces of the PC "console" pages (library, servers, downloads):
/// tiles that grow with a pulsing ring, pill buttons, key caps and covers.

/// Stable colour derived from a name (series, server).
Color consoleColor(String name, {double l = .5}) {
  var h = 0;
  for (final c in name.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return HSLColor.fromAHSL(1, (h % 360).toDouble(), .55, l).toColor();
}

class ConsoleAction {
  const ConsoleAction(this.label, this.run, {this.icon, this.primary = false});
  final String label;
  final VoidCallback run;
  final IconData? icon;
  final bool primary;
}

/// The mouse wheel scrolls a horizontal row.
Widget consoleWheel(ScrollController c, Widget child) => Listener(
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

/// Scrolls a row so the focused tile sits near the left edge.
void consoleScrollTo(ScrollController c, int index, double extent) {
  if (!c.hasClients) return;
  final viewport = c.position.viewportDimension;
  final anchor = viewport * .2 < extent * 1.6 ? viewport * .2 : extent * 1.6;
  final target =
      (index * extent - anchor).clamp(0.0, c.position.maxScrollExtent);
  c.animateTo(target,
      duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
}

/// Key hints shown at the bottom of a console page.
class ConsoleHints extends StatelessWidget {
  const ConsoleHints(this.hints, {super.key});
  final List<(List<String>, String)> hints;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 13);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 14),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 22,
          runSpacing: 6,
          children: [
            for (final (keys, label) in hints)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final k in keys) ...[
                    ConsoleKeyCap(k),
                    const SizedBox(width: 4)
                  ],
                  const SizedBox(width: 3),
                  Text(label, style: style),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Tinted background that follows the focused item colour.
class ConsoleBackdrop extends StatelessWidget {
  const ConsoleBackdrop({super.key, required this.color, required this.child});
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-.65, -1.15),
            radius: 1.25,
            colors: [color.withValues(alpha: .34), color.withValues(alpha: 0)],
          ),
        ),
        child: child,
      );
}

/// Upper-case section label ("EN COURS · 2").
class ConsoleLabel extends StatelessWidget {
  const ConsoleLabel(this.text, {super.key, this.trailing});
  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 10, 28, 0),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(
              text: text.toUpperCase(),
              style: const TextStyle(
                  fontWeight: FontWeight.w900, letterSpacing: 1)),
          if (trailing != null)
            TextSpan(
                text: '  $trailing',
                style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
        style: theme.textTheme.labelLarge?.copyWith(color: color),
      ),
    );
  }
}

class ConsoleTile extends StatelessWidget {
  const ConsoleTile({
    super.key,
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

class ConsoleCover extends StatelessWidget {
  const ConsoleCover(
      {super.key,
      required this.path,
      required this.title,
      required this.number});
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
    final c = consoleColor(title);
    final dark = consoleColor(title, l: .18);
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

class ConsoleChip extends StatelessWidget {
  const ConsoleChip(this.text, {super.key});
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

class ConsoleBadge extends StatelessWidget {
  const ConsoleBadge(this.icon, this.color, {super.key});
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

class ConsoleKeyCap extends StatelessWidget {
  const ConsoleKeyCap(this.label, {super.key});
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

class ConsolePill extends StatelessWidget {
  const ConsolePill({
    super.key,
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

class ConsoleActionButton extends StatelessWidget {
  const ConsoleActionButton(
      {super.key,
      required this.action,
      required this.focused,
      required this.onTap});
  final ConsoleAction action;
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
