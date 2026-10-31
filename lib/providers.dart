import 'data/fake/fake_market_service.dart';
import 'data/models/market.dart';
import 'data/services/market_service.dart';
import 'features/market/market_screen.dart';
import 'data/fake/fake_rating_service.dart';
import 'data/services/rating_service.dart';
import 'data/models/rating.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/fake/fake_auth_service.dart';
import 'data/fake/fake_book_lookup_service.dart';
import 'data/fake/fake_curation_service.dart';
import 'data/fake/fake_library_service.dart';
import 'data/fake/fake_moderation_service.dart';
import 'data/fake/fake_payment_service.dart';
import 'data/fake/fake_review_service.dart';
import 'data/fake/fake_trend_service.dart';
import 'data/models/book.dart';
import 'data/models/curation_result.dart';
import 'data/models/entitlement.dart';
import 'data/models/library_entry.dart';
import 'data/models/review.dart';
import 'data/models/user_profile.dart';
import 'data/services/auth_service.dart';
import 'data/services/book_lookup_service.dart';
import 'data/services/curation_service.dart';
import 'data/services/library_service.dart';
import 'data/services/moderation_service.dart';
import 'data/services/payment_service.dart';
import 'data/services/review_service.dart';
import 'data/services/trend_service.dart';
import 'features/account/account_screen.dart';
import 'features/book_detail/book_detail_screen.dart';
import 'features/premium/matchmaker_screen.dart';
import 'features/premium/premium_screen.dart';
import 'features/home_shell.dart';
import 'features/library/library_screen.dart';
import 'features/scanner/scanner_screen.dart';
import 'features/search/search_screen.dart';
import 'features/trending/trending_screen.dart';

/// Sélection du backend : `--dart-define=BACKEND=fake|firebase`.
/// Phase 1 = `fake` (défaut). Phase 2 = implémentations Firebase
/// (voir lib/data/firebase/README.md) — l'UI ne change pas.
const String kBackend = String.fromEnvironment('BACKEND', defaultValue: 'fake');

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    ' sharedPreferencesProvider doit être surchargé dans main()',
  ),
);

final authServiceProvider = Provider<AuthService>((ref) {
  if (kBackend == 'firebase') {
    throw UnimplementedError(
      'Firebase (phase 2) — voir lib/data/firebase/README.md',
    );
  }
  return FakeAuthService(ref.watch(sharedPreferencesProvider));
});

final bookLookupServiceProvider = Provider<BookLookupService>((ref) {
  if (kBackend == 'firebase') {
    throw UnimplementedError(
      'Firebase (phase 2) — voir lib/data/firebase/README.md',
    );
  }
  return FakeBookLookupService();
});

final curationServiceProvider = Provider<CurationService>((ref) {
  if (kBackend == 'firebase') {
    throw UnimplementedError(
      'Firebase (phase 2) — voir lib/data/firebase/README.md',
    );
  }
  return FakeCurationService();
});

final reviewServiceProvider = Provider<ReviewService>((ref) {
  if (kBackend == 'firebase') {
    throw UnimplementedError(
      'Firebase (phase 2) — voir lib/data/firebase/README.md',
    );
  }
  return FakeReviewService(ref.watch(sharedPreferencesProvider));
});

final libraryServiceProvider = Provider<LibraryService>((ref) {
  if (kBackend == 'firebase') {
    throw UnimplementedError(
      'Firebase (phase 2) — voir lib/data/firebase/README.md',
    );
  }
  return FakeLibraryService(ref.watch(sharedPreferencesProvider));
});

final paymentServiceProvider = Provider<PaymentService>((ref) {
  if (kBackend == 'firebase') {
    throw UnimplementedError(
      'Firebase (phase 2) — voir lib/data/firebase/README.md',
    );
  }
  return FakePaymentService(ref.watch(sharedPreferencesProvider));
});

final trendServiceProvider = Provider<TrendService>((ref) {
  if (kBackend == 'firebase') {
    throw UnimplementedError(
      'Firebase (phase 2) — voir lib/data/firebase/README.md',
    );
  }
  return FakeTrendService();
});

final moderationServiceProvider = Provider<ModerationService>((ref) {
  if (kBackend == 'firebase') {
    throw UnimplementedError(
      'Firebase (phase 2) — voir lib/data/firebase/README.md',
    );
  }
  return FakeModerationService();
});

final profileProvider = Provider<UserProfile>(
  (ref) =>
      ref.watch(profileStreamProvider).value ??
      ref.watch(authServiceProvider).currentProfile(),
);

/// Profil réactif (se met à jour à la connexion / déconnexion).
final profileStreamProvider = StreamProvider<UserProfile>(
  (ref) => ref.watch(authServiceProvider).watchProfile(),
);

final entitlementProvider = FutureProvider<Entitlement>(
  (ref) => ref.watch(paymentServiceProvider).currentEntitlement(),
);

/// Entitlement réactif (jetons dépensés, abonnement, annulation).
final entitlementStreamProvider = StreamProvider<Entitlement>(
  (ref) => ref.watch(paymentServiceProvider).watchEntitlement(),
);

/// Fiches « déblocquées » avec un jeton IA (session courante).
class _UnlockedBooksNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void unlock(String isbn) => state = {...state, isbn};

  void lockAll() => state = const {};
}

final unlockedBooksProvider =
    NotifierProvider<_UnlockedBooksNotifier, Set<String>>(
      _UnlockedBooksNotifier.new,
    );

/// Livre par ISBN (catalogue local, sinon API Google Books).
final bookByIsbnProvider = FutureProvider.family<Book?, String>(
  (ref, isbn) => ref.watch(bookLookupServiceProvider).lookupByIsbn(isbn),
);

/// Curation IA par ISBN (synthèse + 5 avis presse + 15 avis web),
/// mise en cache par Riverpod (family).
final curationProvider = FutureProvider.family<CurationResult, String>(
  (ref, isbn) => ref.watch(curationServiceProvider).curate(isbn),
);

/// Avis de la communauté Ela par ISBN.
final communityReviewsProvider = FutureProvider.family<List<Review>, String>(
  (ref, isbn) => ref.watch(reviewServiceProvider).communityReviews(isbn),
);

final libraryEntriesProvider = StreamProvider<List<LibraryEntry>>(
  (ref) => ref.watch(libraryServiceProvider).watchEntries(),
);

final trendingProvider = FutureProvider.family<List<Book>, String?>((
  ref,
  category,
) {
  return ref.watch(trendServiceProvider).trending(category: category);
});

final categoriesProvider = FutureProvider<List<String>>(
  (ref) => ref.watch(trendServiceProvider).categories(),
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final saved = ref
        .watch(sharedPreferencesProvider)
        .getString('ela.themeMode');
    return ThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => ThemeMode.system,
    );
  }

  void set(ThemeMode mode) {
    state = mode;
    ref.read(sharedPreferencesProvider).setString('ela.themeMode', mode.name);
  }

  void toggle() {
    final dark =
        state == ThemeMode.dark ||
        (state == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);
    set(dark ? ThemeMode.light : ThemeMode.dark);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// Onboarding (3 écrans) : montré une seule fois, mémorisé dans les
/// SharedPreferences (`ela.onboarded`).
class OnboardedNotifier extends Notifier<bool> {
  @override
  bool build() =>
      ref.watch(sharedPreferencesProvider).getBool('ela.onboarded') ?? false;

  Future<void> finish() async {
    state = true;
    await ref.read(sharedPreferencesProvider).setBool('ela.onboarded', true);
  }
}

final onboardedProvider = NotifierProvider<OnboardedNotifier, bool>(
  OnboardedNotifier.new,
);

/// Shell à 5 branches : Tendance / Scanner / Bibliothèque / Recherche / Marché.
/// Le détail livre est hors shell (pas de bottom bar).
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/tendance',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tendance',
                builder: (context, state) => const TrendingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/scanner',
                builder: (context, state) => const ScannerScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bibliotheque',
                builder: (context, state) => const LibraryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/recherche',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/marche',
                builder: (context, state) => MarketScreen(
                  isbn: state.uri.queryParameters['isbn'],
                  radar: state.uri.queryParameters['vue'] == 'radar',
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/annonce/:id',
        builder: (context, state) =>
            ListingScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/livre/:isbn',
        builder: (context, state) => BookDetailScreen(
          isbn: state.pathParameters['isbn']!,
          heroTag: state.extra is String ? state.extra as String : null,
        ),
      ),
      GoRoute(
        path: '/compte',
        builder: (context, state) => const AccountScreen(),
      ),
      GoRoute(
        path: '/premium',
        builder: (context, state) => const PremiumScreen(),
      ),
      GoRoute(
        path: '/radar',
        redirect: (context, state) => '/marche?vue=radar',
      ),
      GoRoute(
        path: '/match',
        builder: (context, state) => const MatchMakerScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

final ratingServiceProvider = Provider<RatingService>((ref) {
  if (kBackend == 'firebase') {
    throw UnimplementedError('Firebase ratings — voir data/firebase/README.md');
  }
  return FakeRatingService(ref.watch(sharedPreferencesProvider));
});
final ratingsStreamProvider = StreamProvider<List<BookRating>>(
  (ref) => ref.watch(ratingServiceProvider).watchRatings(),
);
final ratingsProvider = Provider<List<BookRating>>(
  (ref) =>
      ref.watch(ratingsStreamProvider).value ??
      ref.watch(ratingServiceProvider).currentRatings(),
);
final ratingSummaryProvider = Provider.family<RatingSummary, String>(
  (ref, isbn) =>
      RatingSummary(ref.watch(ratingsProvider).where((r) => r.isbn == isbn)),
);
final personalRatingProvider = Provider.family<double?, String>((ref, isbn) {
  final uid = ref.watch(profileProvider).id;
  return ref
      .watch(ratingsProvider)
      .where((r) => r.isbn == isbn && r.userId == uid)
      .firstOrNull
      ?.value;
});

final marketServiceProvider = Provider<MarketService>((ref) {
  if (kBackend == 'firebase') {
    throw UnimplementedError('Firebase market — voir data/firebase/README.md');
  }
  return FakeMarketService(ref.watch(sharedPreferencesProvider));
});
final marketListingsProvider = StreamProvider<List<ReaderListing>>(
  (ref) => ref.watch(marketServiceProvider).watchListings(),
);
final bookOffersProvider = FutureProvider.family<List<BookOffer>, String>(
  (ref, isbn) => ref.watch(marketServiceProvider).offers(isbn),
);
