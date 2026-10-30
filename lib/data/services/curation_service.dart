import '../models/curation_result.dart';

/// Curation IA : sélectionne et extrait les meilleurs avis existants
/// (5 presse + 15 web) et produit une synthèse courte. Simulé en phase 1.
abstract interface class CurationService {
  /// Simule le travail de curation (~15 s côté serveur réel).
  /// Le résultat est ensuite mis en cache par ISBN.
  Future<CurationResult> curate(String isbn);
}
