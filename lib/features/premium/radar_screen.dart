import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets/book_cover.dart';
import '../../data/fake/demo_books.dart';
import '../../data/models/book.dart';
import '../../providers.dart';
import 'premium_screen.dart';

/// Radar à économies (Premium) : les meilleures occasions du catalogue,
/// prix d'occasion fictifs.
class RadarScreen extends ConsumerWidget {
  const RadarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final entitlement = ref.watch(entitlementStreamProvider).value;
    if (entitlement == null) {
      final failed = ref.watch(entitlementStreamProvider).hasError;
      return BookScaffold(
        appBar: BookAppBar(title: const Text('Radar à économies')),
        body: BookNotice(
          title: failed
              ? 'Cette page est momentanément indisponible'
              : 'Ouverture de votre édition…',
          loading: !failed,
          action: failed
              ? OutlinedButton(
                  onPressed: () => ref.invalidate(entitlementStreamProvider),
                  child: const Text('Réessayer'),
                )
              : null,
        ),
      );
    }

    // Top 6 par taux de remise (prix d'occasion fictif / prix neuf).
    final deals =
        DemoData.books
            .where((b) => b.priceEur != null && b.usedPriceEur != null)
            .toList()
          ..sort((a, b) => _discount(b)!.compareTo(_discount(a)!));
    final top = deals.take(6).toList();

    return BookScaffold(
      backgroundColor: scheme.surface,
      appBar: BookAppBar(title: const Text('Radar à économies')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          ElaSize.v24,
          ElaSize.v8,
          ElaSize.v24,
          ElaSize.v32,
        ),
        children: [
          const ChapterHeader(
            chapter: 'VI',
            title: 'Le Radar',
            subtitle: 'De belles lectures, à prix doux.',
          ),
          Text(
            'Prix d’occasion fictifs · catalogue de démonstration',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: ElaSize.v16),
          if (!entitlement.isPremium) ...[
            Text(
              'L’essentiel du Radar vous est montré.',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: ElaSize.v8),
            const Text(
              'Premium ouvre les six meilleures occasions, classées par remise.',
            ),
            const SizedBox(height: ElaSize.v16),
          ],
          for (var i = 0; i < top.length; i++)
            if (entitlement.isPremium || i == 0)
              _DealRow(
                book: top[i],
                discount: _discount(top[i])!,
                onTap: () => context.push('/livre/${top[i].isbn}'),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: ElaSize.v12),
                child: _LockedDealRow(book: top[i]),
              ),
          if (!entitlement.isPremium)
            const PremiumUnlockCard(
              message: 'Découvrez les six meilleures occasions du catalogue.',
            ),
          const Folio('06'),
        ],
      ),
    );
  }

  static double? _discount(Book b) {
    if (b.priceEur == null || b.usedPriceEur == null || b.priceEur! == 0) {
      return null;
    }
    return 1 - b.usedPriceEur! / b.priceEur!;
  }
}

class _DealRow extends StatelessWidget {
  const _DealRow({
    required this.book,
    required this.discount,
    required this.onTap,
  });

  final Book book;
  final double discount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pct = (discount * 100).round();
    return PageCard(
      margin: const EdgeInsets.only(bottom: ElaSize.v10),
      child: InkWell(
        borderRadius: BorderRadius.circular(ElaSpace.radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(ElaSize.v12),
          child: Row(
            children: [
              _Cover(book: book),
              const SizedBox(width: ElaSize.v12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: TextStyle(
                        fontSize: ElaType.body,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: ElaSize.v2),
                    Text(
                      book.author,
                      style: TextStyle(
                        fontSize: ElaSize.v13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: ElaSize.v6),
                    Wrap(
                      spacing: ElaSize.v8,
                      runSpacing: ElaSize.v8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          formatPrice(book.priceEur),
                          style: TextStyle(
                            fontSize: ElaSize.v13,
                            color: scheme.onSurfaceVariant,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: ElaSize.v8),
                        Text(
                          formatPrice(book.usedPriceEur),
                          style: TextStyle(
                            fontSize: ElaSize.v14,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: ElaSize.v8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: ElaSize.v7,
                            vertical: ElaSize.v2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.secondary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(
                              ElaSpace.radius,
                            ),
                          ),
                          child: Text(
                            '−$pct %',
                            style: TextStyle(
                              fontSize: ElaSize.v12,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.primary,
                            ),
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

class _Cover extends StatelessWidget {
  const _Cover({required this.book});
  final Book book;
  @override
  Widget build(BuildContext context) =>
      BookCover(book: book, width: ElaSize.v48);
}

class _LockedDealRow extends StatelessWidget {
  const _LockedDealRow({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(ElaSize.v12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(ElaSpace.radius),
      ),
      child: Row(
        children: [
          _Cover(book: book),
          const SizedBox(width: ElaSize.v12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: TextStyle(
                    fontSize: ElaSize.v14,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: ElaSize.v4),
                Text(
                  'Occasion floutée — Premium',
                  style: TextStyle(
                    fontSize: ElaSize.v12_5,
                    color: scheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.lock_outline,
            size: ElaSize.v18,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
