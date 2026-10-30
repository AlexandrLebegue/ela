import '../models/entitlement.dart';

/// Freemium : entitlement, jetons IA, paiement (fake en phase 1).
abstract interface class PaymentService {
  Future<Entitlement> currentEntitlement();

  Stream<Entitlement> watchEntitlement();

  /// Abonnement Premium (2 €/mois) — simulé.
  Future<void> subscribePremium();

  Future<void> cancelPremium();

  /// Débloque la fiche complète d'un livre (1 jeton IA).
  Future<bool> spendAiToken();

  /// Lien d'achat affilié fictif.
  Future<String> affiliatePurchaseLink(String isbn);
}
