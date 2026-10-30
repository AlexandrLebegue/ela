import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import 'fake_delay.dart';

class FakeAuthService implements AuthService {
  FakeAuthService(this._prefs) {
    _profile = _loadOrAnonymous();
  }

  final SharedPreferences _prefs;
  static const _key = 'ela.profile';

  late UserProfile _profile;
  final StreamController<UserProfile> _controller =
      StreamController<UserProfile>.broadcast();

  @override
  UserProfile currentProfile() => _profile;

  @override
  Stream<UserProfile> watchProfile() => Stream.multi((controller) {
        // Instantané initial : un abonnement tardif ne rate pas l'état.
        controller.add(_profile);
        final sub = _controller.stream.listen(controller.add);
        controller.onCancel = sub.cancel;
      });

  UserProfile _loadOrAnonymous() =>
      userProfileFromJsonString(_prefs.getString(_key)) ??
      const UserProfile.anonymous();

  void _setProfile(UserProfile p) {
    _profile = p;
    _prefs.setString(
      _key,
      '{"id":"${p.id}","email":${_escape(p.email)},"displayName":${_escape(p.displayName)},"isAnonymous":${p.isAnonymous}}',
    );
    _controller.add(p);
  }

  String? _escape(String? s) =>
      s == null ? 'null' : '"${s.replaceAll('"', r'\"')}"';

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await fakeDelay();
    _setProfile(UserProfile(
      id: 'user-${email.hashCode.toRadixString(16)}',
      email: email,
      displayName: email.split('@').first,
    ));
  }

  @override
  Future<void> signInWithGoogle() async {
    await fakeDelay(min: const Duration(milliseconds: 600));
    _setProfile(const UserProfile(
      id: 'user-google-42',
      email: 'lecteur@gmail.com',
      displayName: 'Lecteur',
    ));
  }

  @override
  Future<void> signInWithApple() async {
    await fakeDelay(min: const Duration(milliseconds: 600));
    _setProfile(const UserProfile(
      id: 'user-apple-42',
      email: 'lecteur@icloud.com',
      displayName: 'Lecteur',
    ));
  }

  @override
  Future<void> signOut() async {
    await fakeDelay(
      min: const Duration(milliseconds: 200),
      max: const Duration(milliseconds: 600),
    );
    _profile = const UserProfile.anonymous();
    _prefs.remove(_key);
    _controller.add(_profile);
  }
}
