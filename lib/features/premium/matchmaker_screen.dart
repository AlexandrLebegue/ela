import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/fake/demo_books.dart';
import '../../data/fake/fake_delay.dart';
import '../../data/models/book.dart';
import '../../data/models/library_entry.dart';
import '../../providers.dart';
import 'premium_screen.dart';

/// MatchMaker (Premium) : des livres qui « ressemblent » à votre étagère,
/// avec un score de compatibilité déterministe.
class MatchMakerScreen extends ConsumerWidget {
  const MatchMakerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final entitlement = ref.watch(entitlementStreamProvider).value;
    if (entitlement == null) return const SizedBox.shrink();
    final entries = ref.watch(libraryEntriesProvider).value ??
        const <LibraryEntry>[];

    // Vos livres : historique d'abord, puis PAL, 4 au maximum.
    final mine = entries
        .where((e) => DemoData.byIsbnLookup(e.isbn) != null)
        .toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    final myBooks = mine
        .take(4)
        .map((e) => DemoData.byIsbnLookup(e.isbn)!)
        .toList();

    final List<_Match> matches = [];
    for (final b in myBooks) {
      matches.addAll(_matchesFor(b).take(2));
    }

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(title: const Text('MatchMaker')),
      body: myBooks.isEmpty
          ? const _MatchEmpty()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'D’après « ${myBooks.map((b) => b.title).join(' », « ')} » '
                    'et votre étagère, Ela vous propose :',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                for (var i = 0; i < matches.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  if (entitlement.isPremium)
                    _MatchRow(
                      match: matches[i],
                      onTap: () =>
                          context.go('/livre/${matches[i].book.isbn}'),
                    )
                  else
                    i < 2
                        ? _MatchRow(
                            match: matches[i],
                            onTap: () =>
                                context.go('/livre/${matches[i].book.isbn}'),
                          )
                        : _LockedMatchRow(match: matches[i]),
                ],
                if (!entitlement.isPremium) ...[
                  const SizedBox(height: 12),
                  PremiumUnlockCard(
                    message:
                        'Tous vos matchs, avec le score de compatibilité et '
                        'la raison du rapprochement — genre, époque, ton.',
                  ),
                ],
              ],
            ),
    );
  }

  static List<_Match> _matchesFor(Book origin) {
    final others = DemoData.books
        .where((b) => b.isbn != origin.isbn && b.genre == origin.genre)
        .toList();
    // Complète avec d'autres genres si le sien est trop étroit.
    if (others.length < 2) {
      others.addAll(DemoData.books
          .where((b) => b.isbn != origin.isbn && b.genre != origin.genre)
          .toList());
    }
    final scored = others
        .map((b) => _Match(
              book: b,
              becauseOf: origin,
              score: 62 + stableHash('${origin.isbn}|${b.isbn}') % 36,
              sameGenre: b.genre == origin.genre,
            ))
        .toList()
      ..sort((a, b) => b.score - a.score);
    return scored;
  }
}

class _Match {
  const _Match({
    required this.book,
    required this.becauseOf,
    required this.score,
    required this.sameGenre,
  });

  final Book book;
  final Book becauseOf;
  final int score;
  final bool sameGenre;

  String get reason => sameGenre
      ? 'Même genre : ${book.genre}'
      : 'Même époque, autre chemin : ${book.genre}';
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({required this.match, required this.onTap});

  final _Match match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _Cover(book: match.book),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.book.title,
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
                      '${match.book.author} · ${match.reason}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: match.score / 100,
                              minHeight: 6,
                              backgroundColor:
                                  scheme.outline.withValues(alpha: 0.25),
                              valueColor:
                                  const AlwaysStoppedAnimation(ElaColors.gold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${match.score} %',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: ElaColors.sepiaDeep,
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

class _LockedMatchRow extends StatelessWidget {
  const _LockedMatchRow({required this.match});

  final _Match match;

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
          _Cover(book: match.book),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.book.title,
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
                  'Match Premium — score masqué',
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

class _MatchEmpty extends StatelessWidget {
  const _MatchEmpty();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Votre étagère est vide — le MatchMaker a besoin de quelques '
          'livres (scannés ou en Pile à Lire) pour vous deviner.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.55,
            color: scheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
