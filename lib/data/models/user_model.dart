/// Represents the authenticated or guest user of TuneTrack
class UserModel {
  final String id;
  final String email;
  final String phoneNumber;
  final String displayName;
  final String? photoUrl;
  final bool isGuest;
  final String authProvider; // 'guest', 'google', 'phone', 'email'
  final List<String> preferredLanguages;
  final String primaryLanguage;
  final bool isSpotifyConnected;
  final String? spotifyDisplayName;
  final String? spotifyEmail;
  final int dailyGoalMinutes;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    this.email = '',
    this.phoneNumber = '',
    required this.displayName,
    this.photoUrl,
    this.isGuest = true,
    this.authProvider = 'guest',
    this.preferredLanguages = const ['Tamil', 'English'],
    this.primaryLanguage = 'Tamil',
    this.isSpotifyConnected = false,
    this.spotifyDisplayName,
    this.spotifyEmail,
    this.dailyGoalMinutes = 45,
    required this.createdAt,
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? phoneNumber,
    String? displayName,
    String? photoUrl,
    bool? isGuest,
    String? authProvider,
    List<String>? preferredLanguages,
    String? primaryLanguage,
    bool? isSpotifyConnected,
    String? spotifyDisplayName,
    String? spotifyEmail,
    int? dailyGoalMinutes,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isGuest: isGuest ?? this.isGuest,
      authProvider: authProvider ?? this.authProvider,
      preferredLanguages: preferredLanguages ?? this.preferredLanguages,
      primaryLanguage: primaryLanguage ?? this.primaryLanguage,
      isSpotifyConnected: isSpotifyConnected ?? this.isSpotifyConnected,
      spotifyDisplayName: spotifyDisplayName ?? this.spotifyDisplayName,
      spotifyEmail: spotifyEmail ?? this.spotifyEmail,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isGuest': isGuest ? 1 : 0,
      'authProvider': authProvider,
      'preferredLanguages': preferredLanguages,
      'primaryLanguage': primaryLanguage,
      'isSpotifyConnected': isSpotifyConnected ? 1 : 0,
      'spotifyDisplayName': spotifyDisplayName,
      'spotifyEmail': spotifyEmail,
      'dailyGoalMinutes': dailyGoalMinutes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final rawLanguages = map['preferredLanguages'];
    List<String> languages = ['Tamil', 'English'];
    if (rawLanguages is List) {
      languages = rawLanguages.map((e) => e.toString()).toList();
    }

    return UserModel(
      id: map['id'] as String,
      email: map['email'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'Guest Listener',
      photoUrl: map['photoUrl'] as String?,
      isGuest: (map['isGuest'] == 1 || map['isGuest'] == true),
      authProvider: map['authProvider'] as String? ?? 'guest',
      preferredLanguages: languages,
      primaryLanguage: map['primaryLanguage'] as String? ??
          (languages.isNotEmpty ? languages.first : 'Tamil'),
      isSpotifyConnected:
          (map['isSpotifyConnected'] == 1 || map['isSpotifyConnected'] == true),
      spotifyDisplayName: map['spotifyDisplayName'] as String?,
      spotifyEmail: map['spotifyEmail'] as String?,
      dailyGoalMinutes: (map['dailyGoalMinutes'] as num?)?.toInt() ?? 45,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
