import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/animations.dart';
import '../../core/format.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/widgets/book_cover.dart';
import '../../data/fake/demo_books.dart';
import '../../data/models/book.dart';
import '../../data/models/library_entry.dart';
import '../../data/models/review.dart';
import '../../providers.dart';
import '../library/fly_to_library.dart';

/// Fiche livre (étape 3) : en-tête + 3 onglets en fondu doux —
/// Synthèse IA & Presse / Le Web / La Communauté — + PAL / Acheter.
class BookDetailScreen extends ConsumerStatefulWidget {
  const BookDetailScreen({super.key, required this.isbn});

  final String isbn;

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
    ref.read(libraryServiceProvider).addHistory(widget.isbn);
  }

  Future<void> _togglePal({required Book book, required bool inPal}) async {
    final lib = ref.read(libraryServiceProvider);
    if (inPal) {
      await lib.removeEntry(widget.isbn, LibrarySection.toRead);
      if (mounted) {
        ElaHaptics.softTap();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Retiré de votre Pile à Lire.')),
        );
      }
      return;
    }
    if (_addingToPal) return;
    setState(() => _addingToPal = true);
    // On capture la position de la couverture avant le vol.
    final from = _coverRect();
    final target = _libraryTargetRect();
    await lib.addToRead(widget.isbn);
    if (!mounted) return;
    setState(() => _addingToPal = false);
    ElaHaptics.heartbeat();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ajouté à votre Pile à Lire.')),
    );
    // La couverture « lévite » vers l'icône Bibliothèque de la barre.
    if (from != null) {
      FlyToLibrary.fly(context, book: book, from: from, to: target);
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
    final center = Offset(size.width * 0.625, size.height - 44);
    return Rect.fromCenter(center: center, width: 34, height: 48);
  }

  Future<void> _purchase(Book book) async {
    if (_purchased) return;
    setState(() => _purchased = true);
    final link =
        await ref.read(paymentServiceProvider).affiliatePurchaseLink(widget.isbn);
    if (!mounted) return;
    setState(() => _purchased = false);
    ElaHaptics.softTap();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('L’offrir : ${book.title} — lien affilié $link'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bookAsync = ref.watch(bookByIsbnProvider(widget.isbn));
    final book = bookAsync.value ?? DemoData.byIsbnLookup(widget.isbn);

    if (book == null && bookAsync.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ela')),
        body: const _CurationLoading(
            message: 'Ouverture de la fiche…', skeletons: 3),
      );
    }

    if (book == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ela')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Text(
              'Ce livre n’a pas pu être trouvé.\nVérifiez l’ISBN et réessayez.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.5, color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      );
    }

    final inPal = ref.watch(libraryEntriesProvider).value
            ?.any((e) => e.isbn == book.isbn && e.section == LibrarySection.toRead) ??
        false;

    return Scaffold(
      appBar: AppBar(
        title: Text(book.title, overflow: TextOverflow.ellipsis),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
            _DetailHeader(
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
                    key: const ValueKey('tab-ai'), isbn: book.isbn),
                _DetailTab.web => _WebTab(
                    key: const ValueKey('tab-web'), isbn: book.isbn),
                _DetailTab.community => _CommunityTab(
                    key: const ValueKey('tab-community'), isbn: book.isbn),
              },
            ),
          ],
        ),
      ),
    );
  }
}

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
  });

  final Book book;
  final bool inPal;
  final bool busy;
  final bool purchased;
  final VoidCallback onTogglePal;
  final VoidCallback onPurchase;
  final GlobalKey? coverKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BookCover(key: coverKey, book: book, width: 110),
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
          const SizedBox(height: 10),
          Text(
            '${formatInt(book.readersCount)} lecteurs d’Ela ont lu ce livre',
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (book.description != null) ...[
            const SizedBox(height: 14),
            Text(
              book.description!,
              style: const TextStyle(fontSize: 14.5, height: 1.55),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: busy ? null : onTogglePal,
                  icon: busy
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(inPal ? Icons.check_circle : Icons.bookmark_add_outlined),
                  label: Text(inPal ? 'Dans votre PAL' : 'Ajouter à la PAL'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: purchased ? null : onPurchase,
                  icon: purchased
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.storefront_outlined),
                  label: Text(purchased ? 'Ouverture…' : 'Acheter'),
                ),
              ),
            ],
          ),
          if (book.priceEur != null)
            const SizedBox(height: 10),
          if (book.priceEur != null)
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                'À partir de ${formatPrice(book.priceEur)} '
                '(${formatPrice(book.usedPriceEur)} en occasion)',
                style: TextStyle(
                  fontSize: 13,
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
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          for (final tab in _DetailTab.values)
            Expanded(child: _TabButton(tab: tab, active: current == tab,
                onTap: () => onSelected(tab))),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.tab, required this.active, required this.onTap});

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
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Text(
              _label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? scheme.onSurface : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              height: 3,
              width: 34,
              decoration: BoxDecoration(
                color: active ? ElaColors.gold : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BreathingText(
            message ?? 'Ela lit, trie et cuit vos avis au feu de bois…',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 15,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < skeletons; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: i == 0
                    ? scheme.primaryContainer.withValues(alpha: 0.5)
                    : null,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.35),
                ),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  InkSkeletonBlock(width: 120, height: 10),
                  const SizedBox(height: 8),
                  const InkSkeletonBlock(height: 13),
                  const SizedBox(height: 6),
                  const InkSkeletonBlock(width: 220, height: 13),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary, this.aiTokens});

  final String summary;
  final int? aiTokens;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: ElaColors.gold, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Synthèse Ela',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (aiTokens != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '✦ $aiTokens jetons IA ce mois-ci',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              summary,
              style: const TextStyle(fontSize: 14.5, height: 1.6),
            ),
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
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Lora',
                fontSize: 16,
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

class _AiPressTab extends ConsumerWidget {
  const _AiPressTab({super.key, required this.isbn});

  final String isbn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final curation = ref.watch(curationProvider(isbn));
    final entitlement = ref.watch(entitlementProvider).value;

    return curation.when(
      loading: () => const _CurationLoading(),
      error: (e, _) => _SoftNotice(
        'La curation IA ne couvre (encore) pas ce titre. '
        'La communauté en a peut-être parlé dans l’onglet suivant.',
      ),
      data: (c) => _TabScroll(
        children: [
          _SummaryCard(summary: c.summary, aiTokens: entitlement?.aiTokens),
          _SectionHeader('La presse en a parlé'),
          for (final r in c.press) _ReviewCard(review: r),
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

    return curation.when(
      loading: () => const _CurationLoading(
          message: 'Ela fouille les pages du web, blog après blog…'),
      error: (e, _) => const _SoftNotice(
          'Les avis du web ne sont pas disponibles pour ce titre.'),
      data: (c) => _TabScroll(
        children: [
          _SectionHeader('${c.web.length} avis du web'),
          for (final r in c.web) _ReviewCard(review: r),
        ],
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
          message: 'Les lecteurs d’Ela partagent leur avis…'),
      error: (e, _) => const _SoftNotice(
          'Impossible de charger les avis de la communauté.'),
      data: (list) => _TabScroll(
        children: [
          _SectionHeader(
            'La communauté d’Ela',
            trailing: OutlinedButton.icon(
              onPressed: () => _openWriteSheet(context, ref),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Écrire un avis'),
            ),
          ),
          for (final r in list)
            _ReviewCard(
              review: r,
              reportable: true,
              onReport: () => _report(context, ref, r),
            ),
          const SizedBox(height: 8),
          if (profile.isAnonymous)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Votre avis rejoindra la page du livre dès que vous '
                'publierez sous votre compte Ela.',
                style: TextStyle(
                  fontSize: 12.5,
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
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _WriteReviewSheet(isbn: isbn),
    );
  }

  Future<void> _report(
      BuildContext context, WidgetRef ref, Review review) async {
    ElaHaptics.softTap();
    await ref.read(reviewServiceProvider).reportReview(review.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Signalement bien reçu. Merci de veiller sur Ela avec nous.'),
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final child in children) ...[
            if (child is _ReviewCard) const SizedBox(height: 12),
            child,
          ],
        ],
      ),
    );
  }
}

class _SoftNotice extends StatelessWidget {
  const _SoftNotice(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: scheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}

/// Carte d'avis (presse / web / communauté).
class _ReviewCard extends StatefulWidget {
  const _ReviewCard({
    required this.review,
    this.reportable = false,
    this.onReport,
  });

  final Review review;
  final bool reportable;
  final VoidCallback? onReport;

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

    return Card(
      key: ValueKey('review-${r.id}'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    meta,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (widget.reportable)
                  InkWell(
                    onTap: widget.onReport,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.flag_outlined,
                          size: 15, color: scheme.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '« ${r.title} »',
              style: TextStyle(
                fontFamily: 'Lora',
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              child: Text(
                r.text,
                maxLines: _expanded ? null : 4,
                overflow:
                    _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.5, height: 1.5),
              ),
            ),
            if (r.text.length > 160)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(_expanded ? 'Réduire' : 'Lire la suite'),
                ),
              ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.favorite_outline,
                    size: 14, color: scheme.onSurfaceVariant),
                const SizedBox(width: 5),
                Text(
                  formatInt(r.likes),
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
    );
  }
}

/// Feuille « Écrire un avis ». Lazy registration : un compte Ela est
/// requis pour publier (connecté à l'étape 6).
class _WriteReviewSheet extends ConsumerStatefulWidget {
  const _WriteReviewSheet({required this.isbn});

  final String isbn;

  @override
  ConsumerState<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends ConsumerState<_WriteReviewSheet> {
  final _titleController = TextEditingController();
  final _textController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isbn = widget.isbn;
    final title = _titleController.text.trim();
    final text = _textController.text.trim();
    if (title.isEmpty || text.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    final profile = ref.read(profileProvider);
    final review = Review(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      isbn: isbn,
      source: ReviewSource.community,
      author: profile.displayNameOrEmail,
      title: title,
      text: text,
      publishedAt: DateTime.now(),
      likes: 0,
    );
    final saved = await ref.read(reviewServiceProvider).addCommunityReview(review);
    if (!mounted) return;
    setState(() => _submitting = false);
    ref.invalidate(communityReviewsProvider(isbn));
    Navigator.of(context).pop();
    ElaHaptics.heartbeat();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Merci ! « ${saved.title} » rejoint la page du livre.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final profile = ref.watch(profileProvider);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: profile.isAnonymous
          ? _AnonymousPrompt()
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Votre avis',
                  style: TextStyle(
                    fontFamily: 'Lora',
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Publié sous le nom « ${profile.displayNameOrEmail} ».',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  maxLength: 90,
                  decoration: const InputDecoration(
                    hintText: 'Un titre pour votre avis',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _textController,
                  maxLength: 600,
                  maxLines: 4,
                  minLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Ce livre vous a fait quoi ?',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send, size: 17),
                  label: Text(_submitting ? 'Publication…' : 'Publier'),
                ),
              ],
            ),
    );
  }
}

/// Invite à créer un compte avant de publier (lazy registration —
/// navigation branchée à l'étape 6).
class _AnonymousPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.person, size: 40, color: ElaColors.gold),
        const SizedBox(height: 12),
        Text(
          'Votre avis mérite un nom',
          style: TextStyle(
            fontFamily: 'Lora',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Publier un avis sur Ela demande un compte — e-mail, Google ou '
          'Apple, en une minute, sans engagement.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.5,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('La création de compte arrive très bientôt.'),
              ),
            );
          },
          child: const Text('Créer mon compte'),
        ),
      ],
    );
  }
}
