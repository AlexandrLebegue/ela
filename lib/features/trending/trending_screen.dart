import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animations.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets/book_cover.dart';
import '../../data/models/book.dart';
import '../../providers.dart';

/// Écran « Tendance » : listes par catégorie, badges de popularité.
class TrendingScreen extends ConsumerWidget {
  const TrendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final selected = ref.watch(selectedCategoryProvider);
    return Scaffold(
      backgroundColor: scheme.surface,
      body: Column(
        children: [
          _TrendingHeader(selected: selected),
          const SizedBox(height: 8),
          Expanded(
            child: _TrendingList(category: selected),
          ),
        ],
      ),
    );
  }
}

class _SelectedCategoryNotifier extends Notifier<String?> {
  @override
  String? build() => 'Tous';

  void select(String category) => state = category;
}

final selectedCategoryProvider =
    NotifierProvider<_SelectedCategoryNotifier, String?>(
  _SelectedCategoryNotifier.new,
);

class _TrendingHeader extends ConsumerWidget {
  const _TrendingHeader({required this.selected});

  final String? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tendance',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontFamily: 'Lora', fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Ce que les lecteurs d’Ela dévorent en ce moment.',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 44,
            child: ref.watch(categoriesProvider).when(
                  data: (cats) => ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: cats.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final c = cats[i];
                      return FilterChip(
                        label: Text(c),
                        selected: c == selected,
                        onSelected: (_) => ref
                            .read(selectedCategoryProvider.notifier)
                            .select(c),
                      );
                    },
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
          ),
        ],
      ),
    );
  }
}

class _TrendingList extends ConsumerWidget {
  const _TrendingList({required this.category});

  final String? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Le changement de catégorie fait fondre l'ancienne liste vers la
    // nouvelle (clé différente) ; l'arrivée des données anime chaque
    // ligne en cascade.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: ref.watch(trendingProvider(category)).when(
            data: (books) {
              if (books.isEmpty) {
                return const _TrendingEmpty(key: ValueKey('tendance-vide'));
              }
              return ListView.builder(
                key: ValueKey('tendance-$category'),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                itemCount: books.length,
                itemBuilder: (context, i) => StaggeredReveal(
                  index: i,
                  child: _TrendingRow(
                    key: ValueKey('tendance-$category-${books[i].isbn}'),
                    book: books[i],
                    rank: i + 1,
                    onTap: () => context.go('/livre/${books[i].isbn}'),
                  ),
                ),
              );
            },
            loading: () =>
                const _TrendingSkeleton(key: ValueKey('tendance-chargement')),
            error: (e, _) =>
                const _TrendingEmpty(key: ValueKey('tendance-vide')),
          ),
    );
  }
}

class _TrendingRow extends StatelessWidget {
  const _TrendingRow({
    super.key,
    required this.book,
    required this.rank,
    required this.onTap,
  });

  final Book book;
  final int rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isTop = rank <= 3;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text(
                'N°$rank',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isTop ? FontWeight.w800 : FontWeight.w500,
                  color: isTop ? ElaColors.gold : scheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 10),
              BookCover(book: book, width: 56),
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
                        fontSize: 15,
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          book.badgeLabel,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${formatInt(book.readersCount)} lecteurs d’Ela',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
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

class _TrendingSkeleton extends StatelessWidget {
  const _TrendingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: 6,
      itemBuilder: (context, _) => const _SkelRow(),
    );
  }
}

class _SkelRow extends StatelessWidget {
  const _SkelRow();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(children: [
        _SkelBox(width: 56, height: 84),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkelLine(width: 160),
              SizedBox(height: 6),
              _SkelLine(width: 110),
              SizedBox(height: 6),
              _SkelLine(width: 140),
            ],
          ),
        ),
      ]),
    );
  }
}

class _SkelLine extends StatelessWidget {
  const _SkelLine({this.width = double.infinity});

  final double width;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: 11,
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: scheme.outline.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _SkelBox extends StatelessWidget {
  const _SkelBox({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: scheme.outline.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _TrendingEmpty extends StatelessWidget {
  const _TrendingEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Rien ne bouge encore dans cette catégorie.',
          textAlign: TextAlign.center,
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
