import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../animations.dart';

/// Papier immobile, grain calculé une fois par taille/couleur, isolé des
/// animations de contenu par une frontière de rendu.
class BookScaffold extends StatelessWidget {
  const BookScaffold({
    super.key,
    this.appBar,
    this.body,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
  });
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: PaperPainter(scheme.surface, scheme.onSurface),
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: appBar,
          body: body,
          bottomNavigationBar: bottomNavigationBar,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        ),
      ],
    );
  }
}

class PaperPainter extends CustomPainter {
  const PaperPainter(this.paper, this.ink);
  final Color paper;
  final Color ink;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(paper, BlendMode.src);
    final random = math.Random(42);
    final grain = Paint()..color = ink.withValues(alpha: .035);
    for (var i = 0; i < size.width * size.height / 170; i++) {
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        .35,
        grain,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 5, size.height),
      Paint()..color = ink.withValues(alpha: .025),
    );
  }

  @override
  bool shouldRepaint(PaperPainter old) => old.paper != paper || old.ink != ink;
}

class ChapterHeader extends StatelessWidget {
  const ChapterHeader({
    super.key,
    required this.chapter,
    required this.title,
    this.subtitle,
    this.trailing,
  });
  final String chapter;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'CHAPITRE $chapter  ·  ELA',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 2,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          Semantics(
            header: true,
            child: Text(title, style: theme.textTheme.headlineLarge),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class Bookplate extends StatelessWidget {
  const Bookplate({
    super.key,
    this.size = 104,
    this.icon = Icons.menu_book_outlined,
  });
  final double size;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(border: Border.all(color: scheme.primary)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: scheme.primary.withValues(alpha: .45)),
        ),
        child: Icon(icon, size: size * .38, color: scheme.primary),
      ),
    );
  }
}

class Folio extends StatelessWidget {
  const Folio(this.number, {super.key});
  final String number;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(width: 28, child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '❦  $number',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        const SizedBox(width: 28, child: Divider()),
      ],
    ),
  );
}

class BookNotice extends StatelessWidget {
  const BookNotice({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.auto_stories_outlined,
    this.action,
    this.loading = false,
  });
  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;
  final bool loading;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Bookplate(size: 72, icon: icon),
            const SizedBox(height: 24),
            if (loading)
              BreathingText(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              )
            else
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            if (message != null) ...[
              const SizedBox(height: 12),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (action != null) ...[const SizedBox(height: 24), action!],
            const Folio('·'),
          ],
        ),
      ),
    ),
  );
}

class DropCapText extends StatelessWidget {
  const DropCapText(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: text.characters.first,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          TextSpan(text: text.substring(text.characters.first.length)),
        ],
      ),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7),
    );
  }
}
