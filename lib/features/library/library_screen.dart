import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/design/book_tile.dart';
import '../../core/widgets/book_cover.dart';
import '../../data/fake/demo_books.dart';
import '../../data/models/book.dart';
import '../../data/models/library_entry.dart';
import '../../providers.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});
  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  bool _shelf = false;
  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(libraryEntriesProvider);
    return BookScaffold(
      body: SafeArea(
        bottom: false,
        child: entries.when(
          loading: () => const BookNotice(
            title: 'Ouverture de votre bibliothèque…',
            loading: true,
          ),
          error: (_, __) => BookNotice(
            title: 'La bibliothèque se fait attendre',
            action: OutlinedButton(
              onPressed: () => ref.invalidate(libraryEntriesProvider),
              child: const Text('Réessayer'),
            ),
          ),
          data: (items) {
            final history =
                items.where((e) => e.section == LibrarySection.history).toList()
                  ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
            final pal =
                items.where((e) => e.section == LibrarySection.toRead).toList()
                  ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: ChapterHeader(
                    chapter: 'III',
                    title: 'Ma Bibliothèque',
                    subtitle: 'Les lectures d’hier. Les envies de demain.',
                    trailing: IconButton(
                      tooltip: 'Votre espace',
                      icon: const Icon(Icons.person_outline),
                      onPressed: () => context.push('/compte'),
                    ),
                  ),
                ),
                if (items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: BookNotice(
                      title: 'Votre étagère attend ses premiers livres.',
                      message:
                          'Scannez un code-barres ou ajoutez un livre à votre Pile à Lire.',
                      action: OutlinedButton.icon(
                        onPressed: () => context.go('/scanner'),
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scanner un livre'),
                      ),
                    ),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Liste'),
                            selected: !_shelf,
                            onSelected: (_) => setState(() => _shelf = false),
                          ),
                          ChoiceChip(
                            label: const Text('Étagère'),
                            selected: _shelf,
                            onSelected: (_) => setState(() => _shelf = true),
                          ),
                        ],
                      ),
                    ),
                  ),
                  for (final section in [
                    (history, 'Historique', 'Passif'),
                    (pal, 'Pile à Lire', 'Active'),
                  ])
                    if (section.$1.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              Text(
                                section.$2,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Chip(label: Text(section.$3)),
                              Text(
                                '${section.$1.length}',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_shelf)
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          sliver: SliverToBoxAdapter(
                            child: Wrap(
                              spacing: 16,
                              runSpacing: 24,
                              children: [
                                for (final e in section.$1)
                                  SizedBox(
                                    width:
                                        (MediaQuery.sizeOf(context).width -
                                            80) /
                                        3,
                                    child: _LibraryBook(entry: e, shelf: true),
                                  ),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          sliver: SliverList.builder(
                            itemCount: section.$1.length,
                            itemBuilder: (context, i) =>
                                _LibraryBook(entry: section.$1[i]),
                          ),
                        ),
                    ],
                  const SliverToBoxAdapter(child: Folio('03')),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LibraryBook extends ConsumerWidget {
  const _LibraryBook({required this.entry, this.shelf = false});
  final LibraryEntry entry;
  final bool shelf;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Book book =
        ref.watch(bookByIsbnProvider(entry.isbn)).value ??
        DemoData.byIsbnLookup(entry.isbn) ??
        Book(
          isbn: entry.isbn,
          title: 'Livre ${entry.isbn}',
          author: 'Auteur inconnu',
          genre: 'Autre',
          year: 2000,
          badge: PopularityBadge.trending,
          readersCount: 0,
        );
    void open() => context.push('/livre/${entry.isbn}');
    if (!shelf) {
      return BookTile(
        book: book,
        onTap: open,
        detail:
            '${entry.addedAt.day}/${entry.addedAt.month}/${entry.addedAt.year}',
      );
    }
    return InkWell(
      onTap: open,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BookCover(
            book: book,
            width: (MediaQuery.sizeOf(context).width - 80) / 3,
          ),
          const SizedBox(height: 8),
          const Divider(thickness: 3),
          Text(book.title, style: Theme.of(context).textTheme.titleSmall),
          Text(book.author, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
