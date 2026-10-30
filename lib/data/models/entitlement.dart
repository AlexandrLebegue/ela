import 'dart:convert';

enum EntitlementTier { free, premium }

class Entitlement {
  const Entitlement.free({this.aiTokens = 3, this.monthlyTokenLimit = 3})
      : tier = EntitlementTier.free,
        premiumSince = null;

  const Entitlement.premium({
    required this.aiTokens,
    required this.premiumSince,
    this.monthlyTokenLimit = 3,
  }) : tier = EntitlementTier.premium;

  final EntitlementTier tier;
  final int aiTokens;
  final int monthlyTokenLimit;
  final DateTime? premiumSince;

  bool get isPremium => tier == EntitlementTier.premium;

  int get freeVisiblePressCount => 1;
  int get freeVisibleWebCount => 2;

  bool canSeePressReview(int index) =>
      isPremium || index < freeVisiblePressCount;

  bool canSeeWebReview(int index) => isPremium || index < freeVisibleWebCount;

  bool canUnlockFullBook() => aiTokens > 0;

  Entitlement copyWith({
    EntitlementTier? tier,
    int? aiTokens,
    DateTime? premiumSince,
  }) =>
      tier == EntitlementTier.premium || this.tier == EntitlementTier.premium
          ? Entitlement.premium(
              aiTokens: aiTokens ?? this.aiTokens,
              premiumSince: premiumSince ?? this.premiumSince,
              monthlyTokenLimit: monthlyTokenLimit,
            )
          : Entitlement.free(
              aiTokens: aiTokens ?? this.aiTokens,
              monthlyTokenLimit: monthlyTokenLimit,
            );

  factory Entitlement.fromJson(Map<String, dynamic> json) {
    final tier = EntitlementTier.values
        .firstWhere((t) => t.name == json['tier'], orElse: () => EntitlementTier.free);
    final tokens = json['aiTokens'] as int? ?? 0;
    final limit = json['monthlyTokenLimit'] as int? ?? 3;
    final since = json['premiumSince'] == null
        ? null
        : DateTime.parse(json['premiumSince'] as String);
    return tier == EntitlementTier.premium
        ? Entitlement.premium(
            aiTokens: tokens,
            premiumSince: since ?? DateTime.now(),
            monthlyTokenLimit: limit,
          )
        : Entitlement.free(aiTokens: tokens, monthlyTokenLimit: limit);
  }

  Map<String, dynamic> toJson() => {
        'tier': tier.name,
        'aiTokens': aiTokens,
        'monthlyTokenLimit': monthlyTokenLimit,
        'premiumSince': premiumSince?.toIso8601String(),
      };
}

String entitlementToJsonString(Entitlement e) => jsonEncode(e.toJson());

Entitlement entitlementFromJsonString(String raw) =>
    Entitlement.fromJson(jsonDecode(raw) as Map<String, dynamic>);
