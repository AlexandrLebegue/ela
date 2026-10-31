import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/animations.dart';
import '../../core/theme.dart';
import '../../core/design/book_tile.dart';
import '../../data/models/book.dart';
import '../../providers.dart';

final searchResultsProvider = FutureProvider.family<List<Book>, String>(
  (ref, query) => ref.watch(bookLookupServiceProvider).search(query),
);

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _changed(String value) {
    _debounce?.cancel();
    setState(() {});
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = _query.isEmpty
        ? null
        : ref.watch(searchResultsProvider(_query));
    return BookScaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            const SliverToBoxAdapter(
              child: ChapterHeader(
                chapter: 'IV',
                title: 'Recherche',
                subtitle: 'Un titre en tête, un auteur à retrouver.',
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  controller: _controller,
                  onChanged: _changed,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (v) {
                    _debounce?.cancel();
                    setState(() => _query = v.trim());
                    FocusScope.of(context).unfocus();
                  },
                  decoration: InputDecoration(
                    labelText: 'Titre, auteur, ou ISBN…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _controller.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Effacer la recherche',
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
            ),
            if (results == null)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: BookNotice(
                  title: 'Toutes les histoires commencent ici.',
                  message:
                      'Cherchez parmi les 18 livres du catalogue — ou saisissez un ISBN pour retrouver sa fiche.',
                ),
              )
            else
              ...results.when(
                data: (items) => items.isEmpty
                    ? [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: BookNotice(
                            title: 'Aucun résultat pour « $_query ».',
                            message:
                                'Essayez un autre titre, un auteur ou un ISBN.',
                          ),
                        ),
                      ]
                    : [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              '${items.length} livre${items.length > 1 ? 's' : ''} à découvrir',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          sliver: SliverList.builder(
                            itemCount: items.length,
                            itemBuilder: (context, i) => StaggeredReveal(
                              index: i,
                              child: BookTile(
                                book: items[i],
                                onTap: () =>
                                    context.push('/livre/${items[i].isbn}'),
                                detail:
                                    '${items[i].year} · ISBN ${items[i].isbn}\n${items[i].badgeLabel}',
                              ),
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: Folio('04')),
                      ],
                loading: () => [
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: BookNotice(
                      title: 'À la recherche de votre livre…',
                      loading: true,
                    ),
                  ),
                ],
                error: (_, __) => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: BookNotice(
                      title: 'La recherche a été interrompue',
                      message:
                          'Vos mots sont conservés. Vous pouvez réessayer.',
                      action: OutlinedButton(
                        onPressed: () =>
                            ref.invalidate(searchResultsProvider(_query)),
                        child: const Text('Réessayer'),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
