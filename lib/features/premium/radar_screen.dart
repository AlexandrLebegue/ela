import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
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
    if (entitlement == null) return const SizedBox.shrink();

    // Top 6 par taux de remise (prix d'occasion fictif / prix neuf).
    final deals = DemoData.books
        .where((b) => b.priceEur != null && b.usedPriceEur != null)
        .toList()
      ..sort((a, b) => _discount(b)!.compareTo(_discount(a)!));
    final top = deals.take(6).toList();

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(title: const Text('Radar à économies')),
      body: entitlement.isPremium
          ? ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: top.length,
              itemBuilder: (context, i) => _DealRow(
                book: top[i],
                discount: _discount(top[i])!,
                onTap: () => context.go('/livre/${top[i].isbn}'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'L’essentiel du Radar vous est montré.',
                  style: TextStyle(
                    fontFamily: 'Lora',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Premium ouvre le radar complet : les 6 meilleures '
                  'occasions du moment, triées par remise, mises à jour '
                  'chaque semaine.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                _DealRow(
                  book: top.first,
                  discount: _discount(top.first)!,
                  onTap: () => context.go('/livre/${top.first.isbn}'),
                ),
                for (var i = 1; i < top.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _LockedDealRow(book: top[i]),
                  ),
                const SizedBox(height: 12),
                PremiumUnlockCard(
                  message: 'Les 6 meilleures occasions, la remise calculée '
                      'sur les prix d’occasion fictifs du catalogue, et '
                      'l’alerte quand une pépite passe sous votre budget.',
                ),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _Cover(book: book),
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          formatPrice(book.priceEur),
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatPrice(book.usedPriceEur),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: ElaColors.sepiaDeep,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: ElaColors.gold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '−$pct %',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: ElaColors.sepiaDeep,
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
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 46,
      height: 70,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.4)),
      ),
      child: Center(
        child: Text(
          book.title.substring(0, 1),
          style: TextStyle(
            fontFamily: 'Lora',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _LockedDealRow extends StatelessWidget {
  const _LockedDealRow({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _Cover(book: book),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Occasion floutée — Premium',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: scheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.lock_outline, size: 18, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
