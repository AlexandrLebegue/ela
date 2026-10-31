import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/widgets/book_cover.dart';
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
    if (entitlement == null) {
      final failed = ref.watch(entitlementStreamProvider).hasError;
      return BookScaffold(
        appBar: BookAppBar(title: const Text('MatchMaker')),
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
    final library = ref.watch(libraryEntriesProvider);
    if (library.isLoading || library.hasError) {
      return BookScaffold(
        appBar: BookAppBar(title: const Text('MatchMaker')),
        body: BookNotice(
          title: library.hasError
              ? 'Votre étagère est momentanément indisponible'
              : 'Ouverture de votre étagère…',
          loading: library.isLoading,
          action: library.hasError
              ? OutlinedButton(
                  onPressed: () => ref.invalidate(libraryEntriesProvider),
                  child: const Text('Réessayer'),
                )
              : null,
        ),
      );
    }
    final entries = library.value ?? const <LibraryEntry>[];

    // Vos livres : historique d'abord, puis PAL, 4 au maximum.
    final mine =
        entries.where((e) => DemoData.byIsbnLookup(e.isbn) != null).toList()
          ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    final myBooks = mine
        .take(4)
        .map((e) => DemoData.byIsbnLookup(e.isbn)!)
        .toList();

    final List<_Match> matches = [];
    for (final b in myBooks) {
      matches.addAll(_matchesFor(b).take(2));
    }

    return BookScaffold(
      backgroundColor: scheme.surface,
      appBar: BookAppBar(title: const Text('MatchMaker')),
      body: myBooks.isEmpty
          ? const _MatchEmpty()
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                ElaSize.v16,
                ElaSize.v8,
                ElaSize.v16,
                ElaSize.v96,
              ),
              children: [
                const ChapterHeader(
                  chapter: 'VII',
                  title: 'Affinités littéraires',
                  subtitle: 'Votre étagère a de la conversation.',
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: ElaSize.v12),
                  child: Text(
                    'D’après « ${myBooks.map((b) => b.title).join(' », « ')} » '
                    'et votre étagère, Ela vous propose :',
                    style: TextStyle(
                      fontSize: ElaSize.v13,
                      height: ElaSize.v1_5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                for (var i = 0; i < matches.length; i++) ...[
                  if (i > 0) const SizedBox(height: ElaSize.v10),
                  if (entitlement.isPremium)
                    _MatchRow(
                      match: matches[i],
                      onTap: () =>
                          context.push('/livre/${matches[i].book.isbn}'),
                    )
                  else
                    i < 2
                        ? _MatchRow(
                            match: matches[i],
                            onTap: () =>
                                context.push('/livre/${matches[i].book.isbn}'),
                          )
                        : _LockedMatchRow(match: matches[i]),
                ],
                if (!entitlement.isPremium) ...[
                  const SizedBox(height: ElaSize.v12),
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
      others.addAll(
        DemoData.books
            .where((b) => b.isbn != origin.isbn && b.genre != origin.genre)
            .toList(),
      );
    }
    final scored =
        others
            .map(
              (b) => _Match(
                book: b,
                becauseOf: origin,
                score: 62 + stableHash('${origin.isbn}|${b.isbn}') % 36,
                sameGenre: b.genre == origin.genre,
              ),
            )
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
    return PageCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(ElaSpace.radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(ElaSize.v12),
          child: Row(
            children: [
              _Cover(book: match.book),
              const SizedBox(width: ElaSize.v12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.book.title,
                      style: TextStyle(
                        fontSize: ElaType.body,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: ElaSize.v2),
                    Text(
                      '${match.book.author} · ${match.reason}',
                      style: TextStyle(
                        fontSize: ElaSize.v12_5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: ElaSize.v8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              ElaSpace.radius,
                            ),
                            child: LinearProgressIndicator(
                              value: match.score / 100,
                              minHeight: ElaSize.v6,
                              backgroundColor: scheme.outline.withValues(
                                alpha: 0.25,
                              ),
                              valueColor: AlwaysStoppedAnimation(
                                Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: ElaSize.v8),
                        Text(
                          '${match.score} %',
                          style: TextStyle(
                            fontSize: ElaSize.v12_5,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.primary,
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
      padding: const EdgeInsets.all(ElaSize.v12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(ElaSpace.radius),
      ),
      child: Row(
        children: [
          _Cover(book: match.book),
          const SizedBox(width: ElaSize.v12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.book.title,
                  style: TextStyle(
                    fontSize: ElaSize.v14,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: ElaSize.v4),
                Text(
                  'Match Premium — score masqué',
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

class _Cover extends StatelessWidget {
  const _Cover({required this.book});
  final Book book;
  @override
  Widget build(BuildContext context) =>
      BookCover(book: book, width: ElaSize.v48);
}

class _MatchEmpty extends StatelessWidget {
  const _MatchEmpty();

  @override
  Widget build(BuildContext context) {
    return const BookNotice(
      title: 'Votre étagère est vide',
      message:
          'Le MatchMaker a besoin de quelques livres scannés ou en Pile à Lire pour vous deviner.',
      icon: Icons.auto_awesome_outlined,
    );
  }
}
