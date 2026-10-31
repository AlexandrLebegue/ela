import '../models/review.dart';

/// Avis de la communauté Ela (onglet « La Communauté »).
abstract interface class ReviewService {
  Future<List<Review>> communityReviews(String isbn);

  /// Publie un avis (compte requis en phase 2).
  Future<Review> addCommunityReview(Review review);

  Future<void> deleteCommunityReview(String isbn, String userId);

  /// Signalement d'un avis (modération IA en phase 2).
  Future<void> reportReview(String reviewId);
}
