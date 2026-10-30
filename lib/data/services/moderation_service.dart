/// Modération des avis (anti-injures / spam / pub déguisée).
/// Simulée en phase 1 (liste de mots), IA en phase 2.
abstract interface class ModerationService {
  /// Retourne `true` si le texte est publiable.
  Future<bool> isAllowed(String text);
}
