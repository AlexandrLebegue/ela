import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/format.dart';
import '../../core/design/book_tile.dart';
import '../../core/widgets/book_cover.dart';
import '../../data/fake/demo_books.dart';
import '../../data/models/market.dart';
import '../../providers.dart';
import '../premium/radar_screen.dart';

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key, this.isbn, this.radar = false});
  final String? isbn;
  final bool radar;
  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  String _query = '';
  String _city = 'Toutes les villes';
  bool _radar = false;
  @override
  void initState() {
    super.initState();
    _radar = widget.radar;
  }

  @override
  void didUpdateWidget(covariant MarketScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.radar != widget.radar) _radar = widget.radar;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isbn != null) return OfferComparison(isbn: widget.isbn!);
    final theme = Theme.of(context);
    final books = DemoData.books
        .where(
          (b) => normalizeQuery(
            '${b.title} ${b.author}',
          ).contains(normalizeQuery(_query)),
        )
        .toList();
    final listings = ref.watch(marketListingsProvider);
    return BookScaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ChapterHeader(
              chapter: 'V',
              title: 'Marché',
              subtitle: 'Les livres passent. Les histoires restent.',
              trailing: IconButton(
                tooltip: 'Votre espace',
                onPressed: () => context.push('/compte'),
                icon: const Icon(Icons.person_outline),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Les bonnes affaires'),
                    selected: !_radar,
                    onSelected: (_) => setState(() => _radar = false),
                  ),
                  ChoiceChip(
                    label: const Text('Radar · Premium'),
                    selected: _radar,
                    onSelected: (_) => setState(() => _radar = true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _radar
                  ? const RadarScreen(embedded: true)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      children: [
                        TextField(
                          onChanged: (q) => setState(() => _query = q),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            labelText: 'Chercher un livre ou un auteur',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Prix et annonces de démonstration · retrait ou livraison selon l’offre.',
                          style: theme.textTheme.labelSmall,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _query.isEmpty
                              ? 'Bonnes affaires du moment'
                              : 'Livres trouvés',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        if (books.isEmpty)
                          const BookNotice(
                            title: 'Aucun livre trouvé',
                            message: 'Essayez un autre titre ou auteur.',
                          ),
                        for (final book in books.take(_query.isEmpty ? 3 : 18))
                          BookTile(
                            book: book,
                            onTap: () =>
                                context.go('/marche?isbn=${book.isbn}'),
                            detail:
                                'Occasion dès ${formatPrice((book.usedPriceEur ?? 3.5) + 1)} · comparer les offres',
                          ),
                        const SizedBox(height: 16),
                        Text(
                          'Annonces entre lecteurs',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _city,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Près de chez vous · ville',
                          ),
                          items:
                              [
                                    'Toutes les villes',
                                    ...{
                                      ...['Paris', 'Lyon', 'Bordeaux'],
                                      ...?listings.value?.map((l) => l.city),
                                    },
                                  ]
                                  .map(
                                    (v) => DropdownMenuItem(
                                      value: v,
                                      child: Text(v),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => setState(() => _city = v!),
                        ),
                        const SizedBox(height: 12),
                        listings.when(
                          loading: () => const BookNotice(
                            title: 'Ouverture des annonces…',
                            loading: true,
                          ),
                          error: (_, _) => BookNotice(
                            title: 'Annonces indisponibles',
                            action: TextButton(
                              onPressed: () =>
                                  ref.invalidate(marketListingsProvider),
                              child: const Text('Réessayer'),
                            ),
                          ),
                          data: (items) {
                            final matches =
                                items
                                    .where(
                                      (l) =>
                                          (_city == 'Toutes les villes' ||
                                              normalizeQuery(l.city) ==
                                                  normalizeQuery(_city)) &&
                                          (_query.isEmpty ||
                                              books.any(
                                                (b) => b.isbn == l.isbn,
                                              )),
                                    )
                                    .toList()
                                  ..sort(
                                    (a, b) =>
                                        b.createdAt.compareTo(a.createdAt),
                                  );
                            return Column(
                              children: [
                                if (matches.isEmpty)
                                  const BookNotice(
                                    title: 'Aucune annonce ici pour le moment',
                                  ),
                                for (final listing in matches)
                                  ListingTile(listing: listing),
                              ],
                            );
                          },
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.go('/bibliotheque'),
                          icon: const Icon(Icons.sell_outlined),
                          label: const Text(
                            'Vendre un livre de ma bibliothèque',
                          ),
                        ),
                        const Folio('05'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class WhereToBuy extends ConsumerWidget {
  const WhereToBuy({super.key, required this.isbn});
  final String isbn;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = ref.watch(bookOffersProvider(isbn));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: PageCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Où l’acheter',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              offers.when(
                loading: () => const Text('Recherche des offres…'),
                error: (_, _) =>
                    const Text('Comparez les offres dans le Marché.'),
                data: (items) {
                  final fresh = sortedOffers(
                    items.where((o) => o.isNew),
                    OfferSort.totalPrice,
                  ).firstOrNull;
                  final used = sortedOffers(
                    items.where((o) => !o.isNew),
                    OfferSort.totalPrice,
                  ).firstOrNull;
                  return Text(
                    [
                      if (fresh != null) 'Neuf : ${formatPrice(fresh.total)}',
                      if (used != null) 'Occasion : ${formatPrice(used.total)}',
                      'port inclus ou retrait',
                    ].join(' · '),
                  );
                },
              ),
              TextButton.icon(
                onPressed: () => context.push('/marche?isbn=$isbn'),
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('Comparer dans le Marché'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OfferComparison extends ConsumerStatefulWidget {
  const OfferComparison({super.key, required this.isbn});
  final String isbn;
  @override
  ConsumerState<OfferComparison> createState() => _OfferComparisonState();
}

class _OfferComparisonState extends ConsumerState<OfferComparison> {
  OfferSort _sort = OfferSort.totalPrice;
  String _kind = 'Tout';
  BookOffer? _opening;
  Future<void> _open(BookOffer offer) async {
    if (_opening != null) return;
    setState(() => _opening = offer);
    try {
      final link = await ref
          .read(paymentServiceProvider)
          .affiliatePurchaseLink(widget.isbn);
      final uri = Uri.parse(link).replace(
        queryParameters: {
          ...Uri.parse(link).queryParameters,
          'merchant': offer.merchant,
        },
      );
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        builder: (context) => SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offre ${offer.merchant}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Text('Lien affilié simulé · aucun achat effectué.'),
                const SizedBox(height: 12),
                SelectableText(uri.toString()),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: uri.toString()),
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lien affilié copié.')),
                      );
                    }
                  },
                  child: const Text('Copier le lien'),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le lien est indisponible. Réessayez.')),
        );
      }
    } finally {
      if (context.mounted) setState(() => _opening = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final book =
        ref.watch(bookByIsbnProvider(widget.isbn)).value ??
        DemoData.byIsbnLookup(widget.isbn);
    final theme = Theme.of(context);
    return BookScaffold(
      appBar: BookAppBar(
        title: const Text('Le comparateur'),
        leading: IconButton(
          tooltip: 'Retour au Marché',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/marche');
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ref
          .watch(bookOffersProvider(widget.isbn))
          .when(
            loading: () => const BookNotice(
              title: 'Comparaison des offres…',
              loading: true,
            ),
            error: (_, _) => BookNotice(
              title: 'Offres indisponibles',
              action: TextButton(
                onPressed: () =>
                    ref.invalidate(bookOffersProvider(widget.isbn)),
                child: const Text('Réessayer'),
              ),
            ),
            data: (items) {
              final sorted = sortedOffers(
                items.where(
                  (o) =>
                      _kind == 'Tout' || (_kind == 'Neuf' ? o.isNew : !o.isNew),
                ),
                _sort,
              );
              final best = sortedOffers(
                sorted,
                OfferSort.totalPrice,
              ).firstOrNull;
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (book != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BookCover(book: book, width: 64),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.title,
                                style: theme.textTheme.headlineSmall,
                              ),
                              Text(book.author),
                              const SizedBox(height: 8),
                              Text(
                                'Neuf et seconde main',
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Prix de démonstration · total avec port, ou retrait gratuit indiqué.',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final kind in ['Tout', 'Neuf', 'Occasion'])
                        ChoiceChip(
                          label: Text(kind),
                          selected: _kind == kind,
                          onSelected: (_) => setState(() => _kind = kind),
                        ),
                    ],
                  ),
                  DropdownButtonFormField<OfferSort>(
                    initialValue: _sort,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Trier les offres',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: OfferSort.totalPrice,
                        child: Text('Prix total croissant'),
                      ),
                      DropdownMenuItem(
                        value: OfferSort.condition,
                        child: Text('Meilleur état, puis prix'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _sort = v!),
                  ),
                  const SizedBox(height: 16),
                  if (sorted.isEmpty)
                    const BookNotice(
                      title: 'Aucune offre pour ce livre pour le moment',
                    ),
                  for (final offer in sorted)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PageCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (offer == best)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    'MEILLEURE OFFRE · PRIX TOTAL',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              Wrap(
                                spacing: 16,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    offer.merchant,
                                    style: theme.textTheme.titleLarge,
                                  ),
                                  Text(
                                    formatPrice(offer.total),
                                    style: theme.textTheme.headlineSmall,
                                  ),
                                ],
                              ),
                              Text(
                                '${offer.condition.label} · livre ${formatPrice(offer.price)} + port ${formatPrice(offer.shipping)}',
                              ),
                              if (offer.shipping == 0)
                                Text(
                                  offer.merchant == 'Place des Libraires' ||
                                          offer.merchant == 'Leboncoin'
                                      ? 'Retrait gratuit sur place'
                                      : 'Livraison incluse',
                                  style: theme.textTheme.labelSmall,
                                ),
                              TextButton.icon(
                                onPressed: _opening != null
                                    ? null
                                    : () => _open(offer),
                                icon: const Icon(Icons.open_in_new, size: 16),
                                label: const Text('Voir l’offre affiliée'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
    );
  }
}

class ListingTile extends ConsumerWidget {
  const ListingTile({super.key, required this.listing});
  final ReaderListing listing;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book =
        ref.watch(bookByIsbnProvider(listing.isbn)).value ??
        DemoData.byIsbnLookup(listing.isbn);
    if (book == null) return const SizedBox.shrink();
    return BookTile(
      book: book,
      onTap: () => context.push('/annonce/${listing.id}'),
      detail:
          '${formatPrice(listing.price)} · ${listing.condition.label}\n${listing.city} · ${listing.seller} · ${shortDate(listing.createdAt)}',
    );
  }
}

class ListingScreen extends ConsumerStatefulWidget {
  const ListingScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<ListingScreen> createState() => _ListingScreenState();
}

class _ListingScreenState extends ConsumerState<ListingScreen> {
  bool _contacted = false;
  bool _busy = false;
  @override
  Widget build(BuildContext context) => BookScaffold(
    appBar: BookAppBar(title: const Text('Entre lecteurs')),
    body: ref
        .watch(marketListingsProvider)
        .when(
          loading: () =>
              const BookNotice(title: 'Ouverture de l’annonce…', loading: true),
          error: (_, _) => const BookNotice(title: 'Annonce indisponible'),
          data: (items) {
            final listing = items.where((l) => l.id == widget.id).firstOrNull;
            if (listing == null) {
              return const BookNotice(
                title: 'Cette annonce n’est plus disponible',
              );
            }
            final book =
                ref.watch(bookByIsbnProvider(listing.isbn)).value ??
                DemoData.byIsbnLookup(listing.isbn);
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (book != null)
                  Center(child: BookCover(book: book, width: 130)),
                const SizedBox(height: 20),
                Text(
                  book?.title ?? 'Livre ${listing.isbn}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                if (book != null) Text(book.author),
                const SizedBox(height: 12),
                Text(
                  formatPrice(listing.price),
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                Text('${listing.condition.label} · ${listing.city}'),
                const SizedBox(height: 16),
                Text(
                  'Proposé par ${listing.seller} · ${shortDate(listing.createdAt)}',
                ),
                const Text(
                  'Remise en main propre · échangez avec le lecteur pour convenir d’un rendez-vous.',
                ),
                if (listing.photoUrl != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Image.network(
                      listing.photoUrl!,
                      height: 180,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          const Text('Photo indisponible'),
                    ),
                  ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _busy || _contacted
                      ? null
                      : () async {
                          setState(() => _busy = true);
                          try {
                            await ref
                                .read(marketServiceProvider)
                                .contact(listing.id);
                            if (context.mounted) {
                              setState(() => _contacted = true);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Contact simulé : aucun message n’a été envoyé.',
                                  ),
                                ),
                              );
                            }
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Contact indisponible. Réessayez.',
                                  ),
                                ),
                              );
                            }
                          } finally {
                            if (context.mounted) setState(() => _busy = false);
                          }
                        },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text(_contacted ? 'Demande simulée' : 'Contacter'),
                ),
                const Text(
                  'Annonces de démonstration · aucune transaction réelle.',
                ),
              ],
            );
          },
        ),
  );
}

Future<void> showSellSheet(BuildContext context, String isbn) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SellBookSheet(isbn: isbn),
    );

class SellBookSheet extends ConsumerStatefulWidget {
  const SellBookSheet({super.key, required this.isbn});
  final String isbn;
  @override
  ConsumerState<SellBookSheet> createState() => _SellBookSheetState();
}

class _SellBookSheetState extends ConsumerState<SellBookSheet> {
  final _form = GlobalKey<FormState>();
  final _price = TextEditingController();
  final _city = TextEditingController();
  final _photo = TextEditingController();
  BookCondition _condition = BookCondition.veryGood;
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _price.dispose();
    _city.dispose();
    _photo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transmettre ce livre',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Text('Votre annonce entre lecteurs · démonstration'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Prix en euros'),
              validator: (v) {
                final price = double.tryParse((v ?? '').replaceAll(',', '.'));
                return price == null ||
                        !price.isFinite ||
                        price <= 0 ||
                        price > 1000
                    ? 'Indiquez un prix entre 0,01 et 1 000 €.'
                    : null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<BookCondition>(
              initialValue: _condition,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'État du livre'),
              items: BookCondition.values
                  .where((v) => v != BookCondition.newBook)
                  .map((v) => DropdownMenuItem(value: v, child: Text(v.label)))
                  .toList(),
              onChanged: (v) => setState(() => _condition = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _city,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Ville'),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Indiquez votre ville.'
                  : null,
            ),
            TextFormField(
              controller: _photo,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Lien vers une photo (optionnel)',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                final uri = Uri.tryParse(v);
                return uri == null || uri.scheme != 'https' || uri.host.isEmpty
                    ? 'Utilisez une adresse de photo https.'
                    : null;
              },
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () async {
                      if (!_form.currentState!.validate()) return;
                      setState(() {
                        _busy = true;
                        _error = null;
                      });
                      try {
                        final profile = ref.read(profileProvider);
                        await ref
                            .read(marketServiceProvider)
                            .publish(
                              ReaderListing(
                                id: 'local-${DateTime.now().microsecondsSinceEpoch}',
                                isbn: widget.isbn,
                                sellerId: profile.id,
                                seller: profile.isAnonymous
                                    ? 'Un lecteur d’Ela'
                                    : profile.displayNameOrEmail,
                                price: double.parse(
                                  _price.text.replaceAll(',', '.'),
                                ),
                                condition: _condition,
                                city: _city.text.trim(),
                                photoUrl: _photo.text.trim().isEmpty
                                    ? null
                                    : _photo.text.trim(),
                                createdAt: DateTime.now(),
                              ),
                            );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Votre annonce rejoint le Marché.'),
                            ),
                          );
                        }
                      } catch (_) {
                        if (context.mounted) {
                          setState(() {
                            _error =
                                'Publication interrompue. Votre saisie est conservée.';
                            _busy = false;
                          });
                        }
                      }
                    },
              child: Text(_busy ? 'Publication…' : 'Publier l’annonce'),
            ),
          ],
        ),
      ),
    ),
  );
}
