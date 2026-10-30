import 'dart:convert';

class UserProfile {
  const UserProfile.anonymous()
      : this(
          id: 'anonymous',
          email: null,
          displayName: null,
          isAnonymous: true,
        );

  const UserProfile({
    required this.id,
    this.email,
    this.displayName,
    this.isAnonymous = false,
  });

  final String id;
  final String? email;
  final String? displayName;
  final bool isAnonymous;

  String get displayNameOrEmail =>
      (displayName?.isNotEmpty == true ? displayName! : (email ?? 'Compte Ela'));

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        email: json['email'] as String?,
        displayName: json['displayName'] as String?,
        isAnonymous: json['isAnonymous'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'isAnonymous': isAnonymous,
      };
}

UserProfile? userProfileFromJsonString(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    return UserProfile.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  } catch (_) {
    return null;
  }
}
