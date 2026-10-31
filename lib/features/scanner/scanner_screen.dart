import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/animations.dart';
import '../../core/flags.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/widgets/book_cover.dart';
import '../../data/models/book.dart';
import '../../providers.dart';

/// Override for deterministic camera states in the capture bench. Production
/// always starts with automatic, web goes straight to ISBN entry.
enum ScannerAvailability { automatic, unavailable, denied }

final scannerAvailabilityProvider = Provider<ScannerAvailability>(
  (ref) => ScannerAvailability.automatic,
);

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});
  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with WidgetsBindingObserver {
  final _isbn = TextEditingController();
  late final MobileScannerController _camera;
  GoRouter? _router;
  bool _manualBusy = false;
  bool _starting = false;
  bool _cameraOn = false;
  bool _denied = false;
  bool _active = true;
  Book? _identified;
  String? _error;
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
    if (_active && _canUseCamera && !_cameraOn && !_starting) {
      _start();
    } else if (!_active) {
      _stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _routeChanged();
    } else {
      _stop();
    }
  }

  Future<void> _start() async {
    if (!_canUseCamera || _starting || !_active) return;
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      await _camera.start();
      if (!mounted) return;
      if (!_active) {
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
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _stop() async {
    if (!_cameraOn && !_starting) return;
    try {
      await _camera.stop();
    } catch (_) {
      /* Camera already stopped. */
    }
    if (mounted) setState(() => _cameraOn = false);
  }

  Future<void> _lookup(String value, {bool scanned = false}) async {
    if (_manualBusy || _identified != null) return;
    final isbn = value.replaceAll(RegExp(r'[^0-9Xx]'), '');
    if (isbn.length != 13) {
      setState(() => _error = 'Saisissez les 13 chiffres de l’ISBN.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _manualBusy = true;
      _error = null;
    });
    try {
      final book = await ref.read(bookLookupServiceProvider).lookupByIsbn(isbn);
      if (!mounted) return;
      if (book == null) {
        setState(
          () => _error = 'Livre introuvable. Vérifiez l’ISBN (13 chiffres).',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Vérifiez le code au dos du livre, puis réessayez.',
            ),
          ),
        );
        return;
      }
      if (scanned) {
        await _stop();
        if (!mounted) return;
        setState(() => _identified = book);
        ElaHaptics.heartbeat();
        await Future<void>.delayed(
          MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 900),
        );
      }
      if (!mounted) return;
      await _stop();
      if (!mounted) return;
      await context.push('/livre/${book.isbn}');
      if (mounted) {
        setState(() => _identified = null);
        _routeChanged();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'La recherche a été interrompue. Réessayez.');
      }
    } finally {
      if (mounted) setState(() => _manualBusy = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router?.routeInformationProvider.removeListener(_routeChanged);
    _isbn.dispose();
    _camera.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final forced = ref.watch(scannerAvailabilityProvider);
    final denied = _denied || forced == ScannerAvailability.denied;
    final cameraArea = _canUseCamera && (_cameraOn || _starting);
    return BookScaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ChapterHeader(
                chapter: 'II',
                title: 'Scanner',
                subtitle: 'Un livre entre vos mains. Toutes ses voix ici.',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedSwitcher(
                  duration: ElaMotion.page,
                  child: _identified != null
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              BookCover(book: _identified!, width: 110),
                              const SizedBox(height: 16),
                              Text(
                                _identified!.title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const Text('Ouverture de la fiche…'),
                            ],
                          ),
                        )
                      : cameraArea
                      ? AspectRatio(
                          aspectRatio: 1.25,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              MobileScanner(
                                controller: _camera,
                                onDetect: (capture) {
                                  final code =
                                      capture.barcodes.firstOrNull?.rawValue;
                                  if (code != null) {
                                    _lookup(code, scanned: true);
                                  }
                                },
                                errorBuilder: (_, error) => BookNotice(
                                  title: 'Caméra indisponible',
                                  message: 'Saisissez l’ISBN ci-dessous.',
                                  icon: Icons.videocam_off_outlined,
                                ),
                              ),
                              IgnorePointer(
                                child: Center(
                                  child: Container(
                                    margin: const EdgeInsets.all(24),
                                    height: 140,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: ElaLampHalo.core,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: ElaLampHalo.glow,
                                          blurRadius: 32,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : BookNotice(
                          title: denied
                              ? 'Accès à la caméra refusé'
                              : 'Caméra indisponible',
                          message: denied
                              ? 'Autorisez la caméra dans les réglages, ou saisissez l’ISBN ci-dessous.'
                              : kIsWeb
                              ? 'Dans votre navigateur, retrouvez un livre avec les 13 chiffres de son code-barres.'
                              : 'Sur cet appareil, utilisez la saisie manuelle d’ISBN ci-dessous.',
                          icon: Icons.qr_code_scanner,
                          action: _canUseCamera
                              ? TextButton(
                                  onPressed: _start,
                                  child: const Text('Réessayer le scan'),
                                )
                              : null,
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Ou saisissez un ISBN',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _isbn,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            labelText: 'ISBN du livre',
                            hintText: '978…',
                            errorText: _error,
                            errorMaxLines: 3,
                          ),
                          onSubmitted: (_) => _lookup(_isbn.text),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _manualBusy
                              ? null
                              : () => _lookup(_isbn.text),
                          icon: const Icon(Icons.search),
                          label: _manualBusy
                              ? const BreathingText('Recherche…')
                              : const Text('Chercher'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Folio('02'),
            ],
          ),
        ),
      ),
    );
  }
}
