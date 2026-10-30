import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/widgets/book_cover.dart';
import '../../data/fake/demo_books.dart';
import '../../data/models/book.dart';
import '../../providers.dart';

/// Fiche livre — version socle (étape 1).
/// Les 3 onglets (Synthèse IA & Presse / Le Web / La Communauté) arrivent
/// à l'étape 3 ; l'en-tête et les actions sont déjà en place.
class BookDetailScreen extends ConsumerStatefulWidget {
  const BookDetailScreen({super.key, required this.isbn});

  final String isbn;

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  bool _addingToPal = false;
  bool _purchased = false;

  Future<void> _addToPal() async {
    if (_addingToPal) return;
    setState(() => _addingToPal = true);
    await ref.read(libraryServiceProvider).addToRead(widget.isbn);
    if (!mounted) return;
    setState(() => _addingToPal = false);
    {
      ElaHaptics.softTap();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajouté à votre Pile à Lire.')),
      );
    }
  }

  Future<void> _purchase() async {
    if (_purchased) return;
    setState(() => _purchased = true);
    final link =
        await ref.read(paymentServiceProvider).affiliatePurchaseLink(widget.isbn);
    if (!mounted) return;
    setState(() => _purchased = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lien affilié : $link')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final book = DemoData.byIsbnLookup(widget.isbn) ??
        Book(
          isbn: widget.isbn,
          title: 'Livre inconnu',
          author: 'Auteur inconnu',
          genre: 'Autre',
          year: 2000,
          badge: PopularityBadge.trending,
          readersCount: 0,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Partager',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lien de la fiche copié.')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BookCover(book: book, width: 120),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (book.publisher != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${book.publisher} · ${book.year}',
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        book.badgeLabel,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${formatInt(book.readersCount)} lecteurs d’Ela ont lu ce livre',
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (book.description != null) ...[
            const SizedBox(height: 16),
            Text(
              'À propos',
              style: TextStyle(
                fontFamily: 'Lora',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              book.description!,
              style: const TextStyle(fontSize: 14.5, height: 1.55),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _addingToPal ? null : _addToPal,
                  icon: _addingToPal
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.bookmark_add_outlined),
                  label:
                      Text(_addingToPal ? 'Ajout…' : 'Ajouter à la PAL'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _purchased ? null : _purchase,
                  icon: _purchased
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.storefront_outlined),
                  label: Text(_purchased ? 'Ouverture…' : 'Acheter'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: ElaColors.gold),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'La curation IA (synthèse, avis presse et web) et la '
                      'communauté s’ouvriront ici dans la prochaine étape.',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (book.priceEur != null) ...[
            const SizedBox(height: 12),
            Text(
              'À partir de ${formatPrice(book.priceEur)} '
              '(${formatPrice(book.usedPriceEur)} en occasion)',
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
