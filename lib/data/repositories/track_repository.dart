import 'package:file_picker/file_picker.dart';
import '../local/app_database.dart';
import '../models/track_model.dart';
import '../../core/utils/id_generator.dart';

class TrackRepository {
  final AppDatabase _db;

  TrackRepository(this._db);

  Stream<List<TrackModel>> watchTracks() => _db.watchTracks;
  Stream<List<String>> watchFavourites() => _db.watchFavourites;

  List<TrackModel> getAllTracks() => _db.getAllTracks();

  TrackModel? getTrackById(String id) => _db.getTrackById(id);

  Future<void> addTrack(TrackModel track) => _db.insertOrUpdateTrack(track);

  Future<void> deleteTrack(String id) => _db.deleteTrack(id);

  List<TrackModel> getFavouriteTracks() {
    final favIds = _db.getFavouriteTrackIds();
    final all = _db.getAllTracks();
    return all.where((t) => favIds.contains(t.id)).toList();
  }

  Future<bool> toggleFavourite(String trackId) => _db.toggleFavourite(trackId);

  bool isFavourite(String trackId) => _db.isTrackFavourite(trackId);

  /// Allows the user to select local audio files from device storage across Android, iOS, Desktop, and Web
  Future<List<TrackModel>> pickLocalAudioFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'wav', 'aac', 'flac', 'ogg'],
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) {
        return [];
      }

      final List<TrackModel> importedTracks = [];
      for (final file in result.files) {
        final path = file.path ?? file.bytes.toString();
        final rawName = file.name;

        // Clean name into title and optional artist
        String title = rawName;
        String artist = 'Local Artist';
        if (title.contains('.')) {
          title = title.substring(0, title.lastIndexOf('.'));
        }
        if (title.contains(' - ')) {
          final parts = title.split(' - ');
          if (parts.length >= 2) {
            artist = parts[0].trim();
            title = parts.sublist(1).join(' - ').trim();
          }
        }

        final track = TrackModel(
          id: IdGenerator.generateTrackId(),
          title: title.isEmpty ? 'Local Audio' : title,
          artistName: artist,
          albumName: 'Device Storage',
          durationMs: 180000, // Default duration if not extracted yet
          sourceType: AudioSourceType.localFile,
          audioSourceUrl: path,
          artworkUrl: null,
          genre: 'Local',
          addedAt: DateTime.now(),
        );

        await _db.insertOrUpdateTrack(track);
        importedTracks.add(track);
      }

      return importedTracks;
    } catch (e) {
      return [];
    }
  }

  List<TrackModel> searchTracks(String query) {
    if (query.trim().isEmpty) return getAllTracks();
    final q = query.toLowerCase().trim();
    return getAllTracks().where((t) {
      return t.title.toLowerCase().contains(q) ||
          t.artistName.toLowerCase().contains(q) ||
          t.albumName.toLowerCase().contains(q) ||
          t.genre.toLowerCase().contains(q);
    }).toList();
  }
}
