import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/haptics.dart';
import '../core/theme.dart';

/// Coquille principale : 4 entrées (Tendance / Scanner / Bibliothèque /
/// Recherche), le Scanner au centre, mis en avant comme une boutonnière.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = navigationShell.currentIndex;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _ElaBottomBar(
        activeIndex: index,
        onNavigate: (i) => navigationShell.goBranch(i),
      ),
    );
  }
}

class _ElaBottomBar extends ConsumerWidget {
  const _ElaBottomBar({required this.activeIndex, required this.onNavigate});

  final int activeIndex;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _TabButton(
              label: 'Tendance',
              icon: Icons.trending_up,
              active: activeIndex == 0,
              onTap: () => onNavigate(0),
            ),
            _ScanFab(
              onTap: () {
                ElaHaptics.softTap();
                onNavigate(1);
              },
              active: activeIndex == 1,
            ),
            _TabButton(
              label: 'Bibliothèque',
              icon: Icons.auto_stories,
              active: activeIndex == 2,
              onTap: () => onNavigate(2),
            ),
            _TabButton(
              label: 'Recherche',
              icon: Icons.search,
              active: activeIndex == 3,
              onTap: () => onNavigate(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = active ? scheme.primary : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bouton central « Scanner » : disque doré en relief façon boutonnière.
class _ScanFab extends StatelessWidget {
  const _ScanFab({required this.onTap, this.active = false});

  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Semantics(
      button: true,
      label: 'Scanner',
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: const Offset(0, -16),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                scale: active ? 1.06 : 1.0,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        isLight ? ElaColors.gold : ElaColors.nightSepia,
                        ElaColors.sepiaDeep,
                      ],
                    ),
                    border: Border.all(
                      color: isLight
                          ? Colors.white.withValues(alpha: 0.75)
                          : ElaColors.nightSepiaDeep.withValues(alpha: 0.6),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ElaLampHalo.glow,
                        blurRadius: 22,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Scanner',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: active ? ElaColors.gold : ElaColors.nightInkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
