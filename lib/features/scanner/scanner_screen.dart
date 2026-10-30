import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../providers.dart';

/// Écran « Scanner » — version socle : saisie manuelle d'ISBN en secours.
/// L'expérience caméra (halo lampe de chevet, lévitation) arrive à l'étape 2.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final _isbnController = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _isbnController.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final isbn = _isbnController.text.trim();
    if (isbn.isEmpty) return;
    setState(() => _searching = true);
    final book = await ref.read(bookLookupServiceProvider).lookupByIsbn(isbn);
    if (!mounted) return;
    setState(() => _searching = false);
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
    final scheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Text(
                'Scanner',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontFamily: 'Lora', fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                'Le scan de code-barres arrive dans la prochaine version.\n'
                'En attendant, saisissez un ISBN.',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
              ),
              const SizedBox(height: 28),
              _LampGlow(isLight: isLight),
              const SizedBox(height: 28),
              TextField(
                controller: _isbnController,
                keyboardType: TextInputType.number,
                maxLength: 13,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: '978…',
                  labelText: 'ISBN du livre',
                ),
                onSubmitted: (_) => _lookup(),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _searching ? null : _lookup,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                icon: _searching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.search),
                label: Text(_searching ? 'Recherche…' : 'Chercher'),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

/// Halo doux « lampe de chevet » (ambre/doré, jamais de laser).
class _LampGlow extends StatelessWidget {
  const _LampGlow({required this.isLight});

  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final core = isLight ? ElaColors.gold : ElaColors.nightSepia;
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            core.withValues(alpha: isLight ? 0.5 : 0.45),
            core.withValues(alpha: 0.18),
            core.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Center(
        child: Container(
          width: 84,
          height: 126,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: core.withValues(alpha: 0.25),
            border: Border.all(color: core.withValues(alpha: 0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: core.withValues(alpha: 0.5),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.qr_code_scanner,
              size: 40,
              color: core.withValues(alpha: 0.9),
            ),
          ),
        ),
      ),
    );
  }
}
