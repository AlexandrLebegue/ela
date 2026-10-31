import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/haptics.dart';
import '../core/theme.dart';
import 'library/fly_to_library.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final receiving = ref.watch(flyToLibraryProvider).receiving;
    const labels = [
      'Tendance',
      'Scanner',
      'Bibliothèque',
      'Recherche',
      'Marché',
    ];
    const icons = [
      Icons.menu_book_outlined,
      Icons.qr_code_scanner,
      Icons.auto_stories_outlined,
      Icons.search,
      Icons.storefront_outlined,
    ];
    return BookScaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: scheme.outline)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ElaSize.v8,
              vertical: ElaSize.v8,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < labels.length; i++)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: navigationShell.currentIndex == i,
                      label: labels[i],
                      excludeSemantics: true,
                      child: InkWell(
                        onTap: () {
                          ElaHaptics.softTap();
                          navigationShell.goBranch(i);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: ElaSize.v2,
                            vertical: ElaSize.v4,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: ElaMotion.detail,
                                width: ElaSize.v48,
                                height: ElaSize.v48,
                                decoration: BoxDecoration(
                                  color: i == 1
                                      ? scheme.primary
                                      : (i == 2 && receiving
                                            ? scheme.primaryContainer
                                            : ElaColors.transparent),
                                  borderRadius: BorderRadius.circular(
                                    ElaSize.v4,
                                  ),
                                ),
                                child: Icon(
                                  icons[i],
                                  color: i == 1
                                      ? scheme.onPrimary
                                      : (navigationShell.currentIndex == i
                                            ? scheme.primary
                                            : scheme.onSurfaceVariant),
                                  size: ElaSize.v23,
                                ),
                              ),
                              const SizedBox(height: ElaSize.v4),
                              Text(
                                labels[i],
                                textAlign: TextAlign.center,
                                softWrap: true,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: navigationShell.currentIndex == i
                                          ? scheme.primary
                                          : scheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
