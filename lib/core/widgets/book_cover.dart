import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../data/models/book.dart';
import '../design/tokens.dart';
import '../flags.dart';

/// Palette éditoriale stable, commune à la couverture de repli et au héros.
Color bookCoverColor(Book book) {
  const colors = [
    Color(0xFF253F55),
    Color(0xFF703B43),
    Color(0xFF38574D),
    Color(0xFF8A5038),
    Color(0xFF554263),
    Color(0xFF3C6468),
  ];
  final seed = book.isbn.codeUnits.fold(0, (a, b) => a + b);
  return colors[seed % colors.length];
}

/// Les vraies couvertures restent prioritaires. Hors ligne, une petite
/// édition illustrée est composée à la taille du livre, comme une image :
/// sa typographie imprimée ne dépend pas du réglage du texte de l'interface.
class BookCover extends StatelessWidget {
  const BookCover({super.key, required this.book, this.width = 84});
  final Book book;
  final double width;

  @override
  Widget build(BuildContext context) {
    final url = isRunningUnderFlutterTest ? null : book.coverUrl;
    final placeholder = _PrintedCover(book: book);
    return Semantics(
      image: true,
      label: 'Couverture de ${book.title}',
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ElaSpace.coverRadius),
            boxShadow: ElaShadows.cover(Colors.black),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ElaSpace.coverRadius),
            child: AspectRatio(
              aspectRatio: 2 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (url == null)
                    placeholder
                  else
                    CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => placeholder,
                      errorWidget: (_, __, ___) => placeholder,
                    ),
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            stops: [0, .025, .055, .10, .97, 1],
                            colors: [
                              Color(0x88000000),
                              Color(0x11000000),
                              Color(0x33FFFFFF),
                              Colors.transparent,
                              Colors.transparent,
                              Color(0x33000000),
                            ],
                          ),
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

class _PrintedCover extends StatelessWidget {
  const _PrintedCover({required this.book});
  final Book book;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.fill,
    child: SizedBox(
      width: 240,
      height: 360,
      child: CustomPaint(
        painter: _CoverArt(bookCoverColor(book), book.isbn),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(25, 25, 22, 18),
          child: Column(
            children: [
              _CoverText(
                book.author.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  fontFamily: ElaType.labelFamily,
                  fontSize: 10,
                  letterSpacing: 2,
                  color: Color(0xFFF3DEB4),
                ),
              ),
              const SizedBox(height: 19),
              SizedBox(
                height: 100,
                child: Center(
                  child: _CoverText(
                    book.title,
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: ElaType.titleFamily,
                      fontSize: 33,
                      height: 1.02,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFFF2D7),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              const _CoverText(
                'E L A  ·  B I B L I O T H È Q U E',
                style: TextStyle(
                  fontFamily: ElaType.labelFamily,
                  fontSize: 8,
                  color: Color(0xFFF3DEB4),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _CoverArt extends CustomPainter {
  const _CoverArt(this.color, this.isbn);
  final Color color;
  final String isbn;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, .3)!],
        ).createShader(rect),
    );
    final gold = Paint()
      ..color = const Color(0xFFDBBA7A).withValues(alpha: .65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .6;
    canvas.drawRect(const Rect.fromLTWH(15, 13, 212, 334), gold);
    final seed = isbn.codeUnits.fold(0, (a, b) => a + b);
    final rng = math.Random(seed);
    for (var i = 0; i < 65; i++) {
      final point = Offset(
        27 + rng.nextDouble() * 187,
        175 + rng.nextDouble() * 140,
      );
      canvas.drawCircle(
        point,
        i % 5 == 0 ? 1.4 : .55,
        gold..style = PaintingStyle.fill,
      );
    }
    final center = Offset(120, seed.isEven ? 237 : 249);
    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(center, 31 + i * 6, gold..style = PaintingStyle.stroke);
    }
    canvas.drawCircle(
      center,
      28,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE9C990), Color(0xFF9D7346)],
        ).createShader(Rect.fromCircle(center: center, radius: 28)),
    );
    for (var i = 0; i < 6; i++) {
      final y = 270.0 + i * 7;
      final path = Path()
        ..moveTo(16, y + 13)
        ..quadraticBezierTo(80, y - 23, 135, y + 4)
        ..quadraticBezierTo(187, y + 26, 226, y - 4);
      canvas.drawPath(path, gold..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(_CoverArt oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isbn != isbn;
}

class _CoverText extends StatelessWidget {
  const _CoverText(
    this.label, {
    required this.style,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });
  final String label;
  final TextStyle style;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;
  @override
  Widget build(BuildContext context) => RichText(
    text: TextSpan(text: label, style: style),
    textAlign: textAlign,
    maxLines: maxLines,
    overflow: overflow,
    textScaler: TextScaler.noScaling,
  );
}
