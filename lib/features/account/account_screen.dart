import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animations.dart';
import '../../core/format.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../data/models/library_entry.dart';
import '../../data/models/user_profile.dart';
import '../../providers.dart';

/// Compte (lazy registration) : aucun compte au démarrage. Cet écran est
/// ouvert seulement quand l'utilisateur en a besoin — publier un avis,
/// sauvegarder dans le cloud, payer — ou depuis l'icône profil.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  _AuthMethod? _busy;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.length < 5 || !email.contains('@')) {
      setState(() => _error = 'Entrez une adresse e-mail valide.');
      return;
    }
    if (password.length < 6) {
      setState(
        () => _error = 'Le mot de passe doit compter 6 caractères au moins.',
      );
      return;
    }
    await _run(
      _AuthMethod.email,
      () => ref
          .read(authServiceProvider)
          .signInWithEmail(email: email, password: password),
    );
  }

  Future<void> _signInWithGoogle() => _run(
    _AuthMethod.google,
    () => ref.read(authServiceProvider).signInWithGoogle(),
  );

  Future<void> _signInWithApple() => _run(
    _AuthMethod.apple,
    () => ref.read(authServiceProvider).signInWithApple(),
  );

  Future<void> _run(_AuthMethod method, Future<void> Function() action) async {
    if (_busy != null) return;
    setState(() {
      _busy = method;
      _error = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = null;
          _error = 'La connexion a été interrompue. Vous pouvez réessayer.';
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() => _busy = null);
    final profile = ref.read(authServiceProvider).currentProfile();
    ElaHaptics.heartbeat();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bienvenue, ${profile.displayNameOrEmail} !')),
    );
  }

  Future<void> _signOut() async {
    if (_busy != null) return;
    setState(() => _busy = _AuthMethod.signOut);
    await ref.read(authServiceProvider).signOut();
    if (!mounted) return;
    setState(() => _busy = null);
    ElaHaptics.softTap();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final profile =
        ref.watch(profileStreamProvider).value ??
        ref.read(authServiceProvider).currentProfile();

    return BookScaffold(
      backgroundColor: scheme.surface,
      appBar: BookAppBar(
        title: const Text('Votre espace'),
        actions: [
          if (!profile.isAnonymous)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Se déconnecter',
              onPressed: _busy == null ? _signOut : null,
            ),
        ],
      ),
      body: _busy != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(ElaSize.v28),
                child: BreathingText(
                  'Connexion à votre compte Ela…',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: ElaSize.v15,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          : profile.isAnonymous
          ? _AnonymousView(
              emailController: _emailController,
              passwordController: _passwordController,
              error: _error,
              onEmail: _signInWithEmail,
              onGoogle: _signInWithGoogle,
              onApple: _signInWithApple,
            )
          : _ProfileView(profile: profile, onSignOut: _signOut),
    );
  }
}

enum _AuthMethod { email, google, apple, signOut }

class _AnonymousView extends StatelessWidget {
  const _AnonymousView({
    required this.emailController,
    required this.passwordController,
    required this.error,
    required this.onEmail,
    required this.onGoogle,
    required this.onApple,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String? error;
  final Future<void> Function() onEmail;
  final Future<void> Function() onGoogle;
  final Future<void> Function() onApple;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        ElaSize.v20,
        ElaSize.v8,
        ElaSize.v20,
        ElaSize.v32,
      ),
      children: [
        const SizedBox(height: ElaSize.v24),
        const Center(child: Bookplate(icon: Icons.person_outline)),
        const SizedBox(height: ElaSize.v14),
        Center(
          child: Text(
            'Bienvenue chez Ela',
            style: TextStyle(
              fontFamily: ElaType.titleFamily,
              fontSize: ElaSize.v22,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: ElaSize.v8),
        Center(
          child: Text(
            'Explorez librement, sans compte. Un compte Ela est demandé '
            'uniquement pour : publier un avis, sauvegarder votre '
            'bibliothèque dans le cloud, ou payer.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ElaSize.v13_5,
              height: ElaSize.v1_55,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: ElaSize.v28),
        Text(
          'Créer mon compte, ou me connecter',
          style: TextStyle(
            fontFamily: ElaType.titleFamily,
            fontSize: ElaSize.v16,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: ElaSize.v14),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Adresse e-mail',
            prefixIcon: Icon(Icons.mail_outline),
          ),
        ),
        const SizedBox(height: ElaSize.v12),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Mot de passe',
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ElaSize.v4,
              ElaSize.v8,
              ElaSize.v4,
              ElaSize.v0,
            ),
            child: Text(
              error!,
              style: TextStyle(
                fontSize: ElaSize.v13,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        const SizedBox(height: ElaSize.v16),
        FilledButton(
          onPressed: onEmail,
          child: const Text('Continuer avec mon e-mail'),
        ),
        const SizedBox(height: ElaSize.v18),
        Row(
          children: [
            Expanded(
              child: Divider(color: scheme.outline.withValues(alpha: 0.4)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ElaSize.v10),
              child: Text(
                'ou',
                style: TextStyle(
                  fontSize: ElaSize.v12_5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Divider(color: scheme.outline.withValues(alpha: 0.4)),
            ),
          ],
        ),
        const SizedBox(height: ElaSize.v18),
        OutlinedButton.icon(
          onPressed: onGoogle,
          icon: const Icon(Icons.account_circle_outlined, size: ElaSize.v18),
          label: const Text('Continuer avec Google'),
        ),
        const SizedBox(height: ElaSize.v10),
        OutlinedButton.icon(
          onPressed: onApple,
          icon: const Icon(Icons.phone_iphone, size: ElaSize.v18),
          label: const Text('Continuer avec Apple'),
        ),
        const SizedBox(height: ElaSize.v24),
        Center(
          child: Text(
            'Démo — les connexions sont simulées, rien n’est envoyé '
            'nulle part.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ElaSize.v11_5,
              fontStyle: FontStyle.italic,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileView extends ConsumerWidget {
  const _ProfileView({required this.profile, required this.onSignOut});

  final UserProfile profile;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final name = profile.displayNameOrEmail;
    final initial = name.substring(0, 1).toUpperCase();
    final entitlement = ref.watch(entitlementStreamProvider).value;
    if (entitlement == null) {
      return BookNotice(
        title: ref.watch(entitlementStreamProvider).hasError
            ? 'Votre compte attend une reprise'
            : 'Ouverture de votre compte…',
        loading: !ref.watch(entitlementStreamProvider).hasError,
        action: TextButton(
          onPressed: () => ref.invalidate(entitlementStreamProvider),
          child: const Text('Réessayer'),
        ),
      );
    }
    final entries =
        ref.watch(libraryEntriesProvider).value ?? const <LibraryEntry>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        ElaSize.v20,
        ElaSize.v8,
        ElaSize.v20,
        ElaSize.v32,
      ),
      children: [
        const SizedBox(height: ElaSize.v28),
        Center(
          child: Container(
            width: ElaSize.v76,
            height: ElaSize.v76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(
                context,
              ).colorScheme.secondary.withValues(alpha: 0.16),
              border: Border.all(
                color: Theme.of(context).colorScheme.secondary,
                width: ElaSize.v2,
              ),
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  fontFamily: ElaType.titleFamily,
                  fontSize: ElaSize.v30,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: ElaSize.v14),
        Center(
          child: Text(
            name,
            style: TextStyle(
              fontFamily: ElaType.titleFamily,
              fontSize: ElaSize.v20,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ),
        if (profile.email != null) ...[
          const SizedBox(height: ElaSize.v4),
          Center(
            child: Text(
              profile.email!,
              style: TextStyle(
                fontSize: ElaSize.v13_5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
        const SizedBox(height: ElaSize.v12),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ElaSize.v12,
              vertical: ElaSize.v5,
            ),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(ElaSpace.radius),
            ),
            child: Text(
              'Membre d’Ela',
              style: TextStyle(
                fontSize: ElaSize.v12,
                fontWeight: FontWeight.w700,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
        const SizedBox(height: ElaSize.v28),
        PageCard(
          child: Padding(
            padding: const EdgeInsets.all(ElaSize.v16),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_outlined,
                  size: ElaSize.v22,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: ElaSize.v12),
                Expanded(
                  child: Text(
                    'Votre bibliothèque (Historique + Pile à Lire) est '
                    'sauvegardée sur cet appareil. La synchronisation cloud '
                    'est simulée pour la démo.',
                    style: TextStyle(
                      fontSize: ElaSize.v13_5,
                      height: ElaSize.v1_5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (entitlement.isPremium) ...[
          const SizedBox(height: ElaSize.v12),
          _BilanCard(
            history: entries
                .where((e) => e.section == LibrarySection.history)
                .length,
            toRead: entries
                .where((e) => e.section == LibrarySection.toRead)
                .length,
            tokens: entitlement.aiTokens,
            reviews:
                ref
                    .read(sharedPreferencesProvider)
                    .getInt('ela.stats.reviews') ??
                0,
          ),
        ] else
          _PremiumCard(
            onTap: () => GoRouter.maybeOf(context)?.push('/premium'),
          ),
        const SizedBox(height: ElaSize.v24),
        OutlinedButton.icon(
          onPressed: onSignOut,
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          icon: const Icon(Icons.logout, size: ElaSize.v18),
          label: const Text('Se déconnecter'),
        ),
        const SizedBox(height: ElaSize.v16),
        Center(
          child: Text(
            'Se déconnecter ne supprime rien de votre bibliothèque locale.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ElaSize.v12,
              fontStyle: FontStyle.italic,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// Invite Premium (version gratuite) : résumé des fonctions + CTA.
class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PageCard(
      child: Padding(
        padding: const EdgeInsets.all(ElaSize.v16),
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
                const SizedBox(width: ElaSize.v10),
                Expanded(
                  child: Text(
                    'Ela Premium — 2 €/mois',
                    style: TextStyle(
                      fontFamily: ElaType.titleFamily,
                      fontSize: ElaSize.v15_5,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: ElaSize.v8),
            Text(
              '20 avis par livre, traduction des avis étrangers, Radar à '
              'économies, MatchMaker, sans pub, Bilan de curiosité exportable.',
              style: TextStyle(
                fontSize: ElaSize.v13,
                height: ElaSize.v1_5,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: ElaSize.v12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: onTap,
                child: const Text('Découvrir Premium'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bilan de curiosité (Premium) : statistiques + export CSV.
class _BilanCard extends StatelessWidget {
  const _BilanCard({
    required this.history,
    required this.toRead,
    required this.tokens,
    required this.reviews,
  });

  final int history;
  final int toRead;
  final int tokens;
  final int reviews;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PageCard(
      child: Padding(
        padding: const EdgeInsets.all(ElaSize.v16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights_outlined,
                  size: ElaSize.v22,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: ElaSize.v10),
                Expanded(
                  child: Text(
                    'Bilan de curiosité',
                    style: TextStyle(
                      fontFamily: ElaType.titleFamily,
                      fontSize: ElaSize.v15_5,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: ElaSize.v12),
            Row(
              children: [
                _Stat(label: 'Lus', value: formatInt(history)),
                _Stat(label: 'En PAL', value: formatInt(toRead)),
                _Stat(label: 'Jetons IA', value: formatInt(tokens)),
                _Stat(label: 'Avis', value: formatInt(reviews)),
              ],
            ),
            const SizedBox(height: ElaSize.v12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => _exportCsv(context),
                icon: const Icon(
                  Icons.file_download_outlined,
                  size: ElaSize.v17,
                ),
                label: const Text('Exporter en CSV'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _exportCsv(BuildContext context) {
    final csv = [
      'champ;valeur',
      'livres_lus;$history',
      'pile_a_lire;$toRead',
      'jetons_ia_ce_mois;$tokens',
      'avis_publies;$reviews',
      'statut;premium',
    ].join('\n');
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bilan de curiosité — CSV'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                csv,
                style: const TextStyle(
                  fontSize: ElaSize.v13,
                  fontFamily: ElaType.labelFamily,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csv));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('CSV copié dans le presse-papier.'),
                ),
              );
            },
            child: const Text('Copier'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ElaSize.v4),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: ElaType.titleFamily,
                fontSize: ElaSize.v20,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: ElaSize.v2),
            Text(
              label,
              style: TextStyle(
                fontSize: ElaSize.v11_5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
