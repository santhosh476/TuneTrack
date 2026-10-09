/// Represents the authenticated or guest user of TuneTrack
class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final bool isGuest;
  final bool isSpotifyConnected;
  final String? spotifyDisplayName;
  final String? spotifyEmail;
  final int dailyGoalMinutes;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    this.email = '',
    required this.displayName,
    this.photoUrl,
    this.isGuest = true,
    this.isSpotifyConnected = false,
    this.spotifyDisplayName,
    this.spotifyEmail,
    this.dailyGoalMinutes = 45,
    required this.createdAt,
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isGuest,
    bool? isSpotifyConnected,
    String? spotifyDisplayName,
    String? spotifyEmail,
    int? dailyGoalMinutes,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isGuest: isGuest ?? this.isGuest,
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
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isGuest': isGuest ? 1 : 0,
      'isSpotifyConnected': isSpotifyConnected ? 1 : 0,
      'spotifyDisplayName': spotifyDisplayName,
      'spotifyEmail': spotifyEmail,
      'dailyGoalMinutes': dailyGoalMinutes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'Guest Listener',
      photoUrl: map['photoUrl'] as String?,
      isGuest: (map['isGuest'] == 1 || map['isGuest'] == true),
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
