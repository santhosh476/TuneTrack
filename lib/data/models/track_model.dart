enum AudioSourceType {
  localFile,
  networkStream,
  spotifyStream,
  demoAsset,
  youtubeVideo,
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
  final String? sourceDetailUrl;
  final String? license;
  final String? previewUrl;

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
    this.sourceDetailUrl,
    this.license,
    this.previewUrl,
  });

  Duration get duration => Duration(milliseconds: durationMs);
  String get audioUrl => audioSourceUrl;

  /// Returns YouTube Video ID if track is a YouTube video source
  String? get youtubeVideoId {
    if (sourceType == AudioSourceType.youtubeVideo) {
      if (audioSourceUrl.contains('v=')) {
        final uri = Uri.tryParse(audioSourceUrl);
        return uri?.queryParameters['v'] ?? id.replaceFirst('yt_', '');
      }
      return audioSourceUrl.isNotEmpty
          ? audioSourceUrl
          : id.replaceFirst('yt_', '');
    }
    return null;
  }

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
    String? sourceDetailUrl,
    String? license,
    String? previewUrl,
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
      sourceDetailUrl: sourceDetailUrl ?? this.sourceDetailUrl,
      license: license ?? this.license,
      previewUrl: previewUrl ?? this.previewUrl,
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
      'sourceDetailUrl': sourceDetailUrl,
      'license': license,
      'previewUrl': previewUrl,
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
      sourceDetailUrl: map['sourceDetailUrl'] as String?,
      license: map['license'] as String?,
      previewUrl: map['previewUrl'] as String?,
    );
  }
}
