import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animations.dart';
import '../../core/format.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../providers.dart';

/// Écran paywall « Ela Premium » (2 €/mois, paiement simulé).
class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  bool _subscribing = false;
  bool _cancelling = false;

  Future<void> _subscribe() async {
    if (_subscribing) return;
    setState(() => _subscribing = true);
    try {
      await ref.read(paymentServiceProvider).subscribePremium();
    } catch (_) {
      if (mounted) {
        setState(() => _subscribing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('L’opération a été interrompue. Réessayez.'),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() => _subscribing = false);
    ElaHaptics.heartbeat();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bienvenue dans Ela Premium !')),
      );
    }
  }

  Future<void> _cancel() async {
    if (_cancelling) return;
    setState(() => _cancelling = true);
    try {
      await ref.read(paymentServiceProvider).cancelPremium();
    } catch (_) {
      if (mounted) {
        setState(() => _cancelling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('L’opération a été interrompue. Réessayez.'),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() => _cancelling = false);
    ElaHaptics.softTap();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entitlement = ref.watch(entitlementStreamProvider).value;
    if (entitlement == null) {
      final failed = ref.watch(entitlementStreamProvider).hasError;
      return BookScaffold(
        appBar: BookAppBar(title: const Text('Ela Premium')),
        body: BookNotice(
          title: failed
              ? 'Cette page est momentanément indisponible'
              : 'Ouverture de votre édition…',
          loading: !failed,
          action: failed
              ? OutlinedButton(
                  onPressed: () => ref.invalidate(entitlementStreamProvider),
                  child: const Text('Réessayer'),
                )
              : null,
        ),
      );
    }
    final isPremium = entitlement.isPremium;

    return BookScaffold(
      backgroundColor: scheme.surface,
      appBar: BookAppBar(title: const Text('Ela Premium')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          ElaSize.v20,
          ElaSize.v8,
          ElaSize.v20,
          ElaSize.v32,
        ),
        children: [
          const ChapterHeader(
            chapter: 'V',
            title: 'L’édition intégrale',
            subtitle: 'Prenez le temps de tout lire.',
          ),
          const Center(child: Bookplate(icon: Icons.auto_stories_outlined)),
          const SizedBox(height: ElaSize.v24),
          Text(
            isPremium ? 'Votre édition Premium' : '2 €',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          Text(
            isPremium
                ? 'Membre depuis ${monthYear(entitlement.premiumSince!)}'
                : 'Par mois · sans engagement',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: ElaSize.v24),
          _FeatureRow(
            icon: Icons.format_list_numbered,
            title: '20 avis par livre',
            detail:
                'Tous les avis presse et web, jamais floutés — au lieu de 1 + 2.',
          ),
          const SizedBox(height: ElaSize.v8),
          _FeatureRow(
            icon: Icons.translate,
            title: 'Traduction automatique',
            detail: 'Les avis étrangers traduits par Ela, en un geste.',
          ),
          const SizedBox(height: ElaSize.v8),
          _FeatureRow(
            icon: Icons.sell,
            title: 'Radar à économies',
            detail:
                'Les occasions à prix doux du catalogue, triées par remise.',
          ),
          const SizedBox(height: ElaSize.v8),
          _FeatureRow(
            icon: Icons.handshake_outlined,
            title: 'MatchMaker',
            detail: 'Des scores de compatibilité d’après votre étagère.',
          ),
          const SizedBox(height: ElaSize.v8),
          _FeatureRow(
            icon: Icons.block,
            title: 'Sans pub',
            detail: 'Rien ne vous interrompt. Jamais.',
          ),
          const SizedBox(height: ElaSize.v8),
          _FeatureRow(
            icon: Icons.insights_outlined,
            title: 'Bilan de curiosité',
            detail: 'Vos statistiques de lecture, exportables en CSV.',
          ),
          const SizedBox(height: ElaSize.v8),
          _FeatureRow(
            icon: Icons.auto_awesome,
            title: '3 jetons IA / mois',
            detail: 'Débloquez la fiche complète d’un livre, résumé et tout.',
          ),
          const SizedBox(height: ElaSize.v32),
          if (_subscribing || _cancelling)
            Padding(
              padding: const EdgeInsets.only(bottom: ElaSize.v8),
              child: BreathingText(
                _subscribing ? 'Ouverture de votre abonnement…' : 'Annulation…',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: ElaSize.v14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (isPremium)
            OutlinedButton.icon(
              onPressed: _cancelling ? null : _cancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              icon: const Icon(Icons.cancel, size: ElaSize.v18),
              label: const Text('Annuler l’abonnement'),
            )
          else
            FilledButton(
              onPressed: _subscribing ? null : _subscribe,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: ElaSize.v16),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text(
                'Passer Premium — 2 €/mois',
                style: TextStyle(
                  fontSize: ElaSize.v15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(height: ElaSize.v12),
          Center(
            child: Text(
              'Démo — le paiement est simulé, rien n’est débité.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ElaSize.v11_5,
                fontStyle: FontStyle.italic,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: ElaSize.v38,
          height: ElaSize.v38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(
              context,
            ).colorScheme.secondary.withValues(alpha: 0.14),
          ),
          child: Icon(
            icon,
            size: ElaSize.v20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: ElaSize.v12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: ElaType.body,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: ElaSize.v2),
              Text(
                detail,
                style: TextStyle(
                  fontSize: ElaSize.v13,
                  height: ElaSize.v1_45,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// CTA compact « déverrouiller avec Premium », réutilisé sur les fiches
/// floutées et les écrans premium verrouillés.
class PremiumUnlockCard extends StatelessWidget {
  const PremiumUnlockCard({
    super.key,
    required this.message,
    this.compact = false,
  });

  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PageCard(
      child: Padding(
        padding: EdgeInsets.all(compact ? ElaSize.v14 : ElaSize.v18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: ElaSize.v22,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: ElaSize.v8),
                Expanded(
                  child: Text(
                    'Avec Ela Premium',
                    style: TextStyle(
                      fontFamily: ElaType.titleFamily,
                      fontSize: compact ? ElaSize.v14_5 : ElaSize.v16,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            if (!compact) ...[
              const SizedBox(height: ElaSize.v8),
              Text(
                message,
                style: TextStyle(
                  fontSize: ElaSize.v13_5,
                  height: ElaSize.v1_5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: ElaSize.v12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: () => context.push('/premium'),
                child: Text(
                  compact ? 'Découvrir Premium' : 'Voir Premium — 2 €/mois',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
