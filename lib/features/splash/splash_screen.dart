import 'package:flutter/material.dart';

import '../../core/animations.dart';
import '../../core/theme.dart';

/// Splash « Ela » : la marque quelques instants au lancement.
/// (Le cold-start Android est couvert par le drawable `launch_background`.)
/// Le parent décide de la durée ; ce widget ne fait que respirer.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _halo;

  @override
  void initState() {
    super.initState();
    _halo = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _halo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = isDark ? ElaColors.nightSepia : ElaColors.gold;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Monogramme : un E serif dans un halo doré qui respire.
            AnimatedBuilder(
              animation: _halo,
              builder: (context, _) {
                final t = _halo.value;
                return Container(
                  width: 104 + 10 * t,
                  height: 104 + 10 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: gold.withValues(alpha: 0.16 + 0.08 * t),
                  ),
                  child: const _Monogram(),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Ela',
              style: TextStyle(
                fontFamily: 'Lora',
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            BreathingText(
              'votre liseuse de poche',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Le « E » d'Ela, dessiné en vector pour rester net à toutes tailles.
class _Monogram extends StatelessWidget {
  const _Monogram();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = isDark ? ElaColors.nightSepia : ElaColors.gold;
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: gold,
      ),
      child: Icon(Icons.menu_book, color: Colors.white, size: 36),
    );
  }
}
