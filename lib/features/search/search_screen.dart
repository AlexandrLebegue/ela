import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animations.dart';
import '../../core/format.dart';
import '../../core/widgets/book_cover.dart';
import '../../data/models/book.dart';
import '../../providers.dart';

/// Écran « Recherche » : titre, auteur ou ISBN.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      _debounce?.cancel();
      final q = _controller.text.trim();
      _debounce = Timer(const Duration(milliseconds: 350), () {
        if (q != _query) setState(() => _query = q);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final query = _query;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Recherche',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontFamily: 'Lora', fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Titre, auteur, ou ISBN…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: query.isEmpty
                      ? null
                        : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _controller.clear();
                            _debounce?.cancel();
                            setState(() => _query = '');
                          },
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              // Chaque nouvelle requête fait fondre les résultats
              // précédents ; chaque ligne apparaît en cascade.
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: query.isEmpty
                    ? const _SearchHint(key: ValueKey('hint'))
                    : _SearchResults(
                        key: ValueKey('q-$query'),
                        query: query,
                        onSearch: _searchFuture,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Book>> _searchFuture(String query) =>
      ref.read(bookLookupServiceProvider).search(query);
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({
    super.key,
    required this.query,
    required this.onSearch,
  });

  final String query;
  final Future<List<Book>> Function(String query) onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Book>>(
      future: onSearch(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _SearchLoading();
        }
        final results = snapshot.data ?? const <Book>[];
        if (results.isEmpty) {
          return _SearchNoResult(query: query);
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          itemCount: results.length,
          itemBuilder: (context, i) => StaggeredReveal(
            index: i,
            child: _ResultRow(
              key: ValueKey('res-$query-${results[i].isbn}'),
              book: results[i],
              onTap: () => context.go('/livre/${results[i].isbn}'),
            ),
          ),
        );
      },
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({super.key, required this.book, required this.onTap});

  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
                      '${book.author} · ${book.year}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ISBN ${book.isbn} · ${book.badgeLabel}',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchHint extends StatelessWidget {
  const _SearchHint({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Cherchez parmi les ${formatInt(18)} livres du catalogue —\nou '
          'saisissez un ISBN pour ouvrir sa fiche directement.',
          textAlign: TextAlign.center,
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
        ),
      ),
    );
  }
}

class _SearchNoResult extends StatelessWidget {
  const _SearchNoResult({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Aucun résultat pour « $query ».',
          textAlign: TextAlign.center,
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
        ),
      ),
    );
  }
}

class _SearchLoading extends StatelessWidget {
  const _SearchLoading();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      itemCount: 4,
      itemBuilder: (context, _) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 76,
        decoration: BoxDecoration(
          color: scheme.outline.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
