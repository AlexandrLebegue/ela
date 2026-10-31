import '../ratings/rating_widgets.dart';
import '../../core/widgets/rating_stars.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animations.dart';
import '../../core/format.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/widgets/book_cover.dart';
import '../../data/fake/demo_books.dart';
import '../../data/models/book.dart';
import '../../data/models/entitlement.dart';
import '../../data/models/library_entry.dart';
import '../../data/models/review.dart';
import '../../providers.dart';
import '../library/fly_to_library.dart';
import '../premium/premium_screen.dart';

/// Fiche livre (étape 3) : en-tête + 3 onglets en fondu doux —
/// Synthèse IA & Presse / Le Web / La Communauté — + PAL / Acheter.
class BookDetailScreen extends ConsumerStatefulWidget {
  const BookDetailScreen({super.key, required this.isbn, this.heroTag});

  final String isbn;
  final String? heroTag;

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  _DetailTab _tab = _DetailTab.aiPress;
  bool _addingToPal = false;
  bool _purchased = false;
  final GlobalKey _coverKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Chaque livre consulté entre dans l'historique (affiché à l'étape 4).
    ref.read(bookByIsbnProvider(widget.isbn).future).then((book) {
      if (mounted && book != null) {
        ref.read(libraryServiceProvider).addHistory(widget.isbn);
      }
    }, onError: (Object _, StackTrace __) {});
  }

  Future<void> _togglePal({required Book book, required bool inPal}) async {
    if (_addingToPal) return;
    setState(() => _addingToPal = true);
    final from = _coverRect(), target = _libraryTargetRect();
    try {
      final library = ref.read(libraryServiceProvider);
      if (inPal) {
        await library.removeEntry(widget.isbn, LibrarySection.toRead);
      } else {
        await library.addToRead(widget.isbn);
      }
      if (!mounted) return;
      ElaHaptics.softTap();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            inPal
                ? 'Retiré de votre Pile à Lire.'
                : 'Ajouté à votre Pile à Lire.',
          ),
        ),
      );
      if (!inPal && from != null && !MediaQuery.disableAnimationsOf(context)) {
        FlyToLibrary.fly(context, book: book, from: from, to: target);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La bibliothèque n’a pas pu être modifiée. Réessayez.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _addingToPal = false);
    }
  }

  Rect? _coverRect() {
    final box = _coverKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final o = box.localToGlobal(Offset.zero);
    return Rect.fromLTWH(o.dx, o.dy, box.size.width, box.size.height);
  }

  /// Position approx. de l'icône Bibliothèque dans la barre (3e bouton/4).
  Rect _libraryTargetRect() {
    final size = MediaQuery.of(context).size;
    final center = Offset(
      size.width * ElaSize.v0_625,
      size.height - ElaSize.v44,
    );
    return Rect.fromCenter(
      center: center,
      width: ElaSize.v34,
      height: ElaSize.v48,
    );
  }

  /// Ouvre l'écran de compte (lazy registration). Dégradation douce si
  /// aucun routeur n'est disponible (tests de widgets isolés).
  void _openAccount() {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.push('/compte');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Un compte Ela est requis (écran de compte).'),
      ),
    );
  }

  Future<void> _purchase(Book book) async {
    if (_purchased) return;
    // Le paiement demande un compte (lazy registration, étape 6).
    if (ref.read(profileProvider).isAnonymous) {
      _openAccount();
      return;
    }
    setState(() => _purchased = true);
    String link;
    try {
      link = await ref
          .read(paymentServiceProvider)
          .affiliatePurchaseLink(widget.isbn);
    } catch (_) {
      if (mounted) {
        setState(() => _purchased = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le lien d’achat est momentanément indisponible.'),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() => _purchased = false);
    ElaHaptics.softTap();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('L’offrir : ${book.title} — lien affilié $link')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookAsync = ref.watch(bookByIsbnProvider(widget.isbn));
    final book = bookAsync.value ?? DemoData.byIsbnLookup(widget.isbn);

    if (book == null && bookAsync.isLoading) {
      return BookScaffold(
        appBar: BookAppBar(title: const Text('Ela')),
        body: const _CurationLoading(
          message: 'Ouverture de la fiche…',
          skeletons: 3,
        ),
      );
    }

    if (book == null) {
      return BookScaffold(
        appBar: BookAppBar(title: const Text('Ela')),
        body: BookNotice(
          title: 'Ce livre n’a pas pu être trouvé.',
          message: 'Vérifiez l’ISBN et réessayez.',
          action: OutlinedButton(
            onPressed: () => ref.invalidate(bookByIsbnProvider(widget.isbn)),
            child: const Text('Réessayer'),
          ),
        ),
      );
    }

    final inPal =
        ref
            .watch(libraryEntriesProvider)
            .value
            ?.any(
              (e) => e.isbn == book.isbn && e.section == LibrarySection.toRead,
            ) ??
        false;

    return BookScaffold(
      appBar: BookAppBar(
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final router = GoRouter.maybeOf(context);
            if (router?.canPop() ?? false) {
              router!.pop();
            } else if (router != null) {
              router.go('/tendance');
            } else {
              Navigator.maybePop(context);
            }
          },
        ),
        title: const Text('La fiche de lecture'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Partager',
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(
                  text: kIsWeb
                      ? Uri.base
                            .replace(fragment: '/livre/${book.isbn}')
                            .toString()
                      : 'Ela · ${book.title} · ISBN ${book.isbn}',
                ),
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Référence de la fiche copiée.')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: ElaSize.v24),
        child: Column(
          children: [
            _DetailHeader(
              heroTag: widget.heroTag,
              book: book,
              inPal: inPal,
              busy: _addingToPal,
              purchased: _purchased,
              onTogglePal: () => _togglePal(book: book, inPal: inPal),
              onPurchase: () => _purchase(book),
              coverKey: _coverKey,
            ),
            _TabBar(
              current: _tab,
              onSelected: (t) {
                if (t == _tab) return;
                ElaHaptics.softTap();
                setState(() => _tab = t);
              },
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: switch (_tab) {
                _DetailTab.aiPress => _AiPressTab(
                  key: const ValueKey('tab-ai'),
                  isbn: book.isbn,
                ),
                _DetailTab.web => _WebTab(
                  key: const ValueKey('tab-web'),
                  isbn: book.isbn,
                ),
                _DetailTab.community => _CommunityTab(
                  key: const ValueKey('tab-community'),
                  isbn: book.isbn,
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

String _languageName(String code) => switch (code) {
  'en' => 'anglais',
  'es' => 'espagnol',
  'de' => 'allemand',
  'it' => 'italien',
  _ => code,
};

enum _DetailTab { aiPress, web, community }

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.book,
    required this.inPal,
    required this.busy,
    required this.purchased,
    required this.onTogglePal,
    required this.onPurchase,
    this.coverKey,
    this.heroTag,
  });

  final Book book;
  final bool inPal;
  final bool busy;
  final bool purchased;
  final VoidCallback onTogglePal;
  final VoidCallback onPurchase;
  final GlobalKey? coverKey;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ElaSize.v16,
        ElaSize.v8,
        ElaSize.v16,
        ElaSize.v12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: heroTag ?? 'book-${book.isbn}',
                child: BookCover(
                  key: coverKey,
                  book: book,
                  width: ElaSize.v110,
                ),
              ),
              const SizedBox(width: ElaSize.v16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: TextStyle(
                        fontFamily: ElaType.titleFamily,
                        fontSize: ElaType.title,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: ElaSize.v4),
                    Text(
                      book.author,
                      style: TextStyle(
                        fontSize: ElaSize.v14,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (book.publisher != null) ...[
                      const SizedBox(height: ElaSize.v2),
                      Text(
                        '${book.publisher} · ${book.year}',
                        style: TextStyle(
                          fontSize: ElaSize.v13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: ElaSize.v10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ElaSize.v10,
                        vertical: ElaSize.v5,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(ElaSpace.radius),
                      ),
                      child: Text(
                        book.badgeLabel,
                        style: TextStyle(
                          fontSize: ElaSize.v12_5,
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
          const SizedBox(height: ElaSize.v10),
          Text(
            '${formatInt(book.readersCount)} lecteurs d’Ela ont lu ce livre',
            style: TextStyle(
              fontSize: ElaSize.v13,
              color: scheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          RatingSummaryCard(isbn: book.isbn),
          if (book.description != null) ...[
            const SizedBox(height: ElaSize.v14),
            Text(
              book.description!,
              style: const TextStyle(
                fontSize: ElaSize.v14_5,
                height: ElaSize.v1_55,
              ),
            ),
          ],
          const SizedBox(height: ElaSize.v16),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: busy ? null : onTogglePal,
                  icon: busy
                      ? const SizedBox(
                          width: ElaSize.v16,
                          height: ElaSize.v16,
                          child: CircularProgressIndicator(
                            strokeWidth: ElaSize.v2,
                          ),
                        )
                      : Icon(
                          inPal
                              ? Icons.check_circle
                              : Icons.bookmark_add_outlined,
                        ),
                  label: Text(inPal ? 'Dans votre PAL' : 'Ajouter à la PAL'),
                ),
              ),
              const SizedBox(width: ElaSize.v12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: purchased ? null : onPurchase,
                  icon: purchased
                      ? const SizedBox(
                          width: ElaSize.v16,
                          height: ElaSize.v16,
                          child: CircularProgressIndicator(
                            strokeWidth: ElaSize.v2,
                          ),
                        )
                      : const Icon(Icons.storefront_outlined),
                  label: Text(purchased ? 'Ouverture…' : 'Acheter'),
                ),
              ),
            ],
          ),
          if (book.priceEur != null) const SizedBox(height: ElaSize.v10),
          if (book.priceEur != null)
            Padding(
              padding: const EdgeInsets.only(left: ElaSize.v2),
              child: Text(
                'À partir de ${formatPrice(book.priceEur)} '
                '(${formatPrice(book.usedPriceEur)} en occasion)',
                style: TextStyle(
                  fontSize: ElaSize.v13,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.current, required this.onSelected});

  final _DetailTab current;
  final ValueChanged<_DetailTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ElaSize.v8),
      child: Row(
        children: [
          for (final tab in _DetailTab.values)
            Expanded(
              child: _TabButton(
                tab: tab,
                active: current == tab,
                onTap: () => onSelected(tab),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.active,
    required this.onTap,
  });

  final _DetailTab tab;
  final bool active;
  final VoidCallback onTap;

  String get _label => switch (tab) {
    _DetailTab.aiPress => 'Synthèse IA & Presse',
    _DetailTab.web => 'Le Web',
    _DetailTab.community => 'La Communauté',
  };

  @override
  Widget build(BuildContext context) {
    return BookmarkTab(label: _label, active: active, onTap: onTap);
  }
}

/// État de chargement de la curation IA : texte qui « respire » +
/// squelettes encre. Jamais de spinner.
class _CurationLoading extends StatelessWidget {
  const _CurationLoading({this.message, this.skeletons = 5});

  final String? message;
  final int skeletons;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(ElaSize.v16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BreathingText(
              message ?? 'Ela lit, trie et cuit vos avis au feu de bois…',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: ElaSize.v15,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: ElaSize.v18),
            for (var i = 0; i < skeletons; i++) ...[
              if (i > 0) const SizedBox(height: ElaSize.v12),
              Container(
                decoration: BoxDecoration(
                  color: i == 0
                      ? scheme.primaryContainer.withValues(alpha: 0.5)
                      : null,
                  borderRadius: BorderRadius.circular(ElaSpace.radius),
                  border: Border.all(
                    color: scheme.outline.withValues(alpha: 0.35),
                  ),
                ),
                padding: const EdgeInsets.all(ElaSize.v14),
                child: Column(
                  children: [
                    InkSkeletonBlock(width: ElaSize.v120, height: ElaSize.v10),
                    const SizedBox(height: ElaSize.v8),
                    const InkSkeletonBlock(height: ElaSize.v13),
                    const SizedBox(height: ElaSize.v6),
                    const InkSkeletonBlock(
                      width: ElaSize.v220,
                      height: ElaSize.v13,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.summary,
    this.aiTokens,
    this.truncated = false,
  });

  final String summary;
  final int? aiTokens;

  /// Version gratuite : la synthèse est recoupée (débloquée par 1 jeton).
  final bool truncated;

  String get _shown {
    if (!truncated) return summary;
    final cut = summary.length > 220 ? summary.substring(0, 220) : summary;
    final dot = cut.lastIndexOf('. ');
    if (dot > 80) return '${cut.substring(0, dot + 1)}…';
    return '$cut…';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PageCard(
      child: Padding(
        padding: const EdgeInsets.all(ElaSize.v16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: ElaSize.v8,
              runSpacing: ElaSize.v8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  color: scheme.secondary,
                  size: ElaSize.v20,
                ),
                Text(
                  'Synthèse Ela',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                if (aiTokens != null)
                  Chip(label: Text('✦ $aiTokens jetons IA ce mois-ci')),
              ],
            ),
            const SizedBox(height: ElaSize.v10),
            DropCapText(_shown),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label, {this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: ElaSize.v20, bottom: ElaSize.v10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: ElaType.titleFamily,
                fontSize: ElaSize.v16,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Freemium (étape 7) : la fiche est « complète » si on est Premium ou
/// si un jeton IA a été dépensé pour ce livre. Sinon : 1 avis presse +
/// 2 avis web visibles, le reste flouté avec invitation.
bool _isFullAccess(WidgetRef ref, String isbn, Entitlement? entitlement) =>
    entitlement != null &&
    (entitlement.isPremium || ref.watch(unlockedBooksProvider).contains(isbn));

class _AiPressTab extends ConsumerWidget {
  const _AiPressTab({super.key, required this.isbn});

  final String isbn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final curation = ref.watch(curationProvider(isbn));
    final entitlement = ref.watch(entitlementStreamProvider).value;
    final full = _isFullAccess(ref, isbn, entitlement);

    return curation.when(
      loading: () => const _CurationLoading(),
      error: (e, _) => _SoftNotice(
        'La curation IA ne couvre (encore) pas ce titre. '
        'La communauté en a peut-être parlé dans l’onglet suivant.',
        onRetry: () => ref.invalidate(curationProvider(isbn)),
      ),
      data: (c) => _TabScroll(
        children: [
          _SummaryCard(
            summary: c.summary,
            aiTokens: entitlement?.aiTokens,
            truncated: !full,
          ),
          _SectionHeader('La presse en a parlé'),
          for (var i = 0; i < c.press.length; i++)
            full || i < 1
                ? _ReviewCard(review: c.press[i])
                : const _BlurredReview(),
          if (entitlement != null && !entitlement.isPremium && !full)
            _TokenUnlockCard(isbn: isbn),
        ],
      ),
    );
  }
}

class _WebTab extends ConsumerWidget {
  const _WebTab({super.key, required this.isbn});

  final String isbn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final curation = ref.watch(curationProvider(isbn));
    final entitlement = ref.watch(entitlementStreamProvider).value;
    final full = _isFullAccess(ref, isbn, entitlement);

    return curation.when(
      loading: () => const _CurationLoading(
        message: 'Ela fouille les pages du web, blog après blog…',
      ),
      error: (e, _) => _SoftNotice(
        'Les avis du web ne sont pas disponibles pour ce titre.',
        onRetry: () => ref.invalidate(curationProvider(isbn)),
      ),
      data: (c) => _TabScroll(
        children: [
          _SectionHeader('${c.web.length} avis du web'),
          for (var i = 0; i < c.web.length; i++)
            full || i < 2
                ? _ReviewCard(
                    review: c.web[i],
                    translated: full && c.web[i].language != 'fr',
                  )
                : const _BlurredReview(),
          if (entitlement != null && !entitlement.isPremium && !full)
            _TokenUnlockCard(isbn: isbn),
        ],
      ),
    );
  }
}

/// Avis flouté (freemium) : forme d'une carte d'avis, contenu illisible,
/// invitation Premium au centre.
class _BlurredReview extends StatelessWidget {
  const _BlurredReview();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PageCard(
      child: Padding(
        padding: const EdgeInsets.all(ElaSize.v14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // « Flouté » en opacité fantôme : les contours restent, les
            // mots non. (Pas de filter en 3.35 : léger et lisible.)
            Opacity(
              opacity: 0.13,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Lecteur d’Ela  ·  blog  ·  12 mai 2026'),
                  const SizedBox(height: ElaSize.v6),
                  const Text('« Un titre d’avis qui ne dit pas où on va »'),
                  const SizedBox(height: ElaSize.v4),
                  const Text(
                    'Ceci est l’aperçu d’un avis. Le texte complet n’est '
                    'pas lisible dans la version gratuite — les contours '
                    'restent, les mots non. L’éditeur a eu l’idée, la mise '
                    'en page a fait le reste, et la lecture a continué '
                    'seule, longtemps, dans un train.',
                    style: TextStyle(
                      fontSize: ElaSize.v13_5,
                      height: ElaSize.v1_5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ElaSize.v10),
            Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  size: ElaSize.v15,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: ElaSize.v6),
                Text(
                  'Avis Premium',
                  style: TextStyle(
                    fontSize: ElaSize.v12_5,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
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

/// Carte « dépenser 1 jeton IA » pour débloquer la fiche complète.
class _TokenUnlockCard extends ConsumerStatefulWidget {
  const _TokenUnlockCard({required this.isbn});

  final String isbn;

  @override
  ConsumerState<_TokenUnlockCard> createState() => _TokenUnlockCardState();
}

class _TokenUnlockCardState extends ConsumerState<_TokenUnlockCard> {
  bool _spending = false;

  Future<void> _unlock() async {
    if (_spending) return;
    setState(() => _spending = true);
    bool ok;
    try {
      ok = await ref.read(paymentServiceProvider).spendAiToken();
    } catch (_) {
      if (mounted) {
        setState(() => _spending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le déblocage a été interrompu. Réessayez.'),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() => _spending = false);
    if (ok) {
      ref.read(unlockedBooksProvider.notifier).unlock(widget.isbn);
      ElaHaptics.heartbeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entitlement = ref.watch(entitlementStreamProvider).value;
    final tokens = entitlement?.aiTokens ?? 0;

    if (tokens <= 0) {
      return Padding(
        padding: const EdgeInsets.only(top: ElaSize.v12),
        child: PremiumUnlockCard(
          message:
              'Plus de jetons IA ce mois-ci. Premium inclut 3 jetons par '
              'mois, et ouvre toutes les fiches sans en dépenser.',
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: ElaSize.v12),
      child: PageCard(
        child: Padding(
          padding: const EdgeInsets.all(ElaSize.v14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: ElaSize.v8,
                runSpacing: ElaSize.v8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Débloquer la fiche complète',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Chip(label: Text('✦ $tokens jetons ce mois-ci')),
                ],
              ),
              const SizedBox(height: ElaSize.v8),
              Text(
                '1 jeton IA débloque la synthèse complète et tous les avis '
                'de cette fiche.',
                style: TextStyle(
                  fontSize: ElaSize.v12_5,
                  height: ElaSize.v1_45,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: ElaSize.v12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: _spending ? null : _unlock,
                  child: _spending
                      ? BreathingText(
                          'Déblocage…',
                          style: TextStyle(
                            color: scheme.onSecondaryContainer,
                            fontSize: ElaSize.v13_5,
                          ),
                        )
                      : const Text('Débloquer — 1 jeton'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunityTab extends ConsumerWidget {
  const _CommunityTab({super.key, required this.isbn});

  final String isbn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final reviews = ref.watch(communityReviewsProvider(isbn));
    final profile = ref.watch(profileProvider);

    return reviews.when(
      loading: () => const _CurationLoading(
        message: 'Les lecteurs d’Ela partagent leur avis…',
      ),
      error: (e, _) =>
          const _SoftNotice('Impossible de charger les avis de la communauté.'),
      data: (list) => _TabScroll(
        children: [
          _SectionHeader(
            'La communauté d’Ela',
            trailing: OutlinedButton.icon(
              onPressed: () => _openWriteSheet(context, ref),
              icon: const Icon(Icons.edit, size: ElaSize.v16),
              label: const Text('Écrire un avis'),
            ),
          ),
          if (list.isEmpty)
            const BookNotice(
              title: 'La première voix sera peut-être la vôtre.',
              message: 'Aucun avis dans cette page pour le moment.',
            ),
          for (final r in list)
            _ReviewCard(
              review: r,
              reportable: true,
              onReport: () => _report(context, ref, r),
            ),
          const SizedBox(height: ElaSize.v8),
          if (profile.isAnonymous)
            Padding(
              padding: const EdgeInsets.only(bottom: ElaSize.v8),
              child: Text(
                'Votre avis rejoindra la page du livre dès que vous '
                'publierez sous votre compte Ela.',
                style: TextStyle(
                  fontSize: ElaSize.v12_5,
                  color: scheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openWriteSheet(BuildContext context, WidgetRef ref) {
    ElaHaptics.softTap();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ElaColors.transparent,
      builder: (sheetContext) => _WriteReviewSheet(isbn: isbn),
    );
  }

  Future<void> _report(
    BuildContext context,
    WidgetRef ref,
    Review review,
  ) async {
    ElaHaptics.softTap();
    await ref.read(reviewServiceProvider).reportReview(review.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Signalement bien reçu. Merci de veiller sur Ela avec nous.',
        ),
      ),
    );
  }
}

class _TabScroll extends StatelessWidget {
  const _TabScroll({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ElaSize.v16,
        ElaSize.v4,
        ElaSize.v16,
        ElaSize.v8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final child in children) ...[
            if (child is _ReviewCard) const SizedBox(height: ElaSize.v12),
            child,
          ],
        ],
      ),
    );
  }
}

class _SoftNotice extends StatelessWidget {
  const _SoftNotice(this.message, {this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => BookNotice(
    title: message,
    action: onRetry == null
        ? null
        : OutlinedButton(onPressed: onRetry, child: const Text('Réessayer')),
  );
}

class _ReviewCard extends StatefulWidget {
  const _ReviewCard({
    required this.review,
    this.reportable = false,
    this.onReport,
    this.translated = false,
  });

  final Review review;
  final bool reportable;
  final VoidCallback? onReport;

  /// Avis étranger traduit par Ela (fonction Premium, simulée).
  final bool translated;

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = widget.review;
    final meta = <String>[
      r.author,
      if (r.outlet != null && r.outlet != r.author) r.outlet!,
      shortDate(r.publishedAt),
    ].join('  ·  ');

    return PageCard(
      key: ValueKey('review-${r.id}'),
      child: Padding(
        padding: const EdgeInsets.all(ElaSize.v14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    meta,
                    style: TextStyle(
                      fontSize: ElaSize.v12_5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (widget.reportable)
                  IconButton(
                    tooltip: 'Signaler cet avis',
                    onPressed: widget.onReport,
                    icon: const Icon(Icons.flag_outlined),
                  ),
              ],
            ),
            if (r.rating != null) RatingStars(value: r.rating!),
            if (widget.translated) ...[
              const SizedBox(height: ElaSize.v6),
              Row(
                children: [
                  Icon(
                    Icons.translate,
                    size: ElaSize.v14,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: ElaSize.v5),
                  Text(
                    'Traduit par Ela (${_languageName(widget.review.language)})',
                    style: TextStyle(
                      fontSize: ElaSize.v11_5,
                      fontStyle: FontStyle.italic,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: ElaSize.v6),
            Text(
              '« ${r.title} »',
              style: TextStyle(
                fontFamily: ElaType.titleFamily,
                fontSize: ElaSize.v14_5,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: ElaSize.v4),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              child: Text(
                r.text,
                maxLines: _expanded || r.text.length <= 160 ? null : 4,
                overflow: _expanded || r.text.length <= 160
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: ElaSize.v13_5,
                  height: ElaSize.v1_5,
                ),
              ),
            ),
            if (r.text.length > 160)
              Padding(
                padding: const EdgeInsets.only(top: ElaSize.v4),
                child: TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(_expanded ? 'Réduire' : 'Lire la suite'),
                ),
              ),
            const SizedBox(height: ElaSize.v2),
            Row(
              children: [
                Icon(
                  Icons.favorite_outline,
                  size: ElaSize.v14,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: ElaSize.v5),
                Text(
                  formatInt(r.likes),
                  style: TextStyle(
                    fontSize: ElaSize.v12,
                    color: scheme.onSurfaceVariant,
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

/// Feuille « Écrire un avis ». Lazy registration : un compte Ela est
/// requis pour publier (connecté à l'étape 6).
class _WriteReviewSheet extends ConsumerWidget {
  const _WriteReviewSheet({required this.isbn});
  final String isbn;
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(profileProvider).isAnonymous
      ? SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.viewInsetsOf(context).bottom + 24,
            ),
            child: _AnonymousPrompt(),
          ),
        )
      : RatingEditor(isbn: isbn);
}

/// Invite à créer un compte avant de publier (lazy registration).
class _AnonymousPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.person,
          size: ElaSize.v40,
          color: Theme.of(context).colorScheme.secondary,
        ),
        const SizedBox(height: ElaSize.v12),
        Text(
          'Votre avis mérite un nom',
          style: TextStyle(
            fontFamily: ElaType.titleFamily,
            fontSize: ElaSize.v18,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: ElaSize.v6),
        Text(
          'Publier un avis sur Ela demande un compte — e-mail, Google ou '
          'Apple, en une minute, sans engagement.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: ElaSize.v13_5,
            height: ElaSize.v1_5,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: ElaSize.v16),
        FilledButton(
          onPressed: () {
            final router = GoRouter.maybeOf(context);
            // On quitte la feuille, puis on ouvre l'écran de compte.
            Navigator.of(context).pop();
            if (router != null) {
              router.push('/compte');
            }
          },
          child: const Text('Créer mon compte'),
        ),
      ],
    );
  }
}
