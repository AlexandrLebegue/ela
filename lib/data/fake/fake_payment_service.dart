import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/entitlement.dart';
import '../services/payment_service.dart';
import 'fake_delay.dart';

/// Freemium : 3 jetons IA/mois, Premium 2 €/mois (simulé).
class FakePaymentService implements PaymentService {
  FakePaymentService(this._prefs) {
    _entitlement = _load();
  }

  final SharedPreferences _prefs;
  static const _key = 'ela.entitlement';

  late Entitlement _entitlement;
  final StreamController<Entitlement> _controller =
      StreamController<Entitlement>.broadcast();

  @override
  Stream<Entitlement> watchEntitlement() => Stream.multi((controller) {
        // Instantané initial : un abonnement tardif ne rate pas l'état.
        controller.add(_entitlement);
        final sub = _controller.stream.listen(controller.add);
        controller.onCancel = sub.cancel;
      });

  Entitlement _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return const Entitlement.free();
    try {
      final e = entitlementFromJsonString(raw);
      return _resetMonthlyIfNeeded(e);
    } catch (_) {
      return const Entitlement.free();
    }
  }

  Entitlement _resetMonthlyIfNeeded(Entitlement e) {
    if (e.tier != EntitlementTier.free) return e;
    final storedMonth = _prefs.getString('ela.aiTokenMonth');
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month}';
    if (storedMonth == null || storedMonth != currentMonth) {
      _prefs.setString('ela.aiTokenMonth', currentMonth);
      return e.copyWith(aiTokens: e.monthlyTokenLimit);
    }
    return e;
  }

  void _persist() {
    _prefs.setString(_key, entitlementToJsonString(_entitlement));
    _controller.add(_entitlement);
  }

  @override
  Future<Entitlement> currentEntitlement() async {
    await fakeDelay(min: const Duration(milliseconds: 150),
        max: const Duration(milliseconds: 400));
    return _entitlement;
  }

  @override
  Future<void> subscribePremium() async {
    // Simule le flux RevenueCat + webhook Firestore (phase 2).
    await fakeDelay(min: const Duration(milliseconds: 800),
        max: const Duration(milliseconds: 1500));
    _entitlement = Entitlement.premium(
      aiTokens: _entitlement.monthlyTokenLimit,
      premiumSince: DateTime.now(),
    );
    _persist();
  }

  @override
  Future<void> cancelPremium() async {
    await fakeDelay(min: const Duration(milliseconds: 300),
        max: const Duration(milliseconds: 800));
    _entitlement = Entitlement.free(
      aiTokens: _entitlement.monthlyTokenLimit,
      monthlyTokenLimit: _entitlement.monthlyTokenLimit,
    );
    _persist();
  }

  @override
  Future<bool> spendAiToken() async {
    await fakeDelay(min: const Duration(milliseconds: 300),
        max: const Duration(milliseconds: 700));
    if (_entitlement.aiTokens <= 0) return false;
    _entitlement = _entitlement.copyWith(aiTokens: _entitlement.aiTokens - 1);
    _persist();
    return true;
  }

  @override
  Future<String> affiliatePurchaseLink(String isbn) async {
    await fakeDelay(min: const Duration(milliseconds: 200),
        max: const Duration(milliseconds: 500));
    return 'https://affiliation.ela.app/acheter?isbn=$isbn';
  }
}
