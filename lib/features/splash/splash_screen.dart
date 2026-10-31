import 'package:flutter/material.dart';
import '../../core/theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => BookScaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'COMPAGNON DE LECTURE',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(letterSpacing: 3),
                ),
                const SizedBox(height: 48),
                const Bookplate(),
                const SizedBox(height: 24),
                Text('Ela', style: Theme.of(context).textTheme.displayLarge),
                const SizedBox(height: 12),
                Text(
                  'Les livres se rencontrent ici.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 48),
                const Folio('I'),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
