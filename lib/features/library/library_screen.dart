import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/book_cover.dart';
import '../../data/fake/demo_books.dart';
import '../../data/models/book.dart';
import '../../data/models/library_entry.dart';
import '../../providers.dart';

/// Écran « Ma Bibliothèque » : Historique (passif) + Pile à Lire (active).
/// Persistance locale, sans compte.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: StreamBuilder<List<LibraryEntry>>(
        stream: ref.read(libraryServiceProvider).watchEntries(),
        builder: (context, snapshot) {
          final entries = snapshot.data ?? const <LibraryEntry>[];
          final history = entries
              .where((e) => e.section == LibrarySection.history)
              .toList();
          final toRead = entries
              .where((e) => e.section == LibrarySection.toRead)
              .toList();
          final isEmpty = history.isEmpty && toRead.isEmpty;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ma Bibliothèque',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontFamily: 'Lora',
                              fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Votre étagère : ce que vous avez lu, et ce qui attend.',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isEmpty
                    ? const _LibraryEmpty()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        children: [
                          if (history.isNotEmpty) ...[
                            _SectionTitle(
                              icon: Icons.history,
                              label: 'Historique',
                              hint: 'Ce que vous avez scanné ou consulté',
                            ),
                            for (final e in history)
                              _LibraryRow(
                                isbn: e.isbn,
                                date: e.addedAt,
                                section: e.section,
                                onTap: () => context.go('/livre/${e.isbn}'),
                              ),
                          ],
                          if (toRead.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _SectionTitle(
                              icon: Icons.bookmark,
                              label: 'Pile à Lire',
                              hint: 'Vos livres en attente, du plus récent',
                            ),
                            for (final e in toRead)
                              _LibraryRow(
                                isbn: e.isbn,
                                date: e.addedAt,
                                section: e.section,
                                onTap: () => context.go('/livre/${e.isbn}'),
                              ),
                          ],
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.label,
    required this.hint,
  });

  final IconData icon;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hint,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryRow extends StatelessWidget {
  const _LibraryRow({
    required this.isbn,
    required this.date,
    required this.section,
    required this.onTap,
  });

  final String isbn;
  final DateTime date;
  final LibrarySection section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final book = DemoData.byIsbnLookup(isbn) ??
        Book(
          isbn: isbn,
          title: 'Livre ${isbn.substring(0, isbn.length > 5 ? 5 : isbn.length)}',
          author: 'Auteur inconnu',
          genre: 'Autre',
          year: 2000,
          badge: PopularityBadge.trending,
          readersCount: 0,
        );
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              BookCover(book: book, width: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _shortDate(date),
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _shortDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}

class _LibraryEmpty extends StatelessWidget {
  const _LibraryEmpty();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_stories_outlined,
                size: 56, color: scheme.outline),
            const SizedBox(height: 16),
            Text(
              'Votre étagère attend ses premiers livres.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Lora',
                fontSize: 18,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scannez un code-barres ou ajoutez un livre à votre Pile à Lire.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
