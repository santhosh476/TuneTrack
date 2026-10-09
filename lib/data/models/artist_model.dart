/// Represents an artist in TuneTrack
class ArtistModel {
  final String id;
  final String name;
  final String? imageUrl;
  final List<String> genres;
  final int monthlyListeners;
  final String bio;

  const ArtistModel({
    required this.id,
    required this.name,
    this.imageUrl,
    this.genres = const [],
    this.monthlyListeners = 0,
    this.bio = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'genres': genres.join(','),
      'monthlyListeners': monthlyListeners,
      'bio': bio,
    };
  }

  factory ArtistModel.fromMap(Map<String, dynamic> map) {
    return ArtistModel(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Unknown Artist',
      imageUrl: map['imageUrl'] as String?,
      genres: (map['genres'] as String?)
              ?.split(',')
              .where((g) => g.isNotEmpty)
              .toList() ??
          [],
      monthlyListeners: (map['monthlyListeners'] as num?)?.toInt() ?? 0,
      bio: map['bio'] as String? ?? '',
    );
  }
}
