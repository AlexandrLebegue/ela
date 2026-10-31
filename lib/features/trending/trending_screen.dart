import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/animations.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/design/book_tile.dart';
import '../../providers.dart';

class _SelectedCategoryNotifier extends Notifier<String?> {
  @override
  String? build() => 'Tous';
  void select(String category) => state = category;
}

final selectedCategoryProvider =
    NotifierProvider<_SelectedCategoryNotifier, String?>(
      _SelectedCategoryNotifier.new,
    );

class TrendingScreen extends ConsumerWidget {
  const TrendingScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCategoryProvider);
    final theme = Theme.of(context);
    final books = ref.watch(trendingProvider(selected));
    return BookScaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ChapterHeader(
                chapter: 'I',
                title: 'Tendance',
                subtitle: 'Les livres qui passent de main en main.',
                trailing: IconButton(
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
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: ElaSize.v24),
                child: Row(
                  children: [
                    Expanded(
                      child: _Discovery(
                        title: 'Radar',
                        subtitle: 'Occasions à prix doux',
                        icon: Icons.sell_outlined,
                        onTap: () => context.push('/radar'),
                      ),
                    ),
                    const SizedBox(width: ElaSize.v12),
                    Expanded(
                      child: _Discovery(
                        title: 'MatchMaker',
                        subtitle: 'Votre prochaine lecture',
                        icon: Icons.auto_awesome_outlined,
                        onTap: () => context.push('/match'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: ElaSize.v16),
                child: SizedBox(
                  height: MediaQuery.textScalerOf(context).scale(40) + 12,
                  child: ref
                      .watch(categoriesProvider)
                      .when(
                        data: (cats) => ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: ElaSize.v24,
                          ),
                          scrollDirection: Axis.horizontal,
                          itemCount: cats.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: ElaSize.v8),
                          itemBuilder: (context, i) => Center(
                            child: FilterChip(
                              label: Text(cats[i]),
                              selected: cats[i] == selected,
                              onSelected: (_) => ref
                                  .read(selectedCategoryProvider.notifier)
                                  .select(cats[i]),
                            ),
                          ),
                        ),
                        loading: () => const Center(
                          child: Text('Ouverture des chapitres…'),
                        ),
                        error: (_, __) => TextButton(
                          onPressed: () => ref.invalidate(categoriesProvider),
                          child: const Text('Réessayer les catégories'),
                        ),
                      ),
                ),
              ),
            ),
            ...books.when(
              data: (items) => items.isEmpty
                  ? [
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: BookNotice(
                          title: 'Une page encore blanche',
                          message: 'Rien ne bouge encore dans cette catégorie.',
                        ),
                      ),
                    ]
                  : [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ElaSize.v24,
                        ),
                        sliver: SliverList.builder(
                          itemCount: items.length,
                          itemBuilder: (context, i) => StaggeredReveal(
                            index: i,
                            child: BookTile(
                              key: ValueKey(
                                'tendance-$selected-${items[i].isbn}',
                              ),
                              book: items[i],
                              rank: i + 1,
                              detail:
                                  '${items[i].badgeLabel}\n${formatInt(items[i].readersCount)} lecteurs d’Ela',
                              onTap: () =>
                                  context.push('/livre/${items[i].isbn}'),
                            ),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: Folio('01')),
                    ],
              loading: () => [
                SliverPadding(
                  padding: const EdgeInsets.all(ElaSize.v24),
                  sliver: SliverList.list(
                    children: [
                      for (var i = 0; i < 4; i++)
                        const Padding(
                          padding: EdgeInsets.only(bottom: ElaSize.v16),
                          child: InkSkeletonBlock(height: ElaSize.v96),
                        ),
                    ],
                  ),
                ),
              ],
              error: (_, __) => [
                SliverFillRemaining(
                  hasScrollBody: false,
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
          ],
        ),
      ),
    );
  }
}

class _Discovery extends StatelessWidget {
  const _Discovery({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => PageCard(
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(ElaSize.v12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: ElaSize.v20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: ElaSize.v8),
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: ElaSize.v4),
            Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    ),
  );
}
