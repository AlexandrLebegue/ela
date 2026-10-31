import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../data/models/book.dart';
import '../flags.dart';

/// Couverture de livre, avec repli élégant (dégradé sépia + initiale)
/// si l'image est indisponible ou hors-ligne.
class BookCover extends StatelessWidget {
  const BookCover({super.key, required this.book, this.width = 84});

  final Book book;
  final double width;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = isRunningUnderFlutterTest ? null : book.coverUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: width,
        child: AspectRatio(
          aspectRatio: 2 / 3,
          child: url == null
              ? _placeholder(scheme)
              : CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (context, _) => _placeholder(scheme),
                  errorWidget: (context, _, __) => _placeholder(scheme),
                ),
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme scheme) {
    final initial = book.title.trim().isEmpty
        ? 'E'
        : book.title.trim()[0].toUpperCase();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.secondaryContainer],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontFamily: 'Lora',
            fontSize: width * 0.42,
            color: scheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
