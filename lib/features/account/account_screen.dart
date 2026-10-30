import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/animations.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
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
      setState(() =>
          _error = 'Le mot de passe doit compter 6 caractères au moins.');
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
    await action();
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
    final profile = ref.watch(profileStreamProvider).value ??
        ref.read(authServiceProvider).currentProfile();

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
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
                padding: const EdgeInsets.all(28),
                child: BreathingText(
                  'Connexion à votre compte Ela…',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 15,
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        const SizedBox(height: 24),
        Center(
          child: Icon(Icons.auto_awesome, size: 44, color: ElaColors.gold),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            'Bienvenue chez Ela',
            style: TextStyle(
              fontFamily: 'Lora',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Explorez librement, sans compte. Un compte Ela est demandé '
            'uniquement pour : publier un avis, sauvegarder votre '
            'bibliothèque dans le cloud, ou payer.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.55,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Créer mon compte, ou me connecter',
          style: TextStyle(
            fontFamily: 'Lora',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'Adresse e-mail',
            prefixIcon: Icon(Icons.mail_outline),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Mot de passe',
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Text(
              error!,
              style: TextStyle(fontSize: 13, color: ElaColors.error),
            ),
          ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: onEmail,
          child: const Text('Continuer avec mon e-mail'),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
                child: Divider(
                    color: scheme.outline.withValues(alpha: 0.4))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'ou',
                style: TextStyle(
                    fontSize: 12.5, color: scheme.onSurfaceVariant),
              ),
            ),
            Expanded(
                child: Divider(
                    color: scheme.outline.withValues(alpha: 0.4))),
          ],
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: onGoogle,
          icon: const Icon(Icons.account_circle_outlined, size: 18),
          label: const Text('Continuer avec Google'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onApple,
          icon: const Icon(Icons.phone_iphone, size: 18),
          label: const Text('Continuer avec Apple'),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'Démo — les connexions sont simulées, rien n’est envoyé '
            'nulle part.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontStyle: FontStyle.italic,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.profile, required this.onSignOut});

  final UserProfile profile;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = profile.displayNameOrEmail;
    final initial = name.substring(0, 1).toUpperCase();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        const SizedBox(height: 28),
        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ElaColors.gold.withValues(alpha: 0.16),
              border: Border.all(color: ElaColors.gold, width: 2),
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: ElaColors.sepiaDeep,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            name,
            style: TextStyle(
              fontFamily: 'Lora',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ),
        if (profile.email != null) ...[
          const SizedBox(height: 4),
          Center(
            child: Text(
              profile.email!,
              style: TextStyle(
                fontSize: 13.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Membre d’Ela',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.cloud_outlined,
                    size: 22, color: scheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Votre bibliothèque (Historique + Pile à Lire) est '
                    'sauvegardée sur cet appareil. La synchronisation cloud '
                    'est simulée pour la démo.',
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: onSignOut,
          style: OutlinedButton.styleFrom(
            foregroundColor: ElaColors.error,
          ),
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Se déconnecter'),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Se déconnecter ne supprime rien de votre bibliothèque locale.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
