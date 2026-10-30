import '../models/user_profile.dart';

/// Authentification « lazy registration » : l'utilisateur démarre anonyme,
/// le compte est créé/lié plus tard (avis, cloud, paiement).
abstract interface class AuthService {
  UserProfile currentProfile();

  Stream<UserProfile> watchProfile();

  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signInWithGoogle();

  Future<void> signInWithApple();

  Future<void> signOut();
}
