/// Represents a music album in TuneTrack
class AlbumModel {
  final String id;
  final String title;
  final String artistName;
  final String? artworkUrl;
  final int releaseYear;
  final int trackCount;
  final String genre;

  const AlbumModel({
    required this.id,
    required this.title,
    required this.artistName,
    this.artworkUrl,
    this.releaseYear = 2026,
    this.trackCount = 0,
    this.genre = 'Music',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artistName': artistName,
      'artworkUrl': artworkUrl,
      'releaseYear': releaseYear,
      'trackCount': trackCount,
      'genre': genre,
    };
  }

  factory AlbumModel.fromMap(Map<String, dynamic> map) {
    return AlbumModel(
      id: map['id'] as String,
      title: map['title'] as String? ?? 'Unknown Album',
      artistName: map['artistName'] as String? ?? 'Unknown Artist',
      artworkUrl: map['artworkUrl'] as String?,
      releaseYear: (map['releaseYear'] as num?)?.toInt() ?? 2026,
      trackCount: (map['trackCount'] as num?)?.toInt() ?? 0,
      genre: map['genre'] as String? ?? 'Music',
    );
  }
}
