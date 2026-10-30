import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Texte qui « respire » pendant le travail de curation IA.
/// Oscillation lente de l'opacité, sans spinner.
class BreathingText extends StatefulWidget {
  const BreathingText(
    this.text, {
    super.key,
    this.style,
    this.minOpacity = 0.35,
    this.period = const Duration(milliseconds: 1800),
  });

  final String text;
  final TextStyle? style;
  final double minOpacity;
  final Duration period;

  @override
  State<BreathingText> createState() => _BreathingTextState();
}

class _BreathingTextState extends State<BreathingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = widget.style ??
        TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 15,
          fontStyle: FontStyle.italic,
        );
    return FadeTransition(
      opacity: Tween<double>(
        begin: widget.minOpacity,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      )),
      child: Text(widget.text, style: style),
    );
  }
}

/// Squelette doux (blocs « encre ») pendant le chargement.
class InkSkeletonBlock extends StatefulWidget {
  const InkSkeletonBlock({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.borderRadius = 8,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<InkSkeletonBlock> createState() => _InkSkeletonBlockState();
}

class _InkSkeletonBlockState extends State<InkSkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = 0.5 + 0.5 * math.sin(_controller.value * math.pi);
        final base = scheme.outline.withValues(alpha: 0.25);
        final bright = scheme.outline.withValues(alpha: 0.55);
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(base, bright, t) ?? base,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// Fondu doux entre deux widgets (transitions d'onglets).
class SoftCrossFade extends StatelessWidget {
  const SoftCrossFade({
    super.key,
    required this.firstChild,
    required this.secondChild,
    required this.showSecond,
    this.duration = const Duration(milliseconds: 420),
  });

  final Widget firstChild;
  final Widget secondChild;
  final bool showSecond;
  final Duration duration;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: duration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: showSecond ? secondChild : firstChild,
      );
}
