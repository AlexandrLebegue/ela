import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show ChangeNotifierProvider;

import '../../data/models/book.dart';
import '../../core/theme.dart';

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// Demande de « vol » d'une couverture vers la barre (icône Bibliothèque).
class FlyToLibraryRequest {
  const FlyToLibraryRequest({
    required this.book,
    required this.from,
    required this.to,
  });

  final Book book;

  /// Rect d'origine (couverture sur l'écran d'où on part).
  final Rect from;

  /// Rect cible (icône Bibliothèque dans la barre).
  final Rect to;
}

/// Contrôleur partagé : gère le « réception » de la barre (qui s'élargit
/// brièvement pour accueillir la couverture) quand un vol se termine.
class FlyToLibraryController extends ChangeNotifier {
  bool _receiving = false;
  bool _disposed = false;

  bool get receiving => _receiving;

  void land() {
    if (_disposed) return;
    _receiving = true;
    notifyListeners();
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 520), () {
      if (_disposed) return;
      _receiving = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }

  Timer? _timer;
}

final flyToLibraryProvider =
    ChangeNotifierProvider<FlyToLibraryController>((ref) {
  return FlyToLibraryController();
});

/// Déclenche le vol : insère une [OverlayEntry] dans le root overlay, anime
/// la couverture de `from` vers `to` (rétrécissante, en arc), puis notifie
/// la réception par la barre.
class FlyToLibrary {
  FlyToLibrary._();

  static void fly(
    BuildContext context, {
    required Book book,
    required Rect from,
    required Rect to,
  }) {
    final navigator = Navigator.of(context, rootNavigator: true);
    final overlay = navigator.overlay;
    if (overlay == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => FlyToLibrarySheet(
        request: FlyToLibraryRequest(book: book, from: from, to: to),
        // Flutter 3.35 : c'est l'entry qu'on retire, pas l'overlay.
        onLanded: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

/// Feuille animée du vol : une [OverlayEntry] qui dessine la couverture en
/// mouvement. Animation one-shot (pas de ticker répété) → `pumpAndSettle`
/// des tests la fait converger proprement.
class FlyToLibrarySheet extends ConsumerStatefulWidget {
  const FlyToLibrarySheet({
    super.key,
    required this.request,
    required this.onLanded,
  });

  final FlyToLibraryRequest request;
  final VoidCallback onLanded;

  @override
  ConsumerState<FlyToLibrarySheet> createState() => _FlyToLibrarySheetState();
}

class _FlyToLibrarySheetState extends ConsumerState<FlyToLibrarySheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );
    // One-shot : au complet on notifie la réception puis on se retire.
    _c.forward().whenComplete(() {
      if (!mounted) return;
      ref.read(flyToLibraryProvider).land();
      widget.onLanded();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final core = isLight ? ElaColors.gold : ElaColors.nightSepia;

    // Positionnement via Transform (pas de Positioned : dans Flutter 3.35,
    // le Positioned ne peut pas appliquer sa StackParentData dans le
    // sous-arbre d'un OverlayEntry).
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topLeft,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = Curves.easeInCubic.transform(_c.value);
            final arc = 46.0 * math.sin(math.pi * _c.value);
            final cx = _lerp(req.from.center.dx, req.to.center.dx, t);
            final cy = _lerp(req.from.center.dy, req.to.center.dy, t) - arc;
            final w = _lerp(req.from.width, req.to.width, t);
            final h = _lerp(req.from.height, req.to.height, t);
            return Transform.translate(
              offset: Offset(cx - w / 2, cy - h / 2),
              child: SizedBox(
                width: w,
                height: h,
                child: _FlyingCover(
                  book: req.book,
                  core: core,
                  glow: 0.55 + 0.35 * math.sin(math.pi * _c.value),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Couverture « allégée » pour le vol (pas de réseau) : dégradé sépia +
/// initiale + halo doré, fidèle au repli de [BookCover].
class _FlyingCover extends StatelessWidget {
  const _FlyingCover({
    required this.book,
    required this.core,
    required this.glow,
  });

  final Book book;
  final Color core;
  final double glow;

  @override
  Widget build(BuildContext context) {
    final initial =
        book.title.trim().isEmpty ? 'E' : book.title.trim()[0].toUpperCase();
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.secondaryContainer],
        ),
        border: Border.all(color: core.withValues(alpha: 0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: core.withValues(alpha: 0.55 * glow),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontFamily: 'Lora',
            fontSize: 22,
            color: scheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
