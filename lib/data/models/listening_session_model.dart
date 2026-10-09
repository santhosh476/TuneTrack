import '../../core/constants/app_constants.dart';

/// Represents a single recorded listening session / event in TuneTrack
class ListeningSessionModel {
  final String id;
  final String userId;
  final String trackId;
  final String trackTitle;
  final String artistName;
  final String albumName;
  final String? artworkUrl;
  final String genre;
  final String playbackSource; // 'local', 'demo', 'spotify', 'stream'
  final DateTime startedAt; // UTC
  final DateTime endedAt; // UTC
  final int audibleDurationSeconds;
  final bool isCompleted;
  final bool isSynced;

  const ListeningSessionModel({
    required this.id,
    required this.userId,
    required this.trackId,
    required this.trackTitle,
    required this.artistName,
    required this.albumName,
    this.artworkUrl,
    required this.genre,
    required this.playbackSource,
    required this.startedAt,
    required this.endedAt,
    required this.audibleDurationSeconds,
    this.isCompleted = false,
    this.isSynced = false,
  });

  /// Check if this listening event constitutes a valid play according to TuneTrack rules
  bool get isValidPlay =>
      audibleDurationSeconds >= AppConstants.minListeningThresholdSeconds ||
      isCompleted;

  ListeningSessionModel copyWith({
    String? id,
    String? userId,
    String? trackId,
    String? trackTitle,
    String? artistName,
    String? albumName,
    String? artworkUrl,
    String? genre,
    String? playbackSource,
    DateTime? startedAt,
    DateTime? endedAt,
    int? audibleDurationSeconds,
    bool? isCompleted,
    bool? isSynced,
  }) {
    return ListeningSessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      trackId: trackId ?? this.trackId,
      trackTitle: trackTitle ?? this.trackTitle,
      artistName: artistName ?? this.artistName,
      albumName: albumName ?? this.albumName,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      genre: genre ?? this.genre,
      playbackSource: playbackSource ?? this.playbackSource,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      audibleDurationSeconds:
          audibleDurationSeconds ?? this.audibleDurationSeconds,
      isCompleted: isCompleted ?? this.isCompleted,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'trackId': trackId,
      'trackTitle': trackTitle,
      'artistName': artistName,
      'albumName': albumName,
      'artworkUrl': artworkUrl,
      'genre': genre,
      'playbackSource': playbackSource,
      'startedAt': startedAt.toUtc().toIso8601String(),
      'endedAt': endedAt.toUtc().toIso8601String(),
      'audibleDurationSeconds': audibleDurationSeconds,
      'isCompleted': isCompleted ? 1 : 0,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory ListeningSessionModel.fromMap(Map<String, dynamic> map) {
    return ListeningSessionModel(
      id: map['id'] as String,
      userId: map['userId'] as String? ?? 'guest',
      trackId: map['trackId'] as String,
      trackTitle: map['trackTitle'] as String? ?? 'Unknown Title',
      artistName: map['artistName'] as String? ?? 'Unknown Artist',
      albumName: map['albumName'] as String? ?? 'Unknown Album',
      artworkUrl: map['artworkUrl'] as String?,
      genre: map['genre'] as String? ?? 'Music',
      playbackSource: map['playbackSource'] as String? ?? 'local',
      startedAt:
          DateTime.tryParse(map['startedAt'] as String? ?? '')?.toUtc() ??
              DateTime.now().toUtc(),
      endedAt: DateTime.tryParse(map['endedAt'] as String? ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
      audibleDurationSeconds:
          (map['audibleDurationSeconds'] as num?)?.toInt() ?? 0,
      isCompleted: (map['isCompleted'] == 1 || map['isCompleted'] == true),
      isSynced: (map['isSynced'] == 1 || map['isSynced'] == true),
    );
  }
}
