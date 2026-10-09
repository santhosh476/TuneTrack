/// Represents a user or curated playlist
class PlaylistModel {
  final String id;
  final String title;
  final String description;
  final String? coverUrl;
  final String userId;
  final bool isPublic;
  final bool isFavourite;
  final List<String> trackIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  const PlaylistModel({
    required this.id,
    required this.title,
    this.description = '',
    this.coverUrl,
    required this.userId,
    this.isPublic = false,
    this.isFavourite = false,
    this.trackIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  PlaylistModel copyWith({
    String? id,
    String? title,
    String? description,
    String? coverUrl,
    String? userId,
    bool? isPublic,
    bool? isFavourite,
    List<String>? trackIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      userId: userId ?? this.userId,
      isPublic: isPublic ?? this.isPublic,
      isFavourite: isFavourite ?? this.isFavourite,
      trackIds: trackIds ?? this.trackIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'coverUrl': coverUrl,
      'userId': userId,
      'isPublic': isPublic ? 1 : 0,
      'isFavourite': isFavourite ? 1 : 0,
      'trackIds': trackIds.join(','),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory PlaylistModel.fromMap(Map<String, dynamic> map) {
    return PlaylistModel(
      id: map['id'] as String,
      title: map['title'] as String? ?? 'Untitled Playlist',
      description: map['description'] as String? ?? '',
      coverUrl: map['coverUrl'] as String?,
      userId: map['userId'] as String? ?? 'guest',
      isPublic: (map['isPublic'] == 1 || map['isPublic'] == true),
      isFavourite: (map['isFavourite'] == 1 || map['isFavourite'] == true),
      trackIds: (map['trackIds'] as String?)
              ?.split(',')
              .where((id) => id.isNotEmpty)
              .toList() ??
          [],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isSynced: (map['isSynced'] == 1 || map['isSynced'] == true),
    );
  }
}
