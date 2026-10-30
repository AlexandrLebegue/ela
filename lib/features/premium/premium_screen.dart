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
    await ref.read(paymentServiceProvider).subscribePremium();
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
    await ref.read(paymentServiceProvider).cancelPremium();
    if (!mounted) return;
    setState(() => _cancelling = false);
    ElaHaptics.softTap();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entitlement = ref.watch(entitlementStreamProvider).value;
    if (entitlement == null) return const SizedBox.shrink();
    final isPremium = entitlement.isPremium;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(title: const Text('Ela Premium')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ElaColors.gold.withValues(alpha: 0.18),
                border: Border.all(color: ElaColors.gold, width: 2),
              ),
              child: const Center(
                child: Icon(Icons.auto_awesome, color: ElaColors.gold, size: 40),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Ela Premium',
              style: TextStyle(
                fontFamily: 'Lora',
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              isPremium
                  ? 'Membre depuis ${monthYear(entitlement.premiumSince!)}'
                  : '2 € / mois — sans engagement, annulable à tout moment',
              style: TextStyle(
                fontSize: 14,
                color: isPremium ? ElaColors.sepiaDeep : scheme.onSurfaceVariant,
                fontWeight: isPremium ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 28),
          _FeatureRow(
            icon: Icons.format_list_numbered,
            title: '20 avis par livre',
            detail:
                'Tous les avis presse et web, jamais floutés — au lieu de 1 + 2.',
          ),
          const SizedBox(height: 8),
          _FeatureRow(
            icon: Icons.translate,
            title: 'Traduction automatique',
            detail: 'Les avis étrangers traduits par Ela, en un geste.',
          ),
          const SizedBox(height: 8),
          _FeatureRow(
            icon: Icons.sell,
            title: 'Radar à économies',
            detail: 'Les occasions à prix doux du catalogue, triées par remise.',
          ),
          const SizedBox(height: 8),
          _FeatureRow(
            icon: Icons.handshake_outlined,
            title: 'MatchMaker',
            detail: 'Des scores de compatibilité d’après votre étagère.',
          ),
          const SizedBox(height: 8),
          _FeatureRow(
            icon: Icons.block,
            title: 'Sans pub',
            detail: 'Rien ne vous interrompt. Jamais.',
          ),
          const SizedBox(height: 8),
          _FeatureRow(
            icon: Icons.insights_outlined,
            title: 'Bilan de curiosité',
            detail: 'Vos statistiques de lecture, exportables en CSV.',
          ),
          const SizedBox(height: 8),
          _FeatureRow(
            icon: Icons.auto_awesome,
            title: '3 jetons IA / mois',
            detail:
                'Débloquez la fiche complète d’un livre, résumé et tout.',
          ),
          const SizedBox(height: 32),
          if (_subscribing || _cancelling)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: BreathingText(
                _subscribing ? 'Ouverture de votre abonnement…' : 'Annulation…',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (isPremium)
            OutlinedButton.icon(
              onPressed: _cancelling ? null : _cancel,
              style: OutlinedButton.styleFrom(foregroundColor: ElaColors.error),
              icon: const Icon(Icons.cancel, size: 18),
              label: const Text('Annuler l’abonnement'),
            )
          else
            FilledButton(
              onPressed: _subscribing ? null : _subscribe,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: ElaColors.sepiaDeep,
              ),
              child: const Text(
                'Passer Premium — 2 €/mois',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Démo — le paiement est simulé, rien n’est débité.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
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
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ElaColors.gold.withValues(alpha: 0.14),
          ),
          child: Icon(icon, size: 20, color: ElaColors.sepiaDeep),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
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
    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 14 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 22, color: ElaColors.gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Avec Ela Premium',
                    style: TextStyle(
                      fontFamily: 'Lora',
                      fontSize: compact ? 14.5 : 16,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            if (!compact) ...[
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
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
