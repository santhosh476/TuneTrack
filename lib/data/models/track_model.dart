enum AudioSourceType {
  localFile,
  networkStream,
  spotifyStream,
  demoAsset,
}

/// Represents a single audio track in TuneTrack
class TrackModel {
  final String id;
  final String title;
  final String artistName;
  final String albumName;
  final int durationMs;
  final String? artworkUrl;
  final AudioSourceType sourceType;
  final String audioSourceUrl;
  final bool isFavourite;
  final String genre;
  final DateTime addedAt;

  const TrackModel({
    required this.id,
    required this.title,
    required this.artistName,
    required this.albumName,
    required this.durationMs,
    this.artworkUrl,
    required this.sourceType,
    required this.audioSourceUrl,
    this.isFavourite = false,
    this.genre = 'Unknown',
    required this.addedAt,
  });

  Duration get duration => Duration(milliseconds: durationMs);
  String get audioUrl => audioSourceUrl;

  TrackModel copyWith({
    String? id,
    String? title,
    String? artistName,
    String? albumName,
    int? durationMs,
    String? artworkUrl,
    AudioSourceType? sourceType,
    String? audioSourceUrl,
    bool? isFavourite,
    String? genre,
    DateTime? addedAt,
  }) {
    return TrackModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artistName: artistName ?? this.artistName,
      albumName: albumName ?? this.albumName,
      durationMs: durationMs ?? this.durationMs,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      sourceType: sourceType ?? this.sourceType,
      audioSourceUrl: audioSourceUrl ?? this.audioSourceUrl,
      isFavourite: isFavourite ?? this.isFavourite,
      genre: genre ?? this.genre,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artistName': artistName,
      'albumName': albumName,
      'durationMs': durationMs,
      'artworkUrl': artworkUrl,
      'sourceType': sourceType.name,
      'audioSourceUrl': audioSourceUrl,
      'isFavourite': isFavourite ? 1 : 0,
      'genre': genre,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory TrackModel.fromMap(Map<String, dynamic> map) {
    return TrackModel(
      id: map['id'] as String,
      title: map['title'] as String? ?? 'Unknown Title',
      artistName: map['artistName'] as String? ?? 'Unknown Artist',
      albumName: map['albumName'] as String? ?? 'Unknown Album',
      durationMs: (map['durationMs'] as num?)?.toInt() ?? 0,
      artworkUrl: map['artworkUrl'] as String?,
      sourceType: AudioSourceType.values.firstWhere(
        (e) => e.name == map['sourceType'],
        orElse: () => AudioSourceType.localFile,
      ),
      audioSourceUrl: map['audioSourceUrl'] as String? ?? '',
      isFavourite: (map['isFavourite'] == 1 || map['isFavourite'] == true),
      genre: map['genre'] as String? ?? 'Music',
      addedAt: map['addedAt'] != null
          ? DateTime.tryParse(map['addedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
