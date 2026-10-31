import 'package:flutter/material.dart';
import '../../data/models/book.dart';
import '../widgets/book_cover.dart';
import 'tokens.dart';
import 'components.dart';

class BookTile extends StatelessWidget {
  const BookTile({
    super.key,
    required this.book,
    required this.onTap,
    this.rank,
    this.detail,
    this.trailing,
  });
  final Book book;
  final VoidCallback onTap;
  final int? rank;
  final String? detail;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PageCard(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ElaSpace.radius),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (rank != null) ...[
                  SizedBox(
                    width: 28,
                    child: Text(
                      'N°$rank',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: rank! <= 3
                            ? theme.colorScheme.secondary
                            : theme.colorScheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                BookCover(book: book, width: 52),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(book.title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        book.author,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (detail != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          detail!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (trailing != null) ...[
                        const SizedBox(height: 8),
                        trailing!,
                      ],
                    ],
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
