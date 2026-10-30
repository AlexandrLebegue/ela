import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/flags.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/widgets/book_cover.dart';
import '../../data/models/book.dart';
import '../../providers.dart';

/// Écran « Scanner » — l'écran phare d'Ela.
///
/// Caméra EAN-13/ISBN (mobile_scanner), halo doré façon « lampe de chevet »
/// (jamais de laser rouge). À la détection : retour haptique doux
/// (battement de cœur), la couverture « lévite », puis la fiche s'ouvre.
/// Saisie manuelle d'ISBN en secours, et gestion propre du refus de la
/// permission caméra.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with TickerProviderStateMixin {
  late final MobileScannerController _controller;
  late final AnimationController _levitate;
  final _isbnController = TextEditingController();

  _ScanPhase _phase = _ScanPhase.starting;
  String? _lastIsbn;
  Book? _book;
  bool _busy = false;
  bool _manualBusy = false;

  @override
  void initState() {
    super.initState();
    _levitate = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _controller = MobileScannerController(
      autoStart: false,
      formats: const <BarcodeFormat>[BarcodeFormat.ean13],
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      lensType: CameraLensType.any,
    );
    if (isRunningUnderFlutterTest) {
      _phase = _ScanPhase.noCamera;
    } else {
      _startCamera();
    }
  }

  @override
  void dispose() {
    _levitate.dispose();
    _isbnController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startCamera() async {
    if (_busy) return;
    setState(() {
      _phase = _ScanPhase.starting;
      _busy = true;
    });
    try {
      await _controller.start();
    } on MobileScannerException catch (e) {
      if (!mounted) return;
      _busy = false;
      setState(() {
        _phase = e.errorCode == MobileScannerErrorCode.permissionDenied
            ? _ScanPhase.permissionDenied
            : _ScanPhase.noCamera;
      });
      return;
    } catch (_) {
      if (!mounted) return;
      _busy = false;
      setState(() => _phase = _ScanPhase.noCamera);
      return;
    }
    if (!mounted) return;
    _busy = false;
    setState(() => _phase = _ScanPhase.scanning);
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy || _phase != _ScanPhase.scanning) return;
    final code = capture.barcodes.firstOrNull?.rawValue?.trim() ?? '';
    if (code.length < 12) return;
    _busy = true;
    await ElaHaptics.heartbeat();
    try {
      await _controller.stop();
    } catch (_) {
      // La caméra peut déjà être stoppée : on ignore.
    }
    if (!mounted) return;
    setState(() {
      _lastIsbn = code;
      _phase = _ScanPhase.identified;
    });
    _levitate.forward(from: 0);
    // Petit souffle pour laisser la couverture « léviter ».
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    final book = await ref.read(bookLookupServiceProvider).lookupByIsbn(code);
    if (!mounted) return;
    _busy = false;
    if (book != null) {
      _book = book;
      context.go('/livre/${book.isbn}');
    } else {
      setState(() => _phase = _ScanPhase.notFound);
    }
  }

  Future<void> _manualLookup() async {
    final isbn = _isbnController.text.trim();
    if (isbn.isEmpty || _manualBusy) return;
    setState(() => _manualBusy = true);
    ElaHaptics.softTap();
    final book = await ref.read(bookLookupServiceProvider).lookupByIsbn(isbn);
    if (!mounted) return;
    setState(() => _manualBusy = false);
    if (book != null) {
      context.go('/livre/${book.isbn}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Livre introuvable. Vérifiez l’ISBN (13 chiffres).'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final showCamera =
        _phase != _ScanPhase.noCamera && _phase != _ScanPhase.permissionDenied;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (showCamera)
                    MobileScanner(
                      controller: _controller,
                      onDetect: _onDetect,
                      placeholderBuilder: (context) =>
                          const _CameraPlaceholder(),
                      errorBuilder: (context, error) => _CameraErrorCard(
                        message: error.errorDetails?.message ??
                            'Caméra indisponible.',
                        onRetry: _startCamera,
                      ),
                    ),
                  if (_phase == _ScanPhase.scanning)
                    const _LampHaloOverlay(),
                  if (_phase == _ScanPhase.identified)
                    _IdentifiedOverlay(state: this),
                  if (_phase == _ScanPhase.notFound)
                    _NotFoundOverlay(
                      isbn: _lastIsbn ?? '',
                      onRetry: _startCamera,
                    ),
                  if (_phase == _ScanPhase.permissionDenied)
                    _PermissionDeniedCard(onRetry: _startCamera),
                  if (_phase == _ScanPhase.noCamera)
                    const _NoCameraCard(),
                ],
              ),
            ),
            _ManualEntry(
              controller: _isbnController,
              busy: _manualBusy,
              onLookup: _manualLookup,
              highlight:
                  _phase == _ScanPhase.permissionDenied ||
                  _phase == _ScanPhase.noCamera ||
                  _phase == _ScanPhase.notFound,
            ),
          ],
        ),
      ),
    );
  }
}

enum _ScanPhase {
  starting,
  scanning,
  identified,
  notFound,
  permissionDenied,
  noCamera,
}

/// Halo « lampe de chevet » : cadre doré doux qui respire, coins arrondis.
/// Aucune ligne rouge, aucun laser : une lumière ambrée apaisante.
class _LampHaloOverlay extends StatefulWidget {
  const _LampHaloOverlay();

  @override
  State<_LampHaloOverlay> createState() => _LampHaloOverlayState();
}

class _LampHaloOverlayState extends State<_LampHaloOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathe;

  @override
  void initState() {
    super.initState();
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
    _breathe.repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final core = isLight ? ElaColors.gold : ElaColors.nightSepia;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _breathe,
        builder: (context, _) {
          final glow = 0.35 + 0.30 * _breathe.value;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Center(
              child: Container(
                width: 320,
                height: 170,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: core.withValues(alpha: 0.55 + 0.25 * glow),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: core.withValues(alpha: 0.30 * glow),
                      blurRadius: 46,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Text(
                        'Pointez le code-barres du livre',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF14100A),
      child: Center(
        child: Icon(
          Icons.qr_code_scanner,
          color: Color(0xFFC9974F),
          size: 40,
        ),
      ),
    );
  }
}

class _CameraErrorCard extends StatelessWidget {
  const _CameraErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: const Color(0xFF14100A),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam_off_outlined,
                      color: scheme.onSurfaceVariant, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14, color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonal(onPressed: onRetry,
                      child: const Text('Réessayer')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// La couverture « lévite » : elle arrive en douceur du bas, en grandissant,
/// entourée d'un halo doré, avant l'ouverture de la fiche.
class _IdentifiedOverlay extends ConsumerStatefulWidget {
  const _IdentifiedOverlay({required this.state});

  final _ScannerScreenState state;

  @override
  ConsumerState<_IdentifiedOverlay> createState() => _IdentifiedOverlayState();
}

class _IdentifiedOverlayState extends ConsumerState<_IdentifiedOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.state._book;
    final isbn = widget.state._lastIsbn ?? '';
    final isLight = Theme.of(context).brightness == Brightness.light;
    final core = isLight ? ElaColors.gold : ElaColors.nightSepia;
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.82),
      child: Center(
        child: AnimatedBuilder(
          animation: widget.state._levitate,
          builder: (context, child) {
            final t = Curves.easeOutCubic.transform(widget.state._levitate.value);
            return Transform.translate(
              offset: Offset(0, 34 * (1 - t)),
              child: Transform.scale(
                scale: 0.72 + 0.28 * t,
                child: Opacity(
                  opacity: t,
                  child: child,
                ),
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: core.withValues(
                          alpha: 0.5 + 0.3 * _c.value),
                      blurRadius: 30 + 22 * _c.value,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: BookCover(
                  book: book ?? Book(
                    isbn: isbn,
                    title: 'Livre…',
                    author: 'Recherche en cours…',
                    genre: 'Autre',
                    year: 0,
                    badge: PopularityBadge.trending,
                    readersCount: 0,
                  ),
                  width: 110,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                book != null ? book.title : 'Livre identifié',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                book != null ? book.author : 'Ouverture de la fiche…',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotFoundOverlay extends StatelessWidget {
  const _NotFoundOverlay({required this.isbn, required this.onRetry});

  final String isbn;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: Colors.black.withValues(alpha: 0.82),
      child: Center(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bookmark_outline,
                    color: scheme.onSurfaceVariant, size: 38),
                const SizedBox(height: 10),
                Text(
                  'Livre introuvable',
                  style: TextStyle(
                    fontFamily: 'Lora',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Le code « $isbn » ne correspond à aucun livre\n'
                  'pour le moment. Vérifiez la saisie ou réessayez.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13.5, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 14),
                FilledButton.tonal(
                  onPressed: onRetry,
                  child: const Text('Réessayer le scan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PermissionDeniedCard extends StatelessWidget {
  const _PermissionDeniedCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: const Color(0xFF14100A),
      child: Center(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.camera_front, color: scheme.onSurfaceVariant),
                const SizedBox(height: 12),
                Text(
                  'Accès à la caméra refusé',
                  style: TextStyle(
                    fontFamily: 'Lora',
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Autorisez la caméra dans les réglages de votre téléphone '
                  'pour scanner, ou saisissez l’ISBN ci-dessous.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13.5, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 14),
                FilledButton.tonal(
                  onPressed: onRetry,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoCameraCard extends StatelessWidget {
  const _NoCameraCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: const Color(0xFF14100A),
      child: Center(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.photo_camera_outlined,
                    color: scheme.onSurfaceVariant),
                const SizedBox(height: 12),
                Text(
                  'Caméra indisponible',
                  style: TextStyle(
                    fontFamily: 'Lora',
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sur cet appareil, utilisez la saisie manuelle d’ISBN\nci-dessous.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13.5, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ManualEntry extends StatelessWidget {
  const _ManualEntry({
    required this.controller,
    required this.busy,
    required this.onLookup,
    required this.highlight,
  });

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onLookup;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: highlight ? scheme.primaryContainer : scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Text(
            'Ou saisissez un ISBN',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: highlight
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  maxLength: 13,
                  decoration: const InputDecoration(
                    hintText: '978…',
                    isDense: true,
                  ),
                  onSubmitted: (_) => onLookup(),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: busy ? null : onLookup,
                icon: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child:
                            CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.search, size: 18),
                label: Text(busy ? 'Recherche…' : 'Chercher'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
