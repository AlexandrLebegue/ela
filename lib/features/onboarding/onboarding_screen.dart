import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../providers.dart';

/// Onboarding court : 3 écrans, une seule fois (mémorisé dans les prefs).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pages = PageController();
  int _page = 0;

  static const _items = [
    _OnboardPage(
      icon: Icons.menu_book,
      title: 'Bienvenue chez Ela',
      body:
          'Un coin douillet pour vos lectures : couvertures, prix d’occasion '
          'et le pouls des lecteurs d’Ela autour de chaque livre.',
    ),
    _OnboardPage(
      icon: Icons.auto_awesome,
      title: '20 avis, 1 verdict',
      body:
          'Presse, web et communauté réunis autour d’une synthèse IA. '
          'Gratuitement : 1 avis presse et 2 avis web — Premium débloque le reste.',
    ),
    _OnboardPage(
      icon: Icons.cloud_circle,
      title: 'Votre bibliothèque, partout',
      body:
          'Historique, Pile à Lire, jetons IA chaque mois… et un Premium à '
          '2 €/mois, sans engagement, pour tout ouvrir.',
    ),
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    ElaHaptics.softTap();
    await ref.read(onboardedProvider.notifier).finish();
  }

  void _go(int page) {
    if (page == 0) {
      _pages.jumpToPage(0);
      return;
    }
    _pages.animateToPage(
      page,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final last = _page == _items.length - 1;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // « Passer » en haut à droite.
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16, top: 8),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Passer'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _items.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _OnboardCard(item: _items[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                children: [
                  // Points de progression.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _items.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: i == _page ? 20 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: i == _page
                                  ? ElaColors.gold
                                  : ElaColors.lineLight,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              _page == 0 ? null : () => _go(_page - 1),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: scheme.outlineVariant),
                          ),
                          child: const Text('Retour'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: () {
                            if (last) {
                              _finish();
                            } else {
                              _go(_page + 1);
                            }
                          },
                          style: FilledButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: ElaColors.gold,
                            // Encre sur or (≈ 5:1) plutôt que blanc (2,6:1) :
                            // accessibilité contraste.
                            foregroundColor: ElaColors.ink,
                          ),
                          child: Text(
                            last ? 'Commencer à lire' : 'Suivant',
                            style: const TextStyle(
                                fontFamily: 'Lora',
                                fontWeight: FontWeight.w700),
                          ),
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
    );
  }
}

class _OnboardPage {
  const _OnboardPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _OnboardCard extends StatelessWidget {
  const _OnboardCard({required this.item});

  final _OnboardPage item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = isDark ? ElaColors.nightSepia : ElaColors.gold;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gold.withValues(alpha: 0.16),
                border: Border.all(color: gold, width: 1.5),
              ),
              child: Icon(item.icon, color: gold, size: 44),
            ),
            const SizedBox(height: 28),
            Text(
              item.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Lora',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              item.body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.55,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
