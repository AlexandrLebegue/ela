import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../data/models/book.dart';
import '../design/tokens.dart';
import '../flags.dart';

/// Une couverture et son dos. Les captures utilisent le véritable repli
/// hors ligne, sans téléchargement ni police de substitution.
class BookCover extends StatelessWidget {
  const BookCover({super.key, required this.book, this.width = 84});
  final Book book;
  final double width;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = isRunningUnderFlutterTest ? null : book.coverUrl;
    final initial = book.title.trim().isEmpty
        ? 'E'
        : book.title.trim().characters.first.toUpperCase();
    final placeholder = Container(
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        border: Border.all(color: scheme.primary.withValues(alpha: .25)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'ELA',
            style: TextStyle(
              fontFamily: ElaType.labelFamily,
              fontSize: width * .10,
              letterSpacing: width * .025,
              color: scheme.onPrimaryContainer,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: width * .20,
              vertical: width * .10,
            ),
            child: Divider(
              height: 1,
              color: scheme.primary.withValues(alpha: .4),
            ),
          ),
          Text(
            initial,
            style: TextStyle(
              fontFamily: ElaType.titleFamily,
              fontSize: width * .47,
              height: 1,
              color: scheme.onPrimaryContainer,
            ),
          ),
          SizedBox(height: width * .1),
          Text(
            '❦',
            style: TextStyle(
              fontSize: width * .16,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
    return Semantics(
      image: true,
      label: 'Couverture de ${book.title}',
      excludeSemantics: true,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ElaSpace.coverRadius),
          boxShadow: ElaShadows.cover(scheme.onSurface),
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
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: width * .10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          scheme.onSurface.withValues(alpha: .20),
                          Colors.transparent,
                          scheme.surface.withValues(alpha: .15),
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
    );
  }
}
