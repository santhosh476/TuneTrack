import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/data/local/app_database.dart';
import 'package:flutter_application_1/data/repositories/playlist_repository.dart';

void main() {
  group('Playlist & Favourites Operations Tests', () {
    late SharedPreferences prefs;
    late AppDatabase db;
    late PlaylistRepository playlistRepo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      db = AppDatabase(prefs);
      playlistRepo = PlaylistRepository(db);
    });

    test('Creates, modifies, and deletes custom playlist', () async {
      final created = await playlistRepo.createPlaylist(
        title: 'Synthwave Odyssey',
        description: 'Retro 80s futuristic soundtrack',
        userId: 'user_1',
      );

      expect(created.title, equals('Synthwave Odyssey'));
      var all = playlistRepo.getAllPlaylists(userId: 'user_1');
      expect(all.any((p) => p.id == created.id), isTrue);

      // Add track
      await playlistRepo.addTrackToPlaylist(created.id, 'demo_trk_1');
      await playlistRepo.addTrackToPlaylist(created.id, 'demo_trk_2');

      var updated = playlistRepo.getPlaylistById(created.id);
      expect(updated?.trackIds.length, equals(2));
      expect(updated?.trackIds, containsAll(['demo_trk_1', 'demo_trk_2']));

      // Reorder tracks (moving index 0 after index 1 in ReorderableListView passes newIndex: 2)
      await playlistRepo.reorderTracksInPlaylist(created.id, 0, 2);
      updated = playlistRepo.getPlaylistById(created.id);
      expect(updated?.trackIds.first, equals('demo_trk_2'));

      // Remove track
      await playlistRepo.removeTrackFromPlaylist(created.id, 'demo_trk_1');
      updated = playlistRepo.getPlaylistById(created.id);
      expect(updated?.trackIds.length, equals(1));

      // Delete playlist
      await playlistRepo.deletePlaylist(created.id);
      expect(playlistRepo.getPlaylistById(created.id), isNull);
    });
  });
}
