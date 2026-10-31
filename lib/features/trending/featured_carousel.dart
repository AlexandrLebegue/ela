import '../ratings/rating_widgets.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import '../../core/flags.dart';
import '../../core/widgets/cover_palette.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/widgets/book_cover.dart';
import '../../data/models/book.dart';
import '../../data/models/library_entry.dart';
import '../../providers.dart';

String trendingHeroTag(String shelf, Book book) =>
    'tendance-$shelf-${book.isbn}';

void openTrendingBook(BuildContext context, String shelf, Book book) {
  context.push('/livre/${book.isbn}', extra: trendingHeroTag(shelf, book));
}

String _hook(Book book) => switch (book.isbn) {
  '9782070667918' => 'Un tout petit monde. Une immense histoire d’amitié.',
  '9781538742578' => 'Derrière cette porte, personne n’est innocent.',
  '9782755692766' => 'Un manuscrit. Un secret. Encore un chapitre…',
  '9782081641624' => 'Et si le vrai trésor était le chemin ?',
  '9781501174827' => 'Sept mariages. Une seule grande histoire d’amour.',
  '9782070409236' => 'Une vie à sauver. Tout un monde à changer.',
  _ => switch (book.genre) {
    'Thrillers' => 'La lecture qui vous fera oublier l’heure.',
    'Fantasy' => 'Ouvrez la porte d’un autre monde.',
    'Classiques' => 'Les belles histoires n’ont pas de dernière fois.',
    _ => 'Quelques pages suffisent pour être ailleurs.',
  },
};

/// Seul le ruban de couvertures se reconstruit pendant le geste. Le papier,
/// les illustrations et les rayons restent isolés de l'animation 3D.
class FeaturedCarousel extends ConsumerStatefulWidget {
  const FeaturedCarousel({
    super.key,
    required this.books,
    required this.visible,
  });
  final List<Book> books;
  final bool visible;

  @override
  ConsumerState<FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends ConsumerState<FeaturedCarousel>
    with WidgetsBindingObserver {
  late final _pages = PageController(
    viewportFraction: .66,
    initialPage: _loop ? 1 : 0,
  );
  bool get _loop => widget.books.length > 1;
  Timer? _auto;
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;
  final _tints = <String, Color>{};
  String? _resolvingIsbn;
  int _index = 0;
  final _pointers = <int>{};
  bool _focused = false;
  bool _foreground = true;
  bool _saving = false;
  bool _paused = false;
  bool _normalizing = false;

  bool get _reduced =>
      MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.accessibleNavigationOf(context);
  bool get _canPlay =>
      mounted &&
      !_reduced &&
      !_paused &&
      !_saving &&
      !_focused &&
      _pointers.isEmpty &&
      _foreground &&
      widget.visible &&
      TickerMode.of(context) &&
      (ModalRoute.of(context)?.isCurrent ?? true) &&
      widget.books.length > 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedule();
    _resolveTint();
  }

  void _resolveTint() {
    final book = widget.books[_index];
    if (isRunningUnderFlutterTest ||
        book.coverUrl == null ||
        _resolvingIsbn == book.isbn ||
        _tints.containsKey(book.isbn)) {
      return;
    }
    _clearImageListener();
    _resolvingIsbn = book.isbn;
    _imageStream = CachedNetworkImageProvider(
      book.coverUrl!,
    ).resolve(createLocalImageConfiguration(context));
    _imageListener = ImageStreamListener((info, synchronousCall) async {
      final image = info.image.clone();
      info.dispose();
      _clearImageListener();
      try {
        final tint = await paletteFromCover(image);
        if (mounted && tint != null) {
          setState(() => _tints[book.isbn] = tint);
        }
      } catch (_) {
        // Le repli illustré garde sa palette si le décodage échoue.
      } finally {
        image.dispose();
      }
    }, onError: (Object error, StackTrace? trace) => _clearImageListener());
    _imageStream!.addListener(_imageListener!);
  }

  void _clearImageListener() {
    if (_imageListener != null) _imageStream?.removeListener(_imageListener!);
    _imageListener = null;
    _imageStream = null;
  }

  @override
  void didUpdateWidget(FeaturedCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _schedule();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _schedule();
  }

  void _schedule({bool afterTouch = false}) {
    _auto?.cancel();
    if (!_canPlay) return;
    _auto = Timer(Duration(seconds: afterTouch ? 12 : 7), () {
      if (!_canPlay || !_pages.hasClients) return;
      _go((_index + 1) % widget.books.length);
    });
  }

  void _go(int index) {
    if (_reduced) {
      _pages.jumpToPage(index + (_loop ? 1 : 0));
    } else {
      _pages.animateToPage(
        index + (_loop ? 1 : 0),
        duration: const Duration(milliseconds: 850),
        curve: Curves.easeInOutCubic,
      );
    }
    _schedule(afterTouch: true);
  }

  Future<void> _add(Book book) async {
    if (_saving) return;
    setState(() => _saving = true);
    _auto?.cancel();
    try {
      await ref.read(libraryServiceProvider).addToRead(book.isbn);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${book.title} rejoint votre Pile à lire.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('L’ajout a échoué. Réessayez.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        _schedule(afterTouch: true);
      }
    }
  }

  @override
  void dispose() {
    _auto?.cancel();
    _clearImageListener();
    _pages.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final book = widget.books[_index];
    final inPal =
        ref
            .watch(libraryEntriesProvider)
            .value
            ?.any(
              (e) => e.isbn == book.isbn && e.section == LibrarySection.toRead,
            ) ??
        false;
    final duration = _reduced
        ? Duration.zero
        : const Duration(milliseconds: 500);
    return Focus(
      includeSemantics: false,
      canRequestFocus: false,
      onFocusChange: (focused) {
        _focused = focused;
        _schedule(afterTouch: true);
      },
      child: Listener(
        onPointerDown: (event) {
          _pointers.add(event.pointer);
          _auto?.cancel();
        },
        onPointerUp: (event) {
          _pointers.remove(event.pointer);
          _schedule(afterTouch: true);
        },
        onPointerCancel: (event) {
          _pointers.remove(event.pointer);
          _schedule(afterTouch: true);
        },
        child: AnimatedContainer(
          key: const ValueKey('trending-hero'),
          duration: duration,
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -.35),
              radius: .95,
              colors: [
                (_tints[book.isbn] ?? bookCoverColor(book)).withValues(
                  alpha: theme.brightness == Brightness.dark ? .40 : .20,
                ),
                scheme.surface.withValues(alpha: 0),
              ],
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'À LA UNE DE VOS ENVIES',
                        style: theme.textTheme.labelSmall?.copyWith(
                          letterSpacing: 2,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                    if (!_reduced)
                      IconButton(
                        tooltip: _paused
                            ? 'Reprendre le carrousel'
                            : 'Mettre le carrousel en pause',
                        onPressed: () {
                          setState(() => _paused = !_paused);
                          _schedule();
                        },
                        iconSize: 18,
                        icon: Icon(
                          _paused
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                        ),
                      ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final coverWidth = constraints.maxWidth * .62;
                    return SizedBox(
                      height: coverWidth * 1.5 + 24,
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollStartNotification) {
                            _auto?.cancel();
                          }
                          if (notification is ScrollEndNotification) {
                            if (_loop &&
                                !_normalizing &&
                                (_pages.page == 0 ||
                                    _pages.page == widget.books.length + 1)) {
                              _normalizing = true;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted && _pages.hasClients) {
                                  _pages.jumpToPage(_index + 1);
                                }
                                _normalizing = false;
                              });
                            }
                            _schedule(afterTouch: true);
                          }
                          return false;
                        },
                        child: PageView.builder(
                          key: const ValueKey('featured-pages'),
                          controller: _pages,
                          itemCount: widget.books.length + (_loop ? 2 : 0),
                          onPageChanged: (index) {
                            setState(
                              () => _index =
                                  (index - (_loop ? 1 : 0)) %
                                  widget.books.length,
                            );
                            _resolveTint();
                            _schedule();
                          },
                          itemBuilder: (context, index) {
                            final logicalIndex =
                                (index - (_loop ? 1 : 0)) % widget.books.length;
                            final item = widget.books[logicalIndex];
                            final sentinel =
                                _loop &&
                                (index == 0 ||
                                    index == widget.books.length + 1);
                            final cover = RepaintBoundary(
                              child: Hero(
                                tag: sentinel
                                    ? '${trendingHeroTag('hero', item)}-sentinel-$index'
                                    : trendingHeroTag('hero', item),
                                child: BookCover(book: item, width: coverWidth),
                              ),
                            );
                            return AnimatedBuilder(
                              animation: _pages,
                              child: cover,
                              builder: (context, child) {
                                final page =
                                    _pages.hasClients &&
                                        _pages.position.hasContentDimensions
                                    ? _pages.page ?? 0
                                    : (_index + (_loop ? 1 : 0)).toDouble();
                                final delta = (index - page).clamp(-1.0, 1.0);
                                final distance = delta.abs();
                                return Center(
                                  child: Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()
                                      ..setEntry(3, 2, .0014)
                                      ..rotateY(_reduced ? 0 : -delta * .38)
                                      ..scaleByDouble(
                                        1 - distance * .20,
                                        1 - distance * .20,
                                        1,
                                        1,
                                      ),
                                    child: Opacity(
                                      opacity: 1 - distance * .48,
                                      child: Semantics(
                                        container: true,
                                        onTap: () => logicalIndex == _index
                                            ? openTrendingBook(
                                                context,
                                                'hero',
                                                item,
                                              )
                                            : _go(logicalIndex),
                                        button: true,
                                        label:
                                            'Ouvrir ${item.title}, ${item.author}',
                                        excludeSemantics: true,
                                        child: InkWell(
                                          onTap: () {
                                            if (logicalIndex == _index) {
                                              _auto?.cancel();
                                              openTrendingBook(
                                                context,
                                                'hero',
                                                item,
                                              );
                                            } else {
                                              _go(logicalIndex);
                                            }
                                          },
                                          child: child,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                child: AnimatedSwitcher(
                  duration: duration,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, .06),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Column(
                    key: ValueKey(book.isbn),
                    children: [
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _index == 0
                              ? 'N°1  ·  LE CHOIX DES LECTEURS'
                              : (_index.isOdd
                                    ? 'EN HAUSSE  ·  À DÉCOUVRIR'
                                    : 'COUP DE CŒUR  ·  ELA'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.primary,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        book.title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        book.author,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      BookRatingLabel(isbn: book.isbn),
                      const SizedBox(height: 9),
                      Text(
                        _hook(book),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FilledButton.icon(
                  key: const ValueKey('quick-add-pal'),
                  onPressed: _saving || inPal ? null : () => _add(book),
                  icon: Icon(
                    inPal ? Icons.bookmark_added_outlined : Icons.add,
                    size: 18,
                  ),
                  label: Text(
                    inPal
                        ? 'Dans votre Pile à lire'
                        : (_saving ? 'Ajout en cours…' : 'Pile à lire'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${formatInt(book.readersCount)} lecteurs ont ouvert ces pages',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < widget.books.length; i++)
                    Semantics(
                      key: ValueKey('featured-dot-$i'),
                      container: true,
                      onTap: () => _go(i),
                      button: true,
                      selected: i == _index,
                      label:
                          'Livre ${i + 1} sur ${widget.books.length} : ${widget.books[i].title}',
                      excludeSemantics: true,
                      child: InkWell(
                        onTap: () => _go(i),
                        child: SizedBox(
                          width: math.max(48, 220 / widget.books.length),
                          height: 48,
                          child: Center(
                            child: AnimatedContainer(
                              duration: duration,
                              width: i == _index ? 22 : 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: i == _index
                                    ? scheme.primary
                                    : scheme.outline,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
