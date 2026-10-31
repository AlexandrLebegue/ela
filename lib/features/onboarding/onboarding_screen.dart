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
    return BookScaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // « Passer » en haut à droite.
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(
                  right: ElaSize.v16,
                  top: ElaSize.v8,
                ),
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
              padding: const EdgeInsets.fromLTRB(
                ElaSize.v24,
                ElaSize.v8,
                ElaSize.v24,
                ElaSize.v20,
              ),
              child: Column(
                children: [
                  // Points de progression.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _items.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: ElaSize.v4,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: i == _page ? 20 : 8,
                            height: ElaSize.v8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                ElaSpace.radius,
                              ),
                              color: i == _page
                                  ? scheme.primary
                                  : scheme.outline,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: ElaSize.v20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _page == 0 ? null : () => _go(_page - 1),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: ElaSize.v14,
                            ),
                            side: BorderSide(color: scheme.outlineVariant),
                          ),
                          child: const Text('Retour'),
                        ),
                      ),
                      const SizedBox(width: ElaSize.v12),
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
                            padding: const EdgeInsets.symmetric(
                              vertical: ElaSize.v14,
                            ),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.secondary,
                            // Encre sur or (≈ 5:1) plutôt que blanc (2,6:1) :
                            // accessibilité contraste.
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onSecondary,
                          ),
                          child: Text(
                            last ? 'Commencer à lire' : 'Suivant',
                            style: const TextStyle(
                              fontFamily: ElaType.titleFamily,
                              fontWeight: FontWeight.w700,
                            ),
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
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.all(ElaSize.v24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'OUVRIR LE LIVRE',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: ElaSize.v2,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: ElaSize.v24),
                Bookplate(icon: item.icon),
                const SizedBox(height: ElaSize.v32),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: ElaSize.v16),
                Text(
                  item.body,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const Folio('·'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
