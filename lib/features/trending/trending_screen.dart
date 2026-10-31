import '../ratings/rating_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/animations.dart';
import '../../core/theme.dart';
import '../../core/widgets/book_cover.dart';
import '../../data/models/book.dart';
import '../../providers.dart';
import 'featured_carousel.dart';

class _SelectedCategoryNotifier extends Notifier<String?> {
  @override
  String? build() => 'Tous';
  void select(String category) => state = category;
}

final selectedCategoryProvider =
    NotifierProvider<_SelectedCategoryNotifier, String?>(
      _SelectedCategoryNotifier.new,
    );

class TrendingScreen extends ConsumerStatefulWidget {
  const TrendingScreen({super.key});
  @override
  ConsumerState<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends ConsumerState<TrendingScreen> {
  final _scroll = ScrollController();
  bool _heroVisible = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_visibility);
  }

  void _visibility() {
    final visible = _scroll.offset < 400;
    if (visible != _heroVisible) setState(() => _heroVisible = visible);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedCategoryProvider);
    final theme = Theme.of(context);
    final books = ref.watch(trendingProvider(selected));
    return BookScaffold(
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: CustomScrollView(
              key: const PageStorageKey('trending-scroll'),
              controller: _scroll,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ELA  /  LE GOÛT DES PAGES',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  letterSpacing: 2,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Semantics(
                                header: true,
                                child: Text(
                                  'Tendance',
                                  style: theme.textTheme.headlineLarge
                                      ?.copyWith(fontSize: 42, height: 1.1),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Votre prochaine histoire commence ici.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: theme.brightness == Brightness.dark
                              ? 'Lire de jour'
                              : 'Lire de nuit',
                          icon: Icon(
                            theme.brightness == Brightness.dark
                                ? Icons.light_mode_outlined
                                : Icons.dark_mode_outlined,
                          ),
                          onPressed: () =>
                              ref.read(themeModeProvider.notifier).toggle(),
                        ),
                      ],
                    ),
                  ),
                ),
                ...books.when(
                  data: (items) => items.isEmpty
                      ? [
                          const SliverToBoxAdapter(
                            child: BookNotice(
                              title: 'Une page encore blanche',
                              message:
                                  'Rien ne bouge encore dans cette catégorie.',
                            ),
                          ),
                        ]
                      : [
                          SliverToBoxAdapter(
                            child: StaggeredReveal(
                              index: 0,
                              child: AnimatedBuilder(
                                animation: _scroll,
                                child: FeaturedCarousel(
                                  key: ValueKey(selected),
                                  books: items.take(5).toList(),
                                  visible: _heroVisible,
                                ),
                                builder: (context, child) =>
                                    Transform.translate(
                                      offset: Offset(
                                        0,
                                        MediaQuery.disableAnimationsOf(
                                                  context,
                                                ) ||
                                                !_scroll.hasClients
                                            ? 0
                                            : _scroll.offset.clamp(0, 400) *
                                                  .025,
                                      ),
                                      child: child,
                                    ),
                              ),
                            ),
                          ),
                        ],
                  loading: () => [
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          children: [
                            InkSkeletonBlock(width: 230, height: 345),
                            SizedBox(height: 24),
                            InkSkeletonBlock(width: 200, height: 26),
                            SizedBox(height: 16),
                            InkSkeletonBlock(width: 160),
                          ],
                        ),
                      ),
                    ),
                  ],
                  error: (_, __) => [
                    SliverToBoxAdapter(
                      child: BookNotice(
                        title: 'Le chapitre attendra un instant',
                        message: 'Impossible de charger les tendances.',
                        action: OutlinedButton(
                          onPressed: () =>
                              ref.invalidate(trendingProvider(selected)),
                          child: const Text('Réessayer'),
                        ),
                      ),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 18),
                    child: SizedBox(
                      height: MediaQuery.textScalerOf(context).scale(40) + 12,
                      child: ref
                          .watch(categoriesProvider)
                          .when(
                            data: (categories) => ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              scrollDirection: Axis.horizontal,
                              itemCount: categories.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) => Center(
                                child: FilterChip(
                                  label: Text(categories[index]),
                                  selected: categories[index] == selected,
                                  onSelected: (_) => ref
                                      .read(selectedCategoryProvider.notifier)
                                      .select(categories[index]),
                                ),
                              ),
                            ),
                            loading: () => const Center(
                              child: Text('Ouverture des chapitres…'),
                            ),
                            error: (_, __) => Center(
                              child: TextButton(
                                onPressed: () =>
                                    ref.invalidate(categoriesProvider),
                                child: const Text('Réessayer les catégories'),
                              ),
                            ),
                          ),
                    ),
                  ),
                ),
                if (books.hasValue && books.value!.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _BookShelf(
                      id: 'top',
                      title: 'En hausse cette semaine',
                      eyebrow: 'LE TOP 10 DES LECTEURS',
                      books: books.value!.take(10).toList(),
                      ranked: true,
                    ),
                  ),
                  if (books.value!.any((b) => b.genre == 'Classiques'))
                    SliverToBoxAdapter(
                      child: _BookShelf(
                        id: 'classics',
                        title: 'Classiques qu’on relit',
                        eyebrow: 'LES HISTOIRES RESTENT',
                        books: books.value!
                            .where((b) => b.genre == 'Classiques')
                            .toList(),
                      ),
                    ),
                  if (books.value!.any(_isShort))
                    SliverToBoxAdapter(
                      child: _BookShelf(
                        id: 'short',
                        title: 'Une soirée, un livre',
                        eyebrow: 'COURTS À LIRE, LONGS À OUBLIER',
                        books: books.value!.where(_isShort).toList(),
                      ),
                    ),
                ],
                if (books.value?.isNotEmpty ?? false)
                  SliverToBoxAdapter(
                    child: _BookShelf(
                      id: 'rated',
                      title: 'Les mieux notés',
                      eyebrow: 'LES VOIX DE LA COMMUNAUTÉ',
                      books: [...books.value!]
                        ..sort(
                          (a, b) => ref
                              .watch(ratingSummaryProvider(b.isbn))
                              .average
                              .compareTo(
                                ref
                                    .watch(ratingSummaryProvider(a.isbn))
                                    .average,
                              ),
                        ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: StaggeredReveal(
                    index: 3,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 6, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Divider(),
                          const SizedBox(height: 12),
                          Text(
                            'Laissez le hasard bien faire.',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => context.push('/radar'),
                                icon: const Icon(Icons.sell_outlined, size: 18),
                                label: const Text('Radar · à prix doux'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => context.push('/match'),
                                icon: const Icon(
                                  Icons.auto_awesome_outlined,
                                  size: 18,
                                ),
                                label: const Text('MatchMaker'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: Folio('01')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

bool _isShort(Book book) => const {
  '9782070667918',
  '9782070413438',
  '9780060970406',
  '9780344279098',
  '9782081641624',
}.contains(book.isbn);

class _BookShelf extends StatelessWidget {
  const _BookShelf({
    required this.id,
    required this.title,
    required this.eyebrow,
    required this.books,
    this.ranked = false,
  });
  final String id, title, eyebrow;
  final List<Book> books;
  final bool ranked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaled = MediaQuery.textScalerOf(context);
    final height = 226 + scaled.scale(20) * 4 + scaled.scale(14) * 2;
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.7,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 5),
                Semantics(
                  header: true,
                  child: Text(title, style: theme.textTheme.headlineSmall),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
          SizedBox(
            height: height,
            child: ListView.separated(
              key: PageStorageKey('shelf-$id'),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.horizontal,
              itemCount: books.length,
              separatorBuilder: (_, __) => const SizedBox(width: 20),
              itemBuilder: (context, index) {
                final book = books[index];
                return StaggeredReveal(
                  index: index,
                  child: SizedBox(
                    width: 132,
                    child: Semantics(
                      container: true,
                      onTap: () => openTrendingBook(context, id, book),
                      button: true,
                      label:
                          '${ranked ? 'N°${index + 1}, ' : ''}${book.title}, ${book.author}. Ouvrir la fiche de lecture',
                      excludeSemantics: true,
                      child: InkWell(
                        onTap: () => openTrendingBook(context, id, book),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 190,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned(
                                    left: ranked ? 18 : 0,
                                    top: 6,
                                    child: Hero(
                                      tag: trendingHeroTag(id, book),
                                      child: BookCover(book: book, width: 114),
                                    ),
                                  ),
                                  if (ranked)
                                    Positioned(
                                      left: 0,
                                      bottom: 0,
                                      child: Text(
                                        '${index + 1}'.padLeft(2, '0'),
                                        textScaler: TextScaler.noScaling,
                                        style: TextStyle(
                                          fontFamily: ElaType.titleFamily,
                                          fontSize: 65,
                                          height: 1,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.primary,
                                          shadows: [
                                            Shadow(
                                              color: theme.colorScheme.surface,
                                              blurRadius: 3,
                                              offset: const Offset(2, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              book.title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 19,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 5),
                            BookRatingLabel(isbn: book.isbn),
                            const SizedBox(height: 5),
                            Text(
                              book.author,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
