import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/flags.dart';
import '../../core/haptics.dart';
import '../../core/widgets/book_cover.dart';
import '../../data/models/book.dart';
import '../../providers.dart';

/// `preview` montre le viseur sans matériel dans les captures déterministes.
enum ScannerAvailability { automatic, unavailable, denied, preview }

final scannerAvailabilityProvider = Provider<ScannerAvailability>(
  (ref) => ScannerAvailability.automatic,
);

bool isBookBarcode(String value) {
  if (!RegExp(r'^97[89][0-9]{10}$').hasMatch(value)) return false;
  var sum = 0;
  for (var i = 0; i < 12; i++) {
    sum += int.parse(value[i]) * (i.isEven ? 1 : 3);
  }
  return (10 - sum % 10) % 10 == int.parse(value[12]);
}

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});
  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController _camera;
  GoRouter? _router;
  bool _starting = false,
      _cameraOn = false,
      _denied = false,
      _active = true,
      _foreground = true;
  bool _manualOpen = false,
      _manualOffered = false,
      _busy = false,
      _navigating = false;
  Book? _identified;
  bool get _canUseCamera =>
      !kIsWeb &&
      !isRunningUnderFlutterTest &&
      ref.read(scannerAvailabilityProvider) == ScannerAvailability.automatic;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _camera = MobileScannerController(
      autoStart: false,
      formats: const [BarcodeFormat.ean13],
      facing: CameraFacing.back,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.maybeOf(context);
    if (router != _router) {
      _router?.routeInformationProvider.removeListener(_routeChanged);
      _router = router;
      router?.routeInformationProvider.addListener(_routeChanged);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _routeChanged();
    });
  }

  void _routeChanged() {
    if (!mounted) return;
    _active =
        _router == null ||
        _router!.routeInformationProvider.value.uri.path == '/scanner';
    if (!_active || !_foreground || _navigating || _manualOpen) {
      _stop();
      return;
    }
    if (_canUseCamera) {
      if (!_cameraOn && !_starting) _start();
    } else if (!_manualOffered &&
        ref.read(scannerAvailabilityProvider) != ScannerAvailability.preview) {
      _manualOffered = true;
      _showManual();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _routeChanged();
    } else {
      _stop();
    }
  }

  Future<void> _start() async {
    if (!_canUseCamera ||
        _starting ||
        !_active ||
        !_foreground ||
        _manualOpen ||
        _navigating) {
      return;
    }
    setState(() => _starting = true);
    try {
      await _camera.start();
      if (!mounted) return;
      if (!_active || !_foreground || _manualOpen || _navigating) {
        await _camera.stop();
        return;
      }
      setState(() {
        _cameraOn = true;
        _denied = false;
      });
    } on MobileScannerException catch (e) {
      if (mounted) {
        setState(() {
          _denied = e.errorCode == MobileScannerErrorCode.permissionDenied;
          _cameraOn = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cameraOn = false);
    } finally {
      if (mounted) {
        setState(() => _starting = false);
        if (!_cameraOn && !_manualOffered && _active && _foreground) {
          _manualOffered = true;
          _showManual();
        }
      }
    }
  }

  Future<void> _stop() async {
    if (!_cameraOn && !_starting) return;
    try {
      await _camera.stop();
    } catch (_) {
      /* Déjà arrêtée. */
    }
    if (mounted) setState(() => _cameraOn = false);
  }

  Future<void> _showManual() async {
    if (_manualOpen || _navigating || !_active) return;
    _manualOpen = true;
    await _stop();
    if (!mounted) return;
    final book = await showModalBottomSheet<Book>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _IsbnEntrySheet(),
    );
    if (!mounted) return;
    _manualOpen = false;
    if (book != null) {
      await _openBook(book);
    } else {
      _routeChanged();
    }
  }

  Future<void> _openBook(Book book) async {
    _navigating = true;
    await _stop();
    if (!mounted) return;
    ElaHaptics.heartbeat();
    await context.push('/livre/${book.isbn}');
    if (mounted) {
      setState(() {
        _identified = null;
        _navigating = false;
      });
      _routeChanged();
    }
  }

  Future<void> _scan(String value) async {
    if (_busy ||
        _navigating ||
        _manualOpen ||
        !_active ||
        !_foreground ||
        !isBookBarcode(value)) {
      return;
    }
    _busy = true;
    try {
      final book = await ref
          .read(bookLookupServiceProvider)
          .lookupByIsbn(value);
      if (!mounted || !_active || !_foreground || _manualOpen) return;
      if (book == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Livre introuvable. Essayez la saisie ISBN.'),
          ),
        );
        return;
      }
      await _stop();
      if (!mounted) return;
      ElaHaptics.softTap();
      setState(() => _identified = book);
      await Future<void>.delayed(
        MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 500),
      );
      if (mounted) await _openBook(book);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La recherche a été interrompue. Réessayez.'),
          ),
        );
      }
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router?.routeInformationProvider.removeListener(_routeChanged);
    _camera.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final forced = ref.watch(scannerAvailabilityProvider);
    final denied = _denied || forced == ScannerAvailability.denied;
    final preview = forced == ScannerAvailability.preview;
    final available = _cameraOn || _starting || preview;
    const cream = Color(0xfff3edde);
    return Scaffold(
      backgroundColor: const Color(0xff151515),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_canUseCamera && (_cameraOn || _starting))
            MobileScanner(
              controller: _camera,
              onDetect: (capture) {
                final code = capture.barcodes
                    .map((b) => b.rawValue)
                    .whereType<String>()
                    .where(isBookBarcode)
                    .firstOrNull;
                if (code != null) _scan(code);
              },
              errorBuilder: (_, _) =>
                  const ColoredBox(color: Color(0xff151515)),
            ),
          _ScanGuide(
            animate: _cameraOn && _identified == null && !_manualOpen,
            detected: _identified != null,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Scanner un livre',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(color: cream),
                  ),
                  const Text(
                    'EAN-13 · ISBN',
                    style: TextStyle(color: Color(0xffc4c1ba), fontSize: 12),
                  ),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 240),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(
                          begin: .96,
                          end: 1,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: _identified == null
                        ? const SizedBox.shrink()
                        : Column(
                            key: ValueKey(_identified!.isbn),
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: cream,
                                size: 36,
                              ),
                              const SizedBox(height: 8),
                              BookCover(book: _identified!, width: 64),
                              const SizedBox(height: 8),
                              Text(
                                _identified!.title,
                                style: const TextStyle(color: cream),
                              ),
                            ],
                          ),
                  ),
                  if (!available) ...[
                    Text(
                      denied
                          ? 'Accès à la caméra refusé'
                          : 'Caméra indisponible',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: cream,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      denied
                          ? 'Autorisez la caméra dans les réglages ou saisissez l’ISBN.'
                          : 'Retrouvez votre livre avec les 13 chiffres de l’ISBN.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xffc4c1ba),
                        fontSize: 13,
                      ),
                    ),
                  ] else
                    const Text(
                      'Placez le code-barres dans le cadre.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cream, fontSize: 14),
                    ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xff733943),
                      foregroundColor: cream,
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: _busy ? null : _showManual,
                    icon: const Icon(Icons.keyboard_outlined, size: 18),
                    label: const Text('Saisir un ISBN'),
                  ),
                  if (!available && _canUseCamera)
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: cream),
                      onPressed: _start,
                      child: const Text('Réessayer le scan'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IsbnEntrySheet extends ConsumerStatefulWidget {
  const _IsbnEntrySheet();
  @override
  ConsumerState<_IsbnEntrySheet> createState() => _IsbnEntrySheetState();
}

class _IsbnEntrySheetState extends ConsumerState<_IsbnEntrySheet> {
  final _isbn = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _isbn.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    if (_busy) return;
    final isbn = _isbn.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (isbn.length != 13) {
      setState(() => _error = 'Saisissez les 13 chiffres de l’ISBN.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final book = await ref.read(bookLookupServiceProvider).lookupByIsbn(isbn);
      if (!mounted) return;
      if (book == null) {
        setState(
          () => _error = 'Livre introuvable. Vérifiez l’ISBN (13 chiffres).',
        );
      } else {
        Navigator.pop(context, book);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'La recherche a été interrompue. Réessayez.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ou saisissez un ISBN',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _isbn,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.search,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9 \-]')),
            ],
            decoration: InputDecoration(
              labelText: 'ISBN du livre',
              hintText: '978…',
              errorText: _error,
              errorMaxLines: 3,
            ),
            onSubmitted: (_) => _lookup(),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xff733943),
              foregroundColor: const Color(0xfff3edde),
            ),
            onPressed: _busy ? null : _lookup,
            icon: const Icon(Icons.search),
            label: Text(_busy ? 'Recherche…' : 'Chercher'),
          ),
        ],
      ),
    ),
  );
}

class _ScanGuide extends StatefulWidget {
  const _ScanGuide({required this.animate, required this.detected});
  final bool animate, detected;
  @override
  State<_ScanGuide> createState() => _ScanGuideState();
}

class _ScanGuideState extends State<_ScanGuide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  void _update() {
    if (widget.animate && !MediaQuery.disableAnimationsOf(context)) {
      if (!_motion.isAnimating) _motion.repeat(reverse: true);
    } else {
      _motion.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _update();
  }

  @override
  void didUpdateWidget(covariant _ScanGuide oldWidget) {
    super.didUpdateWidget(oldWidget);
    _update();
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _motion,
      builder: (_, _) => CustomPaint(
        painter: _GuidePainter(
          position: widget.animate ? _motion.value : .5,
          detected: widget.detected,
        ),
      ),
    ),
  );
}

class _GuidePainter extends CustomPainter {
  const _GuidePainter({required this.position, required this.detected});
  final double position;
  final bool detected;
  @override
  void paint(Canvas canvas, Size size) {
    final frame = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * .43),
      width: math.min(size.width - 64, 380),
      height: math.min(160, size.height * .27),
    );
    final veil = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRect(frame);
    canvas.drawPath(veil, Paint()..color = const Color(0x77000000));
    final ink = Paint()
      ..color = const Color(0xfff3edde)
      ..style = PaintingStyle.stroke
      ..strokeWidth = detected ? 2 : 1;
    const edge = 22.0;
    for (final corner in [
      frame.topLeft,
      frame.topRight,
      frame.bottomLeft,
      frame.bottomRight,
    ]) {
      final dx = corner.dx == frame.left ? edge : -edge;
      final dy = corner.dy == frame.top ? edge : -edge;
      canvas.drawPath(
        Path()
          ..moveTo(corner.dx, corner.dy + dy)
          ..lineTo(corner.dx, corner.dy)
          ..lineTo(corner.dx + dx, corner.dy),
        ink,
      );
    }
    canvas.drawLine(
      Offset(frame.left + 12, frame.top + 8 + (frame.height - 16) * position),
      Offset(frame.right - 12, frame.top + 8 + (frame.height - 16) * position),
      Paint()
        ..color = const Color(0x66f3edde)
        ..strokeWidth = .7,
    );
  }

  @override
  bool shouldRepaint(covariant _GuidePainter oldDelegate) =>
      position != oldDelegate.position || detected != oldDelegate.detected;
}
